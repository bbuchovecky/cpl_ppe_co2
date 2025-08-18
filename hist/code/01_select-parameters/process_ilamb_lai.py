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
lai_avh15c1 = xr.open_dataset(f'{INDIR}/LAI_AVH15C1_ILAMB_20250709.nc')
lai_avhrr = xr.open_dataset(f'{INDIR}/LAI_AVHRR_ILAMB_20250709.nc')
lai_cao2023 = xr.open_dataset(f'{INDIR}/LAI_CAO2023_ILAMB_20250709.nc')
lai_modis = xr.open_dataset(f'{INDIR}/LAI_MODIS_ILAMB_20250709.nc')

# Store in dictionary for easier processing
lai = {
    'AVH15C1': lai_avh15c1,
    'AVHRR': lai_avhrr,
    'CAO2023': lai_cao2023,
    'MODIS': lai_modis,
}

# Process each dataset
for key, ds in lai.items():
    print(f'{key}')

    # Select the time range if specified
    if START_DATE is not None or END_DATE is not None:
        print('  selecting time range...', end='')
        ds = ds.sel(time=TIME_RANGE)
        print(' done')

    # Calculate the annual mean
    print('  calculating annual mean...', end='')
    ds['lai'] = calc_annual_mean(ds['lai'], season='annual')
    print(' done')

    # Rename variable and set attributes
    ds['lai'].attrs['units'] = 'm2/m2'
    ds['lai'].attrs['long_name'] = 'leaf area index'

    # Save the processed dataset
    print('  saving to file...', end='')
    outfile = os.path.join(OUTDIR, f'LAI_ANNUAL_{key}_ILAMB_20250709.nc')
    ds.to_netcdf(outfile)
    print(' done')
