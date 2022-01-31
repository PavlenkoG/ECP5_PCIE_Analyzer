onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /spi_controller_tb/clk_100
add wave -noupdate /spi_controller_tb/rst
add wave -noupdate /spi_controller_tb/SCLK
add wave -noupdate /spi_controller_tb/mosi
add wave -noupdate /spi_controller_tb/miso
add wave -noupdate /spi_controller_tb/cs_n
add wave -noupdate -radix hexadecimal /spi_controller_tb/controller_inst/d
add wave -noupdate -radix hexadecimal /spi_controller_tb/controller_inst/q
add wave -noupdate -radix hexadecimal /spi_controller_tb/controller_inst/r
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
run 10 us
WaveRestoreZoom {0 ps} {6 us}
