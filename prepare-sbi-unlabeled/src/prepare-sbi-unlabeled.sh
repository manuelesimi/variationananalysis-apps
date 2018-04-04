#!/bin/bash
# prepare-sbi-unlabeled 0.0.1
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
    CONFIG_FILE="${HOME}/in/scripts/configure.sh"
    mkdir -p ${HOME}/in/scripts/
    mkdir -p ${HOME}/out/SBI
    set -x 
    #flatten the inputs in a single folder
    find ${HOME}/in/Genome/ -type f -name "${Genome_prefix[0]}.*" -execdir mv {} .. \;
    find ${HOME}/in/Goby_Alignment/ -type f -name "${Goby_Alignment_prefix[0]}.*" -execdir mv {} .. \;
    
    # configure
    echo "export SBI_GENOME=/in/Genome/${Genome_prefix[0]}" >> ${CONFIG_FILE}
    echo "export GOBY_ALIGNMENT=/in/Goby_Alignment/${Goby_Alignment_prefix[0]}" >> ${CONFIG_FILE}
    echo "export GOBY_NUM_SLICES=1" >> ${CONFIG_FILE}
    # adjust num threads to match number of cores -1:
    cpus=`grep physical  /proc/cpuinfo |grep id|wc -l`
    cpus=`echo $(( cpus / 3 * 2  ))`
    alignment_basename="${Goby_Alignment_prefix[0]}"
    echo "export SBI_NUM_THREADS=${cpus}" >> ${CONFIG_FILE}
    echo "export INCLUDE_INDELS='true'" >> ${CONFIG_FILE}
    echo "export REALIGN_AROUND_INDELS='false'" >> ${CONFIG_FILE}
    echo "export REF_SAMPLING_RATE='0.01'" >> ${CONFIG_FILE}
    echo "export OUTPUT_PREFIX=${alignment_basename}" >> ${CONFIG_FILE}
    echo "export DATASET=${alignment_basename}" >> ${CONFIG_FILE}
    echo "export GOBY_NUM_SLICES='50'" >> ${CONFIG_FILE}
    echo "export DO_CONCAT='true'" >> ${CONFIG_FILE}

    echo "Content of configure.sh: "
    cat ${CONFIG_FILE}
    cat >${HOME}/in/run.sh <<EOL
        #!/bin/bash
        source /in/scripts/configure.sh
        mkdir /out/tmp
        cd /out/tmp
        generate-genotype-unlabeled.sh 20g "/in/Goby_Alignment/${Goby_Alignment_prefix[0]}" "/in/Genome/${Genome_prefix[0]}"
        mv /out/tmp/${Goby_Alignment_prefix[0]}*.sbi /out/SBI/
        mv /out/tmp/${Goby_Alignment_prefix[0]}*.sbip /out/SBI/
        rm -rf /out/tmp
EOL
    chmod a+x  ${HOME}/in/run.sh

    echo "Downloading the docker image..."
    dx-docker pull artifacts/variationanalysis-app:${Image_Version} &>/dev/null

    dx-docker run \
      -v ${HOME}/out/:/out/ \
        -v ${HOME}/in/:/in/ \
        artifacts/variationanalysis-app:${Image_Version} \
        bash -c "source ~/.bashrc; source ~/.bashrc; /in/run.sh "

    ls -lrt $HOME/out/SBI

    dx-upload-all-outputs --parallel

}
