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
freesurfer=`jq -r '.freesurfer' config.json`
warp=`jq -r '.warp' config.json`
inv_warp=`jq -r '.inverse_warp' config.json`
fsurfparc=`jq -r '.fsurfparc' config.json`
echo "parsing inputs complete"

# set hemisphere labels
echo "set hemisphere labels"
HEMI="lh rh"
CARETHemi="L R"
echo "hemisphere labels set"

# set other variables for ease of scripting
echo "setting useful variables"
if [[ ! ${warp} == 'null' ]]; then
	SPACES="native mni"
	SPACES_DIR=("./cortexmap/cortexmap/surf" "./cortexmap/cortexmap/surf/mni")
else
	SPACES="native"
	SPACES_DIR=("./cortexmap/cortexmap/surf/")
fi

for spaces in ${SPACES_DIR[*]}
do
	mkdir -p ${spaces}
done

FUNC_DIR=("./cortexmap/cortexmap/func/")
surfs="pial.surf.gii white.surf.gii"
echo "variables set"

#### identify transform between freesurfer space and anat space. See HCP pipeline for more reference ####
if [ ! -f c_ras.mat ]; then
	echo "identifying transform between freesurfer and anat space"
	MatrixXYZ=`mri_info --cras ${freesurfer}/mri/brain.finalsurfs.mgz`
	MatrixX=`echo ${MatrixXYZ} | awk '{print $1;}'`
	MatrixY=`echo ${MatrixXYZ} | awk '{print $2;}'`
	MatrixZ=`echo ${MatrixXYZ} | awk '{print $3;}'`
	echo "1 0 0 ${MatrixX}" >  c_ras.mat
	echo "0 1 0 ${MatrixY}" >> c_ras.mat
	echo "0 0 1 ${MatrixZ}" >> c_ras.mat
	echo "0 0 0 1"          >> c_ras.mat
fi
echo "transform computed"

#### convert ribbons and surface files ####
# ribbon
echo "converting ribbon files"
[ ! -f ${SPACES_DIR[0]}/ribbon.nii.gz ] && mri_convert ${freesurfer}/mri/ribbon.mgz ${SPACES_DIR[0]}/ribbon.nii.gz

# extract hemispheric ribbons
[ ! -f ./ribbon_lh.nii.gz ] && fslmaths ${SPACES_DIR[0]}/ribbon.nii.gz -thr 3 -uthr 3 -bin ./ribbon_lh.nii.gz
[ ! -f ./ribbon_rh.nii.gz ] && fslmaths ${SPACES_DIR[0]}/ribbon.nii.gz -thr 42 -uthr 42 -bin ./ribbon_rh.nii.gz
echo "converting ribbon files complete"

