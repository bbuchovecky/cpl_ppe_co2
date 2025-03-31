'''
Process ILAMB data
'''

import os
import numpy as np
import xarray as xr


### PREAMBLE ###

# Make xarray keep attributes when performing operations
xr.set_options(keep_attrs=True)

# File management
INDIR = '/glade/work/bbuchovecky/CPL_PPE_CO2/select_parameters/ILAMB_data/raw'
OUTDIR = '/glade/work/bbuchovecky/CPL_PPE_CO2/select_parameters/ILAMB_data/processed/annual_mean'

# Define constants
Lv = 2.26e6  # J/kg, latent heat of vaporization

# Define time period
START_DATE = None
END_DATE = None
TIME_RANGE = slice(START_DATE, END_DATE)


### FUNCTIONS ###

def calc_annual_mean(ds, season='annual'):
    ''' Calculate the annual mean of a dataset, optionally for a specific season. '''
    nyears = len(ds.groupby('time.year'))
    month_length = ds.time.dt.days_in_month
    if season != 'annual':
        month_length = month_length.where(month_length['time.season'] == season)

    weights = month_length.groupby('time.year') / month_length.groupby('time.year').sum()
    np.testing.assert_allclose(weights.groupby('time.year').sum().values, np.ones(nyears))

    return (ds * weights).groupby('time.year').sum(dim='time')


### MAIN ###

# Load the data
et_gleam = xr.open_dataset(f'{INDIR}/ET_GLEAMv3.3a_ILAMB_20250320.nc')
et_mod16a2 = xr.open_dataset(f'{INDIR}/ET_MOD16A2_ILAMB_20250320.nc')
et_modis = xr.open_dataset(f'{INDIR}/ET_MODIS_ILAMB_20250320.nc')
et_dolce = xr.open_dataset(f'{INDIR}/EVSPSBL_DOLCE_ILAMB_20250320.nc')
et_class = xr.open_dataset(f'{INDIR}/HFLS_CLASS_ILAMB_20250320.nc')
et_wecann = xr.open_dataset(f'{INDIR}/HFLS_WECANN_ILAMB_20250320.nc')
et_fluxcom = xr.open_dataset(f'{INDIR}/LE_FLUXCOM_ILAMB_20250320.nc')

# Store in dictionary for easier processing
et = {
    'GLEAMv3.3a': et_gleam,
    'MOD16A2': et_mod16a2,
    'MODIS': et_modis,
    'DOLCE': et_dolce,
    'CLASS': et_class,
    'WECANN': et_wecann,
    'FLUXCOM': et_fluxcom
}

# Original variable name (either ET or LH)
orig_varname = {
    'GLEAM': 'et',
    'MOD16A2': 'et',
    'MODIS': 'et',
    'DOLCE': 'hfls',
    'CLASS': 'hfls',
    'WECANN': 'hfls',
    'FLUXCOM': 'le',
}

# Process each dataset
for key, ds in et.items():
    print(f'{key}')
    v = orig_varname[key]

    # Select the time range if specified
    if START_DATE is not None or END_DATE is not None:
        print('  selecting time range...', end='')
        ds = ds.sel(time=TIME_RANGE)
        print(' done')

    # Convert from kg/m2/s to W/m2 if necessary
    if ds[v].attrs['units'] == 'kg/m2/s':
        print('  converting from kg/m2/s to W/m2...', end='')
        ds[v] = ds[v] * Lv
        print(' done')

    # Calculate the annual mean
    print('  calculating annual mean...', end='')
    ds[v] = calc_annual_mean(ds[v], season='annual')
    print(' done')

    # Rename variable and set attributes
    ds = ds.rename({v:'hfls'})
    ds['hfls'].attrs['units'] = 'W m-2'
    ds['hfls'].attrs['long_name'] = 'latent heat flux'
    ds['hfls'].attrs['standard_name'] = 'latent_heat_flux'

    # Save the processed dataset
    print('  saving to file...', end='')
    outfile = os.path.join(OUTDIR, f'HFLS_ANNUAL_{key}_ILAMB_20250320.nc')
    ds.to_netcdf(outfile)
    print(' done')
