/* vim: set tabstop=3 softtabstop=3 shiftwidth=3 autoindent: */
/*
	Functions specific to camera images taken by boat
*/



struct BOAT_PICS {
	float lat;
	float lon;
	float depth;
	float heading;
	float somd;
}

func boat_create_lst(sdir=, relpath=, fname=, verbose=) {
/* DOCUMENT  boat_create_lst(sdir=, relpath=, fname=, verbose=)

	Creates a boat lst file for a directory's jpg's.

	The following parameters are required:

		n/a

	The following options are required:

		sdir= Directory the list file will be saved in.

	The following options are optional:

		relpath= The relative path from the sdir to the images. Default is "".

		fname= The filename to save the lst file as. Default is boat.lst.

		verbose= Indicates the verbosity level to run at.
			Default: 1
			Valid values:
				0 - No progress info
				1 - Limited progress information
				2 - Full progress information
				3 - Full progress information for this function
					and all called functions
				-1 - Explicitly request the default level
				-2 - No progress info for this or any called
					functions

	Function returns:

		n/a
*/
	/* Check for required options */
	if (is_void(sdir)) {
		write, "One or more required options not provided. See 'help, boat_create_lst'.";
		if(is_void(sdir)) write, "-> Missing 'sdir='.";
		return;
	}

	/* Validate the verbosity */
	if (!(is_array(verbose) && !dimsof(verbose)(1))) verbose = 1;
	if (verbose == -1) verbose = 1;
	verbose = int(verbose);
	
	/* Set called function verbosity */
	if(verbose == 3 || verbose == -2) {
		func_verbose = verbose;
	} else {
		func_verbose = -1;
	}
	
	/* Validate the sdir */
	if("/" != strpart(sdir, strlen(sdir):strlen(sdir))) {
		sdir = sdir + "/";
	}

	/* Validate the relpath */
	if(is_void(relpath)) {
		relpath = "";
	}
	if(0 < strlen(relpath) && "/" != strpart(relpath, strlen(relpath):strlen(relpath))) {
		relpath = relpath + "/";
	}


	/* Validate the fname */
	if(is_void(fname)) {
		fname = "boat.lst";
	}
								
								if(verbose >= 2) write, format="==> boat_create_lst(sdir=%s, relpath=%s, fname=%s, verbose=%i)\n", sdir, relpath, fname, verbose;

	cmd = "cd " + sdir + " > /dev/null; echo set camtype 2 > " + fname + "; find " + relpath + "*.jpg | sort >> " + fname + "; cd - > /dev/null"
								if(verbose >= 2) write, format=" cmd=%s\n", cmd;

	f = popen(cmd, 0);
	close, f;
								if(verbose >= 1) write, format="Created .lst file as %s%s\n", sdir, fname;

								if(verbose >= 2) write, format="--/ boat_create_lst%s", "\n";
}

func boat_rename_exif_files(indir=, outdir=, datestring=, move=, verbose=) {
/* DOCUMENT  boat_rename_exif_files(indir=, outdir=, datestring=, move=, verbose=)

	Renames the JPG files in a directory using their EXIF information. By
	default, all files are copied from indir to outdir using the new name,
	but this can be overridden to move them instead.

	NOTE: This will ONLY rename files that contain EXIF GPS time imformation. Any
	files that do not contain an EXIF GPS time stamp will be silently ignored.

	The following parameters are required:

		n/a

	The following options are required:

		indir= Input directory, containing the JPG images to be renamed. Must
			be a full path.

		outdir= Output directory, where the renamed JPG images will be placed.
			Must be a full path.

		datestring= A string representing the mission date. This string must be
			formatted as YYYY-MM-DD.

	The following options are optional:

		move= Set to any nonzero value to indicate that the file is to be moved
			instead of copied.

		verbose= Indicates the verbosity level to run at.
			Default: 1
			Valid values:
				0 - No progress info
				1 - Limited progress information
				2 - Full progress information
				3 - Full progress information for this function
					and all called functions
				-1 - Explicitly request the default level
				-2 - No progress info for this or any called
					functions

	Function returns:

		n/a
*/
	
	/* Check for required options */
	if (is_void(indir) || is_void(outdir) || is_void(datestring)) {
		write, "One or more required options not provided. See 'help, boat_rename_exif_files'.";
		if(is_void(indir)) write, "-> Missing 'indir='.";
		if(is_void(outdir)) write, "-> Missing 'outdir='.";
		if(is_void(datestring)) write, "-> Missing 'datestring='.";
		return;
	}

	/* Validate the verbosity */
	if (!(is_array(verbose) && !dimsof(verbose)(1))) verbose = 1;
	if (verbose == -1) verbose = 1;
	verbose = int(verbose);
	
	/* Set called function verbosity */
	if(verbose == 3 || verbose == -2) {
		func_verbose = verbose;
	} else {
		func_verbose = -1;
	}

	/* Validate move */
	if (move) {
		move = 1;
	} else {
		move = 0;
	}

	/* Validate and fix the indir and outdir to have trailing / */
	if("/" != strpart(indir, strlen(indir):strlen(indir))) {
		indir = indir + "/";
	}
	if("/" != strpart(outdir, strlen(outdir):strlen(outdir))) {
		outdir = outdir + "/";
	}

								if(verbose >= 2) write, format="==> boat_rename_exif_files(indir=%s, outdir=%s, datestring=%s, move=%i, verbose=%i)\n", indir, outdir, datestring, move, verbose;


	if(move == 1) {
		action = "mv";
								if(verbose >= 1) write, "Files will be moved.";
	} else {
		action = "cp";
								if(verbose >= 1) write, "Files will be copied.";
	}
	
	cmd = "exiflist -o l -f file-name,date-taken,gps-time " + indir + "*.jpg | perl -an -F',' -e 'chomp $F[1];chomp $F[2]; sub gettime {@temp=split/ /,shift(@_);return $temp[1];}; sub hms {return split/:/,shift(@_);}; @t=($F[2]?hms($F[2]):hms(gettime($F[1])));system \"" + action + " " + indir + "\" . $F[0] . \" " + outdir + "\" . substr($F[0], 0, length($F[0])-8) . \"_\" . \"" + datestring + "\" . \"_\" . sprintf(\"%02d\",$t[0]) . sprintf(\"%02d\",$t[1]) . sprintf(\"%02d\", $t[2]) . \"_\" . substr ($F[0], length($F[0])-8) . \"\\n\";';"

								if(verbose >= 2) write, format=" cmd=%s\n", cmd;

								if(verbose >= 1) write, "Starting rename process.";
	f = popen(cmd, 0);
	close, f;
								if(verbose >= 1) write, "Finished rename process.";

								if(verbose >= 2) write, format="--/ boat_rename_exif_files%s", "\n";
}

