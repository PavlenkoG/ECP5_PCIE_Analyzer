library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ptm_engine_pkg.all;
use work.pci_wrapper_pkg.all;

library aldec;
use aldec.aldec_tools.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

entity ptm_tb is
    generic (runner_cfg : string);
end entity ptm_tb;

architecture RTL of ptm_tb is

    signal rst              : std_logic;
    signal clk              : std_logic;
    signal timer            : std_logic;
    signal d_ptm            : t_ptm_engine_in;
    signal q_ptm            : t_ptm_engine_out;

    signal ptm_timer        : std_logic_vector (63 downto 0) := X"00000000_000F4240";
    signal current_ptm_timer: std_logic_vector (63 downto 0) := (others => '0');

    signal first_req        : std_logic := '0';
    signal us_pulse         : std_logic;
    signal us_pulse_dut     : std_logic := '0';
    signal q_tlp            : t_rx_tlp_intf_q;

    signal ptm_offset       : std_logic_vector (63 downto 0);
    signal ptm_offset_cfg   : std_logic;

    alias ptm_timer_dut is <<signal ptm_tb.ptm_inst.ptm_timer_dut : std_logic_vector (63 downto 0) >>;
begin

--******************************************************************************
-- VUnit
--******************************************************************************

    asdb_dump("/ptm_tb/clk");
    asdb_dump("/ptm_tb/ptm_inst/d");
    asdb_dump("/ptm_tb/ptm_inst/q");
    asdb_dump("/ptm_tb/ptm_inst/r");
    asdb_dump("/ptm_tb/ptm_inst/d_mst");
    asdb_dump("/ptm_tb/ptm_inst/q_mst");
    
    main : process
    begin
        test_runner_setup (runner, runner_cfg);
        while test_suite loop
            if run("test ptm") then
                wait for 10 ms;
                report "ptm test ";
            end if;
        end loop;
        report "ptm test done";
        test_runner_cleanup(runner);
    end process;

--******************************************************************************
-- CPU Time simulate
--******************************************************************************
    ptm_timer_proc : process is
    begin
        wait for 4000 ps;
        ptm_timer <= std_logic_vector(unsigned(ptm_timer) + 4);
    end process;

    us_pulse_proc : process is
        variable counter : integer := 250;
    begin
        us_pulse <= '0';
        for i in 1 to counter loop
            wait for 4000 ps;
        end loop;
        counter := 249;
        us_pulse <= '1';
        wait for 4000 ps;
        us_pulse <= '0';
    end process;

    us_dut_gen_proc : process is
        variable div_1000 : integer := 0;
    begin
        wait for 4 ns;
        if (unsigned(ptm_timer_dut) > 1000) then
            div_1000 := to_integer(unsigned(ptm_timer_dut))/1000;
        end if;
        if abs((div_1000 * 1000) - to_integer(unsigned(ptm_timer_dut))) <= 7 then
            us_pulse_dut <= '1';
            wait for 8 ns;
            us_pulse_dut <= '0';
        end if;

    end process;

--******************************************************************************
-- diff measure
--******************************************************************************
    diff_measure_proc : process is
        variable differece : integer := 0;
    begin
        differece := to_integer(unsigned(ptm_timer_dut)) - to_integer(unsigned(ptm_timer));
        wait for 4 ns;
    end process;

--******************************************************************************
-- Reset process
--******************************************************************************
    rst_process : process is
    begin
        rst <= '1';
        wait for 300 ns;
        rst <= '0';
        wait for 100 ns;
        wait;
    end process;

--******************************************************************************
-- clk process
--******************************************************************************
    clk_125MHz : process
    begin
        clk <= '0';
        wait for 4 ns;
        clk <= '1';
        wait for 4 ns;
    end process;

--******************************************************************************
-- 1 MHZ timer
--******************************************************************************
    clk_1Mhz : process
    begin
        if rst = '0' then
            for i in 1 to 123 loop
                wait until clk = '1';
            end loop;
            wait until clk = '1';
            timer <= '1';
            wait until clk = '1';
            timer <= '0';
        else
            timer <= '0';
            wait until clk = '1';
        end if;
    end process;

--******************************************************************************
-- PTM enabling
--******************************************************************************
    ptm_ena_proc    : process
    begin
        d_ptm.ptm_ena <= '0';
        d_ptm.ptm_offset_ena <= '0';
        wait until rst = '0';
        ptm_offset <= (others => '0');
        ptm_offset_cfg <= '0';
        wait for 1 us;
        wait until clk = '1';
        d_ptm.ptm_ena <= '1';
        wait for 40 us;
        wait until clk = '1';
        ptm_offset <= X"0000000000000020";
        d_ptm.ptm_offset_ena <= '1';
        wait until clk = '1';
        d_ptm.ptm_offset_ena <= '0';
        wait for 1 ms;
        ptm_offset <= X"0000000000000100";
        ptm_offset_cfg <= '1';
        wait until clk = '1';
        d_ptm.ptm_offset_ena <= '1';
        wait until clk = '1';
        d_ptm.ptm_offset_ena <= '0';
        wait;
    end process;

