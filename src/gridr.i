

/* 
   $Id$

*/

/* DOCUMENT 
*/


write,"$Id$"

require, "pnm.i"

func dgrid(w, ll, d, c, wd) {
  x0 = ll(1);
  x1 = ll(2);
  for ( y=ll(3); y<=ll(4); y+=d ) {
   pldj, x0,y,x1,y,color=c,width=wd;
  }

  y0 = ll(3);
  y1 = ll(4);
  for ( x=x0; x<=x1; x+=d ) {
   pldj, x,y0,x,y1,color=c,width=wd;
  }
}

func draw_grid( w ) {
/* DOCUMENT draw_grid(w)
 
   Draws a standard grid in window "w" using the windows current
 limits.  The grid outlines tiles in red, quads in dark gray, and 
 cells in light gray.

 For a description of tiles, quads, and cells type:
 help, show_grid_location.

 See also: tile_file_name, draw_grid, show_grid_location, dgrid
*/
 c = [200,200,200];
  if ( is_void(w) ) w = 5;
  old_w = window();
  window,w
  ll = int(limits()/2000) * 2000;
  ll(2) +=2000;
  ll(4) += 2000;
  if ((ll(4)-ll(3)) <= 4000) {
   dgrid, w, ll, 250, [200,200,200],0.1
   dgrid, w, ll, 1000,[120,120,120],0.1
  }
  if ((ll(4)-ll(3)) >= 8000) {
   ll = int(limits()/10000) * 10000;
   ll(2) +=10000;
   ll(4) += 10000;
   dgrid, w, ll, 2000,[250,140,140],3
   dgrid, w, ll, 10000, [170,120,170], 7
  } else {
    dgrid, w, ll, 2000,[250,140,140],5
  }
  window(old_w);
}

func tile_file_name(m) {
/* DOCUMENT tile_file_name(m)

   Determines the file name of a tile based on the input coords
  of "m".  

   Returns:  
      tilefn     A string containing the filename of the tile
                 which goes with the selected location.

 See also: tile_file_name, draw_grid, show_grid_location, dgrid
*/
tilefn = "";
  tile = tile_location(m);
  tilefn=swrite( format="%d-%d-tile.pbd", 
     tile(1)/1000, 
     tile(2)/1000
         );
  return tilefn;
}

func set_tile_filename(m, win=, nodata=) {
	extern curzone, tilename, finaldata, ifinaldata; 
	if (is_void(win)) win = window();
 	if (is_void(finaldata) && (!nodata)) {
	   write, "No finaldata found.  Cannot Save"
	   return
	}
 	window, win;
	if (is_void(m)) m = mouse(,,"Click in window:");
	emin = 2000*(int(m(1)/2000.));
	nmax = int(2000*(ceil(m(2)/2000.)));
	if (!nodata) {
	  ifinaldata = finaldata(data_box(finaldata.east/100.0, finaldata.north/100.0, emin, emin+2000, nmax-2000, nmax)); //Selects finaldata only from the clicked tile;

	  // find the unique elements in the ifinaldata array
	  ifinaldata = ifinaldata(sort(ifinaldata.rn));
	  idx = unique(ifinaldata.rn, ret_sort=1);
	  ifinaldata = ifinaldata(idx);
	  ymd = soe2ymd(ifinaldata.soe(where(ifinaldata.soe == min(ifinaldata.soe))));                                 // finds the year-month-day of the lowest SOE value;
	  if (ymd(2) <=9) m = swrite(format="0%d", ymd(2));
	  if (ymd(2) >9)  m = swrite(format="%d", ymd(2));
	  if (ymd(3) <=9) d = swrite(format="0%d", ymd(3));
	  if (ymd(3) >9)  d = swrite(format="%d", ymd(3));
	  mdate = swrite(format="%d%s%s", ymd(1), m, d);
        } else {
	  mdate = "yyyymmdd"
        }
	if (!curzone) {
		zone="void";
		write, "Please enter the current UTM zone: \n";
		read(zone); 
		curzone=0;
                sread(zone, format="%d", curzone);
	}
	zone = swrite(format="%d", long(curzone)); //Here zone was read as a string, converted to long and now back to string, but needed to make curzone global
	//zonel = utm_zone_letter(nmax); //gets zone letter from function in batch_process;
	type = "b"; //I still need to put in this part .. defaults to bathy for now.
	tilefname = swrite(format="t_e%d_n%d_%s_%s_%s_mf.pbd", emin, nmax, zone, mdate, type);
	temin = emin/1000;
	tnmax = nmax/1000;
	tmdate = strpart(mdate,5:);
	tilename = swrite(format="t_%d_%d_%s_%s_%s",temin,tnmax,zone,tmdate,type);
	
	if (_ytk) {
	  //send tilefname to tk
 	  tkcmd, swrite(format="set tilefname %s",tilefname);
 	  tkcmd, swrite(format="set tilename %s",tilename);
        }
	return tilefname;		
}

