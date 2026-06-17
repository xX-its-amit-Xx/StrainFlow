// Emit a JSON run-manifest: samples, params, tool versions, git commit, timestamp

process RUN_MANIFEST {
    label        'small'
    publishDir   "${params.outdir}", mode: params.publish_dir_mode

    container 'quay.io/biocontainers/python:3.11--hb4d6b87_2'

    input:
    val  sample_ids
    val  pipeline_version
    val  git_commit
    val  run_params

    output:
    path "strainflow_run_manifest.json", emit: manifest

    script:
    def params_json = groovy.json.JsonOutput.toJson(run_params)
    """
    python3 ${projectDir}/bin/generate_manifest.py \\
        --sample-ids    '${sample_ids.join(",")}' \\
        --version       '${pipeline_version}' \\
        --git-commit    '${git_commit}' \\
        --params        '${params_json}' \\
        --output        strainflow_run_manifest.json
    """
}
