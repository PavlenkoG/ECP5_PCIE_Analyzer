library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.analyzer_pkg.all;
use work.controller_pkg.all;

entity top is
    port(
        clk_in          : in std_logic;
        rst             : in std_logic;

        pcie_up_n       : in std_logic;
        pcie_up_p       : in std_logic;
        pcie_down_n     : in std_logic;
        pcie_down_p     : in std_logic;

        -- spi slave interface
        sclk            : in std_logic;
        cs_n            : in std_logic;
        mosi            : in std_logic;
        miso            : out std_logic
    );
end top;

architecture RTL of top is
    constant SPI_WORD_SIZE     : integer := 8;

    signal clk_100              : std_logic;

    signal rx_k_1              : std_logic_vector (0 downto 0);
    signal rx_k_2              : std_logic_vector (0 downto 0);
    signal rx_pclk_1           : std_logic;
    signal rx_pclk_2           : std_logic;
    signal rxdata_1            : std_logic_vector (7 downto 0);
    signal rxdata_2            : std_logic_vector (7 downto 0);
    signal rxstatus_1          : std_logic_vector (2 downto 0);
    signal pcie_done_s_1       : std_logic;
    signal pcie_cone_s_1       : std_logic;
    signal lsm_status_s_1      : std_logic;
    signal rx_cdr_lol_s_1      : std_logic;
    
    signal scram_rst_1         : std_logic;
    signal scram_rst_2         : std_logic;
    signal scram_en_1          : std_logic;
    signal scram_en_2          : std_logic;

    signal d_and                : t_analyzer_in;
    signal q_and                : t_analyzer_out;

    signal d_anu                : t_analyzer_in;
    signal q_anu                : t_analyzer_out;

    signal data_addr_1          : std_logic_vector (14 downto 0);
    signal data_addr_2          : std_logic_vector (14 downto 0);
    signal data_ch_1            : std_logic_vector (31 downto 0);
    signal data_ch_2            : std_logic_vector (31 downto 0);
    signal data_wr_1            : std_logic;
    signal data_wr_2            : std_logic;

    -- spi user interface
    signal din                  : std_logic_vector (SPI_WORD_SIZE - 1 downto 0);
    signal din_vld              : std_logic;
    signal din_rdy              : std_logic;
    signal dout                 : std_logic_vector (SPI_WORD_SIZE - 1 downto 0);
    signal dout_vld             : std_logic;

    signal d_cntr               : t_controller_in;
    signal q_cntr               : t_controller_out;


begin

    pcs_inst_1 : entity work.pcs_pci
    port map (
        hdinn           => pcie_up_n,
        hdinp           => pcie_up_p,
        rxrefclk        => clk_in,
        rst_dual_c      => rst,
        rx_pcs_rst_c    => rst,
        rx_pwrup_c      => '1',
        rx_serdes_rst_c => rst,
        serdes_pdb      => '1',
        serdes_rst_dual_c => rst,
        signal_detect_c => '0',
        rx_cdr_lol_s    => rx_cdr_lol_s_1,
        rx_k            => rx_k_1,
        rx_pclk         => rx_pclk_1,
        rxdata          => rxdata_1,
        rxstatus0       => rxstatus_1,
        pcie_det_en_c   => '1',
        pcie_ct_c       => '0',
        pcie_done_s     => pcie_done_s_1,
        pcie_con_s      => pcie_cone_s_1,
        lsm_status_s    => lsm_status_s_1
    );

    pcs_inst_2 : entity work.pcs_pci
    port map (
        hdinn           => pcie_down_n,
        hdinp           => pcie_down_p,
        rst_dual_c      => rst,
        rx_pcs_rst_c    => rst,
        rx_pwrup_c      => '1',
        rx_serdes_rst_c => rst,
        rxrefclk        => clk_in,
        serdes_pdb      => '1',
        serdes_rst_dual_c => rst,
        signal_detect_c => '0',
        rx_cdr_lol_s    => open,
        rx_k            => rx_k_2,
        rx_pclk         => rx_pclk_2,
        rxdata          => rxdata_2,
        rxstatus0       => open,
        pcie_det_en_c   => '1',
        pcie_ct_c       => '1',
        pcie_done_s     => open,
        pcie_con_s      => open,
        lsm_status_s    => open
    );

    lfsr_scrambler_inst_1 : entity work.lfsr_scrambler
    port map (
        rst             => rst,
        clk             => rx_pclk_1,
        data_in         => rxdata_1,
        rx_k            => rx_k_1(0),
        data_out        => d_and.data_in_scr,
        rx_k_out        => d_and.rx_k
    );

    lfsr_scrambler_inst_2 : entity work.lfsr_scrambler
    port map (
        rst             => rst,
        clk             => rx_pclk_2,
        data_in         => rxdata_2,
        rx_k            => rx_k_2(0),
        data_out        => d_anu.data_in_scr,
        rx_k_out        => d_anu.rx_k
    );

    analyzer_down_inst : entity  work.analyzer
    port map (
        clk             => rx_pclk_1,
        rst             => rst,
        d               => d_and,
        q               => q_and
    ); 

    packet_memory_down_inst : entity work.packet_ram
        port map(
            WrAddress => q_and.addr_wr,
            RdAddress => q_cntr.d_addr_read,
            Data      => q_and.data_wr,
            WE        => q_and.wr_en,
            RdClock   => clk_100,
            RdClockEn => '1',
            Reset     => rst,
            WrClock   => rx_pclk_1,
            WrClockEn => '1',
            Q         => d_cntr.d_mem_data_in
        );

    analyzer_up_inst : entity  work.analyzer
    port map (
        clk             => rx_pclk_2,
        rst             => rst,
        d               => d_anu,
        q               => q_anu
    ); 

    packet_memory_up_inst : entity work.packet_ram
        port map(
            WrAddress => q_anu.addr_wr,
            RdAddress => q_cntr.u_addr_read,
            Data      => q_anu.data_wr,
            WE        => q_anu.wr_en,
            RdClock   => clk_100,
            RdClockEn => '1',
            Reset     => rst,
            WrClock   => rx_pclk_2,
            WrClockEn => '1',
            Q         => d_cntr.u_mem_data_in
        );

    data_addr_1 <= q_and.addr_wr;
    data_addr_2 <= q_anu.addr_wr;
    data_ch_1 <= q_and.data_wr(34 downto 27) & q_and.data_wr(25 downto 18) & q_and.data_wr(16 downto 9) & q_and.data_wr(7 downto 0);
    data_ch_2 <= q_anu.data_wr(34 downto 27) & q_anu.data_wr(25 downto 18) & q_anu.data_wr(16 downto 9) & q_anu.data_wr(7 downto 0);
    data_wr_1 <= q_and.wr_en;
    data_wr_2 <= q_anu.wr_en;

    spi_slave_inst : entity work.SPI_SLAVE
        generic map(
            WORD_SIZE => SPI_WORD_SIZE
        )
        port map(
            CLK      => rx_pclk_2,--clk_100,
            RST      => rst,
            SCLK     => sclk,
            CS_N     => cs_n,
            MOSI     => mosi,
            MISO     => miso,
            DIN      => q_cntr.data_out,
            DIN_VLD  => q_cntr.data_out_vld,
            DIN_RDY  => d_cntr.data_out_rdy,
            DOUT     => d_cntr.data_in,
            DOUT_VLD => d_cntr.data_in_vld
        );

    controller_inst : entity work.controller
        port map(
            clk => rx_pclk_2,
            rst => rst,
            d   => d_cntr,
            q   => q_cntr
        );
end architecture RTL;
