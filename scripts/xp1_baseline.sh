#!/bin/sh

INPUT_FILE=experiment/input/xp1_baseline.csv
JOB_NAME=xp1_baseline
OUTPUT_DIR=experiment/output/xp1_baseline

./scripts/run.sh $INPUT_FILE --job-name $JOB_NAME --site $1 --cluster $2 --start-index $3 --walltime $4 --output $OUTPUT_DIR --log log

if [ -d $OUTPUT_DIR ]
then
  ./scripts/tidy.sh $OUTPUT_DIR --archive
else
  echo "Error: $OUTPUT_DIR does not exist."
fi
