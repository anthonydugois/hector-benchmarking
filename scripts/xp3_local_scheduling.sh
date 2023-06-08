#!/bin/sh

INPUT_FILE=experiment/input/xp3_local_scheduling.csv
JOB_NAME=xp3_local_scheduling
OUTPUT_DIR=experiment/output/xp3_local_scheduling

./scripts/run.sh $INPUT_FILE --job-name $JOB_NAME --site $1 --cluster $2 --start-index $3 --walltime $4 --output $OUTPUT_DIR --log log

if [ -d $OUTPUT_DIR ]
then
  ./scripts/tidy.sh $OUTPUT_DIR --archive
else
  echo "Error: $OUTPUT_DIR does not exist."
fi
