--------------------------------------------------------------------------------
-- Entity: rev_analyzer
-- Date: 23 Sep 2021
-- Author: GRPA    
--
-- Description: brief
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--vhdl_comp_off
--library sinplify;
--use sinplify.attributes.all;
--vhdl_comp_on

package rev_analyzer_pkg is
    type t_rev_analyzer_in is record
        button              : std_logic;
        data_in_rx          : std_logic_vector (35 downto 0);
        data_in_tx          : std_logic_vector (35 downto 0);

        stop_trigger        : std_logic;
    end record;
    type t_rev_analyzer_out is record
        led_out             : std_logic_vector (7 downto 0);
        trigger_ena         : std_logic;
        read_addr           : std_logic_vector (14 downto 0);

        data_out_rx         : std_logic_vector (31 downto 0);
        timestamp_ena_rx    : std_logic;
        data_ena_rx         : std_logic;

        data_out_tx         : std_logic_vector (31 downto 0);
        timestamp_ena_tx    : std_logic;
        data_ena_tx         : std_logic;
    end record;
end package;
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use work.rev_analyzer_pkg.all;

--! placeholder for sinplify libraries
--vhdl_comp_off
--library sinplify;
--use sinplify.attributes.all;
--vhdl_comp_on
 
entity rev_analyzer is
    port  (
        clk : in std_logic;        -- input clock, xx MHz.
        rst : in std_logic;
        d   : in t_rev_analyzer_in;
        q   : out t_rev_analyzer_out
    );
    attribute syn_preserve : boolean;
    attribute syn_preserve of q : signal is true;
end rev_analyzer;
 
architecture arch of rev_analyzer is
 
    type t_state is (WAIT_ST, TRIGGER_ST, READ_ST);
    type reg_t is record
        button_del              : std_logic;
        led_out                 : std_logic_vector (7 downto 0);
        trigger_ena             : std_logic;
        trigger_stop            : std_logic_vector (1 downto 0);
        wait_cnt                : std_logic_vector (3 downto 0);
        read_addr               : std_logic_vector (14 downto 0);
        state                   : t_state;

        read_data_rx            : std_logic_vector (31 downto 0);
        timestamp_rx            : std_logic;
        data_ena_rx             : std_logic;

        read_data_tx            : std_logic_vector (31 downto 0);
        timestamp_tx            : std_logic;
        data_ena_tx             : std_logic;

    end record reg_t;
 
    constant REG_T_INIT : reg_t := (
        button_del              => '0',
        led_out                 => (others => '0'),
        trigger_ena             => '0',
        trigger_stop            => (others => '0'),
        wait_cnt                => (others => '0'),
        read_addr               => (others => '0'),
        state                   => WAIT_ST,

        read_data_rx            => (others => '0'),
        timestamp_rx            => '0',
        data_ena_rx             => '0',

        read_data_tx            => (others => '0'),
        timestamp_tx            => '0',
        data_ena_tx             => '0'
    );
 
    signal r, rin : reg_t;

--******************************************************************************
-- REVEAL ANALYZER SIGNALS
-- placeholder for debug
-- attributes used to prevent signals optimizing
--******************************************************************************
    signal data_in_rx               : std_logic_vector (31 downto 0);
    signal data_in_tx               : std_logic_vector (31 downto 0);
    signal timestamp_flag_rx        : std_logic;
    signal timestamp_flag_tx        : std_logic;
    signal data_ena_rx              : std_logic;
    signal data_ena_tx              : std_logic;
--
    attribute syn_preserve of data_in_rx          : signal is true;
    attribute syn_preserve of timestamp_flag_rx   : signal is true;
    attribute syn_preserve of data_ena_rx         : signal is true;
    attribute syn_preserve of data_ena_tx         : signal is true;
    attribute syn_preserve of data_in_tx          : signal is true;
    attribute syn_preserve of timestamp_flag_tx   : signal is true;
--******************************************************************************
 
begin

    data_in_rx <= d.data_in_rx(34 downto 27) & d.data_in_rx(25 downto 18) & d.data_in_rx(16 downto 9) & d.data_in_rx(7 downto 0);
    timestamp_flag_rx <= d.data_in_rx(35);
    data_ena_rx <= '1' when r.state = READ_ST else '0';
    data_in_tx <= d.data_in_tx(34 downto 27) & d.data_in_tx(25 downto 18) & d.data_in_tx(16 downto 9) & d.data_in_tx(7 downto 0);
    timestamp_flag_tx <= d.data_in_tx(35);
    data_ena_tx <= '1' when r.state = READ_ST else '0';
 
    comb : process (r, d) is
    variable v: reg_t;
    begin
        v := r;
        v.button_del := d.button;
        v.trigger_stop := r.trigger_stop(0) & d.stop_trigger;

        v.read_data_rx := d.data_in_rx(34 downto 27) & d.data_in_rx(25 downto 18) & d.data_in_rx(16 downto 9) & d.data_in_rx(7 downto 0);
        v.timestamp_rx := d.data_in_rx(35);

        v.read_data_tx := d.data_in_tx(34 downto 27) & d.data_in_tx(25 downto 18) & d.data_in_tx(16 downto 9) & d.data_in_tx(7 downto 0);
        v.timestamp_tx := d.data_in_tx(35);

        case r.state is
        when WAIT_ST =>
            v.led_out(7) := '0';
            v.led_out(6) := '1';
            v.led_out(5) := '1';
            v.data_ena_rx := '0';
            v.data_ena_tx := '0';
            if r.button_del = '0' and d.button = '1' then
                v.trigger_ena := '1';
                v.state := TRIGGER_ST;
            end if;
        when TRIGGER_ST =>
            v.led_out(7) := '0';
            v.led_out(6) := '0';
            v.led_out(5) := '1';
            if r.trigger_stop(1) = '0' and r.trigger_stop(0) = '1' then
                v.state := READ_ST;
            end if;
        when READ_ST =>
            v.led_out(7) := '0';
            v.led_out(6) := '0';
            v.led_out(5) := '0';
            if r.read_addr < 15X"00FF" then
                v.read_addr := r.read_addr + 1;
                v.data_ena_rx := '1';
                v.data_ena_tx := '1';
            else
                v.read_addr := (others => '0');
                v.state := WAIT_ST;
            end if;
        end case;

        if r.trigger_ena = '1' then
            if r.wait_cnt < "1111" then
                v.wait_cnt := r.wait_cnt + 1;
            else
                v.trigger_ena := '0';
                v.wait_cnt := (others => '0');
            end if;
        end if;
        --TODO: ADD YOUR CODE HERE
        rin <= v;
    end process comb;
 
    q.read_addr <= r.read_addr;
    q.led_out <= r.led_out;
    q.trigger_ena <= r.trigger_ena;

    q.data_out_rx <= r.read_data_rx;
    q.timestamp_ena_rx <= r.timestamp_rx;
    q.data_ena_rx <= r.data_ena_rx;

    q.data_out_tx <= r.read_data_tx;
    q.timestamp_ena_tx <= r.timestamp_tx;
    q.data_ena_tx <= r.data_ena_tx;

    -- Register process
    regs : process (clk) is
    begin
        -- Synchronous reset
        if rising_edge(clk) then
            if rst = '1' then
                r <= REG_T_INIT;
            else
                r <= rin;
            end if;               
        end if;  
    end process regs;
end arch;