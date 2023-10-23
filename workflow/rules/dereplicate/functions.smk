def get_tsvs_for_dereplicate_coverm_genome(wildcards):
    """Get the tsv files for the coverm genome rule."""
    method = wildcards.method
    tsv_files = [
        DREP_COVERM / "genome" / method / f"{sample_id}.{library_id}.tsv"
        for sample_id, library_id in SAMPLE_LIBRARY
    ]
    return tsv_files


def get_tsvs_for_dereplicate_coverm_contig(wildcards):
    """Get the tsv files for the coverm contig rule."""
    method = wildcards.method
    tsv_files = [
        DREP_COVERM / "contig" / method / f"{sample_id}.{library_id}.tsv"
        for sample_id, library_id in SAMPLE_LIBRARY
    ]
    return tsv_files
