#!/bin/bash

# set configurable inputs
cortexmap=`jq -r '.cortexmap' config.json`
freesurfer=`jq -r '.freesurfer' config.json`
resamp_surf=`jq -r '.resample_surf' config.json`

# set hemispheres
hemispheres="lh rh"

# set path to standard meshes. this can be found at http://brainvis.wustl.edu/workbench/standard_mesh_atlases.zip
atlases='./standard_mesh_atlases'

# copy freesurfer directory
[ ! -d ./freesurfer ] && cp -R ${freesurfer} ./freesurfer

# make output directory
[ ! -d ./cortexmap ] && mkdir -p cortexmap cortexmap/surf cortexmap/func cortexmap/label

# copy over cortexmap data and make resampled directory
cp -R ${cortexmap} ./tmp/

# convert freesurfer sphere
for hemi in ${hemispheres}
do
    [ ! -f ./${hemi}.sphere.reg.surf.gii ] && echo "converting ${hemi} sphere" && mris_convert ./freesurfer/surf/${hemi}.sphere.reg ./${hemi}.sphere.reg.surf.gii
done

# grab list of surface and functional files
func_files=`ls tmp/func/`
surf_files=`ls tmp/surf/`
label_files=`ls tmp/label/`

# resample surfaces
for i in ${surf_files}
do
    if [[ ${i} == *".surf.gii" ]]; then
    	echo "resampling ${i}"

        # see what hemisphere this belongs to
        if [[ ${i} == *"lh"* ]]; then
            hemi="lh"
            wb_hemi="L"
        else
            hemi="rh"
            wb_hemi="R"
        fi

        # resample surface
    	wb_command -surface-resample \
    		./tmp/surf/${i} \
            ./${hemi}.sphere.reg.surf.gii \
            ${atlases}/resample_fsaverage/fs_LR-deformed_to-fsaverage.${wb_hemi}.sphere.${resamp_surf}_fs_LR.surf.gii \
            BARYCENTRIC \
            ./cortexmap/surf/${i}
    fi
done

# resample surfaces - mni
if [ -d ./tmp/surf/mni ]; then

    mni_surf_files=`ls ./tmp/surf/mni/`
    [ ! -d ./cortexmap/surf/mni ] && mkdir -p cortexmap/surf/mni

    for i in ${mni_surf_files}
    do
        if [[ ${i} == *".surf.gii" ]]; then
            echo "resampling ${i}"

            # see what hemisphere this belongs to
            if [[ ${i} == *"lh"* ]]; then
                hemi="lh"
                wb_hemi="L"
            else
                hemi="rh"
                wb_hemi="R"
            fi

            # resample surface
            wb_command -surface-resample \
                ./tmp/surf/mni/${i} \
                ./${hemi}.sphere.reg.surf.gii \
                ${atlases}/resample_fsaverage/fs_LR-deformed_to-fsaverage.${wb_hemi}.sphere.${resamp_surf}_fs_LR.surf.gii \
                BARYCENTRIC \
                ./cortexmap/surf/mni/${i}
        fi
    done
fi

# resample func files
for i in ${func_files}
do
    echo "resampling ${i}"

    # see what hemisphere this belongs to
    if [[ ${i} == *"lh"* ]]; then
        hemi="lh"
        wb_hemi="L"
    else
        hemi="rh"
        wb_hemi="R"
    fi

    # resample surface
    wb_command -metric-resample \
        ./tmp/func/${i} \
        ./${hemi}.sphere.reg.surf.gii \
        ${atlases}/resample_fsaverage/fs_LR-deformed_to-fsaverage.${wb_hemi}.sphere.${resamp_surf}_fs_LR.surf.gii \
        ADAP_BARY_AREA \
        ./cortexmap/func/${i} \
        -area-surfs ./tmp/surf/${hemi}.midthickness.native.surf.gii \
        ./cortexmap/surf/${hemi}.midthickness.native.surf.gii

done

# resample label files
for i in ${label_files}
do
    echo "resampling ${i}"

    # see what hemisphere this belongs to
    if [[ ${i} == *"lh"* ]]; then
        hemi="lh"
        wb_hemi="L"
    else
        hemi="rh"
        wb_hemi="R"
    fi

    # resample surface
    wb_command -label-resample \
        ./tmp/label/${i} \
        ./${hemi}.sphere.reg.surf.gii \
        ${atlases}/resample_fsaverage/fs_LR-deformed_to-fsaverage.${wb_hemi}.sphere.${resamp_surf}_fs_LR.surf.gii \
        ADAP_BARY_AREA \
        ./cortexmap/label/${i} \
        -area-surfs ./tmp/surf/${hemi}.midthickness.native.surf.gii \
        ./cortexmap/surf/${hemi}.midthickness.native.surf.gii
done

# add resample vertices as datatype tag
product=""
product="\"cortexmap\": {\"tags\": [ \"$resamp_surf\" ]}, $product"
cat << EOF > product.json
{
    $product
}
EOF

# file check
func_files=(${func_files})
num_files=`echo ${#func_files[@]}`
if [ ! -f ./cortexmap/func/${func_files[$num_files-1]} ]; then
    echo "something went wrong. check derivatives and logs"
    exit 1
else
    echo "resampling complete"
    rm -rf ./tmp ./freesurfer *.gii
    exit 0
fi
