#!/bin/bash

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Define directories and user settings
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Case name and directory for the simulation
export CESM_CASE_NAME=test_HST
export CESM_CASE_DIR=/glade/u/home/bbuchovecky/cesm_runs/cases

# Project number to charge for the simulation
export PROJECT_NUM=TEMPLATE_PROJNUM

# Resolution and compset
export CESM_CASE_RES=TEMPLATE_RES
export CESM_COMPSET=TEMPLATE_COMPSET

# Simulation to branch from
export BASECASE_NAME=TEMPLATE_BASENAME

# CESM source code directory
export CESM_SRC_DIR=TEMPLATE_SRCDIR

# Output storage
export ARCHIVE_DIR=/glade/derecho/scratch/bbuchovecky/archive
export RUN_DIR=/glade/derecho/scratch/bbuchovecky

# This run script
export FILENAME=/glade/u/home/bbuchovecky/projects/cpl_ppe_co2/hist/code/03_run-scripts/run_script_hst_ppe_20250412.sh
echo "{$0}"
echo "${FILENAME}"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Clean up workspace (only if necessary)
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Delete old case
rm -rf "${CESM_CASE_DIR}/${CESM_CASE_NAME:?}"

# Delete old run directory
rm -rf "${RUN_DIR}/${CESM_CASE_NAME:?}"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Make case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Change to directory to make case
cd "${CESM_SRC_DIR}/cime/scripts" || exit

# Create new case
./create_newcase --case "${CESM_CASE_DIR}/${CESM_CASE_NAME}" --res ${CESM_CASE_RES} --compset ${CESM_COMPSET} --project ${PROJECT_NUM} --machine derecho --run-unsupported
# !! keep --run-unsupported tag?

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Configure case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Change to case directory
cd "${CESM_CASE_DIR}/${CESM_CASE_NAME}" || exit

# +++ Modify xml files related to data model components
./xmlchange DOCN_SOM_FILENAME="pop_frc.b.e21.BW1850.f09_g17.CMIP6-piControl.001.190514.nc"

# +++ Modify xml files related to run time

# NOTE: do these settings for test run
#./xmlchange STOP_OPTION="ndays"
#./xmlchange STOP_N=4
#./xmlchange RESUBMIT=0
#./xmlchange JOB_WALLCLOCK_TIME=00:30:00 --subgroup case.run

# NOTE: do these settings for full run
./xmlchange STOP_OPTION="nyears"
./xmlchange STOP_N=1
./xmlchange RESUBMIT=0
./xmlchange JOB_WALLCLOCK_TIME=11:30:00 --subgroup case.run

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Set up case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

./case.setup

# !! unsure about these settings
# ./xmlchange BUILD_COMPLETE=TRUE
# ./xmlchange EXEROOT=$RUN_DIR/$BASECASE_NAME"/bld"

# +++ Turn on/off short term archiving
#./xmlchange DOUT_S=FALSE

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Modify namelists
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Copy over namelist
cp test user_nl_clm

# Modify land namelist
cat >> user_nl_clm << EOF
EOF

# Modify atmosphere namelist
cat >> user_nl_cam << EOF
EOF

# Modify coupler namelist -- only uncomment this for DEFAULT simulations
# cat >> user_nl_cpl << EOF
# EOF

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Build case and copy in resubmit files
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copy this run script into the run directory
cp $FILENAME .

# Copy resubmit files (from case we're branching from) into this case's run folder on glade
cd "${RUN_DIR}/${CESM_CASE_NAME}/run" || exit
cp "${RESTART_DIR}/*" .

# Build the case
cd "${CESM_CASE_DIR}/${CESM_CASE_NAME}" || exit
qcmd -A "${PROJECT_NUM}" -- ./case.build

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Submit case
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
cd "${CESM_CASE_DIR}/${CESM_CASE_NAME}" || exit
./case.submit