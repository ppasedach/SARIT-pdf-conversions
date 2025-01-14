#!/usr/bin/env bash

# see http://www.davidpashley.com/articles/writing-robust-shell-scripts/#id2382181
set -o errexit # exit on error 
set -o nounset # don't allow uninitalized vars

BASEDIR=$(realpath $(dirname ${0})"/../")
CONVERSIONSCRIPT=$(realpath ${BASEDIR}"/bin/convert_sarit_to_tex.sh")
COMPILETEXSCRIPT=$(realpath ${BASEDIR}"/bin/compile_xetex.sh")

CORPUS=${1:-}

if [ -z "${CORPUS}" ]
    then
    echo "Please specify name of corpus file (usually SARIT-corpus/saritcorpus.xml)."
    exit 1
fi

STARTDIR=$(pwd)
CORPUS=$(realpath ${CORPUS})
XDIR=$(dirname ${CORPUS})
OUTDIR=$(mktemp --tmpdir -d "pdf-conv-XXXX")
LOGFILE=$(realpath $OUTDIR"/pdf-conversion.log")

function cleanup {
    cd $STARTDIR
    echo "Results are in ${OUTDIR}."
    echo "Logfile is in ${LOGFILE}"
}
trap cleanup EXIT

cd $XDIR

echo "Logging to ${LOGFILE}"

xmlstarlet sel -N xi='http://www.w3.org/2001/XInclude' -t -v '//xi:include/@href'  ${CORPUS} | \
    parallel --bar --jobs 0.5% $CONVERSIONSCRIPT {} ${OUTDIR} 1> ${LOGFILE} 2>&1


cd ${OUTDIR}

ls *tex | parallel --bar --jobs 0.5% ${COMPILETEXSCRIPT} {} 


# for i in `ls *tex`
# do
#     xelatex -shell-escape -no-pdf -etex -interaction=nonstopmode ${i}
#     biber --nodieonerror --onlylog `basename ${i} .tex`
#     xelatex -shell-escape -no-pdf -etex -interaction=nonstopmode ${i}
#     biber --nodieonerror --onlylog `basename ${i} .tex`
#     xelatex -shell-escape -etex -interaction=nonstopmode ${i}
# done

# or this, but loses logs:
# parallel --bar --jobs 0.5% $CONVERSIONSCRIPT {} ${OUTDIR} 2> >(zenity --progress --auto-kill)