--******************************************************************************
-- PTM requesting
--******************************************************************************
    ptm_request_proc : process
    begin
        d_ptm.pcie_rx.rx_st_vc0 <= '0';
        d_ptm.pcie_rx.rx_end_vc0 <= '0';
        d_ptm.pcie_rx.rx_data_vc0 <= (others => '0');

        d_ptm.ptm_ready <= '0';
        wait until q_ptm.ptm_request = '1';
        wait until clk = '1';
        current_ptm_timer <= std_logic_vector(unsigned(ptm_timer)+100);
        d_ptm.ptm_ready <= '1';
        wait until clk = '1';
        d_ptm.ptm_ready <= '0';
        wait for 600 ns;
        -----------------------------------------
        -- FIRST DW 1
        wait until clk = '1';
        d_ptm.pcie_rx.rx_st_vc0 <= '1';
        if first_req = '0' then
            d_ptm.pcie_rx.rx_data_vc0 <= X"3400";
        else
            d_ptm.pcie_rx.rx_data_vc0 <= X"7400";
        end if;
        -- FIRST DW 2
        wait until clk = '1';
        d_ptm.pcie_rx.rx_st_vc0 <= '0';
        if first_req = '0' then
            d_ptm.pcie_rx.rx_data_vc0 <= X"0000";
        else
            d_ptm.pcie_rx.rx_data_vc0 <= X"0001";
        end if;
        -----------------------------------------
        -- SECOND DW 1
        wait until clk = '1';
        d_ptm.pcie_rx.rx_data_vc0 <= X"0099";
        -- SECOND DW 2
        wait until clk = '1';
        d_ptm.pcie_rx.rx_data_vc0 <= X"0053";
        -----------------------------------------
        -- THIRD DW 1
        wait until clk = '1';
        if first_req = '0' then
            d_ptm.pcie_rx.rx_data_vc0 <= X"0000";
        else
            d_ptm.pcie_rx.rx_data_vc0 <= current_ptm_timer(63 downto 48);
        end if;
        -- THIRD DW 2
        wait until clk = '1';
        if first_req = '0' then
            d_ptm.pcie_rx.rx_data_vc0 <= X"0000";
        else
            d_ptm.pcie_rx.rx_data_vc0 <= current_ptm_timer(47 downto 32);
        end if;
        -----------------------------------------
        -- FOURTH DW 1
        wait until clk = '1';
        if first_req = '0' then
            d_ptm.pcie_rx.rx_data_vc0 <= X"0000";
        else
            d_ptm.pcie_rx.rx_data_vc0 <= current_ptm_timer(31 downto 16);
        end if;
        -- FOURTH DW 2
        wait until clk = '1';
        if first_req = '0' then
            d_ptm.pcie_rx.rx_end_vc0 <= '1';
            d_ptm.pcie_rx.rx_data_vc0 <= X"0000";
        else
            d_ptm.pcie_rx.rx_data_vc0 <= current_ptm_timer(15 downto 0);
        end if;
        -----------------------------------------
        if first_req = '1' then
            -- FIFTH DW 2
            wait until clk = '1';
            d_ptm.pcie_rx.rx_data_vc0 <= X"9001";
            -- FIFTH DW 2
            wait until clk = '1';
            d_ptm.pcie_rx.rx_end_vc0 <= '1';
            d_ptm.pcie_rx.rx_data_vc0 <= X"0000";
        else
            wait until clk = '1';
            d_ptm.pcie_rx.rx_end_vc0 <= '0';
        end if;
        wait until clk = '1';
        first_req <= '1';
        d_ptm.pcie_rx.rx_end_vc0 <= '0';
        d_ptm.pcie_rx.rx_data_vc0 <= X"0000";

    end process;

--******************************************************************************
-- DUT
--******************************************************************************
ptm_inst : entity work.ptm_engine
    port map(
        clk => clk,
        rst => rst,
        d   => d_ptm,
        q   => q_ptm
    );
    d_ptm.ptm_offset <= ptm_offset;
    d_ptm.ptm_offset_cfg <= ptm_offset_cfg;

    d_ptm.pcie_rx.rx_bar_hit <= (others => '0');
    d_ptm.pcie_rx.rx_malf_tlp_vc0 <= '0';
    d_ptm.pcie_rx.rx_us_req_vc0 <= '0';
    d_ptm.sync_1mhz_in <= timer;

end architecture RTL;
