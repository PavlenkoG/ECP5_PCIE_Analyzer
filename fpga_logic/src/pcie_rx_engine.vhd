--------------------------------------------------------------------------------
-- Entity: pcie_rx_engine
-- Date:2016-06-06
-- Author: grpa
--
-- Description:
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pci_wrapper_pkg.all;

package pcie_rx_engine_pkg is

    type t_pcie_rx_engine_in is record
        tlp_rx              : t_rx_tlp_intf_q;                  --! tlp interface input
        nph_processed_vc0   : std_logic;                        --! release non-posted header credits
    end record;

    type t_pcie_rx_engine_out is record
        tlp_rx              : t_rx_tlp_intf_d;                  --! tlp interface output

        addr_out            : std_logic_vector (31 downto 0);   --! Write address out
        data_out            : std_logic_vector (15 downto 0);   --! Write data out
        we                  : std_logic_vector (1 downto 0);    --! Write enable & byte enable

        tc                  : std_logic_vector (1 downto 0);    --! read request traffic class
        req_id              : std_logic_vector (15 downto 0);   --! read request ID
        tag                 : std_logic_vector (7 downto 0);    --! read request Tag
        read_req            : std_logic;                        --! read request signal
        length              : std_logic_vector (9 downto 0);    --! read request length
        dw                  : std_logic_vector (7 downto 0);    --! Last DW and First DW
        bar_hit             : std_logic_vector (6 downto 0);    --! bar_hit for read_request
        cfg_cmpl_req        : std_logic;                        --! extendet config space write completion request

--!     Placeholder for reveal analyzer
--      ra_data             : std_logic_vector (15 downto 0);
--      ra_st               : std_logic;
--      ra_end              : std_logic;
--      ra_bar              : std_logic_vector (6 downto 0);

    end record;

end package pcie_rx_engine_pkg;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.pcie_rx_engine_pkg.all;
    use work.pci_wrapper_pkg.all;

entity pcie_rx_engine is
    generic (debug_pcie_rx : boolean := TRUE); -- placeholder for reveal analyzer, not used in design
    port  (
        clk : in std_logic;
        rst : in std_logic;
        d   : in t_pcie_rx_engine_in;
        q   : out t_pcie_rx_engine_out
    );
end pcie_rx_engine;

architecture arch of pcie_rx_engine is
    type t_tlp_packet_fmt is (NONE, MRD, MWR, CPLD, CFG_RD, CFG_WR); --! TLP types: Write TLP, Read TLP, CMPL TLP, CONFIG Read, CONFIG Write
    type t_tlp_packet_st is (WAIT_ST, LEN_W, RID_W, TAG_W, ADDRH_W, ADDRL_W, PLD_W); --! TLP read main state
    type t_reg is record

        tlp_rx_r            : t_rx_tlp_intf_d;                  --! TLP interface registers
        read_req            : std_logic;                        --! read request signal

        addr_out            : std_logic_vector (31 downto 0);   --! address out for write and read
        tlp_packet_fmt      : t_tlp_packet_fmt;                 --! TLP packet type
        tlp_packet_st       : t_tlp_packet_st;                  --! TLP receive state
        tlp_length          : std_logic_vector (11 downto 0);   --! length of packet in bytes
        tag                 : std_logic_vector (7 downto 0);    --! tag to read
        lastbe              : std_logic_vector (3 downto 0);    --! last byte enable
        firstbe             : std_logic_vector (3 downto 0);    --! first byte enable

        tc                  : std_logic_vector (1 downto 0);    --! Traffic class field

        requesterid         : std_logic_vector (15 downto 0);   --! Requester id to store
        completerid         : std_logic_vector (15 downto 0);   --! Completer id to store

        byte_count          : std_logic_vector (11 downto 0);   --! Byte counter in TLP packet
        we                  : std_logic_vector (1 downto 0);    --! Write enable output signal
        bar_hit             : std_logic_vector (6 downto 0);    --! BAR selector output signal
        cfg_cmpl_req        : std_logic;                        --! config completion request output signal

    end record t_reg;

    constant REG_T_INIT : t_reg := (
        tlp_rx_r        => ('0','0','0','0','0','0','0','0','0','0',
                        (others => '0'), (others => '0')),

       read_req         => '0',

       addr_out         => (others => '0'),
       tlp_packet_fmt   => NONE,
       tlp_packet_st    => WAIT_ST,
       tlp_length       => (others => '0'),
       tag              => (others => '0'),
       lastbe           => (others => '0'),
       firstbe          => (others => '0'),

       tc               => (others => '0'),

       requesterid      => (others => '0'),
       completerid      => (others => '0'),

       byte_count       => (others => '0'),
       we               => (others => '0'),
       bar_hit          => (others => '0'),
       cfg_cmpl_req     => '0'

    );

    signal r, rin : t_reg;

