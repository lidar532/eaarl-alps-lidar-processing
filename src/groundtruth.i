// vim: set ts=3 sts=3 sw=3 ai sr et:
require, "eaarl.i";

func gt_extract_comparisons(model, truth, modelmode=, truthmode=, radius=) {
/* DOCUMENT gt_extract_comparisons(model, truth, modelmode=, truthmode=,
   radius=)

   Returns a group object with the comparison results for the given MODEL
   against the given TRUTH.

   The parameters, MODEL and TRUTH, must be values suitable for passing to
   data2xyz. This means they can be arrays of type VEG__, FS, etc. They can
   also be 3xn or nx3 arrays of doubles.

   Options MODELMODE= and TRUTHMODE= specify how to interpret MODEL and TRUTH,
   respectively. Defaults are:
      modelmode="fs"
      truthmode="fs"
   However, any of the normal values may be passed ("be", "ba", etc.).

   RADIUS= is the search radius to use about each truth point, in meters. It
   defaults to 1 meter.

   Return result is a group object with these members:
      truth - The elevation value from TRUTH.
      m_best - The elevation value from MODEL that is closest in value to
         TRUTH's elevation value, among those points within the RADIUS.
      m_nearest - The elevation value from MODEL that is spatially closest to
         TRUTH's x,y location.
      m_average - The average elevation value for the MODEL points within
         RADIUS of TRUTH.
      m_median - The median elevation value for the MODEL points within RADIUS
         of TRUTH.
*/
   extern curzone;
   local mx, my, mz, tx, ty, tz;
   default, radius, 1.;
   radius = double(radius);

   // Use curzone if it's defined, otherwise arbitrarily make it 15. The zone
   // really doesn't matter since all we're using it for is to dummy out tile
   // names as part of partitioning.
   zone = curzone ? curzone : 15;

   data2xyz, model, mx, my, mz, mode=modelmode;
   data2xyz, truth, tx, ty, tz, mode=truthmode;

   // Eliminate model points outside of bbox+radius from truth points. Easy to
   // do, and results in huge savings if the model points cover a much larger
   // region than the truth points.
   w = data_box(mx, my, [tx(min),tx(max),ty(min),ty(max)] + radius*[-1,1,-1,1]);
   if(!numberof(w))
      error, "Points do not overlap";
   mx = mx(w);
   my = my(w);
   mz = mz(w);

   // We seek four results:
   //    best: The model elevation closest to truth
   //    nearest: The model elevation for the point spatially closest to truth
   //    average: Average of model elevations in radius about truth
   //    median: Median of model elevations in radius about truth
   m_best = m_nearest = m_average = m_median = array(double, dimsof(tx));

   // Some or all of the truth points may not have a model point within radius;
   // such points must be discarded. "keep" tracks which points have yielded
   // results.
   keep = array(char(0), dimsof(tx));

   // In order to reduce the overall number of point-to-point comparisons
   // necessary, the truth data is partitioned into successively smaller
   // regions. The corresponding model points are extracted for each partition.
   // This works especially well when the truth points are clustered in several
   // disparate areas.
   //
   // A stack is used to handle the partitioning. Each item in the stack is a
   // group object with three members:
   //    t - index list into the truth data for this set of points
   //    m - index list into the model data that corresponds to the above
   //    schemes - string array with the tiling schemes that need to be applied
   //          yet for this point cloud's partitioning
   //
   // When an item is popped off the stack, one of two things happens depending
   // on the number of schemes defined for it. If the number of schemes is
   // non-zero, then the truth points are partitioned with the first scheme in
   // the list. Each tile gets pushed onto the stack as a new item; each will
   // be provided with the model points that match the truth points' area as
   // well as with the array of remaining schemes that must be applied.
   //
   // If an item is popped that has no remaining schemes, then the points are
   // analyzed to extract the relevant model values for each truth value. These
   // values go in m_best, m_nearest, etc.
   stack = deque();
   stack, push, save(t=indgen(numberof(tx)), m=indgen(numberof(mx)),
      schemes=["it","dt","dtquad","dtcell"]);

   t0 = array(double, 3);
   timer, t0;
   tp = t0;
   while(stack(count,)) {
      top = stack(pop,);
      if(numberof(top.schemes)) {
         tiles = partition_by_tile(tx(top.t), ty(top.t), zone, top.schemes(1),
            buffer=0);
         names = h_keys(tiles);
         count = numberof(names);
         schemes = (numberof(top.schemes) > 1 ? top.schemes(2:) : []);
         for(i = 1; i <= count; i++) {
            t = top.t(tiles(names(i)));
            xmin = tx(t)(min) - radius;
            ymin = ty(t)(min) - radius;
            xmax = tx(t)(max) + radius;
            ymax = ty(t)(max) + radius;
            idx = data_box(mx(top.m), my(top.m), xmin, xmax, ymin, ymax);
            if(numberof(idx)) {
               m = top.m(idx);
               stack, push, save(t, m, schemes);
            }
         }
      } else {
         X = mx(top.m);
         Y = my(top.m);
         Z = mz(top.m);
         count = numberof(top.t);
         for(i = 1; i <= count; i++) {
            j = top.t(i);
            idx = find_points_in_radius(tx(j), ty(j), X, Y, radius=radius);
            if(!numberof(idx))
               continue;

            XP = X(idx);
            YP = Y(idx);
            ZP = Z(idx);

            keep(j) = 1;

            dist = abs(ZP - tz(j));
            m_best(j) = ZP(dist(mnx));

            dist = ((tx(j) - XP)^2 + (ty(j) - YP)^2) ^ .5;
            m_nearest(j) = ZP(dist(mnx));

            m_average(j) = ZP(avg);
            m_median(j) = median(ZP);
         }
      }
      // The timer_remaining call will be fairly inaccurate, but in a
      // pessimistic sense. There's a larger up-front cost due to the
      // partitioning. Still, in extremely large datasets, this is better than
      // nothing.
      if(anyof(match))
         timer_remaining, t0, numberof(where(match)), numberof(match), tp,
            interval=10;
   }
   timer_finished, t0;

   if(noneof(keep))
      return [];
   mx = my = mz = tx = ty = [];

   w = where(keep);
   truth = tz(w);
   m_best = m_best(w);
   m_nearest = m_nearest(w);
   m_average = m_average(w);
   m_median = m_median(w);

   return save(truth, m_best, m_nearest, m_average, m_median);
}