func boat_output(boat=, ofbase=, no_pdb=, no_txt=, no_gga=, verbose=) {
/* DOCUMENT  boat_output(boat=, ofbase=, no_pdb=, no_txt=, no_gga=, verbose=)

	Saves boat camera data in various formats. By default, saves in all three
	of pdb, txt, and gga. Save formats may be selectively disabled.

	The following parameters are required:

		n/a

	The following options are required:

		boat= Array of type BOAT_PICS, containing the data to
			be saved to the files.

		ofbase= Full path and the base of the file to save data as. This
			base will have ".txt" appended to save as a txt file, ".pdb"
			appended to save as pdb, and "-gga.ybin" appended to save as
			gga format.

	The following options are optional:

		no_pdb= Set to any non-zero value to disable the output of a
			pdb file.

		no_txt= Set to any non-zero value to disable the output of a
			txt file.

		no_gga= Set to any non-zero value to disable the output of a
			gga file.

		verbose= Indicates the verbosity level to run at.
			Default: 1
			Valid values:
				0 - No progress info
				1 - Limited progress information
				2 - Full progress information
				3 - Full progress information for this function
					and all called functions
				-1 - Explicitly request the default level
				-2 - No progress info for this or any called
					functions

	Function returns:

		n/a
*/
	/* Check for required options */
	if (is_void(boat) || is_void(ofbase)) {
		write, "One or more required options not provided. See 'help, boat_output'.";
		if(is_void(boat)) write, "-> Missing 'boat='.";
		if(is_void(ofbase)) write, "-> Missing 'ofbase='.";
		return;
	}

	/* Partially validate the ofname */
	if (dimsof(ofbase)(1)) {
		write, "An array was passed for ofbase, but only a scalar value is acceptable.\nSee 'help, boat_output'.";
		return;
	}

	/* Validate the verbosity */
	if (!(is_array(verbose) && !dimsof(verbose)(1))) verbose = 1;
	if (verbose == -1) verbose = 1;
	verbose = int(verbose);
	
	/* Set called function verbosity */
	if(verbose == 3 || verbose == -2) {
		func_verbose = verbose;
	} else {
		func_verbose = -1;
	}

	/* Validate no_pdb, no_txt, no_gga */
	if(no_pdb) { no_pdb = 1; } else { no_pdb = 0; }
	if(no_txt) { no_txt = 1; } else { no_txt = 0; }
	if(no_gga) { no_gga = 1; } else { no_gga = 0; }
	
								if(verbose >= 2) write, format="==> boat_output(boat=[%i], ofbase=%s, no_pdb=%i, no_txt=%i, no_gga=%i, verbose=%i)\n", numberof(boat), ofbase, no_pdb, no_txt, no_gga, verbose;

	if(! no_pdb) {
		boat_output_pdb, boat=boat, ofname=ofbase+".pdb", verbose=func_verbose;
	}
	if(! no_txt) {
		boat_output_txt, boat=boat, ofname=ofbase+".txt", verbose=func_verbose;
	}
	if(! no_gga) {
		boat_output_gga, boat=boat, ofname=ofbase+"-gga.ybin", verbose=func_verbose;
	}
								if(verbose >= 2) write, format="--/ boat_output%s", "\n";
}

func boat_output_gga(boat=, ofname=, verbose=) {
/* DOCUMENT  boat_output_gga(boat=, ofname=, verbose=)

	Saves boat camera data to a pseudo gga.ybin file.

	The following parameters are required:

		n/a

	The following options are required:

		boat= Array of type BOAT_PICS, containing the data to
			be saved to the gga.ybin file.

		ofname= Full path and file name to save data as.

	The following options are optional:

		verbose= Indicates the verbosity level to run at.
			Default: 1
			Valid values:
				0 - No progress info
				1 - Limited progress information
				2 - Full progress information
				3 - Full progress information for this function
					and all called functions
				-1 - Explicitly request the default level
				-2 - No progress info for this or any called
					functions

	Function returns:

		n/a
*/
	require, "rbgga.i";
	
	/* Check for required options */
	if (is_void(boat) || is_void(ofname)) {
		write, "One or more required options not provided. See 'help, boat_output_gga'.";
		if(is_void(boat)) write, "-> Missing 'boat='.";
		if(is_void(ofname)) write, "-> Missing 'ofname='.";
		return;
	}

	/* Partially validate the ofname */
	if (dimsof(ofname)(1)) {
		write, "An array was passed for ofname, but only a scalar value is acceptable.\nSee 'help, boat_output_gga'.";
		return;
	}

	/* Validate the verbosity */
	if (!(is_array(verbose) && !dimsof(verbose)(1))) verbose = 1;
	if (verbose == -1) verbose = 1;
	verbose = int(verbose);
	
	/* Set called function verbosity */
	if(verbose == 3 || verbose == -2) {
		func_verbose = verbose;
	} else {
		func_verbose = -1;
	}
	
								if(verbose >= 2) write, format="==> boat_output_gga(boat=[%i], ofname=%s, verbose=%i)\n", numberof(boat), ofname, verbose;

	num = numberof(boat);

	f = open(ofname, "w+b");
								if(verbose >= 2) write, format="   Binary file %s opened\n", ofname;
		
	byt_pos = 0;
	_write, f, byt_pos, int(num);
								if(verbose >= 2) write, format="   Wrote %d at %d\n", num, byt_pos;
	byt_pos += sizeof(int);
		
	for(j = 1; j <= num; j++) {
								if(verbose >= 2) write, format="   Record %d:\n", j;
		_write, f, byt_pos, float(boat.somd(j));
								if(verbose >= 2) write, format="     Wrote %f at %d\n", boat.somd(j), byt_pos;
		byt_pos += sizeof(float);
		_write, f, byt_pos, float(boat.lat(j));
								if(verbose >= 2) write, format="     Wrote %f at %d\n", boat.lat(j), byt_pos;
		byt_pos += sizeof(float);
		_write, f, byt_pos, float(boat.lon(j));
								if(verbose >= 2) write, format="     Wrote %f at %d\n", boat.lon(j), byt_pos;
		byt_pos += sizeof(float);
		_write, f, byt_pos, float(boat.depth(j));
								if(verbose >= 2) write, format="     Wrote %f at %d\n", boat.depth(j), byt_pos;
		byt_pos += sizeof(float);

								if(verbose == 1) write, format="   Wrote record %d of %d\r", j, num;
	}

	close, f;
								if(verbose == 1) write, format="%s", "\n";
								if(verbose >= 2) write, "  Binary file closed.";
								if(verbose == 1) write, format=" Binary gga file written to %s.\n", ofname;
								if(verbose >= 2) write, format="--/ boat_output_gga%s", "\n";
}

