rule bin_magscot_prodigal_one:
    """Run prodigal over a single assembly"""
    input:
        assembly=ASSEMBLE_RENAME / "{assembly_id}.fa",
    output:
        proteins=MAGSCOT / "{assembly_id}/prodigal.faa",
        genes=MAGSCOT / "{assembly_id}/prodigal.ffn",
    log:
        MAGSCOT / "{assembly_id}/prodigal.log",
    conda:
        "magscot.yml"
    threads: 24
    resources:
        runtime=24 * 60,
        mem_mb=double_ram(8),
    retries: 5
    shell:
        """
        (cat {input.assembly} \
        | parallel \
            --jobs {threads} \
            --block 1M \
            --recstart '>' \
            --pipe \
            prodigal \
                -p meta \
                -a {output.proteins}.{{#}}.faa \
                -d {output.genes}.{{#}}.ffn \
                -o /dev/null \
        ) 2> {log} 1>&2
        cat {output.proteins}.*.faa > {output.proteins} 2>> {log}
        cat {output.genes}.*.ffn > {output.genes} 2>> {log}
        rm -f {output.proteins}.*.faa {output.genes}.*.ffn 2>> {log} 2>&1
        """


rule bin_magscot_hmmsearch_pfam_one:
    """Run hmmsearch over the predicted proteins of an assembly using Pfam as database"""
    input:
        proteins=MAGSCOT / "{assembly_id}/prodigal.faa",
        hmm=features["magscot"]["pfam_hmm"],
    output:
        tblout=MAGSCOT / "{assembly_id}/pfam.tblout",
    log:
        MAGSCOT / "{assembly_id}/pfam.log",
    conda:
        "magscot.yml"
    threads: 4
    resources:
        runtime=24 * 60,
        mem_mb=double_ram(8),
    retries: 5
    shell:
        """
        hmmsearch \
            -o /dev/null \
            --tblout {output.tblout} \
            --noali \
            --notextw \
            --cut_nc \
            --cpu {threads} \
            {input.hmm} \
            {input.proteins} \
        2> {log} 1>&2
        """


rule bin_magscot_hmmsearch_tigr_one:
    """Run hmmsearch over the predicted proteins of an assembly using TIGR as database"""
    input:
        proteins=MAGSCOT / "{assembly_id}/prodigal.faa",
        hmm=features["magscot"]["tigr_hmm"],
    output:
        tblout=MAGSCOT / "{assembly_id}/tigr.tblout",
    log:
        MAGSCOT / "{assembly_id}/tigr.log",
    conda:
        "magscot.yml"
    threads: 4
    resources:
        runtime=24 * 60,
        mem_mb=8 * 1024,
    shell:
        """
        hmmsearch \
            -o /dev/null \
            --tblout {output.tblout} \
            --noali \
            --notextw \
            --cut_nc \
            --cpu {threads} \
            {input.hmm} \
            {input.proteins} \
        2> {log} 1>&2
        """


rule bin_magscot_join_hmm_one:
    """Join the results of hmmsearch over TIGR and Pfam"""
    input:
        tigr_out=MAGSCOT / "{assembly_id}/tigr.tblout",
        pfam_out=MAGSCOT / "{assembly_id}/pfam.tblout",
    output:
        merged=MAGSCOT / "{assembly_id}/hmm.tblout",
    log:
        MAGSCOT / "{assembly_id}/hmm.log",
    conda:
        "magscot.yml"
    shell:
        """
        (grep -v "^#" {input.tigr_out} | awk '{{print $1"\\t"$3"\\t"$5}}' >  {output.merged}) 2>  {log}
        (grep -v "^#" {input.pfam_out} | awk '{{print $1"\\t"$4"\\t"$5}}' >> {output.merged}) 2>> {log}
        """


rule bin_magscot_compose_contig_to_bin_concoct_one:
    """Compose the contig to bin file from CONCOCT"""
    input:
        CONCOCT / "fasta_bins" / "{assembly_id}/",
    output:
        MAGSCOT / "{assembly_id}/concoct.contigs_to_bin.tsv",
    log:
        MAGSCOT / "{assembly_id}/concoct.contigs_to_bin.log",
    conda:
        "magscot.yml"
    shell:
        """
        (grep -H ^">" {input}/*.fa \
        | parallel -j 1 echo {{/}} \
        | sed 's/\.fa:>/\\t/' \
        | awk '{{print $0"\\tconcoct"}}' \
        > {output} \
        ) 2> {log}
        """


rule bin_magscot_compose_contig_to_bin_maxbin2_one:
    """Compose the contig to bin file from MaxBin2"""
    input:
        MAXBIN2 / "bins" / "{assembly_id}/",
    output:
        MAGSCOT / "{assembly_id}/maxbin2.contigs_to_bin.tsv",
    log:
        MAGSCOT / "{assembly_id}/maxbin2.contigs_to_bin.log",
    conda:
        "magscot.yml"
    shell:
        """
        (grep -H ^">" {input}/*.fasta \
        | parallel -j 1 echo {{/}} \
        | sed 's/\.fa:>/\\t/' \
        | awk '{{print $0"\\tmaxbin2"}}' \
        > {output} \
        ) 2> {log}
        """


