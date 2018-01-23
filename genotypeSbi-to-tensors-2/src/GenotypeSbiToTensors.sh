#!/bin/bash
# GenotypeSbiToTensors 0.0.1
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

    echo "Value of SBI: '${GenotypeSBI[@]}'"
    echo "Value of FeatureMapper: '$FeatureMapper'"
    echo "Value of SampleName: '$SampleName'"
    echo "Value of LabelSmoothingEpsilon: '$LabelSmoothingEpsilon'"
    echo "Value of Ploidy: '$Ploidy'"
    echo "Value of GenomicContextLength: '$GenomicContextLength'"

    #download inputs in $HOME/in
    dx-download-all-inputs --parallel

    SBI_basename=`basename ${HOME}/in/SBI/*.sbi .sbi`
    echo "SBI basename: '$SBI_basename'"

    dx-docker pull artifacts/variationanalysis-app:latest &>/dev/null

    mkdir -p $HOME/out/VEC

    dx-docker run \
        -v /input/:/input \
        -v /output/sbi:/output/sbi \
        artifacts/variationanalysis-app:latest \
        bash -c "source ~/.bashrc; cd $HOME/out/VEC; export-genotype-tensors.sh 2g -feature-mapper ${FeatureMapper} -i \"/${HOME}/in/SBI/${SBI_basename}.sbi\" -o ${SBI_basename} --label-smoothing-epsilon ${LabelSmoothingEpsilon} --ploidy ${Ploidy} --genomic-context-length ${GenomicContextLength} --export-inputs input --export-outputs softmaxGenotype --sample-name [${SampleName}]  --sample-type germline"

    dx-upload-all-outputs --parallel

}
