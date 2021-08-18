--------------------------------------------------------------------------------
-- Entity: pcie_tb
-- Date:10/09/2018
-- Author: GRPA
--
-- Description:
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

use work.top_pkg.all;
use work.pcie_tx_engine_pkg.all;
use work.pcie_rx_engine_pkg.all;
use work.pci_wrapper_pkg.all;
use work.pci_core_wrapper_pkg.all;

library ecp5u;
use ecp5u.components.all;

library ovi_ecp5u;
use ovi_ecp5u.all;

--library aldec;
--use aldec.aldec_tools.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

--library modelsim_lib;
--use modelsim_lib.util.all;

entity bp_x86_tb is
    generic (runner_cfg : string);
end bp_x86_tb;

architecture arch of bp_x86_tb is

    -- PCIExpress internal interface

    signal tlp_rx_q     : t_rx_tlp_intf_q;

    signal pcie_rxn, pcie_rxp, pcie_txn, pcie_txp : std_logic;
    signal root_pcie_rxn            : std_logic;
    signal root_pcie_rxp            : std_logic;
    signal root_pcie_txn            : std_logic;
    signal root_pcie_txp            : std_logic;

    signal rst                      :  std_logic;


    signal clk_25, ioclk            : std_logic;
    signal clk_100                  : std_logic;
    signal clk_150                  : std_logic;
    signal timer                    : std_logic;
    signal sync                     : std_logic;
    signal io_no_pcie_train         : std_logic;
    signal refclk                   : std_logic;

    signal npd_processed            : std_logic;
    signal nph_processed            : std_logic;
    signal npd_num_vc0              : std_logic_vector (7 downto 0);
    signal np_req_pend              : std_logic;

    signal rx_k                         : std_logic_vector (0 downto 0);
    signal rxdata                       : std_logic_vector (7 downto 0);
    signal rx_pclk                      : std_logic;
    signal scram_rst                    : std_logic;
    signal scram_en                     : std_logic;

    signal in_tlp                       : t_tx_tlp_intf_d;
    signal out_tlp                      : t_tx_tlp_intf_q;

    signal d_pci                        : t_pci_core_wrapper_in;
    signal q_pci                        : t_pci_core_wrapper_out;

    signal d_pci_ep                     : t_pci_core_wrapper_in;
    signal q_pci_ep                     : t_pci_core_wrapper_out;

    -- component for Power Up Set/Reset; Set/Reset interface
    component pur is
    generic(
      rst_pulse       : integer := 1);
    port(
      pur             : in std_logic);
    end component;

    component gsr is
    port(
        GSR             : in std_logic);
    end component;

begin
    
    --asdb_dump("/bp_x86_tb/BP_x86_inst/dma_table_inst/DataInA");

    main : process
    begin
        test_runner_setup (runner, runner_cfg);
        if run("wait for pcie link up") then
            wait until q_pci.phy.phy_ltssm_state = "0010";
            report "PCIExpress link ok";
            wait until stim_file_read_done = true;
            report "END OF FILE";
        end if;
        test_runner_cleanup(runner);
    end process;

  ------------------------------------
    -- instantiation of GSR and PUR
    GSR_INST: GSR port map (GSR=>not rst);
    PUR_INST : PUR
    generic map (RST_PULSE => 1)
    port map (PUR =>not rst);
    ------------------------------------

    clk_25_porcess : process is
    begin
        clk_25 <= '0';
        wait for 20 ns;
        clk_25 <= '1';
        wait for 20 ns;
    end process;

    ----------------------------------------------------------------------------
    -- PCIExpress clock generating
    ----------------------------------------------------------------------------
    refclk_process : process is
    begin
        refclk <= '0';
        wait for 5 ns;
        refclk <= '1';
        wait for 5 ns;
    end process;

    rst_process : process is
    begin
        rst <= '0';
        wait for 300 ns;
        rst <= '1';
        wait for 100 ns;
        wait;
    end process;

    clk_150_process :process
    begin
        clk_150 <= '1';
        wait for 3.333 ns;
        clk_150 <= '0';
        wait for 3.333 ns;
    end process;

    clk_100_process :process
    begin
        clk_100 <= '1';
        wait for 5 ns;
        clk_100 <= '0';
        wait for 5 ns;
    end process;

    clk_1Mhz : process
    begin
        timer <= '0';
        wait for 800 ns;
        timer <= '0';
        wait until clk_100 = '1';
        timer <= '1';
        wait until clk_100 = '1';
        timer <= '0';
    end process;

    sync_process : process
    begin
        sync <= '1';
        wait for 0.5 us;
        sync <= '0';
        wait for 0.5 us;
    end process;


