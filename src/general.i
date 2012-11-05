// vim: set ts=2 sts=2 sw=2 ai sr et:
require, "yeti_regex.i";
require, "zlib.i";

func default(&var, val) {
/* DOCUMENT default, &variable, value

  This function is meant to be used at the beginning of functions as a helper.
  It will set the variable to value if and only if the variable is void. This
  is a very simple wrapper intended to help abbreviate code and help it
  self-document better.

  Parameters:

    variable: The variable to be set to a default value, if void. It will be
      updated in place.

    value: The default value.

  SEE ALSO: require_keywords
*/
  if(is_void(var)) var = val;
}

func require_keywords(args) {
/* DOCUMENT require_keywords, key1, key2, key3
  This checks each of the given variables to make sure that the user provided
  a non-void value for them.

  For example, consider this function:

    func increment(&x, amount=) {
      require_keywords, amount;
      x += amount;
    }

  If the user omits the "amount=" keyword (or if they provide it, but define
  it to []), then they will receive an error. Otherwise, it works. To
  illustrate:

    > x=0
    > increment, x, amount=5
    > x
    5
    > increment, x
    ERROR (increment) Missing required keyword: amount
    WARNING source code unavailable (try dbdis function)
    now at pc= 3 (of 21), failed at pc= 7
     To enter debug mode, type <RETURN> now (then dbexit to get out)
    >

  SEE ALSO: default
*/
// Original David Nagle 2010-07-29
  arg_count = args(0);
  for(i = 1; i <= arg_count; i++)
    if(is_string(args(-,i)) && is_void(args(i)))
      error, "Missing required keyword: "+args(-,i);
}
errs2caller, require_keywords;
wrap_args, require_keywords;

func keyval_val(&data, name, val, fmt) {
/* DOCUMENT keyval_val, data, name, val, fmt
  DATA is an array of key/val string pairs. This function adds NAME and VAL to
  the array. VAL is formatted using optional parameter FMT if given;
  otherwise, is coerced into string as necessary.
  SEE ALSO: keyval_hash keyval_obj keyval_display
*/
  if(!is_string(val))
    default, fmt, "";
  if(!is_void(fmt))
    val = swrite(format=fmt, val);
  grow, data, [[name, val]];
}

func keyval_hash(&data, obj, key, fmt, name=) {
/* DOCUMENT keyval_hash, data, obj, key, fmt, name=
  DATA is an array of key/val string pairs. If OBJ has a key KEY, then its
  value is formatted using FMT and is added to DATA for the value. The name
  will then be NAME if provided, KEY otherwise.
  SEE ALSO: keyval_val keyval_obj keyval_display
*/
  if(!h_has(obj, key))
    return;
  default, name, key;
  val = swrite(format=fmt, obj(key));
  grow, data, [[name, val]];
}

func keyval_obj(&data, obj, key, fmt, name=) {
/* DOCUMENT keyval_obj, data, obj, key, fmt, name=
  DATA is an array of key/val string pairs. If OBJ has a member KEY, then its
  value is formatted using FMT and is added to DATA for the value. The name
  will then be NAME if provided, KEY otherwise.
  SEE ALSO: keyval_val keyval_hash keyval_display
*/
  if(!obj(*,key))
    return;
  default, name, key;
  val = swrite(format=fmt, obj(noop(key)));
  grow, data, [[name, val]];
}

func keyval_display(data, prefix=, delim=, keyright=, valright=) {
/* DOCUMENT keyval_display, data, prefix=, delim=, keyright=, valright=
  DATA is an array of key/val string pairs that will be displayed one pair per
  line as "KEY : VAL\n". PREFIX is a string to prefix to each line and
  defaults to " ". DELIM is the delimiter to use between the key and value and
  defaults to " : ". KEYRIGHT and VALRIGHT can be used to right justify either
  the keys or values; they are left justified by default.
  SEE ALSO: keyval_val keyval_hash keyval_display
*/
  default, prefix, " ";
  default, delim, " : ";
  default, keyright, 0;
  default, valright, 0;
  cols = strlen(data)(,max);
  fmt = swrite(format="%s%%%s%ds%s%%%s%ds\n", prefix, (keyright ? "" : "-"),
    cols(1), delim, (valright ? "" : "-"), cols(2));
  write, format=fmt, data(1,), data(2,);
}

func popen_rdfile(cmd) {
/* DOCUMENT popen_rdfile(cmd)
  This opens a pipe to the command given and reads its output, returning it as
  an array of lines. (It combines popen and rdfile into a single function,
  thus the name.)
*/
  f = popen(cmd, 0);
  lines = rdfile(f);
  close, f;
  return lines;
}

func bound(val, bmin, bmax) {
/* DOCUMENT bound(val, bmin, bmax)
  Constrains a value to a set of bounds. Note that val can have any
  dimensions.

  If bmin <= val <= bmax, then returns val
  If val < bmin, then returns bmin
  if bmax < val, then returns bmax
*/
// Original David Nagle 2008-11-18
  return min(bmax, max(bmin, val));
}

