# Map tract endpoint ROIs to cortical surface for quantitative analyses

**Update 2024.03.31: Brainlife version back online. Use online version instead of local version.**

Using Brainlife app locally for SemConn UT diffusion processing & testing. 
Use branch `endpoints-v1.1` for the app version with negative `projfrac` & smoothing[^1]. 

[^1]: `projfrac` & smoothing params details: 
* 2023.12.05:
  * current setting: `projfrac_min=-1`, some smoothing (heven't decided on width).
* 2024.02.07: 
  * Brad: these are all hyperparams that should be determined by the results. Could do width vs results plot to choose. For now using the most smooth (`sigma=1`)

## General pipeline
1. `run_main.py`: Creates a separate directory for each subjects, generates surface ROI map, then uploads the results to Brainlife project [Semantic Connectivity - UT](https://brainlife.io/project/6542d7ceb094062da61faac2/) with the specified tags;
2. [TODO] script: copy results to grimes/corral.
    * note output `cortexmap/cortexmap/func` dir contains both smoothed & nonsmoothed data. copy only desired ones over.

## TODO:
* after `run_main.py`: add script to copy things over to correct location to grimes/corral

---
# orignal README
[![Abcdspec-compliant](https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg)](https://github.com/brain-life/abcd-spec)
[![Run on Brainlife.io](https://img.shields.io/badge/Brainlife-brainlife.app.572-blue.svg)](https://doi.org/10.25663/brainlife.app.572)

# Map tract endpoint ROIs to cortical surface for quantitative analyses
This app will map regions of interest of tract endpoints to the cortical surface in order to use for downstream quantitative analyses. 

The code for this app was adapted from HCP's PostFreesurfer pipeline (https://github.com/Washington-University/HCPpipelines/blob/master/PostFreeSurfer/scripts/FreeSurfer2CaretConvertAndRegisterNonlinear.sh) and RIKEN - Brain Connectomics Imaging Laboratory's NoddiSurfaceMapping repository (https://github.com/RIKEN-BCIL/NoddiSurfaceMapping) for use on brainlife.io.

### Authors
- Brad Caron (bacaron@iu.edu)

### Contributors
- Soichi Hayashi (hayashi@iu.edu)
- Franco Pestilli (franpest@indiana.edu)

### Funding

brainlife.io is publicly funded and for the sustainability of the project it is helpful to Acknowledge the use of the platform. We kindly ask that you acknowledge the funding below in your publications and code reusing this code.

[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-1636893](https://img.shields.io/badge/NSF_BCS-1636893-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-ACI-1916518](https://img.shields.io/badge/NSF_ACI-1916518-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1916518)
[![NSF-IIS-1912270](https://img.shields.io/badge/NSF_IIS-1912270-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1912270)
[![NIH-NIBIB-R01EB029272](https://img.shields.io/badge/NIH_NIBIB-R01EB029272-green.svg)](https://grantome.com/grant/NIH/R01-EB029272-01)

### Citations

We kindly ask that you cite the following articles when publishing papers and code using this code.

1. Avesani, P., McPherson, B., Hayashi, S. et al. The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. Sci Data 6, 69 (2019). https://doi.org/10.1038/s41597-019-0073-y

2. Fukutomi, H. et al. Neurite imaging reveals microstructural variations in human cerebral cortical gray matter. Neuroimage (2018). doi:10.1016/j.neuroimage.2018.02.017

3. Glasser MF, Sotiropoulos SN, Wilson JA, et al. The minimal preprocessing pipelines for the Human Connectome Project. Neuroimage. 2013;80:105-124. doi:10.1016/j.neuroimage.2013.04.127

## Running the App 

### On Brainlife.io

You can submit this App online at [https://doi.org/10.25663/brainlife.app.572](https://doi.org/10.25663/bl.app.572) via the "Execute" tab.

### Running Locally (on your machine)

1. git clone this repo.
2. Inside the cloned directory, create `config.json` with something like the following content with paths to your input files.

```json
{
        "rois": "./input/rois/rois",
        "freesurfer": "./input/freesurfer/output",
        "warp": "./input/warp/warp.nii.gz",
        "inverse_warp": "./input/warp/inverse-warp.nii.gz",
        "cortexmap": "./input/cortexmap/cortexmap",
        "fsurfparc": "aparc.a2009s"
}
```

<!-- ### Sample Datasets

You can download sample datasets from Brainlife using [Brainlife CLI](https://github.com/brain-life/cli).

```
npm install -g brainlife
bl login
mkdir input
bl dataset download --id 5b96bbf2059cf900271924f3 && mv 5b96bbf2059cf900271924f3 input/
bl dataset download --id 5967bffa9b45c212bbec8958 && mv 5967bffa9b45c212bbec8958 input/freesurfer
bl dataset download --id 5c5d35e3f5d2a10052842848 && mv 5c5d35e3f5d2a10052842848 input/tensor

```


3. Launch the App by executing `main`

```bash
./main
``` -->

## Output

The main output of this app is a folder entitled 'cortexmap', with the subdirectories 'func', 'label', and 'surf'. 'func' contains the measures mapped to the surface in the form of .func.gii files. 'label' contains the aparc.a2009s labels converted to CARET in the form of .label.gii files. 'surf' contains the surface files, including the midthickness surface, in the form of '.surf.gii' and '.shape.gii' files. This app also outputs a folder entitled 'raw', which contains the derivatives generated during the application. These are intended to be used in either quality assurance or generating figures.

#### Product.json
The secondary output of this app is `product.json`. This file allows web interfaces, DB and API calls on the results of the processing. 

### Dependencies

This App only requires [singularity](https://www.sylabs.io/singularity/) to run. If you don't have singularity, you will need to install the following libraries:

  - singularity: https://singularity.lbl.gov/
  - FSL: https://hub.docker.com/r/brainlife/fsl/tags/5.0.9
  - Freesurfer: https://hub.docker.com/r/brainlife/freesurfer/tags/6.0.0
  - jsonlab: https://github.com/fangq/jsonlab.git
  - Connectome Workbench: https://hub.docker.com/r/brainlife/connectome_workbench
  
