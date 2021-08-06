--------------------------------------------------------------------------------
-- Entity: BP_pkg
-- Date:2016-12-09
-- Author: GRPA
--
-- Description:
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

package top_pkg is

    constant MODUL_NUM_CONST : integer := 32;               --! deprecated, not used in new design

    -- debug settings
    constant PCIE_RX_DEBUG_ENA : BOOLEAN        := FALSE;    -- reveal analyzer inserter

    -- SIO commands
    constant SET_DATA_4 : std_logic_vector (7 downto 0) := X"24";
    constant INIT_ISR   : std_logic_vector (7 downto 0) := X"30";

    -- function to calculate FirstDW and LastDW fields
    function dw_assign (addr : std_logic_vector(1 downto 0); len : std_logic_vector (6 downto 0)) return std_logic_vector;
    -- function to calculate LENGTH field for TLP Header
    function len_calc (addr : std_logic_vector (1 downto 0); len : std_logic_vector (6 downto 0)) return std_logic_vector;

end package;


package body top_pkg is

--------------------------------------------------------------------------------
-- assign dw field
--------------------------------------------------------------------------------
    function dw_assign (addr : std_logic_vector(1 downto 0); len : std_logic_vector (6 downto 0)) return std_logic_vector is
        variable dw : std_logic_vector (7 downto 0);
        variable len_temp : std_logic_vector (6 downto 0);
        variable l        : std_logic_vector (6 downto 0);
    begin
        dw := "00000000";
        if (unsigned(len)) < 5 then
            l := std_logic_vector(unsigned(len) - 1);
        else
            l := "0000011";
        end if;
        -- assign first DW
        -- is solved with Karnaugh map
        dw(0) := (not addr(0)) and (not addr(1));
        dw(1) := (addr(0) and (not addr(1))) or (l(0) and (not addr(1))) or (l(1) and (not addr(1)));
        dw(2) := ((not addr(0)) and addr(1)) or (l(1) and (not addr(1))) or (l(0) and addr(0) and (not addr(1)));
        dw(3) := (l(1) or addr(1)) and (l(0) or addr(0) or addr(1)) and (l(0) or l(1) or addr(0));
        -- assign last DW
        len_temp := std_logic_vector(unsigned(len) - dw(0) - dw(1) - dw(2) - dw(3));
        if (unsigned(len_temp)) > 0 then
            case len_temp(1 downto 0) is
            when "00" => dw(7 downto 4) := "1111";
            when "01" => dw(7 downto 4) := "0001";
            when "10" => dw(7 downto 4) := "0011";
            when "11" => dw(7 downto 4) := "0111";
            when others =>
            end case;
        end if;
        return dw;
    end dw_assign;

--------------------------------------------------------------------------------
-- length field in TLP packet calculate
--------------------------------------------------------------------------------
    function len_calc (addr : std_logic_vector (1 downto 0); len : std_logic_vector (6 downto 0)) return std_logic_vector is
        variable len_t : std_logic_vector (9 downto 0);
    begin
        if (unsigned(len)) >= 4 then
       -- lenght = (len + addr + 3)/4
          len_t := std_logic_vector(unsigned(addr) + ("000"&(unsigned(len)) + 3));
        else
          len_t := "0000000100";
          if (unsigned(len)) = 2 and (unsigned(addr)) = 3 then len_t := "0000001000"; end if;
          if (unsigned(len)) = 3 and (unsigned(addr)) > 1 then len_t := "0000001000"; end if;
        end if;
        return "00" & len_t (9 downto 2);
    end len_calc;

end package body;
