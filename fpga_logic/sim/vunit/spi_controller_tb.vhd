library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
use ieee.numeric_std.all;
use work.analyzer_tb_pkg.all;

package spi_controller_tb_pkg is
    /*
    procedure spi_test (
                        constant freq       : in integer;
                        signal clk          : out std_logic;
                        signal miso         : in std_logic;
                        signal mosi         : out std_logic;
                        signal cs           : out std_logic;

                        signal data_in      : in payload_t;
                        signal data_out     : out payload_t;
                        constant len          : in integer
    );
    */
end package;
package body spi_controller_tb_pkg is
    /*
    procedure spi_test (
                        constant freq       : in integer;
                        signal clk          : out std_logic;
                        signal miso         : in std_logic;
                        signal mosi         : out std_logic;
                        signal cs           : out std_logic;

                        signal data_in      : in payload_t;
                        signal data_out     : out payload_t;
                        constant len          : in integer) is
        
        variable waittime : time;
        variable realtime : real;
    begin
        realtime := 1.0 / Real(freq*2);
        waittime := realtime * 1 us;
        cs <= '0';
        wait for waittime;-- (1/Real(freq))*1 us;
        clk <= '0';
        for i in 0 to len - 1 loop
            for j in 0 to 7 loop
                data_out(i)(7 - j) <= miso;
                wait for waittime;--(1/freq)*500 ns;
                clk <= '1';
                mosi <= data_in(i)(7 - j);
                wait for waittime;--(1/freq)*500 ns;
                clk <= '0';
            end loop;
        end loop;
        wait for waittime;-- (1/freq)*1 us;
        cs <= '1';
        wait for waittime;--(1/freq)*1 us;
    end spi_test;
    */
end package body;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

use work.controller_pkg.all;
use work.spi_controller_tb_pkg.all;
use work.analyzer_pkg.all;
use work.analyzer_tb_pkg.all;

/*
library aldec;
use aldec.aldec_tools.all;
*/

library vunit_lib;
context vunit_lib.vunit_context;
--context vunit_lib.vc_context;

entity spi_controller_tb is
    generic (runner_cfg : string);
end spi_controller_tb;

architecture arch of spi_controller_tb is

    constant SPI_WORD_SIZE     : integer := 8;

    signal clk_100          : std_logic;
    signal rx_pclk          : std_logic;
    signal rst              : std_logic;
    signal SCLK             : std_logic;
    signal mosi             : std_logic;
    signal miso             : std_logic;
    signal cs_n             : std_logic;
    signal d_cntr           : t_controller_in;
    signal q_cntr           : t_controller_out;

    signal d_and            : t_analyzer_in;
    signal q_and            : t_analyzer_out;

    signal d_anu            : t_analyzer_in;
    signal q_anu            : t_analyzer_out;

    signal scr_data_1           : std_logic_vector (7 downto 0);
    signal rx_k_1d              : std_logic;
    signal scr_data_2           : std_logic_vector (7 downto 0);
    signal rx_k_2d              : std_logic;

    signal payload          : payload_t;
    signal spi_data_in      : payload_t;
    signal tb_end           : boolean := false;

    signal d_mem_data_out   : std_logic_vector (35 downto 0);
    signal u_mem_data_out   : std_logic_vector (35 downto 0);
    constant payload_clear  : payload_t := (others => (others => '0'));
    signal spi_read_en      : std_logic;
