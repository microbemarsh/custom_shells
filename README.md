# fun_shell_scripts
# I currently use all of these within a SLURM HPC

This is a collection of shell scripts I produce and use in the analysis of bacterial metagenomic data. 

* 16S.sh
  This will perform chopper [chopper](https://github.com/wdecoster/chopper/ "chopper") trimming and [emu](https://gitlab.com/treangenlab/emu/ "emu") abundance estimations on gzipped fastq files from ONT nanopore sequence data. I generally will use a shell script to perform the seqkit scat step prior to this so I can rename my samples individually.

* hgtloop.sh
  This script will loop through multiple metagenomic contigs in fasta format and use [waafle](https://github.com/biobakery/waafle/ "waafle") to identify lateral gene transfer events.

* amrloop.sh
  This will loop through multiple metagenomic contigs as well multiple databases and attempt to find antimicrobial resistance (AMR) genes using the tool [abricate](https://github.com/tseemann/abricate "abricate"), it in the future will incorporate possible AMR prediction with the tool [RGI](https://github.com/arpcard/rgi "RGI"). The loop will take your outputs and create an interactive "hamronized" output in the end.