begin

    comb : process (r, d) is
    variable v: t_reg;
    begin
        v := r;
        v.bar_hit := d.tlp_rx.rx_bar_hit;
        -- one shoot signals
        v.tlp_rx_r.pd_processed_vc0 := '0';
        v.tlp_rx_r.ph_processed_vc0 := '0';
        v.tlp_rx_r.pd_num_vc0 := (others => '0');

        v.tlp_rx_r.nph_processed_vc0 := '0';
        v.read_req := '0';

        case r.tlp_packet_st is

            -- wait for start of TLP Packet
            when WAIT_ST =>
                v.byte_count := (others => '0');
                v.cfg_cmpl_req := '0';
                -- Byte 1, Byte 2 from first header DW
                -- FMT TYPE TC
                if d.tlp_rx.rx_st_vc0 = '1' then
                    case (d.tlp_rx.rx_data_vc0(14 downto 8)) is
                        when RX_MEM_RD_FMT_TYPE =>   -- 0x0000
                            v.tlp_packet_fmt := MRD;
                            v.tc := d.tlp_rx.rx_data_vc0(5 downto 4);
                        when RX_MEM_WR_FMT_TYPE =>   -- 0x4000
                            v.tlp_packet_fmt := MWR;
                        when RX_CPLD_FMT_TYPE =>     -- 0x4A00
                            v.tlp_packet_fmt := CPLD;
                        when RX_CFG_RD_FMT_TYPE =>
                            v.tlp_packet_fmt := CFG_RD;
                            v.tc := d.tlp_rx.rx_data_vc0(5 downto 4);
                        when RX_CFG_WR_FMT_TYPE =>
                            v.cfg_cmpl_req := '1';
                            v.tlp_packet_fmt := CFG_WR;
                        when others =>
                    end case;
                    v.tlp_packet_st := LEN_W;
                else
                    v.tlp_packet_fmt := NONE;
                end if;

            -- Byte 3, Byte 4 from first header DW
            -- TD EP ATTR Length
            when LEN_W =>
                v.tlp_length(11 downto 2) := d.tlp_rx.rx_data_vc0(9 downto 0);
                v.tlp_packet_st := RID_W;

            -- Byte 1, Byte 2 from second header DW
            -- Requester ID/ Completer ID
            when RID_W =>
                -- Completer ID
                if (r.tlp_packet_fmt = CPLD) then
                    v.completerid := d.tlp_rx.rx_data_vc0;
                -- Requester ID
                else
                    v.requesterid := d.tlp_rx.rx_data_vc0;
                end if;
                v.tlp_packet_st := TAG_W;

            -- Byte 3, Byte 4 from second header DW
            -- Tag LastDW FirstDW - for write/read header
            -- Cmpl BCM Byte Count - for completion header
            when TAG_W =>
                if (r.tlp_packet_fmt = CPLD)then
                -- TODO add Completition status
                    v.byte_count := d.tlp_rx.rx_data_vc0(11 downto 0);
                else
                    v.tag := d.tlp_rx.rx_data_vc0(15 downto 8);
                    v.lastbe := d.tlp_rx.rx_data_vc0(7 downto 4);
                    if (r.tlp_packet_fmt = CFG_RD) then
                        v.firstbe := "1111";
                    else
                        v.firstbe := d.tlp_rx.rx_data_vc0(3 downto 0);
                    end if;
                end if;
                v.tlp_packet_st := ADDRH_W;

            -- Byte 1, Byte 2 from third header DW
            -- Addres/ Requester ID
            when ADDRH_W =>
                if (r.tlp_packet_fmt = CPLD) then
                    v.requesterid := d.tlp_rx.rx_data_vc0;
                else
                    v.addr_out(31 downto 16) := d.tlp_rx.rx_data_vc0;
                end if;
                v.tlp_packet_st := ADDRL_W;

            -- Byte 3, Byte 4 from third header DW
            -- Address / Tag, LoAddr
            when ADDRL_W =>
                -- lo address is divided by 2 for writing into 16bit memory
                v.addr_out(15 downto 0) := "0" & d.tlp_rx.rx_data_vc0(15 downto 1);
                if (r.tlp_packet_fmt = MRD or r.tlp_packet_fmt = CFG_RD ) then
                -- send Read request to PCI tx handler
                    v.read_req := '1';
                    v.tlp_packet_st := WAIT_ST;
                    v.tlp_packet_fmt := NONE;
                else
                -- Recieve payload data
                    v.tlp_packet_st := PLD_W;
                    if (r.tlp_packet_fmt = CPLD) then
                        v.addr_out(6 downto 0) := d.tlp_rx.rx_data_vc0 (6 downto 0);
                        v.tag := d.tlp_rx.rx_data_vc0 (15 downto 8);
                    end if;
                end if;
                -- we assign
                if r.tlp_packet_fmt = MWR or r.tlp_packet_fmt = CFG_WR then
                    v.we := r.firstbe (1 downto 0);
                end if;
                -- do nothing
                if r.tlp_packet_fmt = CPLD then
                end if;

            -- Payload
            when PLD_W =>
                if (r.tlp_packet_fmt = CFG_WR) then
                end if;
                if d.tlp_rx.rx_end_vc0 = '0' then
                    v.byte_count := std_logic_vector(unsigned(r.byte_count) + 1);
                    v.addr_out := std_logic_vector(unsigned(r.addr_out) + 1);
                else
                    v.tlp_packet_st := WAIT_ST;
                    if r.tlp_packet_fmt = CFG_WR then
                        v.read_req := '1';
                    end if;
                end if;

                -- we assign
                if r.tlp_packet_fmt = MWR or r.tlp_packet_fmt = CFG_WR then
                    v.we := "11";
                    if (unsigned(r.byte_count))= 0 then
                        v.we := r.firstbe (3 downto 2);
                    elsif r.byte_count(10 downto 0) = std_logic_vector(unsigned(r.tlp_length(11 downto 1)) - 3) then
                        v.we := r.lastbe(1 downto 0);
                    elsif r.byte_count(10 downto 0) = std_logic_vector(unsigned(r.tlp_length(11 downto 1)) - 2) then
                        v.we := r.lastbe(3 downto 2);
                    elsif r.byte_count(10 downto 0) = std_logic_vector(unsigned(r.tlp_length(11 downto 1)) - 1) then
                        v.we := "00";
                    end if;
                end if;
                if r.tlp_packet_fmt = CPLD then

                end if;
            when others =>
        end case;

        -- Release credits for posted data and posted header
        if d.tlp_rx.rx_end_vc0 = '1' then
            if r.tlp_packet_fmt = MWR then
                v.tlp_rx_r.pd_processed_vc0 := '1';
                v.tlp_rx_r.ph_processed_vc0 := '1';
                -- TODO length calculate
                if (unsigned(r.tlp_length(3 downto 2))) = 0 then
                    v.tlp_rx_r.pd_num_vc0(7 downto 0) := r.tlp_length (11 downto 4);
                end if;
                if (unsigned(r.tlp_length(3 downto 2)))  > 0 then
                    v.tlp_rx_r.pd_num_vc0(7 downto 0) := std_logic_vector(unsigned(r.tlp_length (9 downto 2)) + 1);
                end if;
            end if;
            if r.tlp_packet_fmt = MRD then
                v.tlp_rx_r.nph_processed_vc0 := '1';
            end if;
        end if;

        rin <= v;
    end process comb;

    q.req_id <= r.requesterid;
    q.tc <= r.tc;
    q.tag <= r.tag;
    q.read_req <= r.read_req;
    q.addr_out <= r.addr_out;
    q.we <= r.we;
    q.data_out <= d.tlp_rx.rx_data_vc0;
    q.length <= r.tlp_length(11 downto 2);
    q.dw (7 downto 4) <= r.lastbe;
    q.dw (3 downto 0) <= r.firstbe;
    q.bar_hit <= r.bar_hit;
    q.cfg_cmpl_req <= r.cfg_cmpl_req;

    q.tlp_rx.ph_processed_vc0 <= r.tlp_rx_r.ph_processed_vc0;
    q.tlp_rx.pd_processed_vc0 <= r.tlp_rx_r.pd_processed_vc0;
    q.tlp_rx.pd_num_vc0 <= r.tlp_rx_r.pd_num_vc0;
    q.tlp_rx.npd_num_vc0 <= (others => '0');

    q.tlp_rx.nph_processed_vc0 <= d.nph_processed_vc0;
    q.tlp_rx.npd_processed_vc0 <= '0';
    q.tlp_rx.ur_np_ext <= '0';
    q.tlp_rx.ur_p_ext <= '0';
    q.tlp_rx.ph_buf_status_vc0 <= '0';
    q.tlp_rx.pd_buf_status_vc0 <= '0';
    q.tlp_rx.npd_buf_status_vc0 <= '0';
    q.tlp_rx.nph_buf_status_vc0 <= '0';

--! placeholder for reveal analyzer
--  reveal_inserter: if (debug_pcie_rx = true) generate
--      q.ra_bar <= d.tlp_rx.rx_bar_hit;
--      q.ra_data <= d.tlp_rx.rx_data_vc0;
--      q.ra_end <= d.tlp_rx.rx_end_vc0;
--      q.ra_st <= d.tlp_rx.rx_st_vc0;
--  end generate reveal_inserter;

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
end arch;

