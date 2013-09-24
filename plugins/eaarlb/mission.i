// vim: set ts=2 sts=2 sw=2 ai sr et:

handler_set, "mission_query_soe_rn", "eaarl_mission_query_soe_rn";
func eaarl_mission_query_soe_rn(env) {
/* DOCUMENT eaarl_mission_query_soe_rn(env)
  Handler function for mission_query_soe_rn.
  SEE ALSO: mission_query_soe_rn
*/
  flights = env.flights;
  rn = env.rn;

  count = numberof(flights);
  dist = array(10000., count);
  for(i = 1; i <= count; i++) {
    mission, load, flights(i);
    if(!is_void(edb) && rn <= numberof(edb))
      dist(i) = abs(env.soe - edb(rn).seconds - edb(rn).fseconds*1.6e-6);
  }
  if(dist(min) <= 1) env, match=flights(dist(mnx));

  return env;
}

handler_set, "mission_query_soe", "eaarl_mission_query_soe";
func eaarl_mission_query_soe(env) {
/* DOCUMENT eaarl_mission_query_soe(env)
  Handler function for mission_query_soe.

  This function determines the flight using time as follows:
    1. Attempts to uniquely determine using EDB
    2. Attempts to uniquely determine using GPS
    3. Attempts to uniquely determine using INS
    4. If multiple matches were found, returns an array of matches that all of
      them agreed on. (If no matches are found for a source, it is excluded.)

  SEE ALSO: mission_query_soe
*/
  soe = env.soe;
  loaded = mission.data.loaded;

  if(!mission.data(*,"soe_bounds"))
    mission, data, soe_bounds=save();

  // Scan through flights and collect information on which flights have matches
  // with the soe
  flights = mission(get,);
  count = numberof(flights);
  edb_match = gps_match = ins_match = [];
  for(i = 1; i <= count; i++) {
    if(!mission.data.soe_bounds(*,flights(i)))
      mission, load, flights(i);
    if(!mission.data.soe_bounds(*,flights(i)))
      continue;
    rng = mission.data.soe_bounds(flights(i));
    if(rng(*,"edb") && rng.edb(1) <= soe && soe <= rng.edb(2))
      grow, edb_match, flights(i);
    if(rng(*,"gps") && rng.gps(1) <= soe && soe <= rng.gps(2))
      grow, gps_match, flights(i);
    if(rng(*,"ins") && rng.ins(1) <= soe && soe <= rng.ins(2))
      grow, ins_match, flights(i);
  }

  mission, load, loaded;

  // If exactly one edb match is found, use it.
  // If no edb match but exactly one gps, use it.
  // If no edb or gps but exactly one ins, use it.
  if(numberof(edb_match) == 1) {
    env, match=edb_match(1);
    return env;
  } else if(!numberof(edb_match)) {
    if(numberof(gps_match) == 1) {
      env, match=gps_match(1);
      return env;
    } else if(!numberof(gps_match) && numberof(ins_match) == 1) {
      env, match=ins_match(1);
      return env;
    }
  }

  // List of all flights that matched anything
  all_match = set_remove_duplicates(grow(edb_match, gps_match, ins_match));
  if(!numberof(all_match)) return env;

  // Winnow list down to just those that appeared on each list of results where
  // we actually had results.
  if(numberof(edb_match))
    all_match = set_intersection(all_match, edb_match);
  if(numberof(gps_match))
    all_match = set_intersection(all_match, gps_match);
  if(numberof(ins_match))
    all_match = set_intersection(all_match, ins_match);

  env, match=all_match;
  return env;
}

handler_set, "mission_load_soe_rn", "eaarl_mission_load_soe_rn";
func eaarl_mission_load_soe_rn(env) {
/* DOCUMENT eaarl_mission_load_soe_rn(env)
  Handler for mission_load_soe_rn.
  SEE ALSO: mission_load_soe_rn
*/
  // Check to see if the current flight contains this soe and rn; if so, do
  // nothing. Only checks EDB.
  if(mission.data.loaded != "" && !is_void(edb) && env.rn <= numberof(edb)) {
    dist = abs(env.soe - edb(env.rn).seconds - edb(env.rn).fseconds*1.6e-6);
    if(dist < 1) return env;
  }

  flight = mission(query_soe_rn, env.soe, env.rn);
  mission, unload;
  if(numberof(flight) == 0) {
    write, "WARNING: no flight found that matched the given soe+rn";
    return env;
  }
  if(numberof(flight) > 1) {
    error, "found multiple matches which shouldn't happen";
  }
  mission, load, flight;
  return env;
}

