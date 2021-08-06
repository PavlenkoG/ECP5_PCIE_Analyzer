#!/usr/local/bin/wish

set cpu  $tcl_platform(machine)

switch $cpu {
 intel -
 i*86* {
     set cpu ix86
 }
 x86_64 {
     if {$tcl_platform(wordSize) == 4} {
     set cpu ix86
     }
 }
}

switch $tcl_platform(platform) {
    windows {
        set Para(os_platform) windows
   if {$cpu == "amd64"} {
     # Do not check wordSize, win32-x64 is an IL32P64 platform.
     set cpu x86_64
     }
    }
    unix {
        if {$tcl_platform(os) == "Linux"}  {
            set Para(os_platform) linux
        } else  {
            set Para(os_platform) unix
        }
    }
}

if {$cpu == "x86_64"} {
 set NTPATH nt64
 set LINPATH lin64
} else {
 set NTPATH nt
 set LINPATH lin
}

if {$Para(os_platform) == "linux" } {
    set os $LINPATH
} else {
    set os $NTPATH
}
set Para(ProjectPath) [file dirname [info script]]
set Para(install_dir) $env(TOOLRTF)
set Para(design) "verilog"
set Para(Bin) "[file join $Para(install_dir) bin $os]"
set Para(FPGAPath) "[file join $Para(install_dir) ispfpga bin $os]"
lappend auto_path "$Para(install_dir)/tcltk/lib/ipwidgets/ispipbuilder/../runproc"
package require runcmd

set Para(ModuleName) "pcie"
set Para(Family) "sa5p00m"
set Para(tech) ecp5um
set Para(caelib) ecp5um
set Para(PartType) "LFE5UM-85F"
set Para(PartName) "LFE5UM-85F-7BG381I"
set Para(SpeedGrade) "7"
set retdir [pwd]
cd $Para(ProjectPath)
set synpwrap_cmd "$Para(Bin)/synpwrap"
if {[file exist syn_results]} {
} else {
file mkdir syn_results
}

    if [catch {open $Para(ModuleName).cmd w} rspFile] {
                puts stderr "Cannot create response file $Para(ModuleName).cmd: $rspFile"
                return -1
    } else {
                puts $rspFile "PROJECT: $Para(ModuleName)"
                puts $rspFile "working_path: \"syn_results\""
                puts $rspFile "module: $Para(ModuleName)"
                puts $rspFile "vhdl_file_list: \"$Para(install_dir)/cae_library/synthesis/vhdl/$Para(caelib).vhd\""
                puts $rspFile "vhdl_file_list: \"../$Para(ModuleName).vhd\""
                puts $rspFile "verilog_file_list: \"$Para(install_dir)/cae_library/synthesis/verilog/pmi_def.v\""
                puts $rspFile "verilog_file_list: \"../pcie_eval/models/$Para(tech)/$Para(ModuleName)_pcs_softlogic.v\""
                puts $rspFile "verilog_file_list: \"../pcie_eval/models/$Para(tech)/$Para(ModuleName)_pcs.v\""
                puts $rspFile "verilog_file_list: \"../pcie_eval/models/$Para(tech)/$Para(ModuleName)_sync1s.v\""
                puts $rspFile "verilog_file_list: \"../pcie_eval/models/$Para(tech)/$Para(ModuleName)_ctc.v\""
                puts $rspFile "verilog_file_list: \"../pcie_eval/models/$Para(tech)/$Para(ModuleName)_pipe.v\""
                puts $rspFile "verilog_file_list: \"../pcie_eval/models/$Para(tech)/$Para(ModuleName)_phy.v\""
                puts $rspFile "resource_sharing: false"
                puts $rspFile "write_verilog: false"
                puts $rspFile "write_vhdl: true"
                puts $rspFile "suffix_name: edi"
                puts $rspFile "output_file_name: $Para(ModuleName)"
                puts $rspFile "write_prf: false"
                puts $rspFile "vlog_std_v2001: true"
                puts $rspFile "disable_io_insertion: true"
                puts $rspFile "force_gsr: false"
                puts $rspFile "speed_grade: $Para(SpeedGrade)"
                puts $rspFile "frequency: 125.000"
                puts $rspFile "fanout_limit: 100"
                puts $rspFile "retiming: false"
                puts $rspFile "pipe: false"
                puts $rspFile "fixgatedclocks: 0"
                puts $rspFile "fixgeneratedclocks: 0"
                close $rspFile
    }

    if [runCmd "\"$synpwrap_cmd\" -rem -e $Para(ModuleName) -target ecp5um"] {
                return
    } else {
                vwait done
                if [checkResult $done] {
                    return
                }
    }

    if [runCmd "\"$Para(FPGAPath)/edif2ngd\" -l $Para(family) -d $Para(PartType) -nopropwarn \"syn_results/$Para(ModuleName).edi\" \"$Para(ModuleName).ngo\""] {
                return
    } else {
                vwait done
                if [checkResult $done] {
                    return
                }
    }

    if [runCmd "\"$Para(FPGAPath)/ngdbuild\" -dt -a $Para(family) -d $Para(PartType) -p \"$Para(install_dir)/ispfpga/$Para(Family)/data\" -p \"syn_results\" \"$Para(ModuleName).ngo\" \"$Para(ModuleName).ngd\""] {
                return
    } else {
                vwait done
                if [checkResult $done] {
                    return
                }
    }

file delete -force "syn_results"
cd $retdir

