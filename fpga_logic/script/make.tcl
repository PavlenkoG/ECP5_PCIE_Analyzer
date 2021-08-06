
cd ..
set ProjectPath [pwd]
set SrcPath $ProjectPath/SRC
set CorePath "C:/.conan/e6e55c/1"
set DesignInfoPath "$ProjectPath/bae-lib/m100-design-info"

puts "Clear project"

file delete -force Impl

file mkdir Impl
cd $ProjectPath/Impl

puts "Creating new backplane project"

prj_project new -name "bpl100" -impl "bpl100" -dev LFE5UM-85F-8BG381I -synthesis "synplify"
prj_project save

puts "Copying core files"

file mkdir ip_cores/pcie
file mkdir ip_cores/extref
file copy -force $ProjectPath/src/cores/pcie/pcie.lpc $ProjectPath/Impl/ip_cores/pcie/pcie.lpc
file copy -force $ProjectPath/src/cores/pcie/generate_core.tcl $ProjectPath/Impl/ip_cores/pcie/generate_core.tcl
file copy -force $ProjectPath/src/cores/pcie/generate_ngd.tcl $ProjectPath/Impl/ip_cores/pcie/generate_ngd.tcl
file copy -force $ProjectPath/src/cores/extref/extref.lpc $ProjectPath/Impl/ip_cores/extref/extref.lpc
file copy -force $ProjectPath/src/cores/extref/generate_core.tcl $ProjectPath/Impl/ip_cores/extref/generate_core.tcl
file copy -force $ProjectPath/src/cores/extref/generate_ngd.tcl $ProjectPath/Impl/ip_cores/extref/generate_ngd.tcl

set currentPath [pwd];set tmp_autopath $auto_path

file copy -force $ProjectPath/src/cores/ip_cores.sbx $ProjectPath/Impl/ip_cores/ip_cores.sbx

prj_src add "ip_cores/ip_cores.sbx"
sbp_design open -dsgn ip_cores/ip_cores.sbx

puts "Creating PICExpress core"

cd "$ProjectPath/Impl/ip_cores/pcie"
source "$ProjectPath/Impl/ip_cores/pcie/generate_core.tcl"
set auto_path $tmp_autopath;cd $currentPath
set currentPath [pwd];set tmp_autopath $auto_path
cd "$ProjectPath/Impl/ip_cores/pcie"
source "$ProjectPath/Impl/ip_cores/pcie/generate_ngd.tcl"

cd $currentPath

sbp_builder export_add -comp {ip_cores/pcie}

puts "Placing DCUCHANNEL"
sbp_resource place -rsc {ip_cores/pcie/DCUCHANNEL} -id 5

puts "Creating Extref core"

cd "$ProjectPath/Impl/ip_cores/extref"
source "$ProjectPath/Impl/ip_cores/extref/generate_core.tcl"
set auto_path $tmp_autopath;cd $currentPath
set currentPath [pwd];set tmp_autopath $auto_path
cd "$ProjectPath/Impl/ip_cores/extref"
source "$ProjectPath/Impl/ip_cores/extref/generate_ngd.tcl"

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
prj_src add "$ProjectPath/src/dma_table.vhd"
prj_src add "$ProjectPath/src/dma_controller.vhd"
prj_src add "$ProjectPath/src/command_interpreter.vhd"
prj_src add "$ProjectPath/src/mem_18_4096.vhd"
prj_src add "$ProjectPath/src/mem_36_2048.vhd"
prj_src add "$ProjectPath/src/msi_x_table.vhd"
prj_src add "$ProjectPath/src/msi_x_pba.vhd"
prj_src add "$ProjectPath/src/packet_fifo.vhd"
prj_src add "$ProjectPath/src/clk_pll.vhd"
prj_src add "$ProjectPath/src/clock_gen.vhd"
prj_src add "$ProjectPath/src/completer_term.vhd"
prj_src add "$ProjectPath/src/idx_memory.vhd"
prj_src add "$ProjectPath/src/bus_rx_fh_fifo.vhd"
prj_src add "$ProjectPath/src/bus_tx_fh_fifo.vhd"
prj_src add "$ProjectPath/src/bus_controller.vhd"
prj_src add "$ProjectPath/src/msi_x_controller.vhd"
prj_src add "$ProjectPath/src/ptm_engine.vhd"
prj_src add "$ProjectPath/src/pdp_64_64.vhd.vhd"
prj_src add "$ProjectPath/src/rd_wr_pkg.vhd"
prj_src add "$ProjectPath/src/reg_controller.vhd"
prj_src add "$ProjectPath/src/top_pkg.vhd"
prj_src add "$ProjectPath/src/top.vhd"

