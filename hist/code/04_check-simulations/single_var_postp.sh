#!/bin/bash

module load nco

DOUT_S_ROOT=/glade/derecho/scratch/${USER}/archive/

CASETYPE=coupPPE-hist
CASEPREFIX=f.e22.FHIST_BGC.f19_f17_mg17
CASENUM=000

CASE=${CASEPREFIX}.${CASETYPE}.${CASENUM}

# Usage function
usage() {
  echo "Usage: $0 -i \"file1.nc file2.nc ...\" -o output.nc -v variable_name"
  echo
  echo "  -i   Input files (quoted, space-separated list of NetCDF files)"
  echo "  -o   Output file name"
  echo "  -v   Variable to extract"
  exit 1
}

# Parse flags
while getopts "i:o:v:" opt; do
  case $opt in
    i) input_files="$OPTARG" ;;
    o) output_file="$OPTARG" ;;
    v) variable="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "$input_files" || -z "$output_file" || -z "$variable" ]]; then
  echo "Error: missing required argument(s)."
  usage
fi

ncrcat "${input_files}" | ncks -v "${variable}" -o "${output_file}"
