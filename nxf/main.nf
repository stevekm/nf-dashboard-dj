println("hello")

Channel.from(["Sample1", "Sample2"]).set { samples_input_ch }

process print_sampleID {
    input:
    val(sampleID) from samples_input_ch

    script:
    """
    echo "${sampleID}"
    """
}
