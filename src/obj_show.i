// vim: set tabstop=2 softtabstop=2 shiftwidth=2 autoindent shiftround expandtab:

func obj_show(obj, prefix=, maxcnt=) {
/* DOCUMENT obj_show, obj;
  Display contents of object OBJ in a tree-like representation. Keyword PREFIX
  can be used to prepend a prefix to the printed lines. Keyword MAXCNT
  (default 5) can be used to specify the maximum number of elements for
  printing array values.
*/
  _obj_show_maxcnt = (is_void(maxcnt) ? 5 : maxcnt);
  _obj_show_worker, obj, "TOP", (is_void(prefix) ? "" : prefix), 0;
}

_obj_show_workers = save();
func _obj_show_worker(obj, name, prefix, stage) {
  if(stage == 1)
    prefix += [" |-", " | "];
  else if(stage == 2)
    prefix += [" `-", "   "];
  else
    prefix += ["", ""];
  if(_obj_show_workers(*,typeof(obj)))
    _obj_show_workers, typeof(obj), obj, name, prefix(1), prefix(2);
  else
    write, format="%s %s (%s)\n", prefixes(1), name, typeof(obj);
}

/*
  Custom workers can be defined by creating a function with parameters (obj,
  name, prefix1, prefix2). Then add an entry to _obj_show_workers like so:
    save, _obj_show_workers, typename=customworker
  where typename is the result of typeof(item).
*/

func _obj_show_oxy_object(obj, name, prefix1, prefix2) {
  count = obj(*);
  write, format="%s %s (oxy_object, %d %s)\n",
    prefix1, name, count, (count == 1 ? "entry" : "entries");
  for(i = 1; i <= count; i++) {
    key = obj(*,i);
    if(!key) key = "(nil)";
    _obj_show_worker, obj(noop(i)), key, prefix2, 1 + (i == count);
  }
}
save, _obj_show_workers, oxy_object=_obj_show_oxy_object;

func _obj_show_hash_table(obj, name, prefix1, prefix2) {
  key_list = h_keys(obj);
  count = numberof(key_list);
  if(count)
    key_list = key_list(sort(key_list));
  ev = h_evaluator(obj);
  write, format="%s %s (hash_table, %s%d %s)\n",
    prefix1, name, (ev ? "evaluator=\""+ev+"\", " : ""),
    count, (count == 1 ? "entry" : "entries");
  for(k = 1; k <= count; k++) {
    key = key_list(k);
    _obj_show_worker, h_get(obj,key), key, prefix2, 1 + (k == count);
  }
}
save, _obj_show_workers, hash_table=_obj_show_hash_table;

func _obj_show_array(obj, name, prefix1, prefix2) {
  descr = typeof(obj);
  dims = dimsof(obj);
  n = numberof(dims);
  k = 1;
  while (++k <= n) {
    descr += swrite(format=",%d", dims(k));
  }
  if(numberof(obj) <= _obj_show_maxcnt) {
    write, format="%s %s (%s) %s\n", prefix1, name, descr, sum(print(obj));
  } else {
    write, format="%s %s (%s)\n", prefix1, name, descr;
  }
}
save, _obj_show_workers,
  float=_obj_show_array,
  double=_obj_show_array,
  char=_obj_show_array,
  short=_obj_show_array,
  int=_obj_show_array,
  long=_obj_show_array;

func _obj_show_void(obj, name, prefix1, prefix2) {
  write, format="%s %s (void) []\n", prefix1, name;
}
save, _obj_show_workers, void=_obj_show_void;

func _obj_show_symlink(obj, name, prefix1, prefix2) {
  write, format="%s %s (%s) \"%s\"\n", prefix1, name, typeof(obj),
    name_of_symlink(obj);
}
save, _obj_show_workers, symlink=_obj_show_symlink;
