#!/bin/bash


# This step aligns 'pseudo-reads', which are assembled contigs from the smrt-sv2 pipeline, to the WS270 genome
# smrt-sv2 pipeline creates many intermediate bam files containing aligned contigs to different regions of the genome
# Using 'samtools fastq', the assembled contig 'reads' were extracted from the bam files, and merged across loci
# This is the 'merged.bam_derived.fastq' file on this script

# Load environment
eval "$(conda shell.bash hook)"
conda activate bioconda

numThreads=12

## Load dir address
homeDir=/home/ec2-user
scratch=$homeDir/mini; mkdir -p $scratch

fastqDirS3=/home/ec2-user/S3_buckets/ayush_sv/eicher_merged_bams_strategy1_WS270/fastqs_from_eicher_merged_bams

referenceS3=/home/ec2-user/S3_buckets/ayush_sv/WS270/c_elegans.PRJNA13758.WS270.genomic.fa
referenceName=$(basename $referenceS3)
reference=$scratch/$referenceName
cp $referenceS3 $reference

minimapExec=/home/ec2-user/apps/minimap2/minimap2

# Run code
for line in CB_MA517  CB_MA530  CB_MA563  CB_MA566  JU1088  PB_MA445  PB_MA459  N2  PB306  QX1211 Hawaii
do
	fastqFile=$fastqDirS3/$line.Strategy1.WS270.merged.bam_derived.fastq
	fastqFileName=$(basename $fastqFile)

	cp $fastqFile $scratch/
	cd $scratch

	fastqScratch=$scratch/$fastqFileName
	minimapBamScratch=$scratch/${fastqFileName/.fastq/.sorted.rg.bam}

	#[ ! -s $minimapBamScratch ] && $minimapExec -a -x map-hifi -Y -t $numThreads $reference $fastqScratch | samtools sort -@ $numThreads | samtools addreplacerg -@ $numThreads -r ID:$line -r LB:$line -r SM:$line /dev/stdin > $minimapBamScratch
	
	[ ! -s $minimapBamScratch ] && $minimapExec -a -x map-hifi -Y -t $numThreads $reference $fastqScratch | samtools addreplacerg -@ $numThreads -r ID:$line -r LB:$line -r SM:$line /dev/stdin | samtools sort -@ $numThreads  > $minimapBamScratch
	
	rm $fastqScratch

	svsigFile=$scratch/$line.svsig.gz
	vcfFile=$scratch/$line.vcf	

	[ ! -s $svsigFile ] && pbsv discover --ccs $minimapBamScratch $svsigFile
        [ ! -s $vcfFile ] && pbsv call --num-threads $numThreads $reference $svsigFile $vcfFile

done

## joint pbsv calling
N2_MA_svsig=$(for line in CB_MA517 CB_MA530 CB_MA563 CB_MA566 N2; do echo -n "$scratch/$line.svsig.gz "; done)
[ ! -s $scratch/N2_joint_MA.vcf ] && pbsv call --num-threads $numThreads $reference $N2_MA_svsig $scratch/N2_joint_MA.vcf

PB_MA_svsig=$(for line in PB_MA445 PB_MA459 PB306; do echo -n "$scratch/$line.svsig.gz "; done)
[ ! -s $scratch/PB306_joint_MA.vcf ] && pbsv call --num-threads $numThreads $reference $PB_MA_svsig $scratch/PB306_joint_MA.vcf

Wild_svsig=$(for line in JU1088 N2 PB306 QX1211 Hawaii; do echo -n "$scratch/$line.svsig.gz "; done)
[ ! -s $scratch/wild_joint.vcf ] && pbsv call --num-threads $numThreads $reference $Wild_svsig $scratch/wild_joint.vcf

