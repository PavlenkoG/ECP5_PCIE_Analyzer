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
use work.analyzer_tb_pkg.all;

library ecp5u;
use ecp5u.components.all;

library ovi_ecp5u;
use ovi_ecp5u.all;

library aldec;
use aldec.aldec_tools.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

--library modelsim_lib;
--use modelsim_lib.util.all;

entity analyzer_tb is
    generic (runner_cfg : string);
end analyzer_tb;

architecture arch of analyzer_tb is

    -- PCIExpress internal interface

    signal tlp_rx_q     : t_rx_tlp_intf_q;

    signal pcie_rxn, pcie_rxp, pcie_txn, pcie_txp : std_logic;
    signal root_pcie_rxn            : std_logic;
    signal root_pcie_rxp            : std_logic;
    signal root_pcie_txn            : std_logic;
    signal root_pcie_txp            : std_logic;

    signal rst                      :  std_logic;


    signal clk_25                   : std_logic;
    signal ioclk1                   : std_logic;
    signal ioclk2                   : std_logic;
    signal clk_100                  : std_logic;
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

    signal payload                      : payload_t;
    signal addr                         : std_logic_vector (31 downto 0);
    signal len                          : integer;
    signal tb_end                       : boolean := false;

    signal sclk                         : std_logic;
    signal miso                         : std_logic;
    signal mosi                         : std_logic;
    signal spi_cs                       : std_logic;
    signal spi_data_in                  : payload_t;

    signal gsrn                         : std_logic;

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
    
    asdb_dump("/analyzer_tb/dut/pcie_up_n");
    asdb_dump("/analyzer_tb/dut/pcie_up_p");
    asdb_dump("/analyzer_tb/dut/clk_100");
    asdb_dump("/analyzer_tb/dut/clk_lvds");
    asdb_dump("/analyzer_tb/dut/clk_100_n");
    asdb_dump("/analyzer_tb/dut/clk_100_p");
    asdb_dump("/analyzer_tb/dut/rst");
--  asdb_dump("/analyzer_tb/dut/rx_k_1");
    asdb_dump("/analyzer_tb/dut/rx_pclk_1");
--  asdb_dump("/analyzer_tb/dut/rxdata_1");
--  asdb_dump("/analyzer_tb/dut/rx_cdr_lol_s_1");


    asdb_dump("/analyzer_tb/dut/pcs1_generate/analyzer_down_inst/d");
    asdb_dump("/analyzer_tb/dut/pcs1_generate/analyzer_down_inst/q");
    asdb_dump("/analyzer_tb/dut/pcs1_generate/analyzer_down_inst/r");
  
--  asdb_dump("/analyzer_tb/dut/analyzer_up_inst/d");
--  asdb_dump("/analyzer_tb/dut/analyzer_up_inst/q");
--  asdb_dump("/analyzer_tb/dut/analyzer_up_inst/r");
--
--  asdb_dump("/analyzer_tb/dut/data_addr_1");
--  asdb_dump("/analyzer_tb/dut/data_ch_1");
--  asdb_dump("/analyzer_tb/dut/data_wr_1");
--  asdb_dump("/analyzer_tb/dut/data_addr_2");
--  asdb_dump("/analyzer_tb/dut/data_ch_2");
--  asdb_dump("/analyzer_tb/dut/data_wr_2");
--
--  asdb_dump("/analyzer_tb/dut/spi_slave_inst/clk");
--  asdb_dump("/analyzer_tb/dut/spi_slave_inst/sclk");
--  asdb_dump("/analyzer_tb/dut/spi_slave_inst/cs_n");
--  asdb_dump("/analyzer_tb/dut/spi_slave_inst/mosi");
--  asdb_dump("/analyzer_tb/dut/spi_slave_inst/miso");
--  asdb_dump("/analyzer_tb/dut/spi_slave_inst/din");
--  asdb_dump("/analyzer_tb/dut/spi_slave_inst/din_vld");
--  asdb_dump("/analyzer_tb/dut/spi_slave_inst/din_rdy");
--  asdb_dump("/analyzer_tb/dut/spi_slave_inst/dout");
--  asdb_dump("/analyzer_tb/dut/spi_slave_inst/dout_vld");
--  asdb_dump("/analyzer_tb/spi_data_in");

    asdb_dump("/analyzer_tb/dut/controller_inst/d");
    asdb_dump("/analyzer_tb/dut/controller_inst/q");
    asdb_dump("/analyzer_tb/dut/controller_inst/r");

    asdb_dump("/analyzer_tb/dut/rev_analyzer_inst/d");
    asdb_dump("/analyzer_tb/dut/rev_analyzer_inst/q");
    asdb_dump("/analyzer_tb/dut/rev_analyzer_inst/r");

