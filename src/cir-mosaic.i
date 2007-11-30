/*

   $Id$
 
  Functions to work with the EAARL Axis digital camera.  

  Orginal W. Wright, 5-6-03 while in San Juan, Pr.

*/

require, "pnm.i";

write,"$Id$";


func jpg_read(filename)
/* DOCUMENT image= jpg_read(filename)

     read a jpg image from FILENAME.  Converts to pnm using the commandline
program convert to convert the image to a pnm file in the /tmp/directory.  
Use pli to display the image.

   SEE ALSO: pnm_display, pnm_write
 */
{
   cmd = swrite(format="convert %s /tmp/etmp.pnm", filename);
   f = popen( cmd, 0);
   close,f;
   return pnm_read( "/tmp/etmp.pnm");
}


  cam1_roll_bias = 0.0;
  cam1_yaw_bias  = 0;
  cam1_pitch_bias  = 0.0;
  fov = 50.0 * pi/180.0;	// camera FOV


func cir_photo_orient( photo, 
        heading=, 
	pitch=, 
	roll=, 
	alt=, 
	center=, 
	offset=, 
	scale=, 
	win= 
) {
/* DOCUMENT photo_orient( p, 
	heading=, pitch=, roll= , center=, offset=, scale= 
  )

   Orient and display EAARL cam1 photos.  Where:
   p		The photo array.
   heading=	Aircraft heading in degrees.
   pitch=       Aircraft pitch (deg).
   roll=        Aircraft roll (deg).
   alt=         Aircraft AGL altitude in meters.
   center=
   offset=
   scale=
   win=         The window to display photo mosaic in.

   

*/

  if ( is_void( scale  ) ) scale  = [1.0, 1.0];
  if ( is_void( offset ) ) offset = [0.0, 0.0];
  if ( is_void(heading)  ) heading = 0.0;
  if ( is_void(win    )  ) win = 7;
  if ( is_void(roll   )  ) roll = 0.0;
  p = photo;
////  p(, , -15:0) = 0;		// zeros the time in the image
  //p = photo(,, 1:-16);		// removes the time image
  //heading = (-heading + cam1_yaw_bias  - 180.0) * pi / 180.0;
  heading = (-heading +cam1_yaw_bias)*pi/180.;
  s = sin(heading);
  c = cos(heading);
  dx = dimsof(p) (3)
  dy = dimsof(p) (4)
  //alt += 30.0;		// make it sealevel more or less
  if ( alt ) { 
     xtk = 2.0 * tan( fov/2.0) * alt;
     scale(1) = scale(2) = xtk / dx;
   }
///////////////////print, "xtk", xtk, scale
  if ( is_void(center) ) {
    center = array( int, 2);
    center(2) = dx / 2.0;
    center(1) = dy / 2.0;  
  }
  roll_offset = tan( roll * pi/180.0) * alt;
 pitch_offset = tan( pitch * pi/180.0) * alt;
   x = span(-center(2), dx-center(2), dx+1 ) (,-:1:dy+1); 
   x += roll_offset;
   y = span(-center(1), dy-center(1), dy+1 ) (-:1:dx+1, ); 
   y += pitch_offset;
   xx =   (x * c - y * s) * scale(2);
   yy =   (x * s + y * c) * scale(1);
  window,win; plf, p, yy+offset(1), xx+offset(2), edges=0;
  return [xx, yy ];

}

func cir_gref_photo( somd=, ioff=, offset=,ggalst=, skip=, drift=, date=, win= ) {
/* DOCUMENT gref_photo, somd=, ioff=, offset=, ggalst=, skip=

    smod=  A time in SOMD, or a list of times.
    ioff= Integer offset 
  offset=
  ggalst=
    skip= Images to skip
   drift= Clock drift to add


*/

 extern aa, aa2;
 if ( is_void(ioff) ) ioff = 0;
 if ( is_void(drift) ) drift = 0.0;
 if ( is_void(offset)) offset = 1.2;
 if (is_array(ggalst)) somd = int(gga.sod(ggalst(unique(int(gga.sod(ggalst))))))
 if (skip)  somd = somd(1:0:skip);
 write, somd
 for ( i = 1; i <=numberof(somd); i++ ) {
  sd = somd(i) + ioff;
  csomd = sd + offset + i * drift;
  heading = interp( tans.heading, tans.somd, csomd);
  roll    = interp( tans.roll   , tans.somd, csomd);
  roll = 0;
  pitch   = interp( tans.pitch  , tans.somd, csomd);
  pitch = 0;
  lat     = interp( pnav.lat, pnav.sod, csomd);
  lon     = interp( pnav.lon, pnav.sod, csomd);
  galt    = interp( pnav.alt, pnav.sod, csomd);
  ll2utm, lat, lon;
  northing = UTMNorthing;
  easting  = UTMEasting;
  zone     = UTMZone;
  hms = sod2hms( int(sd ) );   
  tkcmd, swrite(format="send cir.tcl tmp_image sod %d",int(sd));
  pause, 500;
  if (i==1) write, "heading, northing, easting, roll, pitch, galt, hms"
  print, heading, northing, easting, roll, pitch, galt, hms
  pname = "/tmp/tmp.jpg";
  photo = jpg_read( pname );
  cir_photo_orient, photo, 
	        alt= galt,
	    heading= heading,
	       roll= roll + ops_conf.roll_bias + cam1_roll_bias,
	     pitch = pitch + ops_conf.pitch_bias + cam1_pitch_bias,
	     offset = [ northing, easting ], win=win;
 }
}



