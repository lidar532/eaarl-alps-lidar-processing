/*
   $Id$
   */
   write, "$Id$"

struct GEO {
     long rn;
     long north;
     long east;
     short sr2;
     long elevation;
     long mnorth;
     long meast;
     long melevation;
     short bottom_peak;
     short first_peak;
     long bath;
     short depth;
     }

struct FS {
     long rn;
     long mnorth;
     long meast;
     long melevation;
     long north;
     long east;
     long elevation;
     short intensity;
     }

struct VEG {
     long rn;
     long north;
     long east;
     long elevation;
     long mnorth;
     long meast;
     long melevation;
     short felv;
     short fint;
     short lelv;
     short lint;
     char nx;
     }
func read_yfile (path, fname_arr=) {

/* DOCUMENT read_yfile(path, fname_arr=) 
This function reads an EAARL yorick-written binary file.
   amar nayegandhi 04/15/2002.
   Input parameters:
   path 	- Path name where the file(s) are located. Don't forget the '/' at the end of the path name.
   fname_arr	- An array of file names to be read.  This may be just 1 file name.
   Output:
   This function returns a an array of pointers.  Each pointer can be dereferenced like this:
   > data_ptr = read_yfile("~/input_files/")
   > data1 = *data_ptr(1)
   > data2 = *data_ptr(2)
   modified 10/01/02.  amar nayegandhi.
      - to include struct FS for first surface topography
      - add more documentation to this function.
   modified 10/17/02.  amar nayegandhi.
      - to include struct VEG for vegetation
   */

if (is_void(path)) {
   ifn  = get_openfn( initialdir="~/", filetype="*.bin *.edf", title="Open Data File" );
   if (ifn != "") {
     ff = split_path( ifn, 0 );
     path = ff(1);
     fname_arr = ff(2);
   } else {
    write, "No File chosen.  Return to main."
    return
   }
}

if (is_void(fname_arr)) {
   s = array(string, 1000);
   ss = "*.bin"
   scmd = swrite(format = "find %s -name '%s'",path, ss); 
   f=popen(scmd, 0); 
   n = read(f,format="%s", s ); 
   close, f;
   fn_arr = s(1:n);
} else { 
  fn_arr = path+fname_arr; 
  n = numberof(fn_arr);
  }

write, format="Number of files to read = %d \n", n

bytord = 0L;
type =0L;
nwpr = 0L;
recs = 0L;
byt_pos=0L;
data_ptr = array(pointer, n);

for (i=0;i<n;i++) {
  f=open(fn_arr(i), "r+b"); 
  _read, f, 0, bytord;
  if (bytord == 65535L) order = 1; else order = 0; 
  //read the output type of the file
  _read, f, 4, type;
  //read the number of words in each record
  _read, f, 8, nwpr;
  //read the total number of records
  _read, f, 12, recs;
  write, format="%d records to be read\n",recs;

  byt_pos = 16;
       
  //fill the array of data structures using the value of type.
  data_ptr(i) = &(data_struc(type, nwpr, recs, byt_pos, f));
  close, f;


 }
 write, format="All %d files read. \n",n;

return data_ptr;
}

