"""
Run Nextstrain builds for SARS-CoV-2 starting with curated sequences.fasta and metadata.tsv files.
"""
configfile: "config/config.yaml"

rule all:
    input:
        expand("auspice/{region}.json", region=config["regions"])

include: "rules/common.smk"

rule filter:
    message: "Filter sequences and metadata to keep high quality sequences."
    input:
        sequences = "data/sequences.fasta",
        metadata = "data/metadata.tsv"
    output:
        sequences = "results/{region}/filtered.fasta"
    log:
        "logs/filter_{region}.txt"
    conda:
        "envs/nextstrain.yaml"
    params:
        min_length = config["min_length"],
        group_by = config["group_by"],
        sequences_per_group = config["sequences_per_group"],
        query_argument = _get_query_argument_by_wildcards
    shell:
        """
        augur filter \
              --sequences {input.sequences} \
              --metadata {input.metadata} \
              --min-length {params.min_length} \
              {params.query_argument} \
              --group-by {params.group_by} \
              --sequences-per-group {params.sequences_per_group} \
              --output {output.sequences} &> {log}
        """

rule align:
    message: "Align sequences."
    input:
        sequences = "results/{region}/filtered.fasta",
        reference = "config/reference.gb"
    output:
        alignment = "results/{region}/aligned.fasta"
    log:
        "logs/align_{region}.txt"
    conda:
        "envs/nextstrain.yaml"
    threads: 4
    shell:
        """
        augur align \
              --sequences {input.sequences} \
              --nthreads {threads} \
              --reference-sequence {input.reference} \
              --remove-reference \
              --fill-gaps \
              --output {output.alignment} &> {log}
        """

rule tree:
    message: "Infer a tree."
    input:
        alignment = "results/{region}/aligned.fasta"
    output:
        tree = "results/{region}/tree_raw.nwk"
    log:
        "logs/tree_{region}.txt"
    conda:
        "envs/nextstrain.yaml"
    threads: 4
    shell:
        """
        augur tree \
              --alignment {input.alignment} \
              --nthreads {threads} \
              --output {output.tree} &> {log}
        """

rule refine:
    message: "Build a time tree."
    input:
        alignment = "results/{region}/aligned.fasta",
        tree = "results/{region}/tree_raw.nwk",
        metadata = "data/metadata.tsv"
    output:
        tree = "results/{region}/tree.nwk",
        node_data = "results/{region}/branch_lengths.json"
    log:
        "logs/refine_{region}.txt"
    conda:
        "envs/nextstrain.yaml"
    shell:
        """
        augur refine \
              --alignment {input.alignment} \
              --tree {input.tree} \
              --metadata {input.metadata} \
              --timetree \
              --output-node-data {output.node_data} \
              --output-tree {output.tree} &> {log}
        """

rule export:
    message: "Export tree to view with auspice."
    input:
        tree = "results/{region}/tree.nwk",
        metadata = "data/metadata.tsv",
        node_data = "results/{region}/branch_lengths.json"
    output:
        tree = "auspice/{region}.json"
    log:
        "logs/export_{region}.txt"
    conda:
        "envs/nextstrain.yaml"
    shell:
        """
        augur export v2 \
              --tree {input.tree} \
              --metadata {input.metadata} \
              --node-data {input.node_data} \
              --output {output.tree} &> {log}
        """
