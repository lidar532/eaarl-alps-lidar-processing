// vim: set ts=2 sts=2 sw=2 ai sr et:

extern _transect_history;
/* DOCUMENT _transect_history

  A stack of recent transect lines generated by calls to "mtransect."
  These can be recalled repeatly with the transact command.

  For example, to recall the last mouse_transect with transect you would:

    transect( fs_all, _transect_history(,0), ..... )

  To recall the one before last, use:

    transect( fs_all, _transect_history(,-1), ..... )
*/

func mtransect(fs, iwin=, owin=, w=, connect=, recall=, color=, xfma=,
rcf_parms=, mode=, rtn=, show=, msize=, expect=, marker=) {
/* DOCUMENT mtransect(fs, iwin=, owin=, w=, connect=, recall=, color=, xfma=,
   rcf_parms=, mode=, rtn=, show=, msize=, expect=, marker=)

  Mouse selected transect. mtransect allows you to "drag out" a line within an
  ALPS topo display window and then create a new graph of all of the points
  near the line.

  To recall a transect line, call mtransect with the recall= parameter and set
  it to:
    0 for the most recent line
    -1 for the previous line
    -2 for the one before that, etc.

  Input:
  fs         :  Variable to process
  owin=      :  Desired Yorick output graph window.       Default is 3
  iwin=      :  Source window for transect.               Default is 5
  w=         :  Search distance from line in centimeters. Default is 150cm
  connect=   :  Set to 1 to connect the points.
  recall=    :  Used to recall a previously generated transact line.
  color=     :  The starting color 1:7, use negative to use only 1 color
  xfma=      :  Set to 1 to auto fma.
  mode=      :  Data mode:
          mode="fs"  first surface
          mode="be"  bare earth
          mode="ba"  bathy
  rtn=       :  Deprecated; use mode= instead. This is ignored if mode= is
    present. Select return type where:
          0  first return
          1  veg last return
          2  submerged topo
  show=      :  Set to 1 to plot the transect in window, win.
  rcf_parms= :  Filter output with [W, P], where
          W = filter width
          P = # points on either side to use as jury pool
  msize=     :  set msize value (same as plcm, etc.), default = .1
  marker=    :  set marker value (same as plcm, etc.), default = 1

  Examples:

  g = mtransect(fs_all, connect=1, rcf_parms=[1.0, 5], xfma=1)

    - use fs_all as data source
    - connect the dots in the output plot
    - rcf filter the output with a 1.0 meter filter width and use 5 points on
      either side of each point as the jury pool
    - auto fma
    - returns the index of the selected points in g
    - this example expects you to generate the line segment with the mouse

  g = mtransect(fs_all, connect=1, rcf_parms=[1.0, 5], xfma=1, recall=0)

  This example is the same as above, except:
  - the transect line is taken from the global transect_history array

  SEE ALSO: transect, _transect_history
*/
  extern _transect_history, transect_line;

  wbkp = current_window();

  default, w, 150;
  default, connect, 0;
  default, owin, 3;
  default, iwin, 5;
  default, msize, 0.1;
  default, xfma, 0;
  default, color, 2;  // start at red, not black

  if(is_void(mode)) {
    if(!is_void(rtn)) {
      if(logger(warn))
        logger, warn, "call to transect using deprecated option rtn=";
    } else {
      rtn = 0;
    }
    mode = ["fs","be","ba"](rtn+1);
  }

  window, owin;
  lmts = limits();
  window,iwin;
  if(is_void(recall)) {
    // get the line coords with the mouse and convert to cm
    transect_line = mouse(1, 2, "")(1:4)*100.0;
    l = transect_line;   // just to keep the equations short;
    if(show)
      plg, [l(2),l(4)]/100., [l(1),l(3)]/100., width=2.0, color="red";
    grow, _transect_history, [l]
  } else {
    if(numberof(_transect_history) == 0) {
      write, "No transect lines in _transect_history";
      window_select, wbkp;
      return;
    }
    if(recall > 0) recall = -recall;
    l = _transect_history(, recall);
  }

  glst = transect(fs, l, connect=connect, color=color, xfma=xfma,
    rcf_parms=rcf_parms, mode=mode, owin=owin, lw=w, msize=msize, marker=marker);
  // plot the actual points selected onto the input window
  if (show == 2 ) {
    data2xyz, unref(fs(glst)), x, y, z, mode=mode;
    window, iwin;
    plmk, unref(y), unref(x), msize=msize, marker=marker, color="black",
      width=10;
  }
  if(show == 3) {   // this only redraws the last transect selected.
    window, iwin;
    plg, [transect_line(2),transect_line(4)]/100.,
      [transect_line(1),transect_line(3)]/100., width=2.0, color="red";
  }
  window, owin;
  if(is_void(recall)) {
    limits;
  } else {
    limits, lmts(1),lmts(2), lmts(3), lmts(4);
  }
  if(!is_void(expect))
    write, format="%s\n", "END mtransect:";

  window_select, wbkp;
  return glst;
}

