
library ieee;
use ieee.std_logic_1164.all;
use work.analyzer_pkg.all;

entity analyzer is
    port (
        clk             : in std_logic;
        rst             : in std_logic;
        d               : t_analyzer_in;
        q               : t_analyzer_out
    );
end analyzer;

architecture arch of analyzer is
    type t_reg is record
        reg1            : std_logic;
    end record t_reg;

    constant REG_T_INIT : t_reg := (
        reg1            => '0'
    );

    signal r, rin : t_reg;
begin
    comb : process (r, d) is
        variable v: t_reg;
    begin
        v := r;
        rin <= v;
    end process comb;

    regs: process (clk) is
    begin
        if rising_edge (clk) then
            if rst = '1' then
                r <= REG_T_INIT;
            else
                r <= rin;
            end if;
        end if;
    end process regs;
end  architecture arch;