func boat_output_txt(boat=, ofname=, verbose=) {
/* DOCUMENT  boat_output_gga(boat=, ofname=, verbose=)

	Saves boat camera data to a text file, used by sf_a.tcl.

	The following parameters are required:

		n/a

	The following options are required:

		boat= Array of type BOAT_PICS, containing the data to
			be saved to the text file.

		ofname= Full path and file name to save data as.

	The following options are optional:

		verbose= Indicates the verbosity level to run at.
			Default: 1
			Valid values:
				0 - No progress info
				1 - Limited progress information
				2 - Full progress information
				3 - Full progress information for this function
					and all called functions
				-1 - Explicitly request the default level
				-2 - No progress info for this or any called
					functions

	Function returns:

		n/a
*/
	require, "dir.i";
	
	/* Check for required options */
	if (is_void(boat) || is_void(ofname)) {
		write, "One or more required options not provided. See 'help, boat_output_txt'.";
		if(is_void(boat)) write, "-> Missing 'boat='.";
		if(is_void(ofname)) write, "-> Missing 'ofname='.";
		return;
	}

	/* Partially validate the ofname */
	if (dimsof(ofname)(1)) {
		write, "An array was passed for ofname, but only a scalar value is acceptable.\nSee 'help, boat_output_txt'.";
		return;
	}

	/* Validate the verbosity */
	if (!(is_array(verbose) && !dimsof(verbose)(1))) verbose = 1;
	if (verbose == -1) verbose = 1;
	verbose = int(verbose);
	
	/* Set called function verbosity */
	if(verbose == 3 || verbose == -2) {
		func_verbose = verbose;
	} else {
		func_verbose = -1;
	}
	
								if(verbose >= 2) write, format="==> boat_output_txt(boat=[%i], ofname=%s, verbose=%i)\n", numberof(boat), ofname, verbose;
	
	somd = floor(boat.somd);
	s = int(somd % 60);
	somd = (somd - s)/60;
	m = int(somd % 60);
	h = int((somd - m)/60);
	somd = [];

								if(verbose >= 2) write, format=" Writing to file %s\n", ofname;
	f = open(ofname, "w")
	write, f, format="%02i%02i%02i,%f,%f,%f\n", h,m,s, boat.lat*100, boat.lon*100, boat.depth;
	close, f;

								if(verbose == 1) write, format=" Text file written to %s.\n", ofname;
								if(verbose >= 2) write, format="--/ boat_output_txt%s", "\n";
}

func boat_output_pdb(boat=, ofname=, verbose=) {
/* DOCUMENT  boat_output_pdb(boat=, ofname=, verbose=)

	Saves boat camera data to a Yorick pdb file.

	The following parameters are required:

		n/a

	The following options are required:

		boat= Array of type BOAT_PICS, containing the data to
			be saved to the pdb file.

		ofname= Full path and file name to save data as.

	The following options are optional:

		verbose= Indicates the verbosity level to run at.
			Default: 1
			Valid values:
				0 - No progress info
				1 - Limited progress information
				2 - Full progress information
				3 - Full progress information for this function
					and all called functions
				-1 - Explicitly request the default level
				-2 - No progress info for this or any called
					functions

	Function returns:

		n/a
*/
	require, "compare_transects.i";
	require, "dir.i";
	
	/* Check for required options */
	if (is_void(boat) || is_void(ofname)) {
		write, "One or more required options not provided. See 'help, boat_output_pdb'.";
		if(is_void(boat)) write, "-> Missing 'boat='.";
		if(is_void(ofname)) write, "-> Missing 'ofname='.";
		return;
	}

	/* Partially validate the ofname */
	if (dimsof(ofname)(1)) {
		write, "An array was passed for ofname, but only a scalar value is acceptable.\nSee 'help, boat_output_pdb'.";
		return;
	}

	/* Validate the verbosity */
	if (!(is_array(verbose) && !dimsof(verbose)(1))) verbose = 1;
	if (verbose == -1) verbose = 1;
	verbose = int(verbose);
	
	/* Set called function verbosity */
	if(verbose == 3 || verbose == -2) {
		func_verbose = verbose;
	} else {
		func_verbose = -1;
	}
	
	/* Variable name to save to file as */
	vname = "boat_data";

								if(verbose >= 2) write, format="==> boat_output_pdb(boat=[%i], ofname=%s, verbose=%i)\n", numberof(boat), ofname, verbose;

								if(verbose >=1) write, "Writing PBD file.";
	f = createb(ofname);
	add_variable, f, -1, vname, structof(boat), dimsof(boat);
	get_member(f, vname) = boat;
	save, f, vname;
	close, f; 
								if(verbose >=1) write, format=" PBD file written to %s as %s.\n", ofname, vname;
								if(verbose >= 2) write, format="--/ boat_output_pdb%s", "\n";
}

