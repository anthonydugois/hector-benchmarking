#!/bin/sh

TEX_DIR=tex
PDF_DIR=report

DATA_DIR=standalone/data
PLOT_DIR=standalone/plots
TEXPLOT_DIR=standalone/tex

mkdir -p $TEXPLOT_DIR

Rscript $PLOT_DIR/xp1_baseline.R $TEXPLOT_DIR $DATA_DIR xp1_baseline.2023-01-24T17:14:14
Rscript $PLOT_DIR/xp1_saturation.R $TEXPLOT_DIR $DATA_DIR xp1_baseline.2023-03-10T19:07:34
Rscript $PLOT_DIR/xp2_saturation.R $TEXPLOT_DIR $DATA_DIR xp2_replica_selection.2023-01-25T17:27:26
Rscript $PLOT_DIR/xp3_rampup.R $TEXPLOT_DIR $DATA_DIR xp3_local_scheduling.2023-04-17T09:50:13

mkdir -p PDF_DIR

latexmk -pdf -outdir=$PDF_DIR $TEX_DIR/quick_report.tex
