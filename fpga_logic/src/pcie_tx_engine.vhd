library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pci_wrapper_pkg.all;

--------------------------------------------------------------------------------
-- Entity: pcie_tx_engine
-- Date:2016-06-28
-- Author: grpa
--
-- Description:
--------------------------------------------------------------------------------
package pcie_tx_engine_pkg is

    type t_pcie_tx_engine_in is record
        --! PCIExpress TLP interface input
        tlp_tx          : t_tx_tlp_intf_q;

        --! PCIExpress Root BARs read interface
        read_req        : std_logic;                        --! Read request from rx engine
        tc              : std_logic_vector (1 downto 0);    --! Traffic class to store in fifo
        addr_read       : std_logic_vector (31 downto 0);   --! Address to read
        completer_id    : std_logic_vector (15 downto 0);   --! Completer id from PCIE Core
        requester_id    : std_logic_vector (15 downto 0);   --! Requester ID to store in fifo
        length          : std_logic_vector (9 downto 0);    --! Data amount to read
        tag             : std_logic_vector (7 downto 0);    --! TLP Tag to store in fifo
        data_in         : std_logic_vector (15 downto 0);   --! Data input from BARs
        dw              : std_logic_vector (7 downto 0);    --! DW to store in fifo
        bar_hit_in      : std_logic_vector (6 downto 0);    --! BAR number to store in fifo
        cfg_cmpl_req    : std_logic;                        --! Config completion flag for non-posted massage

        --! SIO Packets write request
        write_req       : std_logic;                        --! write request flag
        write_req_addr  : std_logic_vector (31 downto 0);   --! Root Complex address to write
        write_req_len   : std_logic_vector (7 downto 0);    --! Amount data to write
        write_data      : std_logic_vector (15 downto 0);   --! Data to write

        --! Read request from DMA
        dma_rd_req      : std_logic;                        --! read request flag
        dma_len         : std_logic_vector (9 downto 0);    --! Amount data to read
        dma_dw          : std_logic_vector (7 downto 0);    --! DW
        dma_tag         : std_logic_vector (7 downto 0);    --! TLP Tag
        dma_addr        : std_logic_vector (31 downto 0);   --! Root Complex address to read

        -- msi-x request
        msi_x_ena       : std_logic;                        --! MSI-X is enabled signal
        msi_x_req       : std_logic;                        --! MSI-X request flag
        msi_x_data      : std_logic_vector (15 downto 0);   --! MSI-X data to write

        -- ptm request
        ptm_req         : std_logic;
    end record;

    type t_pcie_tx_engine_out is record
        --! PCIExpress TLP interface output
        tlp_tx          : t_tx_tlp_intf_d;

        rdaddress       : std_logic_vector (11 downto 0);   --! Read BAR address
        nph_processed_vc0 : std_logic;                      --! non posted header credits release
        read_bar        : std_logic_vector (6 downto 0);    --! BAR number to read

        read_fifo       : std_logic;                        --! reading data from packet fifo

        dma_req_rdy     : std_logic;                        --! DMA request ready

        read_msi_x      : std_logic;                        --! reading data from msi-x module

        ptm_ready       : std_logic;                        --! PTM read data ready
    end record;

end package pcie_tx_engine_pkg;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.pci_wrapper_pkg.all;
    use work.pcie_tx_engine_pkg.all;
    use work.top_pkg.all;

entity pcie_tx_engine is
    port  (
        clk : in std_logic;
        rst : in std_logic;
        d   : in t_pcie_tx_engine_in;
        q   : out t_pcie_tx_engine_out  );
end pcie_tx_engine;