handler_set, "mission_load_soe", "eaarl_mission_load_soe";
func eaarl_mission_load_soe(env) {
/* DOCUMENT eaarl_mission_load_soe(env)
  Handler for mission_load_soe.
  SEE ALSO: mission_load_soe
*/
  // Check to see if the current flight contains this soe; if so, do nothing.
  // This only works if it matches the SOE in all three of GPS, INS, and EDB
  // (if each is present).
  if(mission.data.loaded != "") {
    match = 1;
    if(is_numerical(soe_day_start)) {
      sod = env.soe - soe_day_start;
      if(!is_void(pnav))
        match = match && pnav.sod(1) <= sod && sod <= pnav.sod(0);
      if(!is_void(tans))
        match = match && tans.somd(1) <= sod && sod <= tans.somd(0);
    }
    if(!is_void(edb))
      match = match && edb.seconds(1) <= env.soe & env.soe <= edb.seconds(0)+1;

    if(match) return env;
  }

  flights = mission(query_soe, env.soe);
  mission, unload;
  if(numberof(flights) == 0) {
    write, "WARNING: no flight found that matched the given soe";
    return env;
  }
  if(numberof(flights) > 1) {
    write, "WARNING: multiple flights found that matched the given soe;";
    write, "         using first match, which may not be correct";
  }
  mission, load, flights(1);
  return env;
}

func eaarl_mission_load_test_key(flight, key) {
/* DOCUMENT eaarl_mission_load_test_key(flight, key)
  Utility function for mission_eaarl_load.
  - Tests to see if the key exists. If not, warning issued.
  - Tests to see if defined file exists. If not:
    - Warning if mission.data.missing_file="warn"
    - Error otherwise
  - Returns 0 if any warning was issued.
  - Returns 1 if everything is okay.
*/
  if(mission(has, flight, key)) {
    fn = mission(get, flight, key);
    if(file_exists(fn)) {
      return 1;
    } else {
      msg = pr1(key)+" defined for "+pr1(flight)+" doesn't exist";
      if(mission.data.missing_file == "warn") {
        write, "WARNING: "+msg;
        return 0;
      } else {
        error, msg;
      }
    }
  } else {
    write, "WARNING: no "+pr1(key)+" defined for "+pr1(flight);
    return 0;
  }
}

handler_set, "mission_load", "eaarl_mission_load";
func eaarl_mission_load(env) {
/* DOCUMENT eaarl_mission_load(env)
  Handler for mission_load.
  SEE ALSO: mission_load
*/
  // Local alias for convenience
  test_key = eaarl_mission_load_test_key;

  // Start by clearing any currently loaded data. (This also triggers onchange
  // caching.)
  mission, unload;

  mission, data, loaded=env.flight;

  if(!strlen(env.flight))
    return env;

  // What was restored from the cache?
  cached = "none";

  // Load from cache, if there is cached data present and caching is enabled.
  if(mission.data.cache_mode != "disabled" && mission.data.cache(*,env.flight)) {
    cached = mission(unwrap, mission.data.cache(env.flight));
  }

  // If we loaded everything from cache and we wanted to load everything from
  // cache, then nothing else needs to be done.
  if(cached == "everything" && mission.data.cache_what == "everything")
    return env;

  // At this point:
  // If cached=="everything" && mission.data.cache_what=="settings" then:
  //    - all data items should be reloaded (don't want what was cached)
  //    - settings should not be reloaded
  // If cached=="settings" && mission.data.cache_what=="everything" then:
  //    - all data items need to be loaded (weren't cached)
  //    - settings do not need to be loaded (were cached)
  // If cached=="settings" && mission.data.cache_what="settings" then:
  //    - all data items need to be loaded
  //    - settings do not need to be loaded
  // if cached=="none" then:
  //    - all data items need to be loaded
  //    - all settings need to be loaded
  // Thus, all data items always need to be loaded at this point. The settings
  // items only need to be loaded if cached=="none".

  // soe_bounds information is used to speed up query_soe and query_soe_rn.
  // These shouldn't change much, so they are perma-cached regardless of cache
  // settings.
  if(!mission.data(*,"soe_bounds"))
    mission, data, soe_bounds=save();
  if(!mission.data.soe_bounds(*,env.flight))
    save, mission.data.soe_bounds, env.flight, save();

  // Step through the data sources used in ALPS and load each one.

  extern data_path;
  if(mission(has, env.flight, "data_path dir"))
    data_path = mission(get, env.flight, "data_path dir");

  // If cached is not "none", then settings were restored from the cache
  // (cached == "everything" or cached == "settings").
  if(cached == "none") {
    // ops_conf -- needs to come first since some other sources depend on it
    extern ops_conf, ops_conf_filename;
    if(test_key(env.flight, "ops_conf file")) {
      ops_conf_filename = mission(get, env.flight, "ops_conf file");
      ops_conf = load_ops_conf(ops_conf_filename);
    } else {
      write, "         (using EAARL-B defaults)";
      ops_conf = obj_copy(ops_eaarlb);
    }

    if(test_key(env.flight, "bathconf file")) {
      bathconf, read, mission(get, env.flight, "bathconf file");
    } else {
      write, "         (using null defaults)";
      bathconf, clear;
    }
  }

  // edb -- defines a few variables (such as soe_day_start) that are needed by
  // things that follow
  extern edb;
  soes = [];
  if(test_key(env.flight, "edb file")) {
    load_edb, fn=mission(get, env.flight, "edb file"), verbose=0;
    idx = [1, numberof(edb)];
    save, mission.data.soe_bounds(env.flight), "edb",
      edb.seconds(idx) + edb.fseconds(idx)*1.6e-6;
  }

  extern pnav, curzone;
  if(test_key(env.flight, "pnav file")) {
    pnav = rbpnav(fn=mission(get, env.flight, "pnav file"), verbose=0);
    if(!curzone && has_member(pnav, "lat") && has_member(pnav, "lon"))
      auto_curzone, pnav.lat, pnav.lon;
    if(has_member(pnav, "sod") && mission(has, env.flight, "date")) {
      idx = [1, numberof(pnav)];
      save, mission.data.soe_bounds(env.flight), "gps",
        date2soe(mission(get, env.flight, "date"), pnav.sod(idx));
    }
  }

  extern ins_filename, iex_nav, iex_head, tans;
  if(test_key(env.flight, "ins file")) {
    ins_filename = mission(get, env.flight, "ins file");
    if(file_extension(ins_filename) == ".pbd") {
      load_iexpbd, ins_filename, verbose=0;
    } else {
      tans = iex_nav = rbtans(fn=ins_filename);
      iex_head = [];
    }
    if(has_member(tans, "somd") && mission(has, env.flight, "date")) {
      idx = [1, numberof(tans)];
      save, mission.data.soe_bounds(env.flight), "ins",
        date2soe(mission(get, env.flight, "date"), tans.somd(idx));
    }
    if(!curzone && has_member(tans, "lat") && has_member(tans, "lon"))
      auto_curzone, tans.lat, tans.lon;
  }

  if(anyof(mission.data.cache_mode == ["onload","onchange"]))
    save, mission.data.cache, mission.data.loaded, mission(wrap,);

  return env;
}

