#! /bin/bash

echo "Complete analysis of ONT Nanopore 16S sequencing data"

echo "Created by Austin Marshall, Dept. of Biology @ Clarkson University"

echo "There is one manual part of this script, it is the naming of the files in the next two lines"

# Write what barcodes you used here in the format "BCXX.fastq.gz"
original_names=("BC14.fastq.gz" "BC15.fastq.gz" "BC16.fastq.gz")

# Write the new names substituting "BCXX.fastq.gz" for "samplename.fastq.gz"
new_names=()

# Check if the new_names array is empty
if [ ${#new_names[@]} -eq 0 ]; then
    echo "No new names have been provided. Exiting..."
    exit 1
fi

# Create the directories for our files to go into
mkdir POD5_output
mkdir dorado_output
mkdir emu_output
mkdir rdp_output
mkdir trimmed_reads

DIR="$PWD"
POD5_OUTDIR="$PWD/POD5_output"
MODEL_DIR="/home/cmi/Documents/dorado_models"
DORADO_OUTDIR="$PWD/dorado_output"
TRIM_DIR="$PWD/trimmed_reads"
EMU_DB_DIR="/home/cmi/Documents/emu/emu_database"
RDP_DB_DIR="/home/cmi/Documents/emu/rdp_database"
EMU_ABUND_DIR="$PWD/emu_output"
RDP_ABUND_DIR="$PWD/rdp_output"

# Move all fast5 files outside of their folders, we'll sort later
for f in fast5_pass/barcode*/*.fast5; do
    mv $f fast5_pass ;
done

for f in fast5_skip/*.fast5; do
    mv $f fast5_pass ;
done

# Convert fast5 to pod5
if [ -e "${POD5_OUTDIR}"/output.pod5 ]; then
    echo "output.pod5 file already exists. Skipping step."
else
    # Generate the pod5 output file
    echo "Generating output.pod5 file..."
    pod5 convert fast5 ./fast5_pass/*.fast5 --output "${POD5_OUTDIR}"/
    touch "${POD5_OUTDIR}"/output.pod5
fi

# Run dorado on our pod5 files we just converted
if [ -e "${DORADO_OUTDIR}"/dorado_reads.fastq.gz ]; then
    echo "dorado output file already exists. Skipping step."
else
    # Generate the fastq output file
    echo "Generating dorado_reads.fastq file..."
    dorado basecaller "${MODEL_DIR}"/dna_r9.4.1_e8_sup@v3.6 "${POD5_OUTDIR}"/ --emit-fastq > "${DORADO_OUTDIR}"/dorado_reads.fastq
    touch "${DORADO_OUTDIR}"/dorado_reads.fastq.gz
fi

# Gzip the dorado fastq file
if [ -e "${DORADO_OUTDIR}"/dorado_reads.fastq.gz ]; then
    echo "dorado output file already gzipped exists. Skipping step."
else
    # Generate the fastq output file
    echo "Gzipping dorado_reads.fastq file..."
    pigz "${DORADO_OUTDIR}"/*.fastq
    touch "${DORADO_OUTDIR}"/dorado_reads.fastq.gz
fi

# Trim the primers and adapters with porechop
cd "${DORADO_OUTDIR}"/

for f in *.fastq.gz; do filename="${f%*.fastq.gz}";
    echo $f "Start Time: `date`";
    porechop -i $f -b "${TRIM_DIR}"/ --threads 15 ;
    echo $(date);
done

# Loop through the files and rename the actual samples
for ((i=0; i<${#original_names[@]}; i++)); do
    original_name="${original_names[$i]}"
    new_name="${new_names[$i]}"
    
    # Check if the original file exists in the source directory
    if [ -e "${TRIM_DIR}/${original_name}" ]; then
        # Rename and move the file to the target directory
        mv "${TRIM_DIR}/${original_name}" "${DIR}/${new_name}"
        echo "Renamed: ${original_name} to ${new_name}"
    else
        echo "Original file not found: ${original_name}. Skipping..."
    fi
done

# Activate mamba environment containing chopper and emu
source ~/mambaforge/bin/activate 16S

# Change directory to where newly named files ar
cd "${DIR}"/

# Once a large fastq file for each sample is made we will select only the reads 1350 >= x =< 1650 base pairs and above Qscore 10
for f in *.fastq.gz; do filename="${f%*.fastq.gz}"; 
    echo $f "Start Time: `date`"; 
    gunzip -c $f | chopper -q 10 --threads 15 --minlength 1350 --maxlength 1650 | cat > $filename".fq" ; 
    echo $(date); 
done

#Compute emu relative abundances for all fastqs with the EMU database
for f in *.fq; do filename="${f%*.fq}"; 
    echo $f "Start Time: `date`"; 
    emu abundance $f --db "${EMU_DB_DIR}" --threads 15 --keep-counts --output-dir "${EMU_ABUND_DIR}" ; 
    echo $(date); 
done

#Compute emu relative abundances for all fastqs with the RDP database
for f in *.fq; do filename="${f%*.fq}"; 
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
    echo $f "Start Time: `date`"; emu combine-outputs --split-tables "${EMU_ABUND_DIR}" 
    genus ; echo $(date); 
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