architecture arch of pcie_tx_engine is

    --! tlp packet transmitting states
    type t_tlp_packet_st is (WAIT_ST, CREDIT_CHK, LEN_W, CID_W, BYTC_W, REQID_W, TAG_W, PLD_W);
    --! tlp packets types
    type t_pcie_tx_state is (WRITE_PD, READ_PD, READ_PCI, WRITE_MSI_X, READ_PTM, IDLE);

    type t_reg is record
        tlp_tx_r        : t_tx_tlp_intf_d;                  --! TLP interface registers
        tlp_packet_st   : t_tlp_packet_st;                  --! transmitting packet main state
        read_addr       : std_logic_vector (11 downto 0);   --! BAR Address to read
        read_addr_cnt   : std_logic_vector (10 downto 0);   --! register to store and count address to read
        length_cnt      : std_logic_vector (10 downto 0);   --! tx data amount counter
        read_ena        : std_logic;                        --! BAR read enable
        cpl_bc          : std_logic_vector (11 downto 0);   --! completion byte counter
        lower_addr      : std_logic_vector (6 downto 0);    --! TLP packet lower address field

        fifo_rd         : std_logic;                        --! read data from completion fifo
        requester_id    : std_logic_vector (15 downto 0);   --! register to store TLP requester id
        nph_processed_vc0 : std_logic;                      --! credit free signal

        pcie_wr_st      : t_pcie_tx_state;                  --! transmitter state

        len             : std_logic_vector (9 downto 0);    --! len field in TLP

        read_fifo       : std_logic;                        --! Packet fifo read signal
        dma_req_rdy     : std_logic;                        --! DMA read ready signal

        dma_rxtx_switch : std_logic;                        --! register to avoid interface blocking

        read_msi_x      : std_logic;                        --! MSI-X read enable signal

        pd_data_trig    : std_logic_vector (15 downto 0);   --! Process data input register
        data_trig       : std_logic_vector (15 downto 0);   --! BAR data input register

        ptm_ready       : std_logic;                        --! PTM request ready signal

    end record t_reg;

    constant REG_T_INIT : t_reg := (
        tlp_tx_r        => ((others => '0'),'0','0','0','0'),
        tlp_packet_st    => WAIT_ST,
        read_addr       => (others => '0'),
        read_addr_cnt   => (others => '0'),
        length_cnt      => (others => '0'),
        read_ena        => '0',
        cpl_bc          => (others => '0'),
        lower_addr      => (others => '0'),
        requester_id    => (others => '0'),

        fifo_rd         => '0',
        nph_processed_vc0 => '0',
        pcie_wr_st      => IDLE,
        len             => (others => '0'),
        read_fifo       => '0',
        dma_req_rdy     => '0',

        dma_rxtx_switch => '0',

        read_msi_x      => '0',
        pd_data_trig    => (others => '0'),
        data_trig       => (others => '0'),

        ptm_ready       => '0'
    );

    signal r, rin : t_reg;
    signal empty  : std_logic;  --! fifo empty signal

    -- fifo_data:
    -- 48    - CfgWr Flag
    -- 47:46 - TC
    -- 45:40 - bar
    -- 39:32 - lenght
    -- 31:24 - tag
    -- 23:16 - dw
    -- 15:0  - addr
    signal fifo_data : std_logic_vector (48 downto 0);                          --! fifo data read
    signal data :std_logic_vector (48 downto 0);                                --! fifo data write

    alias length : std_logic_vector (7 downto 0) is fifo_data(39 downto 32);
    alias dw : std_logic_vector (7 downto 0) is fifo_data(23 downto 16);


