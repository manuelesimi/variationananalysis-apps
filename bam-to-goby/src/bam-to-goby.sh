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

    mkdir -p /input/BAM
    mkdir -p /input/scripts
    mkdir -p /input/FASTA_Genome
    mkdir -p /input/Goby_Genome
    mkdir -p /out/Goby_Alignment

    echo "Downloading BAM file '${Realigned_Bam_name}'"
    dx download "${Realigned_Bam}" -o /input/BAM/${Realigned_Bam_name}

    echo "Downloading BAM file '${Realigned_Bam_Index_name}'"
    dx download "${Realigned_Bam_Index}" -o /input/BAM/${Realigned_Bam_Index_name}

    #download the gzipped genome
    echo "Downloading genome file '${Genome_name}'"
    dx download "${Genome}" -o /input/FASTA_Genome/${Genome_name}
    #unzip
    (cd /input/FASTA_Genome; gunzip ${Genome_name})
    genome=`basename /input/FASTA_Genome/*.fa*`

    echo "Downloading the docker image..."
    dx-docker pull artifacts/variationanalysis-app:latest &>/dev/null
    
    cat >/input/scripts/index.sh <<EOL
    #!/bin/bash
    set -x
    ls -lrt  /input/FASTA_Genome/
    cd /input/FASTA_Genome
    samtools faidx /input/FASTA_Genome/*.fa*
    ls -lrt  /input/FASTA_Genome/
    cd /input/Goby_Genome/
     #build goby indexed genome
    goby 10g build-sequence-cache /input/FASTA_Genome/${genome}
    ls -lrt  /input/Goby_Genome/
    ls -lrt  /input/FASTA_Genome/

EOL
    chmod u+x /input/scripts/index.sh

    #index
    dx-docker run \
        -v /input/:/input \
        artifacts/variationanalysis-app:latest \
        bash -c "source ~/.bashrc; cd /input/Goby_Genome; /input/scripts/index.sh"

    alignment_basename=`basename /input/BAM/*.bam | cut -d. -f1`
    goby_genome_basename=`basename /input/FASTA_Genome/*.bases | cut -d. -f1`
    echo "export OUTPUT_BASENAME=${alignment_basename}" >> /input/configure.sh
    echo "export FASTA_GENOME=/input/FASTA_Genome/${genome}" >> /input/configure.sh
    echo "export SBI_GENOME=/input/FASTA_Genome/${goby_genome_basename}" >> /input/configure.sh
    cpus=`grep physical  /proc/cpuinfo |grep id|wc -l`
    echo "export SBI_NUM_THREADS=${cpus}" >> /input/configure.sh

    dx-docker run \
        -v /input/:/input \
        -v /out/Goby_Alignment/:/out/Goby_Alignment \
        artifacts/variationanalysis-app:latest \
        bash -c "source ~/.bashrc; source /input/configure.sh; cd /out/Goby_Alignment; parallel-bam-to-goby.sh 6g /input/BAM/*.bam"

    #upload the output
    ls -lrt /out/Goby_Alignment
    mkdir -p $HOME/out/
    #remove refs.txt and calmd-and-convert-commands.txt
    rm /out/Goby_Alignment/*.txt
    mv /out/Goby_Alignment/ $HOME/out/
    dx-upload-all-outputs
}
