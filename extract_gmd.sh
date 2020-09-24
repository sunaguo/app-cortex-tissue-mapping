#!/bin/bash

# configurable inputs
mask=`jq -r '.mask' config.json`

# extract gmd and make it's own nifti volume
[ ! -f 5tt.mif ] && mrconvert ${mask} -stride 1,2,3,4,5 5tt.mif -force

[ ! -f gmd.nii.gz ] && mrconvert -coord 3 0 5tt.mif gmd.nii.gz -force