// Possible error messages from cir code.
cir_error = array(string,100);
cir_error( 1) = "Operation completed normally.";
cir_error(-1) = "The cir_mask array is void.";
cir_error(-2) = "No CIR photo exists at the requested SOD value.";
cir_error(-3) = "The jgwinfo(1) path isn't set. See set_jgwinfo.";
cir_error(-4) = "The jgwinfo(2) date isn't set. See set_jgwinfo.";
cir_error(-5) = "The structure iex_nav1hz is void. Load a DMARS dataset to correct this problem.";
cir_error(-6) = "No attitude data found for that time.";
cir_error(-8) = "The iex_nav data variable is void.";
cir_error(-9) = "";
cir_error(-10)= "";
cir_error(-12)= "";
cir_error(-13)= "";
cir_error(-14)= "";
cir_error(-15)= "";

func load_cir_mask( fn ) {
/* DOCUMENT load_cir_mask( fn )

 Original: W. Wright 5/4/2006

031006-214859-332-cir.jpg

*/
 extern cir_mask
 cir_mask = array(short, 86400); 
 tmp = array(long,86400*2);
 ds = ""; ts=""; ms = int(0); hh = int(0); mm=int(0); ss=int(0); 
 f = open( fn, "r");
 for (i=1; i<86400; i++ ) {
  n = read(f,format="%06s-%02d%02d%02d-%d", ds,hh,mm,ss,ms );
  if ( n == 0 ) break;
    sod = hh*3600+mm*60+ss;
    cir_mask(sod) = sod;
 }
 write,format="Read %d CIR file names from: %s\n", i-1, fn
 close,f
 return 1;
}

func gen_jgw_files( somd_list ) {
/* DOCUMENT gen_jgw_files( somd_list )

 Generates jgw files for each element of the somd_list.

ls | grep jgw > junk
tar --remove-files -cvzf jgwfiles.tgz -T junk


Original W. Wright 5/6/06
*/
 extern jgwinfo, camera_specs
  n = numberof( somd_list );
n
  if ( is_void( jgwinfo ) ) {
   write,"Operation aborted.  The jgwinfo array must be set first.  try: help, jgwinfo"
  }
 write,""
 gen_cir_nav(camera_specs.trigger_delay);
  for (i=1; i<= n; i++ ) {
     e = gen_jgw_file( somd_list(i));		// Generate each jgw file.
     if ( e != 1 ) {
       write,format="Error %d for sod:%d\n", e, i; 
     }
     if ( (i % 100) == 0  ) write, format=" Generated: %d of %d (%3.0f%%) jgw files\r", i, n, (i*100.0/n);
  }  
   i--;
   write, format=" Generated: %d of %d (%3.0f%%) jgw files\r", i, n, (i*100.0/n);
   write,"\nOperation completed.\n"
  return 1;
}

// Set the jgwinfo array to two "" strings.
if ( is_void( jgwinfo) ) {
  jgwinfo = array(string,2);
  jgwinfo(1) = jgwinfo(2) = "";
}

func set_jgw_info( dir, m, d, y ) {
/* DOCUMENT set_jgw_info( dir, m, d, y)


  Use this function to either set or query the current output
  path and date.  The jgwinfo is an array of two strings, where 
  jgwinfo(1) is the directory to store the jgw files and 
  jgwinfo(2) is the date string specfic to the CIR camera in the 
  format mmddyy. Note that the mm sarts at zero, so january is 
  0 and december is 11.

 set-jgw_info() with no parameters will return the current value
 of the jgwinfo array.

  Example:  set_jgw_info, "/tmp", 4,11,06

  The above sets the output diretroy to "/tmp" and the date to
  to 4/11/2006.  **** Important note **** The month in the jpg and
  jgw file will appear to be early by one month. For example, if
  you set the month to April or 4, it will appear in the file  name
  as March or 3.  I know it's odd, but we now have millions of photos
  named that way, and code to read them.

  Example jpg file name: 021406-193951-326-cir.jpg

Original W. Wright 5/6/06
*/
 extern jgwinfo
 if ( is_void(dir) ) return jgwinfo;
 if ( y > 2000) y -= 2000;
 jgwinfo(1) = dir;
 jgwinfo(2)=swrite(format="%02d%02d%02d", m-1,d,y);
}

