// vim: set tabstop=4 softtabstop=4 shiftwidth=4 autoindent expandtab:

require, "eaarl.i";
write, "$Id$";

func extract_qq(text) {
/* DOCUMENT extract_qq(text)

    Extract the quarter quad string from a text string. The text string will
    probably be a filename or similar. The expected rules it will follow:

    - The QQ name may be optionally preceeded by other text, but must be
      separated by an underscore if so.
    - The QQ name may be optionally followed by other text, but must be
      separated by either an underscore or a period if so.
    - The QQ name must be exactly 8 characters in length, and must use lowercase
      alpha instead of uppercase alpha where relevant.

    This function will work on scalars or arrays. The returned result will be
    the quarter quad name(s).

    Original David Nagle 2008-07-17
*/
    regmatch, "(^|_)([0-9][0-9][0-1][0-9][0-9][a-h][1-8][a-d])(\.|_|$)", text, , , qq;
    return qq;
}

func dt_short(dtcodes) {
/* DOCUMENT shortnames = dt_short(dtcodes)
    Returns abbreviated names for an array of data tile codes.

    Example:

        > dt_short("t_e466000_n3354000_16")
        "e466_n3354_16"

    Original David Nagle 2008-07-21
*/
    w = n = z = []; // prevents the next line from making them externs
    regmatch, "(^|_)e([1-9][0-9]{2})(000)?_n([1-9][0-9]{3})(000)?_z?([1-9][0-9]?)(_|\\.|$)", dtcodes, , , w, , n, , z;
    return swrite(format="e%s_n%s_%s", w, n, z);
}

func dt_long(dtcodes) {
/* DOCUMENT longnames = dt_long(dtcodes)
    Returns full names for an array of data tile codes.

    Example:

        > dt_long("e466_n3354_16")
        "t_e466000_n3354000_16"
    
    Original David Nagle 2008-08-07
*/
    w = n = z = []; // prevents the next line from making them externs
    regmatch, "(^|_)e([1-9][0-9]{2})(000)?_n([1-9][0-9]{3})(000)?_z?([1-9][0-9]?)(_|\\.|$)", dtcodes, , , w, , n, , z;
    return swrite(format="t_e%s000_n%s000_%s", w, n, z);
}

func dt2utm(dtcodes, &north, &east, &zone, bbox=, centroid=) {
/* DOCUMENT dt2utm(dtcodes, bbox=, centroid=)
    dt2utm, dtcodes, &north, &east, &zone

    Returns the northwest coordinates for the given dtcodes as an array of
    [north, west, zone].

    If bbox=1, then it instead returns the bounding boxes, as an array of
    [south, east, north, west, zone].

    If centroid=1, then it returns the tile's central point.

    If called as a subroutine, it sets the northwest coordinates of the given
    output variables.
*/
//  Original David Nagle 2008-07-21
    w = n = z = []; // prevents the next line from making them externs
    if(regmatch("(^|_)e([1-9][0-9]{2})(000)?_n([1-9][0-9]{3})(000)?_z?([1-9][0-9]?)(_|\\.|$)", dtcodes, , , w, , n, , z)) {
        n = atoi(n + "000");
        w = atoi(w + "000");
        z = atoi(z);
    } else {
        w = n = z = [];
    }

    if(am_subroutine()) {
        north = n;
        east = w;
        zone = z;
    }

    if(is_void(z))
        return [];
    else if(bbox)
        return [n - 2000, w + 2000, n, w, z];
    else if(centroid)
        return [n - 1000, w + 1000, z];
    else
        return [n, w, z];
}

func it2utm(itcodes, bbox=, centroid=) {
/* DOCUMENT it2utm(itcodes, bbox=, centroid=)
    Returns the northwest coordinates for the given itcodes as an array of
    [north, west, zone].

    If bbox=1, then it instead returns the bounding boxes, as an array of
    [south, east, north, west, zone].

    If centroid=1, then it returns the tile's central point.
*/
//  Original David Nagle 2008-07-21
    u = dt2utm(itcodes);
    
    if(is_void(u))
        return [];
    else if(bbox)
        return [u(..,1) - 10000, u(..,2) + 10000, u(..,1), u(..,2), u(..,3)];
    else if(centroid)
        return [u(..,1) -  5000, u(..,2) +  5000, u(..,3)];
    else
        return u;
}


