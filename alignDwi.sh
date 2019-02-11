#!/bin/bash

dwi=`jq -r '.dwi' config.json`;

flirt -in ${dwi} -ref ./cortexmap/surf/ribbon.nii.gz -out ./dwi_resliced.nii.gz -omat ./acpcxform.mat;