func batch_gen_jgw_file(photo_dir, date, progress=, mask=) {
/* DOCUMENT batch_gen_jgw_file, photo_dir, date, progress=, mask=

   Generates jgw files for each CIR image in photo_dir's subdirectories. Since
   find is used, any directory structure will work. The date argument should be
   "mmddyy" where mm is the month minus 1. (So January is 00, and December is
   11.)

   The jgw file will be in the same directory as its associated jpg.

   This function uses file_dirname, which requires yeti_regex.i. See dir.i for
   more info.

   Set progress=0 to disable progress information.

   If mask= is provided, it should be an array as array(short, 86400) that
   indicates, for each SOD value, whether or not the image at that time should
   have a JGW generated. 1 means generate, 0 means don't. The default is
   mask=array(1, 86400), which means that all files get jgws.

   Note: This will set the extern cir_mask to array(1, 86400) if it's void to
   avoid error messages from gen_jgw_file.
*/
   extern jgwinfo, cir_error, cir_mask, iex_nav1hz;
   fix_dir, photo_dir;
   default, progress, 1;
   default, cir_mask, array(short(1), 86400);

   // The default mask matches the time boundaries of iex_nav1hz
   temp = array(short(0), 86400);
   temp(int(ceil(iex_nav1hz.somd(min)))-1:int(iex_nav1hz.somd(max))-1) = 1;
   default, mask, temp;
   temp = [];

   jpgs = find(photo_dir, glob="*-cir.jpg");
   if(progress) {
      tstamp = 0;
      timer_init, tstamp;
      write, format="Generating JGW's for %d files.\n", numberof(jpgs);
   }
   for(i = 1; i <= numberof(jpgs); i++) {
      if(progress)
         timer_tick, tstamp, i, numberof(jpgs);
      somd = hms2sod(atoi(strpart(jpgs(i), -13:-8)));
      if(!mask(somd)) continue;
      jgwinfo = [file_dirname(jpgs(i)), date];
      ret = gen_jgw_file(somd);
      if(ret < 1) {
         if(progress) write, "";
         if(ret == 0) msg = "No file found.";
         else msg = cir_error(ret);
         write, format="Error for image %s: %s\n", jpgs(i), msg;
      }
   }
}

func gen_jgw_file( somd ) {
/* DOCUMENT gen_jgw_file(somd)

  This function generates jgw files to georef the CIR images. 

 Inputs: somd
externs: jgwinfo  The path and date where the cir jpg files are loaded.
Returns: 0 if no cir file exists
         1 if it generated a jgw file
        -1 if cir_mask is void
        -2 if the no photo exists at the sod
        -3 The jgwinfo(1) path isn't set. See set_jgwinfo
        -4 The jgwinfo(2) date isn't set. See set_jgwinfo

Outputs: a jgw file named after the cooresponding cir.jpg file.

Original W. Wright 5/6/06

*/
 extern jgwinfo, jgwfndate, cir_mask
 somd %= 86400
 somd = int(somd);
 if ( is_void( cir_mask ) ) return -1;
 if ( !cir_mask(somd))  return -2;
 if ( jgwinfo(1) =="") return -3;
 if ( jgwinfo(2) =="") return -4;

 a = gen_jgw( somd );
 if ( numberof(a) ==1 ) {	// an error is one element long, return it now.
   return a;
 }
 hms = sod2hms(somd);
 ofn=swrite(format="%s/%s-%02d%02d%02d-cir.jgw", 
    jgwinfo(1),jgwinfo(2), hms(1),hms(2),hms(3));
 jpg_ofn=swrite(format="%s-%02d%02d%02d-cir.jpg", 
    jgwinfo(2), hms(1),hms(2),hms(3));
// write,format="%s\n", ofn
 of = open(ofn,"w");
 write,of,format="%9.6f \n", a(1:4)    
 write,of,format="%12.3f \n", a(5:6)    
 close,of
 // ab = system("cp /data/1/EAARL/Processed_Data/JELA_06/cir_images/"+jpg_ofn+" "+jgwinfo(1)+"/"+jpg_ofn);
 return 1;
}

// Camera mounting bias values.
// 
 struct CIR_MOUNTING_BIAS {
  string name;		// Aircraft id (N-Number).
  float pitch;		// +nose up
  float roll;		// +cw (roll to the right)
  float heading;	// +cw (right turn)
  float x;		// Offset from Camera to IMU along the fuselage toward the nose
  float y;		// Offset across the fueslage, positive toward the right wing
  float z;		// Offset +up
}

