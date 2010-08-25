// vim: set tabstop=3 softtabstop=3 shiftwidth=3 autoindent shiftround expandtab:
require, "eaarl.i";

// scratch stores the values of scratch and tmp so that we can restore them
// when we're done, leaving things as we found them.
scratch = save(tmp, scratch);
// tmp stores a list of the methods that will go into wfobj. It stores their
// current values up-front, then restores them at the end while swapping the
// new function definitions into wfobj.
tmp = save(summary, index, x0, y0, z0, xyz0, x1, y1, z1, xyz1);

func wfobj(base, obj) {
/* DOCUMENT wfobj()
   Creates a waveforms data object. This can be called in one of four ways.

      data = wfobj()
         Without any arguments, DATA is an object with defaults for header
         values and void for array/data values. Effectively, it's "empty".
      data = wfobj(group)
         When passed a group object, DATA will be initialized as a copy of it.
         Any missing header or data members get filled in as in the previous
         case.
      data = wfobj(filename)
         When passed a filename, DATA will be initialized using the data from
         the specified file; that file should have been created using the save
         method to this class.
      wfobj, data
         When called in the subroutine form, data should be a group object. It
         will be treated as in the second case, but will be done in-place.

   A wfobj object is comprised of scalar header members, array data members,
   and methods. In the documentation below, "data" is the result of a call to
   wfobj.

   Scalar header members:
      data(source,)           string      default: "unknown"
         Source used to collect the data. Generally an airplane tail number.
      data(system,)           string      default: "unknown"
         Data acquisition system, ie. ATM, EAARL, etc.
      data(record_format,)    long        default: 0
         Defines how to interpret the record field.
      data(cs,)               string      default: string(0)
         Specifies the coordinate system used.
      data(sample_interval,)  double      default: 0.
         Specifies the interval in nanoseconds between samples.

   Array data members, for N points:
      data(raw_xyz0,)         array(double,N,3)
         Specifies an arbitrary point that, along with "raw_xyz1", defines the
         line upon which the waveform traveled. This point is in the coordinate
         system specified by "cs". It is recommended that this point be the
         point of origin for the waveform (ie the mirror location), but this is
         not required and should not be assumed.
      data(raw_xyz1,)         array(double,N,3)
         Specifies a point that, along with "raw_xyz0", defines the line upon
         which the waveform traveled. Unlike "raw_xyz0", this point is NOT
         arbitrary. If TDELTA is the time interval in ns between the first
         sample of "tx" and the first sample of "rx", then "raw_xyz1" is the
         point representing where the pulse would be at TDELTA ns after the
         laser fired.
      data(soe,)              array(double,N)
         The timestamp for the point, in seconds of the epoch.
      data(record,)           array(long,N,2)
         The record number for the point. This value must be interpreted as
         defined by "record_format". Together with "soe", this should uniquely
         identify the waveform.
      data(tx,)               array(pointer,N)
         The transmit waveform.
      data(rx,)               array(pointer,N)
         The return waveform.

   Methods:
      data, help
         Displays this help documentation.
      data, summary
         Displays a summary for the data. Meant for interactive use.
      data(index, idx)
         Returns a new wfobj object. The new object will contain the same
         header information. However, it will contain only the points specified
         by "idx".
      data(xyz0,) -or- data(xyz0,idx)
         Returns the points stored in raw_xyz0, except converted into the
         current coordinate system as specified by current_cs. The points are
         cached to improve performance. If "idx" is specified, then only those
         points are returned.
      data(xyz1,) -or- data(xyz1,idx)
         Like "xyz0", except for the points stored in raw_xyz1.
      data(x0,)  data(y0,)  data(z0,)  data(x1,)  data(y1,)  data(z1,)
         Like "xyz0" or "xyz1", except they only return the x, y, or z
         coordinate. Like xyz0 and xyz1, these also can accept an "idx"
         parameter.
      data, save, fn
         Saves the data for this wfobj object to a pbd file specified by FN.
         The data can later be restored using 'data = wfobj(fn)'.
*/
   default, obj, save();

   // For restoring from file
   if(is_string(obj)) {
      obj = pbd2obj(obj);
   // If calling as a subroutine, don't modify in place
   } else if(!am_subroutine()) {
      obj = obj(:);
   }

   // Set up methods. We override generic's "index" method so we have to
   // provide it specially.
   obj_merge, obj, base;
   obj_generic, obj;
   save, obj, obj_index;
   // We don't want all of the objects to share a common data item, so they get
   // re-initialized here.
   save, obj,
      xyz0=closure(obj.xyz0.function, save(var="raw_xyz0", cs="-", xyz=[])),
      xyz1=closure(obj.xyz1.function, save(var="raw_xyz1", cs="-", xyz=[]));

   // Provide defaults for scalar members
   keydefault, obj, source="unknown", system="unknown", record_format=0,
      cs=string(0), sample_interval=0.;
   // Provide null defaults for array members
   keydefault, obj, raw_xyz0=[], raw_xyz1=[], soe=[], record=[], tx=[], rx=[];

   return obj;
}