# hemisphere ribbon and surfaces (obtained directly from HCP PostFreesurfer pipeline and amended for BL: https://github.com/Washington-University/HCPpipelines/blob/master/PostFreeSurfer/scripts/FreeSurfer2CaretConvertAndRegisterNonlinear.sh)
echo "looping through hemispheres and creating appropriate surface files"
for hemi in $HEMI
do
		if [[ ${hemi} == 'lh' ]]; then
			STRUCTURE="CORTEX_LEFT"
		else
			STRUCTURE="CORTEX_RIGHT"
		fi

		for SURFS in $surfs
		do
			# convert files and set structure
			if [ ! -f ${SPACES_DIR[0]}/${hemi}.${SURFS} ]; then
				mris_convert ${freesurfer}/surf/${hemi}.${SURFS::-9} ${SPACES_DIR[0]}/${hemi}.${SURFS}

				# set up gifti structure
				wb_command -set-structure ${SPACES_DIR[0]}/${hemi}.${SURFS} \
					${STRUCTURE} \
					-surface-type ANATOMICAL
			fi

			# apply affine
			[ ! -f ${SPACES_DIR[0]}/${hemi}.cras.${SURFS} ] && wb_command -surface-apply-affine ${SPACES_DIR[0]}/${hemi}.${SURFS} \
				c_ras.mat \
				${SPACES_DIR[0]}/${hemi}.cras.${SURFS}

			if [[ ! ${warp} == 'null' ]]; then
				# apply MNI warp
				[ ! -f ${SPACES_DIR[1]}/${hemi}.mni.${SURFS} ] && wb_command -surface-apply-warpfield ${SPACES_DIR[0]}/${hemi}.cras.${SURFS} ${inv_warp} \
					${SPACES_DIR[1]}/${hemi}.mni.${SURFS} \
					-fnirt \
					${warp}
			fi
		done

		# create midthickness surfaces
		if [ ! -f ${SPACES_DIR[0]}/${hemi}.midthickness.native.surf.gii ]; then 
			wb_command -surface-average \
				${SPACES_DIR[0]}/${hemi}.midthickness.native.surf.gii \
				-surf ${SPACES_DIR[0]}/${hemi}.cras.white.surf.gii \
				-surf ${SPACES_DIR[0]}/${hemi}.cras.pial.surf.gii

			wb_command -set-structure \
				${SPACES_DIR[0]}/${hemi}.midthickness.native.surf.gii \
				${STRUCTURE} \
				-surface-type ANATOMICAL \
				-surface-secondary-type MIDTHICKNESS

			if [[ ! ${warp} == 'null' ]]; then
				[ ! -f ${SPACES_DIR[1]}/${hemi}.midthickness.mni.surf.gii ] && wb_command -surface-apply-warpfield ${SPACES_DIR[0]}/${hemi}.midthickness.native.surf.gii ${inv_warp} \
					${SPACES_DIR[1]}/${hemi}.midthickness.mni.surf.gii \
					-fnirt \
					${warp}
			fi
		fi

		# identify number of vertices for inflation
		NativeVerts=$(wb_command -file-information ${SPACES_DIR[0]}/${hemi}.midthickness.native.surf.gii | grep 'Number of Vertices:' | cut -f2 -d: | tr -d '[:space:]')
        NativeInflationScale=$(echo "scale=4; 0.75 * $NativeVerts / 32492" | bc -l)

        # inflate surfaces
        for spaces in ${SPACES}
        do
        	if [[ ${spaces} == 'native' ]]; then
        		outdir=${SPACES_DIR[0]}
        	else
        		outdir=${SPACES_DIR[1]}
        	fi

	        # inflate native
	        [ ! -f ${outdir}/${hemi}.midthickness.very_inflated.${spaces}.surf.gii ] && wb_command -surface-generate-inflated \
	        	${outdir}/${hemi}.midthickness.${spaces}.surf.gii \
	        	${outdir}/${hemi}.midthickness.inflated.${spaces}.surf.gii \
	        	${outdir}/${hemi}.midthickness.very_inflated.${spaces}.surf.gii \
	        	-iterations-scale $NativeInflationScale
	    done

	    # volume-specific operations
	    volume_name="volume.shape.gii"
	    outdir=${SPACES_DIR[0]}
	    if [ ! -f ${outdir}/${hemi}.${volume_name} ]; then
	    	mris_convert -c ${freesurfer}/surf/${hemi}.volume \
	    		${freesurfer}/surf/${hemi}.white \
	    		${outdir}/${hemi}.${volume_name}

			wb_command -set-structure ${outdir}/${hemi}.${volume_name} \
				${STRUCTURE}

			wb_command -set-map-names ${outdir}/${hemi}.${volume_name} \
				-map 1 ${hemi}_Volume

			wb_command -metric-palette ${outdir}/${hemi}.${volume_name} \
				MODE_AUTO_SCALE_PERCENTAGE \
				-pos-percent 2 98 \
				-palette-name Gray_Interp \
				-disp-pos true \
				-disp-neg true \
				-disp-zero true
			
			wb_command -metric-math "abs(volume)" \
				${outdir}/${hemi}.${volume_name} \
				-var volume \
				${outdir}/${hemi}.${volume_name}

			wb_command -metric-palette ${outdir}/${hemi}.${volume_name} \
				MODE_AUTO_SCALE_PERCENTAGE \
				-pos-percent 4 96 \
				-interpolate true \
				-palette-name videen_style \
				-disp-pos true \
				-disp-neg false \
				-disp-zero false
		fi

		# thickness-specific operations
		thickness_name="thickness.shape.gii"
		outdir=${SPACES_DIR[0]}
		if [ ! -f ${outdir}/${hemi}.${thickness_name} ]; then
			mris_convert -c ${freesurfer}/surf/${hemi}.thickness \
				${freesurfer}/surf/${hemi}.white \
				${outdir}/${hemi}.${thickness_name}

			wb_command -set-structure ${outdir}/${hemi}.${thickness_name} \
				${STRUCTURE}

			wb_command -metric-math "var * -1" ${outdir}/${hemi}.${thickness_name} \
				-var var\
				${outdir}/${hemi}.${thickness_name}

			wb_command -set-map-names ${outdir}/${hemi}.${thickness_name} \
				-map 1 ${hemi}_Thickness

			wb_command -metric-palette ${outdir}/${hemi}.${thickness_name} \
				MODE_AUTO_SCALE_PERCENTAGE \
				-pos-percent 2 98 \
				-palette-name Gray_Interp \
				-disp-pos true \
				-disp-neg true \
				-disp-zero true

			wb_command -metric-math "abs(thickness)" \
				${outdir}/${hemi}.${thickness_name} \
				-var thickness \
				${outdir}/${hemi}.${thickness_name}

			wb_command -metric-palette ${outdir}/${hemi}.${thickness_name} \
				MODE_AUTO_SCALE_PERCENTAGE \
				-pos-percent 4 96 \
				-interpolate true \
				-palette-name videen_style \
				-disp-pos true \
				-disp-neg false \
				-disp-zero false

			wb_command -metric-math "thickness > 0" \
				${outdir}/${hemi}.roi.shape.gii \
				-var thickness \
				${outdir}/${hemi}.${thickness_name}

			wb_command -metric-fill-holes \
				${outdir}/${hemi}.midthickness.native.surf.gii \
				${outdir}/${hemi}.roi.shape.gii \
				${outdir}/${hemi}.roi.shape.gii

			wb_command -metric-remove-islands \
				${outdir}/${hemi}.midthickness.native.surf.gii \
				${outdir}/${hemi}.roi.shape.gii \
				${outdir}/${hemi}.roi.shape.gii

			wb_command -set-map-names \
				${outdir}/${hemi}.roi.shape.gii \
				-map 1 \
				"${hemi}"_ROI
		fi

		# set up aparc.a2009s labels
		if [ ! -f ./cortexmap/cortexmap/label/${hemi}.${fsurfparc}.native.label.gii ]; then
			mris_convert --annot \
				${freesurfer}/label/${hemi}.${fsurfparc}.annot \
				${freesurfer}/surf/${hemi}.pial \
				./cortexmap/cortexmap/label/${hemi}.${fsurfparc}.native.label.gii

			wb_command -set-structure \
				./cortexmap/cortexmap/label/${hemi}.${fsurfparc}.native.label.gii \
				${STRUCTURE}

			wb_command -set-map-names \
				./cortexmap/cortexmap/label/${hemi}.${fsurfparc}.native.label.gii \
				-map 1 \
				"${hemi}"_aparc.a2009s

			wb_command -gifti-label-add-prefix \
				./cortexmap/cortexmap/label/${hemi}.${fsurfparc}.native.label.gii \
				"${hemi}_" \
				./cortexmap/cortexmap/label/${hemi}.${fsurfparc}.native.label.gii
		fi
done
echo "surface files generated"

if [ -f ./cortexmap/cortexmap/label/${hemi}.${fsurfparc}.native.label.gii ]; then
	echo "cortexmap structure generation complete"
	exit 0
else
	echo "something went wrong. check derivatives and logs"
	exit 1
fi
