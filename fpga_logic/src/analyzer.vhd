
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
begin
end  architecture arch;