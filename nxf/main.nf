params.outputDir = "output"

Channel.from(["Sample1", "Sample2"]).set { samples_input_ch }

process print_sampleID {
    input:
    val(sampleID) from samples_input_ch

    output:
    file("${output_file}") into sampleID_files

    script:
    output_file = "${sampleID}.txt"
    """
    echo "${sampleID}" > "${output_file}"
    sleep 15
    """
}
sampleID_files.collectFile(name: "sampleIDs.txt", storeDir: "${params.outputDir}")
