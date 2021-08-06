library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.top_pkg.all;

use work.pci_wrapper_pkg.all;
use work.pci_core_wrapper_pkg.all;

use work.pcie_rx_engine_pkg.all;
use work.pcie_tx_engine_pkg.all;

library m100_sio_core;
use m100_sio_core.siobp_frame_handler_pkg.all;
use m100_sio_core.siobp_frame_engine_rx_pkg.all;
use m100_sio_core.siobp_frame_buffer_rx_cw_pkg.all;
use m100_sio_core.sio_serializer_pkg.all;
use m100_sio_core.sio_deserializer_pkg.all;
use m100_sio_core.sio_bus_pkg.all;

use work.command_interpreter_pkg.all;
use work.dma_controller_pkg.all;
use work.completer_term_pkg.all;
use work.msi_x_controller_pkg.all;
use work.packet_fifo_pkg.all;
use work.bus_controller_pkg.all;
use work.reg_controller_pkg.all;

use work.command_interpreter_pkg.all;
use work.ptm_engine_pkg.all;

library m100_design_info;
use m100_design_info.design_info_pkg.all;

library ecp5um;
use ecp5um.components.all;

--! placeholder for sinplify libraries
--library sinplify;
--use sinplify.attributes.all;

entity top is
    generic ( TEST : boolean := FALSE;                  -- the usrmclk module doesn't generate in the test version
              MSI_X_ENA : boolean := TRUE;              -- using the MSI-X interrupts
              MODUL_NUM : integer := MODUL_NUM_CONST);  -- deprecated, unused in new version
    port(
        clk_25           : in std_logic;

        -- sync out and modul reset
        sync_in         : in std_logic;
        sync_out        : out std_logic;
        modul_reset_n   : out std_logic;

        -- spi config memory interface
        -- clock signal generates the usrmclk moudle
        config_cs_n     : out std_ulogic;
        config_mosi     : out std_logic;
        config_miso     : in std_logic;

        -- id reg memory interface
        id_cs_n        : out std_logic;
        id_sck         : out std_logic;
        id_mosi        : out std_logic;
        id_miso        : in std_logic;

        -- sensors i2c interface, not unused
        sda             : inout std_logic;
        scl             : out std_logic;

        -- sensor interrupts inputs, not used
--      acc_int1        : in std_logic;
--      acc_int2        : inout std_logic;

        -- 9-pin socket, pin 1: GND, pins 2-9: debug (0 to 7)
        debug           : out std_logic_vector (7 downto 0);

        -- fpga interrupt
--      fpga_int1       : out std_logic;        -- reserved for interrupts output
--      fpga_int2       : out std_logic;        -- reserved for interrupts output
        self_reset      : out std_logic;

        -- serial interface to module
        bimo            : in std_logic_vector (30 downto 0);
        bomi            : out std_logic_vector (30 downto 0);

        -- PCIE interface
        pcie_rxp        : in std_logic;  --! FPGA in ROOT out
        pcie_rxn        : in std_logic;

        pcie_txp        : out std_logic; --! FPGA out ROOT in
        pcie_txn        : out std_logic;

        pcie_clkp       : in std_logic;
        pcie_clkn       : in std_logic
    );
end entity top;