begin

    comb : process (r, d, empty, fifo_data) is
    variable v: t_reg;
    begin
        v := r;

        --! one shoot signals
        v.tlp_tx_r.tx_st_vc0 := '0';
        v.tlp_tx_r.tx_end_vc0  := '0';
        v.fifo_rd := '0';
        v.nph_processed_vc0 := '0';
        v.ptm_ready := '0';

        --! main state machine
        --(WAIT_ST, CREDIT_CHK, LEN_W, CID_W, BYTC_W, REQID_W, TAG_W, PLD_W)
        case r.tlp_packet_st is

        -- wait for a read or write request
        when WAIT_ST =>
            v.dma_req_rdy := '0';
            --! MSI_X interrupt high priority
            if d.msi_x_req = '1' and d.msi_x_ena = '1' then
                v.pcie_wr_st := WRITE_MSI_X;
                v.tlp_packet_st := CREDIT_CHK;
                v.len := "0000000001";
            --! PTM requester send (prio 1)
            elsif d.ptm_req = '1' then
                v.pcie_wr_st := READ_PTM;
                v.tlp_packet_st := CREDIT_CHK;
            --! DMA Process data read (prio 2)
            elsif d.dma_rd_req = '1' and r.dma_rxtx_switch = '0' then
                if d.write_req = '1' then
                    v.dma_rxtx_switch := '1';       --! switch between process data write end read
                end if;
                v.pcie_wr_st := READ_PD;
                v.tlp_packet_st := CREDIT_CHK;
                v.len := len_calc (d.dma_addr(1 downto 0), d.dma_len(6 downto 0));
            --! PCIE data write
            else
                --! Process data write
                if d.write_req = '1' then
                    v.dma_rxtx_switch := '0';       --! switch between process data write end read
                    v.pcie_wr_st := WRITE_PD;
                    v.tlp_packet_st := CREDIT_CHK;
                    v.len := len_calc (d.write_req_addr(1 downto 0), d.write_req_len(6 downto 0));
                --! Completion data write
                else
                    if empty = '0' then
                        v.pcie_wr_st := READ_PCI;
                        v.tlp_packet_st := CREDIT_CHK;
                        v.fifo_rd := '1';
                    else
                        v.pcie_wr_st := IDLE;
                    end if;
                end if;
            end if;

        -- credit check
        -- set the Byte 1, Byte 2 to first DW
        when CREDIT_CHK =>
            --! wait until PCIE core ready
            if r.tlp_tx_r.tx_req_vc0 = '0' then
                v.tlp_tx_r.tx_data_vc0 := (others => '0');
                v.tlp_tx_r.tx_req_vc0 := '1';
            end if;
            if d.tlp_tx.tx_ca_cpl_recheck_vc0 = '0' and d.tlp_tx.tx_ca_p_recheck_vc0 = '0' then
                if d.tlp_tx.tx_rdy_vc0 = '1' then
                    --! packet type selector:
                    case r.pcie_wr_st is
                    when WRITE_PD =>    --! Process data write state
                       v.tlp_tx_r.tx_data_vc0(14 downto 8) := RX_MEM_WR_FMT_TYPE;
                       v.tlp_tx_r.tx_data_vc0(5 downto 4) := fifo_data(47 downto 46);
                       --! check if root complex has enought data credits 
                       if (((unsigned(d.tlp_tx.tx_ca_pd_vc0)) > (unsigned(r.len))) and ((unsigned(d.tlp_tx.tx_ca_ph_vc0)) > 1)) then
                           v.tlp_packet_st := LEN_W;
                           v.tlp_tx_r.tx_st_vc0 := '1';
                       else
                           v.tlp_tx_r.tx_req_vc0 := '0';
                           v.tlp_packet_st := WAIT_ST;
                       end if;
                    when READ_PCI =>    --! Completion packet write
                        if (unsigned(d.tlp_tx.tx_ca_cpld_vc0)) > 0 then --! check if rc has enought credits
                            v.tlp_packet_st := LEN_W;
                            v.tlp_tx_r.tx_st_vc0 := '1';
                            v.tlp_tx_r.tx_data_vc0(5 downto 4) := fifo_data(47 downto 46);
                            if (fifo_data(48) = '0') then
                                v.tlp_tx_r.tx_data_vc0(14 downto 8) := RX_CPLD_FMT_TYPE; --! completion with data
                            else
                                v.tlp_tx_r.tx_data_vc0(14 downto 8) := RX_CPL_FMT_TYPE;  --! completion without data (by writing to extended config space)
                            end if;
                        end if;
                    when READ_PD =>     --! Getting Processdata from rootcomplex
                        v.tlp_tx_r.tx_data_vc0(14 downto 8) := RX_MEM_RD_FMT_TYPE;
                        --! check if RC has enought header credits
                        if (unsigned(d.tlp_tx.tx_ca_nph_vc0)) > 1 then
                            v.tlp_packet_st := LEN_W;
                            v.tlp_tx_r.tx_st_vc0 := '1';
                        else
                            v.tlp_tx_r.tx_req_vc0 := '0';
                            v.tlp_packet_st := WAIT_ST;
                        end if;
                    when WRITE_MSI_X => --! Writing MSI-X packet
                        v.tlp_tx_r.tx_data_vc0(14 downto 8) := RX_MEM_WR_FMT_TYPE;
                        v.tlp_tx_r.tx_st_vc0 := '1';
                        --TODO assign Traffic Class dynamic
                        v.tlp_tx_r.tx_data_vc0(5 downto 4) := "11";
                        v.tlp_packet_st := LEN_W;
                    when READ_PTM =>    --! sending PTM request paket
                        v.tlp_tx_r.tx_data_vc0(14 downto 8) := TX_MSG_RQ_FMT_TYPE;
                        if (unsigned(d.tlp_tx.tx_ca_ph_vc0)) > 0 then
                            v.ptm_ready := '1';
                            v.tlp_tx_r.tx_st_vc0 := '1';
                            v.tlp_packet_st := LEN_W;
                        else
                            v.tlp_tx_r.tx_req_vc0 := '0';
                            v.tlp_packet_st := WAIT_ST;
                        end if;
                    when others =>
                    end case;
                end if;
            else
                v.tlp_tx_r.tx_req_vc0 := '0';
            end if;

        -- Byte 3, Byte 4 of first DW header
        -- TD EP Attr Length
        when LEN_W =>
            v.tlp_tx_r.tx_req_vc0 := '0';
            v.tlp_tx_r.tx_data_vc0 (15 downto 10) := (others => '0');
            v.tlp_packet_st := CID_W;
            case r.pcie_wr_st is
            when WRITE_PD =>
                v.tlp_tx_r.tx_data_vc0(9 downto 0) :=  r.len;
                if (unsigned(d.write_req_len)) >= 4 then
                    v.length_cnt :=   r.len & '0';
                end if;
                if (unsigned(d.write_req_len)) < 4 then
                    if (unsigned(r.len)) = 1 then v.length_cnt := "000" & X"02";
                    else v.length_cnt := "000" & X"04"; end if;
                end if;
            when READ_PCI =>
                v.tlp_tx_r.tx_data_vc0 (9 downto 0) := "00" & fifo_data(39 downto 32);-- LENGTH
                v.length_cnt(10 downto 0) := "00" & fifo_data(39 downto 32) & '0';
            when READ_PD =>
                if fifo_data(40) = '1' then
                    v.read_ena := '1';
                end if;
                v.tlp_tx_r.tx_data_vc0(9 downto 0) :=  r.len;
            when WRITE_MSI_X =>
                v.tlp_tx_r.tx_data_vc0 := X"0001";
            when READ_PTM =>
                v.tlp_tx_r.tx_data_vc0 := X"0000";
            when others =>
            end case;

        -- Byte 1, Byte 2 of second DW header
        -- Requester or Completer id
        -- here are Byte counter and lower address fields calculated
        when CID_W =>
                v.read_addr_cnt := r.length_cnt;
                v.tlp_packet_st := BYTC_W;

                v.tlp_tx_r.tx_data_vc0 := d.completer_id;
                -- assigning TLP completion byte counter
                case fifo_data(23 downto 16) is
                    when "00001111" => v.cpl_bc := "0000" & X"04";
                    when "00000111" => v.cpl_bc := "0000" & X"03";
                    when "00001110" => v.cpl_bc := "0000" & X"03";
                    when "00000011" => v.cpl_bc := "0000" & X"02";
                    when "00000110" => v.cpl_bc := "0000" & X"02";
                    when "00001100" => v.cpl_bc := "0000" & X"02";
                    when "00000001" => v.cpl_bc := "0000" & X"01";
                    when "00000010" => v.cpl_bc := "0000" & X"01";
                    when "00000100" => v.cpl_bc := "0000" & X"01";
                    when "00001000" => v.cpl_bc := "0000" & X"01";
                    when "00000000" => v.cpl_bc := "0000" & X"01";
                    when "11111111" => v.cpl_bc := "00" & length & "00";
                    when "01111111" => v.cpl_bc := std_logic_vector(unsigned(("00" & length & "00")) - 1);
                    when "00111111" => v.cpl_bc := std_logic_vector(unsigned(("00" & length & "00")) - 2);
                    when "00011111" => v.cpl_bc := std_logic_vector(unsigned(("00" & length & "00")) - 3);
                    when "11111110" => v.cpl_bc := std_logic_vector(unsigned(("00" & length & "00")) - 1);
                    when "01111110" => v.cpl_bc := std_logic_vector(unsigned(("00" & length & "00")) - 2);
                    when "00111110" => v.cpl_bc := std_logic_vector(unsigned(("00" & length & "00")) - 3);
                    when "00011110" => v.cpl_bc := std_logic_vector(unsigned(("00" & length & "00")) - 4);
                    when "11111100" => v.cpl_bc := std_logic_vector(unsigned(("00" & length & "00")) - 2);
                    when "01111100" => v.cpl_bc := std_logic_vector(unsigned(("00" & length & "00")) - 3);
                    when "00111100" => v.cpl_bc := std_logic_vector(unsigned(("00" & length & "00")) - 4);
                    when "00011100" => v.cpl_bc := std_logic_vector(unsigned(("00" & length & "00")) - 5);
                    when "11111000" => v.cpl_bc := std_logic_vector(unsigned(("00" & length & "00")) - 3);
                    when "01111000" => v.cpl_bc := std_logic_vector(unsigned(("00" & length & "00")) - 4);
                    when "00111000" => v.cpl_bc := std_logic_vector(unsigned(("00" & length & "00")) - 5);
                    when "00011000" => v.cpl_bc := std_logic_vector(unsigned(("00" & length & "00")) - 6);
                    when others =>  v.cpl_bc := (others => '0');
            end case;

            --! TLP Lower address calculating
            if dw(3 downto 0) = "1111" or dw(3 downto 0) = "0111" or
               dw(3 downto 0) = "0011" or dw(3 downto 0) = "0001" then
               v.lower_addr := (fifo_data(5 downto 0)&"0");
            end if;
            if dw(3 downto 0) = "1110" or dw(3 downto 0) = "0110" or
               dw(3 downto 0) = "0010" then
               v.lower_addr := std_logic_vector(unsigned((fifo_data(5 downto 0)&"0")) + 1);
            end if;
            if dw(3 downto 0) = "1100" or dw(3 downto 0) = "0100" then
               v.lower_addr := std_logic_vector(unsigned((fifo_data(5 downto 0)&"0")) + 2);
            end if;
            if dw(3 downto 0) = "1000" then
               v.lower_addr := std_logic_vector(unsigned((fifo_data(5 downto 0)&"0")) + 3);
            end if;

            case r.pcie_wr_st is
            when WRITE_PD =>
                v.read_fifo := '1';
            when READ_PCI =>
                v.read_ena := '1';
            when others =>
            end case;

        -- Byte 3, Byte 4 of second DW header
        -- Tag LastDW FirstDW/ CmplStatus ByteCount
        when BYTC_W =>
            v.tlp_packet_st := REQID_W;
            case r.pcie_wr_st is
            when WRITE_PD =>
                v.read_ena := '1';
                v.read_fifo := '1';
                v.tlp_tx_r.tx_data_vc0 (15 downto 8) := X"00";
                v.tlp_tx_r.tx_data_vc0 (7 downto 0) := dw_assign (d.write_req_addr(1 downto 0), d.write_req_len(6 downto 0));
                if (unsigned(r.len)) = 1 then
                    v.tlp_tx_r.tx_data_vc0 (7 downto 4) := (others => '0');
                end if;
            when READ_PD =>
                v.tlp_tx_r.tx_data_vc0 (15 downto 8) := d.dma_tag;
                v.tlp_tx_r.tx_data_vc0 (7 downto 0) := dw_assign (d.dma_addr(1 downto 0), d.dma_len(6 downto 0));
                if (unsigned(r.len)) = 1 then
                    v.tlp_tx_r.tx_data_vc0 (7 downto 4) := (others => '0');
                end if;
            when READ_PCI =>
                v.read_ena := '1';
                v.tlp_tx_r.tx_data_vc0(15 downto 13) := SUCCESSFUL_CMPL;-- TODO add compl stats logic
                v.tlp_tx_r.tx_data_vc0(12) := '0';
                v.tlp_tx_r.tx_data_vc0(11 downto 0) := r.cpl_bc;
            when WRITE_MSI_X =>
                v.tlp_tx_r.tx_data_vc0 (15 downto 8) := X"00";
                v.tlp_tx_r.tx_data_vc0 (7 downto 0) := X"0F";
                v.length_cnt := X"00"&"010";
                v.read_msi_x := '1';
            when READ_PTM =>
                v.tlp_tx_r.tx_data_vc0 (15 downto 8) := (others => '0');
                v.tlp_tx_r.tx_data_vc0 (7 downto 0) := X"52"; --Message code 0101 0010 for PTM Request
            when others =>
            end case;

        -- Byte 1, Byte 2 of third DW header
        -- RequesterId/ Address
        when REQID_W =>
            v.tlp_packet_st := TAG_W;
            case r.pcie_wr_st is
            when WRITE_PD =>
                v.tlp_tx_r.tx_data_vc0 := d.write_req_addr(31 downto 16);
