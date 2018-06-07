#!/bin/bash
# The exit status of a Slurm job may not actually match Snakemakes expectation in terms of a
# successfully completed job. For instance, if a Slurm job exceeds it's allocated time, Slurm
# will go about cancelling the job. If Slurm is successful in cancelling the job, the exit
# status will be zero, even if the job was not successfully completed. As such, for Snakemake
# to correctly identify if a job was completed successfully, this script will query Slurm by
# job ID and return "running", "success" or "failed" depending on the Slurm status of that job.
#
# Snakemake can then use this script to determine if a job is still running, completed
# successfully or failed.

JOBID="${1}"

STATE=$(sacct --format state --parsable2 --jobs "${JOBID}" | tail -n1)

case "${STATE}" in
  *RUNNING*|*PENDING*|*SUSPENDED*|*COMPLETING*|*CONFIGURING* )
    echo running
    exit 0
    ;;
  *COMPLETED* )
    echo success
    exit 0
    ;;
  *BOOT_FAIL*|*CANCELLED*|*FAILED*|*NODE_FAIL*|*PREEMPTED*|*SPECIAL_EXIT*|*STOPPED*|*TIMEOUT* )
    echo failed
    exit 0
    ;;
  * )
    # Slurm's sacct didn't return a state we understand
    echo unknown
    exit 1
    ;;
esac

exit 1
