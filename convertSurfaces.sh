#!/bin/bash

# Set subject directory in Freesurfer
export SUBJECTS_DIR=./

# Variables
freesurfer=`jq -r '.freesurfer' config.json`;
dwi=`jq -r '.dwi' config.json`;
fa=`jq -r '.fa' config.json`;
ad=`jq -r '.ad' config.json`;
md=`jq -r '.md' config.json`;
rd=`jq -r '.rd' config.json`;
icvf=`jq -r '.icvf' config.json`;
isovf=`jq -r '.isovf' config.json`;
od=`jq -r '.od' config.json`;
HEMI="lh rh";

if [ "$fa" = "null" ];
then
	METRIC="${icvf} ${isovf} ${od}"
elif [ "$icvf" = "null" ]; then
	METRIC="${ad} ${fa} ${md} ${rd}"
else
	METRIC="${ad} ${fa} ${md} ${rd} ${icvf} ${isovf} ${od}"
fi

## make directory and copy metric files to folder
mkdir cortexmap;
mkdir metric;
mkdir ./cortexmap/surf;
mkdir ./cortexmap/label;
mkdir ./cortexmap/func;


for i in ${METRIC}
	do
		cp -v "${i}" ./metric/;
	done

# convert ribbon to nifti.gz
mri_convert ${freesurfer}/mri/ribbon.mgz ./cortexmap/surf/ribbon.nii.gz;

for hemi in $HEMI
	do
		# convert files
		mris_convert ${freesurfer}/surf/${hemi}.pial ./cortexmap/surf/${hemi}.pial.surf.gii;
		mris_convert ${freesurfer}/surf/${hemi}.white ./cortexmap/surf/${hemi}.white.surf.gii;
		mris_convert -c ${freesurfer}/surf/${hemi}.thickness ${freesurfer}/surf/${hemi}.white ./cortexmap/surf/${hemi}.native.thickness.shape.gii;
		mri_convert ${freesurfer}/mri/${hemi}.ribbon.mgz ./cortexmap/surf/${hemi}.ribbon.nii.gz;

		# set up aparc.a2009s labels
		mris_convert --annot ${freesurfer}/label/${hemi}.aparc.a2009s.annot ${freesurfer}/surf/${hemi}.pial ./cortexmap/label/${hemi}.aparc.a2009s.native.label.gii;
	done
