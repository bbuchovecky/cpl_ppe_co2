"""
Fixes the FUN bug by switching 'kn_nonmyc' and 'kc_nonmyc' in the default parameter file.
"""

import os
import shutil
import xarray as xr

PDIR = "/glade/u/home/bbuchovecky/projects/cpl_ppe_co2/hist/data/cesm2.1.5/paramfiles"
PFILENAME = "clm5_params.c171117"
PPE_PARAMPATH = f"{PDIR}/coupPPE-hist.000.nc"

orig_paramfile = xr.open_dataset(f"{PDIR}/{PFILENAME}.nc", decode_timedelta=False)

kn_nonmyc_attrs = orig_paramfile["kn_nonmyc"].attrs
kc_nonmyc_attrs = orig_paramfile["kc_nonmyc"].attrs

new_paramfile = orig_paramfile.rename({"kn_nonmyc": "_tmp_", "kc_nonmyc": "kn_nonmyc"})
new_paramfile = new_paramfile.rename({"_tmp_": "kc_nonmyc"})

new_paramfile["kn_nonmyc"].attrs = kn_nonmyc_attrs
new_paramfile["kc_nonmyc"].attrs = kc_nonmyc_attrs

new_paramfile.to_netcdf(f"{PDIR}/{PFILENAME}_FUNfix.nc")

if os.path.exists(PPE_PARAMPATH):
    os.chmod(PPE_PARAMPATH, 0o666)
    os.remove(PPE_PARAMPATH)

shutil.copy2(f"{PDIR}/{PFILENAME}_FUNfix.nc", PPE_PARAMPATH)
