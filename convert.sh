#!/bin/bash

# set top variables
surf_data_left=`jq -r '.surf_data_left' config.json`
surf_data_right=`jq -r '.surf_data_right' config.json`
surf_verts_left=`jq -r '.surf_verts_left' config.json`
surf_verts_right=`jq -r '.surf_verts_right' config.json`
label=`jq -r '.label' config.json`
hemi="left right"


# make cortexmap directories
[ ! -d ./cortexmap ] && mkdir -p cortexmap cortexmap/cortexmap cortexmap/cortexmap/func cortexmap/cortexmap/surf cortexmap/cortexmap/label

# loop through hemispheres, copy files that don't need conversion / convert files that do
for h in ${hemi}
do
	## vertices
	# set directory
	$(eval "echo \$lmax${lmax}")
	tmpdir=$(eval "echo \$surf_verts_${h}")

	# grab data files
	files=(`ls ${tmpdir}`)

	# identify if files need to be converted; if so, convert. if not, straight copy
	for i in ${files}
	do
		if [[ ${i} == *".surf.gii"* ]]; then
			cp ${tmpdir}/${i} ./cortexmap/cortexmap/surf/
		else
			substr=${i%%.gii}
			cp ${tmpdir}/${i} ./cortexmap/cortexmap/surf/lh.${substr}.surf.gii
		fi
	done

	## surface data
	# set hemisphere substring for connectome workbench format
	if [[ ${h} == 'left' ]]; then
		hem="lh"
	else
		hem="rh"
	fi

	# if label.json exists, then the data is probably parcellation data. if not, it's probably func data. identify and set appropriate output dirs and names
	if [ -f ${label} ]; then
		importdir="label"
		outname="parc.label.gii"
	else
		importdir="func"
		outname="data.func.gii"
	fi

	# copy data
	tmpdata=$(eval "echo \$surf_data_${h}")
	cp ${tmpdata} ./cortexmap/cortexmap/${importdir}/${hem}.${outname}
done

# final check
[ "$(ls -A ./cortexmap/cortexmap/${importdir})" ] && echo "something went wrong. check logs and derivatives" && exit 1 || echo "complete" && exit 0