architecture rtl of top is

    signal refclk                   : std_logic;    --! reference clock for PCIExpress core
    signal sys_clk_125              : std_logic;    --! PCIExpress TLP interface clock
    signal rst_n                    : std_logic;    --! reset for PCIExpress core, active low
    signal pcie_rst                 : std_logic;    --! reset when dl_up is 0, active high

    signal clk_100                  : std_logic;
    signal clk_150                  : std_logic;    --! Frame handler deserializer clock
    signal timer_clk                : std_logic;    --! timer clock for frame handler
    signal pll_lock                 : std_logic;    --! pll_lock from clock generator

    signal bimo_s                   : std_logic_vector (31 downto 0);   --! registered sio_bimo
    signal bomi_s                   : std_logic_vector (31 downto 0);   --! registered sio_bomi

    --! PCIExpress core interface
    signal d_pci                    : t_pci_core_wrapper_in;
    signal q_pci                    : t_pci_core_wrapper_out;

    --! PCIExpress TX/RX engine interface
    signal d_tx                     : t_pcie_tx_engine_in;
    signal q_tx                     : t_pcie_tx_engine_out;

    signal d_rx                     : t_pcie_rx_engine_in;
    signal q_rx                     : t_pcie_rx_engine_out;

    --! PCIEXpress completer module interface
    signal d_cpl                    : t_completer_term_in;
    signal q_cpl                    : t_completer_term_out;

    --! bus frame handler interface
    signal tx_slot_index            : integer range 0 to 7;         --! frame handler slot number iterator
    signal tx_fh_index              : integer range 0 to 3;         --! frame handler iterator
    signal tx_valid                 : std_logic;
    signal tx_last                  : std_logic_vector (1 downto 0);
    signal tx_data                  : std_logic_vector (15 downto 0);

    --! DMA interface
    signal d_dma                    : t_dma_controller_in;
    signal q_dma                    : t_dma_controller_out;

    --! packet fifo interface
    signal d_pf                     : packet_fifo_in_t;
    signal q_pf                     : packet_fifo_out_t;

    --! command interpreter interface
    signal d_ci                     : command_interpreter_in_t;
    signal q_ci                     : command_interpreter_out_t;

    --! MSI-X interface
    signal d_msix                   : t_msi_x_controller_in;
    signal q_msix                   : t_msi_x_controller_out;

    --! DPRAM interface for DMA Table (BAR0)
    signal dma_table_addr_a         : std_logic_vector (14 downto 0);
    signal dma_table_wr_data_a      : std_logic_vector (17 downto 0);
    signal dma_table_rd_data_a      : std_logic_vector (17 downto 0);
    signal dma_table_rd_data_b      : std_logic_vector (17 downto 0);
    signal dma_table_be             : std_logic_vector (1 downto 0);
    signal dma_table_we             : std_logic;


    --! Frame handlers interface
    type t_d_fh_array is array (3 downto 0) of t_siobp_frame_handler_in;
    type t_q_fh_array is array (3 downto 0) of t_siobp_frame_handler_out;
    signal d_fh                     : t_d_fh_array;
    signal q_fh                     : t_q_fh_array;

    --! BPL sio bus
    signal d_sio                    : t_sio_bus_in;
    signal q_sio                    : t_sio_bus_out(sync(0 to 6));

    --! BPL sio bus controller
    signal d_bc                     : t_bus_controller_in;
    signal q_bc                     : t_bus_controller_out;

    --! Register controller signals
    signal d_rc                     : t_reg_controller_in;
    signal q_rc                     : t_reg_controller_out;

    --! PTM interface
    signal d_ptm                    : t_ptm_engine_in;
    signal q_ptm                    : t_ptm_engine_out;

    --! buffer clear signal from frame handler to dma controller
    signal buffer_clr               : std_logic_vector (31 downto 0);

    --! PCIExpress reset delay generation
    signal pwrup_reset_delay_count  : std_logic_vector(5 downto 0) := (others => '0');
    constant C_PWRUP_RESET_DELAY    : std_logic_vector(5 downto 0) := (others => '1');

    component USRMCLK
    port (
        usrmclki : in std_ulogic;
        usrmclkts : in std_ulogic
    );
    end component;

