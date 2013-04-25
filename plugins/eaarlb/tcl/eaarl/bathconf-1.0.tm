# vim: set ts=4 sts=4 sw=4 ai sr et:

package provide eaarl::bathconf 1.0

# sync using: bathctl, set, "group", "key", val

namespace eval ::eaarl::bathconf {
    namespace import ::misc::tooltip

    # Array to hold configuration info in
    # Mapping is from Yorick:
    #       bathconf.data.GROUP.active.KEY
    # To Tcl:
    #       ::eaarl::bathconf::settings(GROUP.KEY)
    variable settings

    # An array to hold profiles in
    # No direct mapping, but kept updated by Yorick such that
    #       ::eaarl::bathconf::profiles(GROUP)
    # provides a list of profiles for GROUP
    variable profiles

    # An array of groups mapping each to its currently active profile
    # Mapping is from Yorick:
    #       .bathconf.data.GROUP.active_name
    # To Tcl:
    #       ::eaarl::bathconf::active_profile(GROUP)
    variable active_profile
}

# plot <window> [-opt val -opt val ...]
# plotcmd <window> [-opt val -opt val ...]
# config <window> [-opt val -opt val ...]
#
# Each of the above commands will launch the embedded window GUI for bathy
# plots if it does not exist. Each will also update the GUI with the given
# options, if any are provided.
#
# config does only the above. It returns the GUI's command.
#
# plot will additionally trigger a plot replot, using the window's current
# options. It returns the GUI's command.
#
# plotcmd is like plot but will instead return the Yorick command (suitable for
# sending via expect)

proc ::eaarl::bathconf::plotcmd {window args} {
    set gui [config $window {*}$args]
    return [$gui plotcmd]
}

proc ::eaarl::bathconf::plot {window args} {
    set gui [config $window {*}$args]
    $gui plot
    return $gui
}

proc ::eaarl::bathconf::config {window args} {
    set gui [namespace current]::window_$window
    if {[info commands $gui] ne ""} {
        $gui configure {*}$args
    } else {
        ::eaarl::bathconf::embed $gui {*}$args -window $window
    }
    return $gui
}

