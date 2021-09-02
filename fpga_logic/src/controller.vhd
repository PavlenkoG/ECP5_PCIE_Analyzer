--------------------------------------------------------------------------------
-- Entity: controller
-- Date: 27 Aug 2021
-- Author: GRPA    
--
-- Description: brief
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.analyzer_pkg.all;

package controller_pkg is

    constant C_START_TRIGGER        : std_logic_vector (7 downto 0) := X"01";
    constant C_READ_MEM             : std_logic_vector (7 downto 0) := X"03";
    constant C_SET_CONFIG           : std_logic_vector (7 downto 0) := X"04";
    constant C_READ_CONFIG          : std_logic_vector (7 downto 0) := X"05";

    constant C_TRIGGER_START        : std_logic_vector (7 downto 0) := X"00";
    constant C_TRIGGER_STOP         : std_logic_vector (7 downto 0) := X"01";

    constant C_TLP_SAVE_EN          : std_logic_vector (7 downto 0) := X"02";
    constant C_DLLP_SAVE_EN         : std_logic_vector (7 downto 0) := X"03";
    constant C_ORDR_ST_SAVE_EN      : std_logic_vector (7 downto 0) := X"04";

    type t_controller_in is record
        -- user spi interface
        data_in             : std_logic_vector (7 downto 0);
        data_in_vld         : std_logic;
        data_out_rdy        : std_logic;

        trigger_evnt        : std_logic;

        -- memory 1 interface
        u_mem_data_in       : std_logic_vector (35 downto 0);
        data_amount_1       : std_logic_vector (14 downto 0);
        -- memory 2 interface
        d_mem_data_in       : std_logic_vector (35 downto 0);
        data_amount_2       : std_logic_vector (14 downto 0);
    end record;

    type t_controller_out is record
        -- user spi interface
        data_out            : std_logic_vector (7 downto 0);
        data_out_vld        : std_logic;

        -- analyzer trigger up interface
        u_trigger_start     : std_logic;
        u_trigger_stop      : std_logic;
        u_trigger_set       : t_trigger_type;
        u_filter_in         : t_filter_in;

        -- analyzer trigger downt interface
        d_trigger_start     : std_logic;
        d_trigger_stop      : std_logic;
        d_trigger_set       : t_trigger_type;
        d_filter_in         : t_filter_in;

        -- memory interface 1
        u_addr_read         : std_logic_vector (14 downto 0);
        -- memory interface 2
        d_addr_read         : std_logic_vector (14 downto 0);

    end record;
end package;
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.controller_pkg.all;
 
entity controller is
    port  (
        clk : in std_logic;        -- input clock, xx MHz.
        rst : in std_logic;
        d   : in t_controller_in;
        q   : out t_controller_out
    );
end controller;
 
architecture arch of controller is
 
    type t_state is (IDLE, CMD_ST, ADDR_ST, TRANSFER_ST);
    type reg_t is record
        -- TODO: ADDR REGISTERS HERE
        state               : t_state;
        din_rdy_d           : std_logic;
        byte_counter        : std_logic_vector (7 downto 0);

        read_addr           : std_logic_vector (14 downto 0);
    end record reg_t;
 
    constant REG_T_INIT : reg_t := (
        state               => IDLE,
        din_rdy_d           => '0',
        byte_counter        => (others => '0'),

        read_addr           => (others => '0')
    );
 
    signal r, rin : reg_t;
 
begin
 
    comb : process (r, d) is
    variable v: reg_t;
    begin
        v := r;
        v.din_rdy_d := d.data_out_rdy;

        case r.state is
        when IDLE =>
            if d.data_out_rdy = '0' and r.din_rdy_d = '1' then
                v.state := TRANSFER_ST;
            end if;
        when CMD_ST =>
        when ADDR_ST =>
        when TRANSFER_ST =>
            if d.data_out_rdy = '1' and r.din_rdy_d = '1' then
                v.state := IDLE;
            end if;
        end case;
        if r.state /= IDLE then
            if r.din_rdy_d = '1' then
                v.byte_counter := std_logic_vector(unsigned(r.byte_counter) + 1);
            end if;
        else
            v.byte_counter := (others => '0');
        end if;

        rin <= v;
    end process comb;
 
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

    q.data_out <= X"00";
    q.data_out_vld <= '0';
end arch;