--******************************************************************************
-- REVEAL ANALYZER SIGNALS
-- placeholder for debug
-- attributes used to prevent signals optimizing
--******************************************************************************
--  signal ra_tx_ca_pd              : std_logic_vector (12 downto 0);
--  signal ra_tx_ca_ph              : std_logic_vector (8 downto 0);
--  signal ra_tx_ca_nph             : std_logic_vector (8 downto 0);
--  signal ra_st                    : std_logic;
--
--  attribute syn_preserve : boolean;
--  attribute syn_preserve of ra_tx_ca_pd        : signal is true;
--  attribute syn_preserve of ra_tx_ca_ph        : signal is true;
--  attribute syn_preserve of ra_tx_ca_nph       : signal is true;
--  attribute syn_preserve of ra_st              : signal is true;
--******************************************************************************

begin

--******************************************************************************
--  DEBUG
--**************************************************************************
    debug(7 downto 2) <= (others => '0');
    debug(1 downto 0) <= q_sio.bimo & q_fh(0).serial_data_out(0);

--**************************************************************************
-- REVEAL INSERTER
-- placeholder for debug
-- signals used to prevent optimizing
--**************************************************************************
--  pcie_rx_reveal_inserter : if (true) generate
--  ra_process : process (sys_clk_125) is
--  begin
--      if rising_edge (sys_clk_125) then
--          ra_tx_ca_pd <= q_tx.ra_tx_ca_pd;
--          ra_tx_ca_ph <= q_tx.ra_tx_ca_ph;
--          ra_tx_ca_nph <= q_tx.ra_tx_ca_nph;
--          ra_st <= q_tx.ra_st;
--      end if;
--  end process;
--  end generate pcie_rx_reveal_inserter;
--******************************************************************************

    modul_reset_n <= 'Z';--q_pci.phy.phy_ltssm_state(1);--'0';

    bomi <= bomi_s(31 downto 1) when pcie_rst = '0' else (others =>'0');
    bimo_s <= bimo & q_sio.bimo;

--  sync_out <= q_dma.sync_trigger_out when q_msix.ptm_ena = '0' else q_ptm.us_clock;
    sync_out <= q_ptm.us_clock;


    d_sio.spi_miso <= config_miso when q_sio.spi_cs_n(0) = '0' else id_miso;
    config_mosi <= q_sio.spi_mosi;
    config_cs_n <= q_sio.spi_cs_n(0);

    id_cs_n <= q_sio.spi_cs_n(1);
    id_mosi <= q_sio.spi_mosi;
    id_sck <= q_sio.spi_sck;

    sda <= 'Z';
    scl <= 'Z';

    self_reset <= q_dma.self_reset;

    --! generating an asynchronous reset signal for pcie core
    P_RESET_DELAY : process (pll_lock, clk_100) is begin
        if pll_lock = '0' then
            rst_n <= '0';
            pwrup_reset_delay_count <= (others => '0');
        else
            if rising_edge(clk_100) then
                if pwrup_reset_delay_count = C_PWRUP_RESET_DELAY then
                    rst_n <= '1';
                else
                    rst_n <= '0';
                    pwrup_reset_delay_count <= std_logic_vector(unsigned(pwrup_reset_delay_count) + 1);
                end if;
            end if;
        end if;
    end process;

    --! generating synchronous reset signal for BPL design
    --! link status used to reset
    logic_reset : process (sys_clk_125) is begin
        if rising_edge(sys_clk_125) then
            if q_pci.data_link.dl_up = '1' then
                pcie_rst <= '0';
            else
                pcie_rst <= '1';
            end if;
        end if;
    end process;

    --! usrmclk module not used in simulation
    config_sck_generate: if TEST = FALSE generate
    usrmclk_inst : USRMCLK port map (
        usrmclki => q_sio.spi_sck,
        usrmclkts => pcie_rst
    );
    end generate config_sck_generate;

--******************************************************************************
-- PCIExpress clock
--******************************************************************************
    extref_inst : entity work.extref
        port map(
            refclkp => pcie_clkn,
            refclkn => pcie_clkp,
            refclko => refclk
        );

