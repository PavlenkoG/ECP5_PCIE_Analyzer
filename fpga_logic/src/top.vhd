library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.analyzer_pkg.all;
use work.controller_pkg.all;
use work.rev_analyzer_pkg.all;

--vhdl_comp_off
--library sinplify;
--use sinplify.attributes.all;
--vhdl_comp_on

library ecp5um;
use ecp5um.components.all;

entity top is
    generic (
        PCS_1_ENABLE    : boolean := true;  -- receiver channel 1 enable
        PCS_2_ENABLE    : boolean := true   -- receiver channel 2 enable
    );
    port(

        clk_25_in       : in std_logic;     -- 25 MHz input clock
        clk_25_en       : out std_logic;    -- oscillator enable signal

        pcie_clk_n      : in std_logic;
        pcie_clk_p      : in std_logic;
        pcie_up_n       : in std_logic;
        pcie_up_p       : in std_logic;
        pcie_down_n     : in std_logic;
        pcie_down_p     : in std_logic;

        -- spi slave interface
        sclk            : in std_logic;
        cs_n            : in std_logic;
        mosi            : in std_logic;
        miso            : out std_logic;

        gsrn            : in std_logic;     -- trigger button for debug

        los             : in std_logic_vector (2 downto 0);     -- opAmp los signal
        disable1        : out std_logic;                        -- disable opAmp ch1
        disable2        : out std_logic;                        -- disable opAmp ch2
        disable3        : out std_logic;                        -- disable opAmp ch3

        -- signals for reveal analyzer
        data_out_o      : out std_logic_vector (31 downto 0);
        data_out_i      : out std_logic_vector (31 downto 0);
        timestamp       : out std_logic_vector (1 downto 0);
        
        led             : out std_logic_vector (7 downto 0);    -- eval board leds
        switch          : in std_logic_vector (7 downto 0)      -- eval board switches
    );
end top;

architecture RTL of top is
    constant SPI_WORD_SIZE     : integer := 8;
    constant C_PWRUP_RESET_DELAY : std_logic_vector (4 downto 0) := (others => '1');
    signal reset_delay_count    : std_logic_vector (4 downto 0) := (others => '0');

    signal clk_100              : std_logic;
    signal clk_200              : std_logic;
    signal extref               : std_logic;
    signal rst                  : std_logic;
    signal pll_lock             : std_logic;

    signal rx_k_1               : std_logic_vector (0 downto 0);
    signal rx_k_2               : std_logic_vector (0 downto 0);
    signal rx_pclk_1            : std_logic;
    signal rx_pclk_2            : std_logic;
    signal rxdata_1             : std_logic_vector (7 downto 0);
    signal rxdata_2             : std_logic_vector (7 downto 0);
    signal rxstatus0            : std_logic_vector (2 downto 0);
    signal rxstatus1           : std_logic_vector (2 downto 0);
    signal pcie_done_s_1        : std_logic;
    signal pcie_cone_s_1        : std_logic;
    signal lsm_status_s_1       : std_logic;
    signal lsm_status_s_2       : std_logic;
    signal rx_los_low           : std_logic;
    signal rx_cdr_lol_s_1       : std_logic;
    signal rx_cdr_lol_s_2       : std_logic;
    signal pcie_done_s          : std_logic;
    signal pcie_con_s           : std_logic;
    signal rx_invert            : std_logic;
    signal tx_invert            : std_logic;
    
    signal scram_rst_1          : std_logic;
    signal scram_rst_2          : std_logic;
    signal scram_en_1           : std_logic;
    signal scram_en_2           : std_logic;

    signal d_and                : t_analyzer_in;
    signal q_and                : t_analyzer_out;

    signal d_anu                : t_analyzer_in;
    signal q_anu                : t_analyzer_out;

--  signal data_addr_1          : std_logic_vector (14 downto 0);
--  signal data_addr_2          : std_logic_vector (14 downto 0);
--  signal data_ch_1            : std_logic_vector (31 downto 0);
--  signal data_ch_2            : std_logic_vector (31 downto 0);
--  signal timestamp_r          : std_logic_vector (1 downto 0);
--  signal data_wr_1            : std_logic;
--  signal data_wr_2            : std_logic;

    -- spi user interface
    signal din                  : std_logic_vector (SPI_WORD_SIZE - 1 downto 0);
    signal din_vld              : std_logic;
    signal din_rdy              : std_logic;
    signal dout                 : std_logic_vector (SPI_WORD_SIZE - 1 downto 0);
    signal dout_vld             : std_logic;

    signal d_cntr               : t_controller_in;
    signal q_cntr               : t_controller_out;

    signal d_ra                 : t_rev_analyzer_in;
    signal q_ra                 : t_rev_analyzer_out;