snit::type ::eaarl::bathconf::embed {
    option -window -readonly 1 -default 8 -configuremethod SetOpt
    option -raster -default 1 -configuremethod SetOpt
    option -channel -default 1 -configuremethod SetOpt
    option -pulse -default 60 -configuremethod SetOpt
    option -group -default {} -configuremethod SetGroup

    component window
    component pane

    # Group currently connected to. Used so that we don't need to repeatedly
    # change the GUI configuration. An empty string is used to indicate that no
    # group is set.
    variable curgroup ""

    # The current decay setting used. Used so that we don't need to repeatly
    # change the GUI configuration.
    variable curdecay ""

    # Some controls want specific settings. This is a dictionary that maps
    # controls to the settings they want.
    variable wantsetting {}

    # This stores the name of the profile combobox so we can apply the list
    # variable and text variable to it.
    variable wantprofiles {}

    # List of controls that accept user interaction. These will be disabled if
    # there is no group selected.
    variable controls {}

    # Empty variable. Used for controls when they're disabled. Keep empty.
    variable empty ""

    variable show_browse 1
    variable show_wf 1
    variable show_rast 1

    variable wf_chan1 0
    variable wf_chan2 0
    variable wf_chan3 0
    variable wf_chan4 0
    variable wf_win 9

    variable rast_plot 0
    variable rast_bath 0
    variable rast_win 11

    constructor {args} {
        if {[dict exist $args -window]} {
            set win [dict get $args -window]
        } else {
            set win 8
        }
        set window [::yorick::window::path $win]
        $window clear_gui
        $window configure -owner $self

        set pane [$window pane bottom]

        $self Gui
        $self configure {*}$args
    }

    method Gui {} {
        # Clear any current GUI
        foreach path [winfo children $pane] {
            destroy $path
        }

        # Reset tracking variables
        set controls [list]
        set wantsetting [dict create]
        set wantprofiles [list]

        # Create GUI
        set sections [list]
        if {$show_browse} {
            lappend sections browse
        }
        if {$show_wf} {
            lappend sections waveforms
        }
        if {$show_rast} {
            lappend sections raster
        }
        lappend sections settings
        foreach section $sections {
            ttk::frame $pane.$section \
                    -relief ridge \
                    -borderwidth 1 \
                    -padding 1
            $self Gui_$section $pane.$section
            pack $pane.$section -side top -fill x -expand 1
        }

        $self UpdateGroup 1
    }

    method Gui_browse {f} {
        ttk::label $f.lblChan -text "Channel:"
        mixin::combobox $f.cboChan \
                -textvariable [myvar options](-channel) \
                -state readonly \
                -width 2 \
                -values {1 2 3 4}
        ::mixin::revertable $f.cboChan \
                -applycommand [mymethod IdlePlot]
        bind $f.cboChan <<ComboboxSelected>> +[list $f.cboChan apply]
        ttk::separator $f.sepChan \
                -orient vertical
        ttk::label $f.lblRast -text "Raster:"
        ttk::spinbox $f.spnRast \
                -textvariable [myvar options](-raster) \
                -from 1 -to 100000000 -increment 1 \
                -width 5
        ::mixin::revertable $f.spnRast \
                -command [list $f.spnRast apply] \
                -valuetype number \
                -applycommand [mymethod IdlePlot]
        ttk::button $f.btnRastPrev \
                -image ::imglib::vcr::stepbwd \
                -style Toolbutton \
                -command [mymethod IncrRast -1] \
                -width 0
        ttk::button $f.btnRastNext \
                -image ::imglib::vcr::stepfwd \
                -style Toolbutton \
                -command [mymethod IncrRast 1] \
                -width 0
        ttk::separator $f.sepRast \
                -orient vertical
        ttk::label $f.lblPulse -text "Pulse:"
        ttk::spinbox $f.spnPulse \
                -textvariable [myvar options](-pulse) \
                -from 1 -to 120 -increment 1 \
                -width 3
        ::mixin::revertable $f.spnPulse \
                -command [list $f.spnPulse apply] \
                -valuetype number \
                -applycommand [mymethod IdlePlot]
        ttk::button $f.btnPulsePrev \
                -image ::imglib::vcr::stepbwd \
                -style Toolbutton \
                -command [mymethod IncrPulse -1] \
                -width 0
        ttk::button $f.btnPulseNext \
                -image ::imglib::vcr::stepfwd \
                -style Toolbutton \
                -command [mymethod IncrPulse 1] \
                -width 0
        ttk::separator $f.sepPulse \
                -orient vertical
        ttk::button $f.btnLims \
                -image ::imglib::misc::limits \
                -style Toolbutton \
                -width 0 \
                -command [mymethod limits]
        ttk::button $f.btnReplot \
                -image ::imglib::misc::refresh \
                -style Toolbutton \
                -width 0 \
                -command [mymethod plot]

        pack $f.lblChan $f.cboChan \
                $f.sepChan \
                $f.lblRast $f.spnRast $f.btnRastPrev $f.btnRastNext \
                $f.sepRast \
                $f.lblPulse $f.spnPulse $f.btnPulsePrev $f.btnPulseNext \
                $f.sepPulse \
                $f.btnLims $f.btnReplot \
                -side left
        pack $f.spnRast -fill x -expand 1
        pack $f.sepChan $f.sepRast $f.sepPulse -fill y -padx 2

        lappend controls $f.cboChan $f.spnRast $f.btnRastPrev $f.btnRastNext \
                $f.spnPulse $f.btnPulsePrev $f.btnPulseNext $f.btnLims \
                $f.btnReplot

        tooltip $f.btnLims \
                "Reset the limits on the plot so everything is visible."
        tooltip $f.btnReplot \
                "Replots the current plot. Also plots linked plots (such as
                raster or raw waveform) if any are selected."
    }

    method Gui_waveforms {f} {
        ttk::label $f.lblWf -text "Plot waveforms:"
        foreach i {1 2 3 4} {
            ttk::checkbutton $f.chkChan$i -text $i \
                    -variable [myvar wf_chan$i] \
                    -command [mymethod WfEnabler $f.spnWin]
        }
        ttk::label $f.lblWin -text "Win:"
        ttk::spinbox $f.spnWin \
                -width 3 \
                -textvariable [myvar wf_win]
        $self WfEnabler $f.spnWin

        pack $f.lblWf $f.chkChan1 $f.chkChan2 $f.chkChan3 $f.chkChan4 \
                -side left
        pack $f.spnWin $f.lblWin \
                -side right
    }

    method Gui_raster {f} {
        ttk::checkbutton $f.chkRast -text "Plot raster" \
                -variable [myvar rast_plot]
        ttk::checkbutton $f.chkBottom -text "Bottom markers" \
                -variable [myvar rast_bath]
        ttk::label $f.lblWin -text "Win:"
        ttk::spinbox $f.spnWin \
                -width 3 \
                -textvariable [myvar rast_win]

        ::mixin::statevar $f.spnWin \
                -statemap {0 disabled 1 normal} \
                -statevariable [myvar rast_plot]

        pack $f.chkRast $f.chkBottom \
                -side left
        pack $f.spnWin $f.lblWin \
                -side right
    }

    method Gui_settings {f} {
        ttk::label $f.lblSettings -text "Settings:"
        ttk::label $f.lblGroup \
                -textvariable [myvar options](-group)
        ttk::label $f.lblProfile -text "Profile:"
        mixin::combobox $f.cboProfile \
                -state readonly \
                -width 6
        ::mixin::revertable $f.cboProfile
        bind $f.cboProfile <<ComboboxSelected>> +[list $f.cboProfile apply]
        ttk::button $f.btnAdd \
                -image ::imglib::plus \
                -style Toolbutton \
                -command [mymethod ProfileAdd] \
                -width 0
        ttk::button $f.btnRem \
                -image ::imglib::x \
                -style Toolbutton \
                -command [mymethod ProfileDel] \
                -width 0
        ttk::menubutton $f.mnuTools -text "Tools" \
                -width 0 \
                -menu $f.mnuTools.mb
        $self Gui_settings_menu $f.mnuTools.mb

        lower [ttk::frame $f.fra1]
        pack $f.lblSettings -in $f.fra1 -side left
        pack $f.lblGroup -in $f.fra1 -side left

        lower [ttk::frame $f.fra2]
        pack $f.lblProfile -in $f.fra2 -side left
        pack $f.cboProfile -in $f.fra2 -side left -fill x -expand 1

        lower [ttk::frame $f.fra3]
        grid $f.fra1 $f.fra2 $f.btnAdd $f.btnRem $f.mnuTools \
                -in $f.fra3 -sticky news
        grid $f.mnuTools -padx {4 0}
        grid columnconfigure $f.fra3 {0 1} -weight 1 -uniform 1

        pack $f.fra3 -side top -fill both -expand 1

        foreach {cmd desc} {
            surfsat "Surface, Saturation, and Smoothing"
            backscatter "Backscatter Model"
            bottom "Bottom Detection"
            validate "Bottom Validation: Pulse Wings"
        } {
            set path $f.lfr${cmd}
            ::mixin::labelframe::collapsible $path -text $desc
            $self Gui_settings_${cmd} [$path interior]
            pack $path -side top -fill x
        }

        lappend controls $f.cboProfile $f.btnAdd $f.btnRem $f.mnuTools
        lappend wantprofiles $f.cboProfile
    }

    method Gui_settings_menu {mb} {
        menu $mb
        $mb add command -label "Rename current profile" \
                -command [mymethod ProfileRename]
        $mb add separator
        $mb add command -label "Save to file..." \
                -command [mymethod FileSave]
        $mb add command -label "Load from file..." \
                -command [mymethod FileLoad]
    }

    method Gui_settings_surfsat {f} {
        ttk::label $f.lblSat -text "Max Sat:"
        ttk::spinbox $f.spnSat \
                -from 0 -to 1000 -increment 1 \
                -width 4
        ::mixin::revertable $f.spnSat \
                -command [list $f.spnSat apply] \
                -valuetype number
        ttk::label $f.lblSfc -text "Surface Last:"
        ttk::spinbox $f.spnSfc \
                -from 1 -to 1000 -increment 1 \
                -width 4
        ::mixin::revertable $f.spnSfc \
                -command [list $f.spnSfc apply] \
                -valuetype number
        ttk::label $f.lblSmo -text "Smooth:"
        ttk::spinbox $f.spnSmo \
                -from 0 -to 1000 -increment 1 \
                -width 4
        ::mixin::revertable $f.spnSmo \
                -command [list $f.spnSmo apply] \
                -valuetype number

        pack $f.lblSat $f.spnSat $f.lblSfc $f.spnSfc \
                $f.lblSmo $f.spnSmo \
                -side left

        lappend controls $f.spnSat $f.spnSfc $f.spnSmo
        dict set wantsetting $f.spnSat maxsat
        dict set wantsetting $f.spnSfc sfc_last
        dict set wantsetting $f.spnSmo smoothwf

        tooltip $f.lblSat $f.spnSat \
                "Maximum number of saturated samples permitted.

                If more than this many samples are saturated, the waveform is
                rejected and no bottom will be found."
        tooltip $f.lblSfc $f.spnSfc \
                "Last sample where first return saturation may begin.

                This is used to determine where the surface starts."
        tooltip $f.lblSmo $f.spnSmo \
                "Smoothing factor to apply to waveform.

                If this is non-zero, then a moving average is applied to the
                waveform. This setting specifies how many samples on either
                side of a sample should be used to generate the average. So
                with a smoothing setting of 2, each sample will be averaged
                using the 2 adjacent samples on either side; thus the average
                is calculated using 5 total samples."
    }

    method Gui_settings_backscatter {f} {
        set curdecay [$self GetDecay]
        if {$curdecay eq "lognormal"} {
            $self Gui_settings_backscatter_lognorm $f
        } else {
            $self Gui_settings_backscatter_exp $f
        }
    }

    method Gui_settings_backscatter_exp {f} {
        ttk::label $f.lblType -text "Type:"
        mixin::combobox $f.cboType \
                -state readonly \
                -width 11 \
                -values {exponential lognormal}
        ::mixin::revertable $f.cboType
        ttk::label $f.lblLaser -text "Laser:"
        bind $f.cboType <<ComboboxSelected>> +[list $f.cboType apply]
        ttk::spinbox $f.spnLaser \
                -from -5 -to -1 -increment 0.1 \
                -width 4
        ::mixin::revertable $f.spnLaser \
                -command [list $f.spnLaser apply] \
                -valuetype number
        ttk::label $f.lblWater -text "Water:"
        ttk::spinbox $f.spnWater \
                -from -10 -to -0.1 -increment 0.1 \
                -width 4
        ::mixin::revertable $f.spnWater \
                -command [list $f.spnWater apply] \
                -valuetype number
        ttk::label $f.lblAgc -text "AGC:"
        ttk::spinbox $f.spnAgc \
                -from -10 -to -0.1 -increment 0.1 \
                -width 4
        ::mixin::revertable $f.spnAgc \
                -command [list $f.spnAgc apply] \
                -valuetype number

        pack $f.lblType $f.cboType $f.lblLaser $f.spnLaser \
                $f.lblWater $f.spnWater $f.lblAgc $f.spnAgc \
                -side left

        lappend controls $f.cboType $f.spnLaser $f.spnWater $f.spnAgc
        dict set wantsetting $f.cboType decay
        dict set wantsetting $f.spnLaser laser
        dict set wantsetting $f.spnWater water
        dict set wantsetting $f.spnAgc agc

        tooltip $f.lblType $f.cboType \
                "Backscatter model to use.

                \"exponential\" models backscatter using an exponential decay
                formula.

                \"lognormal\" models backscatter using a log-normal
                distribution.

                For both types, the basic idea is to model the backscatter /
                signal decay mathematically. That model is then subtracted from
                the waveform, and what's left is them adjusted using an AGC
                model."
        tooltip $f.lblLaser $f.spnLaser \
                "Exponential decay coefficient for the laser.

                This attempts to model the decay of the signal due to the decay
                of the laser signal. This coefficient is passed through the
                exponential function.

                This is normally a negative number. Values closer to 0 will
                result in a slower decay.

                Laser and Water use the same math, except Water's curve is
                multiplied by 0.25 to make it weaker. They are then added
                together."
        tooltip $f.lblWater $f.spnWater \
                "Exponential decay coefficient for the water column.

                This attempts to model the decay of the signal due to the water
                column. This coefficient is passed through the exponential
                function.

                This is normally a negative number. Values closer to 0 will
                result in a slower decay.

                Laser and Water use the same math, except Water's curve is
                multiplied by 0.25 to make it weaker. They are then added
                together."
        tooltip $f.lblAgc $f.spnAgc \
                "Automatic gain control coefficient.

                This weakens the waveform signal towards the beginning,
                eventually tapering to full strength towards the end.

                This is normally a negative number. Values closer to 0 will
                result in a more gradual transition from weakened to full
                strength. Values with very large negative values (such as
                -1000) effectively leave the entire waveform at full strength."
    }

    method Gui_settings_backscatter_lognorm {f} {
        ttk::label $f.lblType -text "Type:"
        mixin::combobox $f.cboType \
                -state readonly \
                -width 11 \
                -values {exponential lognormal}
        ::mixin::revertable $f.cboType
        bind $f.cboType <<ComboboxSelected>> +[list $f.cboType apply]
        ttk::label $f.lblMean -text "Mean:"
        ttk::spinbox $f.spnMean \
                -from -100 -to 100 -increment 0.05 \
                -width 4
        ::mixin::revertable $f.spnMean \
                -command [list $f.spnMean apply] \
                -valuetype number
        ttk::label $f.lblStd -text "Std Dev:"
        ttk::spinbox $f.spnStd \
                -from -100 -to 100 -increment 0.05 \
                -width 4
        ::mixin::revertable $f.spnStd \
                -command [list $f.spnStd apply] \
                -valuetype number
        ttk::label $f.lblAgc -text "AGC:"
        ttk::spinbox $f.spnAgc \
                -from -10 -to -0.1 -increment 0.1 \
                -width 4
        ::mixin::revertable $f.spnAgc \
                -command [list $f.spnAgc apply] \
                -valuetype number
        ttk::label $f.lblXsh -text "X Shift:"
        ttk::spinbox $f.spnXsh \
                -from -100 -to 100 -increment 1 \
                -width 4
        ::mixin::revertable $f.spnXsh \
                -command [list $f.spnXsh apply] \
                -valuetype number
        ttk::label $f.lblXsc -text "X Scale:"
        ttk::spinbox $f.spnXsc \
                -from 1 -to 100 -increment 1 \
                -width 4
        ::mixin::revertable $f.spnXsc \
                -command [list $f.spnXsc apply] \
                -valuetype number
        ttk::label $f.lblTie -text "Tie Point:"
        ttk::spinbox $f.spnTie \
                -from 1 -to 1000 -increment 1 \
                -width 4
        ::mixin::revertable $f.spnTie \
                -command [list $f.spnTie apply] \
                -valuetype number

        lower [ttk::frame $f.fra1]
        pack $f.lblType $f.cboType $f.lblMean $f.spnMean $f.lblStd \
                $f.spnStd $f.lblAgc $f.spnAgc \
                -in $f.fra1 -side left
        lower [ttk::frame $f.fra2]
        pack $f.lblXsh $f.spnXsh $f.lblXsc $f.spnXsc $f.lblTie $f.spnTie \
                -in $f.fra2 -side left

        pack $f.fra1 $f.fra2 -side top -anchor w

        lappend controls $f.cboType $f.spnMean $f.spnStd $f.spnAgc \
                $f.spnXsh $f.spnXsc $f.spnTie
        dict set wantsetting $f.cboType decay
        dict set wantsetting $f.spnMean mean
        dict set wantsetting $f.spnStd stdev
        dict set wantsetting $f.spnAgc agc
        dict set wantsetting $f.spnXsh xshift
        dict set wantsetting $f.spnXsc xscale
        dict set wantsetting $f.spnTie tiepoint

        tooltip $f.lblType $f.cboType \
                "Backscatter model to use.

                \"exponential\" models backscatter using an exponential decay
                formula.

                \"lognormal\" models backscatter using a log-normal
                distribution.

                For both types, the basic idea is to model the backscatter /
                signal decay mathematically. That model is then subtracted from
                the waveform, and what's left is them adjusted using an AGC
                model."
        tooltip $f.spnMean $f.lblMean \
                "Mean coefficient for log-normal distribution."
        tooltip $f.lblStd $f.spnStd \
                "Standard deviation coefficient for log-normal distribution."
        tooltip $f.lblAgc $f.spnAgc \
                "Automatic gain control coefficient.

                This weakens the waveform signal towards the beginning,
                eventually tapering to full strength towards the end.

                This is normally a negative number. Values closer to 0 will
                result in a more gradual transition from weakened to full
                strength. Values with very large negative values (such as
                -1000) effectively leave the entire waveform at full strength."
        tooltip $f.lblXsh $f.spnXsh \
                "Number of samples to shift the distribution along the X axis."
        tooltip $f.lblXsc $f.spnXsc \
                "Scaling factor to apply along X axis.

                Larger values will stretch the distribution further
                left-to-right. Smaller values will compress it."
        tooltip $f.lblTie $f.spnTie \
                "The sample at which to scale the distribution to.

                The log-normal distribution will be vertically scaled so that
                its graph crosses the raw waveform's graph at this pixel."
    }

    method Gui_settings_bottom {f} {
        ttk::label $f.lblFirst -text "First:"
        ttk::spinbox $f.spnFirst \
                -from 1 -to 1000 -increment 1 \
                -width 4
        ::mixin::revertable $f.spnFirst \
                -command [list $f.spnFirst apply] \
                -valuetype number
        ttk::label $f.lblLast -text "Last:"
        ttk::spinbox $f.spnLast \
                -from 1 -to 1000 -increment 1 \
                -width 4
        ::mixin::revertable $f.spnLast \
                -command [list $f.spnLast apply] \
                -valuetype number
        ttk::label $f.lblThresh -text "Threshold:"
        ttk::spinbox $f.spnThresh \
                -from 1 -to 1000 -increment 1 \
                -width 4
        ::mixin::revertable $f.spnThresh \
                -command [list $f.spnThresh apply] \
                -valuetype number

        pack $f.lblFirst $f.spnFirst $f.lblLast $f.spnLast \
                $f.lblThresh $f.spnThresh \
                -side left

        lappend controls $f.spnFirst $f.spnLast $f.spnThresh
        dict set wantsetting $f.spnFirst first
        dict set wantsetting $f.spnLast last
        dict set wantsetting $f.spnThresh thresh

        tooltip $f.lblFirst $f.lblLast $f.lblThresh \
                $f.spnFirst $f.spnLast $f.spnThresh \
                "First, Last, and Thresh define where to look for a bottom.

                The bottom will only be looked for between samples First and
                Last. Only signals that raise above Thresh will be considered.

                In the graph, First and Last are plotted with vertical red
                lines. Thresh is plotted as a horizontal green line connecting
                them. The bottom must occur between the red lines, with a peak
                above the green line."
    }

    method Gui_settings_validate {f} {
        ttk::label $f.lblLeft -text "Left Dist/Factor:"
        ttk::spinbox $f.spnLeftDist \
                -from 1 -to 100 -increment 1 \
                -width 4
        ::mixin::revertable $f.spnLeftDist \
                -command [list $f.spnLeftDist apply] \
                -valuetype number
        ttk::spinbox $f.spnLeftFact \
                -from 0 -to 1 -increment 0.05 \
                -width 4
        ::mixin::revertable $f.spnLeftFact \
                -command [list $f.spnLeftFact apply] \
                -valuetype number
        ttk::label $f.lblRight -text "Right Dist/Factor:"
        ttk::spinbox $f.spnRightDist \
                -from 1 -to 100 -increment 1 \
                -width 4
        ::mixin::revertable $f.spnRightDist \
                -command [list $f.spnRightDist apply] \
                -valuetype number
        ttk::spinbox $f.spnRightFact \
                -from 0 -to 1 -increment 0.05 \
                -width 4
        ::mixin::revertable $f.spnRightFact \
                -command [list $f.spnRightFact apply] \
                -valuetype number

        pack $f.lblLeft $f.spnLeftDist $f.spnLeftFact \
                $f.lblRight $f.spnRightDist $f.spnRightFact \
                -side left

        lappend controls $f.spnLeftDist $f.spnLeftFact \
                $f.spnRightDist $f.spnRightFact
        dict set wantsetting $f.spnLeftDist lwing_dist
        dict set wantsetting $f.spnLeftFact lwing_factor
        dict set wantsetting $f.spnRightDist rwing_dist
        dict set wantsetting $f.spnRightFact rwing_factor

        tooltip $f.lblLeft $f.spnLeftDist $f.spnLeftFact \
                $f.lblRight $f.spnRightDist $f.spnRightFact \
                "Defines the pulse wing locations.

                The \"pulse wings\" are used to validate the bottom by
                examining its shape. The samples at the given Dist to the left
                and right of the bottom are examined and must be found to be no
                more than Factor of the peak intensity value.

                In the graph, the pulse wings are plotted as magenta dots. The
                waveform must always be beneath these dots in order to
                validate. These allow the algorithm to reject wide pulse
                shapes."
    }

    method ProfileAdd {} {
        if {
            [::getstring::tk_getString $window.gs text \
                    "Please provide the new profile name:"]
        } {
            exp_send "bathconf, profile_add, \"$options(-group)\",\
                    \"$text\";\r"
        }
    }

    method ProfileDel {} {
        exp_send "bathconf, profile_del, \"$options(-group)\",\
                \"$::eaarl::bathconf::active_profile($options(-group))\";\r"
    }

    method ProfileRename {} {
        set old $::eaarl::bathconf::active_profile($options(-group))
        if {
            [::getstring::tk_getString $window.gs new \
                    "What would you like to rename \"$old\" to?"]
        } {
            if {$old ne $new} {
                exp_send "bathconf, profile_rename, \"$options(-group)\",\
                        \"$old\", \"$new\";\r"
            }
        }
    }

    method FileLoad {} {
        set fn [tk_getOpenFile \
                -parent $window \
                -title "Select file to load" \
                -filetypes {
                    {{Bathy configuration files} {.bathconf}}
                    {{JSON files} {.json}}
                    {{bctl files} {.bctl}}
                    {{All files} {*}}
                }]
        if {$fn ne ""} {
            exp_send "bathconf, read, \"$fn\"; "
            $self plot
        }
    }

    method FileSave {} {
        set fn [tk_getSaveFile \
                -parent $window \
                -title "Select destination" \
                -filetypes {
                    {{Bathy configuration files} {.bathconf}}
                    {{All files} {*}}
                }]
        if {$fn ne ""} {
            exp_send "bathconf, write, \"$fn\";\r"
        }
    }

    method SetOpt {option value} {
        set options($option) $value
        $self UpdateTitle
    }

    method SetGroup {option value} {
        set options($option) $value
        $self UpdateGroup
    }

    method UpdateTitle {} {
        wm title $window "Window $options(-window) - Raster $options(-raster)\
                Pulse $options(-pulse) Channel $options(-channel)"
    }

    method UpdateGroup {{force 0}} {
        if {!$force && $curgroup eq $options(-group)} return
        set group $options(-group)

        set ns ::eaarl::bathconf

        if {$curgroup ne ""} {
            trace remove variable ${ns}::settings(${curgroup},decay) \
                    write [mymethod TraceDecay]
        }

        if {$group eq ""} {
            set var [myvar empty]
            foreach path $controls {
                $path state disabled
            }
            dict for {path key} $wantsetting {
                $path configure -textvariable $var
            }
            foreach path $wantprofiles {
                $path configure -listvariable $var -textvariable $var
            }
        } else {
            foreach path $controls {
                $path state !disabled
            }
            dict for {path key} $wantsetting {
                $path configure \
                        -textvariable ${ns}::settings(${group},${key}) \
                        -applycommand [mymethod SetKey $key]
            }
            foreach path $wantprofiles {
                $path configure \
                        -textvariable ${ns}::active_profile(${group}) \
                        -listvariable ${ns}::profiles(${group}) \
                        -applycommand [mymethod SetProfile]
            }
            trace add variable ${ns}::settings(${group},decay) \
                    write [mymethod TraceDecay]
        }
        set curgroup $options(-group)
    }

    method WfEnabler {widget} {
        if {$wf_chan1 || $wf_chan2 || $wf_chan3 || $wf_chan4} {
            $widget state !disabled
        } else {
            $widget state disabled
        }
    }

    method IncrRast {amt} {
        incr options(-raster) $amt
        if {$options(-raster) < 1} {
            set options(-raster) 1
        }
        $self plot
    }

    method IncrPulse {amt} {
        incr options(-pulse) $amt
        if {$options(-pulse) < 1} {
            set options(-pulse) 1
        } elseif {$options(-pulse) > 120} {
            set options(-pulse) 120
        }
        $self plot
    }

    method IdlePlot {old new} {
        ::misc::idle [mymethod plot]
    }

    method SetKey {key old new} {
        exp_send "bathconf, set, \"$options(-group)\", \"$key\", \"$new\"; "
        $self plot
        return -code error
    }

    method SetProfile {old new} {
        exp_send "bathconf, profile_select, \"$options(-group)\", \"$new\"; "
        $self plot
        return -code error
    }

    method GetDecay {} {
        if {$curgroup eq ""} return ""
        return $::eaarl::bathconf::settings($curgroup,decay)
    }

    # If the decay value changes, the GUI needs to be re-made.
    method TraceDecay {name1 name2 op} {
        if {$curdecay ne [$self GetDecay]} {
            $self Gui
        }
    }

    method limits {} {
        exp_send "window, $options(-window); limits;\r"
    }

    # Returns the command that can be used to (re)plot this window
    method plotcmd {} {
        set cmd ""
        append cmd "ex_bath, $options(-raster), $options(-pulse), graph=1,\
                win=$options(-window), xfma=1"
        if {$options(-channel)} {
            append cmd ", forcechannel=$options(-channel)"
        }
        append cmd "; "
        return $cmd
    }

    # (Re)plots the window
    method plot {} {
        set cmd [$self plotcmd]

        if {$rast_plot} {
            append cmd " show_rast, $options(-raster), win=${rast_win},\
                    bathy=${rast_bath}, channel=$options(-channel),\
                    autolims=0;"
        }

        if {$wf_chan1 || $wf_chan2 || $wf_chan3 || $wf_chan4} {
            append cmd " show_wf, $options(-raster), $options(-pulse),\
                    win=${wf_win}"
            ::misc::appendif cmd \
                    $wf_chan1   ", c1=1" \
                    $wf_chan2   ", c2=1" \
                    $wf_chan3   ", c3=1" \
                    $wf_chan4   ", c4=1" \
                    1           ";"
        }

        exp_send "$cmd\r"
    }

    # Used by associated window when resetting the GUI for something else
    method clear_gui {} {
        $self destroy
    }
}