prj_src add "$CorePath/src/sio_time_engine.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_wr_controller.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_rd_controller.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_serializer.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_serializer_sc.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_status_engine.vhd" -work m100_sio_core
#prj_src add "$CorePath/src/sio_sync_adder.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_sync_os_comp.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_sync_comp.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_sync_engine.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_frame_engine_rx.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_frame_engine_tx.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_frame_handler.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_frame_opcodes_pkg.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_nonvol_buffer.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_nonvol_controller.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_wr_buffer.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_rd_buffer.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_bus.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_crc8_generator.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_deserializer.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_deserializer_sc.vhd" -work m100_sio_core

prj_src add "$CorePath/src/sio_sync_os_comp.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_wr_buffer.vhd" -work m100_sio_core
prj_src add "$CorePath/src/sio_rd_buffer.vhd" -work m100_sio_core

prj_src add "$CorePath/src/core/sio_nonvol_buffer_fifo_cw.vhd" -work m100_sio_core
prj_src add "$CorePath/src/core/sio_set_addr_map_cw.vhd" -work m100_sio_core
prj_src add "$CorePath/src/core/sio_spi_controller_cw.vhd" -work m100_sio_core
prj_src add "$CorePath/src/core/sio_cfg_frame_ram_cw.vhd" -work m100_sio_core
prj_src add "$CorePath/src/core/sio_frame_buffer_cw.vhd" -work m100_sio_core
prj_src add "$CorePath/src/core/sio_get_addr_map_cw.vhd" -work m100_sio_core

prj_src add "$CorePath/src/core/machxo3/sio_machxo3_nonvol_buffer_fifo_core.vhd" -work m100_sio_core
prj_src add "$CorePath/src/core/machxo3/sio_machxo3_spi_controller.vhd" -work m100_sio_core
prj_src add "$CorePath/src/core/machxo3/sio_machxo3_spi_core.vhd" -work m100_sio_core
prj_src add "$CorePath/src/core/machxo3/sio_machxo3_addr_map_core.vhd" -work m100_sio_core
prj_src add "$CorePath/src/core/machxo3/sio_machxo3_cfg_frame_ram_core.vhd" -work m100_sio_core
prj_src add "$CorePath/src/core/machxo3/sio_machxo3_frame_buffer_core.vhd" -work m100_sio_core

prj_src add "$CorePath/src/core/ecp5/sio_ecp5_frame_buffer_core.vhd" -work m100_sio_core
prj_src add "$CorePath/src/core/ecp5/sio_ecp5_nonvol_buffer_fifo_core.vhd" -work m100_sio_core
prj_src add "$CorePath/src/core/ecp5/sio_ecp5_spi_controller.vhd" -work m100_sio_core
prj_src add "$CorePath/src/core/ecp5/sio_ecp5_addr_map_core.vhd" -work m100_sio_core
prj_src add "$CorePath/src/core/ecp5/sio_ecp5_cfg_frame_ram_core.vhd" -work m100_sio_core

prj_src add "$CorePath/src_bp/siobp_time_master.vhd" -work m100_sio_core
prj_src add "$CorePath/src_bp/siobp_frame_handler.vhd" -work m100_sio_core
prj_src add "$CorePath/src_bp/siobp_frame_engine_rx.vhd" -work m100_sio_core
prj_src add "$CorePath/src_bp/siobp_frame_engine_tx.vhd" -work m100_sio_core

prj_src add "$CorePath/src_bp/core/siobp_frame_buffer_rx_cw.vhd" -work m100_sio_core
prj_src add "$CorePath/src_bp/core/siobp_frame_buffer_tx_cw.vhd" -work m100_sio_core

prj_src add "$CorePath/src_bp/core/ecp5/siobp_ecp5_frame_buffer_tx_core.vhd" -work m100_sio_core
prj_src add "$CorePath/src_bp/core/ecp5/siobp_ecp5_frame_buffer_rx_core.vhd" -work m100_sio_core

prj_src add "$DesignInfoPath/design_info_pkg.vhd" -work m100_design_info

prj_src add "$ProjectPath/SRC/constrains.lpf"
prj_src enable "$ProjectPath/SRC/constrains.lpf"
prj_src remove "$ProjectPath/Impl/bpl100.lpf"
file delete -force $ProjectPath/Impl/bpl100.lpf
 
prj_strgy set_value -strategy Strategy1 syn_vhdl2008=True
prj_project save