--  test implementation
    signal button               : std_logic;
    signal button_del           : std_logic;
    signal led_reg              : std_logic_vector (7 downto 0);

    signal trigger_ena          : std_logic := '0';
    signal trigger_resync       : std_logic_vector (1 downto 0) := (others => '0');
    signal trigger_stop         : std_logic_vector (1 downto 0);
    signal rd_addr              : std_logic_vector (14 downto 0) := (others => '0');
    signal read_ena             : std_logic;
    signal data_out             : std_logic_vector (35 downto 0);
    signal mem_data_out_rx      : std_logic_vector (35 downto 0);
    signal mem_data_out_tx      : std_logic_vector (35 downto 0);

    signal scr_data_1           : std_logic_vector (7 downto 0);
    signal rx_k_1d              : std_logic;
    signal scr_data_2           : std_logic_vector (7 downto 0);
    signal rx_k_2d              : std_logic;

    signal refclk               : std_logic;
    signal clk_lvds             : std_logic;
--vhdl_comp_off
--  attribute syn_preserve : boolean;
--  attribute syn_keep : boolean;
--  attribute syn_preserve of data_ch_1 : signal is true;
--  attribute syn_keep of data_ch_1 : signal is true;
--  attribute syn_preserve of data_ch_2 : signal is true;
--  attribute syn_keep of data_ch_2 : signal is true;
--  attribute syn_preserve of timestamp_r : signal is true;
--  attribute syn_keep of timestamp_r : signal is true;
--
--  attribute syn_preserve of clk_100 : signal is true;
--  attribute syn_keep of clk_100 : signal is true;
--vhdl_comp_on
    component ilvds
    port (
        an : in std_ulogic;
        a  : in std_ulogic;
        z  : out std_ulogic
    );
    end component;

begin

    led(2 downto 0) <= not los(2) & not los (1) & not los (0);
    led(4 downto 3) <= not lsm_status_s_1 & not lsm_status_s_2;
    led(7 downto 5) <= q_ra.led_out(7 downto 5);
    clk_25_en <= '1';

    disable3 <= switch(2);
    disable2 <= switch(1);
    disable1 <= switch(0);

--  rx_invert <= switch(3);
--  tx_invert <= switch(4);

    extref_inst : entity work.extref
        port map(
            refclkp => pcie_clk_p,
            refclkn => pcie_clk_n,
            refclko => extref
        );

    clk_100_mhz_pll : entity work.pll
    port map (
        clki                => clk_25_in,
        clkop               => clk_100,
        lock                => pll_lock
    );

    clk_200_mhz_pll : entity work.pll_200
    port map (
        clki                => extref,
        clkop               => refclk,
        lock                => open
    );

    pcs1_generate : if (PCS_1_ENABLE) generate
        -- CDR Loss of Lock Range 1
        -- Linear Equalizer 2
        -- Loss of Signal Threshold Select 5
        pcs_inst_1 : entity work.pcs_pci_rx
        port map (
            hdinn           => pcie_up_n,
            hdinp           => pcie_up_p,
            rxrefclk        => refclk,
            rx_pclk         => rx_pclk_1,
            rxdata          => rxdata_1,
            rx_k            => rx_k_1,
            rxstatus0       => rxstatus0,
            pcie_det_en_c   => '1',
            pcie_ct_c       => '0',
            signal_detect_c => '1',
            pcie_done_s     => pcie_done_s,
            pcie_con_s      => pcie_con_s,
            rx_los_low_s    => open, --rx_los_low,
            lsm_status_s    => lsm_status_s_1,
            rx_cdr_lol_s    => rx_cdr_lol_s_1,
            rx_pcs_rst_c    => rst,
            rx_serdes_rst_c => rst,
            rx_pwrup_c      => '1',
            rst_dual_c      => rst,
            serdes_rst_dual_c => rst,
            serdes_pdb      => '1'
        );

        lfsr_scrambler_inst_1 : entity work.lfsr_scrambler
        port map (
            rst             => rst,
            clk             => rx_pclk_1,
            data_in         => rxdata_1,
            rx_k            => rx_k_1(0),
            data_out        => scr_data_1,
            rx_k_out        => rx_k_1d
        );

        d_and.data_in_scr <= scr_data_1;
        d_and.rx_k <= rx_k_1d;

        d_and.trigger_start <= trigger_resync(1);--q_cntr.trigger_start;
