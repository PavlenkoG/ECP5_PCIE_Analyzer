
"""
BPL Project test
"""

from pathlib import Path
from vunit import VUnit, VUnitCLI
from vunit.sim_if import activehdl

VU = VUnit.from_argv()
VU.add_osvvm()
VU.add_verification_components()


SRC_PATH = Path(__file__).parents[2]

'''
MACHXO_VHDL_LIB = Path("C:\\lscc\\diamond\\3.12\\cae_library\\simulation\\vhdl\\machxo3l\\src")
MACHXO_VL_LIB =   Path("C:\\lscc\\diamond\\3.12\\cae_library\\simulation\\verilog\\machxo3l")
ECP5_VHDL_LIB = Path("C:\\lscc\\diamond\\3.12\\cae_library\\simulation\\vhdl\\ecp5u\\src")
ECP5_VL_LIB =   Path("C:\\lscc\\diamond\\3.12\\cae_library\\simulation\\verilog\\ecp5u")
'''


'''
VU.add_external_library("ecp5u","C:\\lscc\\diamond\\3.11_x64\\active-hdl\\vlib\\ecp5u")
VU.add_external_library("ecp5um","C:\\lscc\\diamond\\3.11_x64\\active-hdl\\vlib\\ecp5u")
VU.add_external_library("machxo3l","C:\\lscc\\diamond\\3.11_x64\\active-hdl\\vlib\\machxo3l")
VU.add_external_library("ovi_ecp5u","C:\\lscc\\diamond\\3.11_x64\\active-hdl\\vlib\\ovi_ecp5u")
VU.add_external_library("pmi_work","C:\\lscc\\diamond\\3.11_x64\\active-hdl\\vlib\\pmi_work")
VU.add_external_library("aldec","C:\\lscc\\diamond\\3.11_x64\\active-hdl\\vlib\\aldec")
VU.add_external_library("pcsd_aldec_work","C:\\lscc\\diamond\\3.11_x64\\active-hdl\\vlib\\pcsd_aldec_work")
'''


VU.add_external_library("ecp5u","C:\\Aldec\\Active-HDL-11.1\\vlib\\lattice\\vhdl\\ecp5u")
VU.add_external_library("ecp5um","C:\\Aldec\\Active-HDL-11.1\\vlib\\lattice\\vhdl\\ecp5u")
VU.add_external_library("machxo3l","C:\\Aldec\\Active-HDL-11.1\\vlib\\lattice\\vhdl\\machxo3l")
VU.add_external_library("ovi_ecp5u","C:\\Aldec\\Active-HDL-11.1\\vlib\\lattice\\verilog\\ovi_ecp5u")
VU.add_external_library("pmi_work","C:\\Aldec\\Active-HDL-11.1\\vlib\\lattice\\verilog\\pmi_work")
VU.add_external_library("aldec","C:\\Aldec\\Active-HDL-11.1\\vlib\\aldec")
VU.add_external_library("pcsd_aldec_work","C:\\Aldec\\Active-HDL-11.1\\vlib\\lattice\\verilog\\pcsd_aldec_work")

#add pcie core
VU.add_library("sim_core")
VU.library("sim_core").add_source_file(SRC_PATH / "sim_core" / "ip_cores " / "pcie" / "pcie.vhd")

#add extref
VU.library("sim_core").add_source_files(SRC_PATH / "sim_core" / "ip_cores" / "extref" / "*.vhd")

#add project library
VU.library("sim_core").add_source_files(SRC_PATH / "SRC" / "*.vhd")


#add simulation
VU.library("sim_core").add_source_files(SRC_PATH / "sim" / "VUnit" / "*.vhd")


VU.add_library("pcie_core")
'''
VU.library("pcie_core").add_source_file(SRC_PATH / "sim_core" / "ip_cores " / "pcie" / "pcie_eval" / "pcie" /"src"/"top"/"pcie_beh.v")
'''

VU.set_compile_option("activehdl.vcom_flags", ['-2008'])


VU.set_compile_option("activehdl.vlog_flags", ['-v2k5', '-dbg', '+define+RSL_SIM_MODE', '+define+SIM_MODE', '+define+USERNAME_EVAL_TOP=pcie_eval_top',
                                               '+define+DEBUG=0', '+define+SIMULATE',  '+define+VHDL_SIM','+define+mixed_hdl',
                                               '+incdir+../sim_core/ip_cores/pcie/pcie_eval/pcie/testbench/top',
                                               '+incdir+../sim_core/ip_cores/pcie/pcie_eval/pcie/testbench/tests',
                                               '+incdir+../sim_core/ip_cores/pcie/pcie_eval/models/ecp5um',
                                               '+incdir+../sim_core/ip_cores/pcie/pcie_eval/pcie/src/params',
                                               '../sim_core/ip_cores/pcie/pcie_eval/pcie/src/params/pci_exp_params.v',
                                               '../sim_core/ip_cores/pcie/pcie_eval/pcie/testbench/top/eval_pcie.v',
                                               '../sim_core/ip_cores/pcie/pcie_eval/pcie/testbench/top/eval_tbtx.v',
                                               '../sim_core/ip_cores/pcie/pcie_eval/pcie/testbench/top/eval_tbrx.v',
                                               '../sim_core/ip_cores/pcie/pcie_eval/models/ecp5um/pcie_ctc.v',
                                               '../sim_core/ip_cores/pcie/pcie_eval/models/ecp5um/pcie_sync1s.v',
                                               '../sim_core/ip_cores/pcie/pcie_eval/models/ecp5um/pcie_pipe.v',
                                               '../sim_core/ip_cores/pcie/pcie_eval/models/ecp5um/pcie_extref.v',
                                               '../sim_core/ip_cores/pcie/pcie_eval/models/ecp5um/pcie_pcs_softlogic.v',
                                               '../sim_core/ip_cores/pcie/pcie_eval/models/ecp5um/pcie_pcs.v',
                                               '../sim_core/ip_cores/pcie/pcie_eval/models/ecp5um/pcie_phy.v',
                                               '../sim_core/ip_cores/pcie/pcie_eval/pcie/src/top/pcie_core.v' ])

VU.set_sim_option("activehdl.vsim_flags",["+access +w_nets", "+access +r","-ieee_nowarn","-t 1ps",
                                          "-L pcie_core","-L pmi_work","-L ovi_ecp5u",
                                          "-L pcsd_aldec_work","-L ecp5um", "-L sim_core"])#, "; do -do ../../v_MEM.do"])

#VU.set_sim_option('activehdl.init_file.gui','v_MEM.do')
VU.main()