func get_user(void) {
/* DOCUMENT get_user()
  Returns the current user's username. If not found, returns string(0).
*/
  if(_user) return _user;
  return get_env("USER");
}

func get_host(void) {
/* DOCUMENT get_host()
  Returns the current host's hostname. If not found, returns string(0).
*/
  if(get_env("HOSTNAME")) return get_env("HOSTNAME");
  return get_env("HOST");
}

func binary_search(ary, val, exact=, inline=) {
/* DOCUMENT binary_search(ary, val, exact=, inline=)
  Searches in ary for val. The ary must be sorted and must contain numerical
  data. Will return the index corresponding to the value in ary that is
  nearest to val. If multiple indices match val exactly, then the first index
  is selected.

  Parameters:
    ary - Array of data to search in. Must be numerical, sorted, and
      one-dimensional.
    val - Value to search for. Must be a scalar number.

  Options:
    exact= By default, the closest match is returned. If exact=1, it will
      instead only return the index if it finds an exact match. If no match
      is found, it will return [].
    inline= If enabled, returns the matched value instead of the index.
*/
  default, exact, 0;
  default, inline, 0;

  // Initial bounds cover entire list
  b0 = 1
  b1 = is_obj(ary) ? ary(*) : numberof(ary);

  // Make sure the value is in bounds. If not... this becomes trivial.
  if(val <= ary(noop(b0)))
    b1 = b0;
  else if(ary(noop(b1)) < val)
    b0 = b1;

  // Narrow bounds until it's either a single value or adjacent indexes
  while(b1 - b0 > 1) {
    pivot = long((b0 + b1) / 2.);
    pivotVal = ary(noop(pivot));

    if(pivotVal < val) {
      b0 = pivot;
    } else {
      b1 = pivot;
    }
  }

  // Select the nearest index
  db0 = abs(val - ary(noop(b0)));
  db1 = abs(val - ary(noop(b1)));
  nearest = (db0 > db1) ? b1 : b0;

  // Handle exact=1
  if(exact && ary(noop(nearest)) != val)
    nearest = [];

  // Handle inline=1
  if(inline && !is_void(nearest))
    nearest = ary(noop(nearest));

  return nearest;
}

func bytes2text(bytes) {
/* DOCUMENT bytes2text(bytes)
  Converts a value in bytes to a textified representation in bytes, KB, MB, or
  GB. Works on scalars and arrays.
*/
  dims = dimsof(bytes);
  bytes = long(reform(bytes, numberof(bytes)));
  result = array(string, numberof(bytes));
  zero = !bytes;
  if(anyof(zero)) {
    result(where(zero)) = "0 bytes";
    bytes(where(zero)) = 1;
  }
  mag = log(bytes)/log(1024);
  mag = ymedian(transpose([0, 3, long(floor(mag-0.01))]));
  low = !result & mag == 0;
  if(anyof(low))
    result(where(low)) = swrite(format="%d bytes", bytes(where(low)));
  remaining = !result;
  if(anyof(remaining)) {
    w = where(remaining);
    fbytes = bytes(w) / (1024.^mag(w));
    suffix = ["KB", "MB", "GB"](mag(w));
    result(w) = swrite(format="%.2f %s", fbytes, suffix);
  }
  if(dims(1) == 0)
    return result(1);
  else
    return reform(result, dims);
}

func z_compress(data, level) {
/* DOCUMENT z_compress(data, level)
  Wrapper around z_deflate/z_flush that compresses data in a single call.
  Returns the compressed data.
  SEE ALSO: z_flush z_deflate z_inflate z_decompress
*/
// Original David B. Nagle 2010-07-23
  return z_flush(z_deflate(level), data);
}

func z_decompress(data, type) {
/* DOCUMENT z_decompress(data, type)
  Wrapper around z_inflate/z_flush that decompresses data in a single call.
  Returns the decompressed data. The type parameter is optional; if provided,
  it should be the data type to decompress as (by default, char).
  SEE ALSO: z_flush z_deflate z_inflate z_compress
*/
// Original David B. Nagle 2010-07-23
  default, type, char;
  buffer = z_inflate();
  flag = z_inflate(buffer, data);
  if(flag == 0 || flag == -1) {
    return z_flush(buffer, type);
  } else {
    error, swrite(format="could not decompress, error code %d", flag);
  }
}

func pass_void(f, val) {
/* DOCUMENT pass_void(f, val)
  If VAL is void, return VAL (that is, return []).
  Otherwise, return F(VAL).
  This is useful if you need to filter val through a function, but only if it's
  non-void -- and you're fine with it staying void if it already is.
*/
  if(is_void(val)) return val;
  return f(val);
}
