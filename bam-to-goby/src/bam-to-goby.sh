#!/bin/bash
# bam-to-goby 0.0.1
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

    echo "Value of sorted_bam: '${Realigned_Bam[@]}'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".
    mkdir -p /input/BAM
    mkdir -p /input/FASTA_Genome
    mkdir -p /input/Goby_Genome
    mkdir -p /out/Goby_Alignment

    for i in ${!Realigned_Bam[@]}
    do
        echo "Downloading BAM file '${Realigned_Bam_name[$i]}'"
        dx download "${Realigned_Bam[$i]}" -o sorted_bam-$i /input/BAM/${Realigned_Bam_name[$i]}
    done

    #download the gzipped genome
    echo "Downloading genome file '${Genome_name}'"
    dx download "${Genome}" -o /input/FASTA_Genome/${Genome_name}
    #unzip
    (cd /input/FASTA_Genome; gunzip ${Genome_name})
    #index
    (cd /input/Goby_Genome; samtools faidx /input/FASTA_Genome/*.fasta)

    #build goby indexed genome
    goby 6g build-sequence-cache /input/FASTA_Genome/${Genome_name}

    alignment_basename=`basename /input/BAM/*.bam | cut -d. -f1`
    goby_genome_basename=`basename /input/Goby_Genome/*.bases | cut -d. -f1`
    genome_basename=`basename /input/indexed_genome/*.fasta | cut -d. -f1`

    echo "export OUTPUT_BASENAME=${alignment_basename}" >> /input/configure.sh
    echo "export FASTA_GENOME=/input/FASTA_Genome/${genome_basename}" >> /input/configure.sh
    echo "export SBI_GENOME=/input/Goby_Genome/${goby_genome_basename}" >> /input/configure.sh
    echo "SBI_NUM_THREADS=\"3\"" >> /input/configure.sh

     # invoke the predict-genotypes-many script inside the container
    dx-docker run \
        -v /input/:/input \
        -v /out/Goby_Alignment/:/out/Goby_Alignment \
        artifacts/variationanalysis-app:latest \
        bash -c "source ~/.bashrc; source /input/configure.sh; cd /out/Goby_Alignment; parallel-bam-to-goby.sh \"/input/BAM/${alignment_basename}\""


    #for i in "${!Goby_Alignment[@]}"; do
    #    dx-jobutil-add-output Goby_Alignment "${Goby_Alignment[$i]}" --class=array:file
    #done


    #data objects must be in the closed state before they are exported
    dx close $HOME/out/Goby_Alignment/*

    dx-upload-all-outputs

}