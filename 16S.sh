#!/bin/bash

#SBATCH --time=04-00:00:00
#SBATCH --partition=general
#SBATCH --mail-user=marshaag@clarkson.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --ntasks-per-node=40
#SBATCH --nodes=1
#SBATCH --job-name=emuloop
#SBATCH --comment=emuloop

source .bashrc

echo "Rapid 16S Nanopore Analysis Software to Generate Emu Relative Abundance Tables"

echo "Created by Austin Marshall, Clarkson University with help from Christian Castro, NASA JSC"

# Make sure your reads have adapters and barcodes trimmed by guppy/dorado

mkdir rdp_out 
DIR="$PWD"
ABUND_DIR="$PWD/rdp_out"
DB_DIR="/path/to/database/emu/rdp_database"

mamba activate emu

# Running chopper to trim reads by length and quality, uncomment when needing to trim
for f in *.fq.gz; do filename="${f%*.fq.gz}"; echo $f "Start Time: `date`"; gunzip -c $f | chopper -q 12 --threads 78 --minlength 1350 --maxlength 1650 | cat > $filename".fq" ; echo $(date); done

#Compute emu relative abundances for all fastqs
for f in *.fq; do filename="${f%*.fq}"; echo $f "Start Time: `date`"; emu abundance $f --db "${DB_DIR}" --threads 80 --keep-counts --output-dir "${ABUND_DIR}" ; echo $(date); done

#Combine all samples into one otu type table for species
for f in *rel-abundance.tsv; do filename="${f%*rel-abundance.tsv}"; echo $f "Start Time: `date`"; emu combine-outputs --split-tables "${ABUND_DIR}" species ; echo $(date); done

#Combine all samples into one otu type table for species counts
for f in *rel-abundance.tsv; do filename="${f%*rel-abundance.tsv}"; echo $f "Start Time: `date`"; emu combine-outputs --counts --split-tables "${ABUND_DIR}" species ; echo $(date); done

#Combine all samples into one otu type table for genus
for f in *rel-abundance.tsv; do filename="${f%*rel-abundance.tsv}"; echo $f "Start Time: `date`"; emu combine-outputs --split-tables "${ABUND_DIR}" genus ; echo $(date); done

#Combine all samples into one otu type table for phylum
for f in *rel-abundance.tsv; do filename="${f%*rel-abundance.tsv}"; echo $f "Start Time: `date`"; emu combine-outputs --split-tables "${ABUND_DIR}" phylum ; echo $(date); done

echo "congrats, now move to R for visualization"