// summary method uses a closure to encapsulate code that would otherwise need
// to be repeated within the function
scratch = save(tmp, scratch);
// listing same item twice to avoid bug where save fails to recognize a single
// void argument
tmp = save(coord_print, coord_print);

func summary(util) {
   extern current_cs;
   local x, y;
   write, "Summary for waveform object:";
   write, "";
   write, format=" %d total waveforms\n", numberof(use(soe));
   write, "";
   write, format=" source: %s\n", use(source);
   write, format=" system: %s\n", use(system);
   write, format=" acquired: %s to %s\n", soe2iso8601(use(soe)(min)),
      soe2iso8601(use(soe)(max));
   write, "";
   write, format=" record_format: %d\n", use(record_format);
   write, format=" sample_interval: %.6f ns/sample\n", use(sample_interval);
   write, "";
   write, "Approximate bounds in native coordinate system";
   write, format=" %s\n", use(cs);
   splitary, use(raw_xyz1), 3, x, y;
   cs = cs_parse(use(cs), output="hash");
   util, coord_print, cs, x, y;

   if(current_cs == use(cs))
      return;
   cs = cs_parse(current_cs);
   splitary, use(xyz1,), 3, x, y;
   write, "";
   write, "Approximate bounds in current coordinate system";
   write, format=" %s\n", current_cs;
   util, coord_print, cs, x, y;
}

func coord_print(cs, x, y) {
   if(cs.proj == "longlat") {
      write, "                min                max";
      write, format="   x/lon: %16.11f   %16.11f\n", x(min), x(max);
      write, format="          %16s   %16s\n",
         deg2dms_string(x(min)), deg2dms_string(x(max));
      write, format="   y/lat: %16.11f   %16.11f\n", y(min), y(max);
      write, format="          %16s   %16s\n",
         deg2dms_string(y(min)), deg2dms_string(y(max));
   } else {
      write, "               min           max";
      write, format="    x/east: %11.2f   %11.2f\n", x(min), x(max);
      write, format="   y/north: %11.2f   %11.2f\n", y(min), y(max);
   }
}

summary = closure(summary, restore(tmp));
restore, scratch;

func index(idx) {
   which = ["raw_xyz0","raw_xyz1", "soe", "record", "tx", "rx"];
   if(am_subroutine()) {
      this = use();
      this, obj_index, idx, which=which;
      wfobj, this;
   } else {
      return wfobj(use(obj_index, idx, which=which));
   }
}

// xyz0 and xyz1 both use the same logic, and they both benefit from caching
// working data. This is accomplished by using a closure to wrap around the
// common functionality and track their working data.
scratch = save(xyzwrap, scratch);

func xyzwrap(working, idx) {
   extern current_cs;
   if(working.cs != current_cs) {
      save, working, cs=current_cs,
         xyz=cs2cs(use(cs), current_cs, use(working.var));
   }
   return working.xyz(idx,);
}

xyz0 = closure(xyzwrap, save(var="raw_xyz0", cs="-", xyz=[]));
xyz1 = closure(xyzwrap, save(var="raw_xyz1", cs="-", xyz=[]));
restore, scratch;

func x0(idx) { return use(xyz0, idx)(,1); }
func y0(idx) { return use(xyz0, idx)(,2); }
func z0(idx) { return use(xyz0, idx)(,3); }

func x1(idx) { return use(xyz1, idx)(,1); }
func y1(idx) { return use(xyz1, idx)(,2); }
func z1(idx) { return use(xyz1, idx)(,3); }

save, tmp, save, help;
func save(fn) { obj2pbd, use(), createb(fn, i86_primitives); }
help = closure(help, wfobj);

wfobj = closure(wfobj, restore(tmp));
restore, scratch;