func transect(fs, l, lw=, connect=, xtime=, msize=, xfma=, owin=, color=,
rcf_parms=, mode=, rtn=, marker=) {
/* DOCUMENT transect(fs, l, lw=, connect=, xtime=, msize=, xfma=, owin=,
   color=, rcf_parms=, mode=, rtn=, marker=)

  Input:
  fs         :  Data where you drew the line
  l          :  Line (as given by mouse())
  lw=        :  Search distance either side of the line in centimeters
  xtime=     :  Set to 1 to plot against time (sod)
  xfma=      :  Set to 1 to clear screen
  owin=      :  Set output window
  color=     :  Select starting color, 1-7, use negative to use only 1 color
  rcf_parms= :  [fw,np]  RCF the data where:
            fw is the width of the filter
            np is the number of points on either side of the index
             to use as a jury.
  mode=      :  Data mode:
          mode="fs"  first surface
          mode="be"  bare earth
          mode="ba"  bathy
  rtn=       :  Deprecated; use mode= instead. This is ignored if mode= is
    present. Select return type where:
          0  first return
          1  veg last return
          2  submerged topo
  msize      :  set msize value (same as plcm, etc.), default = .1
  marker     :  set marker value (same as plcm, etc.), default = 1

  SEE ALSO: mtransact, _transect_history
*/
  extern rx, elevation, glst, llst, segs;

  wbkp = current_window();

  default, rtn, 0;    // first return
  default, lw, 150;   // search width, cm
  default, color, 1;  // 1 is first color
  default, owin, 3;
  default, msize, 0.1;
  default, marker, 1;

  if(is_void(mode)) {
    if(!is_void(rtn)) {
      if(logger(warn))
        logger, warn, "call to transect using deprecated option rtn=";
    } else {
      rtn = 0;
    }
    mode = ["fs","be","ba"](rtn+1);
  }

  window, wait=1;
  window, owin;
  if(xfma) fma;

  // determine the bounding box n,s,e,w coords
  n = l(2:4:2)(max);
  s = l(2:4:2)(min);
  w = l(1:3:2)(min);
  e = l(1:3:2)(max);

  // compute the rotation angle needed to make the selected line
  // run east west
  dnom = l(1)-l(3);
  if(dnom != 0.0)
    angle = atan((l(2)-l(4)) / dnom) ;
  else angle = pi/2.0;
  //  angle ;
  //  [n,s,e,w]

  // clean and sort fs
  fs = test_and_clean(fs);
  // sort by soe only if soe values are not the same. This is necessary because
  // some times a data set is brought in that does not have any soe value
  if(is_array(where(fs.soe(dif))))
    fs = fs(sort(fs.soe))

  // build a matrix to select only the data withing the bounding box

  glst = data_box(fs.east, fs.north, w, e, s, n);
  // rotation:  x' = xcos - ysin
  //            y' = ycos + xsin

  // Steps:
  //    1 translate data and line to 0,0
  //    2 rotate data and line
  //    3 select desired data

  if(numberof(glst) == 0) {
    write, "No points found along specified line";
    window_select, wbkp;
    return;
  }

  // XYZZY - this is the last place we see fs being used for x
  y = fs.north(*)(glst) - l(2);
  x = fs.east(*)(glst)  - l(1);

  ca = cos(-angle);
  sa = sin(-angle);

  // XYZZY - rx is used to plot x
  // XYZZY - would the rx element give us the glst element to use?
  rx = x*ca - y*sa;
  ry = y*ca + x*sa;

  // XYZZY - y is computed from elevation
  // XYZZY - lw is the search width
  llst = where(abs(ry) < lw);
  if(mode == "fs")
    elevation = fs.elevation(*);
  else if(mode == "be")
    elevation = fs.lelv(*);
  else if(mode == "ba")
    elevation = fs.elevation(*) + fs.depth(*);

  //     1        2      3       4        5          6         7
  clr = ["black", "red", "blue", "green", "magenta", "yellow", "cyan" ];

  window, owin;
  window, wait=1;
  segs = where(abs(fs.soe(glst(llst))(dif)) > 5.0);
  nsegs = numberof(segs)+1;
  if(nsegs > 1) {
   // 20060425:  setting ss to [0] causes bizarre behavior where lines appear
   // to get merged.
   ss = [];
   grow, ss, segs,[0];
   segs = ss;

   segs = segs(where(abs(segs(dif)) > 1.0));
   nsegs = numberof(segs)+1;
  }

  ss = [0];
  if(nsegs > 1) {
    grow, ss, segs, [0];
    c = color;
    msum = 0;
    for(i = 1; i < numberof(ss); i++) {
      if(c >= 0)
        c = ((color+(i-1))%7);
      soeb = fs.soe(*)(glst(llst)(ss(i)+1));
      t = soe2time( soeb );
      tb = fs.soe(*)(glst(llst)(ss(i)+1))%86400;
      te = fs.soe(*)(glst(llst)(ss(i+1)))%86400;
      td = abs(te - tb);
      hms = sod2hms(tb);

      // This grabs the heading from the tans data nearest the end point.  This
      // really only works when looking at "just processed" data and not batch
      // processed data.
      hd = 0.0;
      if(is_array(tans)) {
        foo = where(abs(tans.somd-te) < .010);
        if(numberof(foo) > 0)
          hd = tans.heading(foo(1));
      }

      write, format="%d:%d sod = %6.2f:%-10.2f(%10.4f) utc=%2d:%02d:%02d %5.1f %s\n",
        t(1),t(2), tb, te, td, hms(1), hms(2), hms(3), hd, clr(abs(c));

      if(xtime) {
        plmk, elevation(*)(glst(llst)(ss(i)+1:ss(i+1)))/100.0,
          fs.soe(*)(llst)(ss(i)+1:ss(i+1))/100.0,color=clr(abs(c)),
          msize=msize, width=10, marker=marker;
        if(connect)
          plg, elevation(*)(glst(llst)(ss(i)+1:ss(i+1)))/100.0,
            fs.soe(*)(llst)(ss(i)+1:ss(i+1))/100.0, color=clr(abs(c));
      } else {
        xx = rx(llst)(ss(i)+1:ss(i+1))/100.0;
        si = sort(xx);
        yy = elevation(glst(llst)(ss(i)+1:ss(i+1)))/100.0;
        if(!is_void(rcf_parms))
          si = si(moving_rcf(yy(si), rcf_parms(1), int(rcf_parms(2))));
        // XYZZY - this is where the points get plotted
        plmk, yy(si), xx(si),color=clr(abs(c)), msize=msize, width=10,
          marker=marker;
        if(connect) plg, yy(si), xx(si),color=clr(abs(c));
      }
    }
  } else {
    xx = rx(llst)/100.0;
    yy = elevation(glst(llst))/100.0;
    si = sort(xx);
    if(!is_void(rcf_parms))
      si = si(moving_rcf(yy(si), rcf_parms(1), int(rcf_parms(2))));
    plmk, yy(si),xx(si), color=clr(color), msize=msize, marker=marker, width=10;
    if(connect)
      plg, yy(si), xx(si),color=clr(color);

    c = (color+0)&7;
    soeb = fs.soe(*)(glst(llst)(1));
    t = soe2time(soeb);
    tb = fs.soe(*)(glst(llst)(1))%86400;
    te = fs.soe(*)(glst(llst)(0))%86400;
    td = abs(te - tb);
    hms = sod2hms(tb);
    if(is_array(tans)) {
      hd = tans.heading(*)(int(te));
    } else {
      hd = 0.0;
    }
    write, format="%d:%d sod = %6.2f:%-10.2f(%10.4f) utc=%2d:%02d:%02d %5.1f %s\n",
      t(1),t(2), tb, te, td, hms(1), hms(2), hms(3), hd, clr(c);
  }
  window_select, wbkp;
  return glst(llst);
}