cir_mounting_bias = CIR_MOUNTING_BIAS(); // Create a mounting bias variable
cir_mounting_bias_n111x = CIR_MOUNTING_BIAS();
cir_mounting_bias_n48rf = CIR_MOUNTING_BIAS();

//=================================================
// For N111x. Calibrated using 3/14/2006 
// Ocean Springs, Ms. runway passes.
//=================================================
cir_mounting_bias_n111x.name = "n111x";
cir_mounting_bias_n111x.pitch  = 1.655;	 // Now, set the bias values.
cir_mounting_bias_n111x.roll   =-0.296;
cir_mounting_bias_n111x.heading= 0.0; 

//=================================================
// For N48rf calibrated using 4/11/2006 KSPG
//=================================================
cir_mounting_bias_n48rf.name = "n48rf";
cir_mounting_bias_n48rf.pitch  = -0.10 + 0.03 + 0.5 -0.5;	 // Now, set the bias values.
cir_mounting_bias_n48rf.roll   = 0.50 - .28 + 0.03 + 0.75 - 0.14 -0.7;
cir_mounting_bias_n48rf.heading= 0.375 - 0.156 + 0.1;


//=================================================
// Camera specifications.
//=================================================
struct CAMERA_SPECS {
  string name;			// Camera name;
  double focal_length;		// focal length in meters
  double ccd_x;			// detector x dim in meters.  Along fuselage.
  double ccd_y; 			// detector y dim in meters.  Across the fuselage.;
  double ccd_xy;			// Detector pixel size in meters.
  double trigger_delay;		// Time from trigger to photo (seconds).
}
camera_specs = CAMERA_SPECS();

///////////////////////////////////////////
// MS4000 info
///////////////////////////////////////////
ms4000_specs = CAMERA_SPECS();
ms4000_specs.name = "ms4000";
ms4000_specs.focal_length = 0.01325;
ms4000_specs.ccd_x        = 0.00888;
ms4000_specs.ccd_y        = 0.01184;
ms4000_specs.ccd_xy       = 7.40e-6 * 1.02;
ms4000_specs.trigger_delay= 0.120;		// Delay (seconds) from trigger to capture.

 camera_specs = ms4000_specs;
 cir_mounting_bias = cir_mounting_bias_n111x;

// Printout the values below.
camera_specs;
cir_mounting_bias;

