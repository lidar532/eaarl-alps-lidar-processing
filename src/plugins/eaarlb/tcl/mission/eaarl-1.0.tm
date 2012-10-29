# vim: set ts=4 sts=4 sw=4 ai sr et:

package provide mission::eaarl 1.0
package require mission

namespace eval ::mission::eaarl {
    namespace import ::yorick::ystr
    namespace import ::misc::menulabel

    proc initialize_path_mission {} {}
    proc initial_path_flight {} {}

    proc load_data {flight} {
        set flight [ystr $flight]
        exp_send "mission, load, \"$flight\";\r"
    }
    set ::mission::commands(load_data) ::mission::eaarl::load_data

    proc menu_actions {mb} {
        $mb add separator
        $mb add command {*}[menulabel "Launch RGB"] \
                -command ::mission::eaarl::menu_load_rgb
        $mb add command {*}[menulabel "Launch CIR"] \
                -command ::mission::eaarl::menu_load_cir
        $mb add command {*}[menulabel "Launch NIR"] \
                -command ::mission::eaarl::menu_load_nir
        $mb add command {*}[menulabel "Dump RGB"] \
                -command ::mission::eaarl::menu_dump_rgb
        $mb add command {*}[menulabel "Dump NIR"] \
                -command ::mission::eaarl::menu_dump_nir
        $mb add separator
        $mb add command {*}[menulabel "Generate KMZ"]
        $mb add command {*}[menulabel "Show EDB summary"]
    }
    set ::mission::commands(menu_actions) ::mission::eaarl::menu_actions

    proc refresh_load {flights extra} {
        set f $flights
        set row 0
        set has_rgb 0
        set has_cir 0
        set has_nir 0
        foreach flight [::mission::get] {
            incr row
            ttk::label $f.lbl$row -text $flight
            ttk::button $f.load$row -text "Load" -width 0 -command \
                    [list exp_send "mission, load, \"[ystr $flight]\";\r"]
            ttk::button $f.rgb$row -text "RGB" -width 0 \
                    -command [list ::mission::eaarl::load_rgb $flight]
            ttk::button $f.cir$row -text "CIR" -width 0 \
                    -command [list ::mission::eaarl::load_cir $flight]
            ttk::button $f.nir$row -text "NIR" -width 0 \
                    -command [list ::mission::eaarl::load_nir $flight]
            grid $f.lbl$row $f.load$row $f.rgb$row $f.cir$row $f.nir$row -padx 2 -pady 2
            grid $f.lbl$row -sticky w
            grid $f.load$row $f.rgb$row $f.cir$row $f.nir$row -sticky ew

            if {
                [::mission::has $flight "rgb dir"] ||
                [::mission::has $flight "rgb file"]
            } {
                set has_rgb 1
            } else {
                $f.rgb$row state disabled
            }

            foreach type {cir nir} {
                if {[::mission::has $flight "$type dir"]} {
                    set has_$type 1
                } else {
                    $f.$type$row state disabled
                }
            }
        }

        set f $extra
        ttk::button $f.btnRGB -text "All RGB" -width 0 \
                -command ::mission::eaarl::menu_load_rgb
        ttk::button $f.btnCIR -text "All CIR" -width 0 \
                -command ::mission::eaarl::menu_load_cir
        ttk::button $f.btnNIR -text "All NIR" -width 0 \
                -command ::mission::eaarl::menu_load_nir
        grid x $f.btnRGB $f.btnCIR $f.btnNIR -sticky ew -padx 2 -pady 2
        grid columnconfigure $f {0 4} -weight 1

        if {!$has_rgb} {$f.btnRGB state disabled}
        if {!$has_cir} {$f.btnCIR state disabled}
        if {!$has_nir} {$f.btnNIR state disabled}
    }
    set ::mission::commands(refresh_load) ::mission::eaarl::refresh_load

    proc load_rgb {flight} {
        if {[::mission::has $flight "rgb dir"]} {
            set path [::mission::get $flight "rgb dir"]
            if {[::mission::get $flight "date"] < "2011"} {
                set driver rgb::f2006::tarpath
            } elseif {[file tail $path] eq "cam1"} {
                set driver rgb::f2006::tarpath
            } else {
                set driver cir::f2010::tarpath
            }
            set rgb [sf::controller %AUTO%]
            $rgb load $driver -path $path
            ybkg set_sf_bookmark \"$rgb\" \"[ystr $flight]\"
        } elseif {[::mission::has $flight "rgb file"]} {
            set rgb [sf::controller %AUTO%]
            $rgb load rgb::f2001::tarfiles \
                    -files [list [::mission::get $flight "rgb file"]]
            ybkg set_sf_bookmark \"$rgb\" \"[ystr $flight]\"
        }
    }

