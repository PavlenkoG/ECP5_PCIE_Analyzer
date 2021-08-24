
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
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
        timestamp               : std_logic_vector (31 downto 0);
        byte_counter            : std_logic_vector (7 downto 0);
        data_reg                : std_logic_vector (31 downto 0);
        data_ext_reg            : std_logic_vector (3 downto 0);

        seq_num                 : std_logic_vector (15 downto 0);
        tlp_len                 : std_logic_vector (9 downto 0);
        req_id                  : std_logic_vector (15 downto 0);
        tag                     : std_logic_vector (7 downto 0);
        dw                      : std_logic_vector (7 downto 0);

        log_ena                 : std_logic;
        addr_pointer            : std_logic_vector (14 downto 0);
        addr_counter            : std_logic_vector (14 downto 0);
        data_amount             : std_logic_vector (14 downto 0);
        trigger                 : std_logic;

        packet_type             : t_packet_type;
        tlp_type                : t_tlp_type;
        dllp_type               : t_dllp_type;
    end record t_reg;

    constant REG_T_INIT : t_reg := (
        timestamp               => (others => '0'),
        byte_counter            => (others => '0'),
        data_reg                => (others => '0'),
        data_ext_reg            => (others => '0'),

        seq_num                 => (others => '0'),
        tlp_len                 => (others => '0'),
        req_id                  => (others => '0'),
        tag                     => (others => '0'),
        dw                      => (others => '0'),

        log_ena                 => '0',
        addr_pointer            => (others => '0'),
        addr_counter            => (others => '0'),
        data_amount             => (others => '0'),
        trigger                 => '0',

        packet_type             => IDLE,
        tlp_type                => NO_PCK,
        dllp_type               => NO_PCK
    );

    signal r, rin : t_reg;
