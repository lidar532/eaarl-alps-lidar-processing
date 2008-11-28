require, "eaarl.i";
write, "$Id$";

/*
  Orginal: 8/17/2002 C. Wayne Wright  wright@lidar.wff.nasa.gov
  
  Compute approximate elevation data for quick and dirty uses
  such as feeding rcf, or geo-refed waveforms.

  qde		A function to do a "quick and dirty" estimation
                of the surface. It takes an XRTRS structure for
                input.
 
*/
 
// The line interpolating heading needs to be done using x/y from a
// unit circle to work for norther headings.

 
   Hcvt = 2115.0;			// keys
   qde_vertical_offset = -1.09;		// vertical distance from
					// gps antenna to MCP
 
func qde( xr, centroid= ) {
/* DOCUMENT qde(  xr, scan=, centroid= )

  "qde" is Quick Dirty Elevation.

   xr		Input array of EAARL XRTRS values generated by
		irg.

*/
   rb = roll_bias * d2r;
   a = xr.sa / Hcvt * pi + rb;
   if ( centroid ) {
     rn = xr.raster(1)
     rast = decode_raster( get_erast( rn=rn ))
     np = dimsof(rast)(2);
     np = 120;
     prange = array(float, 4, np);
     for (i=1; i< np; i++ ) {
        write,format="i=%d np=%d\n", i,np
        prange(,i) = pcr( rast, i);
     }
     xr.irange(,1) = prange(1,) ;
     e = -(prange(1,) * NS2MAIR - range_bias) *  cos(a + xr.rroll ) * 
         cos(xr.rpitch + ops_conf.pitch_bias*d2r ) ;
   } else {
     e = -(xr.irange * NS2MAIR - range_bias) *  cos(a + xr.rroll ) * 
         cos(xr.rpitch + ops_conf.pitch_bias*d2r ) ;
   }
   ea = [ e + xr.alt - qde_vertical_offset, (xr.sa+3)/4 + 80 ];
   return ea;
}





func open_fscube( junk, invalid= ) {
/* DOCUMENT open_fscube()

   Returns a filter cube for use in spatial filtering first surface
  return data.

*/
   if ( is_void(invalid) ) 
	invalid = float(-32768);
   return ( array( invalid, 160, 9 ) );

}

func load_fscube( w, cube, invalid= ) {
/* DOCUMENT load_fscube(w, cube, invalid=)

   Put values into the filter cube.

   Inputs:
    w           Input array of raster data values. 
    cube        The data cube to insert w into.
    invalid     A value which indicates invalid data. (default -32768);

   Returns:
    cube        The data cube with the new values installed and the
                data shifted.

*/
   if ( is_void( invalid ) )
	invalid = float(-32768);
   n = dimsof(cube)(3);
   cube( , 2:n) = cube(, 1:n-1);	// shift cube data down one.    
   cube( , 1) = invalid;
   cube( int( w(,2) ), 1) = w(,1);
   return cube;
}

func f3x3(c, w) {

// Prime the filter cube with 9 samples from this 
// set if data.
   for (i=1; i<=9; i++  ) 
      load_fscube( w(, i, ), c);
   n = dimsof(w)(2);  			// get the number of rasters
    
    
}


func lsq(y,x) {
/* DOCUMENT lsq(y,x)
   Compute linear least squares on x and y giving the
   "a" and "b" terms in a return array.  A detailed 
   description of the method can be found at:

   http://www.efunda.com/math/leastsquares/lstsqr1dcurve.cfm

   The return value is an array [a,b] where the fitted line
   can be generated by:   y  = bx+a. 
   
*/
  sy  = y(sum);
  sx  = x(sum);
  sx2 = (x^2)(sum);
  sxy = (x*y)(sum);
  n = float(numberof(x));
  d = n * sx2 - sx^2;
  a = ( sy * sx2 - sx*sxy) / d;
  b = ( n*sxy - sx*sy) / d;
  return [ a, b ];
}

func d(start,stop, wn=) {
  if ( is_void(wn) )
	wn = 2.0;
 
  xx = [-.5, .5];
  animate,1;
  for (i=start; i<stop; i++) {
    s = *rcf( w(,i,1), wn, mode=2)(1);		// Find surface values.
    ns = indgen(1:120); 			// Find rejects.
    ns(s) = 0;					// Zero out good indexes.
    nsi = where(ns);
    fma;
    plmk, w(nsi,i,1), w(nsi,i,2), marker=3, color="black", msize=.2;
    plmk, w(s,i,1), w(s,i,2), marker=4, color="red";
    si = s(sort( s )) ;
    plg, w(si,i,1), w(si,i,2), marks=0, color="red";
    a = lsq( w(s, i, 1), w(s,i,2) );
    b = a(2); a=a(1);
    write,format="%f %f %f\n", w(s,i,1)(rms), a, b;
    plg, xx*b+a, xx, marks=0, color="blue"
  }
  animate,0;
}