func gen_jgw( somd ) {
/* DOCUMENT gen_jgw(somd)

 Gen_jgw(somd) generates JGW matrix elements. 

 Inputs:  somd (Seconds of the mission day)
 Returns: A 1d array of the six elements for the jgw file.

 

Original tranasformation code written by Jon Sellars and/or
Chris parrish December, 2005.
Updated by Jon Sellars and Bang Le, NOAA, December, 2005
Updated by Jon Sellars and Chris Parrish to Read CSV files 
  to create JGW world files for DSS Images April 2006

Converted to Yorick for EAARL CIR jgw generation, 
W. Wright and Jon Sellars 5/4/2006

Integrated with EAARL ALPS W. Wright 5/7/2006
*/
extern iex_nav1hz;	// INS data dumbed down to 1hz
extern cir_mounting_bias;
extern camera_specs;	// Camera specifications
extern Geoid;

// determine the seconds of the day... this needs changed to somd sometime
timeBias = 1;		// the CIR acquisition times are off by exactly one second
somd %= 86400
if ( is_void(iex_nav1hz) ) return -5;

//================================================================================
// Here we locate the index for our sod value.  We truncate it to integer seconds
// for the search.  The actual time in the iex_nav1hz entry will already be offset
// by the trigger_delay.
//================================================================================
somd += timeBias;
insI = where( int(iex_nav1hz.somd) == somd )(1) ;
if ( is_void(insI) ) return -6;
ins = iex_nav1hz(insI);

// This is some debugging code.
//hms = sod2hms(int(ins.somd));
// write,format="%02d:%02d:%02d %d %12.3f %6.3f %7.3f %7.3f %8.1f\n", 
//   hms(1),hms(2),hms(3), insI,  ins.somd, ins.pitch, ins.roll, ins.heading, ins.northing
Z = ins.alt;
X = ins.easting;
Y = ins.northing; 
P = ins.pitch; 
R = ins.roll; 
H = ins.heading; 

CCD_X = camera_specs.ccd_x;
CCD_Y = camera_specs.ccd_y;
CCD_XY= camera_specs.ccd_xy;
    FL= camera_specs.focal_length;

//Angle from camera to edges of image WRT X along track Y across track

//Ang_X = 18.559 * d2r
//Ang_Y = 24.116 * d2r

//Principle Point Offsets
//ppX = 0.000
//ppY = 0.000



//     FL=0.013255;		// focal length
// CCD_X = 0.00888
// CCD_Y = 0.01184
// CCD_XY = 0.0000074

// THe following should be determined by the lidar elevation. Right now it is the ITRF elev offset to the airfield
if(is_void(Geoid))
 Geoid = -21.28   // -24.0;	// Elevation offset from ground to nad83 ell.

// Load the local vars for mounting bias.
  BS_P =  cir_mounting_bias.pitch;
  BS_R =  cir_mounting_bias.roll;
  BS_H =  cir_mounting_bias.heading;


 // Calculate pixel size based on flying height
    FH=Z + (-1.0 * Geoid)
    PixSz=(FH*CCD_XY)/FL


// Convert heading to - clockwise and + CCW for 1st and 3rd rotation matrix
    if (H >= 180.0) 
       H2= 360.0 - (H + BS_H);
    else 
      H2 = -((H + BS_H) * 1.0);
//

    Prad = (P + BS_P) * d2r
    Rrad = (R + BS_R) * d2r
    Hrad = (H + BS_H) * d2r
    H2rad = H2 * d2r

// Create Rotation Coeff
    Term1 = cos(H2rad)
    Term2= -1.0* (sin(H2rad))
    Term3 = sin(H2rad)

// Create first four lines of world file
// Resolution times rotation coeffs
    A=PixSz * Term1
    B=-1.0*(PixSz * Term2)
    C=(PixSz * Term3)
    D=-1.0*(PixSz *Term1)

    // Calculate s_inv
    s_inv = 1.0/(FL/FH)

// Create terms for the M matrix
    M11 = cos(Prad)*sin(Hrad)
    M12 = -cos(Hrad)*cos(Rrad)-sin(Hrad)*sin(Prad)*sin(Rrad)
    M13 = cos(Hrad)*sin(Rrad)-sin(Hrad)*sin(Prad)*cos(Rrad)
    M21 = cos(Prad)*cos(Hrad)
    M22 = sin(Hrad)*cos(Rrad)-(cos(Hrad)*sin(Prad)*sin(Rrad))
    M23 = (-sin(Hrad)*sin(Rrad))-(cos(Hrad)*sin(Prad)*cos(Rrad))
    M31 = sin(Prad)
    M32 = cos(Prad)*sin(Rrad)
    M33 = cos(Prad)*cos(Rrad)

// Upper Left Corner Define p matrix (+X direction of flight along track, +Y left wing across track, -FL)
//    Xi = (CCD_X/2.0) - ppX
//    Yi = (CCD_Y/2.0) - ppY
//    FLneg = -1.0 * FL

// Center Pixel UL Define p matrix (+X direction of flight along track, +Y left wing across track, -FL) eventually we should use the principle point as the center
    Xi = 0.0000074
    Yi = 0.0000074
    FLneg = -1.0 * FL

// s_inv * M * p + T(GPSxyz) CENTER PIX (Used to be UL_X, UL_Y, UL_Z)
    CP_X = (s_inv *(M11* Xi + M12 * Yi + M13 * FLneg)) + X
    CP_Y = (s_inv *(M21* Xi + M22 * Yi + M23 * FLneg)) + Y
    CP_Z = (s_inv *(M31* Xi + M32 * Yi + M33 * FLneg)) + FH

//Calculate Upper left corner (from center) in mapping space, rotate, apply to center coords in mapping space
Yoff0 = PixSz * 600
Xoff0 = PixSz *(-1 *  800)


Xoff1 = (Term1 * Xoff0) + (Term2 * Yoff0)
Yoff1 = (Term3 * Xoff0) +(Term1 * Yoff0)

NewX = Xoff1 + CP_X
NewY = Yoff1 + CP_Y

//Calculate offset to move corner to the ground "0" won't need this again until we start doing orthos
//Xoff0 = (tan(Ang_X + Prad)) * UL_Z
//Yoff0 = (tan(Ang_Y + Rrad)) * UL_Z

//Rotate offset to cartesian (+ y up +x right), rotate to mapping frame, apply to mapping frame
//Xoff1 = -1.00 * Yoff0
//Yoff1 = Xoff0

//Xoff2 = (Term1 * Xoff1) + (Term2 * Yoff1)
//Yoff2 = (Term3 * Xoff1) +(Term1 * Yoff1)

//NewX = UL_X + Xoff2
//NewY = UL_Y + Yoff2

 return [A,B,C,D,NewX,NewY];

}


