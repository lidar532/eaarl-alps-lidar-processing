/*
 $Id$

  rbtans.i
  This program reads a binary file of tans-vector data generated by
  the tans2bin.c program.  The input data file begines with a single
  32 bit integer which contains the number of tans sample points following
  it in the file.  The points which follow are single precision floating
  point binary values in the following order, sow, roll, pitch, heading.  sow
  is seconds of the week, and the rest are in degrees with pitch and roll 
  varying from -180:+180 and heading from 0:360.
  
Returns an array of type TANS as follows:

   tans.somd	Second of the mission day.
   tans.roll	Degrees of roll
   tans.pitch   Degrees of pitch
   tans.heading Degrees of heading **Note: Heading values range from 
		0 to 360. Passing through 0 or 360 causes a wrap-around
		which will cause invalid results if you try to use the
		data with "interp".  To correct the problem, break the
		heading into it's X and Y components for a unit circle,
		do the interp on those components, and then reform the
		heading in degrees (or radians).

History:
  1/21/02  Added correction for gps time offset. Modified the comments, 
           changed sod to somd.
 11/13/01  Modified to: 1) convert time from sow, to sod, 2) check and
           correct for midnight rollover. -WW

*/

struct TANS {
  float somd;
  float roll;
  float pitch;
  float heading;
};


require, "sel_file.i"
require, "ytime.i"
write,"$Id$"

plmk_default,msize=.1

if ( is_void( gps_time_correction ) )
  gps_time_correction = -13.0

func rbtans( junk ) {
 
 path = data_path+"/tans/"

if ( _ytk ) {
    ifn  = get_openfn( initialdir=path, filetype="*.ybin" );
    if (strmatch(ifn, "ybin") == 0) {
          exit, "NO FILE CHOSEN, PLEASE TRY AGAIN\r";
    }
    ff = split_path( ifn, -1 );
    data_path = ff(1);
} else {
 if ( is_void(data_path) )
   data_path = rdline(prompt="Enter data path:");
 ifn = sel_file(ss="*.ybin", path=data_path+"/tans/")(1);
}


n = int(0)
idf = open( ifn, "rb");

// get the integer number of records
_read, idf,  0, n

tans = array( float, 4, n);
_read(idf, 4, tans);

mxroll = tans(2, ) (max)
mnroll = tans(2, ) (min)

// compute seconds of the day
//////////tans(1,) = tans(1,) % 86400;

// check and correct midnight rollover
  q = where( tans(1, ) < 0 );		// look for neg spike
/****
  if ( numberof(q) ) {			// if found, then correct
    rng = q(1)+1:dimsof(tans(1,) )(2);  // determine values to correct
    tans(1,) += 86400;			// add 86400 seconds
  }
******/

 tans(1, ) += gps_time_correction;

write,format="Using %f seconds to correct time-of-day\n", gps_time_correction
write,format="%s", 
              "               Min          Max\n"
write, format="  SOD:%14.3f %14.3f %6.2f hrs\n", tans(1,min), tans(1,max), 
	(tans(1,max)-tans(1,min))/ 3600.0
write, format=" Roll:%14.3f %14.3f\n", tans(2,min), tans(2,max)
write, format="Pitch:%14.3f %14.3f\n", tans(3,min), tans(4,max)
print, "Tans_Information_Loaded"
 t = array( TANS, dimsof(tans)(3) );
 t.somd    = tans(1,);
 t.roll    = tans(2,);
 t.pitch   = tans(3,);
 t.heading = tans(4,);
 return t;
}


func prepare_sf_pkt (tans) {
  /* this function prepares a packet for sf_a.tcl which contains the pitch, roll, heading information
     for every camera photo every 1 second */
  /* amar nayegandhi 03/05/2002. */

  print, "Preparing packet at 1Hz for sf_a.tcl\n\r";

  no_t = (dimsof(tans)(2)/10); 
  if ((dimsof(tans)(2)%10) != 0) no_t++;

  t = array(TANS, no_t);

  t.somd = tans(1::10).somd;
  t.roll = tans(1::10).roll;
  t.pitch = tans(1::10).pitch;
  t.heading = tans(1::10).heading;


  return t;

}

func make_sf_tans_file(tmpfile) {
  /* this function writes out a tmpfile containing tans information for sf */
  f = open(tmpfile, "w");
  write, f, format=" %7d, %3.3f, %3.3f, %4.3f\n", (int)(pkt_sf.somd), pkt_sf.pitch, pkt_sf.roll, pkt_sf.heading;
  close, f
  }