--******************************************************************************
-- Main clock generating
--******************************************************************************
    pll_inst : entity work.clock_gen
        port map(
            clk          => clk_25,
            clk_125      => sys_clk_125,
            clk_100      => clk_100,
            clk_150      => clk_150,
            clk_25       => open,
            timer_clk    => timer_clk,
            sync_out     => open,
            pll_lock     => pll_lock
        );

--******************************************************************************
-- PCIExpress core wrapper
--******************************************************************************
    pcie_core_wrapper_inst : entity work.pci_core_wrapper
        port map(
            pll_refclki      => refclk,
            rxrefclk         => refclk,
            no_pcie_train    => '0',

            pci_core_hdinn0  => pcie_rxn,
            pci_core_hdinp0  => pcie_rxp,

            pci_core_hdoutn0 => pcie_txn,
            pci_core_hdoutp0 => pcie_txp,

            pci_rst_n        => rst_n,
            sli_rst          => '0',
            sys_clk_125      => sys_clk_125,

            d                => d_pci,
            q                => q_pci
        );

    d_rx.tlp_rx <= q_pci.rx_tlp;
    d_pci.rx_tlp <= q_rx.tlp_rx;

    d_tx.tlp_tx <= q_pci.tx_tlp;
    d_pci.tx_tlp <= q_tx.tlp_tx;

    d_pci.cfg.msi <= q_pf.interrupt;

--******************************************************************************
-- PCIExpress RX
--******************************************************************************
    d_rx.nph_processed_vc0 <= q_tx.nph_processed_vc0;

    pcie_rx_engine_inst : entity work.pcie_rx_engine
    generic map(debug_pcie_rx => PCIE_RX_DEBUG_ENA) -- placeholder for reveal analyzer, not used in design
    port map (
       clk                  => sys_clk_125,
       rst                  => pcie_rst,
       d                    => d_rx,
       q                    => q_rx
    );

--******************************************************************************
-- PCIExpress TX
--******************************************************************************
    d_tx.read_req   <= q_rx.read_req;
    d_tx.addr_read  <= q_rx.addr_out;
    d_tx.tag        <= q_rx.tag;
    d_tx.data_in    <= dma_table_rd_data_a(7 downto 0) & dma_table_rd_data_a (16 downto 9) when q_tx.read_bar(0) = '1' else
                    q_dma.data_out when q_tx.read_bar(1) = '1' else
                    q_msix.data_out when q_tx.read_bar(2) = '1' else
                    q_msix.data_out when q_tx.read_bar(3) = '1' else
                    q_msix.data_out when (unsigned(q_tx.read_bar) = 0) else
                    (others => '0');

    d_tx.tc <= q_rx.tc;
    d_tx.length     <= q_rx.length;
    d_tx.bar_hit_in <= q_rx.bar_hit;
    d_tx.requester_id <= q_rx.req_id;
    d_tx.completer_id <= q_pci.cfg.bus_num & q_pci.cfg.dev_num & q_pci.cfg.func_num;
    d_tx.dw           <= q_rx.dw;
    d_tx.cfg_cmpl_req <= q_rx.cfg_cmpl_req;

    d_tx.dma_len <= q_dma.length;
    d_tx.dma_tag <= q_dma.tag;
    d_tx.dma_rd_req <= q_dma.pcie_rd_req;
    d_tx.dma_addr <= q_dma.pcie_rd_addr;

    d_tx.msi_x_data <= q_msix.msi_x_data;
    d_tx.msi_x_ena <= q_msix.msi_x_ena;
    d_tx.msi_x_req <= q_msix.msi_x_req;

    d_tx.ptm_req <= q_ptm.ptm_request;

    pcie_tx_engine_inst : entity work.pcie_tx_engine
    port map (
        clk                 => sys_clk_125,
        rst                 => pcie_rst,
        d                   => d_tx,
        q                   => q_tx
    );

