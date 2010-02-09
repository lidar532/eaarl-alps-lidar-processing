/* vim: set tabstop=3 softtabstop=3 shiftwidth=3 autoindent: */
require, "eaarl.i";

/**********************************************************************

   Transect.i
   Original W. Wright 9/21/2003

  Contains:

    mtransect
     transect


*********************************************************************/

extern _transect_history;
/* DOCUMENT _transect_history

A stack of recent transect lines generated by calls to "mtransect."
These can be recalled repeatly with the transact command.

For example, to recall the last mouse_transect with transect you would:

  transect( fs_all, _transect_history(,0), ..... )

to recall the one before last, use:

  transect( fs_all, _transect_history(,-1), ..... )

*/

func mtransect( fs, iwin=, owin=, w=, connect=, recall=, color=, xfma=, rcf_parms=, rtn=, show=, msize=, exp= ) {
/* DOCUMENT mtransect( fs, iwin= ,owin=, w=, connect=, recall=, color=, xfma= )

Mouse selected transect

mtransect allows you to "drag out" a line within an ALPS topo display
window and then create a new graph of all of the points near the line.

To recall a transect line, call mtransect with the recall= parameter
and set it to:
  0 for the most recent line,
 -1 for the previous line,
 -2 for the one before that, etc. etc.


Input:
  fs         :  Variable to process
  owin=      :  Desired Yorick output graph window.       Default is 3
  iwin=      :  Source window for transect.               Default is 5
  w=         :  Search distance from line in centimeters. Default is 150cm
  connect=   :  Set to 1 to connect the points.
  recall=    :  Used to recall a previously generated transact line.
  color=     :  The starting color 1:7, use negative to use only 1 color
  xfma=      :  Set to 1 to auto fma.
  rtn=       :  Select return type where:
                0  first return
                1  veg last return
                2  submerged topo
  show=      :  Set to 1 to plot the transect in window, win.
  rcf_parms= :  Filter output with [W, P], where
                W = filter width
                P = # points on either side to use as jury pool

Examples:

  g = mtransect(fs_all, connect=1, rcf_parms=[1.0, 5],xfma=1 )

  - Use fs_all as data source
  - Connect the dots in the output plot
  - rcf filter the output with a 1.0 meter filter width and use 5
    points on either side of each point as the jury pool
  - auto fma
  - returns the index of the selected points in g.
  This example expects you to generate the line segment with the mouse.


  g = mtransect(fs_all, connect=1, rcf_parms=[1.0, 5],xfma=1, recall=0 )

  This example is the same as above, except:
  - the transect line is taken from the global transect_history array.

See also: transect, _transect_history

*/

 extern _transect_history;
 extern transect_line;


 if ( is_void(rtn)   )    rtn = 0;		// default is first return
 if ( is_void(w))             w = 150;
 if ( is_void(connect)) connect = 0;
 if ( is_void(owin))       owin = 3;
 if ( is_void(iwin))       iwin = 5;
 if ( is_void(msize))     msize = 0.1;
 if ( is_void(xfma))        xfma= 0;
 if ( is_void(color))      color= 2;  // start at red, not black
 if ( is_void(rcf_parms))   rcf_parms = [];


 window,owin;
 lmts = limits();
 window,iwin;
 if ( is_void(recall) ) {
// get the line coords with the mouse and convert to cm
  transect_line = mouse(1, 2, "")(1:4)*100.0;
  l = transect_line;   // just to keep the equations short;
  if (show)
    plg, [l(2),l(4)]/100., [l(1),l(3)]/100., width=2.0, color="red";
  grow, _transect_history, [l]
 } else {
  if ( numberof(_transect_history) == 0 ) {
    write, "No transect lines in _transect_history";
    return;
  }
  if ( recall > 0 ) recall = -recall;
  l = _transect_history(, recall);
 }
  // if ( color > 0 ) --color;  // XYZZY adjust for nsegs starting at 1
  fs = test_and_clean(fs);
  fs = fs(sort(fs.soe))

  glst = transect( fs, l, connect=connect, color=color,xfma=xfma, rcf_parms=rcf_parms,rtn=rtn, owin=owin, lw=w, msize=msize );
   // plot the actual points selected onto the input window
   if (show == 2 )
     show_track,fs(glst), utm=1, skip=0, color="red", lines=0, win=iwin;
  if (show == 3 ) {   // this only redraws the last transect selected.
    window,iwin;
    plg, [transect_line(2),transect_line(4)]/100., [transect_line(1),transect_line(3)]/100., width=2.0, color="red";
  }
  window,owin;
  if ( is_void(recall) ) {
        limits
  } else
	limits(lmts(1),lmts(2), lmts(3), lmts(4));
   if ( ! is_void ( exp ) )
      write, format="%s\n", "END mtransect:";
  return glst;
}