func boat_merge_datasets(boatA, boatB, verbose=) {
/* DOCUMENT  boat_merge_datasets(boatA, boatB, verbose=)

	Combines two arrays of type BOAT_PICS. Both arrays should be
	ordered chronologically. The returned array of BOAT_PICS will
	also be ordered chronologically.

	NOTE: If the two arrays are from two different days, they will
	not be properly ordered chronologically as the BOAT_PICS struct
	only contains the SOMD, not the date.

	The following parameters are required:

		boatA: Array of type BOAT_PICS.

		boatB: Array of type BOAT_PICS.

	The following options are required:

		n/a

	The following options are optional:

		verbose= Indicates the verbosity level to run at.
			Default: 1
			Valid values:
				0 - No progress info
				1 - Limited progress information
				2 - Full progress information
				3 - Full progress information for this function
					and all called functions
				-1 - Explicitly request the default level
				-2 - No progress info for this or any called
					functions

	Function returns:

		Array of type BOAT_PICS.
*/
	
	/* Validate the verbosity */
	if (!(is_array(verbose) && !dimsof(verbose)(1))) verbose = 1;
	if (verbose == -1) verbose = 1;
	verbose = int(verbose);
	
	/* Set called function verbosity */
	if(verbose == 3 || verbose == -2) {
		func_verbose = verbose;
	} else {
		func_verbose = -1;
	}
	
								if(verbose >= 2) write, format="==> boat_merge_datasets(boatA:[%i], boatB:[%i], verbose=%i)\n", numberof(boatA), numberof(boatB), verbose;

	new_boat = array(BOAT_PICS, numberof(boatA) + numberof(boatB));
								if(verbose >= 2) write, format=" new_boat's size is %i\n", numberof(new_boat);

	a = 1; b = 1; i = 1;
	
								if(verbose == 1) write, "Merging datasets...";
								if(verbose >= 2) write, "Looping through both boatA and boatB.";
	while(a <= numberof(boatA) && b <= numberof(boatB)) {
								if(verbose >= 2) write, format=" a=%i b=%i c=%i  ", a, b, i;
		if(boatA(a).somd < boatB(b).somd) {
								if(verbose >= 2) write, format="Copied from boatA.%s", "\n";
			new_boat(i) = boatA(a);
			i++;
			a++;
		} else {
								if(verbose >= 2) write, format="Copied from boatB.%s", "\n";
			new_boat(i) = boatB(b);
			i++;
			b++;
		}
	}

								if(verbose >= 2) write, "Looping through boatA.";
	while(a <= numberof(boatA)) {
								if(verbose >= 2) write, format=" a=%i b=%i c=%i  ", a, b, i;
								if(verbose >= 2) write, format="Copied from boatA.%s", "\n";
		new_boat(i) = boatA(a);
		i++;
		a++;
	}
	
								if(verbose >= 2) write, "Looping through boatB.";
	while(b <= numberof(boatB)) {
								if(verbose >= 2) write, format=" a=%i b=%i c=%i  ", a, b, i;
								if(verbose >= 2) write, format="Copied from boatB.%s", "\n";
		new_boat(i) = boatB(b);
		i++;
		b++;
	}
								if(verbose == 1) write, "Finished merging datasets.";
								if(verbose >= 2) write, format="--/ boat_merge_datasets%s", "\n";
	return new_boat;

}

func boat_combine_depth_gps(depth=, gps=, verbose=) {
/* DOCUMENT  boat_combine_depth_gps(depth=, gps=, verbose=)

	Adds depth information from an array of BOAT_PICS to the GPS information
	in an array of BOAT_PICS and returns an array of BOAT_PICS. Depth info is
	interpolated for each possible GPS location.

	The following parameters are required:

		n/a

	The following options are required:

		depth= Array of type BOAT_PICS. Fields somd and depth
			must contain valid data.

		gps= Array of type BOAT_PICS. All data except depth
			will be preserved and returned from this array.

	The following options are optional:

		verbose= Indicates the verbosity level to run at.
			Default: 1
			Valid values:
				0 - No progress info
				1 - Limited progress information
				2 - Full progress information
				3 - Full progress information for this function
					and all called functions
				-1 - Explicitly request the default level
				-2 - No progress info for this or any called
					functions

	Function returns:

		Array of type BOAT_PICS.
*/
	
	/* Check for required options */
	if (is_void(depth) || is_void(gps)) {
		write, "One or more required options not provided. See 'help, boat_combine_depth_gps'.";
		if(is_void(depth)) write, "-> Missing 'depth='.";
		if(is_void(gps)) write, "-> Missing 'gps='.";
		return;
	}

	/* Validate the verbosity */
	if (!(is_array(verbose) && !dimsof(verbose)(1))) verbose = 1;
	if (verbose == -1) verbose = 1;
	verbose = int(verbose);
	
	/* Set called function verbosity */
	if(verbose == 3 || verbose == -2) {
		func_verbose = verbose;
	} else {
		func_verbose = -1;
	}
	
								if(verbose >= 2) write, format="==> boat_combine_depth_gps(depth=[%i], gps=[%i], verbose=%i)\n", numberof(depth), numberof(gps), verbose;

	/* d is where we are at with depth; g is where we are at with gps */
	d = 1; g = 1;
								if(verbose >= 2) write, format=" d=%i g=%i\n", d, g;

	/* Make sure the first GPS is bigger than the first depth */
	while(depth(d).somd > gps(g).somd && d <= numberof(depth) && g <= numberof(gps)) {
		g++;
								if(verbose >= 2) write, format=" d=%i g=%i\n", d, g;
	}
	
	while(d <= numberof(depth) && g <= numberof(gps)) {
								if(verbose == 1) write, format=" Interpolating depth for GPS location %i of %i.\r", g, numberof(gps);
		
		/* Set d to the first depth bigger than the current GPS */
		while(d <= numberof(depth) && depth(d).somd < gps(g).somd) {
			d++;
								if(verbose >= 2) write, format=" d=%i g=%i\n", d, g;
		}
		
		/* Figure out how far in time the GPS is from d-1 to d, then interpolate a depth */
		if(d <= numberof(depth)) {
			ratio = (gps(g).somd - depth(d-1).somd)/(depth(d).somd - depth(d-1).somd);
								if(verbose >= 2) write, format="   ratio=%d ", ratio;
			gps(g).depth = depth(d-1).depth + ratio * (depth(d).depth - depth(d-1).depth);
								if(verbose >= 2) write, format="   depth=%d\n", gps(d).depth;
		
			g++;
								if(verbose >= 2) write, format=" d=%i g=%i\n", d, g;
		}
	}
								if(verbose == 1) write, format="%s", "\n";
								if(verbose >= 2) write, format="--/ boat_combine_depth_gps%s", "\n";
	return gps;
}

