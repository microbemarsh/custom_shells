This is a collection of shell scripts I produced and use in the analysis of bacterial metagenomic data. I currently use the second two within a SLURM HPC.

* [16S.sh](https://github.com/microbemarsh/custom_shells/blob/main/16S.sh/ "16S.sh")
  will perform everything from [fast5 --> pod5](https://github.com/nanoporetech/pod5-file-format/blob/master/python/pod5/README.md#pod5-convert-fast5) file conversion, [dorado](https://github.com/nanoporetech/dorado) basecalling, length filtering reads with [chopper](https://github.com/wdecoster/chopper/ "chopper") and finally [emu](https://gitlab.com/treangenlab/emu/ "emu") abundance estimations with both the Emu and RDP databases. This was intended for use with ONT nanopore 16S sequence data and the only inputs are the fast5 files from your sequencing run. You must input your new file names into the script before running, that is the only manual part of the pipeline.

* [hgtloop.sh](https://github.com/microbemarsh/custom_shells/blob/main/hgtloop.sh/ "hgtloop.sh")
  will loop through multiple metagenomic contigs in fasta format and use [waafle](https://github.com/biobakery/waafle/ "waafle") to identify lateral gene transfer events.

* [amrloop.sh](https://github.com/microbemarsh/custom_shells/blob/main/amrloop.sh/ "amrloop.sh")
  will loop through multiple metagenomic contigs as well multiple databases and attempt to find antimicrobial resistance (AMR) genes using the tool [abricate](https://github.com/tseemann/abricate "abricate"), it in the future will incorporate possible AMR prediction with the tool [RGI](https://github.com/arpcard/rgi "RGI"). The loop will take your outputs and create an interactive "hamronized" output in the end. Still a work in progress.
