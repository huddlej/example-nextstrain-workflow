#!/bin/bash

# Run Nextstrain builds for SARS-CoV-2 starting with curated sequences.fasta and metadata.tsv files.

# Setup output directories.
mkdir -p results auspice

# Filter sequences and metadata to keep high quality sequences.
augur filter \
      --sequences data/sequences.fasta \
      --metadata data/metadata.tsv \
      --min-length 25000 \
      --group-by region year month \
      --sequences-per-group 10 \
      --output results/filtered.fasta

# Align sequences.
augur align \
      --sequences results/filtered.fasta \
      --nthreads 4 \
      --reference-sequence config/reference.gb \
      --remove-reference \
      --fill-gaps \
      --output results/aligned.fasta

# Infer a tree.
augur tree \
      --alignment results/aligned.fasta \
      --nthreads 4 \
      --output results/tree_raw.nwk

# Build a time tree.
augur refine \
      --alignment results/aligned.fasta \
      --tree results/tree_raw.nwk \
      --metadata data/metadata.tsv \
      --timetree \
      --output-node-data results/branch_lengths.json \
      --output-tree results/tree.nwk

# Export tree to view with auspice.
augur export v2 \
      --tree results/tree.nwk \
      --metadata data/metadata.tsv \
      --node-data results/branch_lengths.json \
      --output auspice/global.json
