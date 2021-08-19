library ieee;
use ieee.std_logic_1164.all;

package analyzer_pkg is

    constant K_COM_SYM_28_5     : std_logic_vector(7 downto 0) := X"BC"; -- comma; used for lane and link initialization and management
    constant K_STP_SYM_27_7     : std_logic_vector(7 downto 0) := X"FB"; -- start TLP; Marks the start of a transaction layer packet
    constant K_SDP_SYM_28_2     : std_logic_vector(7 downto 0) := X"5C"; -- start DLLP; marks the start of a data link layer packet
    constant K_END_SYM_29_7     : std_logic_vector(7 downto 0) := X"FD"; -- end; marks the end of a TLP packet or DLLP packet
    constant K_EDB_SYM_30_7     : std_logic_vector(7 downto 0) := X"FE"; -- EnD Bad; marks the end of nullified TLP
    constant K_PAD_SYM_23_7     : std_logic_vector(7 downto 0) := X"F7"; -- PAD; used in framing and link width and lane ordering negotiations
    constant K_PAD_SKP_28_0     : std_logic_vector(7 downto 0) := X"1C"; -- skip; used for compensating for different bit rates 
    constant K_PAD_FTS_28_1     : std_logic_vector(7 downto 0) := X"30"; -- Fast Training Sequence; Used within a ordered set to exit from L0s to L0
    constant K_PAD_IDL_28_3     : std_logic_vector(7 downto 0) := X"7C"; -- Idle; used in the electrical idle ordered set
    constant K_PAD_EIE_28_7     : std_logic_vector(7 downto 0) := X"FC"; -- Electrical Idle Exit; Reserved in 2.5 GT/s


end package;