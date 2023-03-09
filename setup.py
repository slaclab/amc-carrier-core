
from distutils.core import setup
from git import Repo

repo = Repo()

# Get version before adding version file
ver = repo.git.describe('--tags')
ver = ver.replace('-', '+', 1) # https://github.com/pypa/setuptools/issues/3772

# append version constant to package init
with open('python/AmcCarrierCore/__init__.py','a') as vf:
    vf.write(f'\n__version__="{ver}"\n')

setup (
    name='amc_carrier_core',
    version=ver,
    packages=[ 'AmcCarrierCore',
               'AmcCarrierCore/AppHardware',
               'AmcCarrierCore/AppHardware/AmcCryo',
               'AmcCarrierCore/AppHardware/AmcCryoDemo',
               'AmcCarrierCore/AppHardware/AmcGenericAdcDac',
               'AmcCarrierCore/AppHardware/AmcMicrowaveMux',
               'AmcCarrierCore/AppHardware/RtmCryoDet',
               'AmcCarrierCore/AppHardware/RtmDigitalDebug',
               'AmcCarrierCore/AppMps',
               'AmcCarrierCore/AppTop',
               'AmcCarrierCore/AxisBramRingBuffer',
               'AmcCarrierCore/BsaCore',
               'AmcCarrierCore/DacSigGen',
               'AmcCarrierCore/DaqMuxV2',],
    package_dir={'':'python'},
)
