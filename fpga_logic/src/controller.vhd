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


    type t_controller_in is record
        -- user spi interface
        cs_n                : std_logic;
        data_in             : std_logic_vector (7 downto 0);
        data_in_vld         : std_logic;
        data_out_rdy        : std_logic;

        -- memory 1 interface
        u_mem_data_in       : std_logic_vector (35 downto 0);
        -- memory 2 interface
        mem_data_in         : std_logic_vector (35 downto 0);

        -- controller interface
        los                 : std_logic_vector (1 downto 0);
        rx_cdr_lol_s        : std_logic_vector (1 downto 0);
        lsm_status          : std_logic_vector (1 downto 0);
        rxstatus0           : std_logic_vector (1 downto 0);
        rxstatus1           : std_logic_vector (1 downto 0);
        trig_run            : std_logic;
        controller_in       : t_intf_controller_i;
    end record;

    type t_controller_out is record
        -- user spi interface
        data_out            : std_logic_vector (7 downto 0);
        data_out_vld        : std_logic;

        -- memory interface
        mem_select          : std_logic;
        addr_read           : std_logic_vector (15 downto 0);

        -- controller interface
        controller_out      : t_intf_controller_o;
    end record;
end package;
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.controller_pkg.all;

use work.analyzer_pkg.all;
 
entity controller is
    port  (
        clk : in std_logic;        -- input clock, xx MHz.
        rst : in std_logic;
        d   : in t_controller_in;
        q   : out t_controller_out
    );
end controller;
 