begin
    comb : process (r, d) is
        variable v: t_reg;
    begin
        v := r;

        if d.trigger_start = '1' then
            v.log_ena := '1';
        end if;
        if d.trigger_stop = '1' or r.data_amount = X"7FFF" then
            v.log_ena := '0';
            v.timestamp := (others => '0');
        end if;

        if r.log_ena = '1' then
            v.timestamp := std_logic_vector (unsigned(r.timestamp) + 1);
        end if;
        -- start TLP Packet
        if d.rx_k = '1' and d.data_in_scr = K_STP_SYM_27_7 then
            v.packet_type := TLP_PKT;
            v.byte_counter := std_logic_vector(unsigned(r.byte_counter) + 1);
        end if;
        -- start DLLP Packet
        if d.rx_k = '1' and d.data_in_scr = K_SDP_SYM_28_2 then
            v.packet_type := DLLP_PKT;
            v.byte_counter := std_logic_vector(unsigned(r.byte_counter) + 1);
        end if;
        -- end TLP/DLLP Packet
        if d.rx_k = '1'and d.data_in_scr = K_END_SYM_29_7 then
            v.packet_type := IDLE;
            v.tlp_type := NO_PCK;
            v.dllp_type := NO_PCK;
            v.byte_counter := (others => '0');
        end if;

        if d.rx_k = '0' and (r.packet_type = TLP_PKT or r.packet_type = DLLP_PKT) then
            v.byte_counter := std_logic_vector(unsigned(r.byte_counter) + 1);
        end if;

        if r.packet_type = TLP_PKT then
            case to_integer(unsigned(r.byte_counter)) is
                -- TLP Sequence Number
                when 1 => v.seq_num(15 downto 8) := d.data_in_scr;
                when 2 => v.seq_num(7 downto 0) := d.data_in_scr;
                -- TLP FMT and Type
                when 3 => 
                    case d.data_in_scr is
                    when TLP_TYPE_MRD3 =>
                        v.tlp_type := MRD;
                    when TLP_TYPE_MRD4 =>
                        v.tlp_type := MRD;
                    when TLP_TYPE_MRDLK3 =>
                        v.tlp_type := MRDLK;
                    when TLP_TYPE_MRDLK4 =>
                        v.tlp_type := MRDLK;
                    when TLP_TYPE_MWR3 =>  
                        v.tlp_type := MWR;
                    when TLP_TYPE_MWR4 =>
                        v.tlp_type := MWR;
                    when TLP_TYPE_IORD =>
                        v.tlp_type := IORD;
                    when TLP_TYPE_IOWR =>
                        v.tlp_type := IOWR;
                    when TLP_TYPE_CFGRD0 =>
                        v.tlp_type := CFGRD0;
                    when TLP_TYPE_CFGWR0 =>
                        v.tlp_type := CFGWR0;
                    when TLP_TYPE_CFGRD1 =>
                        v.tlp_type := CFGRD1;
                    when TLP_TYPE_CFGWR1 =>
                        v.tlp_type := CFGWR1;
                    when TLP_TYPE_TCFGRD =>
                        v.tlp_type := TCFGRD;
                    when TLP_TYPE_TCFGWR =>
                        v.tlp_type := TCFGWR;
                    when TLP_TYPE_MSG =>
                        v.tlp_type := MSG;
                    when TLP_TYPE_MSGD =>
                        v.tlp_type := MSGD;
                    when TLP_TYPE_CPL =>
                        v.tlp_type := CPL;
                    when TLP_TYPE_CPLD =>
                        v.tlp_type := CPLD;
                    when TLP_TYPE_CPLLK =>
                        v.tlp_type := CPLLK;
                    when TLP_TYPE_CPLDLK =>
                        v.tlp_type := CPLDLK;
                    when others => 
                    end case;
                -- TC
                when 4 =>
                -- Attribute & Lenght
                when 5 =>
                    v.tlp_len (9 downto 8) := d.data_in_scr(1 downto 0);
                -- Lenght
                when 6 =>
                    v.tlp_len (7 downto 0) := d.data_in_scr;
                -- Requester ID
                when 7 =>
                    v.req_id (15 downto 8) := d.data_in_scr;
                when 8 =>
                    v.req_id (7 downto 0) := d.data_in_scr;
                -- Tag
                when 9 =>
                    v.tag := d.data_in_scr;
                -- Last & First DW
                when 10 =>
                    v.dw := d.data_in_scr;
                when others => 
            end case;
        end if;
        if r.packet_type = DLLP_PKT then
            case to_integer(unsigned(r.byte_counter)) is
                when 1 => 
                    case d.data_in_scr is
                        when DLLP_TYPE_ACK =>
                            v.dllp_type := ACK;
                        when DLLP_TYPE_NAK =>
                            v.dllp_type := NAK;
                        when DLLP_TYPE_PM_L1 =>
                            v.dllp_type := PM_L1;
                        when DLLP_TYPE_PM_L23 =>
                            v.dllp_type := PM_L23;
                        when DLLP_TYPE_PM_ASR1 =>
                            v.dllp_type := PM_ASR1;
                        when DLLP_TYPE_REQ_ACK =>
                            v.dllp_type := REQ_ACK;
                        when DLLP_TYPE_VEN_SP =>
                            v.dllp_type := VEN_SP;
                        when DLLP_TYPE_FC1P =>
                            v.dllp_type := FC1P;
                        when DLLP_TYPE_FC1NP =>
                            v.dllp_type := FC1NP;
                        when DLLP_TYPE_FC1CPL =>
                            v.dllp_type := FC1CPL;
                        when DLLP_TYPE_FC2P =>
                            v.dllp_type := FC2P;
                        when DLLP_TYPE_FC2NP =>
                            v.dllp_type := FC2NP;
                        when DLLP_TYPE_FC2CPL =>
                            v.dllp_type := FC2CPL;
                        when DLLP_TYPE_FCP =>
                            v.dllp_type := FCP;
                        when DLLP_TYPE_FCNP =>
                            v.dllp_type := FCNP;
                        when DLLP_TYPE_FCCPL =>
                            v.dllp_type := FCCPL;
                        when others =>
                    end case;
                when others => 
            end case;
        end if;

        -- logger logic
        if r.packet_type /= IDLE then
            if r.log_ena = '1' then
            end if;
        end if;


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