rule bin_magscot_compose_contig_to_bin_metabat2_one:
    """Compose the contig to bin file from MetaBAT2"""
    input:
        METABAT2 / "bins/{assembly_id}/",
    output:
        MAGSCOT / "{assembly_id}/metabat2.contigs_to_bin.tsv",
    log:
        MAGSCOT / "{assembly_id}/metabat2.contigs_to_bin.log",
    conda:
        "magscot.yml"
    shell:
        """
        (grep -H ^">" {input}/*.fa \
        | parallel -j 1 echo {{/}} \
        | sed 's/\.fa:>/\\t/' \
        | awk '{{print $0"\\tmetabat2"}}' \
        > {output} \
        ) 2> {log}
        """


rule bin_magscot_merge_contig_to_bin_one:
    """Merge the contig to bin files from CONCOCT, MaxBin2 and MetaBAT2"""
    input:
        MAGSCOT / "{assembly_id}/concoct.contigs_to_bin.tsv",
        MAGSCOT / "{assembly_id}/maxbin2.contigs_to_bin.tsv",
        MAGSCOT / "{assembly_id}/metabat2.contigs_to_bin.tsv",
    output:
        MAGSCOT / "{assembly_id}/contigs_to_bin.tsv",
    log:
        MAGSCOT / "{assembly_id}/contigs_to_bin.log",
    conda:
        "magscot.yml"
    shell:
        """
        cat {input} > {output} 2> {log}
        """


rule bin_magscot_run_one:
    """Run MAGSCOT over one assembly"""
    input:
        contigs_to_bin=MAGSCOT / "{assembly_id}/contigs_to_bin.tsv",
        hmm=MAGSCOT / "{assembly_id}/hmm.tblout",
    output:
        ar53=MAGSCOT / "{assembly_id}/magscot.gtdb_rel207_ar53.out",
        bac120=MAGSCOT / "{assembly_id}/magscot.gtdb_rel207_bac120.out",
        refined_contig_to_bin=MAGSCOT
        / "{assembly_id}/magscot.refined.contig_to_bin.out",
        refined_out=MAGSCOT / "{assembly_id}/magscot.refined.out",
        scores=MAGSCOT / "{assembly_id}/magscot.scores.out",
    log:
        MAGSCOT / "{assembly_id}/magscot.log",
    conda:
        "magscot.yml"
    params:
        out_prefix=compose_out_prefix_for_bin_magscot_run_one,
    resources:
        runtime=8 * 60,
        mem_mb=8 * 1024,
    shell:
        """
        Rscript --vanilla workflow/scripts/MAGScoT/MAGScoT.R \
            --input {input.contigs_to_bin} \
            --hmm {input.hmm} \
            --out {params.out_prefix} \
        2> {log} 1>&2
        """


rule bin_magscot_reformat_one:
    """Reformat the results from MAGSCOT"""
    input:
        refined_contig_to_bin=MAGSCOT
        / "{assembly_id}/magscot.refined.contig_to_bin.out",
    output:
        clean=MAGSCOT / "{assembly_id}/magscot.reformat.tsv",
    log:
        MAGSCOT / "{assembly_id}/magscot.reformat.log",
    conda:
        "magscot.yml"
    shell:
        """
        Rscript --vanilla workflow/scripts/clean_magscot_bin_to_contig.R \
            --input-file {input.refined_contig_to_bin} \
            --output-file {output.clean} \
        2> {log} 1>&2
        """


rule bin_magscot_rename_one:
    """Rename the contigs in the assembly to match the assembly and bin names"""
    input:
        assembly=ASSEMBLE_RENAME / "{assembly_id}.fa",
        clean=MAGSCOT / "{assembly_id}/magscot.reformat.tsv",
    output:
        fasta=MAGSCOT / "{assembly_id}.fa",
    log:
        MAGSCOT / "{assembly_id}/magscot.rename.log",
    conda:
        "magscot.yml"
    shell:
        """
        python workflow/scripts/reformat_fasta_magscot.py \
            {input.assembly} \
            {input.clean} \
        > {output.fasta} 2> {log}
        """


rule bin_magscot_split_into_bins:
    """Split the magscot fasta into bins"""
    input:
        fasta=MAGSCOT / "{assembly_id}.fa",
    output:
        bins=directory(MAGSCOT / "{assembly_id}/bins"),
    log:
        MAGSCOT / "{assembly_id}/bins.log",
    conda:
        "magscot.yml"
    shell:
        """
        mkdir -p {output.bins} 2> {log}
        ( seqtk seq {input.fasta} \
        | paste - -  \
        | tr "@:" "\\t" \
        | awk '{{print $1":"$2"@"$3"\\n"$4 > "{output.bins}/"$2".fa"}}'
        ) 2> {log}
        """


rule bin_magscot:
    """Run MAGSCOT over all assemblies"""
    input:
        [MAGSCOT / f"{assembly_id}/bins" for assembly_id in ASSEMBLIES],
