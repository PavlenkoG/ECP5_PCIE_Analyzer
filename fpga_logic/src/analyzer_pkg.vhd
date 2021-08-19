library ieee;
use ieee.std_logic_1164.all;

package analyzer_pkg is
    constant MEM_LEN            : integer := 16;

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

    --                                                              FMT TYPE
    constant TLP_TYPE_MRD       : std_logic_vector (7 downto 0) := "000_00000";
    constant TLP_TYPE_MRDLK     : std_logic_vector (7 downto 0) := "000_00001";
    constant TLP_TYPE_MWR       : std_logic_vector (7 downto 0) := "010_00000";
    constant TLP_TYPE_IORD      : std_logic_vector (7 downto 0) := "000_00010";
    constant TLP_TYPE_IOWR      : std_logic_vector (7 downto 0) := "010_00010";
    constant TLP_TYPE_CFGRD0    : std_logic_vector (7 downto 0) := "000_00100";
    constant TLP_TYPE_CFGWR0    : std_logic_vector (7 downto 0) := "010_00100";
    constant TLP_TYPE_CFGRD1    : std_logic_vector (7 downto 0) := "000_00101";
    constant TLP_TYPE_CFGWR1    : std_logic_vector (7 downto 0) := "010_00101";
    constant TLP_TYPE_TCFGRD    : std_logic_vector (7 downto 0) := "000_11011";
    constant TLP_TYPE_TCFGWR    : std_logic_vector (7 downto 0) := "010_11011";
    constant TLP_TYPE_MSG       : std_logic_vector (7 downto 0) := "001_10000";
    constant TLP_TYPE_MSGD      : std_logic_vector (7 downto 0) := "011_10000";
    constant TLP_TYPE_CPL       : std_logic_vector (7 downto 0) := "000_01010";
    constant TLP_TYPE_CPLD      : std_logic_vector (7 downto 0) := "010_01010";
    constant TLP_TYPE_CPLLK     : std_logic_vector (7 downto 0) := "000_01011";
    constant TLP_TYPE_CPLDLK    : std_logic_vector (7 downto 0) := "010_01011";


    type t_analyzer_in is record
        data_in             : std_logic_vector (7 downto 0);
        rx_k                : std_logic;
    end record;

    type t_analyzer_out is record
        addr_wr             : std_logic_vector (MEM_LEN - 1 downto 0);
    end record;

    type t_packet_type is (DLLP_PKT, TLP_PKT, ORDR_ST);
    type t_tlp_type is (MRD, MRDLK, MWR, IORD, IOWR, CFGRD0, CFGWR0, CFGRD1, CFGWR1, TCFGRD, TCFGWR, MSG, MSGD, CPL, CPLD, CPLLK, CPLDLK);
end package;