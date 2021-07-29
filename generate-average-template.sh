#!/bin/bash

# set configurable inputs
inputs=($(jq -r '.inputs' config.json  | tr -d '[]," '))

# identify number of inputs
num_inputs=`echo ${#inputs[@]}`

# set hemispheres
hemispheres="lh rh"

func_files=`ls ${inputs[0]}/func/`
surf_files=`ls ${inputs[0]}/surf/`
label_files=`ls ${inputs[0]}/label/`

# make output directory
[ ! -d ./cortexmap/ ] && mkdir -p cortexmap cortexmap/cortexmap cortexmap/cortexmap/surf cortexmap/cortexmap/func cortexmap/cortexmap/label

# native space surfaces
for surf in ${surf_files}
do
    if [[ ${surf} == *".surf.gii" ]]; then
        echo "surface - ${surf}"
        tmp_command=""
        for i in ${inputs[*]}
        do
            tmp_command="$tmp_command -surf `echo ${i}/surf/${surf}`"
        done

        wb_command -surface-average ./cortexmap/cortexmap/surf/${surf} ${tmp_command}
    fi
done

# if mni directory is there, generate average mni surface
if [ -d ${inputs[0]}/surf/mni ]; then

    mni_surf_files=`ls ${inputs[0]}/surf/mni/`
    [ ! -d ./cortexmap/surf/mni ] && mkdir -p cortexmap/cortexmap/surf/mni

    for surf in ${mni_surf_files}
    do
        if [[ ${surf} == *".surf.gii" ]]; then
            echo "mni surface - ${surf}"

            tmp_command=""
            for i in ${inputs}
            do
                tmp_command="$tmp_command -surf `echo ${i}/surf/mni/${surf}`"
            done

            wb_command -surface-average ./cortexmap/cortexmap/surf/mni/${surf} ${tmp_command}
        fi
    done
fi

# loop through functional files and average
for func in ${func_files}
do
    echo "generating average for ${func}"
    
    # average first two files
    wb_command -metric-math '(x+y)/2' ./cortexmap/cortexmap/func/${func} -var 'x' ${inputs[0]}/func/${func} -var 'y' ${inputs[1]}/func/${func}

    if [ ${num_inputs} -gt 2 ]; then
        for (( i=2; i<${num_inputs}; i++ ))
        do 
            wb_command -metric-math '(x+y)/2' ./cortexmap/cortexmap/func/${func} -var 'x' ./cortexmap/cortexmap/func/${func} -var 'y' ${inputs[$i]}/func/${func}
        done
    fi
done

# file check
func_files=(${func_files})
num_files=`echo ${#func_files[@]}`
if [ ! -f ./cortexmap/cortexmap/func/${func_files[$num_files-1]} ]; then
    echo "something went wrong. check derivatives and logs"
    exit 1
else
    echo "resampling complete"
    exit 0
fi