handler_set, "mission_unload", "eaarl_mission_unload";
func eaarl_mission_unload(env) {
/* DOCUMENT eaarl_mission_unload(env)
  Handler for mission_unload.
  SEE ALSO: mission_unload
*/
  if(mission.data.cache_mode == "onchange" && mission.data.loaded != "")
    save, mission.data.cache, mission.data.loaded, mission(wrap,);

  mission, data, loaded="";

  extern data_path;
  data_path = "";

  extern edb, edb_filename, edb_files, total_edb_records, soe_day_start,
    eaarl_time_offset;
  edb = edb_filename = edb_files = total_edb_records = soe_day_start =
    eaarl_time_offset = [];

  extern pnav, gga, pnav_filename;
  pnav = gga = [];
  pnav_filename = "";

  extern iex_nav, iex_head, tans, ins_filename;
  iex_nav = iex_head = tans = ins_filename = [];

  extern ops_conf, ops_conf_filename;
  ops_conf = ops_conf_filename = [];

  extern bathconf;
  bathconf, clear;

  return env;
}

handler_set, "mission_wrap", "eaarl_mission_wrap";
func eaarl_mission_wrap(env) {
/* DOCUMENT eaarl_mission_wrap(env)
  Handler for mission_wrap.
  SEE ALSO: mission_wrap
*/
  default, cache_what, env.cache_what;
  default, cache_what, mission.data.cache_what;

  extern data_path;
  extern edb, edb_filename, edb_files, total_edb_records, soe_day_start,
    eaarl_time_offset;
  extern pnav, gga, pnav_filename;
  extern iex_nav, iex_head, tans, ins_filename;
  extern ops_conf, ops_conf_filename;
  extern bathconf;

  save, env.wrapped,
    cache_what,
    ops_conf, ops_conf_filename,
    bathconf_data=bathconf.data;

  if(cache_what == "everything") {
    save, env.wrapped,
      data_path,
      edb, edb_filename, edb_files, total_edb_records, soe_day_start,
        eaarl_time_offset,
      pnav, gga, pnav_filename,
      iex_nav, iex_head, tans, ins_filename;
  }

  return env;
}

