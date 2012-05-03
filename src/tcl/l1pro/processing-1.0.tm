# vim: set ts=4 sts=4 sw=4 ai sr et:

package provide l1pro::processing 1.0

namespace eval ::l1pro::processing {
    namespace import ::misc::appendif
    namespace import ::l1pro::file::prefix
}

proc ::l1pro::processing::define_region_box {} {
    exp_send "q = gga_win_sel(win=$::_map(window));\r"
}

proc ::l1pro::processing::define_region_poly {} {
    exp_send "q = gga_pip_sel(1, win=$::_map(window));\r"
}

proc ::l1pro::processing::define_region_rect {} {
    define_region_rect::gui [prefix]%AUTO%
}

namespace eval ::l1pro::processing::define_region_rect {
    namespace import ::l1pro::file::prefix
}
snit::widget ::l1pro::processing::define_region_rect::gui {
    hulltype toplevel
    delegate method * to hull
    delegate option * to hull

    variable x0 {}
    variable x1 {}
    variable y0 {}
    variable y1 {}

    constructor args {
        wm title $win "Define rectangular coordinates"
        wm resizable $win 1 0

        ttk::frame $win.f
        grid $win.f -sticky news
        grid columnconfigure $win 0 -weight 1
        grid rowconfigure $win 0 -weight 1

        set f $win.f

        ttk::label $f.xlbl -text "Longitude/Easting: "
        ttk::label $f.ylbl -text "Latitude/Northing: "
        ttk::label $f.boundslbl -text "Bounds (min/max)"
        foreach var {x0 x1 y0 y1} {
            ttk::entry $f.$var -width 15 -textvariable [myvar $var]
        }

        ttk::frame $f.btns
        ttk::button $f.ok -text "OK" -command [mymethod btn_ok]
        ttk::button $f.plot -text "Plot" -command [mymethod btn_plot]
        ttk::button $f.dismiss -text "Dismiss" -command [mymethod btn_dismiss]
        grid x $f.ok $f.plot $f.dismiss x -in $f.btns -padx 2 -pady 0
        grid columnconfigure $f.btns {0 4} -weight 1

        grid x $f.boundslbl - -padx 2 -pady 2
        grid $f.xlbl $f.x0 $f.x1 -padx 2 -pady 2
        grid $f.ylbl $f.y0 $f.y1 -padx 2 -pady 2
        grid $f.btns - - -pady 2
        grid configure $f.xlbl $f.ylbl -sticky e
        grid configure $f.x0 $f.x1 $f.y0 $f.y1 -sticky ew
        grid columnconfigure $f {1 2} -weight 1 -uniform 1

        $self configurelist $args
    }

    method btn_ok {} {
        lassign [lsort -real [list $x0 $x1]] xmin xmax
        lassign [lsort -real [list $y0 $y1]] ymin ymax
        set utm [expr {$xmin > 1000}]
        exp_send "utm = $utm;\
                q = gga_win_sel(win=$::_map(window),\
                        llarr=\[$xmin,$xmax,$ymin,$ymax\]);\r"
        destroy $self
    }

    method btn_dismiss {} {
        destroy $self
    }

    method btn_plot {} {
        lassign [lsort -real [list $x0 $x1]] xmin xmax
        lassign [lsort -real [list $y0 $y1]] ymin ymax
        exp_send "window, $::_map(window);\
                plg, \[$ymin,$ymax\](\[1,2,2,1,1\]),\
                        \[$xmin,$xmax\](\[1,1,2,2,1\]);\r"
    }
}

proc ::l1pro::processing::process {} {
    set ::pro_var $::pro_var_next

    set cmd ""
    switch -- $::processing_mode {
        fs {
            set cmd "$::pro_var = make_fs(latutm=1, q=q, ext_bad_att=1,\
                    usecentroid=$::usecentroid)"
        }
        bathy {
            set cmd "$::pro_var = make_bathy(latutm = 1, q = q,\
                    avg_surf=$::avg_surf)"
            }
        veg {
            set cmd "$::pro_var = make_veg(latutm=1, q=q, ext_bad_att=1,\
                    ext_bad_veg=1, use_centroid=$::usecentroid)"
        }
        cveg {
            set cmd "$::pro_var = make_veg(latutm=1, q=q,\
                    use_centroid=$::usecentroid, multi_peaks=1)"
        }
        dws {
            exp_send "require, \"waves.i\"; process_for_dws, q;\r"
        }
        default {
            error "Unknown processing mode: $::processing_mode"
        }
    }

    if {$cmd ne ""} {
        if {$::autoclean_after_process} {
            append cmd "; test_and_clean, $::pro_var"
        }
        exp_send "$cmd;\r"
    }
    append_varlist $::pro_var
}