func transrch(fs, m, llst, _rx=, _el=, spot=, iwin=, mode=, disp_type=) {
/* DOCUMENT transrch(fs, m, llst, _rx=, _el=, spot=, iwin=, mode=, disp_type=)
  Searches for the point in the transect plot window iwin (default 3) nearest
  to where the user clicks.

  The selected point is highlighted red in the transect window and as a blue
  circle on the topo (5) window.

  Windows showing the raster and pixel waveform are displayed.

  Text is displayed in the console window showing details on the point
  selected.

  Input:
    fs          : Variable to process, must be of type FS.
                  use fs=test_and_clean(fs_all) to create
    m           : is the result from a call to mtransect()
    llst        : internal variable created from mtransect()

  To use, first generate a transect with these steps:

    cln_fs = test_and_clean(fs)
    m = mtransect(cln_fs, show=1);

    transrch, cln_fs, fs, llst;
*/
  //     1        2      3       4        5          6         7
  clr = ["black", "red", "blue", "green", "magenta", "yellow", "cyan" ];

  wbkp = current_window();

  extern mindata;
  extern _last_transrch;
  if(!is_void(_rx)) rx = _rx;
  if(!is_void(_el)) elevation = _el;
  default, _last_transrch, [0.0, 0.0, 0.0, 0.0];
  default, iwin, 3;

  if(is_void(mode)) {
    if(!is_void(disp_type)) {
      if(logger(warn))
        logger, warn, "call to transect using deprecated option disp_type=";
    } else {
      disp_type = 0;
    }
    mode = ["fs","be","ba"](disp_type+1);
  }

  // xyzzy - this assumes the default iwin for transect
  window, iwin;
  // m is the result from mtransect()
  // llst is an extern from transect()
  xx = rx(llst) / 100.;
  yy = elevation(m) / 100.;
  if(is_void(spot)) spot = mouse();
  write, format="mouse :       : %f %f\n", spot(1), spot(2);

  if(1) {   // the yorick way - rwm
    ll = limits();

    dx = spot(1)-xx;
    // need to normalize the x and y values
    dx = dx / (ll(2) - ll(1));
    dx = dx^2;
    dy = spot(2)-yy;
    dy = dy / (ll(4) - ll(3));
    dy = dy^2;
    dd = dx+dy;
    dd = sqrt(dd);
    minindx = dd(mnx);

  } else {  // non-yorick way
    // copied from raspulsrch(), useful for debugging
    qy = where(yy     > spot(2) -   2.5 & yy     < spot(2) +   2.5);
    qx = where(xx(qy) > spot(1) - 500.0 & xx(qy) < spot(1) + 500.0);

    // Does this really differ from qx?
    indx = qy(qx);
    write, format="searching %d points\n", numberof(indx);

    if(is_array(indx)) {
      mindist = 999999;
      for(i = 1; i < numberof(indx); i++) {
        dist = sqrt(((spot(1) - xx(indx(i)))^2) + ((spot(2) - yy(indx(i)))^2));
        x = [xx(i), xx(i)];
        y = [yy(i), yy(i)];
        plg, y, x, width=8.0, color="green";
        if(dist < mindist) {
          mindist = dist;
          minindx = indx(i);
          x = [xx(minindx), xx(minindx)];
          y = [yy(minindx), yy(minindx)];
          plg, y, x, width=9.0, color="blue";
        }
      }
    }
  } // end of the non-yorick way

  // Now we have the x/y values of the nearest transect point.
  // From here we need to find the original data value
  write, format="Result: %6d: %f %f\n", minindx, xx(minindx), yy(minindx);
  x = [xx(minindx), xx(minindx)];
  y = [yy(minindx), yy(minindx)];

  // We want to determine which segment a point is from so that we can redraw
  // it in that color.

  // Made segs extern in transect.i
  // 2008-11-25: wonder why i did that. must be computed here so we can
  // have multiple transects - rwm
  segs = where(abs(fs.soe(m)(dif)) > 5.0);
  // there must be a better way.
  for(i = 1, col = 0; i <= numberof(segs); i++) {
    if(segs(i) < minindx)
      col = i;
  }

  // just is.
  col += 2;
  col = col % 7;
  write, format="color=%s\n", clr(col);
  // highlight selected point in iwin
  plg, y, x, width=10.0, color=clr(col);

  mindata = fs(m(minindx));
  pixelwf_set_point, mindata;
  rasterno = mindata.rn&0xFFFFFF;
  pulseno = mindata.rn/0xFFFFFF
  hms = sod2hms(soe2sod(mindata.soe));
  write, format="Indx  : %6d HMS: %02d%02d%02d  Raster/Pulse: %d/%d FS UTM: %7.1f, %7.1f\n",
    minindx, hms(1), hms(2), hms(3), rasterno, pulseno, mindata.north/100.0,
    mindata.east/100.0;
  show_track, mindata, utm=1, skip=0, color=clr(col), win=5, msize=.5;
  window, 1, wait=1;
  fma;
  rr = decode_raster(rn=rasterno);
  write, format="soe: %d  rn: %d  dgtz: %d  np: %d\n",
    rr.soe, rr.rasternbr, rr.digitizer, rr.npixels;

  // Now lets display the waveform
  show_wf, rasterno, pulseno, win=0, cb=7;
  limits;

  mindata_dump_info, edb, mindata, minindx, last=_last_transrch,
    ref=_transrch_reference;

  _last_transrch = get_east_north_elv(mindata, mode=mode);

  window_select, wbkp;
}

