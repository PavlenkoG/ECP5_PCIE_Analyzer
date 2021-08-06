#!/usr/local/bin/wish

proc GetPlatform {} {
    global tcl_platform

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
            if {$cpu == "amd64"} {
                # Do not check wordSize, win32-x64 is an IL32P64 platform.
                set cpu x86_64
            }
            if {$cpu == "x86_64"} {
                return "nt64"
            } else {
                return "nt"
            }
        }
        unix {
            if {$tcl_platform(os) == "Linux"}  {
                if {$cpu == "x86_64"} {
                    return "lin64"
                } else {
                    return "lin"
                }
            } else  {
                return "sol"
            }
        }
    }
    return "nt"
}

set platformpath [GetPlatform]
set Para(spx_dir) [file dirname [info script]]
set Para(install_dir) $env(TOOLRTF)
set Para(FPGAPath) "[file join $Para(install_dir) ispfpga bin $platformpath]"

set asbgen "$Para(FPGAPath)/asbgen"
set modulename "extref"
set lang "vhdl"
set lpcfile "$Para(spx_dir)/$modulename.lpc"
set arch "sa5p00m"
set Para(result) [catch {exec "$asbgen" -n "$modulename" -lang "$lang" -arch "$arch" -fe "$lpcfile"} msg]
#puts $msg