--******************************************************************************
-- DMA Controller
--******************************************************************************

    d_dma.sync_in <= sync_in;
    d_dma.addr_rd <= q_tx.rdaddress(7 downto 0);
    d_dma.addr_wr <= q_rx.addr_out(7 downto 0);
    d_dma.bar_hit <= q_rx.bar_hit(1);
    d_dma.data_in <= q_rx.data_out;
    d_dma.pcie_be <= q_rx.we;

    d_dma.compl_err <= q_cpl.compl_err_out;
    d_dma.compl_err_mod_num <= q_cpl.compl_err_mod_num;
    d_dma.pcie_req_rdy <= q_tx.dma_req_rdy;

    d_dma.dma_table_rd_data_b <= dma_table_rd_data_b(16 downto 9) & dma_table_rd_data_b(7 downto 0);

    d_dma.buffer_clr <= buffer_clr(31 downto 0);

    d_dma.msi_x_pba_status <= q_msix.msi_x_pba_status;

    --! debug ptm timer
--  d_dma.ptm_timer <= q_ptm.ptm_timer;

    event_ready_generate: for i in 0 to 7 generate
        d_dma.tx_evt_rdy(i) <= q_fh(0).tx_evt_rdy(i);
        d_dma.tx_evt_rdy(8+i) <= q_fh(1).tx_evt_rdy(i);
        d_dma.tx_evt_rdy(16+i) <= q_fh(2).tx_evt_rdy(i);
        d_dma.tx_evt_rdy(24+i) <= q_fh(3).tx_evt_rdy(i);
    end generate;

    dma_controller_inst : entity work.dma_controller
        port map(
            clk => sys_clk_125,
            rst => pcie_rst,
            d   => d_dma,
            q   => q_dma
        );

--******************************************************************************
-- completer terminator
--******************************************************************************

    d_cpl.tlp_rx <= q_pci.rx_tlp;

    d_cpl.interrupt_wait <= q_dma.interrupt_wait;
    d_cpl.interrupt_tag <= q_dma.interrupt_tag;
    d_cpl.interrupt_async <= q_dma.interrput_async;
    d_cpl.int_0_rdy <= q_msix.int_0_rdy;
    d_cpl.int_1_rdy <= q_msix.int_1_rdy;

    completer_inst : entity work.completer_term
        port map(
            clk => sys_clk_125,
            rst => pcie_rst,
            d   => d_cpl,
            q   => q_cpl
        );

--******************************************************************************
-- MSI-X Controller
--******************************************************************************

    msi_x_modul_generate : if (MSI_X_ENA) generate
    d_msix.addr_write <= q_rx.addr_out(11 downto 0);
    d_msix.bar_hit_wr <= q_rx.bar_hit;
    d_msix.bar_hit_rd <= q_tx.read_bar;
    d_msix.data_in <= q_rx.data_out;
    d_msix.pcie_be <= q_rx.we;

    d_msix.addr_read <= q_tx.rdaddress;
    d_msix.read_msi_x <= q_tx.read_msi_x;

    d_msix.msi_x_num <= q_pf.msi_x_num;
    d_msix.msi_x_stb <= q_pf.msi_x_stb;

    d_msix.msi_x_pba_clear <= q_dma.msi_x_pba_clear;
    d_msix.msi_x_pba_ena <= q_dma.msi_x_pba_ena;

    d_msix.int_0 <= q_cpl.int_0;
    d_msix.int_1 <= q_cpl.int_1;

    event_rec_generate: for i in 0 to 7 generate
        d_msix.rx_evt_rec(i) <= q_fh(0).rx_evt_rec(i);
        d_msix.rx_evt_rec(8+i) <= q_fh(1).rx_evt_rec(i);
        d_msix.rx_evt_rec(16+i) <= q_fh(2).rx_evt_rec(i);
        d_msix.rx_evt_rec(24+i) <= q_fh(3).rx_evt_rec(i);

        d_msix.rx_evt_idx(i) <= q_fh(0).rx_evt_idx(i);
        d_msix.rx_evt_idx(8+i) <= q_fh(1).rx_evt_idx(i);
        d_msix.rx_evt_idx(16+i) <= q_fh(2).rx_evt_idx(i);
        d_msix.rx_evt_idx(24+i) <= q_fh(3).rx_evt_idx(i);
    end generate;
    msi_x_controller_inst : entity work.msi_x_controller
        port map(
            clk => sys_clk_125,
            rst => pcie_rst,
            d   => d_msix,
            q   => q_msix
        );
    end generate;

