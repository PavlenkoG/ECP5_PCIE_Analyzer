-----------------------------------------------------------------------------
-- Module:   pulse_filt
-- File:    pulse_filt.vhd
-----------------------------------------------------------------------------
-- COPYRIGHT BY G BACHMANN ELECTRONIC GMBH 2014
-----------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;


--! @author     WANA
--! @brief      Configurable filter
--! @details    This entity defines a configurable filter. The filter is build with an up / down counter.
--!             When the input x is high the counter is incremented until it reaches the value filter_len_sel. Then the output y goes to high.
--!             When the input x is low the counter is decremented until it reaches the value 0. Then the output y goes to low.

entity pulse_filt is
    generic (
        constant FILT_LEN : integer := 8    --! length of the filter constant
    );
    port (
        clk             : in    std_logic;  --! clock input
        rst             : in    std_logic;  --! reset (active high)
        -- Filter len select
        filt_len_sel    : std_logic_vector(FILT_LEN-1 downto 0);    --! filter value
        x               : in    std_logic;  --! signal to filter
        y               : out   std_logic   --! filtered signal
    );
end;

architecture rtl of pulse_filt is

type reg_t is record
    filter_count    : unsigned(FILT_LEN-1 downto 0);
    y               : std_logic;
end record reg_t;

-- Initial values after reset
constant REG_T_INIT : reg_t := (
    filter_count       => (others => '0'),
    y                  => '0'
);



signal r, rin : reg_t;

begin

    -- Combinatorial process
    comb : process (r,x, filt_len_sel) is
    variable v : reg_t;
    begin
        v := r;
        -- Workaround for filt_len = 0
        if unsigned(filt_len_sel) = 0 then
            v.y := x;
            v.filter_count := (others=>'0');    -- Reset filter counter
        else
            -- Pulse counter with saturation
            if x='1' then
                if r.filter_count < unsigned(filt_len_sel) then
                    v.filter_count:= r.filter_count + 1;
                end if;
            else
                if r.filter_count > 0 then
                    v.filter_count := r.filter_count - 1;
                end if;
            end if;

            -- set/reset logic for filter output
            if r.filter_count = unsigned(filt_len_sel) then
                v.y := '1';
            elsif r.filter_count = 0 then
                v.y := '0';
            end if;
        end if;

        -- Output assignments
        y <= v.y;

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
end;
