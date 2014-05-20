// vim: set ts=2 sts=2 sw=2 ai sr et:
/*
History:
   9/20/02  -ww Fixed problem where data_path was being overwritten
         when the pnav file was not located in "gps".
   1/21/02  Added automatic correction for gps time.
  11/17/01  Added raeggnav function to read precision gps
         data files generated by John Sonntag and Chreston.
  11/13/01  Modified to check/correct midnight rollover. -WW

  This program reads a binary file of precision GPS data generated by
  the pnav2ybin.c program.  The input data file begines with a single
  32 bit integer which contains the number of pnav sample points following
  it in the file.  The points which follow are binary values in the
  following structure:

 struct PNAV {
  short sv;
  short flag;
  float sod;
  float pdop;
  float alt;
  float xrms;
  float veast;
  float vnorth;
  float vup;
  double lat;
  double lon;
};


*/

struct PNAV {
  short sv;
  short flag;
  float sod;
  float pdop;
  //float hdop;		// egg data only
  float alt;
  float xrms;
  float veast;
  float vnorth;
  float vup;
  double lat;
  double lon;
};

struct EGGNAV {
  short yr;
  short day;
  float sod;
  double lat;
  double lon;
  float alt;
  float pdop;
  float hdop;
}

func raeggnav (junk) {
/* DOCUMENT raeggnav
  Read ASCII EGG precision navigation file.  This reads nav trajectories
  produced by John Sonntag or Chreston Martin.

  The data are returned as an array of structures of the form:

  struct EGGNAV {
    short yr;
    short day;
    float sod;
    double lat;
    double lon;
    float alt;
    float pdop;
    float hdop;
  }
*/
  extern data_path;
  if (is_void(data_path)) {
    data_path = rdline(prompt="Enter data path:");
  }

  path = data_path +"/gps/";
  ifn = select_file(path, pattern="\\.egg$");

  n = int(0);
  idf = open(ifn);

  // an array big enough to hold 24 hours at 10hz (76mb)
  // ncol = 11;
  ncol = 14;
  tmp = array( double, ncol, 864000);
  write,"Reading.........";
  s = rdline(idf);
  n = read(idf,format="%f", tmp) / ncol;
  egg = array( EGGNAV, n);
  egg.yr  = tmp(1,:n);
  egg.day = tmp(2,:n);
  egg.sod = tmp(3,:n);
  egg.lat = tmp(4,:n);
  egg.lon = tmp(5,:n) - 360.0;
  egg.alt = tmp(6,:n);
  egg.pdop = tmp(7,:n);
  egg.hdop = tmp(8,:n);
  write,format="\n\n    File:%s\n", ifn;
  write,format="Contains:%d points\n", dimsof(egg)(2);
  write,format="%s", "               Min          Max\n";
  write, format="  SOD:%14.3f %14.3f %6.2f hrs\n", egg.sod(min), egg.sod(max),
    (egg.sod(max) -egg.sod(min))/ 3600.0;
  write, format=" Pdop:%14.3f %14.3f\n", egg.pdop(min), egg.pdop(max);
  write, format="  Lat:%14.3f %14.3f\n", egg.lat(min), egg.lat(max);
  write, format="  Lon:%14.3f %14.3f\n", egg.lon(min), egg.lon(max);
  write, format="  Alt:%14.3f %14.3f\n", egg.alt(min), egg.alt(max);

  close,idf;
  return egg;
}

func precision_warning(verbose) {
  extern silence_precision_warning;
  default, verbose, 1;
  if(!silence_precision_warning && verbose && _ytk) {
    tkcmd, "tk_messageBox -icon warning -message { \
      The pnav file you have selected does not appear to be a precision \
      trajectory.  It should not be used in the production of final data \
      products or to assess accuracy of the system. \
    }";
  }
}


/* Per Nagle's suggestion, changed rbpnav() to load_pnav(), but without
 * the setting of gga.  Create a new rbpnav() that calls this, but then
 * sets gga, thus keeping the old functionality of rbpnav(), but adding
 * the ability to load a pnav without messing with gga.  2008-11-05 rwm
 */