func boat_apply_offset(boat=, h=, m=, s=, verbose=) {
/* DOCUMENT  func boat_apply_offset(boat=, h=, m=, s=, verbose=)

	Applies a time offset to a boat dataset. Useful for changing
	time zones.

	The following parameters are required:

		n/a

	The following options are required:

		boat= The boat dataset to which the offset will be applied.

	The following options are optional:

		h= Number of hours to offset.

		m= Number of minutes to offset.

		s= Number of seconds to offset.

		verbose= Indicates the verbosity level to run at.
			Default: 1
			Valid values:
				0 - No progress info
				1 - Limited progress information
				2 - Full progress information
				3 - Full progress information for this function
					and all called functions
				-1 - Explicitly request the default level
				-2 - No progress info for this or any called
					functions

	Function returns:

		Array of type BOAT_PICS
*/
	
	/* Check for required options */
	if (is_void(boat)) {
		write, "One or more required options not provided. See 'help, boat_apply_offset'.";
		if(is_void(boat)) write, "-> Missing 'boat='.";
		return;
	}

	/* Validate the verbosity */
	if (!(is_array(verbose) && !dimsof(verbose)(1))) verbose = 1;
	if (verbose == -1) verbose = 1;
	verbose = int(verbose);
	
	/* Set called function verbosity */
	if(verbose == 3 || verbose == -2) {
		func_verbose = verbose;
	} else {
		func_verbose = -1;
	}

	/* Validate h, m, s */
	if(is_void(h)) { h = 0; }
	if(is_void(m)) { m = 0; }
	if(is_void(s)) { s = 0; }

									if(verbose >= 2) write, format="==> boat_apply_offset(boat=[%i], h=%i, m=%i, s=%i, verbose=%i)\n", numberof(boat), h, m, s, verbose;

	offset = (h * 60 + m) * 60 + s;
									if(verbose >= 1) write, format=" Offset is %i seconds.\n", offset;
	
	if(offset == 0) {
									if(verbose >= 1) write, "An offset of zero seconds doesn't affect anything.\n Perhaps you meant to specify 'h=', 'm=', or 's='?";
	} else {
		boat.somd = boat.somd + offset;
	}

								if(verbose >= 2) write, format="--/ boat_apply_offset%s", "\n";
	return boat;
}

func boat_gps_smooth(boat, lat, lon, step, verbose=) {
/* DOCUMENT  boat_gps_smooth(boat, lat, lon, step, verbose=)

	Applies a smoothing algorithm to the boat data to help even
	out the GPS information. This is necessary due to the motion
	of the boat due to waves and other such factors for which bias
	information is unavailable. The lat and lon variables are to
	contain the GPS information; any latitude and longitude info
	that is already in boat is disregarded and replaced.

	The following parameters are required:

		boat: Array of type BOAT_PICS, containing the data to
			which the smoothed lat/lon data will be added. (Any
			lat/lon information already in boat will be replaced
			using the data from lat and lon, see above.)

		lat: Array of latitude values to process, with index
			values corresponding to the indexes of boat.

		lon: Array of longitude values, like lat.

		step: The step value used by avgline to make smoothed
			values.

	The following options are required:

		n/a

	The following options are optional:

		verbose= Indicates the verbosity level to run at.
			Default: 1
			Valid values:
				0 - No progress info
				1 - Limited progress information
				2 - Full progress information
				3 - Full progress information for this function
					and all called functions
				-1 - Explicitly request the default level
				-2 - No progress info for this or any called
					functions

	Function returns:

		Array of type BOAT_PICS
*/
	require, "compare_transects.i";
	require, "ll2utm.i";

	/* Validate the verbosity */
	if (!(is_array(verbose) && !dimsof(verbose)(1))) verbose = 1;
	if (verbose == -1) verbose = 1;
	verbose = int(verbose);
	
	/* Set called function verbosity */
	if(verbose == 3 || verbose == -2) {
		func_verbose = verbose;
	} else {
		func_verbose = -1;
	}

									if(verbose >= 2) write, format="==> boat_gps_smooth(boat:[%i], lat:[%i], lon:[%i], step:%i, verbose=%i)\n", numberof(boat), numberof(lat), numberof(lon), step, verbose;

									if(verbose >= 2) write, format=" Step = %i\n", step;
	av1 = avgline(lat, lon, step=step);
									if(verbose >= 2) write, "First average line contructed from geo locations.";
	av2 = avgline(lat(step/2+1:), lon(step/2+1:), step=step);
									if(verbose >= 2) write, "Second average line constructed from geo locations.";

	av = array(float, numberof(av1(,1)) + numberof(av2(,1)), 2);
									if(verbose >= 2) write, "Second average line constructed from geo locations.";
		
	av(1::2,) = av1;
									if(verbose >= 2) write, "Spliced first average line into consolidated average.";
	av(2::2,) = av2;
									if(verbose >= 2) write, "Spliced second average line into consolidated average.";
	av1 = av2 = [];
	
	av_lat = av(,1);
	av_lon = av(,2);
									if(verbose >= 1) write, format=" Lat-Lon average line calculated, %d locations.\n", numberof(av_lat);

	av = [];
		
	av_somd = array(double, numberof(av_lat));
	av_somd(1::2) = boat.somd(1+step/2:(numberof(boat.somd)/step)*step:step);
	av_somd(2::2) = boat.somd(1+2*(step/2):((numberof(boat.somd)-step/2)/step)*step+step/2:step);
									if(verbose >= 2) write, format=" SOMD array created to match avg line, %d entries.\n", numberof(av_somd);

	/* Line-fit GPS coordinates before first pair of avg'd points */
	cur_av = 1;
		
									if(verbose >= 2) write, format=" Looping through GPS coordinates to fit to line, initial set%s", "\n";
		
	spanstart = 1;
	
	for(i = 1; i <= numberof(boat); i++) {
		
		if(boat.somd(i) >= av_somd(cur_av+1)) cur_av++;
		if(cur_av > numberof(av_somd)-1) cur_av = numberof(av_somd) - 1;

									if((verbose == 1 && (i % 197 == 0 || i == numberof(boat)))) write, format=" Looping through GPS coordinates to fit to line, %d of %d.\r", i, numberof(boat);


		intersection = perpendicular_intercept(av_lat(cur_av), av_lon(cur_av), av_lat(cur_av+1), av_lon(cur_av+1), lat(i), lon(i));
		boat.lat(i) = intersection(1);
		boat.lon(i) = intersection(2);
									if(verbose >= 2) write, format="     %d: Geo (%.2f,%.2f)", i, boat.lat(i), boat.lon(i);
									if(verbose == 2) write, format="%s", " - ";
									if(verbose == 3) write, format="%s", "\n";
		boat.heading(i) = calculate_heading(av_lon(cur_av), av_lat(cur_av), av_lon(cur_av+1), av_lat(cur_av+1), verbose=func_verbose);
									if(verbose == 3) write, format="     %d: ", i;
									if(verbose >= 2) write, format="Heading %.2f\n", boat.heading(i);

		}

									if(verbose >= 1) write, format="%s", "\n\n";
									if(verbose >= 1) write, format=" Data processed for %d locations.\n\n", numberof(boat);

								if(verbose >= 2) write, format="--/ boat_gps_smooth%s", "\n";
	return boat;
}