func analysis_plot(z1, z2, win=, xtitle=, ytitle=) {
   default, win, window();
   default, xtitle, "Ground Truth Data (m)";
   default, ytitle, "Lidar Data (m)";

   // z1 = truth; z2 = lidar
   zdif = z2 - z1;

   // Line of equality
   eq_lo = max(z2(min), z1(min));
   eq_hi = min(z2(max), z1(max));
   eq = [eq_lo, eq_hi];

   // Least-squares-fit line
   lsqx = [z1(min), z1(max)];
   lsqy = fitlsq(z2, z1, lsqx);

   txt_rmse = swrite(format="RMSE = %.1f cm", zdif(rms)*100);
   txt_me = swrite(format="ME = %.1f cm", zdif(avg)*100);
   txt_count = swrite(format="%d points", numberof(z1));

   wbkp = current_window();
   window, win;
   fma;
   // Scatter plot of points
   plmk, z2, z1, width=10, marker=4, msize=0.1, color="black";
   // Line of equality
   plg, eq, eq, width=3, type="dash";
   // Least-squares-fit line
   plg, lsqy, lsqx, color="black", width=3;
   vp = viewport();
   tx = vp(1) + 0.01;
   ty = vp(4);
   plt, txt_rmse, tx, (ty -= .02);
   plt, txt_me, tx, (ty -= .02);
   plt, txt_count, tx, (ty -= .02);
   xytitles, xtitle, ytitle;
   limits, square=1;
   limits;
   window_select, wbkp;
}