    proc load_cir {flight} {
        if {[::mission::has $flight "cir dir"]} {
            set path [::mission::get $flight "cir dir"]
            if {[::mission::get $flight "date"] < "2012"} {
                set driver cir::f2004::tarpath
            } else {
                set driver cir::f2010::tarpath
            }
            set cir [sf::controller %AUTO%]
            $cir load $driver -path $path
            ybkg set_sf_bookmark \"$cir\" \"[ystr $flight]\"
        }
    }

    proc load_nir {flight} {
        if {[::mission::has $flight "nir dir"]} {
            set path [::mission::get $flight "nir dir"]
            set driver cir::f2010::tarpath
            set nir [sf::controller %AUTO%]
            $nir load $driver -path $path
            ybkg set_sf_bookmark \"$nir\" \"[ystr $flight]\"
        }
    }

    proc menu_load_rgb {} {
        set paths [list]
        set date ""
        foreach flight [::mission::get] {
            if {[::mission::has $flight "rgb dir"]} {
                lappend paths [::mission::get $flight "rgb dir"]
                set date [::mission::get $flight "date"]
            }
        }
        if {[llength $paths]} {
            if {$date < "2011"} {
                set driver rgb::f2006::tarpaths
            } elseif {[file tail [lindex $paths 0]] eq "cam1"} {
                set driver rgb::f2006::tarpaths
            } else {
                set driver cir::f2010::tarpaths
            }
            set rgb [sf::controller %AUTO%]
            $rgb load $driver -paths $paths
            ybkg set_sf_bookmarks \"$rgb\"
            return
        }

        set paths [list]
        foreach flight [::mission::get] {
            if {[::mission::has $flight "rgb file"]} {
                lappend paths [::mission::get $flight "rgb file"]
            }
        }
        if {[llength $paths]} {
            set rgb [sf::controller %AUTO%]
            $rgb load rgb::f2001::tarfiles -files $paths
            ybkg set_sf_bookmarks \"$rgb\"
        }
    }

    proc menu_load_cir {} {
        set paths [list]
        set date ""
        foreach flight [::mission::get] {
            if {[::mission::has $flight "cir dir"]} {
                lappend paths [::mission::get $flight "cir dir"]
                set date [::mission::get $flight "date"]
            }
        }
        if {[llength $paths]} {
            if {$date < "2012"} {
                set driver cir::f2004::tarpaths
            } else {
                set driver cir::f2010::tarpaths
            }
            set cir [sf::controller %AUTO%]
            $cir load $driver -paths $paths
            ybkg set_sf_bookmarks \"$cir\"
        }
    }

    proc menu_load_nir {} {
        set paths [list]
        foreach flight [::mission::get] {
            if {[::mission::has $flight "nir dir"]} {
                lappend paths [::mission::get $flight "nir dir"]
            }
        }
        if {[llength $paths]} {
            set nir [sf::controller %AUTO%]
            $nir load cir::f2010::tarpaths -paths $paths
            ybkg set_sf_bookmarks \"$nir\"
        }
    }

    proc menu_dump_rgb {} {
        set outdir [tk_chooseDirectory \
                -title "Select destination for RGB imagery" \
                -initialdir $::mission::path]
        if {$outdir ne ""} {
            dump_imagery "rgb dir" cir::f2010::tarpath $outdir \
                    -subdir photos/rgb
        }
    }

    proc menu_dump_nir {} {
        set outdir [tk_chooseDirectory \
                -title "Select destination for NIR imagery" \
                -initialdir $::mission::path]
        if {$outdir ne ""} {
            dump_imagery "nir dir" cir::f2010::tarpath $outdir \
                    -subdir photos/nir
        }
    }

    proc dump_imagery {type driver dest args} {
        set subdir photos
        if {[dict exists $args -subdir]} {
            set subdir [dict get $args -subdir]
        }
        foreach flight [::mission::get] {
            if {[::mission::has $flight $type]} {
                set path [::mission::get $flight $type]
                set model [::sf::model::create::$driver -path $path]
                set rel [::fileutil::relative $::mission::path \
                        [::mission::get $flight "data_path dir"]]
                set dest [file join $dest $rel $subdir]
                if {[::sf::tools::dump_model_images $model $dest]} {
                    return
                }
            }
        }
    }
}