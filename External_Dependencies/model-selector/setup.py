from setuptools import setup, find_packages
from zephod.__version__ import __version__

requirements = [
    'docopt',
    'h5py',
    'matplotlib',
    'numpy',
    'opencv',
    'pandas',
    'pathlib',
    'scikit-image',
    'scipy',
    'torch',
    'tqdm'
]

setup(
    name='zephod',
    version=__version__,
    description='Object/feature detection model selector algorithm.',
    author='James Yu, Vivek Venkatachalam',
    author_email='yu.hyo@northeastern.edu',
    url='https://github.com/venkatachalamlab/zephod',
    entry_points={'console_scripts': ['zephod=zephod.main:main',
                                      'auto_annotate=zephod.auto_annotate:main',
                                      'train_zephod=zephod.train:main']},
    keywords=['object detection', 'feature detection'],
    # install_requires=requirements,
    packages=find_packages()
)
