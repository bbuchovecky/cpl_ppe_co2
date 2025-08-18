#!/bin/csh

# INCOMPLETE

module load ncl nco

# Location of postprocessing timeseries scripts
setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/pp-offline/derecho/LR/

# Location of history files to archive as timeseries
setenv DOUT_S_ROOT /glade/derecho/scratch/${USER}/archive/

# The postprocessing run directory
setenv CASEROOT /glade/derecho/scratch/${USER}/postp

# Custom xml timeseries settings
set TIMESERIES_XML = /glade/u/home/bbuchovecky/projects/cpl_ppe_co2/hist/code/05_postprocess/env_timeseries_coupPPE.xml

# Case names
set CASETYPE   = coupPPE-hist
set CASEPREFIX = f.e22.FHIST_BGC.f19_f17_mg17
set CASENUM    = ( 000 )

# set CASEPREFIX = f.e22.FHIST_BGC.f19_f19_mg17
# set CASENUM    = ( 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020 021 022 023 024 025 026 027 028 029 030 )

foreach CASEN ($CASENUM)

    set CASE = ${CASEPREFIX}.${CASETYPE}.${CASEN}
    echo "case: ${CASE}"

    mkdir -vp ${CASEROOT}/${CASE}
    cd ${CASEROOT}/${CASE}
    echo "pwd: ${PWD}"

    # Revert to older ncarenv module compatible with `cesm_postprocessing_derecho`
    module purge
    module load ncarenv/23.09
    module reset

    # Load required modules
    module use /glade/work/bdobbins/Software/Modules
    module load cesm_postprocessing_derecho

    # If the path "postprocess" does not exist, load the required modules and set up the postprocessing environment
    if ( ! -d "postprocess" ) then
        create_postprocess -caseroot=`pwd`
	endif

    cd postprocess

    pp_config --set CASE=$CASE
    pp_config --set TIMESERIES_OUTPUT_ROOTDIR=/glade/derecho/scratch/${USER}/timeseries/${CASE}
	pp_config --set DOUT_S_ROOT=${DOUT_S_ROOT}/${CASE}

    pp_config --set ATM_GRID=1.9x2.5
	pp_config --set LND_GRID=1.9x2.5
	pp_config --set ICE_GRID=gx1v7
	pp_config --set OCN_GRID=gx1v7
	pp_config --set ICE_NX=144
	pp_config --set ICE_NY=96

    # GENERATE_TIMESERIES: If TRUE, create the single variable time series files using the history time slice files.
    # All the time invariant metadata is included in each variable time series file header. Rules for how the time series 
    # variable files are created are specified in the env_archive.xml file.
    pp_config --set GENERATE_TIMESERIES=FALSE

    # TIMESERIES_GENERATE_ALL: If TRUE, create all variable timeseries files for all history streams regardless of
    # the settings listed in the env_timeseries.xml tseries_create element. If set to FALSE, then use the tseries_create
    # element setting in env_timeseries.xml for customized generation of timeseries files based on the history stream.
    pp_config --set TIMESERIES_GENERATE_ALL=FALSE

    # Specify if you want to run other diagnostics and averaging

    #+++ ATM
    pp_config --set GENERATE_DIAGS_ATM=FALSE

    #+++ LND
    pp_config --set GENERATE_DIAGS_LND=TRUE
    pp_config --set LNDDIAG_CLEANUP_FILES=FALSE

    pp_config --set LNDDIAG_MODEL_VS_OBS=TRUE
    pp_config --set LNDDIAG_MODEL_VS_MODEL=TRUE

    #+++ SEA ICE
    pp_config --set GENERATE_DIAGS_ICE=TRUE

    #+++ OCN
    pp_config --set GENERATE_DIAGS_OCN=FALSE

    pp_config --set GENERATE_AVGS_ATM=FALSE
    pp_config --set GENERATE_AVGS_LND=FALSE
    pp_config --set GENERATE_AVGS_ICE=FALSE
    pp_config --set GENERATE_AVGS_OCN=FALSE

    pp_config --set GENERATE_REGRID_LND=FALSE
    pp_config --set GENERATE_ILAMB=TRUE

    echo "> built and configured postp directory"

    # Modify the run script and request less walltime (generating all timeseries for 000 took ~45min)
	sed -i "s|#PBS -q regular|#PBS -q main|" lnd_diagnostics
	sed -i "s|#PBS -A None|#PBS -A UWAS0155|" lnd_diagnostics
    echo "> finished modifying the lnd_diagnostics run script"

    qsub lnd_diagnostics
	echo "> submitted the lnd_diagnostics run script"

end

exit