func data_struc (type, nwpr, recs, byt_pos, f) {
  /* DOCUMENT data_struc(type, nwpr, recs, byt_pos, f).
     This function is used by read_yfile to define the structure depending on the data type.
     */

  if (type == 3) {
    rn = 0L;
    mnorth = 0L;
    meast = 0L;
    melevation = 0L;
    north = 0L;
    east = 0L;
    elevation = 0L;
    intensity = 0S;

    data = array(FS, recs); 
    for (i=0;i<recs;i++) {

       _read, f, byt_pos, rn;
       data(i).rn = rn;
       byt_pos = byt_pos + 4;

       _read, f, byt_pos, mnorth;
       data(i).mnorth = mnorth;
       byt_pos = byt_pos + 4;

       _read, f, byt_pos, meast;
       data(i).meast = meast;
       byt_pos = byt_pos + 4;

       _read, f, byt_pos, melevation;
       data(i).melevation = melevation;
       byt_pos = byt_pos + 4;

       _read, f, byt_pos, north;
       data(i).mnorth = north;
       byt_pos = byt_pos + 4;

       _read, f, byt_pos, east;
       data(i).east = east;
       byt_pos = byt_pos + 4;

       _read, f, byt_pos, elevation;
       data(i).elevation = elevation;
       byt_pos = byt_pos + 4;

       _read, f, byt_pos, intensity;
       data(i).intensity = intensity;
       byt_pos = byt_pos + 2;
    }
  }  

  if (type == 4) {

    rn = 0L;
    north = 0L;
    east = 0L;
    sr2 = 0S;
    bath = 0L;
    elevation=0L;
    mnorth=0L;
    meast=0L;
    melevation=0L;
    depth = 0S;
    bottom_peak = 0S;
    first_peak = 0S;
    sa = 0S;

    data = array(GEO, recs); 

    for (i=0;i<recs;i++) {

       _read, f, byt_pos, rn;
       data(i).rn = rn;
       byt_pos = byt_pos + 4;

       _read, f, byt_pos, north;
       data(i).north = north;
       byt_pos = byt_pos + 4;
       
       _read, f, byt_pos, east;
       data(i).east = east;
       byt_pos = byt_pos + 4;
       
       _read, f, byt_pos, sr2;
       data(i).sr2 = sr2;
       byt_pos = byt_pos + 2;

       _read, f, byt_pos, elevation;
       data(i).elevation = elevation;
       byt_pos = byt_pos + 4;

       _read, f, byt_pos, mnorth;
       data(i).mnorth = mnorth;
       byt_pos = byt_pos + 4;

       _read, f, byt_pos, meast;
       data(i).meast = meast;
       byt_pos = byt_pos + 4;
       
       _read, f, byt_pos, melevation;
       data(i).melevation = melevation;
       byt_pos = byt_pos + 4;

       _read, f, byt_pos, bottom_peak;
       data(i).bottom_peak = bottom_peak;
       byt_pos = byt_pos + 2;

       _read, f, byt_pos, first_peak;
       data(i).first_peak = first_peak;
       byt_pos = byt_pos + 2;
       
       _read, f, byt_pos, depth;
       data(i).depth = depth;
       byt_pos = byt_pos + 2;

    }
  }

  if (type == 5) {

    rn = 0L;
    north = 0L;
    east = 0L;
    elevation=0L;
    mnorth=0L;
    meast=0L;
    melevation=0L;
    felv = 0s;
    fint = 0s;
    lelv = 0s;
    lint = 0s;
    nx = ' ';


    data = array(VEG, recs); 

    for (i=0;i<recs;i++) {

       _read, f, byt_pos, rn;
       data(i).rn = rn;
       byt_pos = byt_pos + 4;

       _read, f, byt_pos, north;
       data(i).north = north;
       byt_pos = byt_pos + 4;
       
       _read, f, byt_pos, east;
       data(i).east = east;
       byt_pos = byt_pos + 4;
       
       _read, f, byt_pos, elevation;
       data(i).elevation = elevation;
       byt_pos = byt_pos + 4;

       _read, f, byt_pos, mnorth;
       data(i).mnorth = mnorth;
       byt_pos = byt_pos + 4;

       _read, f, byt_pos, meast;
       data(i).meast = meast;
       byt_pos = byt_pos + 4;
       
       _read, f, byt_pos, melevation;
       data(i).melevation = melevation;
       byt_pos = byt_pos + 4;

       _read, f, byt_pos, felv;
       data(i).felv = felv;
       byt_pos = byt_pos + 2;

       _read, f, byt_pos, fint;
       data(i).fint = fint;
       byt_pos = byt_pos + 2;

       _read, f, byt_pos, lelv;
       data(i).lelv = lelv;
       byt_pos = byt_pos + 2;

       _read, f, byt_pos, lint;
       data(i).lint = lint;
       byt_pos = byt_pos + 2;

       _read, f, byt_pos, nx;
       data(i).nx = nx;
       byt_pos = byt_pos + 1;

    }
  }

  return data;
}
  
