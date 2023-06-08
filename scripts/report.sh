#!/bin/sh

TEX_DIR=tex
PDF_DIR=report

DATA_DIR=archives
PLOT_DIR=plots
TEXPLOT_DIR=tex

mkdir -p $TEXPLOT_DIR

Rscript $PLOT_DIR/xp1_baseline.R $TEXPLOT_DIR $DATA_DIR xp1_baseline-light
Rscript $PLOT_DIR/xp2_replica_selection.R $TEXPLOT_DIR $DATA_DIR xp2_replica_selection-light
Rscript $PLOT_DIR/xp3_local_scheduling.R $TEXPLOT_DIR $DATA_DIR xp3_local_scheduling-light

mkdir -p PDF_DIR

latexmk -pdf -outdir=$PDF_DIR $TEX_DIR/report.tex
