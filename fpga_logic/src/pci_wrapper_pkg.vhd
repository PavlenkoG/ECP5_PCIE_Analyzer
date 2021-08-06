--------------------------------------------------------------------------------
-- Entity: pci_wrapper_pkg
-- Date:2016-06-03
-- Author: grpa
--
-- Description:
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package pci_wrapper_pkg is

    --! TLP Header types
    constant RX_MEM_RD_FMT_TYPE : std_logic_vector(6 downto 0) := "0000000";
    constant RX_MEM_WR_FMT_TYPE : std_logic_vector(6 downto 0) := "1000000";
    constant RX_CPLD_FMT_TYPE   : std_logic_vector(6 downto 0) := "1001010";
    constant RX_CFG_WR_FMT_TYPE : std_logic_vector(6 downto 0) := "1000100";
    constant RX_CFG_RD_FMT_TYPE : std_logic_vector(6 downto 0) := "0000100";
    constant RX_CPL_FMT_TYPE    : std_logic_vector(6 downto 0) := "0001010";
    constant TX_MSG_RQ_FMT_TYPE : std_logic_vector(6 downto 0) := "0110100";
    constant RX_RESP_PTM_TYPE   : std_logic_vector(6 downto 0) := "1110000";
    --! These bits encoded by the completer to indicate success in fulfilling the request
    constant SUCCESSFUL_CMPL    : std_logic_vector (2 downto 0) := "000";   --! Successful Completion (SC)
    constant UNSUPPRTD_RQ       : std_logic_vector (2 downto 0) := "001";   --! Unsupported Request (UR)
    constant CONF_REQ_RS        : std_logic_vector (2 downto 0) := "010";   --! Config Req Retry Status (CR S)
    constant COMPLETER_ABORT    : std_logic_vector (2 downto 0) := "100";   --! Completer abort. (CA)

    type t_tx_tlp_intf_d is record
        tx_data_vc0             : std_logic_vector(15 downto 0);
        tx_req_vc0              : std_logic;
        tx_st_vc0               : std_logic;
        tx_end_vc0              : std_logic;
        tx_nlfy_vc0             : std_logic;
    end record;

    type t_tx_tlp_intf_q is record
        tx_rdy_vc0              : std_logic;
        tx_ca_ph_vc0            : std_logic_vector (8 downto 0);
        tx_ca_nph_vc0           : std_logic_vector (8 downto 0);
        tx_ca_cplh_vc0          : std_logic_vector (8 downto 0);
        tx_ca_pd_vc0            : std_logic_vector(12 downto 0);
        tx_ca_npd_vc0           : std_logic_vector(12 downto 0);
        tx_ca_cpld_vc0          : std_logic_vector(12 downto 0);
        tx_ca_p_recheck_vc0     : std_logic;
        tx_ca_cpl_recheck_vc0   : std_logic;
    end record;

    type t_rx_tlp_intf_d is record
        ur_np_ext               : std_logic;
        ur_p_ext                : std_logic;
        ph_buf_status_vc0       : std_logic;
        pd_buf_status_vc0       : std_logic;
        nph_buf_status_vc0      : std_logic;
        npd_buf_status_vc0      : std_logic;
        ph_processed_vc0        : std_logic;
        nph_processed_vc0       : std_logic;
        pd_processed_vc0        : std_logic;
        npd_processed_vc0       : std_logic;
        pd_num_vc0              : std_logic_vector(7 downto 0);
        npd_num_vc0             : std_logic_vector(7 downto 0);
    end record;

    type t_rx_tlp_intf_q is record
        rx_data_vc0             : std_logic_vector(15 downto 0);
        rx_st_vc0               : std_logic;
        rx_end_vc0              : std_logic;
        rx_us_req_vc0           : std_logic;
        rx_malf_tlp_vc0         : std_logic;
        rx_bar_hit              : std_logic_vector(6 downto 0);
    end record;

    type t_phy_layer_d is record
        no_pcie_train           : std_logic;
        force_lsm_active        : std_logic;
        force_rec_ei            : std_logic;
        force_phy_status        : std_logic;
        force_disable_scr       : std_logic;
        hl_snd_beacon           : std_logic;
        hl_disable_scr          : std_logic;
        hl_gto_dis              : std_logic;
        hl_gto_det              : std_logic;
        hl_gto_hrst             : std_logic;
        hl_gto_l0stx            : std_logic;
        hl_gto_l0stxfts         : std_logic;
        hl_gto_l1               : std_logic;
        hl_gto_l2               : std_logic;
        hl_gto_lbk              : std_logic;
        hl_gto_rcvry            : std_logic;
        hl_gto_cfg              : std_logic;
        tx_lbk_kcntl            : std_logic_vector(1 downto 0);
        tx_lbk_data             : std_logic_vector(15 downto 0);
    end record;

    type t_phy_layer_q is record
        phy_ltssm_state         : std_logic_vector(3 downto 0);
        phy_pol_compliance      : std_logic;
        tx_lbk_rdy              : std_logic;
        rx_lbk_kcntl            : std_logic_vector(1 downto 0);
        rx_lbk_data             : std_logic_vector(15 downto 0);
    end record;

    type t_data_link_layer_d is record
        tx_dllp_val             : std_logic_vector(1 downto 0);
        tx_pmtype               : std_logic_vector(2 downto 0);
        tx_vsd_data             : std_logic_vector(23 downto 0);
    end record;

    type t_data_link_layer_q is record
        dl_inactive             : std_logic;
        dl_init                 : std_logic;
        dl_active               : std_logic;
        dl_up                   : std_logic;
        tx_dllp_sent            : std_logic;
        rxdp_pmd_type           : std_logic_vector(2 downto 0);
        rxdp_vsd_data           : std_logic_vector(23 downto 0);
        rxdp_dllp_val           : std_logic_vector(1 downto 0);
    end record;

    type t_transaction_layer_d is record
        cmpln_tout              : std_logic;
        cmpltr_abort_np         : std_logic;
        cmpltr_abort_p          : std_logic;
        unexp_cmpln             : std_logic;
        np_req_pend             : std_logic;
    end record;

    type t_config_reg_d is record
        inta_n                  : std_logic;
        msi                     : std_logic_vector(7 downto 0);
        pme_status              : std_logic;
    end record;

    type t_config_reg_q is record
        bus_num                 : std_logic_vector(7 downto 0);
        dev_num                 : std_logic_vector(4 downto 0);
        func_num                : std_logic_vector(2 downto 0);
        cmd_reg_out             : std_logic_vector(5 downto 0);
        dev_cntl_out            : std_logic_vector(14 downto 0);
        lnk_cntl_out            : std_logic_vector(7 downto 0);
        mm_enable               : std_logic_vector(2 downto 0);
        msi_enable              : std_logic;
        pme_en                  : std_logic;
        pm_power_state          : std_logic_vector(1 downto 0);
    end record;

end package;