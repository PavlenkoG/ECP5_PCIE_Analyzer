library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.analyzer_pkg.all;
use work.controller_pkg.all;
use work.rev_analyzer_pkg.all;

--vhdl_comp_off
--library sinplify;
--use sinplify.attributes.all;
--vhdl_comp_on

library ecp5um;
use ecp5um.components.all;

entity top is
    generic (
        PCS_1_ENABLE    : boolean := true;
        PCS_2_ENABLE    : boolean := false
    );
    port(
        clk_100_p       : in std_logic;
        clk_100_n       : in std_logic;

        pcie_clk_n      : in std_logic;
        pcie_clk_p      : in std_logic;
        pcie_up_n       : in std_logic;
        pcie_up_p       : in std_logic;
        pcie_down_n     : in std_logic;
        pcie_down_p     : in std_logic;

        -- spi slave interface
        sclk            : in std_logic;
        cs_n            : in std_logic;
        mosi            : in std_logic;
        miso            : out std_logic;

        -- button
        gsrn            : in std_logic;
        los             : in std_logic_vector (2 downto 0);
        disable1        : out std_logic;
        disable2        : out std_logic;
        disable3        : out std_logic;
        -- leds
        data_out_o      : out std_logic_vector (31 downto 0);
        led             : out std_logic_vector (7 downto 0);
        seg             : out std_logic_vector (14 downto 0);
        switch          : in std_logic_vector (7 downto 0)
    );
end top;

architecture RTL of top is
    constant SPI_WORD_SIZE     : integer := 8;
    constant C_PWRUP_RESET_DELAY : std_logic_vector (4 downto 0) := (others => '1');
    signal reset_delay_count    : std_logic_vector (4 downto 0) := (others => '0');

    signal clk_100              : std_logic;
    signal rst                  : std_logic;
    signal pll_lock             : std_logic;

    signal rx_k_1               : std_logic_vector (0 downto 0);
    signal rx_k_2               : std_logic_vector (0 downto 0);
    signal rx_pclk_1            : std_logic;
    signal rx_pclk_2            : std_logic;
    signal rxdata_1             : std_logic_vector (7 downto 0);
    signal rxdata_2             : std_logic_vector (7 downto 0);
    signal rxstatus_1           : std_logic_vector (2 downto 0);
    signal pcie_done_s_1        : std_logic;
    signal pcie_cone_s_1        : std_logic;
    signal lsm_status_s         : std_logic;
    signal rx_cdr_lol_s_1       : std_logic;
    
    signal scram_rst_1          : std_logic;
    signal scram_rst_2          : std_logic;
    signal scram_en_1           : std_logic;
    signal scram_en_2           : std_logic;

    signal d_and                : t_analyzer_in;
    signal q_and                : t_analyzer_out;

    signal d_anu                : t_analyzer_in;
    signal q_anu                : t_analyzer_out;

    signal data_addr_1          : std_logic_vector (14 downto 0);
    signal data_addr_2          : std_logic_vector (14 downto 0);
    signal data_ch_1            : std_logic_vector (31 downto 0);
    signal data_ch_2            : std_logic_vector (31 downto 0);
    signal data_wr_1            : std_logic;
    signal data_wr_2            : std_logic;

    -- spi user interface
    signal din                  : std_logic_vector (SPI_WORD_SIZE - 1 downto 0);
    signal din_vld              : std_logic;
    signal din_rdy              : std_logic;
    signal dout                 : std_logic_vector (SPI_WORD_SIZE - 1 downto 0);
    signal dout_vld             : std_logic;

    signal d_cntr               : t_controller_in;
    signal q_cntr               : t_controller_out;

    signal d_ra                 : t_rev_analyzer_in;
    signal q_ra                 : t_rev_analyzer_out;

--  test implementation
    signal button               : std_logic;
    signal button_del           : std_logic;
    signal led_reg              : std_logic_vector (7 downto 0);

    signal trigger_ena          : std_logic := '0';
    signal trigger_resync       : std_logic_vector (1 downto 0) := (others => '0');
    signal trigger_stop         : std_logic_vector (1 downto 0);
    signal rd_addr              : std_logic_vector (14 downto 0) := (others => '0');
    signal read_ena             : std_logic;
    signal data_out             : std_logic_vector (35 downto 0);
    signal mem_data_out         : std_logic_vector (35 downto 0);

    signal refclk               : std_logic;
    signal clk_lvds             : std_logic;
--vhdl_comp_off
    attribute syn_preserve : boolean;
    attribute syn_keep : boolean;
    attribute syn_preserve of data_ch_1 : signal is true;
    attribute syn_keep of data_ch_1 : signal is true;

    attribute syn_preserve of clk_100 : signal is true;
    attribute syn_keep of clk_100 : signal is true;
