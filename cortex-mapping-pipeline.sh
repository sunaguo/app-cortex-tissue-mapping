#!/bin/bash

## This script will create a midthickness surface, map tensor and NODDI values to this surface, and compute stats for each ROI from Freesurfer parcellation

set -x
set -e

#### Set cores ####
OMP_NUM_THREADS=8

#### make directory and copy metric files to folder ####
echo "making directories"
mkdir cortexmap ./cortexmap/cortexmap/
mkdir metric
mkdir ./cortexmap/cortexmap/label
mkdir ./cortexmap/cortexmap/func
mkdir raw
echo "making directories complete"

#### Variables ####
# parse inputs
echo "parsing inputs"
cortexmap=`jq -r '.cortexmap' config.json`
fix_zeros=`jq -r '.fix_zeros' config.json`
surface_smooth_kernel=`jq -r '.surface_smooth_kernel' config.json`
surface_fwhm=`jq -r '.surface_fwhm' config.json`
smooth_method=`jq -r '.surface_smooth_method' config.json`
echo "parsing inputs complete"

# parsing smoothing-related inputs
fb=""
sfwhm=""
if [[ ${fix_zeros} == true ]]; then
	fb="-fix-zeros"
fi
if [[ ${surface_fwhm} == true ]]; then
	sfwhm="-fwhm"
fi

# if cortexmap already exists, copy
cp -R ${cortexmap} ./cortexmap/
chmod -R +rw ./cortexmap

surfdir=./cortexmap/cortexmap/surf
funcdir=./cortexmap/cortexmap/func

files=(`find ${funcdir} -name *.gii -printf "%f\n"`)

for i in ${files[*]}
do
	hemi=${i%%.*}
	# smooth data
	wb_command -metric-smoothing ${surfdir}/${hemi}.white.surf.gii \
		${funcdir}/${i} \
		${surface_smooth_kernel} \
		${funcdir}/${i%%.func.gii}.smooth_${surface_smooth_kernel}.func.gii \
		-method ${smooth_method} ${sfwhm} ${fb}
done