architecture arch of controller is
 
    type t_state is (IDLE, CMD_ST, ADDR_ST, TRANSFER_ST, WR_REG_ST);
    type reg_t is record
        -- TODO: ADDR REGISTERS HERE
        state               : t_state;
        cmd_r               : std_logic_vector (7 downto 0);
        read_memory         : std_logic;
        read_register       : std_logic;
        mem_select          : std_logic;
        next_byte           : std_logic;
        cs_n_d              : std_logic;
        din_rdy_d           : std_logic;
        byte_counter        : std_logic_vector (7 downto 0);

        data_out            : std_logic_vector (7 downto 0);
        data_out_vld        : std_logic;

        read_addr           : std_logic_vector (17 downto 0);
        mem_data            : std_logic_vector (31 downto 0);
        mem_ext_data        : std_logic_vector (7 downto 0);

        trigger_start       : std_logic;
        trigger_stop        : std_logic;
        -- register set

        intf_controller     : t_intf_controller_o;
        
    end record reg_t;
 
    constant REG_T_INIT : reg_t := (
        state               => IDLE,
        cmd_r               => (others => '0'),
        read_memory         => '0',
        read_register       => '0',
        mem_select          => '0',
        next_byte           => '0',
        cs_n_d              => '0',
        din_rdy_d           => '0',
        byte_counter        => (others => '0'),

        data_out            => (others => '0'),
        data_out_vld        => '0',

        read_addr           => (others => '0'),
        mem_data            => (others => '0'),
        mem_ext_data        => (others => '0'),

        trigger_start       => '0',
        trigger_stop        => '0',

        intf_controller     => INTF_CONTROLLER_O
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

        case r.state is
        when IDLE =>
            -- wait for falling edge of cs_n
            if d.cs_n = '0' and r.cs_n_d = '1' then
                -- when first command comes
                if r.read_memory = '0' and r.read_register = '0' then 
                    v.state := CMD_ST;
                end if;
                -- when read memory after command
                if r.read_memory = '1' or r.read_register = '1' then
                    v.state := TRANSFER_ST;
                end if;
            end if;
        when CMD_ST =>
            -- first byte is command
            v.read_addr := (others => '0');
            if d.data_in_vld = '1' then
                v.state := ADDR_ST;     -- next byte after command is address
                v.cmd_r := d.data_in;   -- save command for using in other states
            end if;
        when ADDR_ST =>
            case r.cmd_r is
            when C_WRITE_REG_CMD =>     -- write register
                if d.data_in_vld = '1' then
                    v.read_addr(7 downto 0) := d.data_in;
                    v.state := WR_REG_ST;
                end if;
            when C_READ_REG_CMD =>      -- read register
                if d.data_in_vld = '1' then
                    if r.byte_counter = X"01" then  -- register address
                        v.mem_select := d.data_in(0);
                    end if;
                end if;
                if d.cs_n = '1' then    -- end of spi transfer
                    v.read_register := '1';
                    v.state := IDLE;
                end if;
            when C_READ_MEM =>          -- read memory
                if d.data_in_vld = '1' then
                    case r.byte_counter is
                    when X"01" =>                               -- memory select 
                        v.mem_select := d.data_in(0);
                    when X"02" =>                               -- low address
                        v.read_addr(15 downto 8) := d.data_in;
                    when X"03" =>                               -- high address
                        v.read_addr(7 downto 0) := d.data_in;
                    when others =>
                    end case;
                end if;
                if d.cs_n = '1' then                            -- end of spi transfer
                    v.read_memory := '1';
                    v.state := IDLE;
                end if;
            when others =>
            end case;
        when TRANSFER_ST =>             -- read registers state
            if d.cs_n = '1' then
                v.state := IDLE;
                v.read_memory := '0';
                v.read_register := '0';
            end if;
        when WR_REG_ST =>
            if d.data_in_vld = '1' then
                v.read_addr(7 downto 0) := r.read_addr(7 downto 0) + 1;
                case r.read_addr(7 downto 0) is
                    when C_CONFIG_REG =>        -- READ ONLY
                        v.intf_controller.start_trig := d.data_in(0);
                        v.intf_controller.stop_trig := d.data_in(1);
                        v.intf_controller.reset_o := d.data_in(7);
                    when C_CONFIG_TLP =>
                        v.intf_controller.filter_in.tlp_save := d.data_in(0);
                    when C_CONFIG_DLLP =>
                        v.intf_controller.filter_in.dllp_save := d.data_in(0);
                    when C_CONFIG_ORDSET =>
                        v.intf_controller.filter_in.order_set_save := d.data_in(0);
                    when others => 
                end case;
            end if;
            if d.cs_n = '1' then                            -- end of spi transfer
                v.state := IDLE;
            end if;
        when others =>
        end case;

        -- read controller registers
        if r.read_register = '1' then
            if d.cs_n = '0' then
                -- increment address by read_rdy or falling edge on cs_n
                if (d.data_out_rdy = '1' or r.cs_n_d = '1') then
                    v.read_addr := std_logic_vector(unsigned(r.read_addr) + 1);
                end if;
            end if;
            -- address mux
            case r.read_addr(7 downto 0) is
--              when C_CONFIG_REG =>        -- READ ONLY
--                  v.data_out := X"01";
                when C_STATUS_REG_0 =>
                    v.data_out := d.trig_run & d.rxstatus0 & d.rxstatus1 & "000";
                when C_STATUS_REG_1 =>
                    v.data_out := d.lsm_status & d.rx_cdr_lol_s & d.los & "00";
                when C_CONFIG_TLP =>
                    v.data_out := "0000000" & r.intf_controller.filter_in.tlp_save;
                when C_CONFIG_DLLP =>
                    v.data_out := "0000000" & r.intf_controller.filter_in.dllp_save;
                when C_CONFIG_ORDSET =>
                    v.data_out := "0000000" & r.intf_controller.filter_in.order_set_save;
                when C_MEM_AMNT_1_LO =>
                    v.data_out := d.controller_in.data_amount_0(7 downto 0);
                when C_MEM_AMNT_1_HI =>
                    v.data_out := d.controller_in.data_amount_0(15 downto 8);
                when C_MEM_AMNT_2_LO =>
                    v.data_out := d.controller_in.data_amount_1(7 downto 0);
                when C_MEM_AMNT_2_HI =>
                    v.data_out := d.controller_in.data_amount_1(15 downto 8);
                when others => 
                    v.data_out := X"00";
            end case;
        end if;

        -- read memory
        if r.read_memory = '1' then
            if d.cs_n = '0' then
                -- increment address by read_rdy or falling edge on cs_n
                if (d.data_out_rdy = '1' or r.cs_n_d = '1') then
                    v.read_addr := std_logic_vector(unsigned(r.read_addr) + 1);
                    -- shift register for timestamp bit
                    if r.read_addr(1 downto 0) = "00" then
                        v.mem_ext_data(6 downto 0) := r.mem_ext_data(7 downto 1);
                        v.mem_ext_data(7) := d.mem_data_in(35);
                    end if;
                end if;
            end if;
            -- first 32 bytes are data
            if r.byte_counter < 31 then
                case r.read_addr(1 downto 0) is 
                    when "00" => v.data_out := d.mem_data_in (34 downto 27);
                    when "01" => v.data_out := d.mem_data_in (25 downto 18);
                    when "10" => v.data_out := d.mem_data_in (16 downto 9);
                    when "11" => v.data_out := d.mem_data_in (7 downto 0);
                    when others =>
                end case;
            -- last byte Nr.33 is timestamp flag register
            else
                v.data_out := r.mem_ext_data;
            end if;
        end if;

        -- byte counter
        if d.cs_n = '0'then
            if d.data_in_vld = '1' and r.din_rdy_d = '0' then
                v.byte_counter := std_logic_vector(unsigned(r.byte_counter) + 1);
            end if;
        else
            v.byte_counter := (others => '0');
        end if;

        if r.read_memory = '1' or r.read_register = '1' then
            v.data_out_vld := '1';
        else
            v.data_out_vld := '0';
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

    q.mem_select <= r.mem_select;
    q.data_out <= r.data_out;
    q.data_out_vld <= r.data_out_vld;
    q.addr_read <= r.read_addr(17 downto 2);
    q.controller_out <= r.intf_controller;
end arch;