#!/bin/bash
set -e
set -u

VERSION="v1.0"

# Function for script description and usage
usage()
{
cat <<EOF >&2
Usage:
SpeciesTree.sh -p pep_file_dir -n cds_file_dir 
[-S search_Program (diamond)] [-A msa_Program (mafft)]
[-t num_Threads (16)] [-b num_Bootstraps (100)] 
[-m aa_SubstitutionModel (PROTGAMMAJTT)] 
[-M nucl_SubstitutionModel (GTRGAMMA)]
[-o outGroupName1[,outGroupName2[,...]]] [-h]
---------------------------------------------------------------------------------------------------
Filename:    SpeciesTree.sh
Revision:    v1.0
Date:        2018/10/24
Author:      Wei Dong
Email:       1369852697@qq.com
GitHub:      https://github.com/Davey1220/
Description: This script was designed to construct species tree 
---------------------------------------------------------------------------------------------------
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
EOF
}

## Initialize variables
# BASE_DIR=$(dirname $(readlink -f "$0")) # readlink in Mac OS X does not support the '-f' option
BASE_DIR=$(cd "$(dirname "$0")" && pwd)
SRC_DIR="${BASE_DIR}/src"

source "${BASE_DIR}/SpeciesTree.cfg"

pep_file_dir="" # protein file path
cds_file_dir="" # cds file path
# default parameters
search_program="diamond"
msa_program="mafft"
aa_model="PROTGAMMAJTT" 
nucl_model="GTRGAMMA"
num_threads=16
num_bootstraps=100
outgroup=""

# Parse positional parameters
while getopts "p:n:S:A:t:b:m:M:o:h" OPTION
do
    case ${OPTION} in
        'p')
            pep_file_dir=${OPTARG}
            ;;
        'n')
            cds_file_dir=${OPTARG}
            ;;
        'S')
            search_program=${OPTARG}
            ;;
        'A')
            msa_program=${OPTARG}
            ;;
        't')
            num_threads=${OPTARG}
            ;;
        'b')
            num_bootstraps=${OPTARG}
            ;;
        'm')
            aa_model=${OPTARG}
            ;;
        'M')
            nucl_model=${OPTARG}
            ;;
        'o')
            outgroup=${OPTARG}
            ;;
        'h')
            usage
            exit 0
            ;;
        '?')
            usage
            exit 1
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