func transect( fs, l, lw=, connect=, xtime=, msize=, xfma=, owin=, color=, rcf_parms=,rtn= ) {
/* DOCUMENT transect( fs, l, lw=, connect=, xtime=, msize=, xfma=,
                      owin=, color=,rtn= )

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
  rtn=       :  Select return type where:
                0  first return
                1  veg last return
                2  submerged topo from bathy algo

 See also: mtransact, _transect_history

*/
  extern rx, elevation, glst, llst, segs;


 if ( is_void(rtn)   )    rtn = 0;		// default is first return
 if ( is_void(lw)    )    lw = 150;		// search width, cm
 if ( is_void(color) ) color = 1;		// 1 is first color
 if ( is_void(owin)   )   owin = 3;
 if ( is_void(msize) ) msize = 0.1;
 window,wait=1;
 window, owin;
 if ( !is_void(xfma) ) {
   if ( xfma)  fma;
 }


// determine the bounding box n,s,e,w coords
  n = l(2:4:2)(max);
  s = l(2:4:2)(min);
  w = l(1:3:2)(min);
  e = l(1:3:2)(max);

// compute the rotation angle needed to make the selected line
// run east west
  dnom = l(1)-l(3);
  if ( dnom != 0.0 )
    angle = atan( (l(2)-l(4)) / dnom ) ;
  else angle = pi/2.0;
//  angle ;
//  [n,s,e,w]


// build a matrix to select only the data withing the bounding box
  good = (fs.north(*) < n)  & ( fs.north(*) > s ) & (fs.east(*) < e ) & ( fs.east(*) > w );

// rotation:  x' = xcos - ysin
//            y' = ycos + xsin

/* Steps:
        1 translate data and line to 0,0
        2 rotate data and line
        3 select desired data
*/

  glst = where(good);
  if ( numberof(glst) == 0 ) {
    write, "No points found along specified line";
    return ;
  }


  // XYZZY - this is the last place we see fs being used for x
  y = fs.north(*)(glst) - l(2);
  x = fs.east(*)(glst)  - l(1);

  ca = cos(-angle); sa = sin(-angle);

  // XYZZY - rx is used to plot x
  // XYZZY - would the rx element give us the glst element to use?
  rx = x*ca - y*sa
  ry = y*ca + x*sa

  // XYZZY - y is computed from elevation
  // XYZZY - lw is the search width
  llst = where( abs(ry) < lw );
  if ( rtn == 0 )
	  elevation = fs.elevation(*);
  else if ( rtn == 1 )
	  elevation = fs.lelv(*);
  else if ( rtn == 2 )
	  elevation = fs.elevation(*) + fs.depth(*);

//            1      2       3        4          5         6       7
  clr = ["black", "red", "blue", "green", "magenta", "yellow", "cyan" ];

  window,owin
  window,wait=1;
///  fma
  segs = where( abs(fs.soe(glst(llst))(dif)) > 5.0 );
  nsegs = numberof(segs)+1;
//segs
//nsegs
  if ( nsegs > 1 ) {
    // 20060425:  setting ss to [0] causes bizaar behavior where lines appear to get
    // merged.
    ss = [];
    grow, ss,segs,[0];
    segs = ss;

    segs = segs(where( abs(segs(dif)) > 1.0 ));
    nsegs = numberof(segs)+1;
  }

 ss = [0];
 if ( nsegs > 1 ) {
   grow, ss,segs,[0];

// "ss";ss
// "nsegs";nsegs
   c = color;
   msum=0;
   for (i=1; i<numberof(ss); i++ ) {
      if ( c >= 0 ) c = ((color+(i-1))%7);
//    write, format="%d: %d %2d %2d %d  ", c, color, i, color+i, ((color+i)%7);
   soeb = fs.soe(*)(glst(llst)(ss(i)+1));
      t = soe2time( soeb );
     tb = fs.soe(*)(glst(llst)(ss(i)+1))%86400;
     te = fs.soe(*)(glst(llst)(ss(i+1)))%86400;
     td = abs(te - tb);
     hms = sod2hms( tb );

     // This grabs the heading from the tans data nearest the end point.
     // This really only works when looking at "just processed" data and
     // not batch processed data.
	  // AN - 20090629 -- Will now work with batch processed data as well.
   hd = 0.0;
	if (is_array(tans)) {
     foo = where ( abs(tans.somd-te) < .010 );
     if ( numberof(foo) > 0 )
        hd = tans.heading(foo(1));
	}

     write, format="%d:%d sod = %6.2f:%-10.2f(%10.4f) utc=%2d:%02d:%02d %5.1f %s\n",
                    t(1),t(2), tb, te, td, hms(1), hms(2), hms(3), hd, clr(abs(c));

     if ( xtime ) {
     plmk, elevation(*)(glst(llst)(ss(i)+1:ss(i+1)))/100.0,
           fs.soe(*)(llst)(ss(i)+1:ss(i+1))/100.0,color=clr(abs(c)), msize=msize, width=10;
       if ( connect ) plg, elevation(*)(glst(llst)(ss(i)+1:ss(i+1)))/100.0,
                fs.soe(*)(llst)(ss(i)+1:ss(i+1))/100.0,color=clr(abs(c))
     } else {
     xx = rx(llst)(ss(i)+1:ss(i+1))/100.0;
     si = sort(xx);
     yy = elevation(glst(llst)(ss(i)+1:ss(i+1)))/100.0;
     if ( !is_void(rcf_parms) )
         si = si(moving_rcf(yy(si), rcf_parms(1), int(rcf_parms(2) )));
     // XYZZY - this is where the points get plotted
     plmk, yy(si), xx(si),color=clr(abs(c)), msize=msize, width=10;
       if ( connect ) plg, yy(si), xx(si),color=clr(abs(c))
    }
   }
 } else {
   xx = rx(llst)/100.0;
   yy = elevation(glst(llst))/100.0;
   si = sort(xx);
   if ( !is_void(rcf_parms) )
         si = si(moving_rcf(yy(si), rcf_parms(1), int(rcf_parms(2) )));
  plmk, yy(si),xx(si), color=clr(color), msize=msize, marker=1, width=10;
  if ( connect ) plg, yy(si), xx(si),color=clr(color)

  c    = (color+0)&7;
  soeb = fs.soe(*)(glst(llst)(1));
  t    = soe2time( soeb);
  tb   = fs.soe(*)(glst(llst)(1))%86400;
  te   = fs.soe(*)(glst(llst)(0))%86400;
  td   = abs(te - tb);
  hms  = sod2hms( tb );
  if (is_array(tans)) {
     hd   = tans.heading(*)(int(te));
  } else {
	  hd = 0.0;
  }
  write, format="%d:%d sod = %6.2f:%-10.2f(%10.4f) utc=%2d:%02d:%02d %5.1f %s\n",
                    t(1),t(2), tb, te, td, hms(1), hms(2), hms(3), hd, clr(c);
 }
// limits
// limits,,, cbar.cmin, cbar.cmax
 return glst(llst);
}

