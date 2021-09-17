#!/bin/bash

# set top variables
surf_data=`jq -r '.surf_data' config.json`
surf_verts=`jq -r '.surf_verts' config.json`
data_type=`jq -r '.type' config.json`
label=`jq -r '.label' config.json`
hemi="left right"


# make cortexmap directories
[ ! -d ./cortexmap ] && mkdir -p cortexmap cortexmap/cortexmap cortexmap/cortexmap/func cortexmap/cortexmap/surf cortexmap/cortexmap/label

## vertices
# loop through hemispheres, copy files that don't need conversion / convert files that do
for h in ${hemi}
do
	# set directory
	tmpdir=${surf_verts}/${h}

	# grab data files
	files=(`ls ${tmpdir}`)

	# identify if files need to be converted
	for i in ${files}
	do
		if [[ ${i} == *".surf.gii"* ]]; then
			cp ${tmpdir}/${i} ./cortexmap/cortexmap/surf/
		else
			substr=${i%%.gii}
			cp ${tmpdir}/${i} ./cortexmap/cortexmap/surf/lh.${substr}.surf.gii
		fi
	done
done

## data
tmpdir=${surf_data}
if [ -f ${label} ]; then
	importdir="label"
	for h in ${hemi}
	do
		if [[ ${h} == 'left' ]]; then
			hem="lh"
		else
			hem="rh"
		fi
		cp ${tmpdir}/${h}.gii cortexmap/cortexmap/label/${hem}.parc.label.gii
	done
else
	importdir="func"
	for h in ${hemi}
	do
		if [[ ${h} == 'left' ]]; then
			hem="lh"
		else
			hem="rh"
		fi
		cp ${tmpdir}/${h}.gii cortexmap/cortexmap/func/${hem}.data.func.gii
	done
fi

# final check
[ "$(ls -A ./cortexmap/cortexmap/${importdir})" ] && echo "something went wrong. check logs and derivatives" && exit 1 || echo "complete" && exit 0




