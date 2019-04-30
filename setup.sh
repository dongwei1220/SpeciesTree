#!/bin/bash
set -e
set -u

VERSION="v1.0"

function check_program_path {
    local program_name="${1}"

    while :
    do
        local program_path=""
        echo 1>&2
        read -p "${program_name} is not found. Is the program already installed? [y/N] " -n 1
        if [[ ${REPLY} =~ ^[Yy]$ ]]
        then
            echo 1>&2
            read -p "Please enter the path of ${program_name} program (ex: /home/foo/bin/${program_name}): " program_path
            [ -e "${program_path}" -a -x "${program_path}" ] && break
        else
            break
        fi
    done

    echo "${program_path}"
}

function add_program_path {
    local program_name="${1}"
    local program_path=""
   
    program_path="$(which "${program_name}" 2> /dev/null | tail -n1 | tr -d '\t')" #To remove alias information
    if [ -z "${program_path}" ]
    then
        program_path=$(check_program_path "${program_name}")
    else
        if [ -e "${program_path}" -a -x "${program_path}" ]
        then
            echo 1>&2
            read -p "The detected path of ${program_name} is ${program_path}. Is it correct? [Y/n] " -n 1
            if [[ ${REPLY} =~ ^[Nn]$ ]]
            then
                program_path="$(check_program_path "${program_name}")"
            fi
        else
            program_path="$(check_program_path "${program_name}")"
        fi
    fi

    echo "${program_path}"
}

# Main
# BASE_DIR=$(dirname $(readlink -f "$0")) # readlink in Mac OS X does not support the '-f' option
BASE_DIR=$(cd "$(dirname "$0")" && pwd)

BASH_PATH="$(which bash 2> /dev/null | tail -n1 | tr -d '\t')" #To remove alias information

echo -e "Version: ${VERSION}\n"
echo "START TO SET UP FOR SpeciesTree!!!"

[ -e "${BASE_DIR}/SpeciesTree.cfg" ] && rm -f "${BASE_DIR}/SpeciesTree.cfg"
touch "${BASE_DIR}/SpeciesTree.cfg"

# Check programs
exec 16<> setup.data
while read -u 16 var_name program_name program_url
do
    program_path="$(add_program_path "${program_name}")"
    if [ -z "${program_path}" ]
    then    
        echo -e "\nYou can download ${program_name} at ${program_url}.\nPlease, install the program and restart this script."
        rm -f "${BASE_DIR}/SpeciesTree.cfg"
        exit 1
    else
        echo "${var_name}='${program_path}'" >> "${BASE_DIR}/SpeciesTree.cfg"
    fi
done

# Configure this pipeline
echo
cd ${BASE_DIR}/src
[ -d "${BASE_DIR}/src/FASconCAT-master/" ] && rm -rf "${BASE_DIR}/src/FASconCAT-master/"
[ -d "${BASE_DIR}/src/Astral/" ] && rm -rf "${BASE_DIR}/src/Astral/"
ls *zip|xargs -I {} unzip {} && chmod a+x *.py && chmod a+x *.R
echo "FASconCAT='${BASE_DIR}/src/FASconCAT-master/FASconCAT_v1.11.pl'" >> "${BASE_DIR}/SpeciesTree.cfg"
echo "ASTRAL='${BASE_DIR}/src/Astral/astral.5.6.2.jar'" >> "${BASE_DIR}/SpeciesTree.cfg"
cd ${BASE_DIR}
chmod a+x SpeciesTree.sh

echo
echo "Congratulations, SpeciesTree is installed successfully!!!"

exit 0
