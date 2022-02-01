--! analyzer package
library ieee;
use ieee.std_logic_1164.all;

package analyzer_pkg is
    constant MEM_LEN            : integer := 16;

    constant K_PAD_SYM_23_7     : std_logic_vector(7 downto 0) := X"F7"; -- PAD; used in framing and link width and lane ordering negotiations
    constant K_STP_SYM_27_7     : std_logic_vector(7 downto 0) := X"FB"; -- start TLP; Marks the start of a transaction layer packet
    constant K_PAD_SKP_28_0     : std_logic_vector(7 downto 0) := X"1C"; -- skip; used for compensating for different bit rates 
    constant K_PAD_FTS_28_1     : std_logic_vector(7 downto 0) := X"30"; -- Fast Training Sequence; Used within a ordered set to exit from L0s to L0
    constant K_SDP_SYM_28_2     : std_logic_vector(7 downto 0) := X"5C"; -- start DLLP; marks the start of a data link layer packet
    constant K_PAD_IDL_28_3     : std_logic_vector(7 downto 0) := X"7C"; -- Idle; used in the electrical idle ordered set
    constant K_COM_SYM_28_5     : std_logic_vector(7 downto 0) := X"BC"; -- comma; used for lane and link initialization and management
    constant K_PAD_EIE_28_7     : std_logic_vector(7 downto 0) := X"FC"; -- Electrical Idle Exit; Reserved in 2.5 GT/s
    constant K_END_SYM_29_7     : std_logic_vector(7 downto 0) := X"FD"; -- end; marks the end of a TLP packet or DLLP packet
    constant K_EDB_SYM_30_7     : std_logic_vector(7 downto 0) := X"FE"; -- EnD Bad; marks the end of nullified TLP

    -- TLP Packet Types
    --                                                               FMT TYPE
    constant TLP_TYPE_MRD3      : std_logic_vector (7 downto 0) := B"000_00000"; -- Memory read request 3DW
    constant TLP_TYPE_MRD4      : std_logic_vector (7 downto 0) := B"001_00000"; -- Memory read request 4DW
    constant TLP_TYPE_MRDLK3    : std_logic_vector (7 downto 0) := B"000_00001"; -- Memory read lock request 3DW
    constant TLP_TYPE_MRDLK4    : std_logic_vector (7 downto 0) := B"001_00001"; -- Memory read lock request 4DW
    constant TLP_TYPE_MWR3      : std_logic_vector (7 downto 0) := B"010_00000"; -- Memory write request 3DW
    constant TLP_TYPE_MWR4      : std_logic_vector (7 downto 0) := B"011_00000"; -- Memory write request 4DW
    constant TLP_TYPE_IORD      : std_logic_vector (7 downto 0) := B"000_00010"; -- IO Read request
    constant TLP_TYPE_IOWR      : std_logic_vector (7 downto 0) := B"010_00010"; -- IO Write request
    constant TLP_TYPE_CFGRD0    : std_logic_vector (7 downto 0) := B"000_00100"; -- Config type 0 Read request
    constant TLP_TYPE_CFGWR0    : std_logic_vector (7 downto 0) := B"010_00100"; -- Config type 0 Write request
    constant TLP_TYPE_CFGRD1    : std_logic_vector (7 downto 0) := B"000_00101"; -- Config type 1 Read request
    constant TLP_TYPE_CFGWR1    : std_logic_vector (7 downto 0) := B"010_00101"; -- Config type 1 Write request
    constant TLP_TYPE_TCFGRD    : std_logic_vector (7 downto 0) := B"000_11011"; -- 
    constant TLP_TYPE_TCFGWR    : std_logic_vector (7 downto 0) := B"010_11011";
    constant TLP_TYPE_MSG       : std_logic_vector (7 downto 0) := B"001_10000"; -- Message request
    constant TLP_TYPE_MSGD      : std_logic_vector (7 downto 0) := B"011_10000"; -- Message request with data
    constant TLP_TYPE_CPL       : std_logic_vector (7 downto 0) := B"000_01010"; -- Completion
    constant TLP_TYPE_CPLD      : std_logic_vector (7 downto 0) := B"010_01010"; -- Completion with data
    constant TLP_TYPE_CPLLK     : std_logic_vector (7 downto 0) := B"000_01011"; -- Completion/Locked
    constant TLP_TYPE_CPLDLK    : std_logic_vector (7 downto 0) := B"010_01011"; -- Completion with data

    -- DLLP Packet Types
    constant DLLP_TYPE_ACK     : std_logic_vector (7 downto 0) := B"0000_0000"; -- TLP Acknowledge
    constant DLLP_TYPE_NAK     : std_logic_vector (7 downto 0) := B"0001_0000"; -- TLP Negative acknowledge
    constant DLLP_TYPE_PM_L1   : std_logic_vector (7 downto 0) := B"0010_0000"; -- Power management Enter L1
    constant DLLP_TYPE_PM_L23  : std_logic_vector (7 downto 0) := B"0010_0001"; -- Power management Enter L23
    constant DLLP_TYPE_PM_ASR1 : std_logic_vector (7 downto 0) := B"0010_0011"; -- Power management Active state request L1
    constant DLLP_TYPE_REQ_ACK : std_logic_vector (7 downto 0) := B"0010_0100"; -- Power management request ack
    constant DLLP_TYPE_VEN_SP  : std_logic_vector (7 downto 0) := B"0011_0000"; -- vendor specific
    constant DLLP_TYPE_FC1P    : std_logic_vector (7 downto 0) := B"0100_0000"; -- InitFC1-P
    constant DLLP_TYPE_FC1NP   : std_logic_vector (7 downto 0) := B"0101_0000"; -- InitFC1-NP
    constant DLLP_TYPE_FC1CPL  : std_logic_vector (7 downto 0) := B"0110_0000"; -- InitFC1-Cpl
    constant DLLP_TYPE_FC2P    : std_logic_vector (7 downto 0) := B"1100_0000"; -- InitFC2-P
    constant DLLP_TYPE_FC2NP   : std_logic_vector (7 downto 0) := B"1101_0000"; -- InitFC2-NP
    constant DLLP_TYPE_FC2CPL  : std_logic_vector (7 downto 0) := B"1110_0000"; -- InitFC2-Cpl
    constant DLLP_TYPE_FCP     : std_logic_vector (7 downto 0) := B"1000_0000"; -- UpdateFC-P
    constant DLLP_TYPE_FCNP    : std_logic_vector (7 downto 0) := B"1001_0000"; -- UpdateFC-NP
    constant DLLP_TYPE_FCCPL   : std_logic_vector (7 downto 0) := B"1010_0000"; -- UpdateFC-Cpl

    type t_packet_type is (DLLP_PKT, TLP_PKT, ORDR_ST, IDLE);
    type t_tlp_type is (NO_PCK, MRD, MRDLK, MWR, IORD, IOWR, CFGRD0, CFGWR0, CFGRD1, CFGWR1, TCFGRD, TCFGWR, MSG, MSGD, CPL, CPLD, CPLLK, CPLDLK);
    type t_dllp_type is (NO_PCK, ACK, NAK, PM_L1, PM_L23, PM_ASR1, REQ_ACK, VEN_SP, FC1P, FC1NP, FC1CPL, FC2P, FC2NP, FC2CPL, FCP, FCNP, FCCPL);
    type t_order_set_type is (NO_PCK, TS1, TS2, SKIP, FTS, EIDLE);

    type t_trigger_type is record
        packet_type_en      : std_logic;
        packet_type         : t_packet_type;

        tlp_type_en         : std_logic;
        tlp_type            : t_tlp_type;

        dllp_type_en        : std_logic;
        dllp_type           : t_dllp_type;

        order_set_en        : std_logic;
        order_set_type      : t_order_set_type;

        addr_match_en       : std_logic;
        addr_match          : std_logic_vector (31 downto 0);
    end record;

    type t_filter_in is record
        tlp_save            : std_logic;
        dllp_save           : std_logic;
        order_set_save      : std_logic;
    end record;

    type t_analyzer_in is record
        data_in_unscr       : std_logic_vector (7 downto 0);
        data_in_scr         : std_logic_vector (7 downto 0);
        rx_k                : std_logic;

        trigger_start       : std_logic;
        trigger_stop        : std_logic;
        trigger_set         : t_trigger_type;
        filter_in           : t_filter_in;
    end record;

    type t_analyzer_out is record
        addr_wr             : std_logic_vector (15 downto 0);
        data_wr             : std_logic_vector (35 downto 0);
        wr_en               : std_logic;
        trigger_out         : std_logic;
        data_amount         : std_logic_vector (15 downto 0);
        addr_pointer        : std_logic_vector (15 downto 0);
        stop_trigger        : std_logic;
    end record;

end package;