func tile_location(m) {
/* DOCUMENT tile_location(m)

   Return the tile location in a 2 element linear array.

  Inputs:
    	   m   What's returned by mouse();

 Returns:
          tile  A 2 element integet array containing the tile
                numbers.

 See also: tile_file_name, draw_grid, show_grid_location, dgrid
*/
 tile = array(int,2);
  tile(1) = int(m)(2) / 2000 * 2000;
  tile(2) = int(m)(1) / 2000 * 2000;
  return tile;
}

func show_grid_location(w,m) {
/* DOCUMENT show_grid_location(w,m)

   Draw a UTM grid on windw "w" centered on mouse position "m".
   If "m" is not given, this function will wait for a mouse click
   in window "w".  Defaults to window 5.  The standard block divisions
    are the tile, quad, and cell.  A tile is always 2x2km, a quad
    1x1km and each tile contains 4 quads.  There are 16 cells in each
    quad and each cell is 250x250 meters. Nothing smaller than a 
   tile is saves in disk files.
   

   Returns:
      An array describing the location as follows:

 Given the input array from mouse(): 
 [ 485913,4.23174e+06,
   485913, 4.23174e+06,
   0.552432,0.653899,
   0.552432,0.653899,
   1,1, 0
  ]

 It will return the following array containing the tile north,
 and east, the block north and east index, and the cell north
 and east index within the block.

  [4230000,484000,2,2,3,4]

 See also: tile_file_name, draw_grid, show_grid_location, dgrid

  
*/

  if ( is_void(w) ) w = 5;
  ltr = [["A","B"],["C","D"]];
  cells =[
          [1 , 2,  3,  4],
          [ 5, 6,  7,  8],
          [9, 10, 11, 12],
          [13,14, 15, 16]
         ];
  if ( is_void(m) ) 
      m = mouse();
  tilefname = set_tile_filename(m, nodata=1);
  im = int(m);
  tile  = tile_location(im);
  tilen = tile(1); 
  tilee = tile(2);
  itilee = tilee/10000 * 10000;
  itilen = tilen/10000 * 10000 + 10000;
  quadn = ((int(m)(2) - tilen ) / 1000 + 1);
  quade = ((int(m)(1) - tilee ) / 1000 + 1);
  celln =  ((im(2) - tilen - (quadn*1000 - 1000)) )/250 + 1;
  celle =  ((im(1) - tilee - (quade*1000 - 1000)) )/250 + 1;
  write, format="Index Tile: i_e%d_n%d\n",itilee, itilen;
  write, format="Tile File name will be %s\n", tilefname;
  write,format="Tile: E%d N%d Quad:%s Cell:%d\n", 
      tilee/1000 *1000, 
      (tilen+2000)/1000 *1000,
      ltr(quade,3-quadn), 
      cells(celle,5-celln);
  return [tilen,tilee,quadn,quade,celln,celle];
}

func slimits(w) {
  if ( is_void(w) ) w = 5;
  
}


/* DOCUMENT gridr(r)

   Bin and grid eaarl data.

   Inputs:
	&r	an "R" array.

   Returns:
	An array of pointers (img) where *img(1) contains the 
        utm coords. for the lower left corner and the upper right
        corner of the selection window. img(2) contains and array

   1) Requires and eaarl "point cloud" in window 5
   2) Click and drag out a rectangle in window 5 that you want
      to grid.

   See also:  fillin.i

   Original by W. Wright 6/7/2002
*/


func sel_grid_area( r ) {
/* DOCUMENT sel_grid_area( r ) 
*/
  w = window();
  window,5; 
  res=mouse(, 1);
  x = int(res(1:3:2));
  y = int(res(2:4:2));

  ll = [x(min), y(min)];
  ur = [x(max), y(max)];
 ll
 ur
  img = array( long, ur(1)-ll(1)+1, ur(2)-ll(2)+1 );


// Extract a list containing all the elements in the selection box
  q = where( (r).least > ll(1)*100 );
 qq = where( (r).least(q) < ur(1)*100 );
  q = q(qq);
 qq = where( (r).lnorth(q) > ll(2)*100 );
  q = q(qq);
 qq = where( (r).lnorth(q) < ur(2)*100 );
  q = q(qq);

// q now holds a list of all elements within the selection box

  x = int( (r).least(q)+50)/100 + 1;  	// add 50cm, then convert from cm to m
  y = int((r).lnorth(q)+50)/100 + 1;
  z = (r).lelv(q); 
 
z(max)
z(avg)
z(min)

// insert elevations into the grid array 
  for (i=1; i<=numberof(x); i++ ) { 
    img( x(i)-ll(1), y(i)-ll(2)) = z(i); 
    if ( (i % 1000) == 0 ) write, format="%d of %d\r", i, numberof(x) ;
  }


  window,w
  return [&ll, &ur, &img ]

}