func get_utm_dtcodes(north, east, zone) {
/* DOCUMENT dt = get_utm_dtcodes(north, east, zone)
    
    For a set of UTM northings, eastings, and zones, this will calculate each
    coordinate's data tile name and return an array of strings that correspond
    to them.

    Original David Nagle 2008-07-21
*/
    return swrite(format="t_e%.0f000_n%.0f000_%d",
        floor(east /2000.0)*2,
        ceil (north/2000.0)*2,
        int(zone));
}

func get_dt_itcodes(dtcodes) {
/* DOCUMENT it = get_dt_itcodes(dtcodes)
    For an array of data tile codes, this will return the corresponding index
    tile codes.

    Original David Nagle 2008-07-21
*/
    east  = floor(atoi(strpart(dtcodes, 4:6))  /10.0)*10;
    north = ceil (atoi(strpart(dtcodes, 12:15))/10.0)*10;
    zone  = strpart(dtcodes, 20:21);
    return swrite(format="i_e%.0f000_n%.0f000_%s", east, north, zone);
}

func get_date(text) {
/* DOCUMENT get_date(text)
    Given an arbitrary string of text, this will parse out the date and return
    it in YYYY-MM-DD format.

    This will match using the following rules:
    * The date must be at the beginning of the string.
    * The date may be in YYYY-MM-DD or YYYYMMDD format. (But cannot be in
      YYYY-MMDD or YYYYMM-DD format.)
    * If there are any characters following the date, the first must not be a
      number. (So 20020101pm is okay but 200201019 is not.)

    If text is an array of strings, then an array of strings (with the same
    dimensions) will be returned.

    If a string does not contain a parseable date, then the nil string
    (string(0)) will be returned instead.
*/
    // Original David Nagle 2008-12-24 (as part of ytime.i's
    // determine_gps_time_correction)
    // The year may be in the range 1970 to 2099.
    yreg = "19[789][0-9]|20[0-9][0-9]";
    // The month may be in the range 01 to 12.
    mreg = "0[1-9]|1[0-2]";
    // The day may be in the range 01 to 31.
    dreg = "0[1-9]|[12][0-9]|3[01]";

    full_reg = swrite(format="^(%s)(-?)(%s)\\2(%s)($|[^0-9])", yreg, mreg, dreg);

    m_full = m_year = m_dash = m_month = m_day = [];
    w = where(regmatch(full_reg, text, m_full, m_year, m_dash, m_month, m_day));
    
    result = array(string(0), dimsof(text));
    if(numberof(w)) {
        result(w) = swrite(format="%s-%s-%s", m_year(w), m_month(w), m_day(w));
    }

    return result;
}

func cir_to_soe(filename, offset=) {
/* DOCUMENT cir_to_soe(filename, offset=)
    Parses a CIR image's filename and returns the second of the epoch from when
    it was taken.

    offset specifies an offset to apply to the raw soe value. By default,
    offset=1.12, which should correct the raw CIR filename timestamp to the
    correct time value.
*/
// Original David B. Nagle 2009-02-23
    default, offset, 1.12;

    dmreg = "0[0-9]|1[01]";             // (date) month reg exp 00-11
    ddreg = "0[1-9]|[12][0-9]|3[01]";   // (date) day reg exp 01-31
    dyreg = "[890123][0-9]";            // (date) year reg exp 80-39
    threg = "[01][0-9]|2[0-3]";         // (time) hour reg exp 00-23
    tmreg = "[0-5][0-9]";               // (time) minute reg exp 00-59
    tsreg = "[0-5][0-9]";               // (time) second reg exp 00-59

    full_reg = swrite(format="^(%s)(%s)(%s)-(%s)(%s)(%s)-cir.jpg$",
        dmreg, ddreg, dyreg, threg, tmreg, tsreg);
    
    m_full = m_dm = m_dd = m_dy = m_th = m_tm = m_ts = [];
    w = where(regmatch(full_reg, filename, m_full,
        m_dm, m_dd, m_dy, m_th, m_tm, m_ts));

    result = array(double(-1), dimsof(filename));
    if(numberof(w)) {
        yy = atod(m_dy(w));
        c20 = yy > 60; // 20th century
        yyyy = array(double, dimsof(yy));
        if(numberof(where(c20)))
            yyyy(where(c20)) = yy(where(c20)) + 1900;
        if(numberof(where(!c20)))
            yyyy(where(!c20)) = yy(where(!c20)) + 2000;

        result(w) = ymd2soe(
            yyyy, atod(m_dm(w))+1, atod(m_dd(w)),
            hms2sod(atod(m_th(w)), atod(m_tm(w)), offset + atod(m_ts(w))));
    }

    return result;
}
