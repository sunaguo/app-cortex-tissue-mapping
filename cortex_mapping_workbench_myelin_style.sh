#!/bin/bash

## This script will create a midthickness surface, map tensor and NODDI values to this surface, and compute stats for each ROI from Freesurfer parcellation

# # Set subject directory in Freesurfer
# export SUBJECTS_DIR=./

# # Variables
# freesurfer=`jq -r '.freesurfer' config.json`;
dwi=`./jq -r '.dwi' config.json`;
tensor=`./jq -r '.tensor' config.json`;
noddi=`./jq -r '.noddi' config.json`;
sigma_val=`./jq -r '.sigma' config.json`;
sigma="`echo "sigma_val" | bc -l`";
HEMI="lh rh";

if [ -z ${tensor} ];
then
	METRIC="icvf isovf od"
elif [ -z ${noddi} ]; then
	METRIC="ad fa md rd"
else
	METRIC="ad fa md rd icvf isovf od"
fi

## converting surfaces and making midthickness surface to which metrics will be mapped
for hemi in $HEMI
	do
		if [ $hemi = "lh" ]; then
			Structure="CORTEX_LEFT";
		elif [ $hemi = "rh" ]; then
			Structure="CORTEX_RIGHT";
		fi
		wb_command -set-structure ./cortexmap/label/${hemi}.aparc.a2009s.native.label.gii $Structure;
		wb_command -set-map-names ./cortexmap/label/${hemi}.aparc.a2009s.native.label.gii -map 1 "${hemi}"_aparc.a2009s;
		wb_command -gifti-label-add-prefix ./cortexmap/label/${hemi}.aparc.a2009s.native.label.gii "${hemi}_" ./cortexmap/label/${hemi}.aparc.a2009s.native.label.gii;
		
		# generate midthickness surface and inflated surfaces
		wb_command -surface-average ./cortexmap/surf/${hemi}.midthickness.native.surf.gii -surf ./cortexmap/surf/${hemi}.white.surf.gii -surf ./cortexmap/surf/${hemi}.pial.surf.gii;
		wb_command -surface-generate-inflated ./cortexmap/surf/${hemi}.midthickness.native.surf.gii ./cortexmap/surf/${hemi}.midthickness.inflated.native.surf.gii ./cortexmap/surf/${hemi}.midthickness.very_inflated.native.surf.gii -iterations-scale 2.5;
		
		# Generate thickness.shape.gii and roi.native.shape.gii structures
		wb_command -metric-math "abs(thickness)" ./cortexmap/surf/${hemi}.native.thickness.shape.gii -var thickness ./cortexmap/surf/${hemi}.native.thickness.shape.gii;
		wb_command -metric-palette ./cortexmap/surf/${hemi}.native.thickness.shape.gii MODE_AUTO_SCALE_PERCENTAGE -pos-percent 4 96 -interpolate true -palette-name videen_style -disp-pos true -disp-neg false -disp-zero false;
		wb_command -set-map-name ./cortexmap/surf/${hemi}.native.thickness.shape.gii 1 "${hemi}"_Thickness;
		wb_command -metric-math "thickness > 0" ./cortexmap/surf/${hemi}.roi.native.shape.gii -var thickness ./cortexmap/surf/${hemi}.native.thickness.shape.gii;
		wb_command -metric-fill-holes ./surf/${hemi}.midthickness.native.surf.gii ./surf/${hemi}.roi.native.shape.gii ./surf/${hemi}.roi.native.shape.gii;
		wb_command -metric-remove-islands ./cortexmap/surf/${hemi}.midthickness.native.surf.gii ./cortexmap/surf/${hemi}.roi.native.shape.gii ./cortexmap/surf/${hemi}.roi.native.shape.gii;
		wb_command -set-map-names ./cortexmap/surf/${hemi}.roi.native.shape.gii -map 1 "${hemi}"_ROI;
	done

# resampling metric volumes to cortical ribbon volume
for metric in $METRIC
	do
		wb_command -volume-affine-resample ./cortexmap/metric/${metric}.nii.gz ./acpcxform.mat ./cortexmap/surf/ribbon.nii.gz TRILINEAR ./cortexmap/metric/${metric}.nii.gz -flirt ${dwi} ./cortexmap/surf/ribbon.nii.gz;
	done

# mapping metrics to midthickness surface
for hemi in $HEMI
	do
		for metric in $METRIC
			do
				
				wb_command -volume-to-surface-mapping ./cortexmap/metric/${metric}.nii.gz ./cortexmap/surf/${hemi}.midthickness.native.surf.gii ./cortexmap/func/${hemi}.${metric}.func.gii -myelin-style ./cortexmap/surf/${hemi}.ribbon.nii.gz ./cortexmap/surf/${hemi}.native.thickness.shape.gii $sigma;
				wb_command -metric-smoothing ./cortexmap/surf/${hemi}.midthickness.native.surf.gii ./cortexmap/func/${hemi}.${metric}.func.gii $sigma ./cortexmap/func/${hemi}.${metric}.func.gii;
				wb_command -metric-mask ./cortexmap/func/${hemi}.${metric}.func.gii ./cortexmap/surf/${hemi}.roi.native.shape.gii ./cortexmap/func/${hemi}.${metric}.func.gii;
				wb_command -set-map-name ./cortexmap/func/${hemi}.${metric}.func.gii 1 "${hemi}"_"${metric}"
				wb_command -metric-palette ./cortexmap/func/${hemi}.${metric}.func.gii MODE_AUTO_SCALE_PERCENTAGE -pos-percent 4 96 -interpolate true -palette-name videen_style -disp-pos true -disp-neg false -disp-zero false;
			done
	done