func load_pnav(junk, fn=, verbose=) {
/* DOCUMENT load_pnav(fn=)
  This function read a "C" precision data file generated by
  B.J.'s Ashtech program(s).  The data are usually not produced
  with precision trajectories.  The file must already be in
  ybin format produced by the pnav2ybin.c program.
*/
  extern pnav_filename; // so we can show which trajectory was used
  extern data_path, gps_time_correction, edb, soe_day_start;
  default, verbose, 1;
  if(!is_void(fn)) {
    pnav_filename = fn;
  } else {
    if(batch())
      error, "fn= not specified";

    if(is_void(data_path) || data_path == "") {
      data_path = rdline(prompt="Enter data path:");
    }
    path = data_path;

    if(_ytk) {
      path = data_path + "/trajectories/";
      ifn = get_openfn(initialdir=path, filetype="*pnav.ybin");
      if (strmatch(ifn, "ybin") == 0) {
        exit, "NO FILE CHOSEN, PLEASE TRY AGAIN\r";
      }
      path = file_dirname(file_dirname(ifn));
    } else {
      write, format="data_path=%s\n", path;
      ifn = select_file(path, pattern="\\.ybin$");
    }
    pnav_filename = ifn;
  }
  if(!strmatch(pnav_filename,"-p-")) {
    precision_warning, verbose;
  }

  n = int(0);
  idf = open(pnav_filename, "rb");
  i86_primitives, idf;
  add_member, idf, "PNAV", -1, "sv", short;
  add_member, idf, "PNAV", -1, "flag", short;
  add_member, idf, "PNAV", -1, "sod", float;
  add_member, idf, "PNAV", -1, "pdop", float;
  add_member, idf, "PNAV", -1, "alt", float;
  add_member, idf, "PNAV", -1, "xrms", float;
  add_member, idf, "PNAV", -1, "veast", float;
  add_member, idf, "PNAV", -1, "vnorth", float;
  add_member, idf, "PNAV", -1, "vup", float;
  add_member, idf, "PNAV", -1, "lat", double;
  add_member, idf, "PNAV", -1, "lon", double;
  install_struct, idf, "PNAV";

  // get the integer number of records
  _read, idf,  0, n;

  ///  pnav = array( double, 12, n);
  pn   = array( PNAV, n);
  _read, idf, 4, pn;

  // check for time roll-over, and correct it
  q = where(pn.sod(dif) < 0);
  if(numberof(q)) {
    rng = q(1)+1:dimsof(pn.sod)(2);
    pn.sod(rng) += 86400;
    // correct soe_day_start if the tlds dont start until after midnight. -rwm
    if(!is_void(edb) && !is_void(soe_day_start)) {
      if((edb.seconds(0) - soe_day_start(1)) < pn.sod(1)) {
        soe_day_start -= 86400;
        write, format="Correcting soe_day_start to %d\n", soe_day_start;
      }
    }
  }

  if(is_void(gps_time_correction))
    determine_gps_time_correction, pnav_filename;
  pn.sod += gps_time_correction;

  if(verbose) {
    write,format="Applied GPS time correction of %f\n", gps_time_correction;
    write,format="%s", "               Min          Max\n";
    write, format="  SOW:%14.3f %14.3f %6.2f hrs\n", pn.sod(min), pn.sod(max),
      (pn.sod(max)-pn.sod(min))/ 3600.0;
    write, format=" Pdop:%14.3f %14.3f\n", pn.pdop(min), pn.pdop(max);
    write, format="  Lat:%14.3f %14.3f\n", pn.lat(min), pn.lat(max);
    write, format="  Lon:%14.3f %14.3f\n", pn.lon(min), pn.lon(max);
    write, format="  Alt:%14.3f %14.3f\n", pn.alt(min), pn.alt(max);
    write, format="  Rms:%14.3f %14.3f\n", pn.xrms(min), pn.xrms(max);
  }
  return pn;
}

func rbpnav (junk, fn=, verbose=) {
  extern gga;
  pn = load_pnav(junk, fn=fn, verbose=verbose);
  gga = pn;
  return pn;
}

func load_pnav2FS(junk, ifn=) {
  extern gt_pnav, pnav_filename;

  gt_pnav = load_pnav(junk, fn=ifn);

  if(is_void(ifn)) {
    ifn = pnav_filename;
  }

  myfn = file_tail(ifn);     // get the actual filename

  yr = atoi(strpart(myfn, 1:4));   // strip out the date
  mo = atoi(strpart(myfn, 6:7));
  dy = atoi(strpart(myfn, 9:10));

  soe = ymd2soe(yr, mo, dy, gt_pnav.sod);
  // soe = gt_pnav.sod;
  fs = pnav2fs(gt_pnav, soe=soe);

  return fs;
}

func pnav2fs(pn, soe=) {
/* DOCUMENT pnav2fs(pn, soe=)
  Converts data in PNAV format to FS format. If provided, SOE is used for
  timestamps instead of PN.SOD.
*/
  extern curzone;
  local x, y;
  if(!curzone) {
    write, "Please define curzone. Aborting.";
    return;
  }
  default, soe, pn.sod;
  ll2utm, pn.lat, pn.lon, y, x, force_zone=curzone;
  fs = array(FS, dimsof(pn));
  fs.east = x * 100;
  fs.north = y * 100;
  fs.elevation = pn.alt * 100;
  fs.soe = soe;
  return fs;
}