handler_set, "mission_unwrap", "eaarl_mission_unwrap";
func eaarl_mission_unwrap(env) {
/* DOCUMENT eaarl_mission_unwrap(env)
  Handler for mission_unwrap.
  SEE ALSO: mission_unwrap
*/
  extern data_path;
  extern edb, edb_filename, edb_files, total_edb_records, soe_day_start,
    eaarl_time_offset;
  extern pnav, gga, pnav_filename;
  extern iex_nav, iex_head, tans, ins_filename;
  extern ops_conf, ops_conf_filename;
  extern bathconf;

  cache_what = env.data.cache_what;
  bathconf_data = env.data.bathconf_data;

  idx = env.data(*,[
    "data_path",
    "edb", "edb_filename", "edb_files", "total_edb_records", "soe_day_start",
        "eaarl_time_offset",
    "pnav", "gga", "pnav_filename",
    "iex_nav", "iex_head", "tans", "ins_filename",
    "ops_conf", "ops_conf_filename"
  ]);
  restore, env.data(idx(where(idx)));

  if(is_void(bathconf_data))
    bathconf, clear;
  else
    bathconf, groups, bathconf_data, copy=0;

  save, env, cache_what;

  return env;
}

local hook_eaarl_mission_jobs_env_wrap, hook_eaarl_mission_jobs_env_unwrap;
/* DOCUMENT
  hook_add, "jobs_env_wrap", "hook_eaarl_mission_jobs_env_wrap";
  hook_add, "jobs_env_unwrap", "hook_eaarl_mission_jobs_env_unwrap";
  makeflow_run, conf, ... ;
  hook_remove, "jobs_env_wrap", "hook_eaarl_mission_jobs_env_wrap";
  hook_remove, "jobs_env_unwrap", "hook_eaarl_mission_jobs_env_unwrap";

  These two hooks are used to send the loaded mission data to jobs, as
  indicated above.
*/

func hook_eaarl_mission_jobs_env_wrap(env) {
  wrapped = mission(wrap, cache_what="everything");
  if(wrapped(*,"bathconf_data"))
    save, wrapped, bathconf_data=serialize(wrapped.bathconf_data);
  if(wrapped(*,"ops_conf"))
    save, wrapped, ops_conf=serialize(wrapped.ops_conf);
  mission_fn = file_rootname(env.fn) + ".flight.pbd";
  obj2pbd, wrapped, mission_fn;
  save, env.env, mission_fn;
  return env;
}

func hook_eaarl_mission_jobs_env_unwrap(env) {
  wrapped = pbd2obj(env.env.mission_fn);
  if(wrapped(*,"bathconf_data"))
    save, wrapped, bathconf_data=deserialize(wrapped.bathconf_data);
  if(wrapped(*,"ops_conf"))
    save, wrapped, ops_conf=deserialize(wrapped.ops_conf);
  mission, unwrap, wrapped;
  return env;
}

hook_add, "mission_flights_auto_critical",
  "eaarl_mission_flights_auto_critical";
func eaarl_mission_flights_auto_critical(env) {
/* DOCUMENT eaarl_mission_flights_auto_critical(env)
  Hook function for "mission_flights_auto_critical" used by
  mission_flights_auto.
  SEE ALSO: mission_flights_auto
*/
  edbs = mission(details, autolist, env.flight, "edb file", env.path);
  env, has_critical=(numberof(edbs) > 0);
  return env;
}

hook_add, "mission_flights_auto_keys", "eaarl_mission_flights_auto_keys";
func eaarl_mission_flights_auto_keys(env) {
/* DOCUMENT eaarl_mission_flights_auto_keys(env)
  Hook function for "mission_flights_auto_keys" used by mission_flights_auto.
  SEE ALSO: mission_flights_auto
*/
  keys = env.keys;
  grow, keys, [
    "edb file",
    "pnav file",
    "ins file",
    "ops_conf file",
    "bathconf file",
    "rgb dir",
    "rgb file",
    "nir dir"
  ];
  save, env, keys;
  return env;
}

hook_add, "mission_details_autolist", "eaarl_mission_details_autolist";
func eaarl_mission_details_autolist(env) {
/* DOCUMENT eaarl_mission_details_autolist(env)
  Hook function for mission_details_autolist.
  SEE ALSO: mission_details_autolist
*/
  key = env.key;
  path = env.path;
  if(key == "edb file")
    env, result=autoselect_edb(path, options=1);
  else if(key == "pnav file")
    env, result=autoselect_pnav(path, options=1);
  else if(key == "ins file")
    env, result=autoselect_iexpbd(path, options=1);
  else if(key == "ops_conf file")
    env, result=autoselect_ops_conf(path, options=1);
  else if(key == "bathconf file")
    env, result=autoselect_bathconf(path, options=1);
  else if(key == "rgb dir")
    env, result=autoselect_rgb_dir(path, options=1);
  else if(key == "rgb file")
    env, result=autoselect_rgb_tar(path, options=1);
  else if(key == "nir dir")
    env, result=autoselect_nir_dir(path, options=1);
  return env;
}