## Main processes
if [ $# -eq 0 ];then
    usage
    exit 1
fi

if [ -z "${pep_file_dir}${cds_file_dir}" ]
then 
    usage
    exit 1
fi

## Running this pipeline
echo "#############################################################################################"
echo "#####             Step_1: Perform full OrthoFinder analysis for the proteins            #####"
echo "#############################################################################################"
if [ ! -z "${pep_file_dir}${cds_file_dir}" ]
then
    if [ ! -d "${pep_file_dir}" -o ! -d "${cds_file_dir}" ]
    then
        usage
        echo "** [ERROR]: Protein fasta dir(${pep_file_dir}) or CDS fasta dir(${cds_file_dir}) was not found!"
        echo "Please provide the protein and cds fasta dir and restart this script."
        exit 1
    else
        # modify protein and cds sequecne name
        for i in `ls ${BASE_DIR}/${pep_file_dir}/*fa*`
        do
            seqname=`basename ${i%%.*}`
            sed -i "s#>#>${seqname}|#g" $i
        done
        for i in `ls ${BASE_DIR}/${cds_file_dir}/*fa*`
        do
            seqname=`basename ${i%%.*}`
            sed -i "s#>#>${seqname}|#g" $i
        done
        echo "Start to perform OrthoFinder analysis."
        if [ ${search_program} != "diamond" ]
        then
            ${OrthoFinder} -f "${pep_file_dir}" -S blast -t "${num_threads}" -og
        else
            ${OrthoFinder} -f "${pep_file_dir}" -S diamond -t "${num_threads}" -og
        [ $? != 0 ] && exit 1
        echo "OrthoFinder analysis was finished successfully!"
        fi
    fi
else
    usage
    echo "Protein fasta dir(${pep_file_dir}) and CDS fasta dir(${cds_file_dir}) were both required!"
    exit 1
fi
echo

echo "#############################################################################################"
echo "#####                  Step_2: Extract SingleCopyOrthogroups sequences                  #####"
echo "#############################################################################################"
RES_DIR="${BASE_DIR}/${pep_file_dir}/Results*"
rm -rf ${RES_DIR}/WorkingDirectory
OG_file="${RES_DIR}/Orthogroups.csv"
SingleCopyOG_file="${RES_DIR}/SingleCopyOrthogroups.txt"
# extract SingleCopyOrthogroups
head -n1 ${OG_file} >SingleCopyOG.txt
cat ${SingleCopyOG_file}|while read line
do 
    grep $line ${OG_file} >>SingleCopyOG.xlsx
done

# merge all pep file and make index
cat ${BASE_DIR}/${pep_file_dir}/*.fa* >allpep.fas
makeblastdb -in allpep.fas -dbtype prot -parse_seqids
[ $? != 0 ] && exit 1
# merge all cds file and make index
cat ${BASE_DIR}/${cds_file_dir}/*.fa* >allcds.fas
makeblastdb -in allcds.fas -dbtype nucl -parse_seqids
[ $? != 0 ] && exit 1

[ -d SingleCopyOG ] && rm -rf SingleCopyOG
echo "Start to extract all SingleCopyOrthogroups sequences."
# extract SingleCopyOG protein sequences
mkdir -p SingleCopyOG/pep/ && cd SingleCopyOG/pep/
# get each SingleCopyOG gene name
cat ${BASE_DIR}/SingleCopyOG.txt|sed '1d'|while read line
do 
    OG_name=`echo $line|awk '{print $1}'` 
    echo $line|sed 's/\s/\n/g'|sed '1d' >${OG_name}.id.txt
done
# get sequences of each single-copy gene 
for i in `ls *id.txt`
do 
    blastdbcmd -db ${BASE_DIR}/allpep.fas -entry_batch $i |sed 's/>lcl|/>/g' >${i%%.id.txt}.fas
done
rm *id.txt
# filter each SingleCopyOG with more than two protein's length less than 50 aa
ls *fas|while read line
do
    ${PYTHON} ${SRC_DIR}/filter_seq_by_length.py $line 50 >tmp
    flag=`cat tmp`
    [ $flag -eq 0 ] && rm $line && echo "$line was removed!"
    rm tmp
done
cd ${BASE_DIR}
# extract SingleCopyOG cds sequences
mkdir -p SingleCopyOG/cds/ && cd SingleCopyOG/cds/
for i in `ls ${BASE_DIR}/SingleCopyOG/pep/*fas`
do
    seqname=`basename ${i%%.*}`
    grep ">" $i | sed 's/>//g' >${seqname}.id.txt
    blastdbcmd -db ${BASE_DIR}/allcds.fas -entry_batch ${seqname}.id.txt |sed 's/>lcl|/>/g' >${seqname}.fas
done
rm *id.txt
# rename all single-copy gene
ls *fas|while read line
do 
    sed 's/|.*$//g' $line >${line%%.fas}.rename.fas
    rm $line
done 
for i in `ls ${BASE_DIR}/SingleCopyOG/pep/*fas`
do
    sed 's/|.*$//g' $i >${i%%.fas}.rename.fas
    rm $i
done
cd ${BASE_DIR}
# remove intermediate file
rm allpep*
rm allcds*
echo "All SingleCopyOrthogroups were extracted done!"
echo

echo "#############################################################################################"
echo "#####    Step_3: Perform multiple sequences alignment and trim the aligned sequences    #####"
echo "#############################################################################################"
[ -d SingleCopyOG_MSA ] && rm -rf SingleCopyOG_MSA
echo "Start to perform multiple sequences alignment and trim the aligned sequences."
mkdir -p SingleCopyOG_MSA/pep/ && cd SingleCopyOG_MSA/pep/
# multiple sequences alignment for proteins
for i in `ls ${BASE_DIR}/SingleCopyOG/pep/*fas`
do
    seq=`basename $i`
    if [ ${msa_program} != "mafft" ]
    then
        ${MUSCLE} -in $i -out ${seq%%.fas}_aln.fas 2>/dev/null
    else
        ${MAFFT} --thread 10 $i >${seq%%.fas}_aln.fas 2>/dev/null
    fi
done
# trim the aligned file
for i in `ls *aln.fas`
do 
    ${TRIMAL} -in $i -out ${i%%.fas}_trimmed.fas -automated1
done
rm *aln.fas
## merge all trimmed single-copy gene into one super-gene matrix
${PERL} ${FASconCAT} -s
[ $? != 0 ] && exit 1
cd ${BASE_DIR}

mkdir -p SingleCopyOG_MSA/cds/ && cd SingleCopyOG_MSA/cds/
# multiple sequences alignment for cds
for i in `ls ${BASE_DIR}/SingleCopyOG/cds/*fas`
do
    seq=`basename $i`
    if [ ${msa_program} != "mafft" ]
    then
        ${MUSCLE} -in $i -out ${seq%%.fas}_aln.fas 2>/dev/null
    else
        ${MAFFT} --thread 10 $i >${seq%%.fas}_aln.fas 2>/dev/null
    fi
done
# trim the aligned file
for i in `ls *aln.fas`
do 
    ${TRIMAL} -in $i -out ${i%%.fas}_trimmed.fas -automated1
done
rm *aln.fas
## merge all trimmed single-copy gene into one super-gene matrix
${PERL} ${FASconCAT} -s
[ $? != 0 ] && exit 1
cd ${BASE_DIR}
echo "Multiple sequences alignment was finished!"
echo

echo "#############################################################################################"
echo "#####         Step_4: Construct the ML species tree with the concatenate methold        #####"
echo "#############################################################################################"
[ -d Concatenation ] && rm -rf Concatenation
echo "Start to construct the ML species tree with concatenate methold."
# make ML tree for proteins
mkdir -p Concatenation/pep/ && cd Concatenation/pep/
# construct ML tree for the super-gene
if [ -z "${outgroup}" ]
then
	${RAxML} -T ${num_threads} -f a -N ${num_bootstraps} -m ${aa_model} -x 123456 -p 123456 -s ${BASE_DIR}/SingleCopyOG_MSA/pep/FcC_smatrix.fas -n concatenation_out.nwk
else
	${RAxML} -T ${num_threads} -f a -N ${num_bootstraps} -m ${aa_model} -x 123456 -p 123456 -s ${BASE_DIR}/SingleCopyOG_MSA/pep/FcC_smatrix.fas -o ${outgroup} -n concatenation_out.nwk
fi
[ $? != 0 ] && exit 1
cd ${BASE_DIR}
# make ML tree for cds
mkdir -p Concatenation/cds/ && cd Concatenation/cds/
# construct ML tree for the super-gene
if [ -z "${outgroup}" ]
then
	${RAxML} -T ${num_threads} -f a -N ${num_bootstraps} -m ${nucl_model} -x 123456 -p 123456 -s ${BASE_DIR}/SingleCopyOG_MSA/cds/FcC_smatrix.fas -n concatenation_out.nwk
else
	${RAxML} -T ${num_threads} -f a -N ${num_bootstraps} -m ${nucl_model} -x 123456 -p 123456 -s ${BASE_DIR}/SingleCopyOG_MSA/cds/FcC_smatrix.fas -o ${outgroup} -n concatenation_out.nwk
fi
[ $? != 0 ] && exit 1
cd ${BASE_DIR}
echo "The ML species tree with the concatenate methold was finished!"
echo 

echo "#############################################################################################"
echo "#####        Step_5: Construct the ML species tree with the coalescent methold          #####"
echo "#############################################################################################"
[ -d Coalescence ] && rm -rf Coalescence
echo "Start to construct the ML species tree with the coalescent methold."
# make ML tree for proteins
mkdir -p Coalescence/pep/ && cd Coalescence/pep/
# construct ML tree for every single-copy gene
for i in `ls ${BASE_DIR}/SingleCopyOG_MSA/pep/*trimmed.fas`
do 
    out_tree_file=`basename $i|cut -d"_" -f1`_out.nwk
    if [ -z "${outgroup}" ]
    then
    	${RAxML} -T ${num_threads} -f a -N ${num_bootstraps} -m ${aa_model} -x 123456 -p 123456 -s $i -n ${out_tree_file} >/dev/null
    else
    	${RAxML} -T ${num_threads} -f a -N ${num_bootstraps} -m ${aa_model} -x 123456 -p 123456 -s $i -o ${outgroup} -n ${out_tree_file} >/dev/null
    fi
    cat RAxML_bipartitions.${out_tree_file} >>allSingleGenes_tree.nwk 
    echo ./RAxML_bootstrap.${out_tree_file} >>allSingleGenes_bootstrap.txt
done
# construct the ASTRAL tree
${JAVA} -jar ${ASTRAL} -i allSingleGenes_tree.nwk -b allSingleGenes_bootstrap.txt -r ${num_bootstraps} -o Astral.coalescent_out.result
[ $? != 0 ] && exit 1
tail -n 1 Astral.coalescent_out.result >Astral.coalescence_tree.nwk
cd ${BASE_DIR}
# make ML tree for cds
mkdir -p Coalescence/cds/ && cd Coalescence/cds/
# construct ML tree for every single-copy gene
for i in `ls ${BASE_DIR}/SingleCopyOG_MSA/cds/*trimmed.fas`
do 
    out_tree_file=`basename $i|cut -d"_" -f1`_out.nwk
    if [ -z "${outgroup}" ]
    then
    	${RAxML} -T ${num_threads} -f a -N ${num_bootstraps} -m ${nucl_model} -x 123456 -p 123456 -s $i -n ${out_tree_file} >/dev/null
    else
    	${RAxML} -T ${num_threads} -f a -N ${num_bootstraps} -m ${nucl_model} -x 123456 -p 123456 -s $i -o ${outgroup} -n ${out_tree_file} >/dev/null
    fi
    cat RAxML_bipartitions.${out_tree_file} >>allSingleGenes_tree.nwk 
    echo ./RAxML_bootstrap.${out_tree_file} >>allSingleGenes_bootstrap.txt
done
# construct the ASTRAL tree
${JAVA} -jar ${ASTRAL} -i allSingleGenes_tree.nwk -b allSingleGenes_bootstrap.txt -r ${num_bootstraps} -o Astral.coalescent_out.result
[ $? != 0 ] && exit 1
tail -n 1 Astral.coalescent_out.result >Astral.coalescence_tree.nwk
cd ${BASE_DIR}
echo "The ML species tree with the coalescent methold was finished!"
echo

echo "#############################################################################################"
echo "#####                     Step_6: Organize the result files                             #####"
echo "#############################################################################################"
[ -d Results ] && rm -rf Results
mkdir Results && cd Results
mv ${RES_DIR} OrthoFinder_Res
mv ${BASE_DIR}/SingleCopyOG.txt ./
mv ${BASE_DIR}/SingleCopyOG/ ./
mv ${BASE_DIR}/SingleCopyOG_MSA/ ./
mv ${BASE_DIR}/Concatenation/ ./
mv ${BASE_DIR}/Coalescence/ ./
cp Concatenation/pep/RAxML_bipartitions.concatenation_out.nwk RAxML_pep.concatenate_tree.nwk
cp Concatenation/cds/RAxML_bipartitions.concatenation_out.nwk RAxML_cds.concatenate_tree.nwk
cp Coalescence/pep/Astral.coalescence_tree.nwk Astral_pep.coalescent_tree.nwk
cp Coalescence/cds/Astral.coalescence_tree.nwk Astral_cds.coalescent_tree.nwk
# tree visualization
${R} --slave --vanilla --file="${SRC_DIR}/tree_visualization.R" >/dev/null
[ $? != 0 ] && exit 1
cd ${BASE_DIR}
echo
echo "#############################################################################################"
echo "Congratulations, all tasks were finished successfully, run SpeciesTree pipeline was done... "
echo "The tree file (RAxML_xx.concatenate_tree.nwk and Astral_xx.coalescent_tree.nwk) and the image (RAxML_xx.concatenate_tree.pdf and Astral_xx.coalescent_tree.png) were generated in the Results directory!"
echo "For better visualize the species tree, you can see the tree file by a program such as MEGA7 (http://www.megasoftware.net/), FigTree (http://tree.bio.ed.ac.uk/software/figtree/) and Newick utilities (http://cegg.unige.ch/newick_utils)."
echo "#############################################################################################"