begin
    /*
    asdb_dump("/spi_controller_tb/rst");
    asdb_dump("/spi_controller_tb/clk_100");
    asdb_dump("/spi_controller_tb/SCLK");
    asdb_dump("/spi_controller_tb/mosi");
    asdb_dump("/spi_controller_tb/miso");
    asdb_dump("/spi_controller_tb/cs_n");
    asdb_dump("/spi_controller_tb/d_cntr");
    asdb_dump("/spi_controller_tb/q_cntr");
    asdb_dump("/spi_controller_tb/controller_inst/r");

    asdb_dump("/spi_controller_tb/rx_pclk");
    asdb_dump("/spi_controller_tb/analyzer_up/d");
    asdb_dump("/spi_controller_tb/analyzer_up/q");
    asdb_dump("/spi_controller_tb/analyzer_up/r");
    asdb_dump("/spi_controller_tb/analyzer_down/d");
    asdb_dump("/spi_controller_tb/analyzer_down/q");
    asdb_dump("/spi_controller_tb/analyzer_down/r");
    */

    main : process
    begin
        test_runner_setup (runner, runner_cfg);
        if run ("test start") then
            wait until tb_end = true;
            report "all data was transferred";
        end if;
        test_runner_cleanup(runner);
    end process;

    rst_process : process is
    begin
        rst <= '1';
        wait for 300 ns;
        rst <= '0';
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

    rx_pclk_process : process is
    begin
        rx_pclk <= '1';
        wait for 2 ns;
        rx_pclk <= '0';
        wait for 2 ns;
    end process;

    test_process: process is
        variable f : integer := 10;
        variable address : std_logic_vector (15 downto 0);
    begin
        tb_end <= false;
        sclk <= '0';
        cs_n <= '1';
        miso <= 'Z';
        mosi <= 'Z';
        address := (others => '0');
        spi_read_en <= '0';

        wait for 400 ns;
        payload <= (0 => X"01", 1 => X"03", 2 => X"01", 3 => X"01", 4 => X"01", others => (others => '0'));
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 5);

        wait for 400 ns;
        payload <= (0 => X"01", 1 => X"00", 2 => X"01", others => (others => '0'));
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 3);


        wait for 400 ns;
        payload <= (0 => X"02", 1 => X"00", others => (others => '0'));
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 2);

        wait for 400 ns;
        payload <= payload_clear;
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 10);
        wait for 1 us;

        wait for 400 ns;
        payload <= (0 => X"03", 1 => X"00", 2 => X"00", 3 => X"20", others => (others => '0'));
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 4);
        wait for 1 us;

        payload <= payload_clear;
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 33);
        wait for 1 us;

        payload <= (0 => X"03", 1 => X"00", 2 => X"00", 3 => X"00", others => (others => '0'));
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 4);
        wait for 1 us;

        payload <= payload_clear;
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 33);
        wait for 1 us;

        payload <= (0 => X"02", 1 => X"00", others => (others => '0'));
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 2);

        wait for 1 us;
        payload <= payload_clear;
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 8);
        wait for 500 us;

        for i in 0 to 2047 loop
            wait for 400 ns;
            payload <= (0 => X"03", 1 => X"00", 2 => address(15 downto 8), 3 => address(7 downto 0), others => (others => '0'));
            spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 4);

            wait for 400 ns;
            payload <= payload_clear;
            spi_read_en <= '1';
            spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 33);
            spi_read_en <= '0';
            address := address + 32;
            wait for 1 us;
        end loop;

        address := (others => '0');
        for i in 0 to 2047 loop
            wait for 400 ns;
            payload <= payload_clear;
            payload <= (0 => X"03", 1 => X"01", 2 => address(15 downto 8), 3 => address(7 downto 0), others => (others => '0'));
            spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 4);

            wait for 400 ns;
            payload <= payload_clear;
            spi_read_en <= '1';
            spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 33);
            spi_read_en <= '0';
            address := address + 32;
            wait for 1 us;
        end loop;

        tb_end <= true;
        wait;
    end process;
--*****************************************************************************************
-- SPI SLAVE DUT
--*****************************************************************************************

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

--*****************************************************************************************
-- STIM DCU
--*****************************************************************************************
    stim_up_process: process is
        file stim_file : text;
        variable fstatus : file_open_status := STATUS_ERROR;
        variable l : line;
        variable c : character;
        variable s_8 : string (1 to 2);
        variable data : std_logic_vector(7 downto 0);
        variable k : std_logic;
    begin
        wait for 10 us;
        if fstatus /= OPEN_OK then
            file_open(fstatus,stim_file, "../../read_dcu1.txt", read_mode);
            report "file opened successfull";
        end if;
        main_loop : loop
            if endfile(stim_file) = true then
                report "end of file";
                exit main_loop;
            end if;
            wait until rx_pclk = '1';
            readline (stim_file, l);
            read (l,s_8); read (l,c);
            read (l, k);
            data := x_read_f(s_8);
            d_anu.data_in_scr <= data;
            d_anu.rx_k <= k;
        end loop;

        file_close(stim_file);
        report "test file closed";
        wait;
    end process;

    stim_down_process: process is
        file stim_file : text;
        variable fstatus : file_open_status := STATUS_ERROR;
        variable l : line;
        variable c : character;
        variable s_8 : string (1 to 2);
        variable data : std_logic_vector(7 downto 0);
        variable k : std_logic;
    begin
        wait for 10 us;
        if fstatus /= OPEN_OK then
            file_open(fstatus,stim_file, "../../read_dcu2.txt", read_mode);
            report "file opened successfull";
        end if;
        main_loop : loop
            if endfile(stim_file) = true then
                report "end of file";
                exit main_loop;
            end if;
            wait until rx_pclk = '1';
            readline (stim_file, l);
            read (l,s_8); read (l,c);
            read (l, k);
            data := x_read_f(s_8);
            d_and.data_in_scr <= data;
            d_and.rx_k <= k;
        end loop;

        file_close(stim_file);
        report "test file closed";
        wait;
    end process;

--*****************************************************************************************
-- CONTROLLER
--*****************************************************************************************
    d_cntr.controller_in.data_amount_0 <= q_anu.data_amount;
    d_cntr.controller_in.data_amount_1 <= q_and.data_amount;
    d_cntr.mem_data_in <= d_mem_data_out when q_cntr.mem_select = '0' else u_mem_data_out;
    controller_inst : entity work.controller
        port map(
            clk => clk_100,
            rst => rst,
            d   => d_cntr,
            q   => q_cntr
        );


