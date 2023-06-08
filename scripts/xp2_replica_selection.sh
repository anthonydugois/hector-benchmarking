#!/bin/sh

INPUT_FILE=experiment/input/xp2_replica_selection.csv
JOB_NAME=xp2_replica_selection
OUTPUT_DIR=experiment/output/xp2_replica_selection

./scripts/run.sh $INPUT_FILE --job-name $JOB_NAME --site $1 --cluster $2 --start-index $3 --walltime $4 --output $OUTPUT_DIR --log log

if [ -d $OUTPUT_DIR ]
then
  ./scripts/tidy.sh $OUTPUT_DIR --archive
else
  echo "Error: $OUTPUT_DIR does not exist."
fi
