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
use work.BP_x86_tb_pkg.all;
use work.pcie_tx_engine_pkg.all;
use work.pcie_rx_engine_pkg.all;
use work.pci_wrapper_pkg.all;
use work.pci_core_wrapper_pkg.all;
use work.fh_traffic_generator_pkg.all;

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
    signal ptm_time                 : std_logic_vector (63 downto 0);
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

    signal request_mem                  : t_read_mem_arr;
    signal request_mem_st               : t_read_mem;
    signal req_mem_idx_head             : integer range 0 to 31 := 0;
    signal req_mem_idx_tail             : integer range 0 to 31 := 0;
    signal req_mem_idx_entries          : integer range 0 to 31 := 0;

    type d_fh_array_t is array (30 downto 0) of t_sio_frame_handler_in;
    type q_fh_array_t is array (30 downto 0) of t_sio_frame_handler_out;

    signal d_fh                         : d_fh_array_t;
    signal q_fh                         : q_fh_array_t;
    signal d_fhg                        : t_fh_intf_in;
    signal q_fhg                        : t_fh_intf_out;
    signal start_fh_test_gen            : std_logic := '0';
    signal tx_last                      : std_logic_vector (MODUL_NUM_CONST - 1 downto 0);
    signal tx_valid                     : std_logic_vector (MODUL_NUM_CONST - 1 downto 0);
    signal tx_ready                     : std_logic_vector (MODUL_NUM_CONST - 1 downto 0);
    signal tx_data                      : std_logic_vector (7 downto 0);
    signal end_test                     : std_logic;
    signal fh_reset                     : std_logic;

    signal bomi                 : std_logic_vector (30 downto 0);
    signal bimo                 : std_logic_vector (30 downto 0);
    signal sda                  : std_logic;
    signal scl                  : std_logic;

    -- TEST Controller signals