--vhdl_comp_on
    component ilvds
    port (
        an : in std_ulogic;
        a  : in std_ulogic;
        z  : out std_ulogic
    );
    end component;

begin

    led(2 downto 0) <= not los(2) & not los (1) & not los (0);
    led(4 downto 3) <= "11";
    led(7 downto 5) <= q_ra.led_out(7 downto 5);
    seg(14) <= not lsm_status_s;
    seg(13) <= not rx_cdr_lol_s_1;
    seg(12 downto 0) <= (others => '1');

    disable3 <= switch(2);
    disable2 <= switch(1);
    disable1 <= switch(0);

    extref_inst : entity work.extref
        port map(
            refclkp => pcie_clk_p,
            refclkn => pcie_clk_n,
            refclko => refclk
        );

    clk_100_mhz_pll : entity work.pll
    port map (
        clki                => clk_lvds,
        clkop               => clk_100,
        lock                => pll_lock
    );
    clk_100_mhz_lvds_in : ilvds
        port map (
            an              => clk_100_n,
            a               => clk_100_p,
            z               => clk_lvds
        );

    pcs1_generate : if (PCS_1_ENABLE) generate
        -- CDR Loss of Lock Range 1
        -- Linear Equalizer 2
        -- Loss of Signal Threshold Select 5
        pcs_inst_1 : entity work.pcs_pci
        port map (
            hdinn           => pcie_up_n,
            hdinp           => pcie_up_p,
            rxrefclk        => clk_100,
            rx_pclk         => rx_pclk_1,
            rxdata          => rxdata_1,
            rx_k            => rx_k_1,
            rx_disp_err     => open,
            rx_cv_err       => open,
            signal_detect_c => '1',
            lsm_status_s    => lsm_status_s,
            rx_cdr_lol_s    => rx_cdr_lol_s_1,
            rx_pcs_rst_c    => rst,
            rx_serdes_rst_c => rst,
            rx_pwrup_c      => '1',
            rst_dual_c      => rst,
            serdes_rst_dual_c => rst,
            serdes_pdb      => '1'
        );

        lfsr_scrambler_inst_1 : entity work.lfsr_scrambler
        port map (
            rst             => rst,
            clk             => rx_pclk_1,
            data_in         => rxdata_1,
            rx_k            => rx_k_1(0),
            data_out        => d_and.data_in_scr,
            rx_k_out        => d_and.rx_k
        );


        d_and.trigger_start <= trigger_resync(1);--q_cntr.trigger_start;
        d_and.trigger_stop <= q_cntr.trigger_stop;

        analyzer_down_inst : entity  work.analyzer
        port map (
            clk             => rx_pclk_1,
            rst             => rst,
            d               => d_and,
            q               => q_and
        ); 

        packet_memory_down_inst : entity work.packet_ram
            port map(
                WrAddress => q_and.addr_wr,
                --! TODO: remove temporary address
                RdAddress => q_ra.read_addr,--q_cntr.addr_read,
                Data      => q_and.data_wr,
                WE        => q_and.wr_en,
                RdClock   => clk_100,
                RdClockEn => '1',
                Reset     => rst,
                WrClock   => rx_pclk_1,
                WrClockEn => '1',
                --! TODO: remove temporary data
                Q         => mem_data_out-- --d_cntr.d_mem_data_in
            );

    end generate;

    pcs2_generate : if (PCS_2_ENABLE) generate
        pcs_inst_2 : entity work.pcs_pci
        port map (
            hdinn           => pcie_down_n,
            hdinp           => pcie_down_p,
            rst_dual_c      => rst,
            rx_pcs_rst_c    => rst,
            rx_pwrup_c      => '1',
            rx_serdes_rst_c => rst,
            rxrefclk        => clk_100,
            serdes_pdb      => '1',
            serdes_rst_dual_c => rst,
            signal_detect_c => '0',
            rx_cdr_lol_s    => open,
            rx_k            => rx_k_2,
            rx_pclk         => rx_pclk_2,
            rxdata          => rxdata_2,
    --      rxstatus0       => open,
            rx_disp_err     => open,
            rx_cv_err       => open
    --      rx_los_low_s    => open
    --      lsm_status_s    => lsm_status_s_1,
    --      rsl_disable     => '0',
    --      rsl_rst         => '0',
    --      rsl_rx_rdy      => open
    --      pcie_det_en_c   => '1',
    --      pcie_ct_c       => '1',
    --      pcie_done_s     => open,
    --      pcie_con_s      => open,
    --      lsm_status_s    => open
        );

        lfsr_scrambler_inst_2 : entity work.lfsr_scrambler
        port map (
            rst             => rst,
            clk             => rx_pclk_2,
            data_in         => rxdata_2,
            rx_k            => rx_k_2(0),
            data_out        => d_anu.data_in_scr,
            rx_k_out        => d_anu.rx_k
        );

        d_anu.trigger_start <= q_cntr.trigger_start;
        d_anu.trigger_stop <= q_cntr.trigger_stop;

        analyzer_up_inst : entity  work.analyzer
        port map (
            clk             => rx_pclk_2,
            rst             => rst,
            d               => d_anu,
            q               => q_anu
        ); 

        packet_memory_up_inst : entity work.packet_ram
            port map(
                WrAddress => q_anu.addr_wr,
                RdAddress => q_cntr.addr_read,
                Data      => q_anu.data_wr,
                WE        => q_anu.wr_en,
                RdClock   => clk_100,
                RdClockEn => '1',
                Reset     => rst,
                WrClock   => rx_pclk_2,
                WrClockEn => '1',
                Q         => d_cntr.u_mem_data_in
            );
    end generate;

    pulse_filt_inst : entity work.pulse_filt
        generic map(
            FILT_LEN => 8
        )
        port map(
            clk          => rx_pclk_1,
            rst          => rst,
            filt_len_sel => X"20",
            x            => not gsrn,
            y            => button
        );

    data_addr_1 <= q_and.addr_wr;
    data_addr_2 <= q_anu.addr_wr;