--      d_and.trigger_stop <= q_cntr.trigger_stop;

        analyzer_down_inst : entity  work.analyzer
        port map (
            clk             => rx_pclk_1,
            rst             => rst,
            d               => d_and,
            q               => q_and
        ); 

        packet_memory_down_inst : entity work.packet_ram
            port map(
                WrAddress => q_and.addr_wr(14 downto 0),
                --! TODO: remove temporary address
                RdAddress => q_cntr.addr_read(14 downto 0),
                Data      => q_and.data_wr,
                WE        => q_and.wr_en,
                RdClock   => clk_100,
                RdClockEn => '1',
                Reset     => rst,
                WrClock   => rx_pclk_1,
                WrClockEn => '1',
                --! TODO: remove temporary data
                Q         => mem_data_out_rx --d_cntr.d_mem_data_in
            );

    end generate;

    pcs2_generate : if (PCS_2_ENABLE) generate
        pcs_inst_2 : entity work.pcs_pci_tx
        port map (

            hdinn           => pcie_down_n,
            hdinp           => pcie_down_p,
            rxrefclk        => refclk,
            rx_pclk         => rx_pclk_2,
            rxdata          => rxdata_2,
            rx_k            => rx_k_2,
            rxstatus0       => rxstatus1,
            pcie_det_en_c   => '1',
            pcie_ct_c       => '0',
            signal_detect_c => '1',
            pcie_done_s     => open,
            pcie_con_s      => open,
            rx_los_low_s    => open, --rx_los_low,
            lsm_status_s    => lsm_status_s_2,
            rx_cdr_lol_s    => rx_cdr_lol_s_2,
            rx_pcs_rst_c    => rst,
            rx_serdes_rst_c => rst,
            rx_pwrup_c      => '1',
            rst_dual_c      => rst,
            serdes_rst_dual_c => rst,
            serdes_pdb      => '1'
        );

        lfsr_scrambler_inst_2 : entity work.lfsr_scrambler
        port map (
            rst             => rst,
            clk             => rx_pclk_2,
            data_in         => rxdata_2,
            rx_k            => rx_k_2(0),
            data_out        => scr_data_2,
            rx_k_out        => rx_k_2d
        );

        d_anu.data_in_scr <= scr_data_1;
        d_anu.rx_k <= rx_k_1d;

        d_anu.trigger_start <= trigger_resync(1);--q_cntr.trigger_start;
--      d_anu.trigger_stop <= q_cntr.trigger_stop;

        analyzer_up_inst : entity  work.analyzer
        port map (
            clk             => rx_pclk_2,
            rst             => rst,
            d               => d_anu,
            q               => q_anu
        ); 

        packet_memory_up_inst : entity work.packet_ram
            port map(
                WrAddress => q_anu.addr_wr(14 downto 0),
                RdAddress => q_cntr.addr_read(14 downto 0),
                Data      => q_anu.data_wr,
                WE        => q_anu.wr_en,
                RdClock   => clk_100,
                RdClockEn => '1',
                Reset     => rst,
                WrClock   => rx_pclk_2,
                WrClockEn => '1',
                Q         => mem_data_out_tx --d_cntr.u_mem_data_in
            );
    end generate;

    pulse_filt_inst : entity work.pulse_filt
        generic map(
            FILT_LEN => 8
        )
        port map(
            clk          => rx_pclk_1,
            rst          => rst,
            filt_len_sel => X"20",
            x            => not gsrn,
            y            => button
        );