--******************************************************************************
-- DMA Table
--******************************************************************************
    dma_table_addr_a <= q_rx.addr_out(14 downto 0) when q_rx.we /= "00" else "000" & q_tx.rdaddress(11 downto 0);
    dma_table_wr_data_a <= '0' &  q_rx.data_out (7 downto 0) & '0' & q_rx.data_out (15 downto 8);
    dma_table_be <= q_rx.we(1) & q_rx.we(0);
    dma_table_we <= (q_rx.we(1) or q_rx.we(0)) when q_rx.bar_hit(0) = '1' else '0';

    dma_table_inst : entity work.dma_table
        port map(
            DataInA  => dma_table_wr_data_a,
            DataInB  => (others => '0'),
            ByteEnA  => dma_table_be,
            ByteEnB  => "00",
            AddressA => dma_table_addr_a,
            AddressB => q_dma.dma_table_addr_b,
            ClockA   => sys_clk_125,
            ClockB   => sys_clk_125,
            ClockEnA => '1',
            ClockEnB => '1',
            WrA      => dma_table_we,
            WrB      => '0',
            ResetA   => pcie_rst,
            ResetB   => pcie_rst,
            QA       => dma_table_rd_data_a,
            QB       => dma_table_rd_data_b
        );

--******************************************************************************
-- IDX Memory
--******************************************************************************

    idx_mem_inst : entity work.idx_memory
        port map(
            WrAddress => "00" & q_dma.idx_addr,
            RdAddress => q_cpl.idx_mem_rd_addr,
            Data      => q_dma.idx_data,
            WE        => q_dma.idx_we,
            RdClock   => sys_clk_125,
            RdClockEn => '1',
            Reset     => pcie_rst,
            WrClock   => sys_clk_125,
            WrClockEn => '1',
            Q         => d_cpl.idx_mem_data
        );


--******************************************************************************
-- SIO BUS
--******************************************************************************
    d_sio.bomi <= q_fh(0).serial_data_out(0);
    d_sio.time_clock <= timer_clk;

    d_sio.mem <= q_rc.mem;
--  d_sio.mem_rd_data <= q_rc.mem_rd_data;
--  d_sio.mem_rd_rdy <= q_bc.mem_rd_rdy;
--  d_sio.mem_wr_rdy <= q_bc.mem_wr_rdy;
    sio_bus_inst : entity m100_sio_core.sio_bus
        generic map (
            G_FPGA_TYPE  => C_FPGA_TYPE,
            G_SYS_CLK_FREQ => 125,
            G_BIT_MASK_16   => "01",
            G_BIT_MASK_32   => "10",
            G_BIT_MASK_64   => "11",
            G_BIG_ENDIAN    => '0'

        )
        port map(
            i_clk        => sys_clk_125,
            i_reset      => pcie_rst,
            i_clk_sample => clk_150,
            d            => d_sio,
            q            => q_sio
        );

