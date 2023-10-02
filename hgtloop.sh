### Only use this top part if you're on an HPC system

#!/bin/bash
#SBATCH --time=04-00:00:00
#SBATCH --partition=general
#SBATCH --mail-user=marshaag@clarkson.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --ntasks-per-node=40
#SBATCH --nodes=1
#SBATCH --job-name=hgtloop
#SBATCH --comment=hgtloop

source .bashrc

echo "Software to Analyze Lateral Gene Transfer from Multiple Metagenomic Contigs"
echo "Created by Austin Marshall, Dept. of Biology @ Clarkson University. Built for use with https://github.com/biobakery/waafle"

mkdir soil_waafle
DIR="$PWD"
OUTDIR="$PWD/cooked_waafle"
DB_DIR="/your/path/to/waafle/waafledb/waafledb"

# Running search to BLAST contig/s against waafle database
for f in *contigs.fasta; do filename="${f%*.contigs.fasta}"; echo $f "Start Time: `date`"; /your/path/to/waafle/bin/waafle_search $f "${DB_DIR}" --threads 80 ; echo $(date); done

# Running genecaller to create .gff file from .blastout file
for f in *contigs.blastout; do filename="${f%*.contigs.blastout}"; echo $f "Start Time: `date`"; /your/path/to/waafle/bin/waafle_genecaller $f ; echo $(date); done

# Running orgscorer to find the LGT events, first we have to define an array of input prefixes
input_prefixes=("s1" "s2" "s3" "s4" "s5" "s6")

# Loop (flips) through each input prefix
for prefix in "${input_prefixes[@]}"; do
    # Define input file names
    fasta_file="${prefix}_contigs.fasta"
    blastout_file="${prefix}_contigs.blastout"
    gff_file="${prefix}_contigs.gff"
    taxonomy_file="/your/path/to/waafle/waafledb_taxonomy.tsv"

    # Check if all required input files exist
    if [ -f "$fasta_file" ] && [ -f "$blastout_file" ] && [ -f "$gff_file" ]; then
        echo "Processing files for $prefix"

        # Run the waafle_orgscorer command with the input files
        /your/path/to/waafle/bin/waafle_orgscorer --basename "${prefix}" "$fasta_file" "$blastout_file" "$gff_file" "$taxonomy_file"
        echo "Finished processing files for $prefix"
    else
        echo "Files not found for $prefix"
    fi
done

echo "your waafles are ready"