func mtransrch(fs, m, llst, _rx=, _el=, spot=, iwin=, mode=, disp_type=,
ptype=, fset=) {
/* DOCUMENT mtransrch(fs, m, llst, _rx=, _el=, spot=, iwin=, mode=, disp_type=,
   ptype=, fset=)
  Call transrch repeatedly until the user clicks the right mouse button.
  Should work similar to Pixel Waveform.

  To use, first generate a transect with these steps:

    cln_fs = test_and_clean(fs_all)
    m = mtransect(cln_fs, show=1);
    mtransrch, cln_fs, fs, llst;
*/
  wbkp = current_window();

  extern _last_transrch, _transrch_reference;

  default, _last_transrch, [0.0, 0.0, 0.0, 0.0];
  default, _last_soe, 0;
  default, iwin, 3;
  default, ptype, 0;      // fs topo
  default, msize, 1.0;
  default, fset, 0;
  default, buf, 1000;     // 10 meters

  if(is_void(mode)) {
    if(!is_void(disp_type)) {
      if(logger(warn))
        logger, warn, "call to transect using deprecated option disp_type=";
    } else {
      disp_type = 0;
    }
    mode = ["fs","be","ba"](disp_type+1);
  }

  if(is_pointer(data)) data = *data(1);

  left_mouse =  1;
  center_mouse = 2;
  right_mouse = 3;
  shift_mouse = 12;
  ctl_left_mouse = 41;

  // the data must be clean coming in, otherwise the index do not match the
  // data.
  fs = test_and_clean(fs);

  rtn_data = [];
  nsaved = 0;

  do {
    write, format="Window: %d. Left: examine point, Center: set reference, Right: quit\n", iwin;
    window, iwin;

    spot = mouse(1,1, "");
    mouse_button = spot(10) + 10 * spot(11);
    if(mouse_button == right_mouse) break;

    if(mouse_button == ctl_left_mouse) {
      grow, finaldata, mindata;
      write, format="\007Point appended to finaldata.  Total saved = %d\n",
        ++nsaved;
    }

    transrch, fs, m, llst, _rx=_rx, _el=_el, spot=spot, iwin=iwin;

    if(mouse_button == center_mouse || mouse_button == shift_mouse) {
      _transrch_reference = get_east_north_elv(mindata, mode=mode);
    }

    mdata = get_east_north_elv(mindata, mode=mode);

    if(is_void(_transrch_reference)) {
      write, "No Reference Point Set";
    } else {
      if(mode == "fs") {
        write, format="   Ref. Dist: %8.2fm  Elev diff: %7.2fm\n",
          sqrt(double(mdata(1,) - _transrch_reference(1))^2 +
          double(mdata(2,) - _transrch_reference(2))^2),
          (mdata(3,) - _transrch_reference(3));
      }
      if(anyof(mode == ["be","ba"])) {
        write, format="   Ref. Dist: %8.2fm  Last Elev diff: %7.2fm\n",
          sqrt(double(mdata(1,) - _transrch_reference(1))^2 +
          double(mdata(2,) - _transrch_reference(2))^2),
          (mdata(4,) - _transrch_reference(4));
      }
    }
  } while(mouse_button != right_mouse);

  window_select, wbkp;
}

