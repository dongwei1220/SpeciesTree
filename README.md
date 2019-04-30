#                              SpeciesTree: an easy-to-use and robust pipeline for eukaryotic species tree construction

## Table of contents

- #### [Introduction](#Introduction)

- #### [Features](#Features)

- #### [Dependencies](#Dependencies)

- #### [Installation](#Installation)

- #### [Running](#Running)

- #### [Contact](#Contact)

## Introduction

**SpeciesTree** is a useful tool to construct species trees using stringent `single-copy nuclear genes` across multiple species. It has been demonstrated to be useful in both plants and animals. SpeciesTree is totally free and open source to the public. 

## Features

1. **Easy-to-use**. The procedures and requirements is listed below. Compared to other available tools, SpeciesTree is rather easy and useful for both animal scientists and plant biologists.
2. **Robust**. We have tested SpeciesTree using both data from animals and plants. SpeciesTree is useful for small number of species and for more than one hundred species. 
3. **The process of tree construction is highly automated**. Users just need to input the **CDS and protein files** from multiple species, and the output files were: a table of single-copy nulear genes, two tree files in newick format (one based on coalescent method, the other one based on supermatrix method), two PDF and two png files of species trees.

## Dependencies

Following are a list of third-party programs that will be used in **SpeciesTree** pipeline. These **dependencies** are required to be installed and **added in your PATH** before running this script.

- [OrthoFinder v2.0.0+](https://github.com/davidemms/OrthoFinder/releases/)
- [MCL](https://www.micans.org/mcl/)
- [BLAST+](ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/)
- [Diamond](https://github.com/bbuchfink/diamond/)
- [MAFFT](https://mafft.cbrc.jp/alignment/software/)
- [MUSCLE](http://www.drive5.com/muscle/)
- [trimAl](http://trimal.cgenomics.org/)
- [RAxML](https://cme.h-its.org/exelixis/web/software/raxml/index.html)
- [Python2.7+](https://www.python.org/)
- [ggtree](https://www.bioconductor.org/packages/release/bioc/html/ggtree.html)

## Installation

1. Download and install the dependencies

   ```shell
   # OrthoFinder installing
   $ wget https://github.com/davidemms/OrthoFinder/releases/download/v2.2.7/OrthoFinder-2.2.7.tar.gz
   $ tar xzvf OrthoFinder-2.2.7.tar.gz
   $ export PATH=$PATH:/your/path/to/orthofinder
   
   # MCL installing
   $ sudo apt-get install mcl
   
   # BLAST+ installing
   $ sudo apt-get install ncbi-blast+
   
   # Diamond installing
   $ wget https://github.com/bbuchfink/diamond/releases/download/v0.9.22/diamond-linux64.tar.gz
   $ tar xzf diamond-linux64.tar.gz
   $ export PATH=$PATH:/your/path/to/diamond
   
   # MAFFT installing
   $ wget https://mafft.cbrc.jp/alignment/software/mafft-7.407-without-extensions-src.tgz
   $ tar xzvf mafft-7.407-without-extensions-src.tgz
   $ cd mafft-7.407-without-extensions-src/core/
   $ make
   $ export PATH=$PATH:/your/path/to/mafft
   
   # MUSCLE installing
   $ wget http://www.drive5.com/muscle/downloads3.8.31/muscle3.8.31_i86linux64.tar.gz
   $ tar xzvf muscle3.8.31_i86linux64.tar.gz
   $ mv muscle3.8.31_i86linux64 muscle
   $ export PATH=$PATH:/your/path/to/muscle
   
   # trimAl installing
   $ wget https://github.com/scapella/trimal/archive/trimAl.zip
   $ unzip trimAl.zip && cd trimal-trimAl/source/
   $ make
   $ export PATH=$PATH:/your/path/to/trimal
   
   # RAxML installing
   $ wget https://github.com/stamatak/standard-RAxML/archive/master.zip
   $ unzip master.zip && cd standard-RAxML-master/
   $ make -f Makefile.PTHREADS.gcc && rm *.o
   $ export PATH=$PATH:/your/path/to/raxmlHPC-PTHREADS
   
   # ggtree installing
   # To install this package, start R (version "3.5") and enter:
   $ if (!requireNamespace("BiocManager", quietly = TRUE))
   $ 	install.packages("BiocManager")
   $ BiocManager::install("ggtree", version = "3.8")
   ```

2. Download and install the SpeciesTree

   ```shell
   $ cd ~/biosoft/ # or any directory of your choice
   $ git clone https://github.com/Davey1220/SpeciesTree.git
   $ cd SpeciesTree/
   # Setup the SpeciesTree 
   # Check dependencies and configure SpeciesTree
   $ bash setup.sh 
   $ ~/biosoft/SpeciesTree/SpeciesTree.sh -h
   Usage:
   SpeciesTree.sh -p pep_file_dir -n cds_file_dir 
   [-S search_Program (diamond)] [-A msa_Program (mafft)]
   [-t num_Threads (16)] [-b num_Bootstraps (100)] 
   [-m aa_SubstitutionModel (PROTGAMMAJTT)] 
   [-M nucl_SubstitutionModel (GTRGAMMA)]
   [-o outGroupName1[,outGroupName2[,...]]] [-h]
   ----------------------------------------------------------------------------------------------
   Filename:    SpeciesTree.sh
   Revision:    v1.0
   Date:        2018/10/24
   Author:      Wei Dong
   Email:       1369852697@qq.com
   GitHub:      https://github.com/Davey1220/
   Description: This script was designed to construct species tree 
   ----------------------------------------------------------------------------------------------
   Version v1.0 2018/10/24
   
   Options:
       -p: Offer protein files with the fasta format in pep_file_dir. (required)
       -n: Offer cds files with the fasta format in cds_file_dir. (required)
       -S: Use search_program for alignment search. [Options: diamond, blast, default is diamond]
       -A: Perform multiple sequences alignment. [Options: mafft, muscle, default is mafft]
       -t: Set the number of threads. [Default is 16]
       -b: Perform multiple bootstrap analysis. [Default is 100]
       -m: Set the model of amino acid substitution. [Default is PROTGAMMAJTT]
       -M: Set the model of nucleotide substitution. [Default is GTRGAMMA]
       -o: Specify the name of a single outgroup or a comma-separated list of outgroups, eg "-o Rat" or "-o Rat,Mouse".
       -h/?: Show this help message and exit.
   
   Example:
       SpeciesTree.sh -p test_pep/ -n test_cds/ -S diamond -A mafft -t 20 -b 100 -m PROTGAMMAJTT -M GTRGAMMA -o speciesA
   ```

## Running

```shell
$ curl -O http://112.74.50.115/Example.tar.gz

$ tar xzvf Example.tar.gz

$ ~/biosoft/SpeciesTree/SpeciesTree.sh -p Example/pep/ -n Example/cds/ -S diamond -A mafft -t 20 -b 100 -M PROTGAMMAJTT -m GTRGAMMA
```

## Homepage

<http://www.eplant.org/speciestree.html>

## Contact

Mr. Wei Dong, 1369852697@qq.com 

Dr. Fei Chen, bioinforchen@163.com