func extract_transect_info(tlst, fs, &coords, &segtimes, rtn=) {
/* DOCUMENT extract_transect_info(tlst, fs)
  Amar Nayegandhi Nov 2006
  This function saves relevant transect information.
  INPUT:
	tlst: returned from the mtransect function. list of indices of the fs array that fall along the transect.
	fs : the original data array (can be of type FS, VEG, or GEO)
	rtn = defaults to 0.
			Select return type where:
			0 first return
			1 veg last return
			2 submerged topo
*/

	if (is_void(rtn)) rtn=0;
	// find the min and max easting and northing of the transect
	if (rtn == 0 || rtn == 2) {
		mxeast = max(fs.east(tlst));
		mneast = min(fs.east(tlst));
		mxnorth = max(fs.north(tlst));
		mnnorth = min(fs.north(tlst));
	}
	if (rtn == 1) {
		mxeast = max(fs.least(tlst));
		mneast = min(fs.least(tlst));
		mxnorth = max(fs.lnorth(tlst));
		mnnorth = min(fs.lnorth(tlst));
	}

	coords = [[mneast/100., mnnorth/100., mxeast/100., mxnorth/100.]];
	coords = double(coords);

	write, format="Transect coordinates:\n NE: %8.2f m, %7.2f m\n SW: %8.2f m, %7.2f m\n",coords(4,1), coords(3,1), coords(2,1), coords(1,1);

	tlength = sqrt((coords(1)-coords(3))^2 + (coords(2)-coords(4))^2);

	write, format="Transect Length = %4.2f m\n",tlength;
		
	// find the start and stop time
	// find number of flightline  segments
	segs = where( abs(fs.soe(tlst)(dif)) > 5.0 );
	nsegs = numberof(segs)+1;
	segtimes = array(long,2,nsegs);
	ss = [0];
	if ( nsegs > 1 ) {
		grow, ss,segs,[0]
		write, "Flightline Segments:"
		write, "Year:DayofYear\t SODbegin:SODend\t Time(s) "
		for (i=1; i<numberof(ss); i++ ) {
			soeb = fs.soe(*)(tlst(ss(i)+1));
			t = soe2time( soeb );
			tb = fs.soe(*)(tlst(ss(i)+1))%86400;
			te = fs.soe(*)(tlst(ss(i+1)))%86400;
			td = abs(te - tb);
			hms = sod2hms( tb );
			segtimes(1,i) = long(tb-1);
			segtimes(2,i) = long(te+1);

			write, format="%d:%d\t\t %6.2f:%-10.2f\t %-4.2f\n",
					      t(1),t(2), tb, te, td;
		}
	}

	return 1;
}

