# vim: set ts=3 sts=3 sw=3 ai sr et:

package provide eaarl 1.0

namespace eval ::eaarl {}

package require eaarl::main
package require eaarl::bathconf
package require eaarl::chanconf
package require eaarl::drast
package require eaarl::jsonlog
package require eaarl::load
package require eaarl::mpconf
package require eaarl::pixelwf
package require eaarl::processing
package require eaarl::raster
package require eaarl::rawwf
package require eaarl::sasr
package require eaarl::sbconf
package require eaarl::settings
package require eaarl::sync
package require eaarl::transmit
package require eaarl::tscheck
package require eaarl::vegconf
package require eaarl::cfconf
package require plugins

namespace eval ::eaarl {
   # These must be provided by a plugin.
   if {![info exists channel_count]} {
      variable channel_count 0
   }
   if {![info exists channel_list]} {
      variable channel_list {}
   }

   variable process_mapping {
      "First Return Topo"  f
      "Submerged Topo"     b
      "Topo Under Veg"     v
      "Shallow Bathy"      sb
      "DEV: Multi-Peak (Experimental)" mp
      "DEV: Curve Fitting (Experimental)" cf
   }

   variable autoclean_after_process 1
   variable usecentroid 1
   variable avg_surf 1
   variable ext_bad_att 20
   variable interactive_batch [expr {$::alpsrc(cores_local) >= 3}]

   variable processing_mode f
   variable pro_var_next fs_all

   proc processing_mode_changed {a b c} {
      variable pro_var_next
      variable processing_mode

      set tokens [split $pro_var_next _]

      set mapping {
         f fs
         v veg
         b depth
         sb shallow
         mp mp
         cf cf
      }

      set prefix [lindex $tokens 0]
      if {
         $prefix in [dict values $mapping] &&
         $processing_mode in [dict keys $mapping]
      } {
         set prefix [dict get $mapping $processing_mode]
         set tokens [lreplace $tokens 0 0 $prefix]
      }

      ::hook::invoke "eaarl::processing_mode_changed" tokens

      set pro_var_next [join $tokens _]
   }

   namespace import ::plugins::make_hook
   namespace import ::plugins::define_hook_set
   namespace import ::plugins::make_handler
   namespace import ::plugins::define_handler_set

   define_hook_set load
   define_handler_set load
   proc load_eaarl {} {
      plugins::apply_hooks load
      plugins::apply_handlers load
      ::sf::mediator register [list ::eaarl::pixelwf::mediator::jump_soe]
      ::misc::idle ::l1pro::expix::reload_gui
      trace add variable \
            ::eaarl::processing_mode write ::eaarl::processing_mode_changed
      ::misc::idle [list catch ::mission::refresh_flights]
   }

   make_hook load "l1pro::expix::gui panels" {w} {
      ::eaarl::pixelwf::gui::panels_hook $w
   }

   make_handler load "mission_initialize_path_mission" {path} {
      ::mission::eaarl::initialize_path_mission $path
   }

   make_handler load "mission_initialize_path_flight" {flight path} {
      ::mission::eaarl::initialize_path_flight $flight $path
   }

   make_hook load "mission_menu_actions" {mb} {
      ::mission::eaarl::menu_actions $mb
   }

   make_handler load "mission_refresh_load" {flights extra} {
      ::mission::eaarl::refresh_load $flights $extra
   }
}