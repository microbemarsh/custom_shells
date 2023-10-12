#! /bin/bash

echo "Complete analysis of ONT Nanopore 16S sequencing data"

echo "Created by Austin Marshall, Dept. of Biology @ Clarkson University"

echo "There is one manual part of this script, it is the naming of the files in the next two lines"

# Write what barcodes you used here in the format "SQK-16S024_barcodeXX.fastq.gz"
original_names=("SQK-16S024_barcode15.fastq.gz" "SQK-16S024_barcode16.fastq.gz" "SQK-16S024_barcode13.fastq.gz" "SQK-16S024_barcode14.fastq.gz")

# Write the new names substituting "SQK-16S024_barcodeXX.fastq.gz" for "samplename.fastq.gz"
new_names=()

# Check if the new_names array is empty
if [ ${#new_names[@]} -eq 0 ]; then
    echo "No new names have been provided. Exiting..."
    exit 1
fi

# Create the directories for our files to go into
mkdir emu_output
mkdir rdp_output
mkdir fastqs

DIR="$PWD"
DEMUX_OUTDIR="$PWD/fastqs"
EMU_ABUND_DIR="$PWD/emu_output"
RDP_ABUND_DIR="$PWD/rdp_output"

MODEL_DIR="/home/cmi/Documents/dorado_models"
EMU_DB_DIR="/home/cmi/Documents/emu/emu_database"
RDP_DB_DIR="/home/cmi/Documents/emu/rdp_database"


# Move all fast5 files to the same folder
for p in fast5_pass/barcode*/*.fast5; do
    mv $p fast5_pass ;
done

for s in fast5_skip/*.fast5; do
    mv $s fast5_pass ;
done

# Convert fast5 to pod5
if [ -e output.pod5 ]; then
    echo "output.pod5 file already exists. Skipping step."
else
    # Generate the pod5 output file
    echo "Generating output.pod5 file..."
    pod5 convert fast5 ./fast5_pass/*.fast5 -o output.pod5 
    touch output.pod5 
fi

# Run dorado on our pod5 files we just converted
if [ -e output.bam ]; then
    echo "dorado output file already exists. Skipping step."
else
    # Generate the bam output file
    echo "Generating dorado_reads.fastq file..."
    dorado basecaller -r --min-qscore 10 --kit-name "SQK-16S024" "${MODEL_DIR}"/dna_r9.4.1_e8_sup@v3.6 output.pod5 > output.bam 
    touch output.bam ;
fi

# Demultiplex and convert the output.bam to fastqs
dorado demux --kit-name SQK-16S024 --emit-fastq --output-dir "${DEMUX_OUTDIR}" output.bam

# Once a large fastq file for each sample is made we will select only the reads 1350 >= x =< 1650 bps
for f in "${DEMUX_OUTDIR}"/*.fastq; do filename="${f%*.fastq}";
    echo $f "Start Time: `date`";
    cat $f | chopper --minlength 1350 --maxlength 1650 --threads 8 | pigz > $filename".fastq.gz"
    echo $(date);
done

# Loop through the files and rename the actual samples
for ((i=0; i<${#original_names[@]}; i++)); do
    original_name="${original_names[$i]}"
    new_name="${new_names[$i]}"
    
    # Check if the original file exists in the source directory
    if [ -e "${DEMUX_OUTDIR}/${original_name}" ]; then
        # Rename and move the file to the target directory
        mv "${DEMUX_OUTDIR}/${original_name}" "${DIR}/${new_name}"
        echo "Renamed: ${original_name} to ${new_name}"
    else
        echo "Original file not found: ${original_name}. Skipping..."
    fi
done

# Gunzip the files to run emu on
for f in "${DIR}"/*.fastq.gz; do filename="${f%*.fastq.gz}";
    echo $f "Start Time: `date`";
    pigz -d -p10 $f ;
    echo $(date);
done

# Activate mamba environment containing emu
source ~/mambaforge/bin/activate 16S

#Compute emu relative abundances for all fastqs with the EMU database
for f in "${DIR}"/*.fastq; do filename="${f%*.fastq}"; 
    echo $f "Start Time: `date`"; 
    emu abundance $f --db "${EMU_DB_DIR}" --threads 15 --keep-counts --output-dir "${EMU_ABUND_DIR}" ; 
    echo $(date); 
done

#Compute emu relative abundances for all fastqs with the RDP database
for f in "${DIR}"/*.fastq; do filename="${f%*.fastq}"; 
    echo $f "Start Time: `date`"; 
    emu abundance $f --db "${RDP_DB_DIR}" --threads 15 --keep-counts --output-dir "${RDP_ABUND_DIR}" ; 
    echo $(date); 
done

#Combine all samples into one otu type table for species for the EMU output
for f in *rel-abundance.tsv; do filename="${f%*rel-abundance.tsv}"; 
    echo $f "Start Time: `date`"; emu combine-outputs --split-tables "${EMU_ABUND_DIR}" species ; 
    echo $(date); 
done

#Combine all samples into one otu type table for species counts for the EMU output
for f in *rel-abundance.tsv; do filename="${f%*rel-abundance.tsv}"; 
    echo $f "Start Time: `date`"; emu combine-outputs --counts --split-tables "${EMU_ABUND_DIR}" species ; 
    echo $(date); 
done

#Combine all samples into one otu type table for genus for the EMU output
for f in *rel-abundance.tsv; do filename="${f%*rel-abundance.tsv}"; 
    echo $f "Start Time: `date`"; emu combine-outputs --split-tables "${EMU_ABUND_DIR}" genus ; 
    echo $(date); 
done

#Combine all samples into one otu type table for phylum for the EMU output
for f in *rel-abundance.tsv; do filename="${f%*rel-abundance.tsv}"; 
    echo $f "Start Time: `date`"; emu combine-outputs --split-tables "${EMU_ABUND_DIR}" phylum ; 
    echo $(date); 
done

#Combine all samples into one otu type table for species for the RDP output
for f in *rel-abundance.tsv; do filename="${f%*rel-abundance.tsv}"; 
    echo $f "Start Time: `date`"; emu combine-outputs --split-tables "${RDP_ABUND_DIR}" species ; 
    echo $(date); 
done

#Combine all samples into one otu type table for species counts for the RDP output
for f in *rel-abundance.tsv; do filename="${f%*rel-abundance.tsv}"; 
    echo $f "Start Time: `date`"; emu combine-outputs --counts --split-tables "${RDP_ABUND_DIR}" species ; 
    echo $(date); 
done

#Combine all samples into one otu type table for genus for the RDP output
for f in *rel-abundance.tsv; do filename="${f%*rel-abundance.tsv}"; 
    echo $f "Start Time: `date`"; emu combine-outputs --split-tables "${RDP_ABUND_DIR}" genus ; 
    echo $(date); 
done

#Combine all samples into one otu type table for phylum for the RDP output
for f in *rel-abundance.tsv; do filename="${f%*rel-abundance.tsv}"; 
    echo $f "Start Time: `date`"; emu combine-outputs --split-tables "${RDP_ABUND_DIR}" phylum ; 
    echo $(date); 
done

echo "congrats, now move to R for visualization"