--*****************************************************************************************
-- UP LINE ANALYZER
--*****************************************************************************************

    d_anu.filter_in <= q_cntr.controller_out.filter_in;
    d_anu.trigger_set <= q_cntr.controller_out.trigger_set;
    d_anu.trigger_start <= q_cntr.controller_out.start_trig;
    d_anu.trigger_stop <= q_cntr.controller_out.stop_trig;

    analyzer_up : entity work.analyzer
    port map (
        clk => rx_pclk,
        rst => rst,
        d   => d_anu,
        q   => q_anu
    );


    ram_inst_d: entity work.pdpram
    generic map (
        addr_width => 16,
        data_width => 36
    )
    port map (
        write_en    => q_anu.wr_en,
        waddr       => q_anu.addr_wr,
        wclk        => rx_pclk,
        raddr       => q_cntr.addr_read,
        rclk        => clk_100,
        din         => q_anu.data_wr,
        dout        => d_mem_data_out
    );
    /*
    ram_inst_d : entity work.packet_ram
    port map (
        WrAddress => (others => '0'),
        RdAddress => q_cntr.addr_read(14 downto 0),
        Data => (others => '0'),
        WE => '0',
        RdClock => clk_100,
        RdClockEn => '1',
        Reset => rst, 
        WrClock => rx_pclk,
        WrClockEn => '1',
        Q => d_mem_data_out
        ); 
    */

    write_up_mem_to_file : process is
        file stim_file : text;
        variable fstatus : file_open_status := STATUS_ERROR;
        variable l : line;
    begin
        wait for 10 us;
        if fstatus /= OPEN_OK then
            file_open(fstatus,stim_file, "up_memory.mem", write_mode);
            report "file opened successfull";
        end if;
        main_loop : loop
            wait until rx_pclk = '1';
            if q_anu.wr_en = '1' then
                write(l, q_anu.data_wr, left, 36);
                writeline(stim_file,l);
            end if;
            if q_anu.stop_trigger = '1' then
                exit main_loop;
            end if;
        end loop;

        file_close(stim_file);
        report "up memory is written";
        wait;
    end process;

--*****************************************************************************************
-- DOWN LINE ANALYZER
--*****************************************************************************************

    d_and.filter_in <= q_cntr.controller_out.filter_in;
    d_and.trigger_set <= q_cntr.controller_out.trigger_set;
    d_and.trigger_start <= q_cntr.controller_out.start_trig;
    d_and.trigger_stop <= q_cntr.controller_out.stop_trig;
    analyzer_down : entity work.analyzer
    port map (
        clk => rx_pclk,
        rst => rst,
        d   => d_and,
        q   => q_and
    );

    ram_inst_u: entity work.pdpram
    generic map (
        addr_width => 16,
        data_width => 36
    )
    port map (
        write_en    => q_and.wr_en,
        waddr       => q_and.addr_wr,
        wclk        => rx_pclk,
        raddr       => q_cntr.addr_read,
        rclk        => clk_100,
        din         => q_and.data_wr,
        dout        => u_mem_data_out
    );

    write_down_mem_to_file : process is
        file stim_file : text;
        variable fstatus : file_open_status := STATUS_ERROR;
        variable l : line;
    begin
        wait for 10 us;
        if fstatus /= OPEN_OK then
            file_open(fstatus,stim_file, "down_memory.mem", write_mode);
            report "file opened successfull";
        end if;
        main_loop : loop
            wait until rx_pclk = '1';
            if q_and.wr_en = '1' then
                write(l, q_and.data_wr, left, 36);
                writeline(stim_file,l);
            end if;
            if q_and.stop_trigger = '1' then
                exit main_loop;
            end if;
        end loop;

        file_close(stim_file);
        report "down memory is written";
        wait;
    end process;

    write_readed_data_to_file : process is
        file file_out : text;
        variable fstatus : file_open_status := STATUS_ERROR;
        variable l : line;
        variable byte : std_logic_vector (7 downto 0);
        variable bit_cnt : integer;
        variable byte_cnt : integer;
    begin
        byte := (others => '0');
        bit_cnt := 0;
        byte_cnt := 0;

        if fstatus /= OPEN_OK then
            file_open(fstatus, file_out, "read_stim_out.txt", write_mode);
            report "file opened successfull";
        end if;
        main_loop : loop
            wait until clk_100 = '1';
            if spi_read_en = '1' then
                wait until SCLK = '1';
                byte(7 downto 1) := byte(6 downto 0);
                byte(0) := miso;
                if bit_cnt < 7 then
                    bit_cnt := bit_cnt + 1;
                else
                    bit_cnt := 0;
                    write(l,string'("0x"));
                    hwrite (l,byte);
                    write (l, string'(" "));
                    if byte_cnt < 32 then
                        byte_cnt := byte_cnt + 1;
                    else
                        byte_cnt := 0;
                        writeline(file_out,l);
                    end if;
                end if;
                if (tb_end = true) then
                    exit main_loop;
                end if;
            else
                byte := (others => '0');
                bit_cnt := 0;
                byte_cnt := 0;
            end if;
        end loop;
        file_close(file_out);
        report "read file closed";
        wait;
    end process;

end arch;