--              v.read_fifo := '1';
            when READ_PD =>
                v.tlp_tx_r.tx_data_vc0 := d.dma_addr(31 downto 16);
            when READ_PCI =>
                v.tlp_tx_r.tx_data_vc0 := r.requester_id;
            when WRITE_MSI_X =>
                v.tlp_tx_r.tx_data_vc0 := d.msi_x_data(15 downto 0);
            when READ_PTM =>
                v.tlp_tx_r.tx_data_vc0 := (others => '0');
                v.length_cnt := "000"& x"02";
            when others =>
            end case;

        -- Byte 3, Byte 4 of third DW header
        -- Tag LoAddr/ Address
        when TAG_W =>
            v.tlp_packet_st := PLD_W;
            case r.pcie_wr_st is
            when WRITE_PD =>
                v.tlp_tx_r.tx_data_vc0 := d.write_req_addr(15 downto 2)&"00";
            when READ_PD =>
                v.tlp_tx_r.tx_end_vc0 := '1';
                v.tlp_tx_r.tx_data_vc0 := d.dma_addr(15 downto 2)&"00";
                v.dma_req_rdy := '1';
            when READ_PCI =>
                v.tlp_tx_r.tx_data_vc0 := (others => '0');
                v.tlp_tx_r.tx_data_vc0(15 downto 8) := fifo_data (31 downto 24);
                if ((unsigned(fifo_data(45 downto 40))) > 0) then
                    v.tlp_tx_r.tx_data_vc0(6 downto 0) := r.lower_addr;
                end if;
                if (fifo_data(48) = '1') then
                    v.tlp_tx_r.tx_end_vc0 := '1';
                    v.read_msi_x := '0';
                    v.tlp_packet_st := WAIT_ST;
                    v.read_ena := '0';
                end if;
            when WRITE_MSI_X =>
                v.tlp_tx_r.tx_data_vc0 := d.msi_x_data(15 downto 0);
            when READ_PTM =>
                v.tlp_tx_r.tx_data_vc0 := (others => '0');
            when others =>
            end case;
        -- write payload
        when PLD_W =>
            if r.pcie_wr_st /= READ_PD then
                if (unsigned(r.length_cnt)) > 1 then
                    v.length_cnt := std_logic_vector(unsigned(r.length_cnt) - 1);
                else
                    v.tlp_tx_r.tx_end_vc0 := '1';
                    v.tlp_packet_st := WAIT_ST;
                    if r.pcie_wr_st = READ_PCI then
                        v.nph_processed_vc0 := '1';
                    end if;
                    v.read_ena := '0';
                    v.read_fifo := '0';
                end if;
            else
                v.tlp_tx_r.tx_end_vc0 := '0';
                v.tlp_packet_st := WAIT_ST;
                v.dma_req_rdy := '0';
            end if;
            if r.pcie_wr_st = READ_PCI then
                v.tlp_tx_r.tx_data_vc0 := r.data_trig;
            end if;
            if r.pcie_wr_st = WRITE_PD then
                v.tlp_tx_r.tx_data_vc0 := r.pd_data_trig;
            end if;
            if r.pcie_wr_st = WRITE_MSI_X then
                v.tlp_tx_r.tx_data_vc0 := d.msi_x_data;
                if (unsigned(r.length_cnt)) > 1 then
                    v.length_cnt := std_logic_vector(unsigned(r.length_cnt) - 1);
                else
                    v.tlp_tx_r.tx_end_vc0 := '1';
                    v.read_msi_x := '0';
                    v.tlp_packet_st := WAIT_ST;
                end if;
            end if;
