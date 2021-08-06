 --------------------------------------------------------------------------------
-- Entity: pci_core_wrapper
-- Date:2016-06-03
-- Author: grpa
--
-- Description:
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ecp5um;
use ecp5um.components.all;
use work.pci_wrapper_pkg.all;

package pci_core_wrapper_pkg is

    type t_pci_core_wrapper_in is record
        tx_tlp              : t_tx_tlp_intf_d;
        rx_tlp              : t_rx_tlp_intf_d;
        data_link           : t_data_link_layer_d;
        transaction         : t_transaction_layer_d;
        cfg                 : t_config_reg_d;
    end record;

    type t_pci_core_wrapper_out is record
        tx_tlp              : t_tx_tlp_intf_q;
        rx_tlp              : t_rx_tlp_intf_q;
        phy                 : t_phy_layer_q;
        data_link           : t_data_link_layer_q;
        cfg                 : t_config_reg_q;
    end record;

end package pci_core_wrapper_pkg;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.pci_core_wrapper_pkg.all;

entity pci_core_wrapper is
    port  (
        pll_refclki             : in std_logic;
        rxrefclk                : in std_logic;
        no_pcie_train           : in std_logic;

        pci_core_hdinn0         : in std_logic;
        pci_core_hdinp0         : in std_logic;

        pci_core_hdoutn0        : out std_logic;
        pci_core_hdoutp0        : out std_logic;

        pci_rst_n               : in std_logic;
        sli_rst                 : in std_logic;

        sys_clk_125             : out std_logic;

        d                       : in t_pci_core_wrapper_in;
        q                       : out t_pci_core_wrapper_out
    );
end pci_core_wrapper;