func boat_input_edt(ifname=, utmzone=, step=, depthonly=, verbose=) {
/* DOCUMENT  boat_input_edt(ifname=, utmzone=, step=, depthonly=, verbose=)

	Reads an EDT file (from Hypack) parsing depth, time, and GPS information
	to be returned as an array of BOAT_PICS.

	The following parameters are required:

		n/a

	The following options are required:

		ifname= Full path and file name of the EDT file to be processed.

		utmzone= The UTM zone number corresponding to this dataset.

	The following options are optional:

		step= Step value used by boat_smoooth_gps to smooth GPS data. Default
			is 8. -1 will force the default. Values less than 2 will be changed
			to 2.

		depthonly= Set to any nonzero value to indicate that only the depth
			information is needed. This will disregard latitude and longitude
			data, causing the function to run more quickly. (This is used
			when the GPS information is being pulled from the EXIF headers.)

		verbose= Indicates the verbosity level to run at.
			Default: 1
			Valid values:
				0 - No progress info
				1 - Limited progress information
				2 - Full progress information
				3 - Full progress information for this function
					and all called functions
				-1 - Explicitly request the default level
				-2 - No progress info for this or any called
					functions

	Function returns:

		Array of type BOAT_PICS
*/
	require, "compare_transects.i";
	require, "dir.i";
	require, "ll2utm.i";
	
	/* Check for required options */
	if (is_void(ifname) || is_void(utmzone)) {
		write, "One or more required options not provided. See 'help, boat_input_edt'.";
		if(is_void(ifname)) write, "-> Missing 'ifname='.";
		if(is_void(utmzone)) write, "-> Missing 'utmzone='.";
		return;
	}

	/* Validate utmzone */
	utmzone = int(utmzone);
	if( !( utmzone>=1 && utmzone<=60 ) ){
		write, "An invalid utmzone was entered. UTM zones are numbered 1 to 60.\nSee 'help, boat_input_edt'.";
		return;
	}

	/* Validate the verbosity */
	if (!(is_array(verbose) && !dimsof(verbose)(1))) verbose = 1;
	if (verbose == -1) verbose = 1;
	verbose = int(verbose);
	
	/* Set called function verbosity */
	if(verbose == 3 || verbose == -2) {
		func_verbose = verbose;
	} else {
		func_verbose = -1;
	}

	/* Validate the step */
	if (!step || step == -1) step = 8;
	if (step < 2) step = 2;
	step = int(ceil(step));

	/* Validate depthonly */
	if (depthonly) {
		depthonly = 1;
	} else {
		depthonly = 0;
	}

									if(verbose >= 2) write, format="==> boat_input_edt(ifname=%s, utmzone=%i, step=%i, depthonly=%i, verbose=%i)\n", ifname, utmzone, step, depthonly, verbose;


								if(verbose >= 2) write, format=" step set to %i\n", step;

	/* Create a mini bash/Perl script that will assist in reading in the data file. 
		
		Cat the contents of the file through word count to get the line count of the file.
		Then cat the contents of the file. Pipe both through the perl script. Perl loops
		and autosplits around STDIN (-an). It initializes a flag $f to 0. If $f is zero,
		it sets the line count $l to the first value on the line and increments $f. If
		$f is 1, a temporary counter is incremented to keep track of how many header lines
		there are, and if the current line is 5 "at" signs, the flag gets incremented and
		the difference between the file's line count and the header line count is printed
		(which will correspond to the number of lines that follow). If $f is any other
		value (such as 2) then the 2nd, 3rd, 4th, and 7th columns of the data are printed,
		space separated.
	*/
	cmd = "((cat " + ifname + " | wc -l); cat " + ifname + ") | perl -ane 'BEGIN{$f=0}if($f==0){$l=$F[0];$f++}elsif($f==1){$c++;if($F[0] =~ /@@@@@/){$f++;print $l-$c.\"\\n\"}}else{print \"$F[1] $F[2] $F[3] $F[6]\\n\"}'";
	
	f = popen(cmd, 0);
								if(verbose >= 2) write, format=" Pipe opened to %s\n", cmd;
	cmd = [];
	
	num = 1;
								if(verbose >= 2) write, "Reading data from file.";
	read, f, format="%d", num;
								if(verbose >= 2) write, format=" Number of entries assigned as %d\n", num;
	
	data_north = array(float, num);
	data_east = array(float, num);
	data_depth = array(float, num);
	data_somd = array(float, num);
	
	read, f, format="%f %f %f %f", data_east, data_north, data_depth, data_somd;
								if(verbose >= 1) write, format=" EDT data file read in, %d entries.\n", numberof(data_somd);
	
	close, f;
								if(verbose >= 2) write, "Pipe closed.";

	boat = array(BOAT_PICS, num);
	boat.somd = data_somd;
	boat.depth = data_depth;
	num = data_depth = data_somd = [];
								if(verbose >= 2) write, "Depth and somd data transferred to structure.";
	
	if( depthonly == 0 ) {
	
		latlon = utm2ll(data_north, data_east, utmzone);
		data_lat = latlon(, 2);
		data_lon = latlon(, 1);
		boat = boat_gps_smooth(boat, data_lat, data_lon, step, verbose=func_verbose);
	} else {
		boat.lat = 0;
		boat.lon = 0;
	}
	
								if(verbose >= 2) write, format="--/ boat_input_edt%s", "\n";
	return boat;
}