--      when others =>  --! state unused
        end case;

        --! calculating address and counter
        if r.read_ena = '1' then
            if (unsigned(r.read_addr_cnt)) > 1 then
                v.read_addr_cnt := std_logic_vector(unsigned(r.read_addr_cnt) - 1);
                v.read_addr := std_logic_vector(unsigned(r.read_addr) + 1);
            end if;
        else
            v.read_addr := fifo_data(11 downto 0);
        end if;

        --! registering input data
        v.pd_data_trig := d.write_data;
        v.data_trig := d.data_in;

        rin <= v;
    end process comb;

    q.tlp_tx.tx_data_vc0    <= r.tlp_tx_r.tx_data_vc0;
    q.tlp_tx.tx_st_vc0      <= r.tlp_tx_r.tx_st_vc0;
    q.tlp_tx.tx_end_vc0     <= r.tlp_tx_r.tx_end_vc0;
    q.tlp_tx.tx_req_vc0     <= r.tlp_tx_r.tx_req_vc0;
    q.tlp_tx.tx_nlfy_vc0    <= r.tlp_tx_r.tx_nlfy_vc0;
    q.nph_processed_vc0     <= r.nph_processed_vc0;
    q.rdaddress             <= r.read_addr;
    q.read_bar              <= '0' & fifo_data(45 downto 40);
    q.read_fifo             <= r.read_fifo;
    q.dma_req_rdy           <= r.dma_req_rdy;
    q.read_msi_x            <= r.read_msi_x;

    q.ptm_ready             <= r.ptm_ready;

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

    -- fifo to save read requests
    -- 48    - CfgWrFlag
    -- 47:46 - traffic class (1:0)
    -- 45:40 - bar (5:0)
    -- 39:32 - lentght (7:0)
    -- 31:24 - tag (7:0)
    -- 23:16 - dw (7:0)
    -- 15:0  - addr (15:0)
    data <= d.cfg_cmpl_req & d.tc & d.bar_hit_in(5 downto 0) & d.length(7 downto 0) & d.tag & d.dw & d.addr_read(15 downto 0);
    -- fifo to store tx requestes
    pci_read_req_fifo_inst : entity work.pci_read_request_fifo
    port map ( Clock => clk,
               Data => data,
               RdEn => r.fifo_rd,
               Reset => rst,
               WrEn => d.read_req,
               Empty => empty,
               Full => open,
               Q => fifo_data
    );

end arch;

