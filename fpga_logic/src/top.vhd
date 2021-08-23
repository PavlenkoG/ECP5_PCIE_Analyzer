library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.analyzer_pkg.all;

entity top is
    port(
        clk_in          : in std_logic;
        rst             : in std_logic;

        pcie_up_n       : in std_logic;
        pcie_up_p       : in std_logic;
        pcie_down_n     : in std_logic;
        pcie_down_p     : in std_logic
    );
end top;

architecture RTL of top is

    signal rx_k_1              : std_logic_vector (0 downto 0);
    signal rx_k_2              : std_logic_vector (0 downto 0);
    signal rx_pclk_1           : std_logic;
    signal rx_pclk_2           : std_logic;
    signal rxdata_1            : std_logic_vector (7 downto 0);
    signal rxdata_2            : std_logic_vector (7 downto 0);
    
    signal scram_rst_1         : std_logic;
    signal scram_rst_2         : std_logic;
    signal scram_en_1          : std_logic;
    signal scram_en_2          : std_logic;

    signal d_and                : t_analyzer_in;
    signal q_and                : t_analyzer_out;

    signal d_anu                : t_analyzer_in;
    signal q_anu                : t_analyzer_out;

begin

    pcs_inst_1 : entity work.pcs_pci
    port map (
        hdinn           => pcie_up_n,
        hdinp           => pcie_up_p,
        rst_dual_c      => rst,
        rx_pcs_rst_c    => rst,
        rx_pwrup_c      => '1',
        rx_serdes_rst_c => rst,
        rxrefclk        => clk_in,
        serdes_pdb      => '1',
        serdes_rst_dual_c => rst,
        signal_detect_c => '0',
        rx_cdr_lol_s    => open,
        rx_k            => rx_k_1,
        rx_pclk         => rx_pclk_1,
        rxdata          => rxdata_1
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
        rxdata          => rxdata_2
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

    analyzer_up_inst : entity  work.analyzer
    port map (
        clk             => rx_pclk_2,
        rst             => rst,
        d               => d_anu,
        q               => q_anu
    ); 
end architecture RTL;