func delete_transect_list(junk) {
   extern coords_all, transect_all;
   coords_all = transect_all = [];
   return 1
}

func save_transect_list(filename) {
   extern coords_all, transect_all;
   f = createb(filename);
   save, f, coords_all, transect_all;
   close, f;
   return 1
}


func append_transect_list(tlst, fs, rtn=) {
/* DOCUMENT append_transect_list(tlst, fs, rtn=)
  Amar Nayegandhi Nov 2006
  This function appends the transect coordinates and time of day to the global variables coords_all and transect_all array.
  INPUT:
	tlst: returned from the mtransect function. list of indices of the fs array that fall along the transect.
	fs : the original data array (can be of type FS, VEG, or GEO)
	rtn = defaults to 0.
			Select return type where:
			0 first return
			1 veg last return
			2 submerged topo
*/
	
	extern transect_all, coords_all;

	success = extract_transect_info(tlst,fs,coords,segtimes,rtn=rtn);

	transect_all = grow(transect_all, segtimes);
	coords_all = grow(coords_all, coords);

}


func reprocess_data_along_transect(new_pnav, outdir=, ofname_tag=, rtn=, w= ) {
/* DOCUMENT reprocess_data_along_transect(new_pnav, outdir=, ofname_tag= )
 Amar Nayegandhi Jan 2006
 This function reprocesses data along the transects defined by the transect_all array.
 INPUT:
	new_pnav : the new pnav data array.  The global variables gga and pnav will be assigned to this new_pnav
   outdir = String.  The output directory where the pbd files will be written to.
   ofname_tag = String.  Define tag name to the output filename that will help differentiate between data processed using different trajectories.  Usually name_tag will include the base station names used to processed the trajectory new_pnav. e.g. name_tag = "kwal_hg63" indicates trajectory processed using the Wallops Island base and the Hangar base station.
	rtn = defaults to 0.
			Select return type where:
			0 first return
			1 veg last return
			2 submerged topo
   The file name will also include the trajectory number.

*/
	
	extern gga, pnav, coords_all, transect_all, _transect_history

	if (!is_void(new_pnav)) {
		gga = pnav = new_pnav;
	}

   _transect_history = coords_all*100.;


   if (is_void(outdir)) {
      write, "output directory not defined. Writing to home directory"
      outdir = "~/";
   }

   if (is_void(save_data)) save_data = 1;
   if (is_void(save_transect_output)) save_transect_output = 1;
   if (is_void(ofname_tag)) ofname_tag = "base";
   if (is_void(rtn)) rtn = 0;

   segtimes = transect_all;
	nsegs = numberof(segtimes(1,));
	q = [];

	for (i=1;i<=nsegs;i++) {
		idx = where((gga.sod >= segtimes(1,i)) & (gga.sod <= segtimes(2,i)));
		q = grow(q,idx);
	}

	if (rtn == 0) {
		data_re = make_fs(latutm=1, q=q, ext_bad_att=1, usecentroid=1);
	}

	if (rtn == 2) {
		data_re = make_bathy(latutm=1, q=q, ext_bad_depth=1, ext_bad_att=1, avg_surf=0);
	}

	if (rtn == 1) {
		data_re = make_veg(latutm=1, q=q, ext_bad_att=1, ext_bad_veg=1, use_centroid=1);
	}

   data_re = test_and_clean(data_re);
   idx = sort(data_re.soe);
   data_re = data_re(idx);
   idx = unique(data_re.soe, ret_sort=1);
   data_re = data_re(idx);
   for (j=1;j<=numberof(coords_all(1,));j++) {
      // run the mtransect function on the each transect
      trans_output = mtransect(data_re, rtn=rtn,recall=1-j,w=w);
      if (is_array(trans_output)) {
         // write out to a file
         // define output file name
         ofname = swrite(format="T%d_%s.pbd",j,ofname_tag);
         coords = coords_all(,j);
         tdata = data_re(trans_output);
         f = createb(outdir+ofname);
         save, f, tdata, coords;
         close, f;
       }
    }

return 1;

}
