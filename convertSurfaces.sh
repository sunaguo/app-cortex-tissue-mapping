#!/bin/bash

# Set subject directory in Freesurfer
export SUBJECTS_DIR=./

# Variables
freesurfer=`jq -r '.freesurfer' config.json`;
dwi=`jq -r '.dwi' config.json`;
tensor=`jq -r '.tensor' config.json`;
noddi=`jq -r '.noddi' config.json`;
HEMI="lh rh";

if [ -z ${tensor} ];
then
	METRIC="icvf isovf od"
elif [ -z ${noddi} ]; then
	METRIC="ad fa md rd"
else
	METRIC="ad fa md rd icvf isovf od"
fi

## make directory and copy metric files to folder
mkdir cortexmap;
mkdir metric;
mkdir ./cortexmap/surf;
mkdir ./cortexmap/label;
mkdir ./cortexmap/func;

# Tensor
if [ -z ${tensor} ];
then
	echo "tensor not being used"
else
	for i in ${tensor}/*
		do	
			cp -v "${i}" ./metric/;
		done
fi

# NODDI
if [ -z ${noddi} ];
then
	echo "noddi not being used"
else
	for i in ${noddi}/*
		do
			cp -v "${i}" ./metric/;
		done
fi

# convert ribbon to nifti.gz
mri_convert ${freesurfer}/mri/ribbon.mgz ./cortexmap/surf/ribbon.nii.gz;

for hemi in $HEMI
	do
		# convert files
		mris_convert ${freesurfer}/surf/${hemi}.pial ./cortexmap/surf/${hemi}.pial.surf.gii;
		mris_convert ${freesurfer}/surf/${hemi}.white ./cortexmap/surf/${hemi}.white.surf.gii;
		mris_convert -c ${freesurfer}/surf/${hemi}.thickness ${freesurfer}/surf/${hemi}.white ./cortexmap./surf/${hemi}.native.thickness.shape.gii;
		mri_convert ${freesurfer}/mri/${hemi}.ribbon.mgz ./cortexmap/surf/${hemi}.ribbon.nii.gz;

		# set up aparc.a2009s labels
		mris_convert --annot ${freesurfer}/label/${hemi}.aparc.a2009s.annot ${freesurfer}/surf/${hemi}.pial ./cortexmap/label/${hemi}.aparc.a2009s.native.label.gii;
	done