func boat_input_exif(ifdir=, step=, verbose=) {
/* DOCUMENT  boat_input_exif(ifdir=, step=, verbose=)

	Scans the JPG images in a directory, parsing time and GPS information
	to be returned as an array of BOAT_PICS.

	The following parameters are required:

		n/a

	The following options are required:

		ifdir= Full path of directory containing JPG images to be scanned.

	The following options are optional:

		step= Step value used by boat_smoooth_gps to smooth GPS data. Default
			is 8. -1 will force the default. Values less than 2 will be changed
			to 2.

		verbose= Indicates the verbosity level to run at.
			Default: 1
			Valid values:
				0 - No progress info
				1 - Limited progress information
				2 - Full progress information
				3 - Full progress information for this function
					and all called functions
				-1 - Explicitly request the default level
				-2 - No progress info for this or any called
					functions

	Function returns:

		Array of type BOAT_PICS
*/
	require, "dir.i";
	
	/* Check for required options */
	if (is_void(ifdir)) {
		write, "One or more required options not provided. See 'help, boat_input_exif'.";
		if(is_void(ifdir)) write, "-> Missing 'ifdir='.";
		return;
	}

	/* Validate the verbosity */
	if (!(is_array(verbose) && !dimsof(verbose)(1))) verbose = 1;
	if (verbose == -1) verbose = 1;
	verbose = int(verbose);
	
	/* Set called function verbosity */
	if(verbose == 3 || verbose == -2) {
		func_verbose = verbose;
	} else {
		func_verbose = -1;
	}

	/* Validate the step */
	if (!step || step == -1) step = 8;
	if (step < 2) step = 2;
	step = int(ceil(step));

								if(verbose >= 2) write, format="==> boat_input_exif(ifdir=%s, step=%i, verbose=%i)\n", ifdir, step, verbose;

	/* Run exiflist to get the gps information from the jpg files, filtering it
		through a perl script.
		
		Exiflist spits out the field values as indicated by its command. The perl
		script loops over them and converts HH:MM:SS to somd and DEG M S to decimal.

		Output is preceded by a line with the count of data items.
	*/
	cmd = "( exiflist -o l -f gps-time,gps-latitude,gps-lat-ref,gps-longitude,gps-long-ref " + ifdir + "/*.jpg | wc -l ); exiflist -o l -f gps-time,gps-latitude,gps-lat-ref,gps-longitude,gps-long-ref " + ifdir + "/*.jpg | perl -an -F',' -e 'sub ll {@c = split / /, shift(@_); $c[1] += $c[2] / 60; $c[0] += $c[1]/60; return $c[0];};sub ld {$d = shift(@_); return 1 if($d eq \"North\" || $d eq \"East\"); return -1 if($d eq \"South\" || $d eq \"West\"); return 0};sub sod {my @t = split /:/,shift(@_); $t[1] += $t[0] * 60; $t[2] += $t[1] * 60; return $t[2];};chomp($F[4]);print sod($F[0]) . \" \" . ll($F[1]) * ld($F[2]) . \" \" . ll($F[3]) * ld($F[4]) . \"\\n\"' | sort "

	f = popen(cmd, 0);
								if(verbose >= 2) write, format=" Pipe opened to %s\n", cmd;
	cmd = [];
	
	num = 1;
								if(verbose >= 2) write, "Reading data from file.";
	read, f, format="%d", num;
								if(verbose >= 2) write, format=" Number of entries assigned as %d\n", num;
	
	data_lat = array(float, num);
	data_lon = array(float, num);
	data_somd = array(float, num);
	
	read, f, format="%f %f %f", data_somd, data_lat, data_lon;
								if(verbose >= 1) write, format=" EXIF data read in, %d entries.\n", numberof(data_somd);
	
	close, f;
								if(verbose >= 2) write, "Pipe closed.";

	boat = array(BOAT_PICS, num);
	boat.somd = data_somd;
	boat.depth = 0;
	num = data_somd = [];
								if(verbose >= 2) write, "Somd data transferred to structure.";
	
	boat = boat_gps_smooth(boat, data_lat, data_lon, step, verbose=func_verbose);

								if(verbose >= 2) write, format="--/ boat_input_exif%s", "\n";
	return boat;
}

