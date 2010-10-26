# vim: set ts=3 sts=3 sw=3 ai sr et:

package provide l1pro::main::menu 1.0

namespace eval ::l1pro::main::menu {

proc menulabel txt {
   lassign [::tk::UnderlineAmpersand $txt] label pos
   if {$pos == -1} {
      return [list -label $label]
   } else {
      return [list -label $label -underline $pos]
   }
}

proc get_top w {
   set w [winfo toplevel $w]
   while {[winfo class $w] eq "Menu"} {
      set w [winfo parent $w]
   }
   return $w
}

proc build mb {
   menu $mb
   $mb add cascade {*}[menulabel &File] \
      -menu [menu_file $mb.file]
   $mb add cascade {*}[menulabel &Mission] \
      -menu [menu_mission $mb.mission]
   $mb add cascade {*}[menulabel &Graph] \
      -menu [menu_graph $mb.graph]
   $mb add cascade {*}[menulabel &Utilities] \
      -menu [menu_utilities $mb.util]
   $mb add cascade {*}[menulabel &CmdLine] \
      -menu [menu_cmdline $mb.cmd]
   $mb add cascade {*}[menulabel &Ytk] \
      -menu [menu_ytk $mb.ytk]
   $mb add cascade {*}[menulabel &Deprecated] \
      -menu [menu_deprecated $mb.dep]
   return $mb
}

proc menu_file mb {
   menu $mb
   $mb add command {*}[menulabel "&Load ALPS data..."] \
      -command ::l1pro::file::load_pbd
   $mb add command {*}[menulabel "&Save ALPS data..."] \
      -command ::l1pro::file::save_pbd
   $mb add separator
   $mb add command {*}[menulabel "L&oad ALPS data as..."] \
      -command ::l1pro::file::load_pbd_as
   $mb add command {*}[menulabel "Load ALPS data &directory..."] \
      -command ::l1pro::dirload
   $mb add command {*}[menulabel "Save ALPS data &as..."] \
      -command ::l1pro::file::save_pbd_as
   $mb add separator
   $mb add command {*}[menulabel "&Import ASPRS LAS..."] \
      -command ::l1pro::file::load_las
   $mb add command {*}[menulabel "I&mport ASCII..."] \
      -command ::l1pro::ascii::launch
   $mb add command {*}[menulabel "E&xport ASCII..."] \
      -command ::l1pro::file::export_ascii
   $mb add separator
   $mb add cascade {*}[menulabel "&Variables..."] \
      -menu [menu_file_variables $mb.vars]
   $mb add command {*}[menulabel "&Capture a display..."] \
      -command scap
   $mb add separator
   $mb add command {*}[menulabel "&Dismiss"] \
      -command [list wm withdraw [get_top $mb]]
   return $mb
}

proc menu_file_variables mb {
   menu $mb
   $mb add command {*}[menulabel "&Load from file..."] \
      -command ::l1pro::vars::load_from_file
   $mb add command {*}[menulabel "&Save to file..."] \
      -command ::l1pro::vars::save_to_file
   return $mb
}

proc menu_mission mb {
   menu $mb
   $mb add command {*}[menulabel "&Mission configuration manager"] \
      -command ::mission::launch_gui
   $mb add command {*}[menulabel "&Plotting tool"] \
      -command ::plot::menu
   $mb add separator
   $mb add cascade {*}[menulabel "&Load mission data"] \
      -menu [menu_mission_load $mb.load]
   $mb add cascade {*}[menulabel "&Settings"] \
      -menu [menu_mission_settings $mb.settings]
   $mb add separator
   $mb add command {*}[menulabel "&EDB Status"] \
      -command edb_status
   $mb add command {*}[menulabel "Launch new SF &viewer..."] \
      -command [list ::sf::controller %AUTO%]
   $mb add separator
   $mb add command {*}[menulabel "Load &Ground PNAV (gt_pnav) data..."] \
      -command load_ground_pnav
   $mb add command {*}[menulabel "Load Ground PNAV2&FS (gt_fs) data..."] \
      -command load_ground_pnav2fs
   return $mb
}

proc menu_mission_load mb {
   menu $mb
   $mb add command {*}[menulabel "&EDB Data..."] \
      -command load_edb
   $mb add command {*}[menulabel "&TANS Data..."] \
      -command {exp_send "tans = rbtans();\r"}
   $mb add command {*}[menulabel "&DMARS PBD Data..."] \
      -command load_dmars
   $mb add command {*}[menulabel "&PNAV Data..."] \
      -command {exp_send "pnav = rbpnav();\r"}
   $mb add command {*}[menulabel "&Bathymetry Settings..."] \
      -command bathctl::gui
   return $mb
}

proc menu_mission_settings mb {
   menu $mb
   $mb add command {*}[menulabel "&Load ops_conf..."] \
      -command load_ops_conf
   $mb add command {*}[menulabel "&Configure ops_conf..."] \
      -command ::l1pro::settings::ops_conf::gui
   $mb add command {*}[menulabel "&Save ops_conf..."] \
      -command ::l1pro::settings::ops_conf::save
   $mb add cascade {*}[menulabel "&Display..."] \
      -menu [menu_mission_settings_ops $mb.ops]
   $mb add separator
   $mb add command {*}[menulabel "&Bathymetry Settings..."] \
      -command bathctl::gui
   return $mb
}

proc menu_mission_settings_ops mb {
   menu $mb
   $mb add command {*}[menulabel "&Current"] \
      -command {exp_send "display_mission_constants, ops_conf, ytk=1;\r"}
   $mb add command {*}[menulabel "&TANS default"] \
      -command {exp_send "display_mission_constants, ops_tans, ytk=1;\r"}
   $mb add command {*}[menulabel "&DMARS default"] \
      -command {exp_send "display_mission_constants, ops_IMU2, ytk=1;\r"}
   $mb add command {*}[menulabel "&Applanix 510 default"] \
      -command {exp_send "display_mission_constants, ops_IMU1, ytk=1;\r"}
   return $mb
}

proc menu_graph mb {
   menu $mb
   $mb add command {*}[menulabel "&Limits Tool"] \
      -command ::l1pro::tools::copy_limits::gui
   $mb add separator
   $mb add command \
      {*}[menulabel "Change current window to 75 DPI / 450x450"] \
      -command [list exp_send "change_window_style, \"work\";\r"]
   $mb add command \
      {*}[menulabel "Change current window to 100 DPI / 600x600"] \
      -command [list exp_send "change_window_style, \"work\", dpi=100;\r"]
   $mb add command \
      {*}[menulabel "Change current window to 75 DPI / 825x638"] \
      -command [list exp_send "change_window_style, \"landscape11x85\";\r"]
   $mb add command \
      {*}[menulabel "Change current window to 100 DPI / 1100x850"] \
      -command [list exp_send "change_window_style, \"landscape11x85\", dpi=100;\r"]
   $mb add separator
   $mb add cascade {*}[menulabel Palette...] \
      -menu [menu_graph_palette $mb.pal]
   $mb add cascade {*}[menulabel Style...] \
      -menu [menu_graph_style $mb.sty]
   $mb add cascade {*}[menulabel "&Grid lines..."] \
      -menu [menu_graph_grid $mb.grid]
   return $mb
}

proc menu_graph_palette mb {
   menu $mb
   foreach p [list earth altearth stern rainbow yarg heat gray] {
      $mb add command -label $p -underline 0 \
         -command [list set_yorick_palette $p]
   }
   return $mb
}

proc menu_graph_style mb {
   menu $mb
   $mb add radiobutton {*}[menulabel "&75 DPI"] \
      -variable yorick_style_dpi -value 75
   $mb add radiobutton {*}[menulabel "&100 DPI"] \
      -variable yorick_style_dpi -value 100
   $mb add separator
   foreach s [list axes boxed l_nobox nobox vgbox vg work landscape11x85] {
      $mb add command -label $s -underline 0 \
         -command [list set_yorick_style $s]
   }
   return $mb
}

proc menu_graph_grid mb {
   menu $mb
   set cmd [list list set_yorick_gridxy]
   $mb add command {*}[menulabel "None"] -command [{*}$cmd 0 0]
   $mb add separator
   $mb add command {*}[menulabel "X axis"] -command [{*}$cmd 1 0]
   $mb add command {*}[menulabel "Y axis"] -command [{*}$cmd 0 1]
   $mb add command {*}[menulabel "Both axes"] -command [{*}$cmd 1 1]
   $mb add separator
   $mb add command {*}[menulabel "X origin"] -command [{*}$cmd 2 0]
   $mb add command {*}[menulabel "Y origin"] -command [{*}$cmd 0 2]
   $mb add command {*}[menulabel "Both origins"] -command [{*}$cmd 2 2]
   return $mb
}

proc menu_utilities mb {
   menu $mb
   $mb add command {*}[menulabel "Pixel Analysis"] \
      -command [list ::pixelwf::gui::launch_full_panel .pixelwf]
   $mb add command {*}[menulabel "Histogram Elevations"] \
      -command ::l1pro::tools::histelev::gui
   $mb add command {*}[menulabel "Groundtruth Analysis"] \
      -command ::l1pro::groundtruth::gui
   $mb add separator
   $mb add command {*}[menulabel "Transect Tool"] \
      -command [list source [file join $::src_path transrch.ytk]]
   $mb add cascade {*}[menulabel "Launch segments by..."] \
      -menu [menu_utilities_segments $mb.seg]
   $mb add cascade {*}[menulabel "Launch statistics by..."] \
      -menu [menu_utilities_statistics $mb.stat]
   $mb add command {*}[menulabel "Browse &Rasters"] \
      -command ::l1pro::drast::gui
   $mb add separator
   $mb add command {*}[menulabel "&Determine Roll Bias"] \
      -command ::l1pro::tools::rollbias::gui
   $mb add command {*}[menulabel "Check and correct EDB time"] \
      -command ts_check
   $mb add separator
   $mb add command {*}[menulabel "Show &Flightlines with No Raster Data..."] \
      -command {exp_send "plot_no_raster_fltlines(gga, edb);\r"}
   $mb add command {*}[menulabel "S&how Flightlines with No TANS Data..."] \
      -command {exp_send "plot_no_tans_fltlines(tans, gga);\r"}

   return $mb
}

proc menu_utilities_segments mb {
   menu $mb
   $mb add command {*}[menulabel "Flightline"] \
      -command [list segment_data_launcher fltlines]
   $mb add command {*}[menulabel "Flightline and digitizer"] \
      -command [list segment_data_launcher fltlines_digitizer]
   $mb add command {*}[menulabel "Day"] \
      -command [list segment_data_launcher days]
   $mb add command {*}[menulabel "Day and digitizer"] \
      -command [list segment_data_launcher days_digitizer]
   $mb add command {*}[menulabel "Manual selection"] \
      -command select_data_segments
   return $mb
}

proc menu_utilities_statistics mb {
   menu $mb
   $mb add command {*}[menulabel "Flightline"] \
      -command [list segment_stat_launcher fltlines]
   $mb add command {*}[menulabel "Flightline and digitizer"] \
      -command [list segment_stat_launcher fltlines_digitizer]
   $mb add command {*}[menulabel "Day"] \
      -command [list segment_stat_launcher days]
   $mb add command {*}[menulabel "Day and digitizer"] \
      -command [list segment_stat_launcher days_digitizer]
   return $mb
}

proc menu_cmdline mb {
   menu $mb
   foreach ycmd {
      mtransect batch_process mbatch_process batch_merge_tiles new_batch_rcf
      batch_rcf batch_datum_convert batch_veg_lfpw batch_pbd2edf batch_pbd2las
      batch_las2pbd batch_qi2pbd batch_write_xyz batch_convert_ascii2pbd
      batch_tile idl_batch_grid
   } {
      $mb add command -label $ycmd -command [list exp_send "help, $ycmd;\r"]
   }
   return $mb
}

proc menu_ytk mb {
   menu $mb
   $mb add command {*}[menulabel "&Load a Yorick/Ytk program file..."] \
      -command select_ytk_fn
   $mb add separator
   $mb add command {*}[menulabel &Tkcon] \
      -command [list exec {*}[auto_execok tkcon] &]
   $mb add command {*}[menulabel Tk&cmd] \
      -command [list wm deiconify .tx]
   $mb add separator
   $mb add checkbutton {*}[menulabel "&Help goes in new window"] \
      -onvalue Yes -offvalue No -variable _ytk(separate_help_win)
   return $mb
}

proc menu_deprecated mb {
   menu $mb
   $mb add cascade {*}[menulabel Analysis] \
      -menu [menu_deprecated_analysis $mb.an]
   $mb add cascade {*}[menulabel "Import/Export"] \
      -menu [menu_deprecated_import $mb.ie]
   $mb add cascade {*}[menulabel "Visualization"] \
      -menu [menu_deprecated_visualization $mb.vz]
   $mb add cascade {*}[menulabel "Editing"] \
      -menu [menu_deprecated_editing $mb.ed]
   return $mb
}

proc menu_deprecated_analysis mb {
   menu $mb
   $mb add command {*}[menulabel "Examine Lidar Rasters..."] \
      -command [list source [file join $::src_path drast.ytk]]
   $mb add command {*}[menulabel "Open Fit Gaussian GUI"] \
      -command open_fit_gaussian_gui
   return $mb
}

proc menu_deprecated_import mb {
   menu $mb
   ### DEPRECATED 2010-01-03 ###
   # Following entries replaced by file-1.0.tm functionality.
   $mb add command {*}[menulabel "Read Binary Data file..."] \
      -command ::l1pro::deprecated::read_binary_data_file
   $mb add command {*}[menulabel "Write Binary Data File..."] \
      -command ::l1pro::deprecated::write_binary_data_file
   $mb add command {*}[menulabel "Read SubSampled Data File..."] \
      -command ::l1pro::deprecated::read_subsampled_data_file
   $mb add command {*}[menulabel "Ascii output ..."] \
      -command ::l1pro::deprecated::ascii_output
   $mb add separator
   $mb add command {*}[menulabel "Save Tile"] \
      -command ::l1pro::deprecated::savetile
   return $mb
}

proc menu_deprecated_visualization mb {
   menu $mb
   $mb add command {*}[menulabel "Open the Limits Tool"]\
      -command ::l1pro::deprecated::limits_tool

   $mb add command {*}[menulabel "Configure elevation scale limits..."] \
      -command ::l1pro::deprecated::configure_elevation_scale_limits

   $mb add command {*}[menulabel "Plot/Write Individual Flightlines..."] \
      -command ::l1pro::deprecated::plot_write_individual_flightlines

   $mb add separator

   ### Deprecated 2009-02-02
   $mb add command {*}[menulabel "Flight Tracks & Coastlines..."] \
      -command ::l1pro::deprecated::rbgga_menu

   ### Deprecated 2009-10-19
   $mb add command {*}[menulabel "1-Hz RGB Low-Res Images..."] \
      -command ::l1pro::deprecated::start_sf

   ### Deprecated 2009-10-19
   $mb add command {*}[menulabel "1-Hz CIR High-Res Images..."] \
      -command ::l1pro::deprecated::start_cir

   return $mb
}

proc menu_deprecated_editing mb {
   menu $mb
   $mb add command {*}[menulabel "Test and Clean"] \
      -command {exp_send "$::pro_var = test_and_clean($::pro_var);\r"}
   $mb add command {*}[menulabel "Append2Tile"] \
      -command ::l1pro::deprecated::append2tile
   $mb add command {*}[menulabel "Old RCF GUI"] \
      -command ::l1pro::deprecated::rcf_region
   return $mb
}

} ;# closes namespace eval ::l1pro::main::menu
