#!/bin/sh

INPUT_FILE=/usr/src/app/experiment/input/helloworld.csv
JOB_NAME=helloworld
OUTPUT_DIR=/usr/src/app/experiment/output/helloworld

./scripts/run.sh $INPUT_FILE --job-name $JOB_NAME --site $1 --cluster $2 --start-index $3 --walltime $4 --output $OUTPUT_DIR --log log

./scripts/tidy.sh $OUTPUT_DIR --archive