--  asdb_dump("/analyzer_tb/dut/trigger_ena");
--  asdb_dump("/analyzer_tb/dut/trigger_resync");
--  asdb_dump("/analyzer_tb/dut/trigger_stop");
--  asdb_dump("/analyzer_tb/dut/button");
--  asdb_dump("/analyzer_tb/dut/rd_addr");
--  asdb_dump("/analyzer_tb/dut/data_ch_1");



    

    main : process
    begin
        test_runner_setup (runner, runner_cfg);
--      if run("wait for pcie link up") then
--          wait until q_pci.phy.phy_ltssm_state = "0010";
--          report "PCIExpress link ok";
--          wait for 10 ns;
--      end if;
        if run ("wait for data transfer") then
            wait until tb_end = true;
            report "all data was transferred";
            wait for 10 ns;
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

    clk_100_process : process is
    begin
        clk_100 <= '1';
        wait for 5 ns;
        clk_100 <= '0';
        wait for 5 ns;
    end process;

    btn_process : process is
    begin
        gsrn <= '0';
        wait for 6 us;
        gsrn <= '1';
        wait for 5 us;
        gsrn <= '0';
        wait for 18 us;
        gsrn <= '1';
        wait for 1 us;
        gsrn <= '0';
        wait for 6 us;
        gsrn <= '1';
        wait for 5 us;
        gsrn <= '0';
        wait;
    end process;
--------------------------------------------------------------------------------
-- forcing signals for link_up
--------------------------------------------------------------------------------
    io_pcie_signals_forcing : process
    begin
        wait until rst = '1';
        wait for 300 ns;
        force_signal ("deposit", "/analyzer_tb/pcie_inst_root/pci_core_inst/u1_pcs_pipe/pcie_ip_rstn", "2#1");
        force_signal ("deposit", "/analyzer_tb/pcie_inst_ep/pci_core_inst/u1_pcs_pipe/pcie_ip_rstn", "2#1");
        wait for 350 ns;
        force_signal ("deposit", "/analyzer_tb/pcie_inst_root/pci_core_inst/u1_pcs_pipe/ffs_pcie_con_0", "2#1");
        force_signal ("deposit", "/analyzer_tb/pcie_inst_ep/pci_core_inst/u1_pcs_pipe/ffs_pcie_con_0", "2#1");
        wait;
    end process;
  
  
    force_signal ("freeze", "/analyzer_tb/pcie_inst_root/pci_core_inst/u1_pcs_pipe/pcs_top_0/sll_inst/LRCLK_TC_w", "16#64");
    force_signal ("freeze", "/analyzer_tb/pcie_inst_root/pci_core_inst/u1_pcs_pipe/pcs_top_0/sll_inst/rcount_tc" , "10#250");
  
    force_signal ("freeze", "/analyzer_tb/pcie_inst_ep/pci_core_inst/u1_pcs_pipe/pcs_top_0/sll_inst/LRCLK_TC_w", "16#64");
    force_signal ("freeze", "/analyzer_tb/pcie_inst_ep/pci_core_inst/u1_pcs_pipe/pcs_top_0/sll_inst/rcount_tc", "10#250");

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- this process reads data from stimuli file and generates
-- tlp packets for PCIExpress core
--------------------------------------------------------------------------------
    test_process : process is
    begin

        in_tlp.tx_data_vc0 <= (others => '0');
        in_tlp.tx_end_vc0 <= '0';
        in_tlp.tx_nlfy_vc0 <= '0';
        in_tlp.tx_req_vc0 <= '0';
        in_tlp.tx_st_vc0 <= '0';
        io_no_pcie_train <= '0';

        sclk <= '0';
        spi_cs <= '1';
        miso <= 'Z';
        mosi <= 'Z';
        tb_end <= false;

        force_signal ("deposit", "/analyzer_tb/dut/analyzer_down_inst/d.trigger_start", "2#1");
        force_signal ("deposit", "/analyzer_tb/dut/analyzer_down_inst/d.filter_in.tlp_save", "2#1");
        force_signal ("deposit", "/analyzer_tb/dut/analyzer_down_inst/d.filter_in.dllp_save", "2#1");
--      force_signal ("deposit", "/analyzer_tb/dut/analyzer_down_inst/d.filter_in.order_set_save", "2#1");

        force_signal ("deposit", "/analyzer_tb/dut/analyzer_up_inst/d.trigger_start", "2#1");
        force_signal ("deposit", "/analyzer_tb/dut/analyzer_up_inst/d.filter_in.tlp_save", "2#1");
        force_signal ("deposit", "/analyzer_tb/dut/analyzer_up_inst/d.filter_in.dllp_save", "2#1");