func boat_input_pdb(ifname=, verbose=) {
/* DOCUMENT  boat_input_pdb(ifname=, verbose=)

	Reads and returns an array of BOAT_PICS that was saved to a Yorick pdb file.

	The following parameters are required:

		n/a

	The following options are required:

		ifname= Full path and file name of pdb file to be read.

	The following options are optional:

		verbose= Indicates the verbosity level to run at.
			Default: 1
			Valid values:
				0 - No progress info
				1 - Limited progress information
				2 - Full progress information
				3 - Full progress information for this function
					and all called functions
				-1 - Explicitly request the default level
				-2 - No progress info for this or any called
					functions

	Function returns:

		Array of type BOAT_PICS
*/
	require, "dir.i";
	
	/* Check for required options */
	if (is_void(ifname)) {
		write, "One or more required options not provided. See 'help, boat_input_pdb'.";
		if(is_void(ifname)) write, "-> Missing 'ifname='.";
		return;
	}

	/* Validate the verbosity */
	if (!(is_array(verbose) && !dimsof(verbose)(1))) verbose = 1;
	if (verbose == -1) verbose = 1;
	verbose = int(verbose);
	
	/* Set called function verbosity */
	if(verbose == 3 || verbose == -2) {
		func_verbose = verbose;
	} else {
		func_verbose = -1;
	}

								if(verbose >= 2) write, format="==> boat_input_pdb(ifname=%s, verbose=%i)\n", ifname, verbose;

								if(verbose >= 2) write, "  Reading file";
	f = openb(ifname);
	restore, f, vname;
	boat = get_member(f, vname);
								if(verbose >= 2) write, format="     vname=%s\n", vname;
	close, f;

								if(verbose >= 2) write, format="--/ boat_input_pdb%s", "\n";
	return boat;
}

func calculate_heading(x1, y1, x2, y2, verbose=) {
/* DOCUMENT calculate_heading(x1, y1, x2, y2, verbose=)
	
	Returns the heading in degrees clockwise from north of an object
	that moved from point x1, y1 to point x2, y2.

	The following parameters are required:

		x1, y1  An ordered pair for the first point an object passed through
		x2, y2  An ordered pair for the second point an object passed through
	
	The following options are required:

		n/a

	The following options are optional:

		verbose= Indicates the verbosity level to run at.
			Default: 0
			Valid values:
				0 - No progress info
				1 - Limited progress information
				2 - Full progress information
				3 - Full progress information for this function
					and all called functions
				-1 - Explicitly request the default level
				-2 - No progress info for this or any called
					functions

	Function returns:

		heading in degrees clockwise from north
*/
	if (!(is_array(verbose) && !dimsof(verbose)(1))) verbose = 0;
	if (verbose == -1) verbose = 0;
	if (verbose == 3 || verbose == -2) {
		func_verbose = verbose;
	} else {
		func_verbose = -1;
	}
	verbose = int(verbose);

								if(verbose >= 2) write, format="==> calculate_heading(x1:%.2f, y1:%.2f, x2:%.2f, y2:%.2f, verbose=%i)\n", float(x1), float(y1), float(x2), float(y2), int(verbose);
	/* Calculate the angle of the point in radians CCW from the positive x-axis */
	/* Special case - x1 == x2 */
	if(x1 == x2) {
								if(verbose >= 2) write, "x1 == x2";
		radians = pi/2.0;
	/* Normal case */
	} else {
								if(verbose >= 2) write, "x1 != x2";
		radians = atan(float(y2-y1)/float(x2-x1));
	}
								if(verbose >= 2) write, format=" radians set to %.2f\n", float(radians);
	
	/* Convert the angle to degrees */
	degrees = radians * 180.0 / pi;
								if(verbose >= 2) write, format=" degrees set to %.2f\n", float(degrees);

	/* Put angle in the proper quadrant */
	if(x2 < x1 || (y2 < y1 && x2 == x1)) degrees -= 180;
								if(verbose >= 2) write, format=" degrees adjusted to %.2f\n", float(degrees);

	/* Convert angle to a heading */
	heading = 90 - degrees;
								if(verbose >= 1) write, format=" heading set to %.2f\n", float(heading);
								if(verbose >= 2) write, format="--/ calculate_heading%s", "\n";
	return heading;
}

func perpendicular_intercept(x1, y1, x2, y2, x3, y3) {
/* DOCUMENT perpendicular_intercept(x1, y1, x2, y2, x3, y3)
	
	Returns the coordinates of the point where the line that passes through
	(x1, y2) and (x2, y2) intersects with the line that passes through
	(x3, y3)	and is perpendicular to the first line.

	The following paramaters are required:

		x1, y1  An ordered pair for a point on a line
		x2, y2  An ordered pair for a point on the same line as x1, y1
		x3, y3  An ordered pair from which to find a perpendicular intersect

	The following options are required:

		n/a
	
	The following options are optional:

		n/a

	Function returns:

		[x, y]
*/
	
/* Make everything doubles */
	x1 = double(x1);
	y1 = double(y1);
	x2 = double(x2);
	y2 = double(y2);
	x3 = double(x3);
	y3 = double(y3);

	/* Special case: x1 == x2 */
	if (x1 == x2) {
	
		xi = x1;
		yi = y3;
	
	/* Special case: y1 == y2 */
	} else if (y1 == y2) {

		yi = y1;
		xi = x3;
	
	/* Normal case */
	} else {
	
		/* m12 - slope of the line passing through pts 1 and 2 */
		m12 = (y2 - y1)/(x2 - x1);
		/* m3 - slope of the line passing through pt 3, perpendicular to line 12 */
		m3 = -1 / m12;

		/* y-intercepts of the two lines */
		b12 = y1 - m12 * x1;
		b3 = y3 - m3 * x3;

		/* x value of the intersection point */
		xi = (b3 - b12)/(m12 - m3);

		/* y value of the intersection point */
		yi = m12 * xi + b12;

	}

	return [xi, yi];
}