func fs2pnav(fs) {
/* DOCUMENT fs2pnav(fs)
  Converts data in FS format to PNAV format.
*/
  extern curzone;
  local x, y;
  if(!curzone) {
    write, "Please define curzone. Aborting.";
    return;
  }
  pn = array(PNAV, dimsof(fs));
  utm2ll, fs.north/100., fs.east/100., curzone, x, y;
  pn.lon = x;
  pn.lat = y;
  pn.alt = fs.elevation/100.;
  minsod = pn.sod(min);
  offset = minsod - (minsod % 86400);
  pn.sod = fs.soe - offset;
  return pn;
}

func pnav_diff_alt(pn1, pn2, xfma=, swin=, woff=, title=) {
/* DOCUMENT pnav_diff_alt(pn1, pn2)
   Given two trajectories produced for the same flight,
   compute the altitude difference for each identical point
   in time.

   -xfma=[0|1]
   -swin=N : specify the starting window number for each plot.
             This function only produces one plot window, but this keeps
             it consistent with the other pnav_diff_ functions that generate
             multiple plot windows.
   -woff=N : [0-3] added to swin when comparing more than one pair
             of trajectories.
   -title="TITLE"
*/
  default, swin, 20;
  default, iwin, 4;
  default, woff, 0;

  window, swin+woff;   // Plot track in UTM
  if(xfma) fma;

  w1 = set_intersection(pn1.sod, pn2.sod, idx=1);
  w2 = set_intersection(pn2.sod, pn1.sod, idx=1);
  pn1=pn1(w1);
  pn2=pn2(w2);
  // allof(pn1.sod == pn2.sod);

  pn1.alt = pn1.alt - pn2.alt;


  legend_add, "red", "delta Altitude";
  legend_show;
  plg, pn1.alt, pn1.sod, color="red";
  xytitles, "Seconds of day", "Meters", [-0.005, -0.01];

  grow, title, "Trajectory Altitude Difference";
  title = strjoin( title, "\n");
  pltitle, title;

  return pn1;
}

func pnav_diff_latlon(pn1, pn2, plot=, xfma=, swin=, woff=, title=) {
/* DOCUMENT pnav_diff_latlon(pn1, pn2)
   Given two trajectories produced for the same flight,
   compute the lat/lon positional difference for each identical point
   in time.

   -xfma=[0|1]
   -swin=N : specify the starting window number for each plot.
             This function produces 4 plot windows.
   -woff=N : [0-3] added to swin when comparing more than one pair
             of trajectories.
   -title="TITLE"

   4 plots are generated.
   Plot 1 shows the differences between lat and lon individually.
   Plot 2 is the same as plot 1, but computed using UTM values.
   Plot 3 is the delta range vs seconds-of-day.
   Plot 4 shows a histogram of the delta values.
 */
  extern u1, u2, ur, p1, p2;
  w1 = set_intersection(pn1.sod, pn2.sod, idx=1);
  w2 = set_intersection(pn2.sod, pn1.sod, idx=1);
  pn1=pn1(w1);
  pn2=pn2(w2);
  // info, pn1; info, pn2;
  // allof(pn1.sod == pn2.sod);

  default, swin, 30;
  default, iwin, 4;
  default, woff, 0;

  llr = lldist(pn1.lat, pn1.lon, pn2.lat, pn2.lon);
  llr *= 1852.0;

// llsr = slldist(pn1.lat, pn1.lon, pn2.lat, pn2.lon);
// llsr *= 1852.0;

// now do it again using utm
  u1 = ll2utm(pn1.lat, pn1.lon);
  u2 = ll2utm(pn2.lat, pn2.lon);

  window, swin+woff; swin += iwin;    // Plot track in UTM
  if(xfma) fma;
  // plmk(u1(1,), u1(2,), color="blue");
  // plmk(u2(1,), u2(2,), color="red" );

  legend_add, "green", "lat";
  legend_add, "cyan",  "lon";
  plmk, ((pn1.lat - pn2.lat) * 111120), pn1.sod, color="green";
  plmk, ((pn1.lon - pn2.lon) * 111120), pn1.sod, color="cyan";

  ttitle = title;
  grow, ttitle, "Delta Lat / Delta Lon";
  ttitle = strjoin( ttitle, "\n");
  pltitle, ttitle;

  legend_show;

  // ur = pow((u2(1,)-u1(1,)),2.0) + pow((u2(2,)-u1(2,)),2.0);
  // info, u1; info, u2;
  // u2(1,7000:7005); u1(1,7000:7005);
  t1 = u2(1,) - u1(1,);
  t2 = u2(2,) - u1(2,);
  window, swin+woff; swin += iwin;    // Plot delta UTM lat / lon
  if(xfma) fma;
  legend_add, "red",    "EAST";       // XYZZY - which is which??
  legend_add, "green", "NORTH";
  plmk, t1, pn1.sod, color="red";
  plmk, t2, pn1.sod, color="green";
  legend_show;
  t1 = t1^2;
  t2 = t2^2;
  ur = (t1+t2) ^ .5;
  ttitle = title;
  grow, ttitle, "UTM differences";
  ttitle = strjoin( ttitle, "\n");
  pltitle, ttitle;


  window, swin+woff; swin += iwin;
  if(xfma) fma;
  legend_add, "red", "latlon range";
  plmk, llr, pn1.sod, color="red";
  // plmk, llsr, pn1.sod, color="cyan";
  legend_add, "blue", "utm range";
  plmk, ur,  pn1.sod, color="blue";
  legend_show;
  xytitles, "Seconds of day", "Meters", [-0.005, -0.01];

  ttitle = title;
  grow, ttitle, "Trajectory Horizontal Difference";
  ttitle = strjoin( ttitle, "\n");
  pltitle, ttitle;

  hist_data_plot, llr, win=46+woff,
    title="Delta Range Histogram",
    xtitle="Range",
    ytitle="Counts",
    dofma=1,
    binsize=.001;

  return llr;
}