--      force_signal ("deposit", "/analyzer_tb/dut/analyzer_up_inst/d.filter_in.order_set_save", "2#1");

        force_signal ("deposit", "/analyzer_tb/pcie_inst_ep/pci_core_inst/u1_dut/no_pcie_train", "2#0");

        wait until q_pci.phy.phy_ltssm_state = "0010";
        io_no_pcie_train <= '1';
        force_signal ("deposit", "/analyzer_tb/pcie_inst_ep/pci_core_inst/u1_dut/no_pcie_train", "2#1");
        wait until q_pci.data_link.dl_active = '1';
        len <= 16;
        wait for 1 us;

        wait for 10 ns;
--      force_signal ("deposit", "/analyzer_tb/dut/analyzer_down_inst/d.trigger_start", "2#0");
--      force_signal ("deposit", "/analyzer_tb/dut/analyzer_up_inst/d.trigger_start", "2#0");


--      force_signal ("deposit", "/analyzer_tb/dut/analyzer_down_inst/r.data_amount", "16#7F00");
--
--      for i in 0 to 10 loop
--          w_pci (ioclk1, addr, len, payload, out_tlp, in_tlp);
--          addr <= X"70010100";
--          wait for 25 ns;
--      end loop;
        payload(0) <= X"01";
        spi_test(freq => 62, clk => sclk, miso => miso, mosi => mosi, cs => spi_cs, data_in => payload, data_out => spi_data_in, len => 1);

        wait for 5 us;
        for i in 0 to 127 loop
            payload(i) <= std_logic_vector(to_unsigned(i,8));
        end loop;

        len <= 128;
        addr <= X"70010000";

        for i in 0 to 10 loop
            w_pci (ioclk1, addr, len, payload, out_tlp, in_tlp);
            addr <= X"70010100";
            wait for 25 ns;
        end loop;