func gen_cir_tiles(gga, src, dest, copyjgw=, toscript= ) {
/* DOCUMENT gen_cir_tiles, gga, src, dest, copyjgw=, toscript=

This function converts the cir image files (and corresponding world files)  from a "minute" directory into our regular 2k by 2k tiling format.

 Inputs: 
	gga:  "gps" or "pnav" data array for that mission day.
 	src : source directory where the cir files in the "minute" format  are stored.
	dest: destination directory.
	copyjgw = set to 1 to copy the corresponding jgw files along with the jpg files.  Set to 0 if you don't want the jgw files to be copied over. Default = 1.
        toscript = set to a path/filename and a shell script will be generated to do the actual copying
*/
   fix_dir, src;
   fix_dir, dest;
   default, copyjgw, 1;
   default, toscript, "";

   files = find(src, glob="*.jpg");
   files_sod = hms2sod(atoi(strpart(files, -13:-8)));
   
   utm_coords = fll2utm(gga.lat, gga.lon);
   north = utm_coords(1,);
   east = utm_coords(2,);
   zone = utm_coords(3,);
   utm_coords = [];

   if(strlen(toscript)) {
      f = open(toscript, "w");
      write, f, format="%s\n", "#!/bin/bash";
   }

   for(i = 1; i <= numberof(files); i++) {
      w = where(gga.sod == files_sod(i));
      if(numberof(w) == 1) {
         w = w(1);
         tte = int(east(w) / 2000.0) * 2000;
         ite = int(east(w) / 10000.0) * 10000;
         ttn = int(north(w) / 2000.0) * 2000 + 2000;
         itn = int(north(w) / 10000.0) * 10000 + 10000;
         ttile = swrite(format="t_e%d_n%d_%d/", tte, ttn, int(zone(i)));
         itile = swrite(format="i_e%d_n%d_%d/", ite, itn, int(zone(i)));
         fdir = dest + itile + ttile;
         if(strlen(toscript))
         cmd = "cp " + files(i) + " " + fdir;
         if(strlen(toscript)) {
            write, f, format="\necho %s - %d of %d\nmkdir -p %s\n%s\n", file_tail(files(i)), i, numberof(files), fdir, cmd;
         } else {
            mkdirp, fdir;
            system, cmd;
         }
         if (copyjgw) {
            jgwfile = file_rootname(files(i))+".jgw";
            if (file_exists(jgwfile)) {
               cmd = "cp " + jgwfile + " " + fdir; 
               if(strlen(toscript))
                  write, f, format="%s\n", cmd;
               else
                  system, cmd; 
            }
         }
         if(strlen(toscript) == 0 || ! (i % 100) || i == numberof(files))
            write, format="%d of %d copied\r", i, numberof(files);
      }
   }
   write, format="%s", "\n";
   if(strlen(toscript))
      close, f;
}

func copy_sod_cirs(sods, src, dest, copyjgw=, progress=) {
/* DOCUMENT copy_sod_cirs, sods, src, dest, copyjgw=, progress=

   Given an array of SOD values, this copies all corresponding CIR images
   located in src to dest.

   Set copyjgw=0 to disable copying of the associated jgw files (enabled by
   default). Set progress=0 to disable progress information (enabled by
   default).
*/
   fix_dir, src;
   fix_dir, dest;
   default, copyjgw, 1;
   default, progress, 1;
   mkdirp, dest;
   files = find(src, glob=swrite(format="*-%d-cir.jpg", sod2hms(sods, noary=1)));
   for(i = 1; i <= numberof(files); i++) {
      cmd = "cp " + files(i) + " " + dest;
      if(progress)
         cmd;
      system, cmd;
      if(copyjgw) {
         jgwfile = file_rootname(files(i))+".jgw";
         if(file_exists(jgwfile)) {
            cmd = "cp " + jgwfile + " " + dest;
            if(progress)
               cmd;
            system, cmd;
         }
      }
   }
}

func copy_gga_cirs(q, src, dest, copyjgw=, progress=) {
/* DOCUMENT copy_gga_cirs, q, src, dest, copyjgw=, progress=

   Given a where query result q, this will copy CIR images located in src that
   correspond to gga.sod(q) to the destination directory dest. This is useful
   in conjunction with the return value of points in polygon and similar tools.

   Set copyjgw=0 to disable copying of the associated jgw files (enabled by
   default). Set progress=0 to disable progress information (enabled by
   default).
*/
   extern gga;
   copy_sod_cirs, gga.sod(q), src, dest, copyjgw=copyjgw, progress=progress;
}

