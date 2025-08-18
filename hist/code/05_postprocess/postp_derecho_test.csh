#!/bin/csh

module load ncl nco
module list

# Location of postprocessing timeseries scripts
setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/pp-offline/derecho/LR/

# Location of history files to archive as timeseries
setenv DOUT_S_ROOT /glade/derecho/scratch/${USER}/archive/

# The postprocessing run directory
setenv CASEROOT /glade/derecho/scratch/${USER}/postp

set CASE = f.e22.FHIST_BGC.f19_f17_mg17.coupPPE-hist.000
echo "case: ${CASE}"

mkdir -vp ${CASEROOT}/${CASE}
cd ${CASEROOT}/${CASE}
echo "pwd: ${PWD}"

# If the path "postprocess" does not exist, load the required modules and set up the postprocessing environment
if ( ! -d "postprocess" ) then
    module purge
    module load ncarenv/23.09
    module reset

    module use /glade/work/bdobbins/Software/Modules
    module load cesm_postprocessing_derecho
    create_postprocess -caseroot=`pwd`
endif

exit