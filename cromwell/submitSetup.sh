#!/bin/bash

echo "Prepare your environment to submit workflow runs to Cromwell"

cp /data/nobackup/pipelines/.ssh_cromwell_rsa ~/cromwell/
chmod 600 ~/cromwell/.ssh_cromwell_rsa
module purge
module load modules modules-init modules-gs
module load python/3.6.5
source /net/maccoss/vol1/maccoss_shared/bdconnol/pipelines/MsconvertWorkflow/.venv/workflow/bin/activate