func pnav_diff_base_latlon(pn1, pn2, lat, lon, plot=, xfma=, swin=, iwin=, woff=) {
/* DOCUMENT pnav_diff_base_latlon(pn1, pn2, lat, lon)
   Given two trajectories produced for the same flight and the lat/lon values
   for the base station, compute the lat/lon positional difference for each
   identical point in time and then plots that value relative to the range
   from the base station.

   -xfma=[0|1]
   -swin=N : specify the starting window number for each plot.
             This function produces 4 plot windows.
   -woff=N : [0-3] added to swin when comparing more than one pair
             of trajectories.
   -title="TITLE"
*/
  extern u1, u2, ur, p1, p2;

  w1 = set_intersection(pn1.sod, pn2.sod, idx=1);
  w2 = set_intersection(pn2.sod, pn1.sod, idx=1);
  pn1=pn1(w1);
  pn2=pn2(w2);

  // allof(pn1.sod == pn2.sod);

  p1 = pn1;
  p2 = pn2;

  default, swin, 50;
  default, iwin, 4;
  default, woff, 0;

  // lat/lon range  or delta ll
  llr = lldist(pn1.lat, pn1.lon, pn2.lat, pn2.lon);
  llr *= 1852.0;

  // lat/base range
  lbr = lldist(pn1.lat, pn1.lon, lat, lon);
  lbr *= 1.8520;

  // delta altitude
  pn1.alt = pn1.alt - pn2.alt;

  // Plot delta position from base in meters
  // window, swin+woff; swin += iwin; fma;
  // xytitles, "Seconds of day", "Meters", [-0.005, -0.01];
  // pltitle, "delta lat and lon from Base";
  //
  // plmk( ((pn1.lat - lat) * 111120), pn1.sod, color="green");
  // plmk( ((pn1.lon - lon) * 111120), pn1.sod, color="cyan");

  window, swin+woff, style="work2.gs"; swin += iwin;
  if(xfma) fma;

  plsys,1;
  legend_add, "blue", "Pdop";
  legend_add, "red",  "altitude";
  plmk, pn1.pdop, pn1.sod, color="blue";
  plsys,2;
  plg, pn1.alt, pn1.sod, color="red";
  legend_show;
  xytitles, "Seconds of day", "Meters", [ 0.505, -0.01];

  ttitle = title;
  grow, ttitle, "Trajectory Altitude Difference";
  ttitle = strjoin( ttitle, "\n");
  pltitle, ttitle;

  window, swin+woff, style="work2.gs"; swin += iwin;
  if(xfma) fma;

  legend_add, "blue", "Pdop";
  legend_add, "red", "Range";
  legend_show;

  // plg, pn1.alt, lbr, color="red";
  plsys,1;
  plmk, pn1.pdop, lbr, color="blue";
  plsys,2;
  plmk, pn1.alt, lbr, color="red";
  // plmk, llsr, pn1.sod, color="cyan";
  xytitles, "Range from Base(km)", "Meters", [0.505, -0.01];

  ttitle = title;
  grow, ttitle, "Trajectory Range Difference";
  ttitle = strjoin( ttitle, "\n");
  pltitle, ttitle;

  return llr;
}