architecture arch of pci_core_wrapper is
begin

    pci_core_inst :entity work.pcie
    port map (

            pll_refclki             => pll_refclki,
            rxrefclk                => rxrefclk,

            rst_n                   => pci_rst_n,
            sli_rst                 => sli_rst,
            serdes_pdb              => open,
            serdes_rst_dual_c       => open,
            tx_pwrup_c              => open,
            tx_serdes_rst_c         => open,
            sys_clk_125             => sys_clk_125,

            flip_lanes              => '0',

            hdinn0                  => pci_core_hdinn0,
            hdinp0                  => pci_core_hdinp0,
            hdoutn0                 => pci_core_hdoutn0,
            hdoutp0                 => pci_core_hdoutp0,
            -- TRANSMIT TLP INTERFACE
            tx_data_vc0             => d.tx_tlp.tx_data_vc0,
            tx_end_vc0              => d.tx_tlp.tx_end_vc0,
            tx_nlfy_vc0             => d.tx_tlp.tx_nlfy_vc0,
            tx_req_vc0              => d.tx_tlp.tx_req_vc0,
            tx_st_vc0               => d.tx_tlp.tx_st_vc0,

            tx_ca_cpld_vc0          => q.tx_tlp.tx_ca_cpld_vc0,
            tx_ca_cplh_vc0          => q.tx_tlp.tx_ca_cplh_vc0,
            tx_ca_npd_vc0           => q.tx_tlp.tx_ca_npd_vc0,
            tx_ca_nph_vc0           => q.tx_tlp.tx_ca_nph_vc0,
            tx_ca_pd_vc0            => q.tx_tlp.tx_ca_pd_vc0,
            tx_ca_ph_vc0            => q.tx_tlp.tx_ca_ph_vc0,
            tx_ca_cpl_recheck_vc0   => q.tx_tlp.tx_ca_cpl_recheck_vc0,
            tx_ca_p_recheck_vc0     => q.tx_tlp.tx_ca_p_recheck_vc0,
            tx_rdy_vc0              => q.tx_tlp.tx_rdy_vc0,
            -- RECEIVE TLP INTERFACE
            npd_buf_status_vc0      => d.rx_tlp.npd_buf_status_vc0,
            npd_processed_vc0       => d.rx_tlp.npd_processed_vc0,
            nph_buf_status_vc0      => d.rx_tlp.nph_buf_status_vc0,
            nph_processed_vc0       => d.rx_tlp.nph_processed_vc0,
            pd_buf_status_vc0       => d.rx_tlp.pd_buf_status_vc0,
            pd_processed_vc0        => d.rx_tlp.pd_processed_vc0,
            ph_buf_status_vc0       => d.rx_tlp.ph_buf_status_vc0,
            ph_processed_vc0        => d.rx_tlp.ph_processed_vc0,
            ur_np_ext               => '0',-- d.rx_tlp.ur_np_ext,
            ur_p_ext                => '0',-- d.rx_tlp.ur_p_ext,
            npd_num_vc0             => d.rx_tlp.npd_num_vc0,
            pd_num_vc0              => d.rx_tlp.pd_num_vc0,

            rx_data_vc0             => q.rx_tlp.rx_data_vc0,
            rx_bar_hit              => q.rx_tlp.rx_bar_hit,
            rx_end_vc0              => q.rx_tlp.rx_end_vc0,
            rx_malf_tlp_vc0         => q.rx_tlp.rx_malf_tlp_vc0,
            rx_st_vc0               => q.rx_tlp.rx_st_vc0,
            rx_us_req_vc0           => q.rx_tlp.rx_us_req_vc0,
            -- CONFIGURATION REGISTERS
            inta_n                  => '1',--TODO d.cfg.inta_n,
            msi                     => d.cfg.msi,
            pme_status              => '0',--d.cfg.pme_status,

            bus_num                 => q.cfg.bus_num,
            cmd_reg_out             => q.cfg.cmd_reg_out,
            dev_cntl_out            => q.cfg.dev_cntl_out,
            dev_num                 => q.cfg.dev_num,
            func_num                => q.cfg.func_num,
            lnk_cntl_out            => q.cfg.lnk_cntl_out,
            mm_enable               => q.cfg.mm_enable,
            pm_power_state          => q.cfg.pm_power_state,
            msi_enable              => q.cfg.msi_enable,
            pme_en                  => q.cfg.pme_en,
            -- DATA LINK LAYER
            tx_dllp_val             => "00",--d.data_link.tx_dllp_val,
            tx_pmtype               => "000",--d.data_link.tx_pmtype,
            tx_vsd_data             => (others=>'0'),--d.data_link.tx_vsd_data,

            dl_inactive             => q.data_link.dl_inactive,
            dl_init                 => q.data_link.dl_init,
            dl_active               => q.data_link.dl_active,
            dl_up                   => q.data_link.dl_up,
            tx_dllp_sent            => q.data_link.tx_dllp_sent,
            rxdp_pmd_type           => q.data_link.rxdp_pmd_type,
            rxdp_vsd_data           => q.data_link.rxdp_vsd_data,
            rxdp_dllp_val           => q.data_link.rxdp_dllp_val,
            -- TRANSACTION LAYER
            unexp_cmpln             => d.transaction.unexp_cmpln,
            np_req_pend             => '0',--d.transaction.np_req_pend,
            cmpln_tout              => '0',--d.transaction.cmpln_tout,
            cmpltr_abort_np         => '0',-- d.transaction.cmpltr_abort_np,
            cmpltr_abort_p          => '0',-- d.transaction.cmpltr_abort_p,
            -- CONTROL AND STATUS
            no_pcie_train           => no_pcie_train,--'1',--TODO set 0 to implementation
            force_lsm_active        => '0',--TODO set 0 to implementation d.phy.force_lsm_active,
            force_rec_ei            => '0',--d.phy.force_rec_ei,
            force_phy_status        => '0',--d.phy.force_phy_status,
            force_disable_scr       => '0',--d.phy.force_disable_scr,
            hl_snd_beacon           => '0',--d.phy.hl_snd_beacon,
            hl_disable_scr          => '0',--d.phy.hl_disable_scr,
            hl_gto_dis              => '0',--d.phy.hl_gto_dis,
            hl_gto_det              => '0',--d.phy.hl_gto_det,
            hl_gto_hrst             => '0',--d.phy.hl_gto_hrst,
            hl_gto_l0stx            => '0',--d.phy.hl_gto_l0stx,
            hl_gto_l0stxfts         => '0',--d.phy.hl_gto_l0stxfts,
            hl_gto_l1               => '0',--d.phy.hl_gto_l1,
            hl_gto_l2               => '0',--d.phy.hl_gto_l2,
            hl_gto_lbk              => '0',--d.phy.hl_gto_lbk,
            hl_gto_rcvry            => '0',--d.phy.hl_gto_rcvry,
            hl_gto_cfg              => '0',--d.phy.hl_gto_cfg,
            tx_lbk_kcntl            => (others => '0'),--d.phy.tx_lbk_kcntl,
            tx_lbk_data             => (others => '0'),--d.phy.tx_lbk_data,

            --------------------------------------------------------------------
            -- sci
            --------------------------------------------------------------------
            sci_wrdata              => (others => '0'),
            sci_addr                => (others => '0'),
            sci_rddata              => open,
            sci_int                 => open,
            sci_en_dual             => '0',
            sci_sel_dual            => '0',
            sci_rd                  => '0',
            sci_wrn                 => '0',
            sci_sel                 => '0',
            sci_en                  => '0',
            --------------------------------------------------------------------

            phy_ltssm_state         => q.phy.phy_ltssm_state,
            phy_pol_compliance      => q.phy.phy_pol_compliance,
            tx_lbk_rdy              => q.phy.tx_lbk_rdy,
            rx_lbk_kcntl            => q.phy.rx_lbk_kcntl,
            rx_lbk_data             => q.phy.rx_lbk_data
    );


end arch;

