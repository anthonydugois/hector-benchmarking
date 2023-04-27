#!/bin/sh

INPUT_FILE=experiment/input/helloworld.csv
JOB_NAME=helloworld
OUTPUT_DIR=experiment/output/helloworld

./scripts/run.sh $INPUT_FILE --job-name $JOB_NAME --site $1 --cluster $2 --start-index $3 --walltime $4 --output $OUTPUT_DIR --log log

if [ -d $OUTPUT_DIR ]
then
  ./scripts/tidy.sh $OUTPUT_DIR --archive
else
  echo "Error: $OUTPUT_DIR does not exist."
fi