--******************************************************************************
-- bus address decoder
--******************************************************************************
--  d_bc.mem_rd_addr <= q_sio.mem_rd_addr(7 downto 0);
--  d_bc.mem_rd_en <= q_sio.mem_rd_en;
--  d_bc.mem_wr_addr <= q_sio.mem_wr_addr(7 downto 0);
--  d_bc.mem_wr_data <= q_sio.mem_wr_data;
--  d_bc.mem_wr_en <= q_sio.mem_wr_en;
--  
--  d_bc.set_link_go_run_num <= q_dma.set_link_go_run_num;
--
--  d_bc.rx_crc_error(7 downto 0) <= q_fh(0).rx_crc_error;
--  d_bc.rx_crc_error(15 downto 8) <= q_fh(1).rx_crc_error;
--  d_bc.rx_crc_error(23 downto 16) <= q_fh(2).rx_crc_error;
--  d_bc.rx_crc_error(31 downto 24) <= q_fh(3).rx_crc_error;
--
--
--  bus_addr_decoder_inst : entity work.bus_controller
--      port map(
--          clk => clk_100,
--          rst => pcie_rst,
--          d   => d_bc,
--          q   => q_bc
--      );

--******************************************************************************
-- Register Controller
--******************************************************************************
    d_rc.mem <= q_sio.mem;
    link_status_generate : for i in 0 to 7 generate
        d_rc.test_r_8_0(i) <= q_fh(0).link_status_ok(i);
        d_rc.test_r_8_1(i) <= q_fh(1).link_status_ok(i);
        d_rc.test_r_8_2(i) <= q_fh(2).link_status_ok(i);
        d_rc.test_r_8_3(i) <= q_fh(3).link_status_ok(i);
    end generate link_status_generate;
--  d_rc.mem_rd_addr <= q_sio.mem_rd_addr;
--  d_rc.mem_rd_be <= q_sio.mem_rd_be;
--  d_rc.mem_wr_addr <= q_sio.mem_wr_addr;
--  d_rc.mem_wr_data <= q_sio.mem_wr_data;
--  d_rc.mem_wr_be <= q_sio.mem_wr_be;

    reg_controller_inst : entity work.reg_controller
        port map(
            i_clk   => sys_clk_125,
            i_reset => pcie_rst,
            d       => d_rc,
            q       => q_rc
        );

--******************************************************************************
-- Frame Handlers
--******************************************************************************

    FRAME_HANDLERS : for i in 3 downto 0 generate

        d_fh(i).timer_clk_en <= timer_clk;
        -- link status go run assignmets
        reverse: for j in 0 to 7 generate
            d_fh(i).link_status_go_run (j) <= '1';--q_bc.link_status_go_run((i * 8) +j );
        end generate;

        d_fh(i).tx_data <= tx_data;
        d_fh(i).tx_valid <= tx_valid when tx_fh_index = i else '0';
        d_fh(i).tx_last <= tx_last when tx_fh_index = i else "00";
        d_fh(i).tx_slot_index <= tx_slot_index when tx_fh_index = i else 0;

        d_fh(i).rx_ready <= q_ci.rx_ready(i);
        d_ci.rx_valid(i) <= q_fh(i).rx_valid;
        d_ci.rx_slot_idx(i) <= q_fh(i).rx_slot_index;


        SERIAL_IO_GENERATE: for j in 7 downto 0 generate
            buffer_clr(i*8+j) <= q_fh(i).buffer_clr(j);
            bomi_s(i*8+j) <= q_fh(i).serial_data_out(j);
            d_fh(i).serial_data_in(j) <= bimo_s(i*8+j);
            d_bc.link_ok(i*8+j) <= q_fh(i).link_status_ok(j);
            d_dma.link_go_run(i*8+j) <= q_fh(i).link_status_run(j);
            d_dma.link_ok(i*8+j) <= q_fh(i).link_status_ok(j);
            d_msix.link(i*8+j) <= q_fh(i).link_status_ok(j);
            d_fh(i).tx_evt_idx(j) <= q_dma.tx_evt_idx(i*8+j);
            d_fh(i).tx_evt_req(j) <= q_dma.tx_evt_req(i*8+j);
        end generate SERIAL_IO_GENERATE;

        frame_handler_inst : entity m100_sio_core.siobp_frame_handler
            generic map ( G_SLOT_0    => 0)
            port map(
                i_clk        => sys_clk_125,
                i_reset      => pcie_rst,
                i_clk_sample => clk_150,
                d            => d_fh(i),
                q            => q_fh(i)
            );
    end generate;

    --! triggering interface signals to closure design timing
    latch_fh_data_fh : process (sys_clk_125) is
    begin
        if rising_edge (sys_clk_125) then
            tx_slot_index <= q_cpl.tx_slot_index;
            tx_fh_index <= q_cpl.tx_fh_index;
            tx_valid <= q_cpl.tx_valid;
            tx_last <= q_cpl.tx_last;
            tx_data <= q_cpl.tx_data;
        end if;
    end process;

