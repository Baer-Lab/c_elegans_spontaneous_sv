#!/bin/sh
#SBATCH --job-name=ST1.N2.WS270
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=ayushsaxena.iitg@gmail.com
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=250gb
#SBATCH --time=95:00:00
#SBATCH --output=ST1.N2.WS270_%j.log
#SBATCH --account=baer
#SBATCH --qos=baer-b
date;hostname;pwd

# Run the smrt-sv2 workflow for N2 using the WS270 reference genome

home="/ufrc/baer/s.ayush/SV_MA/Analysis/smrtsv2/N2/Strategy1/WS270"
reference="/ufrc/baer/s.ayush/SV_MA/Reference/WS270/c_elegans.PRJNA13758.WS270.genomic.fa"
inputs="/ufrc/baer/s.ayush/SV_MA/Analysis/smrtsv2/N2/input_bams.fofn"
TMP=$home/TEMPDIR

cd $home/Working_directory
module load smrtsv2 slurm-drmaa repeatmasker

echo "smrtsv --tempdir ${TMP}  --verbose --dryrun  run --runjobs 10,10,5,5 --batches 3 --threads 64 --species Elegans \
--asm-polish arrow --min-support 10 --min-hardstop-support 5 \
--asm-cpu 12 --asm-mem 15G --min-length 30 --asm-rt "00:10:00:00" --asm-group-rt "02:00:00:00" \
${reference} ${inputs}
"

smrtsv --tempdir ${TMP}  --verbose  run --runjobs 10,10,5,5 --batches 3 --threads 64 --species Elegans \
--asm-polish arrow --min-support 3 --min-hardstop-support 3 \
--asm-cpu 12 --asm-mem 20G --min-length 30 --asm-rt "01:10:00:00" --asm-group-rt "02:00:00:00" \
${reference} ${inputs}


date