func write_ascii_xyz(geoptr, opath=,ofname=,type=) {
  /* this function writes out an ascii file containing x,y,z information.
    amar nayegandhi 04/25/02
    */
  fn = opath+ofname;

  /* open file to read/write (it will overwrite any previous file with same name) */
  f = open(fn, "w");

  geoarr = *(geoptr)(1);
  totw = 0;

  /* now look through the geobath array of structures and write out only valid points */
  indx = where(geoarr.depth != -10000);   
  num_valid = numberof(indx);
  len = numberof(geoarr);
  for (i=1;i<=num_valid;i++) {
    if (type == 1) {
        /* this writes out xyz depth data */
         write, f, format="%9.2f  %10.2f  %8.2f \n",geoarr.east(indx(i))/100.,geoarr.north(indx(i))/100., geoarr.depth(indx(i))/100.;
	 totw++;
    }
    if (type == 2) {
        /* this writes out xyz topo data with the 4th word being first surface return intensity */
        write, f, format="%9.2f  %10.2f  %8.2f  %d \n", geoarr.east(indx(i))/100., geoarr.north(indx(i))/100., geoarr.elevation(indx(i))/100., geoarr.first_peak(indx(i));
	totw++;
    }
    if (type == 3) {
        /* this writes out xyz submerged topography data with the 4th word being bottom peak intensity return */
	bath = geoarr.elevation(indx(i))+geoarr.depth(indx(i));
        write, f, format="%9.2f  %10.2f  %8.2f %d \n",geoarr.east(indx(i))/100.,geoarr.north(indx(i))/100., bath/100., geoarr.bottom_peak(indx(i));
	 totw++;
    }
    if (type == 4) {
        /* this writes out xyz bottom subaerial topography with the 4th word being the bottom peak intensity */
	bottom_topo = geoarr.elevation(indx(i)) + geoarr.sr2(indx(i))*NS2MAIR;
        write, f, format="%9.2f  %10.2f  %8.2f %d \n",geoarr.east(indx(i))/100.,geoarr.north(indx(i))/100., bottom_topo/100., geoarr.bottom_peak(indx(i));
	 totw++;
    }

  }
  close, f;
  write, format="Total records written to ascii file = %d\n", totw;
}

func read_ascii_xyz(ipath=,ifname=,type=){
 /* this function reads in an xyz ascii file and returns a 3-d array.
    amar nayegandhi 05/01/02
    */

    fn = ipath+ifname
    /* open file to read */
    f = open(fn, "r");
    x=0.0;y=0.0;z=0.0;
    a = rdline(f);
    count = 0;
    
    while ((a > "")) {
      sread, a, x,y,z;
      if (count == 0) {
        arr = array(double, 3, 1);
	arr(1,1) = x;
	arr(2,1) = y;
	arr(3,1) = z;
	} else {
        grow, arr, [x,y,z];
      }
      count++;
      a=rdline(f);
    }

  return arr
}

func read_pointer_yfile(data_ptr, mode=) {
  // this function reads the data_ptr array from read_yfile.
  // select mode = 1 to merge all data files
  // amar nayegandhi 11/25/02.
  extern fs_all, depth_all, veg_all;
  data_out = [];

  if (!is_array(data_ptr)) return;
  if (mode == 1) {
    //merge all data files 
    for (i=1; i <= numberof(data_ptr); i++) {
       grow, data_out, (*data_ptr(i));
    }
  }
  a = structof(data_out);
  if (a == FS) {
    fs_all = data_out;
    if (_ytk) {
      tkcmd, swrite(format=".l1wid.bf4.1.p setvalue @%d",0);
    }
  }
  if (a == GEO) {
    depth_all = data_out;
    if (_ytk) {
      tkcmd, swrite(format=".l1wid.bf4.1.p setvalue @%d",1);
    }
  }
  if (a == VEG) {
    veg_all = data_out;
    if (_ytk) {
      tkcmd, swrite(format=".l1wid.bf4.1.p setvalue @%d",2);
    }
  }

}
    
    
