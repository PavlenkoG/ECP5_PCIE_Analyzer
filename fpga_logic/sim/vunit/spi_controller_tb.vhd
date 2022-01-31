
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

use work.controller_pkg.all;
use work.analyzer_tb_pkg.all;
use work.analyzer_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

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

    signal mem_data_out     : std_logic_vector (35 downto 0);
begin
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
    begin
        tb_end <= false;
        sclk <= '0';
        cs_n <= '1';
        miso <= 'Z';
        mosi <= 'Z';

        wait for 400 ns;
        payload(0) <= X"03";        -- read memory
        payload(1) <= X"00";        -- address lo
        payload(2) <= X"00";        -- address high
        spi_test(freq => 62, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 3);
        wait for 1 us;

        payload(0) <= X"00";        -- read memory
        payload(1) <= X"00";        -- address lo
        payload(2) <= X"00";        -- address high
        payload(3) <= X"00";
        payload(4) <= X"00";
        payload(5) <= X"00";
        payload(6) <= X"00";
        payload(7) <= X"00";
        payload(8) <= X"00";
        spi_test(freq => 62, clk => sclk, miso => miso, mosi => mosi, cs => cs_n, data_in => payload, data_out => spi_data_in, len => 10);
        wait for 5 us;
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
            DOUT_VLD => d_cntr.data_in_vld
        );

    d_cntr.cs_n <= cs_n;
    d_cntr.d_mem_data_in <= mem_data_out;
    controller_inst : entity work.controller
        port map(
            clk => clk_100,
            rst => rst,
            d   => d_cntr,
            q   => q_cntr
        );
    ram_inst: entity work.pdpram
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
        dout        => mem_data_out
    );

end arch;