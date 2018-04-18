#!/bin/bash
# rtg-eval-vcf 0.0.1
# Generated by dx-app-wizard.
#
# Basic execution pattern: Your app will run on a single machine from
# beginning to end.
#
# Your job's input variables (if any) will be loaded as environment
# variables before this script runs.  Any array inputs will be loaded
# as bash arrays.
#
# Any code outside of main() (or any entry point you may add) is
# ALWAYS executed, followed by running the entry point itself.
#
# See https://wiki.dnanexus.com/Developer-Portal for tutorials on how
# to modify this file.

main() {

    dx-download-all-inputs --parallel
    set -x
    CONFIG_FILE="${HOME}/in/scripts/configure.sh"
    mkdir -p ${HOME}/in/scripts/
    mv /input/scripts/* ${HOME}/in/scripts/

    echo "export RTG_TEMPLATE_ARCHIVE=${RTG_Template_name}" >> ${CONFIG_FILE}
    echo "export RTG_TEMPLATE_PATH=/in/RTG_Template" >> ${CONFIG_FILE}
    echo "export VCF_INPUT=/in/Predictions/${Predictions_name}" >> ${CONFIG_FILE}
    echo "export VCF_INPUT_BASENAME=${Predictions_prefix}" >> ${CONFIG_FILE}
    if [ ! -z "${Regions_name}" ]; then
        echo "export BED_OBSERVED_REGIONS_INPUT=/in/Regions/${Regions_name}" >> ${CONFIG_FILE}
    fi
    echo "export BASELINE_VCF=/in/Baseline_VCF/${Baseline_VCF_name}" >> ${CONFIG_FILE}
    echo "export BASELINE_VCF_BASENAME=${Baseline_VCF_prefix}" >> ${CONFIG_FILE}
    if [ ! -z "${Baseline_Regions_name}" ]; then
        echo "export BASELINE_REGIONS=/in/Baseline_Regions/${Baseline_Regions_name}" >> ${CONFIG_FILE}
    fi
    echo "export RTG_OPTIONS=\"${RTG_Vcfeval_Options}\"" >> ${CONFIG_FILE}
    
    echo "Content of ${CONFIG_FILE}:"
    cat ${CONFIG_FILE}

    cat >${HOME}/in/run.sh <<EOL
        #!/bin/bash
        source /in/scripts/configure.sh
        source /in/scripts/working_script.sh
        execute
EOL
    chmod a+x  ${HOME}/in/run.sh


    mkdir -p ${HOME}/out/Summaries
    mkdir -p ${HOME}/out/Recall_Plots
    mkdir -p ${HOME}/out/Evaluation_Archive

    echo "Downloading the docker image..."
    dx-docker pull artifacts/variationanalysis-app:${Image_Version} &>/dev/null

    dx-docker run \
        -v ${HOME}/out/:/out/ \
        -v ${HOME}/in/:/in/ \
        artifacts/variationanalysis-app:${Image_Version} \
        bash -c "source ~/.bashrc; /in/run.sh"

    dx-upload-all-outputs --parallel

}