--  data_ch_1 <= q_and.data_wr(34 downto 27) & q_and.data_wr(25 downto 18) & q_and.data_wr(16 downto 9) & q_and.data_wr(7 downto 0);
    data_ch_2 <= q_anu.data_wr(34 downto 27) & q_anu.data_wr(25 downto 18) & q_anu.data_wr(16 downto 9) & q_anu.data_wr(7 downto 0);
    data_wr_1 <= q_and.wr_en;
    data_wr_2 <= q_anu.wr_en;

    spi_slave_inst : entity work.SPI_SLAVE
        generic map(
            WORD_SIZE => SPI_WORD_SIZE
        )
        port map(
            CLK      => rx_pclk_2,--clk_100,
            RST      => rst,
            SCLK     => sclk,
            CS_N     => cs_n,
            MOSI     => mosi,
            MISO     => miso,
            DIN      => q_cntr.data_out,
            DIN_VLD  => q_cntr.data_out_vld,
            DIN_RDY  => d_cntr.data_out_rdy,
            DOUT     => d_cntr.data_in,
            DOUT_VLD => d_cntr.data_in_vld
        );

    d_cntr.data_amount_1 <= q_and.data_amount;
    d_cntr.data_amount_2 <= q_and.data_amount;
    controller_inst : entity work.controller
        port map(
            clk => rx_pclk_2,
            rst => rst,
            d   => d_cntr,
            q   => q_cntr
        );

    d_ra.button <= button;
    d_ra.stop_trigger <= q_and.stop_trigger;
    d_ra.data_in <= mem_data_out;

    rev_analyzer_inst : entity work.rev_analyzer
        port map(
            clk => clk_100,
            rst => rst,
            d   => d_ra,
            q   => q_ra
        );

    rst <= not (pll_lock and switch(7));
    reg_process : process (clk_100) is
    begin
        if rising_edge(clk_100) then
--          if reset_delay_count = C_PWRUP_RESET_DELAY then
--              rst <= '0';
--          else
--              rst <= '1';
--              reset_delay_count <= std_logic_vector(unsigned(reset_delay_count) + 1);
--          end if;

            d_and.trigger_set.packet_type_en <= '0';
            d_and.trigger_set.packet_type <= TLP_PKT;
            d_and.trigger_set.tlp_type_en <= '1';
            d_and.trigger_set.tlp_type <= NO_PCK;
            d_and.trigger_set.dllp_type_en <= '0';
            d_and.trigger_set.dllp_type <= NO_PCK;
            d_and.trigger_set.order_set_en <= '0';
            d_and.trigger_set.order_set_type <= NO_PCK;
            d_and.trigger_set.addr_match_en <= '0';
            d_and.trigger_set.addr_match <= (others => '0');
            d_and.filter_in.tlp_save <= '1';
            d_and.filter_in.order_set_save <= '0';
            d_and.filter_in.dllp_save <= '0';

            trigger_stop(0) <= q_and.stop_trigger;
            trigger_stop(1) <= trigger_stop(0);

            data_ch_1 <= mem_data_out(34 downto 27) & mem_data_out(25 downto 18) & mem_data_out(16 downto 9) & mem_data_out(7 downto 0);
            data_out_o <= data_ch_1;
        end if;
    end process;

    resync_process : process (rx_pclk_1) is
    begin
        if rising_edge (rx_pclk_1) then
            trigger_resync(0) <= q_ra.trigger_ena;
            trigger_resync(1) <= trigger_resync(0);
        end if;
    end process;
end architecture RTL;
