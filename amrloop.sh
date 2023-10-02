#!/bin/bash
#SBATCH --time=04-00:00:00
#SBATCH --partition=general
#SBATCH --mail-user=marshaag@clarkson.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --ntasks-per-node=40
#SBATCH --nodes=1
#SBATCH --job-name=amrloop
#SBATCH --comment=amrloop

source .bashrc

echo "Software to Analyze Antibiotic Resistance Genes from Multiple Metagenomic Contigs"

echo "Created by Austin Marshall, Dept. of Biology @ Clarkson University. Built for use with https://github.com/tseemann/abricate"

# Activate abricate mamba environment
mamba activate abricate

for f in *contigs.fasta; do filename="${f%*.contigs.fasta}";

    for db in {ncbi,resfinder,argannot,card,ecoh,megares,plasmidfinder,ecoli_vf}; do abricate $f --db $db --noheader >> $filename"_alldbs.tsv" ; done

done

# Activate hamronization mamba environment
mamba deactivate

mamba activate hamr

# Running hamr merge all abricate amr outputs, first we have to define an array of input prefixes
input_prefixes=("SLR5" "SLR25" "SLR34" "SLR42" "SLR43" "SLR45" "SLR46" "SLR50" "SLR54" "SLR71")

# Loop through each input prefix
for prefix in "${input_prefixes[@]}"; do
    # Define input file names
    ind_file="${prefix}_alldbs.tsv"

    # Check if all required input files exist
    if [ -f "$ind_file" ]; then
        echo "Processing files for $prefix"

        # Run the waafle_orgscorer command with the input files
        hamronize abricate "$ind_file" --analysis_software_version 1.0.1 --format interactive
        echo "Finished processing files for $prefix"
    else
        echo "Files not found for $prefix"
    fi
done


