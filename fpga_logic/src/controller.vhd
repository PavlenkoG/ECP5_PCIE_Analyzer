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

    constant C_WRITE_REG_CMD        : std_logic_vector (7 downto 0) := X"01";
    constant C_READ_REG_CMD         : std_logic_vector (7 downto 0) := X"02";
    constant C_READ_MEM             : std_logic_vector (7 downto 0) := X"03";

    constant C_CONFIG_REG           : std_logic_vector (7 downto 0) := X"00";   -- config register
    constant C_STATUS_REG           : std_logic_vector (7 downto 0) := X"01";   -- status register
    constant C_CONFIG_TLP           : std_logic_vector (7 downto 0) := X"02";
    constant C_CONFIG_DLLP          : std_logic_vector (7 downto 0) := X"03";
    constant C_CONFIG_ORDSET        : std_logic_vector (7 downto 0) := X"04";
    constant C_MEM_AMNT_1_LO        : std_logic_vector (7 downto 0) := X"05";   -- entries of memory 1
    constant C_MEM_AMNT_1_HI        : std_logic_vector (7 downto 0) := X"06";
    constant C_MEM_AMNT_2_LO        : std_logic_vector (7 downto 0) := X"07";   -- entries of memory 2
    constant C_MEM_AMNT_2_HI        : std_logic_vector (7 downto 0) := X"08";

    type t_controller_in is record
        cs_n                : std_logic;
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

        trigger_start     : std_logic;
        trigger_stop      : std_logic;
        -- analyzer trigger up interface
        u_trigger_set       : t_trigger_type;
        u_filter_in         : t_filter_in;

        -- analyzer trigger downt interface
        d_trigger_set       : t_trigger_type;
        d_filter_in         : t_filter_in;

        -- memory interface
        addr_read         : std_logic_vector (15 downto 0);
    end record;
end package;
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
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
 
    type t_state is (IDLE, CMD_ST,  ADDR_ST, TRANSFER_ST, WAIT_ST);
    type t_controller_state is (IDLE, READ_CONFIG, WRITE_CONFIG, READ_MEMORY);
    type reg_t is record
        -- TODO: ADDR REGISTERS HERE
        state               : t_state;
        cntr_state          : t_controller_state;
        cs_n_d              : std_logic;
        din_rdy_d           : std_logic;
        byte_counter        : std_logic_vector (7 downto 0);

        data_out            : std_logic_vector (7 downto 0);
        data_out_vld        : std_logic;

        read_addr           : std_logic_vector (15 downto 0);
        mem_data            : std_logic_vector (31 downto 0);
        mem_ext_data        : std_logic_vector (7 downto 0);

        trigger_start       : std_logic;
        trigger_stop        : std_logic;
        
    end record reg_t;
 
    constant REG_T_INIT : reg_t := (
        state               => IDLE,
        cntr_state          => IDLE,
        cs_n_d              => '0',
        din_rdy_d           => '0',
        byte_counter        => (others => '0'),

        data_out            => (others => '0'),
        data_out_vld        => '0',

        read_addr           => (others => '0'),
        mem_data            => (others => '0'),
        mem_ext_data        => (others => '0'),

        trigger_start       => '0',
        trigger_stop        => '0' 
    );
 
    signal r, rin : reg_t;
 