--  data_addr_1 <= q_and.addr_wr;
--  data_addr_2 <= q_anu.addr_wr;
--
--  data_wr_1 <= q_and.wr_en;
--  data_wr_2 <= q_anu.wr_en;

    spi_slave_inst : entity work.SPI_SLAVE
        generic map(
            WORD_SIZE => SPI_WORD_SIZE
        )
        port map(
            CLK      => clk_100,
            RST      => rst,
            SCLK     => sclk,
            CS_N     => cs_n,
            MOSI     => mosi,
            MISO     => miso,
            DIN      => q_cntr.data_out,
            DIN_VLD  => q_cntr.data_out_vld,
            DIN_RDY  => d_cntr.data_out_rdy,
            DOUT     => d_cntr.data_in,
            DOUT_VLD => d_cntr.data_in_vld,
            CS_N_OUT => d_cntr.cs_n
        );

--  d_cntr.data_amount_1 <= q_and.data_amount;
--  d_cntr.data_amount_2 <= q_and.data_amount;
    d_cntr.mem_data_in <= mem_data_out_rx when q_cntr.mem_select = '0' else mem_data_out_tx;

    controller_inst : entity work.controller
        port map(
            clk => clk_100,
            rst => rst,
            d   => d_cntr,
            q   => q_cntr
        );

    d_ra.button <= button;
    d_ra.stop_trigger <= q_and.stop_trigger;
    d_ra.data_in_rx <= mem_data_out_rx;
    d_ra.data_in_tx <= mem_data_out_tx;

    rev_analyzer_inst : entity work.rev_analyzer
        port map(
            clk => clk_100,
            rst => rst,
            d   => d_ra,
            q   => q_ra
        );

    rst <= not (pll_lock and switch(7));
    reg_process : process (clk_100) is
    begin
        if rising_edge(clk_100) then
--          if reset_delay_count = C_PWRUP_RESET_DELAY then
--              rst <= '0';
--          else
--              rst <= '1';
--              reset_delay_count <= std_logic_vector(unsigned(reset_delay_count) + 1);
--          end if;

            d_and.trigger_set.packet_type_en <= '0';
            d_and.trigger_set.packet_type <= TLP_PKT;
            d_and.trigger_set.tlp_type_en <= '1';
            d_and.trigger_set.tlp_type <= NO_PCK;
            d_and.trigger_set.dllp_type_en <= '0';
            d_and.trigger_set.dllp_type <= NO_PCK;
            d_and.trigger_set.order_set_en <= '0';
            d_and.trigger_set.order_set_type <= NO_PCK;
            d_and.trigger_set.addr_match_en <= '0';
            d_and.trigger_set.addr_match <= (others => '0');
            d_and.filter_in.tlp_save <= '1';
            d_and.filter_in.order_set_save <= '1';
            d_and.filter_in.dllp_save <= '1';

            d_anu.trigger_set.packet_type_en <= '0';
            d_anu.trigger_set.packet_type <= TLP_PKT;
            d_anu.trigger_set.tlp_type_en <= '1';
            d_anu.trigger_set.tlp_type <= NO_PCK;
            d_anu.trigger_set.dllp_type_en <= '0';
            d_anu.trigger_set.dllp_type <= NO_PCK;
            d_anu.trigger_set.order_set_en <= '0';
            d_anu.trigger_set.order_set_type <= NO_PCK;
            d_anu.trigger_set.addr_match_en <= '0';
            d_anu.trigger_set.addr_match <= (others => '0');
            d_anu.filter_in.tlp_save <= '1';
            d_anu.filter_in.order_set_save <= '0';
            d_anu.filter_in.dllp_save <= '0';

            trigger_stop(0) <= q_and.stop_trigger;
            trigger_stop(1) <= trigger_stop(0);

--          data_ch_1 <= mem_data_out_rx(34 downto 27) & mem_data_out_rx(25 downto 18) & mem_data_out_rx(16 downto 9) & mem_data_out_rx(7 downto 0);
--          data_ch_2 <= mem_data_out_tx(34 downto 27) & mem_data_out_tx(25 downto 18) & mem_data_out_tx(16 downto 9) & mem_data_out_tx(7 downto 0);
--          timestamp_r <= mem_data_out_rx(35) & mem_data_out_tx(35);
--          data_out_o <= data_ch_1;
--          data_out_i <= data_ch_2;
--          timestamp <= timestamp_r;
        end if;
    end process;

    resync_process : process (rx_pclk_1) is
    begin
        if rising_edge (rx_pclk_1) then
            trigger_resync(0) <= q_ra.trigger_ena;
            trigger_resync(1) <= trigger_resync(0);
        end if;
    end process;
end architecture RTL;
