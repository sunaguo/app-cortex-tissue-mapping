"""
create directory & copy scripts for each subject for ease of data control
"""

import json
import glob
import os
import subprocess
import time

print("recommended to bl login rn for data upload. proceed to processing in 5 seconds...")
time.sleep(5)
print("starting processing!")

## ===== configs
bl_subjects = ["20231130AH", "20231117RA", "20231208AA"]  #
subjects = ["AHqsi2", "RAqsi", "AAqsi"]  #
datatype_tags = []
tags = ["qsiprep_freesurfer", "ras_lpi_relabel"]

## ===== var init
params = {
    "fsurfparc": "aparc.a2009s",
    "volume_smooth_kernel": "",
    "surface_smooth_kernel": "1",
    "fix_zeros": False,
    "surface_fwhm": False,
    "surface_smooth_method": "GEO_GAUSS_AREA",
    "projfrac_min": "-1"
}

main = """#!/bin/bash
#PBS -l nodes=1:ppn=8,walltime=6:30:00
#PBS -N app-cortex-mapping
#PBS -l vmem=20gb
#PBS -V

set -e

[ -z "$FREESURFER_LICENSE" ] && echo "Please set FREESURFER_LICENSE in .bashrc" && exit 1;
echo $FREESURFER_LICENSE > license.txt

echo "mapping measures to cortical surface"
time singularity exec -e -B `pwd`/license.txt:/usr/local/freesurfer/license.txt docker://brainlife/connectome_workbench:1.5.0 ./cortex-mapping-pipeline.sh

mv *.nii.gz c_ras.mat ./metric/ ./raw/
"""

for (blsid, sid) in zip(bl_subjects, subjects):
    ## ===== create & copy things to subject dir
    os.chdir("/home/sunaguo/code/app-cortex-tissue-mapping")

    subjdir = f"outputs/{sid}/"

    if not os.path.exists(subjdir):
        os.mkdirs(subjdir)
    ## always update to newest version
    for fp in [f"{subjdir}/cortex-mapping-pipeline.sh", 
               f"{subjdir}/config.json",
               f"{subjdir}/main"]:
        if os.path.exists(fp): 
            os.remove(f"{subjdir}/cortex-mapping-pipeline.sh")
    os.system(f"cp cortex-mapping-pipeline.sh {subjdir}/cortex-mapping-pipeline.sh")

    print(blsid)
    rois = glob.glob(f"/media/storage/UT_subjects/proj-654*/sub-{blsid}/*tractEndpointDensity*relabel*/rois")[0]
    fs = glob.glob(f"./inputs/proj-651*/sub-{blsid}/*freesurfer*qsiprep*/output")[0]

    print(rois)
    print(fs)

    d = {
        "subeject": sid, 
        "rois": rois,
        "freesurfer": "." + fs
    }
    sparams = {**d, **params}
    # print(sparams)

    with open(f"{subjdir}/config.json", "w") as f:
        json.dump(sparams, f)

    # mainstr = main.format(blsid)
    with open(f"{subjdir}/main", "w") as f:
        f.write(main)

    # ## ===== run ROI mapping
    print(os.getcwd())
    os.chdir(subjdir)
    print(os.getcwd())

    subprocess.run(["chmod", "u+x", f"main"])
    # subprocess.run([f"./main"])  ## somehow this container doesn't recognize fs licence on ruby
    subprocess.run(["bash", "cortex-mapping-pipeline.sh"])

    # ## ===== upload results to bl
    # blcmd = """bl data upload -p 6542d7ceb094062da61faac2 -d neuro/cortexmap
    #         --datatype_tag tractEndpointDensity --datatype_tag resliced --datatype_tag anat --datatype_tag rois
    #         --tag ruby_gen --tag semconn_pipeline
    #         --cortexmap ./cortexmap/cortexmap
    #     """.split()
    
    # blcmd += ["--subject", blsid]
    # for dt in datatype_tags:
    #     blcmd += ["--datatype_tag", dt]
    # for t in tags:
    #     blcmd += ["--tag", t]

    # print(blcmd)
    # subprocess.run(blcmd)

    break