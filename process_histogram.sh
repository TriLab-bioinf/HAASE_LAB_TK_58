#!/bin/bash

#########################################################
# process_histogram <genome faste> <hist file> <> strand [any,-,+]
#
#########################################################

GENOME=$1
HISTFILE=$2
STRAND=$3

# Get sample name
HISTFILE_NAME=$(basename ${HISTFILE})
SAMPLE=${HISTFILE_NAME%.step3.R1.hist}

echo
echo Processing sample ${SAMPLE}
echo GENOME = ${GENOME}
echo HISTOGRAM FILE = ${HISTFILE}
echo STRAND = ${STRAND}

# Calculate histogram of coverage frequency
echo
echo Calculate overall frequency stats
grep -v '^#' ${HISTFILE} | cut -f 4 | sort | uniq -c | sort -k2n > ${SAMPLE}.IS_frequency.stats

# Get fasta sequences 
echo
echo Fetching fasta sequences:
for i in {1..15}; do
    echo Coverage = ${i}
    ./filter_histogram.pl -i ${HISTFILE} -c ${i} -m ${i} -s ${STRAND} > ${SAMPLE}.step3.R1.cov.${i}.hist
    seqtk subseq ${GENOME} ${SAMPLE}.step3.R1.cov.${i}.hist >  ${SAMPLE}.step3.R1.cov.${i}.IS_flank.fasta
done

# Histogram for coverage >= 16
echo 'Coverage >= 16'
./filter_histogram.pl -i ${HISTFILE} -c 16 -s ${STRAND} > ${SAMPLE}.step3.R1.cov.16.hist
seqtk subseq ../human_GRCh38.fasta ${SAMPLE}.step3.R1.cov.16.hist >  ${SAMPLE}.step3.R1.cov.16.IS_flank.fasta

echo
echo Calculating TTAA proportion at insertion sites:

# Analyze insertion sites
echo "COVERAGE\tTTAA\tNON_TTAA" > ${SAMPLE}.ttaa_counts.txt
for i in {1..16}; do
    COV=${i}
    TTAA=$(grep -v '>' ${SAMPLE}.step3.R1.cov.${i}.IS_flank.fasta| perl -ne '$x=substr($_,30,4);print "$x\n"'|grep -c 'TTAA')
    NON_TTAA=$(grep -v '>' ${SAMPLE}.step3.R1.cov.${i}.IS_flank.fasta| perl -ne '$x=substr($_,30,4);print "$x\n"'|grep -cv 'TTAA')
    if [[ ${TTAA} > 0 && ${NON_TTAA} > 0 ]]; then 
        RATIO=$(printf %.2f "$((10**4 * ${TTAA}/( ${NON_TTAA} + ${TTAA} ) ))e-4")
    else
        RATIO=0
    fi
    echo "${COV}    ${TTAA} ${NON_TTAA} ${RATIO}"

    cat ${SAMPLE}.step3.R1.cov.${i}.IS_flank.fasta >> ${SAMPLE}.step3.R1.IS_flank.fasta
done >> ${SAMPLE}.ttaa_counts.txt

# Generate DNA logo figure
echo
echo Generating Logo plots:

for i in {1..16}; do
    echo ${i} 
    weblogo --format png_print \
    --errorbars False \
    -o ${SAMPLE}.logo.cov.${i}.png \
    --sequence-type dna \
    --datatype fasta \
    -c classic \
    -n 80 < ${SAMPLE}.step3.R1.cov.${i}.IS_flank.fasta
done

# Run weblogo for all the insertions
weblogo --format png_print \
    --errorbars False \
    -o ${SAMPLE}.logo.png \
    --sequence-type dna \
    --datatype fasta \
    -c classic \
    -n 80 < ${SAMPLE}.step3.R1.IS_flank.fasta

echo
echo Done !
echo




