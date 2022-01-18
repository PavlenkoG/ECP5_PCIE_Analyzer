
--
-- Verific VHDL Description of module EXTREFB
--

-- EXTREFB is a black-box. Cannot print a valid VHDL entity description for it

--
-- Verific VHDL Description of module extref
--

library ieee ;
use ieee.std_logic_1164.all ;

library ecp5um ;
use ecp5um.components.all ;

entity extref is
    port (refclkp: in std_logic;
        refclkn: in std_logic;
        refclko: out std_logic
    );
    
end entity extref;

architecture v1 of extref is 
    signal n2,n1,gnd,pwr : std_logic; 
    attribute LOC : string;
    attribute LOC of EXTREF0_inst : label is "EXTREF0";
begin
    EXTREF0_inst: component EXTREFB generic map (REFCK_PWDNB=>"0b1",REFCK_RTERM=>"0b1",
        REFCK_DCBIAS_EN=>"0b0")
     port map (REFCLKP=>refclkp,REFCLKN=>refclkn,REFCLKO=>refclko);
    n2 <= '1' ;
    n1 <= '0' ;
    gnd <= '0' ;
    pwr <= '1' ;
    
end architecture v1;

