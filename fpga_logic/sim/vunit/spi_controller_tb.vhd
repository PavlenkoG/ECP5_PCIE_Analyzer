library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

package spi_controller_tb_pkg is
    type payload_t is array (0 to 128) of std_logic_vector (7 downto 0);
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
end package;
package body spi_controller_tb_pkg is
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
    signal rst              : std_logic;
    signal SCLK             : std_logic;
    signal mosi             : std_logic;
    signal miso             : std_logic;
    signal cs_n             : std_logic;
    signal d_cntr           : t_controller_in;
    signal q_cntr           : t_controller_out;

    signal payload          : payload_t;
    signal spi_data_in      : payload_t;
    signal tb_end           : boolean := false;

    signal d_mem_data_out   : std_logic_vector (35 downto 0);
    signal u_mem_data_out   : std_logic_vector (35 downto 0);
    constant payload_clear  : payload_t := (others => (others => '0'));
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

    test_process: process is
        variable f : integer := 10;
    begin
        tb_end <= false;
        sclk <= '0';
        cs_n <= '1';
        miso <= 'Z';
        mosi <= 'Z';

        wait for 400 ns;
        payload(0) <= X"01";        -- write reg cmd
        payload(1) <= X"03";        -- config tlp
        payload(2) <= X"01";        -- address hi 
        payload(3) <= X"01";        -- address lo 
        payload(4) <= X"01";        -- address lo 
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 5);

        wait for 400 ns;
        payload(0) <= X"01";        -- write reg cmd
        payload(1) <= X"00";        -- config tlp
        payload(2) <= X"01";        -- address hi 
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 3);

        wait for 400 ns;
        payload(0) <= X"02";        -- write reg cmd
        payload(1) <= X"00";        -- config tlp
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 2);

        wait for 400 ns;
        payload <= payload_clear;
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 10);
        wait for 1 us;

        wait for 400 ns;
        payload(0) <= X"03";        -- read memory
        payload(1) <= X"00";        -- select mem
        payload(2) <= X"00";        -- address hi 
        payload(3) <= X"20";        -- address lo 
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 4);
        wait for 1 us;

        payload <= payload_clear;
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 33);
        wait for 1 us;

        payload(0) <= X"03";        -- read memory
        payload(1) <= X"00";        -- select mem
        payload(2) <= X"00";        -- address hi 
        payload(3) <= X"00";        -- address lo 
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 4);
        wait for 1 us;

        payload <= payload_clear;
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 33);
        wait for 1 us;

        payload(0) <= X"02";        -- read memory
        payload(1) <= X"00";        -- select mem
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 2);
        wait for 1 us;
        payload <= payload_clear;
        spi_test(freq => f, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 8);
        wait for 1 us;

        tb_end <= true;
        wait;

    end process;

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

    d_cntr.mem_data_in <= d_mem_data_out when q_cntr.mem_select = '0' else u_mem_data_out;
    controller_inst : entity work.controller
        port map(
            clk => clk_100,
            rst => rst,
            d   => d_cntr,
            q   => q_cntr
        );
    ram_inst_d: entity work.pdpram
    generic map (
        addr_width => 16,
        data_width => 36
    )
    port map (
        write_en    => '0',
        waddr       => (others => '0'),
        wclk        => '0',
        raddr       => q_cntr.addr_read,
        rclk        => clk_100,
        din         => (others => '0'),
        dout        => d_mem_data_out
    );

    ram_inst_u: entity work.pdpram
    generic map (
        addr_width => 16,
        data_width => 36
    )
    port map (
        write_en    => '0',
        waddr       => (others => '0'),
        wclk        => '0',
        raddr       => q_cntr.addr_read,
        rclk        => clk_100,
        din         => (others => '0'),
        dout        => u_mem_data_out
    );

end arch;