func tune_cir_parameters(photo_dir, date, fixed_roll=, fixed_pitch=, fixed_heading=, fixed_geoid=, mask=, start_temp=, min_temp=, cooling=, maxgen=, degrate=, params=, stdevs=, no_evolve=, pto_script=) {
/* DOCUMENT tune_cir_parameters, photo_dir, date, fixed_roll=, fixed_pitch=,
   fixed_heading=, fixed_geoid=, mask=, start_temp=, min_temp=, cooling=,
   maxgen=, degrate=, params=, stdevs=, no_evolve=, pto_script=

   Warning: This function is experimental!

   This is used to tune the parameters used to make JGWs for CIR images: roll,
   pitch, heading, and geoid. It tunes these parameters using an optimization
   algorithm that is similar to simulated annealing or evolution strategy
   (depending on the exact parameters used).

   The approach is thus:

      1. Find a subset of CIR images that overlap and contain several different
         flightlines. Alternately, find several such subsets of images. Put
         all of these images in a single directory. Try not to use more than
         a few hundred images; certainly no more ~500 images in most cases. As
         few as 20-30 can sometimes yeild results, though.

      2. Take these images to a Windows machine. Use autopano to generate
         control points for these images. You can find autopano here:
            http://autopano.kolor.com/
         Make sure you use autopano_v103 or later, as it is substantially
         improved over previous versions. The command you want to use to make
         control points is:
            autopano.exe /project:hugin /size:800 /keys:8
         You want to run that from within the image directory (from the Windows
         command line). It will generate one or more *.pto files. You can try
         different values for /size: and /keys:, but make sure /project:hugin
         is always set. See autopano's documentation for more information
         about that software.

      3. Optionally, open up each PTO file in Hugin to make sure the control
         points generated are good. You can find hugin here:
            http://hugin.sourceforge.net/
         You want to usually avoid having control points on bodies of waters,
         because they are typically not stable. Control points on shadows or
         vehicles or people are similarly not stable. Sometimes, good control
         points are difficult to find due to distortion and parallax. You can
         manually add and/or remove control points as desired, then save the
         files.

      3. Copy the *.pto files back to the linux machine and put them in a
         directory.  This can be the same directory as the images, or it can be
         a different directory. It doesn't matter.

      4. Run this function.

   You may have to try many different combinations of parameters to get good
   results, and you may have to run the function repeatedly, starting it with
   the last session's best result each time.

   The procedure of tuning the CIR parameters is a trial-and-error approach
   that may be trying to solve the wrong problem but still can yield improved
   results.  As such, you may not get good results. The RMSD given by this
   function for each set of parameters is a good guideline for how well the
   images in the subset fit together, but may not represent the dataset as a
   whole. Thus, it is important to test the tuned parameters against other
   images outside of the subset, preferably from other flightlines in the same
   mission day.

   Note that this essentially speeds up what would be done manually. Normally,
   you would tweak the four parameters manually, run the JGWs, then take a look
   at them to see if it improved things. This function requires a bit more
   setup time, but allows you to explore magnitudes more combinations of
   parameters in a much shorter time period.

   Sometimes, however, it does not work *AT ALL*. Sometimes, it will tell you
   that the roll is 50 degrees and the pitch is -80 and the heading is 90
   degrees.  This is your hint that you can't use the function to optimize
   those paramters.  Try fixing them at the default and just optimize the
   geoid. The geoid might be any value; it isn't usually the actual geoid
   because (at present) cir-mosaic's other functions generate jgw's without
   compensating for the actual elevation.  Eventually using the lidar data to
   do so will probably partly or largely obsolete this function.

   Parameters:
      photo_dir: The directory to the CIR photo subset.
      date: A string in MMDDYY format, where MM is the month minus 1.

   Options:
      fixed_roll= If specified, this forces the roll to the given fixed value.
      fixed_pitch= If specified, this forces the pitch to the given fixed
         value.
      fixed_heading= If specified, this forces the heading to the given fixed
         value.
      fixed_geoid= If specified, this forces the geoid to the given fixed
         value.
      mask= An array that indicates whether the jgw for the image at any given
         SOD should be generated (1) or not (0). The default is array(short(1),
         86400), which specifies that all images can have jgws generated.
      start_temp= The starting temperature. The temperature is multiplied by
         the random adjustments, so higher temperatures search a larger space
         more quickly but with less precision.
      min_temp= The lowest temperature that is permissible. Defaults to 0.01.
         If the temperature drops to low, then the adjustments become
         negligible.
      cooling= The rate at which the temperature cools. On each iteration, the
         temperature will be multiplied by the cooling factor. A value of 1
         disables cooling entirely. The default is 0.995.
      maxgen= The maximum number of no-improvement generates that can be run
         before termination. (When degrate is enabled, it's the number of
         no-new-best generations.) The default is 10000. Normally, you will
         probably use CTRL-C to interrupt the function long before it reaches
         the maximum generation.
      degrate= Specifies the degredation rate. If nonzero, this will allow the
         parameters to occasionally go from a better result to a worse result.
         The higher the degrate, the more likely this will happen. This might
         be helpful in avoiding local minima, but it comes at the expense of a
         much longer run time. The default is 0, which disables it.
      params= If provided, this specifies the combination of parameters that
         should be used at initialization. It should be an array of doubles as
         [roll, pitch, heading, geoid]. The default is to use the n111x biases
         for roll, pitch, and heading and to use -30.0 for the geoid. Using
         fixed parameters (such as fixed_roll) will override that part of this
         option.
      stdevs= The standard deviations to use when generating random adjustments
         for the parameters. This is an array of doubles that matches the
         params, where each element is the standard deviation to use for that
         parameter.  The random adjustments are generated from a standard
         normal distribution with mean=0 and the given standard deviation. The
         default is [0.25, 0.25, 0.25, 1.0].
      no_evolve= If set to 1, then no optimization takes place. Instead, it
         uses the given parameters to generate the jgws for the given photo
         directory, then stops.
      pto_script= The location of the script to use to determine the RMSM. The
         default is "./pto_cir.pl".
*/
   extern cir_mounting_bias;
   extern cir_mounting_bias_n111x;
   extern Geoid;

   default, start_temp, 1.0;
   default, min_temp, 0.01;
   default, cooling, 0.995;
   default, maxgen, 10000;
   default, degrate, 0.0;
   default, mask, array(short(1), 86400);
   default, stdevs, [0.25, 0.25, 0.25, 1.0];
   default, no_evolve, 0;

   default, pto_script, "./pto_cir.pl";

   use_fixed_roll    = !is_void(fixed_roll);
   use_fixed_pitch   = !is_void(fixed_pitch);
   use_fixed_heading = !is_void(fixed_heading);
   use_fixed_geoid   = !is_void(fixed_geoid);

   default, fixed_roll,    cir_mounting_bias_n111x.roll;
   default, fixed_pitch,   cir_mounting_bias_n111x.pitch;
   default, fixed_heading, cir_mounting_bias_n111x.heading;
   default, fixed_geoid,   -30.0;

   default, params, [fixed_roll, fixed_pitch, fixed_heading, fixed_Geoid];

   if(use_fixed_roll)
      params(1) = fixed_roll;
   cir_mounting_bias.roll = params(1);
   if(use_fixed_pitch)
      params(2) = fixed_pitch;
   cir_mounting_bias.pitch = params(2);
   if(use_fixed_heading)
      params(3) = fixed_heading;
   cir_mounting_bias.heading = params(3);
   if(use_fixed_geoid)
      params(4) = fixed_Geoid;
   Geoid = params(4);

   batch_gen_jgw_file, photo_dir, date, progress=no_evolve, mask=mask;

   if(no_evolve) return;

   cmd = pto_script + " " + photo_dir + " " + photo_dir + " ";
   rmse = 0.0;
   f = popen(cmd, 0);
   read, f, rmse;
   close, f;

   best = grow(rmse, params);
   write, "Initial state:";
   write, format=" %.4f - [%.4f,%.4f,%.4f,%.4f]\n", best(1), best(2), best(3), best(4), best(5);
   write, "";
   curr = best;

   stop = 0;
   allgen = 0;
   gen = 0;
   temperature = start_temp;
   do {
      allgen++;
      gen++;
      params = best(2:) + random_n(numberof(stdevs)) * stdevs * temperature;
      temperature *= cooling;
      temperature = [temperature, min_temp](max);

      if(use_fixed_roll)
         params(1) = fixed_roll;
      cir_mounting_bias.roll = params(1);
      if(use_fixed_pitch)
         params(2) = fixed_pitch;
      cir_mounting_bias.pitch = params(2);
      if(use_fixed_heading)
         params(3) = fixed_heading;
      cir_mounting_bias.heading = params(3);
      if(use_fixed_geoid)
         params(4) = fixed_Geoid;
      Geoid = params(4);

      batch_gen_jgw_file, photo_dir, date, progress=no_evolve, mask=mask;

      write, format="%s", ".";
      cmd = pto_script + " " + photo_dir + " " + photo_dir + " ";
      f = popen(cmd, 0);
      read, f, rmse;
      close, f;

      if(rmse < best(1)) {
         best = grow(rmse, params);
         gen = 0;
         write, "";
         write, "New best:";
         write, format=" %.4f - [%.4f,%.4f,%.4f,%.4f]\n", best(1), best(2), best(3), best(4), best(5);
      }
      if(rmse < curr(1) || random() < (rmse/curr(1) * degrate)) {
         if(deg_rate > 0) {
            write, "";
            if(rmse < curr(1))
               write, "Improvement:";
            else
               write, "Degredation:";
         }
         curr = grow(rmse, params);
         if(deg_rate > 0) {
            write, format=" %.4f - [%.4f,%.4f,%.4f,%.4f]\n", curr(1), curr(2), curr(3), curr(4), curr(5);
         }
      }

      if(gen >= maxgen) stop = 1;
   } while (!stop);
}
