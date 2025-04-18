#!/bin/bash

# The minimap2-aligned pseudo-reads are processed by this script to be aligned against simulated WS270 genomes that contain variants

# Load environment
eval "$(conda shell.bash hook)"
conda activate bioconda

numThreads=32

## Load dir address
homeDir=/home/ec2-user
scratch=$homeDir/mini; mkdir -p $scratch

mergedBamDirS3=/home/ec2-user/S3_buckets/ayush_sv/all_eichler_merged_bams
remappedBamsDirS3=$mergedBamDirS3/remapped_bams; mkdir -p $remappedBamsDirS3


# referenceS3=/home/ec2-user/S3_buckets/ayush_sv/WS270/c_elegans.PRJNA13758.WS270.genomic.fa
# referenceName=$(basename $referenceS3)
# reference=$scratch/$referenceName
# cp $referenceS3 $reference

minimapExec=/home/ec2-user/app/minimap2/minimap2

# Run code
for variantType in WS270 Inversion Deletion Insertion
do

    [ $variantType == 'WS270' ] && var=WS270 # Runs three times and over-writes for no good reason because of simulation 1 2 3 (I dont want to rewrite code)
    [ $variantType == 'Deletion' ] && var=DEL # The keyword DEL is present in bam file names, not Deletion
    [ $variantType == 'Inversion' ] && var=INV
    [ $variantType == 'Insertion' ] && var=INS

    for simulation in 1 2 3
    do

        for line in CB_MA517 CB_MA530 CB_MA563 CB_MA566 JU1088 PB_MA445 PB_MA459 N2 PB306 QX1211 Hawaii
        do

            for strategy in Strategy1 Strategy2
            do
                [[ $var == 'WS270' ]] && bamFile=$mergedBamDirS3/$line.$strategy.$var.merged.bam || bamFile=$mergedBamDirS3/$line.$strategy.SIM.$var.$simulation.merged.bam
                bamFileName=$(basename $bamFile)
                bamFileNameScratch=$scratch/$bamFileName

                [ ! -s $bamFile ] && echo "bam file: $bamFile not found, exiting .. " && continue
                echo "bam file: $bamFile found"

                [[ $var == 'WS270' ]] && referenceS3=/home/ec2-user/S3_buckets/ayush_sv/WS270/c_elegans.PRJNA13758.WS270.genomic.fa || referenceS3=/home/ec2-user/S3_buckets/ayush_sv/WS270/$variantType/Simulation.$simulation.WS270/Simulation.$simulation.WS270.fasta
                referenceName=$(basename $referenceS3)
                referenceScratch=$scratch/$referenceName

                [ ! -s $referenceS3 ] && echo "reference file: $referenceS3 not found, exiting .. " && continue 
                echo "reference file: $referenceS3 found"

                fastqFileName=${bamFileName/.bam/.bam_derived.fastq}
                fastqFileScratch=$scratch/$fastqFileName

                cp -pr $bamFile $bamFileNameScratch
                cp -pr $referenceS3 $referenceScratch
                samtools fastq -@ $numThreads $bamFileNameScratch > $fastqFileScratch

                minimapBamScratch=$scratch/${fastqFileName/.fastq/.sorted.rg.bam}

                [ ! -s $minimapBamScratch ] && $minimapExec -a -x map-hifi -Y -t $numThreads $referenceScratch $fastqFileScratch | samtools addreplacerg -@ $numThreads -r ID:$line -r LB:$line -r SM:$line /dev/stdin | samtools sort -@ $numThreads  > $minimapBamScratch
                
                rm $fastqFileScratch
                rm $bamFileNameScratch

                svsigFile=$scratch/$bamFileName.svsig.gz
                vcfFile=$scratch/$bamFileName.vcf	

                pbsv discover --ccs $minimapBamScratch $svsigFile && pbsv call --num-threads $numThreads $referenceScratch $svsigFile $vcfFile && mv $minimapBamScratch $remappedBamsDirS3/ && mv $svsigFile $remappedBamsDirS3/ && mv $vcfFile $remappedBamsDirS3/ &

            done
        done
    done
done

# ## joint pbsv calling
# N2_MA_svsig=$(for line in CB_MA517 CB_MA530 CB_MA563 CB_MA566 N2; do echo -n "$scratch/$line.svsig.gz "; done)
# [ ! -s $scratch/N2_joint_MA.vcf ] && pbsv call --num-threads $numThreads $reference $N2_MA_svsig $scratch/N2_joint_MA.vcf

# PB_MA_svsig=$(for line in PB_MA445 PB_MA459 PB306; do echo -n "$scratch/$line.svsig.gz "; done)
# [ ! -s $scratch/PB306_joint_MA.vcf ] && pbsv call --num-threads $numThreads $reference $PB_MA_svsig $scratch/PB306_joint_MA.vcf

# Wild_svsig=$(for line in JU1088 N2 PB306 QX1211 Hawaii; do echo -n "$scratch/$line.svsig.gz "; done)
# [ ! -s $scratch/wild_joint.vcf ] && pbsv call --num-threads $numThreads $reference $Wild_svsig $scratch/wild_joint.vcf