--      payload(0) <= X"02";
--      spi_test(freq => 62, clk => sclk, miso => miso, mosi => mosi, cs => spi_cs, data_in => payload, data_out => spi_data_in, len => 1);
--      wait for 5 us;
--
--      payload(0) <= X"03";
--      payload(1) <= X"00";
--      payload(2) <= X"00";
--      wait for 2 us;
--      spi_test(freq => 62, clk => sclk, miso => miso, mosi => mosi, cs => spi_cs, data_in => payload, data_out => spi_data_in, len => 35);
        wait for 11 us;
        tb_end <= true;

        wait;
    end process;

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

    out_tlp <= q_pci.tx_tlp;
    d_pci.tx_tlp <= in_tlp;

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
        sys_clk_125         => ioclk1,

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
        sys_clk_125         => ioclk2,

        d                   => d_pci_ep,
        q                   => q_pci_ep
    );

    dut : entity work.top
        generic map (
            PCS_1_ENABLE    => true,
            PCS_2_ENABLE    => false
        )
        port map (
            clk_100_p       => clk_100,
            clk_100_n       => not clk_100,

            pcie_clk_n      => '0',
            pcie_clk_p      => '0',
            pcie_up_n       => pcie_rxn,
            pcie_up_p       => pcie_rxp,
            pcie_down_n     => pcie_txn,
            pcie_down_p     => pcie_txp,

            sclk            => sclk,
            cs_n            => spi_cs,
            mosi            => mosi,
            miso            => miso,
            
            gsrn            => gsrn,
            los             => (others => '0'),
            disable1        => open,
            disable2        => open,
            disable3        => open,
            data_out_o      => open,
            led             => open,
            seg             => open,
            switch          => (others => '1')
        );

    -- process check write address
    check_write_addr_up_process: process is
       alias addr_wr      is <<signal analyzer_tb.dut.data_addr_1 : std_logic_vector(14 downto 0)>>; 
       alias data_up      is <<signal analyzer_tb.dut.data_ch_1   : std_logic_vector(31 downto 0)>>;
       alias wr_en        is <<signal analyzer_tb.dut.data_wr_1   : std_logic>>;
       alias clk          is <<signal analyzer_tb.dut.rx_pclk_1   : std_logic>>;
       variable cnt     : std_logic_vector (14 downto 0) := (0 => '1', others => '0');
    begin

        wait until clk = '1';
        if wr_en = '1' then
            --report "address to write is " & integer'image(to_integer(unsigned(addr_wr))) severity note;
            assert cnt /= addr_wr report "addres to write (" & integer'image(to_integer(unsigned(addr_wr))) & ") doesn't match to calculated address " & integer'image(to_integer(unsigned(cnt))) severity warning;
        end if;
        cnt := std_logic_vector(unsigned(cnt) + 1);
    end process;

    check_wirte_addr_down_process: process is
       alias addr_wr      is <<signal analyzer_tb.dut.data_addr_2   : std_logic_vector(14 downto 0)>>; 
       alias data_up      is <<signal analyzer_tb.dut.data_ch_2     : std_logic_vector(31 downto 0)>>;
       alias wr_en        is <<signal analyzer_tb.dut.data_wr_2     : std_logic>>;
       alias clk          is <<signal analyzer_tb.dut.rx_pclk_2     : std_logic>>;
       variable cnt     : std_logic_vector (14 downto 0) := (0 => '1', others => '0');
    begin
        wait until clk = '1';
        if wr_en = '1' then
            --report "address to write is " & integer'image(to_integer(unsigned(addr_wr))) severity note;
            assert cnt /= addr_wr report "addres to write (" & integer'image(to_integer(unsigned(addr_wr))) & ") doesn't match to calculated address " & integer'image(to_integer(unsigned(cnt))) severity warning;
        end if;
        cnt := std_logic_vector(unsigned(cnt) + 1);
    end process;


    -- release credits
    d_pci_ep.rx_tlp.ur_np_ext <= '0';
    d_pci_ep.rx_tlp.ur_p_ext <= '0';
    d_pci_ep.rx_tlp.ph_buf_status_vc0 <= '0';
    d_pci_ep.rx_tlp.pd_buf_status_vc0 <= '0';
    d_pci_ep.rx_tlp.nph_buf_status_vc0 <= '0';
    d_pci_ep.rx_tlp.npd_buf_status_vc0 <= '0';
    d_pci_ep.rx_tlp.npd_processed_vc0 <= '0';
    d_pci_ep.rx_tlp.nph_processed_vc0 <= nph_processed;
    d_pci_ep.rx_tlp.pd_processed_vc0 <= '0';
    d_pci_ep.rx_tlp.ph_processed_vc0 <= '0';
    d_pci_ep.rx_tlp.npd_num_vc0 <= (others => '0');
    d_pci_ep.transaction.cmpln_tout <= '0';
    d_pci_ep.transaction.cmpltr_abort_np <= '0';
    d_pci_ep.transaction.cmpltr_abort_p <= '0';
    d_pci_ep.transaction.unexp_cmpln <= '0';
    d_pci_ep.transaction.np_req_pend <= np_req_pend;
    pcie_release_credits_process : process is
         variable tlp_type : std_logic_vector (6 downto 0);
         variable data_transfer_ena : std_logic := '0';
         variable received_packet : integer := 0;
         variable counter : integer := 1;

    begin
         if d_pci.tx_tlp.tx_st_vc0 = '1' and d_pci.tx_tlp.tx_data_vc0(14 downto 8) = RX_MEM_RD_FMT_TYPE then
             np_req_pend <= '1';
         end if;
         if tlp_rx_q.rx_st_vc0 = '1' then
             data_transfer_ena := '1';
             case tlp_rx_q.rx_data_vc0 (14 downto 8) is
                 when RX_MEM_RD_FMT_TYPE =>
                     counter := counter + 1;
                     tlp_type := RX_MEM_RD_FMT_TYPE;
                 when RX_MEM_WR_FMT_TYPE =>
                     counter := counter + 1;
                     tlp_type := RX_MEM_WR_FMT_TYPE;
                     received_packet := received_packet + 1;
                 when RX_CPLD_FMT_TYPE   =>
                     counter := counter + 1;
                     tlp_type := RX_CPLD_FMT_TYPE;
                 when RX_CFG_WR_FMT_TYPE =>
                     counter := counter + 1;
                     tlp_type := RX_CFG_WR_FMT_TYPE;
                 when RX_CFG_RD_FMT_TYPE =>
                     counter := counter + 1;
                     tlp_type := RX_CFG_RD_FMT_TYPE;
                 when RX_CPL_FMT_TYPE =>
                     counter := counter + 1;
                     tlp_type := RX_CPL_FMT_TYPE;
                 when others =>
             end case;
         end if;
        if tlp_rx_q.rx_end_vc0 = '1' then
            if tlp_type = RX_CPLD_FMT_TYPE or tlp_type = RX_MEM_RD_FMT_TYPE then
                npd_processed <= '1';
                nph_processed <= '1';
                np_req_pend <= '0';
            end if;
            data_transfer_ena := '0';
            if tlp_type = RX_MEM_RD_FMT_TYPE or tlp_type = RX_MEM_WR_FMT_TYPE or tlp_type = RX_CPLD_FMT_TYPE then
                if tlp_type = RX_MEM_RD_FMT_TYPE then
                end if;
                if tlp_type = RX_MEM_WR_FMT_TYPE or tlp_type = RX_CPLD_FMT_TYPE then
                else
                end if;
            end if;
        else
            npd_processed <= '0';
            nph_processed <= '0';
        end if;
        wait until ioclk2 = '1';
    end process;

end arch;