--------------------------------------------------------------------------------
-- forcing signals for link_up
--------------------------------------------------------------------------------
--  io_pcie_signals_forcing : process
--  begin
--      wait until rst = '1';
--      wait for 300 ns;
--      force_signal ("deposit", "/bp_x86_tb/pcie_inst/pci_core_inst/u1_pcs_pipe/pcie_ip_rstn", "2#1");
--      force_signal ("deposit", "/bp_x86_tb/bp_x86_inst/pcie_core_wrapper_inst/pci_core_inst/u1_pcs_pipe/pcie_ip_rstn", "2#1");
--      wait for 350 ns;
--      force_signal ("deposit", "/bp_x86_tb/pcie_inst/pci_core_inst/u1_pcs_pipe/ffs_pcie_con_0", "2#1");
--      force_signal ("deposit", "/bp_x86_tb/bp_x86_inst/pcie_core_wrapper_inst/pci_core_inst/u1_pcs_pipe/ffs_pcie_con_0", "2#1");
--      wait;
--  end process;
--
--
--  force_signal ("freeze", "/bp_x86_tb/pcie_inst/pci_core_inst/u1_pcs_pipe/pcs_top_0/sll_inst/LRCLK_TC_w", "16#64");
--  force_signal ("freeze", "/bp_x86_tb/pcie_inst/pci_core_inst/u1_pcs_pipe/pcs_top_0/sll_inst/rcount_tc" , "10#250");
--
--  force_signal ("freeze", "/bp_x86_tb/bp_x86_inst/pcie_core_wrapper_inst/pci_core_inst/u1_pcs_pipe/pcs_top_0/sll_inst/LRCLK_TC_w", "16#64");
--  force_signal ("freeze", "/bp_x86_tb/bp_x86_inst/pcie_core_wrapper_inst/pci_core_inst/u1_pcs_pipe/pcs_top_0/sll_inst/rcount_tc", "10#250");

--------------------------------------------------------------------------------


--******************************************************************************
-- PCIExpress core for test generating
--------------------------------------------------------------------------------

    root_pcie_rxn <= '1' when pcie_txn = '1' else
        '0' when pcie_txn = '0' else 'H';
    root_pcie_rxp <= '1' when pcie_txp = '1' else
        '0' when pcie_txp = '0' else 'H';

    pcie_rxn <= '1' when root_pcie_txn = '1' else
        '0' when root_pcie_txn = '0' else 'H';
    pcie_rxp <= '1' when root_pcie_txp = '1' else
        '0' when root_pcie_txp = '0' else 'H';

    pcie_inst_root: entity work.pci_core_wrapper
    port map (
        pll_refclki         => refclk,
        rxrefclk            => refclk,
        no_pcie_train       => io_no_pcie_train,
        pci_core_hdinn0     => root_pcie_rxn,
        pci_core_hdinp0     => root_pcie_rxp,

        pci_core_hdoutn0    => root_pcie_txn,
        pci_core_hdoutp0    => root_pcie_txp,

        pci_rst_n           => rst,
        sli_rst             => '0',
        sys_clk_125         => ioclk,

        d                   => d_pci,
        q                   => q_pci
    );

    pcie_inst_ep: entity work.pci_core_wrapper
    port map (
        pll_refclki         => refclk,
        rxrefclk            => refclk,
        no_pcie_train       => io_no_pcie_train,
        pci_core_hdinn0     => pcie_rxn,
        pci_core_hdinp0     => pcie_rxp,

        pci_core_hdoutn0    => pcie_txn,
        pci_core_hdoutp0    => pcie_txp,

        pci_rst_n           => rst,
        sli_rst             => '0',
        sys_clk_125         => ioclk,

        d                   => d_pci_ep,
        q                   => q_pci_ep
    );





--  pcs_inst : entity work.pcs_pci
--  port map (
--      hdinn           => pcie_rxn,
--      hdinp           => pcie_rxp,
--      rst_dual_c      => not rst,
--      rx_pcs_rst_c    => not rst,
--      rx_pwrup_c      => '1',
--      rx_serdes_rst_c => not rst,
--      rxrefclk        => refclk,--clk,
--      serdes_pdb      => '1',
--      serdes_rst_dual_c => not rst,
--      signal_detect_c => '0',
--      rx_cdr_lol_s    => open,
--      rx_k            => rx_k,
--      rx_pclk         => rx_pclk,
--      rxdata          => rxdata
--  );
--
--  scram_rst <= '1' when rx_k(0) = '1' and rxdata = X"BC" else '0';
--  scram_en <= '0' when rx_k(0) = '1' and rxdata = X"BC" else
--              '0' when rx_k(0) = '1' and rxdata =X"1C" else
--              '1';
--  lfsr_scrambler_inst : entity work.lfsr_scrambler
--  port map (
--      data_in         => rxdata,
--      rx_k            => rx_k(0),
--      scram_en        => scram_en,
--      scram_rst       => scram_rst,
--      rst             => not rst,
--      clk             => rx_pclk,
--      data_out        => open
--  );
end arch;

