#!/bin/bash

# This code will compute the temporal snr following code developed for the HCP processing pipeline

#### Parse inputs ####
dwi=`jq -r '.dwi' config.json`
bvals=`jq -r '.bvals' config.json`
bvecs=`jq -r '.bvecs' config.json`
mask=`jq -r '.brainmask' config.json`

#### make directories ####
mkdir -p outdir raw

#### extract b0 images ####
[ ! -f nodif.nii.gz ] && select_dwi_vols ${dwi} \
	${bvals} \
	nodif.nii.gz \
	0

#### compute mean signal in b0 ####
[ ! -f nodif_mean.nii.gz ] && fslmaths nodif.nii.gz -Tmean nodif_mean.nii.gz -odt float

#### compute standard deviation (noise) of b0 ####
[ ! -f nodif_std.nii.gz ] && fslmaths nodif.nii.gz -Tstd nodif_std.nii.gz -odt float

#### compute signal-to-noise ratio of mean signal and standard deviation (noise) ####
[ ! -f snr.nii.gz ] && fslmaths nodif_mean.nii.gz -div nodif_std.nii.gz snr.nii.gz -odt float

#### generate brainmask if not provided ####
[[ ${mask} == 'null' ]] && bet nodif_mean nodif_brain -f 0.3 -g 0 -m && mv nodif_brain_mask.nii.gz mask.nii.gz && mask="mask.nii.gz"

#### mask snr ####
[ ! -f ./outdir/snr.nii.gz ] && fslmaths snr.nii.gz -mas ${mask} ./outdir/snr.nii.gz

#### final checks and cleanup ####
if [ -f ./outdir/snr.nii.gz ]; then
	mv *.nii.gz ./raw/
	echo "temporal snr computed"
	exit 0
else
	echo "temporal snr calculation failed. see logs and derivatives"
	exit 1
fi
