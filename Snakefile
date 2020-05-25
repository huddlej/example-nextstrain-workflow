"""
Run Nextstrain builds for SARS-CoV-2 starting with curated sequences.fasta and metadata.tsv files.
"""

rule all:
    input: "auspice/global.json"

rule filter:
    message: "Filter sequences and metadata to keep high quality sequences."
    input:
        sequences = "data/sequences.fasta",
        metadata = "data/metadata.tsv"
    output:
        sequences = "results/filtered.fasta"
    shell:
        """
        augur filter \
              --sequences {input.sequences} \
              --metadata {input.metadata} \
              --min-length 25000 \
              --group-by region year month \
              --sequences-per-group 10 \
              --output {output.sequences}
        """

rule align:
    message: "Align sequences."
    input:
        sequences = "results/filtered.fasta",
        reference = "config/reference.gb"
    output:
        alignment = "results/aligned.fasta"
    shell:
        """
        augur align \
              --sequences {input.sequences} \
              --nthreads 4 \
              --reference-sequence {input.reference} \
              --remove-reference \
              --fill-gaps \
              --output {output.alignment}
        """

rule tree:
    message: "Infer a tree."
    input:
        alignment = "results/aligned.fasta"
    output:
        tree = "results/tree_raw.nwk"
    shell:
        """
        augur tree \
              --alignment {input.alignment} \
              --nthreads 4 \
              --output {output.tree}
        """

rule refine:
    message: "Build a time tree."
    input:
        alignment = "results/aligned.fasta",
        tree = "results/tree_raw.nwk",
        metadata = "data/metadata.tsv"
    output:
        tree = "results/tree.nwk",
        node_data = "results/branch_lengths.json"
    shell:
        """
        augur refine \
              --alignment {input.alignment} \
              --tree {input.tree} \
              --metadata {input.metadata} \
              --timetree \
              --output-node-data {output.node_data} \
              --output-tree {output.tree}
        """

rule export:
    message: "Export tree to view with auspice."
    input:
        tree = "results/tree.nwk",
        metadata = "data/metadata.tsv",
        node_data = "results/branch_lengths.json"
    output:
        tree = "auspice/global.json"
    shell:
        """
        augur export v2 \
              --tree {input.tree} \
              --metadata {input.metadata} \
              --node-data {input.node_data} \
              --output {output.tree}
        """
