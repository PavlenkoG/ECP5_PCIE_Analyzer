
cd ..
set ProjectPath [pwd]
set SrcPath $ProjectPath/SRC

puts "Clear project"

file delete -force sim_core

file mkdir sim_core
cd $ProjectPath/sim_core

puts "Creating new backplane project"

prj_project new -name "pcie_core" -impl "pcie_core" -dev LFE5UM-85F-8BG381I -synthesis "synplify"
prj_project save

puts "Copying core files"

file mkdir ip_cores/pcie
file mkdir ip_cores/extref
file copy -force $ProjectPath/src/cores/pcie/pcie.lpc $ProjectPath/sim_core/ip_cores/pcie/pcie.lpc
file copy -force $ProjectPath/src/cores/pcie/generate_core.tcl $ProjectPath/sim_core/ip_cores/pcie/generate_core.tcl
file copy -force $ProjectPath/src/cores/pcie/generate_ngd.tcl $ProjectPath/sim_core/ip_cores/pcie/generate_ngd.tcl
file copy -force $ProjectPath/src/cores/extref/extref.lpc $ProjectPath/sim_core/ip_cores/extref/extref.lpc
file copy -force $ProjectPath/src/cores/extref/generate_core.tcl $ProjectPath/sim_core/ip_cores/extref/generate_core.tcl
file copy -force $ProjectPath/src/cores/extref/generate_ngd.tcl $ProjectPath/sim_core/ip_cores/extref/generate_ngd.tcl

set currentPath [pwd];set tmp_autopath $auto_path

file copy -force $ProjectPath/src/cores/ip_cores.sbx $ProjectPath/sim_core/ip_cores/ip_cores.sbx

prj_src add "ip_cores/ip_cores.sbx"
sbp_design open -dsgn ip_cores/ip_cores.sbx

puts "Creating PICExpress core"

cd "$ProjectPath/sim_core/ip_cores/pcie"
source "$ProjectPath/sim_core/ip_cores/pcie/generate_core.tcl"
set auto_path $tmp_autopath;cd $currentPath
set currentPath [pwd];set tmp_autopath $auto_path
cd "$ProjectPath/sim_core/ip_cores/pcie"
source "$ProjectPath/sim_core/ip_cores/pcie/generate_ngd.tcl"

cd $currentPath

sbp_builder export_add -comp {ip_cores/pcie}

puts "Placing DCUCHANNEL"
sbp_resource place -rsc {ip_cores/pcie/DCUCHANNEL} -id 5

puts "Creating Extref core"

cd "$ProjectPath/sim_core/ip_cores/extref"
source "$ProjectPath/sim_core/ip_cores/extref/generate_core.tcl"
set auto_path $tmp_autopath;cd $currentPath
set currentPath [pwd];set tmp_autopath $auto_path
cd "$ProjectPath/sim_core/ip_cores/extref"
source "$ProjectPath/sim_core/ip_cores/extref/generate_ngd.tcl"

sbp_builder export_add -comp {ip_cores/extref}
puts "Placing EXTREF"

sbp_resource place -rsc {ip_cores/extref/EXTREF} -id 3

puts "Generating PCIExpress core"

sbp_design gen

sbp_design save

sbp_design close

prj_src add "$ProjectPath/src/pci_core_wrapper.vhd"
prj_src add "$ProjectPath/src/pci_wrapper_pkg.vhd"
prj_src add "$ProjectPath/src/pcie_rx_engine.vhd"
prj_src add "$ProjectPath/src/pcie_tx_engine.vhd"
prj_src add "$ProjectPath/src/pci_read_request_fifo.vhd"
prj_src add "$ProjectPath/src/top_pkg.vhd"
prj_src add "$ProjectPath/src/top.vhd"


prj_src add "$ProjectPath/SRC/constrains.lpf"
prj_src enable "$ProjectPath/SRC/constrains.lpf"
prj_src remove "$ProjectPath/sim_core/bpl100.lpf"
file delete -force $ProjectPath/sim_core/bpl100.lpf
 
prj_strgy set_value -strategy Strategy1 syn_vhdl2008=True
prj_project save