// vim: set ts=2 sts=2 sw=2 ai sr et:
// Place to collect all yorick .i files that eaarl needs.

if(is_void(__eaarl_includes_included__)) {
  __eaarl_includes_included__ = 1;

  // Configure doubles and floats so that northing values will render with two
  // decimal places interactively by default
  print_format, float="%.10g", double="%.10g";

  plmk_default, msize=.1;
  pldefault, marks=0;

  // roll is a yorick function but often gets overwritten, so copy it to yroll
  // so that it doesn't get lost
  if(is_void(yroll))
    yroll = roll;

  // merge is another yorick function that sometimes gets overwritten
  if(is_void(ymerge))
    ymerge = merge;

  // Built-in and plugin includes
  require, "copy_plot.i";
  require, "jpeg.i";
  require, "lmfit.i";
  require, "msort.i";
  require, "pnm.i";
  require, "poly.i";
  require, "rdcols.i";
  require, "string.i";
  require, "unsigned.i";
  require, "utils.i";
  require, "yeti.i";
  require, "yeti_regex.i";
  require, "yeti_yhdf.i";
  require, "ytk.i";
  require, "ytk_window.i";
  require, "zlib.i";

  // Patches for core / plugins
  require, "patches/2012-08-yutils.i";
  require, "patches/2012-09-funcset.i";

  // Replace built-in median with Yeti's median which is much faster
  if(is_void(ymedian))
    ymedian = median;
  median = quick_median;

  // ALPS requires
  // These must come first, since some other functions make use of them at the
  // top level
  require, "eaarl_constants.i";
  require, "eaarl_structs.i";
  require, "eaarl_data.i";
  require, "util_basic.i";
  require, "general.i";
  require, "util_obj.i";
  require, "util_progress.i";

  require, "ascii.i";
  require, "ascii_encode.i";
  require, "asciixyz.i";
  require, "batch_process.i";
  require, "centroid.i";
  require, "class_clsobj.i";
  require, "class_deque.i";
  require, "class_mapobj.i";
  require, "class_pcobj.i";
  require, "class_wfobj.i";
  require, "colorbar.i";
  require, "compare_transects.i";
  require, "comparison_fns.i";
  require, "cs.i";
  require, "cs_geotiff.i";
  require, "data_rgn_selector.i";
  require, "data_segments.i";
  require, "datum_converter.i";
  require, "dir.i";
  require, "dirload.i";
  require, "dmars.i";
  require, "edf.i";
  require, "flightlines.i";
  require, "fp.i";
  require, "geometry.i";
  require, "geotiff_tags.i";
  require, "gridding.i";
  require, "groundtruth.i";
  require, "histogram.i";
  require, "ircf.i";
  require, "jpeg_support.i";
  require, "json_decode.i";
  require, "json_encode.i";
  require, "kml.i";
  require, "kml_extents.i";
  require, "kml_flightlines.i";
  require, "kml_fp.i";
  require, "kml_jgw.i";
  require, "kml_lines.i";
  require, "kml_markup.i";
  require, "las.i";
  require, "las_filter.i";
  require, "lines.i";
  require, "ll2utm.i";
  require, "makeflow.i";
  require, "makeflow_eaarla.i";
  require, "makeflow_las.i";
  require, "makeflow_rcf.i";
  require, "manual_filter.i";
  require, "map.i";
  require, "mathop.i";
  require, "mission.i";
  require, "mosaic_tools.i";
  require, "mouse.i";
  require, "nad832navd88.i";
  require, "obj_show.i";
  require, "parse.i";
  require, "pcobj_export.i";
  require, "pcobj_import.i";
  require, "pip.i";
  require, "plugins.i";
  require, "rbgga.i";
  require, "rbpnav.i";
  require, "rbtans.i";
  require, "rcf.i";
  require, "read_yfile.i";
  require, "rlw.i";
  require, "seamless.i";
  require, "set.i";
  require, "sf.i";
  require, "shapefile.i";
  require, "statistics.i";
  require, "tiles.i";
  require, "transect.i";
  require, "transrch.i";
  require, "util_cast.i";
  require, "util_container.i";
  require, "util_coord.i";
  require, "util_plot.i";
  require, "util_str.i";
  require, "wf_analysis.i";
  require, "wf_filter.i";
  require, "wf_process.i";
  require, "wgs842nad83.i";
  require, "window.i";
  require, "ytime.i";
  require, "ytriangulate.i";
  require, "zone.i";

  // Must come last, because it depends on some of the above (it actually runs
  // something instead of only defining functions)
  require, "alpsrc.i";
  require, "geotiff_constants.i";

  // Invoke any autoloading needed for plugins.
  plugins_autoload;
}

// Functions for working with sf_a.tcl

if(is_void(last_somd)) last_somd = 0;

func send_sod_to_sf(somd) {
/* DOCUMENT send_sod_to_sf, somd
  Wrapper around the Tcl command send_sod_to_sf
*/
  extern last_somd, soe_day_start;
  tkcmd, swrite(format="send_sod_to_sf %d", somd);
  soe = int(soe_day_start + somd);
  tkcmd, swrite(format="::sf::mediator broadcast soe %d", soe);
  last_somd = somd;
}

func send_tans_to_sf(somd, pitch, roll, heading) {
/* DOCUMENT send_tans_to_sf, somd, pitch, roll, heading
  Wrapper around the Tcl command send_tans_to_sf
*/
  extern last_somd;
  tkcmd, swrite(format="send_tans_to_sf %d %f %f %f",
    somd, pitch, roll, heading);
  last_somd = somd;
}