--  signal d_tc                 : t_TEST_controller_v2_in;
--  signal q_tc                 : t_TEST_controller_v2_out;
    signal d_sio                : t_sio_bus_in;
    signal q_sio                : t_sio_bus_out;

    signal comment              : string(1 to 40);

    -- events
    signal tx_evt_req           : std_logic_vector (31 downto 0);
    signal tx_evt_idx           : t_tx_evt_idx;
    signal tx_evt_rdy           : std_logic_vector (31 downto 0);

    signal received_packet_cnt  : integer;
    signal fh_received_pkt_cnt  : integer;
    signal report_tlp_len       : integer;
    signal fhd_speed            : t_fh_data_speed;
    signal fhd_time             : t_dur_time;

    signal stim_file_read_done  : boolean := false;


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
    io_pcie_signals_forcing : process
    begin
        wait until rst = '1';
        wait for 300 ns;
        force_signal ("deposit", "/bp_x86_tb/pcie_inst/pci_core_inst/u1_pcs_pipe/pcie_ip_rstn", "2#1");
        force_signal ("deposit", "/bp_x86_tb/bp_x86_inst/pcie_core_wrapper_inst/pci_core_inst/u1_pcs_pipe/pcie_ip_rstn", "2#1");
        wait for 350 ns;
        force_signal ("deposit", "/bp_x86_tb/pcie_inst/pci_core_inst/u1_pcs_pipe/ffs_pcie_con_0", "2#1");
        force_signal ("deposit", "/bp_x86_tb/bp_x86_inst/pcie_core_wrapper_inst/pci_core_inst/u1_pcs_pipe/ffs_pcie_con_0", "2#1");
        wait;
    end process;


    force_signal ("freeze", "/bp_x86_tb/pcie_inst/pci_core_inst/u1_pcs_pipe/pcs_top_0/sll_inst/LRCLK_TC_w", "16#64");
    force_signal ("freeze", "/bp_x86_tb/pcie_inst/pci_core_inst/u1_pcs_pipe/pcs_top_0/sll_inst/rcount_tc" , "10#250");

    force_signal ("freeze", "/bp_x86_tb/bp_x86_inst/pcie_core_wrapper_inst/pci_core_inst/u1_pcs_pipe/pcs_top_0/sll_inst/LRCLK_TC_w", "16#64");
    force_signal ("freeze", "/bp_x86_tb/bp_x86_inst/pcie_core_wrapper_inst/pci_core_inst/u1_pcs_pipe/pcs_top_0/sll_inst/rcount_tc", "10#250");

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Frame handler signals forcing
--------------------------------------------------------------------------------
    frame_handler_proc : process
    begin
    wait for 16.5 us;
    wait until clk_150 = '1';

    if TEST_MODUL_GENERATE = false then
        for i in 0 to 30 loop
            force_signal ("deposit", "bp_x86_tb/FH_TEST_GEN/FRAME_HANDLERS__"&integer'image(i)&"/fh_inst/sio_frame_engine_rx_inst/r.link_active_timer_count", "8#02");
        end loop;
    else
        force_signal ("deposit", "bp_x86_tb/TEST_MODUL_GEN/fh_inst_2/sio_frame_handler_inst/sio_frame_engine_rx_inst/r.link_active_timer_count", "8#02");
    end if;

    wait for 5 us;
    wait until ioclk = '1';

    wait;
end process;

--------------------------------------------------------------------------------
-- this process reads data from stimuli file and generates
-- tlp packets for PCIExpress core
--------------------------------------------------------------------------------
    test_process : process is
        constant STIM_FILE_NAME : string := "..\..\stim_file.txt";
    begin

        in_tlp.tx_data_vc0 <= (others => '0');
        in_tlp.tx_end_vc0 <= '0';
        in_tlp.tx_nlfy_vc0 <= '0';
        in_tlp.tx_req_vc0 <= '0';
        in_tlp.tx_st_vc0 <= '0';
        io_no_pcie_train <= '0';
        tx_evt_req <= (others => '0');
        tx_evt_idx <= (others => (others => '0'));

        force_signal ("deposit", "/bp_x86_tb/bp_x86_inst/pcie_core_wrapper_inst/pci_core_inst/u1_dut/no_pcie_train", "2#0");
--      force_signal ("deposit", "/bp_x86_tb/bp_x86_inst/pcie_core_wrapper_inst/no_pcie_train", "2#0");--pci_core_inst/u1_dut/no_pcie_train", "2#0");

        wait until q_pci.phy.phy_ltssm_state = "0010";
        io_no_pcie_train <= '1';
        force_signal ("deposit", "/bp_x86_tb/bp_x86_inst/pcie_core_wrapper_inst/pci_core_inst/u1_dut/no_pcie_train", "2#1");
--      force_signal ("deposit", "/bp_x86_tb/bp_x86_inst/pcie_core_wrapper_inst/no_pcie_train", "2#1");--pci_core_inst/u1_dut/no_pcie_train", "2#1");
        wait until q_pci.data_link.dl_active = '1';

        wait for 10 ns;
        start_fh_test_gen <= '1' after 1 us;
        stim_file_read (STIM_FILE_NAME, ptm_time, ioclk, clk_100,out_tlp,np_req_pend,in_tlp,tx_ready,tx_valid,tx_data,tx_last,tx_evt_req,tx_evt_idx,tx_evt_rdy,request_mem_st, comment);
        report "exit from stim file read";
        wait for 5 us;
        stim_file_read_done <= true;

        --std.env.stop(0);

        wait;
    end process;

--******************************************************************************
--
--******************************************************************************
    report_process : process is
         file report_file : text;
         variable fstatus : file_open_status := STATUS_ERROR;
         variable l : line;
         variable time_pcie_start : time;
         variable time_pcie_end : time;
    begin
        wait until tlp_rx_q.rx_st_vc0 = '1';
        time_pcie_start := time(now);
        if end_test ='0' then
            wait until end_test = '1';
            report "end test";
        end if;
        report "first tlp packet";
        wait_for_receive_all_packets: loop
            if fh_received_pkt_cnt = received_packet_cnt then
                wait until tlp_rx_q.rx_end_vc0 = '1';
                wait until ioclk = '1';
                time_pcie_end := time(now);
                exit wait_for_receive_all_packets;
            else
                wait until ioclk = '1';
            end if;
        end loop;
        
        file_open(fstatus, report_file, "perf_report.txt", append_mode);
        write (l, C_PACKET_LEN + 1);
        write (l, ht);
        write (l, C_TEST_LEN);
        write (l, ht);
        write (l, time_pcie_end - time_pcie_start);
        write (l, ht);
        write (l, received_packet_cnt);
        write (l, ht);
        write (l, report_tlp_len);
        write (l, ht);
        write(l, fhd_speed(1));
        for i in 0 to 30 loop
            write(l, ht);
            write(l, fhd_time(i));
        end loop;
        writeline (report_file, l); 

        --std.env.stop(0);

        wait;
    end process;

    speed_measure_process : process is
        file report_file_in : text;
        file report_file_out : text;
        type t_byte_counter is array (0 to 30) of integer;
        variable byte_counter_in : t_byte_counter;
        variable byte_counter_out : t_byte_counter;
        variable fstatus : file_open_status := STATUS_ERROR;
        variable time_counter : integer := 0;
        variable l_in : line;
        variable l_out : line;
        variable t : time;
    begin
        byte_counter_in := (others => 0);
        byte_counter_out := (others => 0);

        file_open(fstatus, report_file_in, "chart_report_in.txt", write_mode);
        file_open(fstatus, report_file_out, "chart_report_out.txt", write_mode);

        calc_loop: loop
            for i in 0 to 30 loop
                if q_fh(i).rx_valid = '1' then
                    byte_counter_out(i) := byte_counter_out(i) + 1;
                end if;
                if d_fh(i).tx_valid = '1' and q_fh(i).tx_ready ='1' then
                    byte_counter_in(i) := byte_counter_in(i) + 1;
                end if;
            end loop;
            if time_counter = 1000 then
                t := time(now);
                write(l_in,t);write(l_in,ht);
                write(l_out,t);write(l_out,ht);
                for j in 0 to 30 loop
                    write (l_in,byte_counter_in(j)); write(l_in,ht);
                    write (l_out,byte_counter_out(j)); write(l_out,ht);
                end loop;
                writeline (report_file_in, l_in);
                writeline (report_file_out, l_out);
                time_counter := 0;
                byte_counter_out:= (others => 0);
                byte_counter_in:= (others => 0);
            else
                time_counter := time_counter + 1;
            end if;
            wait until clk_100 = '1';
        end loop;

    end process;

--******************************************************************************
-- DUT
--******************************************************************************

    BP_x86_inst : entity work.top
        generic map(
            TEST      => true,
            MSI_X_ENA => true,
            MODUL_NUM => MODUL_NUM_CONST
        )
        port map(
            clk_25          => clk_25,
            sync_in         => sync,
            sync_out        => open,
            modul_reset_n   => open,
            config_cs_n     => open,
            config_mosi     => open,
            config_miso     => '0',
            id_cs_n         => open,
            id_sck          => open,
            id_mosi         => open,
            id_miso         => '0',
            sda             => sda,
            scl             => scl,

            debug           => open,

            self_reset      => open,

            bimo            => bimo,
            bomi            => bomi,
            pcie_rxp        => pcie_rxp,
            pcie_rxn        => pcie_rxn,
            pcie_txp        => pcie_txp,
            pcie_txn        => pcie_txn,
            pcie_clkp       => refclk,
            pcie_clkn       => not refclk
        );

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

    scl <= 'L' when scl = '0' else 'Z';
    sda <= 'L' when sda = '0' else 'Z';
    pcie_inst: entity work.pci_core_wrapper
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

--******************************************************************************
-- I2C Sim
--******************************************************************************

--  i2c_tb : entity work.I2C_minion
--     generic map(
--         MINION_ADDR            => "0011001",
--         USE_INPUT_DEBOUNCING   => false,
--         DEBOUNCING_WAIT_CYCLES => 0
--     )
--     port map(
--         scl              => scl,
--         sda              => sda,
--         clk              => clk_100,
--         rst              => not rst,
--         read_req         => open,
--         data_to_master   => X"A5",
--         data_valid       => open,
--         data_from_master => open
--      );
--******************************************************************************
-- MODULE IMPLEMENTATION for tests
--******************************************************************************

    TEST_MODUL_GEN : if TEST_MODUL_GENERATE = true generate
        fh_inst_2: entity work.sio_bus
            port map(
                i_clk        => clk_100,
                i_reset      => not rst,
                i_clk_sample => clk_150,
                d            => d_sio,
                q            => q_sio
            );

--      d_sio.bomi <= bomi(1);
--      bimo(1) <= q_sio.bimo;

--      d_sio.mem_rd_data <= q_tc.mem_rd_data;
--      d_sio.mem_rd_rdy <= q_tc.mem_rd_rdy;
--      d_sio.mem_wr_rdy <= q_tc.mem_wr_rdy;
--      d_tc.mem_rd_addr <= q_sio.mem_rd_addr;
--      d_tc.mem_wr_data <= q_sio.mem_wr_data;
--      d_tc.mem_wr_en <= q_sio.mem_wr_en;
--      test_modul_impl : entity work.TEST_controller_v2
--          port map(
--              clk => clk_100,
--              rst => not rst,
--              d   => d_tc,
--              q   => q_tc
--          );
    end generate TEST_MODUL_GEN;

--******************************************************************************
-- FRAME HANDLER for test generating
--******************************************************************************

    FH_TEST_GEN : if TEST_MODUL_GENERATE = false generate
        FRAME_HANDLERS: for i in (30) downto 0 generate
        fh_inst : entity m100_sio_core.sio_frame_handler
            generic map (G_FPGA_TYPE => "ecp5-85")
            port map ( i_clk => clk_100,
                       i_reset =>  not rst,
                       i_clk_sample => clk_150,
                       d => d_fh(i),
                       q => q_fh(i));
                d_fh(i).bomi <= bomi(i);
                bimo(i) <= q_fh(i).bimo;
                d_fh(i).timer_clk_en <= timer;
                d_fh(i).rx_ready <= '1' when q_fh(i).rx_valid = '1' else '0';

                d_fh(i).tx_data <= q_fhg(i).tx_data when FH_TRAFFIC_GENERATOR = true else tx_data;
                d_fh(i).tx_last <= q_fhg(i).tx_last when FH_TRAFFIC_GENERATOR = true else tx_last(i);
                d_fh(i).tx_valid <=q_fhg(i).tx_valid when FH_TRAFFIC_GENERATOR = true else tx_valid(i);
                d_fhg(i).tx_ready <= q_fh(i).tx_ready;

                tx_ready(i) <= q_fh(i).tx_ready;
                d_fh(i).tx_evt_req <= tx_evt_req(i);
                d_fh(i).tx_evt_idx <= tx_evt_idx(i);
                tx_evt_rdy(i) <= q_fh(i).tx_evt_rdy;
         end generate FRAME_HANDLERS;
     end generate FH_TEST_GEN;

--******************************************************************************
-- FRAME HANDLER TRAFFIC GENERATOR
--******************************************************************************
    FH_GEN: if FH_TRAFFIC_GENERATOR = true generate
        fh_traffic_generator_inst : entity work.fh_traffic_generator
        port map (
            clk_100 => clk_100,
            clk_125 => ioclk,
            rst => start_fh_test_gen,
  
            test_len => C_TEST_LEN,
            packet_len => C_PACKET_LEN,
            modul_mask => C_MODULE_IN_TEST,--X"0000003F",--(others => '1'),
            test_end => end_test,
            send_packet_counter_out => fh_received_pkt_cnt,
            fhd_speed => fhd_speed,
            fhd_time => fhd_time,
  
            d_fh => d_fhg,
            q_fh => q_fhg
        );
    end generate FH_GEN;


--******************************************************************************
-- writes received data from host pcie to the file
--******************************************************************************

        request_mem_st <= request_mem(req_mem_idx_tail);
        tlp_rx_q <= q_pci.rx_tlp;
        d_pci.rx_tlp.ur_np_ext <= '0';--npd_processed(1);
        d_pci.rx_tlp.ur_p_ext <= '0';--npd_processed(1);
        d_pci.rx_tlp.ph_buf_status_vc0 <= '0';--npd_processed(1);
        d_pci.rx_tlp.pd_buf_status_vc0 <= '0';--npd_processed(1);
        d_pci.rx_tlp.nph_buf_status_vc0 <= '0';--npd_processed(1);
        d_pci.rx_tlp.npd_buf_status_vc0 <= '0';--npd_processed(1);
        d_pci.rx_tlp.npd_processed_vc0 <= '0';--npd_processed(1);
        d_pci.rx_tlp.nph_processed_vc0 <= nph_processed;--nph_processed(1);
        d_pci.rx_tlp.pd_processed_vc0 <= '0';--nph_processed(1);
        d_pci.rx_tlp.ph_processed_vc0 <= '0';--nph_processed(1);
        d_pci.rx_tlp.npd_num_vc0 <= (others => '0');
        d_pci.transaction.cmpln_tout <= '0';
        d_pci.transaction.cmpltr_abort_np <= '0';
        d_pci.transaction.cmpltr_abort_p <= '0';
        d_pci.transaction.unexp_cmpln <= '0';
        d_pci.transaction.np_req_pend <= np_req_pend;
        pcie_write_process : process is
             file pcie_file : text;
             variable fstatus : file_open_status := STATUS_ERROR;
             variable tlp_type : std_logic_vector (6 downto 0);
             variable data_transfer_ena : std_logic := '0';
             variable l : line;
             variable data_cnt : integer := 0;
             variable counter : integer := 1;
             variable tx_start : std_logic := '0';
             variable temp_data : std_logic_vector (15 downto 0) := (others => '0');
             variable received_packet : integer := 0;
         begin
             if fstatus /= OPEN_OK then
                 file_open(fstatus, pcie_file, "pcie_read.txt", write_mode);
             end if;
             if d_pci.tx_tlp.tx_st_vc0 = '1' and d_pci.tx_tlp.tx_data_vc0(14 downto 8) = RX_MEM_RD_FMT_TYPE then
                 np_req_pend <= '1';
             end if;

             if tlp_rx_q.rx_st_vc0 = '1' then
                 data_transfer_ena := '1';
                 case tlp_rx_q.rx_data_vc0 (14 downto 8) is
                     when RX_MEM_RD_FMT_TYPE =>
                         write (l, counter); write (l,ht);
                         counter := counter + 1;
                         write (l, "MRd32"); write (l, ht);
                         tlp_type := RX_MEM_RD_FMT_TYPE;
                     when RX_MEM_WR_FMT_TYPE =>
                         write (l, counter); write (l,ht);
                         counter := counter + 1;
                         write (l, "MWr32"); write (l, ht);
                         tlp_type := RX_MEM_WR_FMT_TYPE;
                         received_packet := received_packet + 1;
                     when RX_CPLD_FMT_TYPE   =>
                         write (l, counter); write (l,ht);
                         counter := counter + 1;
                         write (l, "CplD"); write (l, ht);
                         tlp_type := RX_CPLD_FMT_TYPE;
                     when RX_CFG_WR_FMT_TYPE =>
                         write (l, counter); write (l,ht);
                         counter := counter + 1;
                         write (l, "CfgWr"); write (l, ht);
                         tlp_type := RX_CFG_WR_FMT_TYPE;
                     when RX_CFG_RD_FMT_TYPE =>
                         write (l, counter); write (l,ht);
                         counter := counter + 1;
                         write (l, "CfgRd"); write (l, ht);
                         tlp_type := RX_CFG_RD_FMT_TYPE;
                     when RX_CPL_FMT_TYPE =>
                         write (l, counter); write (l,ht);
                         counter := counter + 1;
                         write (l, "Cpl"); write (l, ht);
                         tlp_type := RX_CPL_FMT_TYPE;
                     when others =>
                 end case;
                 request_mem(req_mem_idx_head).tlp_type <= tlp_rx_q.rx_data_vc0(14 downto 8);
             end if;
             if tlp_rx_q.rx_end_vc0 = '1' then
                 if tlp_type = RX_CPLD_FMT_TYPE or tlp_type = RX_MEM_RD_FMT_TYPE then
                     npd_processed <= '1';
                     nph_processed <= '1';
                     np_req_pend <= '0';
                 end if;
                 data_transfer_ena := '0';
                 data_cnt := 0;
                 if tlp_type = RX_MEM_RD_FMT_TYPE or tlp_type = RX_MEM_WR_FMT_TYPE or tlp_type = RX_CPLD_FMT_TYPE then
                     if tlp_type = RX_MEM_RD_FMT_TYPE then
                         request_mem(req_mem_idx_head).address(15 downto 0) <= tlp_rx_q.rx_data_vc0(15 downto 0);
                         request_mem(req_mem_idx_head).ena <= true;
                         if req_mem_idx_head < 31 then
                             req_mem_idx_head <= req_mem_idx_head + 1;
                         else
                             req_mem_idx_head <= 0;
                         end if;
                     end if;
                     if tlp_type = RX_MEM_WR_FMT_TYPE or tlp_type = RX_CPLD_FMT_TYPE then
                         hwrite (l, tlp_rx_q.rx_data_vc0(7 downto 0) & tlp_rx_q.rx_data_vc0(15 downto 8));
                         hwrite (l, temp_data);
                     else
                         hwrite (l, tlp_rx_q.rx_data_vc0);
                     end if;
                     write (l, ";");
                 end if;
                     writeline (pcie_file, l);
             else
                 npd_processed <= '0';
                 nph_processed <= '0';
             end if;

             if data_transfer_ena = '1' then
                 case data_cnt is
                     when 1 =>
                         write (l, "len: "); write (l, to_integer(unsigned(tlp_rx_q.rx_data_vc0(9 downto 0))));
                         report_tlp_len <= to_integer(unsigned(tlp_rx_q.rx_data_vc0(9 downto 0)));
                         write (l, ht);
                         if tlp_type = RX_CPLD_FMT_TYPE then
                            npd_num_vc0 <= tlp_rx_q.rx_data_vc0(7 downto 0);
                         end if;
                         if tlp_type = RX_MEM_RD_FMT_TYPE then
                             request_mem(req_mem_idx_head).length <= tlp_rx_q.rx_data_vc0(9 downto 0);
                         end if;
                     when 2 =>
                         if tlp_type = RX_MEM_RD_FMT_TYPE then
                             write (l, "ReqID: "); hwrite (l, tlp_rx_q.rx_data_vc0); write (l, ht);
                             request_mem(req_mem_idx_head).requester_id <= tlp_rx_q.rx_data_vc0;
                         end if;
                     when 3 =>

                         if tlp_type = RX_MEM_RD_FMT_TYPE then
                             write (l, "Tag: "); hwrite (l, tlp_rx_q.rx_data_vc0(15 downto 8)); write (l, ht);
                             request_mem(req_mem_idx_head).tag <= tlp_rx_q.rx_data_vc0(15 downto 8);
                             request_mem(req_mem_idx_head).dw <= tlp_rx_q.rx_data_vc0(7 downto 0);
                         end if;

                        if tlp_type /= RX_CPLD_FMT_TYPE then
                            -- First/Last DW
                            write (l, "lDW: "); write (l, tlp_rx_q.rx_data_vc0(7 downto 4));
                            write (l, ht);
                            write (l, "fDW: "); write (l, tlp_rx_q.rx_data_vc0(3 downto 0));
                            write (l, ht);
                        else
                            -- Byte count
                            write (l, "BC: "); hwrite (l,tlp_rx_q.rx_data_vc0(10 downto 0)); write (l, ht);
                        end if;
                     when 4 =>
                         if tlp_type = RX_MEM_RD_FMT_TYPE or tlp_type = RX_MEM_WR_FMT_TYPE then
                             write (l, "Addr: 0x"); hwrite (l, tlp_rx_q.rx_data_vc0);
                             request_mem(req_mem_idx_head).address(31 downto 16) <= tlp_rx_q.rx_data_vc0(15 downto 0);
                         end if;
                     when 5 =>
                         if tlp_type = RX_MEM_RD_FMT_TYPE or tlp_type = RX_MEM_WR_FMT_TYPE then
                             hwrite (l, tlp_rx_q.rx_data_vc0); write (l, ht);
                             write (l, "Data: 0x");
                         end if;
                         if tlp_type = RX_CPLD_FMT_TYPE then
                             write (l, "Tag: 0x"); hwrite (l,tlp_rx_q.rx_data_vc0(15 downto 8)); write (l, ht);
                             write (l, "LoAd: "); hwrite (l,tlp_rx_q.rx_data_vc0(6 downto 0)); write (l, ht);
                             write (l, "Data: 0x");
                         end if;
                     when  6 to 257 =>
                         if tlp_type = RX_MEM_RD_FMT_TYPE or tlp_type = RX_MEM_WR_FMT_TYPE or tlp_type = RX_CPLD_FMT_TYPE then
                             if std_logic_vector(to_unsigned(data_cnt,1)) = "0" then
                                 temp_data := tlp_rx_q.rx_data_vc0(7 downto 0) & tlp_rx_q.rx_data_vc0(15 downto 8);
--                               hwrite (l, tlp_rx_q.rx_data_vc0);
                             else
                                 hwrite (l, tlp_rx_q.rx_data_vc0(7 downto 0) & tlp_rx_q.rx_data_vc0(15 downto 8));
                                 hwrite (l, temp_data, LEFT, 4);
                                 write (l,"  0x");
                             end if;
                         end if;
                     when others =>
                 end case;
                 data_cnt := data_cnt + 1;
             end if;
            if d_pci.tx_tlp.tx_st_vc0 = '1' then
                if d_pci.tx_tlp.tx_data_vc0(14 downto 8) = RX_CPLD_FMT_TYPE or
                   d_pci.tx_tlp.tx_data_vc0(14 downto 8) = TX_MSG_RQ_FMT_TYPE then
                    tx_start := '1';
                end if;

            end if;
            -- Memory read handling
            -- stores requests to request memory
            if d_pci.tx_tlp.tx_end_vc0 = '1' then
                if tx_start = '1' then
                    tx_start := '0';
                    request_mem(req_mem_idx_tail).ena <= false;
                    if req_mem_idx_tail < 31 then
                        req_mem_idx_tail <= req_mem_idx_tail + 1;
                    else
                        req_mem_idx_tail <= 0;
                    end if;
                    if req_mem_idx_entries > 0 then
                        req_mem_idx_entries <= req_mem_idx_entries - 1;
                    end if;
                end if;
            end if;
            received_packet_cnt <= received_packet;
            wait until ioclk = '1';

        end process;

--******************************************************************************
-- writes received module data to the file
--******************************************************************************

    module_write_process : process is
--      file module_file : text open WRITE_MODE is "C:\Users\GRPA\Documents\WORK\JADE\Systembus\BP_Project\SIM\ActiveHDL\module_read.txt";
        file module_file : text open WRITE_MODE is "module_read.txt";
        type t_packet is array (31 downto 0) of std_logic_vector (7 downto 0);
        type t_data is array (31 downto 0) of t_packet;
        type t_data_cnt is array (31 downto 0) of integer;
        type t_time is array (31 downto 0) of time;

        variable module_data_mem : t_data;
        variable module_data_cnt : t_data_cnt := (others => 0);
        variable module_time_start : t_time;
        variable l : line;
        variable counter : integer := 0;

    begin
        for i in 0 to 30 loop
            if d_fh(i).rx_ready = '1' then
                module_data_mem(i)(module_data_cnt(i)) := q_fh(i).rx_data;
                if q_fh(i).rx_last = '1' then
                    module_time_start(i) := time(now);
                    write (l, counter); write(l, ' ');
                    counter := counter + 1;
                    write (l, "M ");
                    write (l, i); write (l, " :"); write (l, ' ');
                    for c in 0 to  module_data_cnt (i) loop
                        write (l, "0x");
                        hwrite (l, module_data_mem(i)(c));
                        if c /= module_data_cnt (i) then
                            write (l, ", ");
                        else
--                          write (l, "; at time ");
--                          write (l, to_string(now));
                        end if;
                    end loop;
                    writeline (module_file, l);
                    module_data_cnt (i) := 0;
                else
                    module_data_cnt (i) := module_data_cnt(i) + 1;
                end if;
            end if;

        end loop;
        wait until clk_100 = '1';
    end process;


    pcs_inst : entity work.pcs_pci
    port map (
        hdinn           => pcie_rxn,
        hdinp           => pcie_rxp,
        rst_dual_c      => not rst,
        rx_pcs_rst_c    => not rst,
        rx_pwrup_c      => '1',
        rx_serdes_rst_c => not rst,
        rxrefclk        => refclk,--clk,
        serdes_pdb      => '1',
        serdes_rst_dual_c => not rst,
        signal_detect_c => '0',
        rx_cdr_lol_s    => open,
        rx_k            => rx_k,
        rx_pclk         => rx_pclk,
        rxdata          => rxdata
    );

    scram_rst <= '1' when rx_k(0) = '1' and rxdata = X"BC" else '0';
    scram_en <= '0' when rx_k(0) = '1' and rxdata = X"BC" else
                '0' when rx_k(0) = '1' and rxdata =X"1C" else
                '1';
    lfsr_scrambler_inst : entity work.lfsr_scrambler
    port map (
        data_in         => rxdata,
        rx_k            => rx_k(0),
        scram_en        => scram_en,
        scram_rst       => scram_rst,
        rst             => not rst,
        clk             => rx_pclk,
        data_out        => open
    );
end arch;