--******************************************************************************
--* packet_fifo write
--******************************************************************************

    d_pf.read_ena <= q_tx.read_fifo;
    d_tx.write_req <= q_pf.write_req;
    d_tx.write_req_addr <= q_pf.write_addr;
    d_tx.write_req_len <= q_pf.write_len;
    d_tx.write_data <= q_pf.data_out;

    d_pf.addr <= q_ci.addr_out;
    d_pf.be_fifo <= q_ci.be_fifo;
    d_pf.data <= q_ci.data;
    d_pf.frame <= q_ci.we_fifo;
    d_pf.interrupt <= q_ci.interrupt;
    d_pf.interrupt_ena <= q_ci.interrupt_ena;
    d_pf.we_fifo <= q_ci.we_fifo;
    d_pf.modul_num <= q_ci.modul_num;
    d_pf.msi_x_ena <= q_msix.msi_x_ena;
    d_pf.msi_x_rdy <= q_msix.msi_x_rdy;
    d_pf.stop_cycl_data <= q_dma.stop_cycl_data;

    packet_fifo_inst : entity work.packet_fifo
    port map (
        clk             => sys_clk_125,
        rst             => pcie_rst,
        d               => d_pf,
        q               => q_pf
    );


--******************************************************************************
--* PTM Engine
--******************************************************************************
    ptm_engine_inst : entity work.ptm_engine
        port map(
            clk => sys_clk_125,
            rst => pcie_rst,
            d   => d_ptm,
            q   => q_ptm
        );

    d_ptm.sync_1mhz_in <= timer_clk;
    d_ptm.ptm_ena <= q_msix.ptm_ena;
    d_ptm.ptm_ready <= q_tx.ptm_ready;
    d_ptm.pcie_rx <= q_pci.rx_tlp;

    d_ptm.ptm_offset <= q_dma.ptm_offset;
    d_ptm.ptm_offset_cfg <= q_dma.ptm_offset_cfg;
    d_ptm.ptm_offset_ena <= q_dma.ptm_offset_ena;

--******************************************************************************
--* Command interpreter
--******************************************************************************
    d_ci.rx_data <= q_fh(0).rx_data when q_ci.rx_ready(0) = '1' else
                    q_fh(1).rx_data when q_ci.rx_ready(1) = '1' else
                    q_fh(2).rx_data when q_ci.rx_ready(2) = '1' else
                    q_fh(3).rx_data when q_ci.rx_ready(3) = '1' else
                    (others => '0');

    d_ci.rx_last <= q_fh(0).rx_last when q_ci.rx_ready(0) = '1' else
                    q_fh(1).rx_last when q_ci.rx_ready(1) = '1' else
                    q_fh(2).rx_last when q_ci.rx_ready(2) = '1' else
                    q_fh(3).rx_last when q_ci.rx_ready(3) = '1' else
                    (others => '0');

--  d_ci.stop_cycl_data <= q_dma.stop_cycl_data;
    d_ci.fifo_full <= q_pf.fifo_full;
    d_ci.addr_in <= q_dma.cpu_offset_out;

    command_interpreter_inst : entity work.command_interpreter
    port map (
        clk             => sys_clk_125,
        rst             => pcie_rst,
        d               => d_ci,
        q               => q_ci
    );

end rtl;