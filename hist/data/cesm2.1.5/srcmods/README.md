# source mods for coupPPE-hist
directory structure:
```
├─ README.md
├─ coupPPE-hist_OAAT.csv       <- decsribes each ensemble member (ens name, parameter, minmax)
├─ orig                        <- original CESM2.1.5 source files
|  ├─ cam                      <- original CAM source files
|  └─ clm                      <- original CLM source files
├─ perturbed                   <- all modified source mods
|  ├─ all                      <- modifed source files to use in all simulations to output specific diagnostics
|  |  ├─ cam
|  |  └─ clm
|  ├─ coupPPE-hist.0[0-9][1-9] <- CLM source mods for each member
|  └─ ...
└─ templates                   <- template CLM source mod files for perturbations, where '<parameter>' has been replaced with 'this_<parameter>'
   ├─ <parameter-name>
   ├─ <parameter-group-name>
   └─ ...
```