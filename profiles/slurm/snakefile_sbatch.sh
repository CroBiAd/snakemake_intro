#!/bin/bash
# This script is supposed to intercept and preprocess a small number of command line arguments
# before passing the remaining arguments to Slurm's sbatch command. The primary goal is to take
# -d, a space-seperated list of job IDs on which this job is dependant, and reformat it for use
# by Slurm's sbatch. Where -o (output log) or -e (error log) are specified and point to a
# subdirectory, we ensure that subdirectory exists by creating it - otherwise sbatch will fail.
#
# We can only accept short forms of arguments (e.g. -J) and not long forms (e.g. --jobs). This
# is problematic since sbatch has options which only have a long form (e.g. --mem). We have
# fudged this a little by accepting -m and converting it to --mem before passing it onto sbatch.

# Initialize default values for some variables
SBATCH_ARGS=""
DEP_STRING=""

# getopts can only handle short forms of arguments
# We'll just process those sbatch arguments which need some pre-processing
# everything else will get sent straight to sbatch
while getopts ":d:o:e:m:" opt; do
    case "${opt}" in
    d)
        DEPS=${OPTARG}
        ;;
    m)
        # sbatch doesn't have a short form for --mem, so we'll accept -m and change this to --mem for sbatch
        SBATCH_ARGS+=" --mem ${OPTARG}"
        ;;
    o|e)
        FILE=${OPTARG}
        if [[ ${FILE} = *"/"* ]]; then
          # specified output/error (-o or -e) file contains a directory seperator, ensure the dir exists
          mkdir -p "${FILE%/*}"
        fi
        SBATCH_ARGS+=" -${opt} ${OPTARG}"
        ;;
    *)
        # Any other arguments will be passed to sbatch as they are
        SBATCH_ARGS+=" -${OPTARG} ${!OPTIND}"
        OPTIND=$((OPTIND+1))
        ;;
    esac
done
shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift

# If DEPS is non-empty, then construct a Slurm dependancy string that sbatch understands
if [[ ! -z "${DEPS}" ]]; then
  DEP_STRING="--dependency=afterok:${DEPS// /:}"
fi

export DEP_STRING
export SBATCH_ARGS

# need to return just the job ID part to enable snakemake to build dependencies correctly
# $@ will still contain the path of the job execution script when this script is called by Snakemake
sbatch ${DEP_STRING} ${SBATCH_ARGS} $@ | cut -f4 -d' '
