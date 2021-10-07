
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use work.analyzer_pkg.all;

entity analyzer is
    port (
        clk             : in std_logic;
        rst             : in std_logic;
        d               : in t_analyzer_in;
        q               : out t_analyzer_out
    );
end analyzer;

architecture arch of analyzer is
    constant MEM_SIZE           : integer := 250;
    type t_reg is record
        trigger_start_del       : std_logic;
        data_in_scr_r           : std_logic_vector (7 downto 0);
        rx_k_r                  : std_logic;
        timestamp               : std_logic_vector (31 downto 0);
        byte_counter            : std_logic_vector (7 downto 0);

        stop_trigger            : std_logic;

        seq_num                 : std_logic_vector (15 downto 0);
        tlp_len                 : std_logic_vector (9 downto 0);
        req_id                  : std_logic_vector (15 downto 0);
        tag                     : std_logic_vector (7 downto 0);
        dw                      : std_logic_vector (7 downto 0);

        log_ena                 : std_logic;
        wr2mem                  : std_logic;
        addr_pointer            : std_logic_vector (14 downto 0);
        addr_counter            : std_logic_vector (14 downto 0);
        data_reg                : std_logic_vector (31 downto 0);
        data_ext_reg            : std_logic_vector (3 downto 0);
        wr_en                   : std_logic;
        data_amount             : std_logic_vector (14 downto 0);
        trigger                 : std_logic;

        packet_type             : t_packet_type;
        tlp_type                : t_tlp_type;
        dllp_type               : t_dllp_type;
    end record t_reg;

    constant REG_T_INIT : t_reg := (
        trigger_start_del       => '0',
        data_in_scr_r           => (others => '0'),
        rx_k_r                  => '0',
        timestamp               => (others => '0'),
        byte_counter            => (others => '0'),

        stop_trigger            => '0',

        seq_num                 => (others => '0'),
        tlp_len                 => (others => '0'),
        req_id                  => (others => '0'),
        tag                     => (others => '0'),
        dw                      => (others => '0'),

        log_ena                 => '0',
        wr2mem                  => '0',
        addr_pointer            => (others => '0'),
        addr_counter            => (others => '0'),
        data_reg                => (others => '0'),
        data_ext_reg            => (others => '0'),
        wr_en                   => '0',
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

    v.data_in_scr_r := d.data_in_scr;
    v.trigger_start_del := d.trigger_start;
    v.rx_k_r := d.rx_k;
    if d.trigger_start = '1' and r.trigger_start_del = '0' then
        v.log_ena := '1';
        v.stop_trigger := '0';
    end if;
    if d.trigger_stop = '1' or r.data_amount = 15X"00FF" then--std_logic_vector(to_unsigned(MEM_SIZE,15)) then--X"7FFF" then
        v.log_ena := '0';
        v.stop_trigger := '1';
        v.timestamp := (others => '0');
        --! TODO: Remove address reset
        v.addr_counter := (others => '0');
        v.data_amount := (others => '0');
    end if;

    v.data_reg(31 downto 8) := r.data_reg(23 downto 0);
    v.data_reg(7 downto 0) := d.data_in_scr;

    if r.log_ena = '1' then
        v.timestamp := r.timestamp + 1;
    end if;
    -- handling of k-symbols
    if d.rx_k = '1' then
        v.packet_type := IDLE;
        -- start TLP Packet
        if d.data_in_scr = K_STP_SYM_27_7 then
            v.packet_type := TLP_PKT;
            if d.filter_in.tlp_save = '1' then
                v.wr2mem := '1';
            end if;
        end if;
        -- start DLLP Packet
        if d.data_in_scr = K_SDP_SYM_28_2 then
            v.packet_type := DLLP_PKT;
            if d.filter_in.dllp_save = '1' then
                v.wr2mem := '1';
            end if;
        end if;
        -- start ORDER SET Packet
        if d.data_in_scr = K_COM_SYM_28_5 then
            v.byte_counter := (others => '0');
            v.packet_type := ORDR_ST;
            if d.filter_in.order_set_save = '1' then
                v.wr2mem := '1';
            else
                v.wr2mem := '0';
            end if;
        end if;
    else
        -- end TLP/DLLP Packet
        -- only when the next start symbol isn't following the end symbol
        if r.rx_k_r = '1' and r.data_in_scr_r = K_END_SYM_29_7 then
            v.packet_type := IDLE;
            v.tlp_type := NO_PCK;
            v.dllp_type := NO_PCK;
            v.wr2mem := '0';
            v.byte_counter := (others => '0');
        end if;
        if r.packet_type = IDLE then
            v.wr2mem := '0';
        end if;
    end if;

    -- byte counter in packets
    if (r.packet_type = IDLE) then
        v.byte_counter := (others => '0');
    -- counts only when Order set, DLLP or TLP packet is sending
    else
        v.byte_counter := r.byte_counter + 1;
        -- order set packet doesn't have an end symbol, therefore the end is detected by the byte counter
        if r.packet_type = ORDR_ST then
            -- TS1 and TS2 packets have 15 bytes
            if unsigned(r.byte_counter) = 15 or d.data_in_scr = K_COM_SYM_28_5 then
                v.byte_counter := (others => '0');
                if d.rx_k = '0' then
                    v.packet_type := IDLE;
                end if;
            end if;
            -- SKIP, FTS or IDLE packets have 4 bytes
            if unsigned(r.byte_counter(1 downto 0)) = 3 and
               (r.data_in_scr_r = K_PAD_SKP_28_0 or r.data_in_scr_r = K_PAD_FTS_28_1 or r.data_in_scr_r = K_PAD_IDL_28_3) then
                v.byte_counter := (others => '0');
                v.packet_type := IDLE;
            end if;
        end if;
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
    if r.packet_type = ORDR_ST then
        
    end if;

    -- logger logic
    v.wr_en := '0';
    if r.packet_type /= IDLE then
        if r.log_ena = '1' then
            if r.packet_type = TLP_PKT then
            end if;
            if r.wr2mem = '1' then
                if unsigned(r.byte_counter) = 1 then
                    v.wr_en := '1';
                    v.data_amount := r.data_amount + 1;
--                     v.addr_counter := std_logic_vector(unsigned(v.addr_counter) + 1);
                end if;
                if r.byte_counter(1 downto 0) = "10" then
                    v.wr_en := '1';
                    v.data_amount := r.data_amount + 1;
--                      v.addr_counter := std_logic_vector(unsigned(v.addr_counter) + 1);
                end if;
            end if;
        end if;
    end if;
    if r.wr_en = '1' then
        v.addr_counter := r.addr_counter + 1;
    end if;


        rin <= v;
    end process comb;

    q.addr_wr <= r.addr_counter;
    q.data_wr <= "0" & r.data_reg(31 downto 24) &
                 "0" & r.data_reg(23 downto 16) &
                 "0" & r.data_reg(15 downto 8) &
                 "0" & r.data_reg(7 downto 0) when r.byte_counter(1 downto 0) = "11" else
                 "1" & r.timestamp(31 downto 24) &
                 "1" & r.timestamp(23 downto 16) &
                 "1" & r.timestamp(15 downto 8) &
                 "1" & r.timestamp(7 downto 0);
    q.wr_en <= r.wr_en;
    q.data_amount <= r.data_amount;
    q.stop_trigger <= r.stop_trigger;

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