func get_east_north_elv(mindata, mode=) {
/* DOCUMENT get_east_north_elv(mindata, mode=)
  This function returns array containing the easting and northing values based
  on the type of data being used.

  INPUT:
    mindata - eaarl n-data array (1 element)
    mode= fs, be, or ba
  OUTPUT:
    (4,n) array consisting of east, north, elevation, lelv/depth values based
    on the display type.
*/
  default, mode, "fs";

  mindata = test_and_clean(mindata);

  local x, y, z1, z2;
  data2xyz, mindata, x, y, z1, mode="fs";
  if(mode != "fs")
    data2xyz, mindata, x, y, z2, mode=mode;
  else
    z2 = array(0., numberof(mindata));

  result = array(double, 4, numberof(mindata));
  result(1,) = x;
  result(2,) = y;
  result(3,) = z1;
  result(4,) = z2;
  return result;
}

func mindata_dump_info(edb, mindata, minindx, last=, ref=) {
/* DOCUMENT mindata_dump_info, edb, mindata, minindx, last=, ref=

  NEEDS DOCUMENTATION
*/
  if(is_void(ref)) last = [0.0, 0.0, 0.0, 0.0];
  if(!is_array(edb)) {
    write, "edb is not set, try again";
    return;
  }

  rasterno = mindata.rn&0xffffff;
  pulseno = mindata.rn>>24;
  _last_soe = edb(mindata.rn&0xffffff).seconds;

  somd = edb(mindata.rn&0xffffff).seconds % 86400;
  rast = decode_raster(get_erast(rn=rasterno));

  fsecs = rast.offset_time - edb(mindata.rn&0xffffff).seconds;
  ztime = soe2time(somd);
  zdt = soe2time(abs(edb(mindata.rn&0xffffff).seconds - _last_soe));

  if(is_array(tans) && is_array(pnav)) {
    pnav_idx = abs(pnav.sod - somd)(mnx);
    tans_idx = abs(tans.somd - somd)(mnx);
    knots = lldist(pnav(pnav_idx).lat, pnav(pnav_idx).lon,
      pnav(pnav_idx+1).lat, pnav(pnav_idx+1).lon) *
      3600.0/abs(pnav(pnav_idx+1).sod - pnav(pnav_idx).sod);
  }

  write, "\n=============================================================";
  write, format="                  Raster/Pulse: %d/%d UTM: %7.1f, %7.1f\n",
    mindata.rn&0xffffff, pulseno, mindata.north/100.0, mindata.east/100.0;

  if(is_array(edb)) {
    write, format="        Time: %7.4f (%02d:%02d:%02d) Delta:%d:%02d:%02d \n",
      double(somd)+fsecs(pulseno), ztime(4), ztime(5), ztime(6), zdt(4),
      zdt(5), zdt(6);
  }
  if(is_array(tans) && is_array(pnav)) {
    write, format="    GPS Pdop: %8.2f  Svs:%2d  Rms:%6.3f Flag:%d\n",
      pnav(pnav_idx).pdop, pnav(pnav_idx).sv, pnav(pnav_idx).xrms,
      pnav(pnav_idx).flag;
    write, format="     Heading:  %8.3f Pitch: %5.3f Roll: %5.3f %5.1fm/s %4.1fkts\n",
      tans(tans_idx).heading, tans(tans_idx).pitch, tans(tans_idx).roll,
      knots * 1852.0/3600.0, knots;
  }

  hy = sqrt(double(mindata.melevation - mindata.elevation)^2 +
      double(mindata.meast - mindata.east)^2 +
      double(mindata.mnorth - mindata.north)^2);

  if((mindata.melevation > mindata.elevation) && (mindata.elevation > -100000))
    aoi = acos((mindata.melevation - mindata.elevation) / hy) * RAD2DEG;
  else
    aoi = -9999.999;
  write, format="Scanner Elev: %8.2fm   Aoi:%6.3f Slant rng:%6.3f\n",
    mindata.melevation/100.0, aoi, hy/100.0;

  write, format="First Surface elev: %8.2fm Delta: %7.2fm\n",
    mindata.elevation/100.0, mindata.elevation/100.0 - last(3);

  if(structeq(structof(mindata(1)), FS)) {
    fs_chn_used = eaarl_intensity_channel(mindata.intensity);
    write, format="First Surface channel / intensity: %d / %3d\n",
      fs_chn_used, mindata.intensity;
  }

  if(structeq(structof(mindata(1)), VEG__)) {
    fs_chn_used = eaarl_intensity_channel(mindata.fint);
    be_chn_used = eaarl_intensity_channel(mindata.lint);

    write, format="Last return elev: %8.2fm Delta: %7.2fm\n",
      mindata.lelv/100., mindata.lelv/100.-last(4);
    write, format="First/Last return elv DIFF: %8.2fm\n",
      (mindata.elevation-mindata.lelv)/100.;
    write, format="First Surface channel-intensity: %d-%3d\n",
      fs_chn_used, mindata.fint;
    write, format="Last Surface channel-intensity: %d-%3d\n",
      be_chn_used, mindata.lint;
  }

  if(structeq(structof(mindata(1)), GEO)) {
    fs_chn_used = eaarl_intensity_channel(mindata.first_peak);
    be_chn_used = eaarl_intensity_channel(mindata.bottom_peak);

    write, format="Bottom elev: %8.2fm Delta: %7.2fm\n",
      (mindata.elevation+mindata.depth)/100.,
      (mindata.elevation+mindata.depth)/100.-last(4);
    write, format="First/Bottom return elv DIFF: %8.2fm", mindata.depth/100.;
    write, format="Surface channel-intensity: %d-%3d\n", fs_chn_used,
      mindata.first_peak;
    write, format="Bottom channel / intensity: %d-%3d\n", be_chn_used,
      mindata.bottom_peak;
  }

  write, "=============================================================\n";
}