begin
 
    comb : process (r, d) is
    variable v: reg_t;
    begin
        v := r;
        v.cs_n_d := d.cs_n;
        v.din_rdy_d := d.data_out_rdy;
        if d.data_out_rdy = '1' then
            v.data_out_vld := '0';
        end if;

        v.trigger_start := '0';
        v.trigger_stop := '0';
        if r.read_addr(15) = '1' then
            v.mem_data(31 downto 24) := d.d_mem_data_in (34 downto 27);
            v.mem_data(23 downto 16) := d.d_mem_data_in (25 downto 18);
            v.mem_data(15 downto 8) := d.d_mem_data_in (16 downto 9);
            v.mem_data(7 downto 0) := d.d_mem_data_in (7 downto 0);
        else
            v.mem_data(31 downto 24) := d.u_mem_data_in (34 downto 27);
            v.mem_data(23 downto 16) := d.u_mem_data_in (25 downto 18);
            v.mem_data(15 downto 8) := d.u_mem_data_in (16 downto 9);
            v.mem_data(7 downto 0) := d.u_mem_data_in (7 downto 0);
        end if;
        case r.cntr_state is
            --(IDLE, READ_CONFIG, WRITE_CONFIG, READ_MEMORY);
            when IDLE => 

            when READ_CONFIG =>
            when WRITE_CONFIG => 
            when READ_MEMORY =>
                if d.cs_n = '0' and r.cs_n_d = '1' then
                    v.data_out_vld := '1';
                end if;
                if (to_integer(unsigned(r.byte_counter)) = 4) then
                    v.read_addr := r.read_addr + 1;
                end if;
                if r.read_addr(1 downto 0) = "00" then
                    v.mem_ext_data (3 downto 0) := d.d_mem_data_in(35) & d.d_mem_data_in(26) & d.d_mem_data_in(17) & d.d_mem_data_in(8);
                end if;
                if r.read_addr(1 downto 0) = "10" then
                    v.mem_ext_data (7 downto 4) := d.d_mem_data_in(35) & d.d_mem_data_in(26) & d.d_mem_data_in(17) & d.d_mem_data_in(8);
                end if;
                case r.byte_counter(1 downto 0) is
                    when "00" =>
                        v.data_out := d.d_mem_data_in(7 downto 0);
                    when "01" =>
                        v.data_out := d.d_mem_data_in(16 downto 9);
                    when "10" =>
                        v.data_out := d.d_mem_data_in(25 downto 18);
                    when "11" =>
                        v.data_out := d.d_mem_data_in(34 downto 27);
                    when others =>
                end case;
                if d.cs_n = '1' and r.cs_n_d = '0' then
                    v.cntr_state := IDLE;
                end if;

        end case;
        case r.state is
        when IDLE =>
            if d.cs_n = '0' and r.cs_n_d = '1' then
                if r.cntr_state = IDLE then 
                    v.state := CMD_ST;
                end if;
            end if;
        when CMD_ST =>
            if d.data_in_vld = '1' then
                v.state := ADDR_ST;
                case d.data_in is
                when C_WRITE_REG_CMD =>
                when C_READ_REG_CMD =>
                when C_READ_MEM =>
                    v.cntr_state := READ_MEMORY;
                    v.state := ADDR_ST;
                when others => 
                end case;
            end if;
            if d.cs_n = '1' then
                v.state := CMD_ST;
            end if;
        when ADDR_ST =>
            if d.data_in_vld = '1' then
                case r.byte_counter is
                when X"01"=>
                    v.read_addr(15 downto 8) := d.data_in;
                when X"02" =>
                    v.read_addr(7 downto 0) := d.data_in;
                    v.state := TRANSFER_ST;
                when others =>
                end case;
            end if;
            if d.cs_n = '1' then
            end if;
        when TRANSFER_ST =>
            if d.data_out_rdy = '1' and r.din_rdy_d = '1' then
                v.state := WAIT_ST;
            elsif d.data_out_rdy = '1' then
                v.read_addr := std_logic_vector(unsigned(r.read_addr) + 1);
            end if;
            if r.din_rdy_d = '1' then
            end if;
            if r.read_addr(1 downto 0) = "00" then
                v.mem_ext_data (3 downto 0) := d.d_mem_data_in(35) & d.d_mem_data_in(26) & d.d_mem_data_in(17) & d.d_mem_data_in(8);
            end if;
            if r.read_addr(1 downto 0) = "10" then
                v.mem_ext_data (7 downto 4) := d.d_mem_data_in(35) & d.d_mem_data_in(26) & d.d_mem_data_in(17) & d.d_mem_data_in(8);
            end if;
            if d.cs_n = '1' then
                v.state := CMD_ST;
            end if;
        when WAIT_ST =>
            v.state := IDLE;
            if d.cs_n = '1' then
                v.state := CMD_ST;
            end if;
        when others =>
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

    q.data_out <= r.data_out;
    q.data_out_vld <= r.data_out_vld;
    q.trigger_start <= r.trigger_start;
    q.trigger_stop <= r.trigger_stop;
    q.addr_read <= r.read_addr;
end arch;