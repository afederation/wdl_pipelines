# Run EncyclopeDIA workflow on files downloaded from 
# PanoramaWeb. The files results files will be uploaded to PanoramaWeb
# 
# Version 0.2
# 
# This pipeline will 
# 1. Download list of narrow window RAW or mzML files from PanoramaWeb folder
# 2. Download background fasta file 
# 3. Download DDA-based spectrum file
# 4. For each file in #1
#   1. Download file
#   2. Convert RAW file using msconvert if needed
#   3. Run encyclopeDIA on mzML file 
# 5. Using results from #4, run encyclopedia to create temp elib file
# 6. Upload temp elib to PanoramaWeb folder
# 7. Download list of wide window RAW or mzML files from PanoramaWeb folder
# 8. For each file in #1
#   1. Download file
#   2. Convert RAW file using msconvert if needed
#   3. Run encyclopeDIA on mzML file 
# 9. Using results from #4, run encyclopedia to generate global quantitation
# 10. Upload global quantitation output to PanoramaWeb folder
#
#
# See the README.md for configuring your workstation to run this pipeline.
# 

workflow dia_msconvert_encyclopedia {

    String panorama_apikey
    String url_labkey_webdav_fasta
    String url_labkey_webdav_dda_library
    String url_labkey_webdav_input_narrow_files_folder
    String url_labkey_webdav_input_wide_files_folder
    String url_labkey_webdav_output_files_folder
    String input_file_extension
    String encyclopedia_library_name
    String? url_labkey_webdav_msconvert_config


    # Get a list of all the files in the folder which contains "narrow windows"
    call list_files as list_files_narrow {
        input:
            raw_files_folder_url=url_labkey_webdav_input_narrow_files_folder,
            ext=input_file_extension,
            apikey=panorama_apikey
    }

    # Download the fasta file
    call download_file as download_fasta_file {
        input:
            file_url=url_labkey_webdav_fasta,
            apikey=panorama_apikey
    }

    # Download the DDA library file
    call download_file as download_dda_lib_file {
        input:
            file_url=url_labkey_webdav_dda_library,
            apikey=panorama_apikey
    }

    # Download the Skyline template file
    if (input_file_extension=='raw' || input_file_extension=='RAW') {
        call download_file as download_msconvert_config {
            input:
                file_url=url_labkey_webdav_msconvert_config,
                apikey=panorama_apikey
        }
    }

    # Run msconvert (if needed) and encyclopeDIA on each "narrow window" input file 
    scatter (input_file_name in read_lines(list_files_narrow.file_list)) {
        call download_file as download_input_file {
            input:
                file_url=url_labkey_webdav_input_narrow_files_folder + "/" + input_file_name,
                apikey=panorama_apikey
        }

        if (input_file_extension=='raw' || input_file_extension=='RAW') {
            call msconvert {
                input:
                    raw_file=download_input_file.downloaded_file,
                    config_file=download_msconvert_config.downloaded_file
            }

            call upload_file {
            input:
                panorama_folder=url_labkey_webdav_output_files_folder,
                apikey=panorama_apikey,
                file_to_be_uploaded=msconvert.converted_file
            }
        }

        File input_file = select_first([msconvert.converted_file, download_input_file.downloaded_file])

        call encyclopedia {
            input:
                input_file=input_file,
                fasta=download_fasta_file.downloaded_file,
                library_elib=download_dda_lib_file.downloaded_file,
                memory="16g"
        }
    }

    # Create chromatogram library. This is a temporary library that will be used in a 
    # later step in the workflow.
    call encyclopedia_export_library {
        input:
            mzml_files=input_file,
            features_files=encyclopedia.features_file,
            encyclopedia_txt_files=encyclopedia.output_report_file,
            dia_files=encyclopedia.dia_file,
            fasta=download_fasta_file.downloaded_file,
            library_elib=download_dda_lib_file.downloaded_file,
            output_library_file=encyclopedia_library_name + "-chr.elib",
            align_between_files=false,
            memory="16g"
    }

    # Upload the chormatogram library to Panorama server
    call upload_file as upload_file_chromatogram_library{
        input:
            panorama_folder=url_labkey_webdav_output_files_folder,
            apikey=panorama_apikey,
            file_to_be_uploaded=encyclopedia_export_library.output_library_elib
    }

    # Get a list of all the files in the folder which contains "wide windows"
    call list_files as list_files_wide {
        input:
            raw_files_folder_url=url_labkey_webdav_input_wide_files_folder,
            ext=input_file_extension,
            apikey=panorama_apikey
    }

    # Run msconvert (if needed) and encyclopeDIA on each "wide window" input file 
    scatter (input_file_name in read_lines(list_files_wide.file_list)) {
        call download_file as download_input_file_wide {
            input:
                file_url=url_labkey_webdav_input_wide_files_folder + "/" + input_file_name,
                apikey=panorama_apikey
        }

        if (input_file_extension=='raw' || input_file_extension=='RAW') {
            call msconvert as msconvert_wide {
                input:
                    raw_file=download_input_file_wide.downloaded_file,
                    config_file=download_msconvert_config.downloaded_file
            }

            call upload_file as upload_file_wide {
            input:
                panorama_folder=url_labkey_webdav_output_files_folder,
                apikey=panorama_apikey,
                file_to_be_uploaded=msconvert_wide.converted_file
            }
        }

        File input_file_wide = select_first([msconvert_wide.converted_file, download_input_file_wide.downloaded_file])

        call encyclopedia_wide {
            input:
                input_file=input_file_wide,
                fasta=download_fasta_file.downloaded_file,
                library_elib=encyclopedia_export_library.output_library_elib,
                memory="16g"
        }
    }

    # Create quantitative library
    call encyclopedia_export_library as encyclopedia_export_library_quant{
        input:
            mzml_files=input_file_wide,
            features_files=encyclopedia_wide.features_file,
            encyclopedia_txt_files=encyclopedia_wide.output_report_file,
            encyclopedia_decoy_txt_files=encyclopedia_wide.output_decoy_file,
            dia_files=encyclopedia_wide.dia_file,
            mzml_elib_files=encyclopedia_wide.mzml_elib_file,
            fasta=download_fasta_file.downloaded_file,
            library_elib=encyclopedia_export_library.output_library_elib,
            output_library_file=encyclopedia_library_name + "-quant.elib",
            align_between_files=true,
            memory="16g"
    }

    call upload_file as upload_file_encyclopedia_quant_lib {
        input:
            panorama_folder=url_labkey_webdav_output_files_folder,
            apikey=panorama_apikey,
            file_to_be_uploaded=encyclopedia_export_library_quant.output_library_elib
    }

    call upload_file as upload_file_encyclopedia_quant_peptides {
        input:
            panorama_folder=url_labkey_webdav_output_files_folder,
            apikey=panorama_apikey,
            file_to_be_uploaded=encyclopedia_export_library_quant.peptides_report
    }

    call upload_file as upload_file_encyclopedia_quant_proteins {
        input:
            panorama_folder=url_labkey_webdav_output_files_folder,
            apikey=panorama_apikey,
            file_to_be_uploaded=encyclopedia_export_library_quant.proteins_report
    }

}


task download_file {
    String file_url
    String apikey

    command {
        java -jar /code/PanoramaClient.jar \
             -d \
             -w "${file_url}" \
             -k "${apikey}"
    }

    runtime {
        docker: "proteowizard/panorama-client-java:latest"
    }

    output {
        File downloaded_file = basename("${file_url}")
    }

    parameter_meta {
        file_url: "WebDAV URL for file to be downloaded"
        apikey: "Panorama Server API key"
    }

    meta {
        author: "Vagisha Sharma"
        email: "vsharma@uw.edu"
        description: "Download file from a Panorama Server WebDAV url"
    }
}


task list_files {
    String raw_files_folder_url
    String ext
    String apikey

    command {
        java -jar /code/PanoramaClient.jar \
             -l \
             -w "${raw_files_folder_url}" \
             -e ${ext} \
             -o file_list.txt \
             -k "${apikey}"
    }

    runtime {
        docker: "proteowizard/panorama-client-java:latest"
    }

    output {
        File file_list = "file_list.txt"
    }

    parameter_meta {
        raw_files_folder_url: "Folder on Panorama Server where input files are located."
        ext: "File extension of the files to be downloaded"
        apikey: "Panorama Server API key"
    }

    meta {
        author: "Vagisha Sharma"
        email: "vsharma@uw.edu"
        description: "List files in folder on Panorama Server"
    }
}


task msconvert {
    File raw_file
    File config_file

    command<<<
        set -e
        wine msconvert ${raw_file} -c ${config_file} | tee ./msconvert_output.txt
        if [[ $? -eq 0 ]]; then
            grep "writing output file" ./msconvert_output.txt | awk -F ": " '{print $2}' | tr '\\' '/' > ./converted_file_name.txt
        else
            echo "MSCONVERT_FAILED" > ./converted_file_name.txt
            exit 1
        fi
    >>>

    runtime {
        docker: "chambm/pwiz-skyline-i-agree-to-the-vendor-licenses:latest"
    }

    output {
        String converted_file_name = read_string("./converted_file_name.txt")
        File converted_file = converted_file_name
    }

    parameter_meta {
        raw_file: "RAW file which msconvert should run on."
        config_file: "msconvert configuration file."
    }

    meta {
        author: "Brian Connolly"
        email: "bdconnol@uw.edu"
        description: "Run msconvert to convert RAW file to mzML"
    }
}


task encyclopedia {
    File input_file
    File fasta
    File library_elib
    String memory = "8g"
    String? numberOfThreadsUsed
    String? out_report_file
    String? acquisition
    String? enzyme
    Int? expectedPeakWidth
    Boolean? filterPeaklists
    String? fixed
    Int? foffset
    String? frag
    Int? ftol
    String? ftolunits
    Int? lftol
    String? lftolunits
    String? localizationModification
    Float? minIntensity
    Int? minNumOfQuantitativePeaks
    Int? minQuantitativeIonNumber
    Float ?numberOfExtraDecoyLibrariesSearche
    Int? numberOfQuantitativePeaks
    Float? percolatorProteinThreshold
    Float? percolatorThreshold
    Float? percolatorTrainingFDR
    Float? percolatorTrainingSetSize
    String? percolatorVersionNumber
    Float? poffset
    Float? precursorIsolationMargin
    Float? precursorWindowSize
    Float? ptol
    String? ptolunits
    Float? rtWindowInMin
    String? scoringBreadthType
    Boolean? verifyModificationIons


    String encyclopedia_version = "0.9.5"
    String local_input_name = basename(input_file)

    command {
        set -e
        # EncyclopeDIA writes all output files the directory 
        # which contains the mzML file. As a result we need to symlink the
        # input files into the local directory so that Cromwell will 
        # be able to access the output files as OUTPUTs
        ln -s ${input_file} ./${local_input_name}

        java ${"-Xmx" + memory} \
        -jar /code/encyclopedia-${encyclopedia_version}-executable.jar \
        -i ${local_input_name} \
        ${"-f " + fasta} \
        ${"-l " + library_elib} \
        ${"-o " +  out_report_file} \
        ${"-numberOfThreadsUsed " + numberOfThreadsUsed} \
        ${"-acquisition " + acquisition} \
        ${"-enzyme " + enzyme} \
        ${"-expectedPeakWidth " + expectedPeakWidth} \
        ${true='-filterPeaklists' false='' filterPeaklists} \
        ${"-fixed " + fixed} \
        ${"-foffset " + foffset} \
        ${"-frag " + frag} \
        ${"-ftol " + ftol} \
        ${"-ftolunits " + ftolunits} \
        ${"-lftol " + lftol} \
        ${"-lftolunits " + lftolunits} \
        ${"-localizationModification " + localizationModification} \
        ${"-minIntensity " + minIntensity} \
        ${"-minNumOfQuantitativePeaks " + minNumOfQuantitativePeaks} \
        ${"-minQuantitativeIonNumber " + minQuantitativeIonNumber} \
        ${"-numberOfExtraDecoyLibrariesSearche " + numberOfExtraDecoyLibrariesSearche} \
        ${"-numberOfQuantitativePeaks " + numberOfQuantitativePeaks} \
        ${"-percolatorProteinThreshold " + percolatorProteinThreshold} \
        ${"-percolatorThreshold " + percolatorThreshold} \
        ${"-percolatorTrainingFDR " + percolatorTrainingFDR} \
        ${"-percolatorTrainingSetSize " + percolatorTrainingSetSize} \
        ${"-percolatorVersionNumber " + percolatorVersionNumber} \
        ${"-poffset " + poffset} \
        ${"-precursorIsolationMargin " + precursorIsolationMargin} \
        ${"-precursorWindowSize " + precursorWindowSize} \
        ${"-ptol " + ptol} \
        ${"-ptolunits " + ptolunits} \
        ${"-rtWindowInMin " + rtWindowInMin} \
        ${"-scoringBreadthType " + scoringBreadthType} \
        ${"-verifyModificationIons " + verifyModificationIons} 
    }

    runtime {
        docker: "proteowizard/panorama-encyclopedia:${encyclopedia_version}"
    }

    output {
        File output_report_file = basename("${input_file}") + ".encyclopedia.txt"
        File features_file = basename("${input_file}") + ".features.txt"
        File dia_file = basename("${input_file}", ".mzML") + ".dia"
    }

    parameter_meta {
        memory: "Amount of memory to use for EncyclopeDIA run"
    }

    meta {
        author: "Brian Connolly"
        email: "bdconnol@uw.edu"
        description: "Execute encyclopeDIA"
    }
}


task encyclopedia_wide {
    File input_file
    File fasta
    File library_elib
    String memory = "8g"
    String? numberOfThreadsUsed
    String? out_report_file
    String? acquisition
    String? enzyme
    Int? expectedPeakWidth
    Boolean? filterPeaklists
    String? fixed
    Int? foffset
    String? frag
    Int? ftol
    String? ftolunits
    Int? lftol
    String? lftolunits
    String? localizationModification
    Float? minIntensity
    Int? minNumOfQuantitativePeaks
    Int? minQuantitativeIonNumber
    Float ?numberOfExtraDecoyLibrariesSearche
    Int? numberOfQuantitativePeaks
    Float? percolatorProteinThreshold
    Float? percolatorThreshold
    Float? percolatorTrainingFDR
    Float? percolatorTrainingSetSize
    String? percolatorVersionNumber
    Float? poffset
    Float? precursorIsolationMargin
    Float? precursorWindowSize
    Float? ptol
    String? ptolunits
    Float? rtWindowInMin
    String? scoringBreadthType
    Boolean? verifyModificationIons


    String encyclopedia_version = "0.9.5"
    String local_input_name = basename(input_file)

    command {
        set -e
        # EncyclopeDIA writes all output files the directory 
        # which contains the mzML file. As a result we need to symlink the
        # input files into the local directory so that Cromwell will 
        # be able to access the output files as OUTPUTs
        ln -s ${input_file} ./${local_input_name}

        java ${"-Xmx" + memory} \
        -jar /code/encyclopedia-${encyclopedia_version}-executable.jar \
        -i ${local_input_name} \
        ${"-f " + fasta} \
        ${"-l " + library_elib} \
        ${"-o " +  out_report_file} \
        ${"-numberOfThreadsUsed " + numberOfThreadsUsed} \
        ${"-acquisition " + acquisition} \
        ${"-enzyme " + enzyme} \
        ${"-expectedPeakWidth " + expectedPeakWidth} \
        ${true='-filterPeaklists' false='' filterPeaklists} \
        ${"-fixed " + fixed} \
        ${"-foffset " + foffset} \
        ${"-frag " + frag} \
        ${"-ftol " + ftol} \
        ${"-ftolunits " + ftolunits} \
        ${"-lftol " + lftol} \
        ${"-lftolunits " + lftolunits} \
        ${"-localizationModification " + localizationModification} \
        ${"-minIntensity " + minIntensity} \
        ${"-minNumOfQuantitativePeaks " + minNumOfQuantitativePeaks} \
        ${"-minQuantitativeIonNumber " + minQuantitativeIonNumber} \
        ${"-numberOfExtraDecoyLibrariesSearche " + numberOfExtraDecoyLibrariesSearche} \
        ${"-numberOfQuantitativePeaks " + numberOfQuantitativePeaks} \
        ${"-percolatorProteinThreshold " + percolatorProteinThreshold} \
        ${"-percolatorThreshold " + percolatorThreshold} \
        ${"-percolatorTrainingFDR " + percolatorTrainingFDR} \
        ${"-percolatorTrainingSetSize " + percolatorTrainingSetSize} \
        ${"-percolatorVersionNumber " + percolatorVersionNumber} \
        ${"-poffset " + poffset} \
        ${"-precursorIsolationMargin " + precursorIsolationMargin} \
        ${"-precursorWindowSize " + precursorWindowSize} \
        ${"-ptol " + ptol} \
        ${"-ptolunits " + ptolunits} \
        ${"-rtWindowInMin " + rtWindowInMin} \
        ${"-scoringBreadthType " + scoringBreadthType} \
        ${"-verifyModificationIons " + verifyModificationIons} 
    }

    runtime {
        docker: "proteowizard/panorama-encyclopedia:${encyclopedia_version}"
    }

    output {
        File output_report_file = basename("${input_file}") + ".encyclopedia.txt"
        File output_decoy_file = basename("${input_file}") + ".encyclopedia.decoy.txt"
        File features_file = basename("${input_file}") + ".features.txt"
        File dia_file = basename("${input_file}", ".mzML") + ".dia"
        File mzml_elib_file = basename("${input_file}") + ".elib"
    }

    parameter_meta {
        memory: "Amount of memory to use for EncyclopeDIA run"
    }

    meta {
        author: "Brian Connolly"
        email: "bdconnol@uw.edu"
        description: "Execute encyclopeDIA"
    }
}


task encyclopedia_export_library {
    Array[File] mzml_files
    Array[File] dia_files
    Array[File] features_files
    Array[File] encyclopedia_txt_files
    Array[File]? encyclopedia_decoy_txt_files
    Array[File]? mzml_elib_files
    File fasta
    File library_elib
    String memory = "8g"
    String output_library_file
    String? align_between_files
    String? blib
    String? fixed
    Int? foffset
    Int? ftol
    String? ftolunits
    String? localizationModification
    Int? minNumOfQuantitativePeaks
    Int? minQuantitativeIonNumber
    Float ?numberOfExtraDecoyLibrariesSearche
    Int? numberOfQuantitativePeaks
    String? numberOfThreadsUsed
    String? percolatorLocation
    Float? percolatorProteinThreshold
    Float? percolatorThreshold

    String encyclopedia_version = "0.9.5"


    command {
        set -e
        # EncyclopeDIA assumes that all mzML, DIA, features and encyclopedia.txt
        # and elib files will be located in a single directory. The code below will 
        # create symlinks from the INPUTS files to the working directory. 
        # symlink input_files
        for f in ${sep=' ' mzml_files}; do ln -s "$f" "./$(basename $f)"; done

        # symlink dia files
        for f in ${sep=' ' dia_files}; do ln -s "$f" "./$(basename $f)"; done

        # symlink features files
        for f in ${sep=' ' features_files}; do ln -s "$f" "./$(basename $f)"; done

        # symlink encyclopedia.txt files
        for f in ${sep=' ' encyclopedia_txt_files}; do ln -s "$f" "./$(basename $f)"; done

        # symlink encyclopedia.decoy.txt files. These are only needed when creating quant library. 
        # Since these are optional, I need to check if the variable has been specified. 
        # If not specified, then skip creating the symlink
        encyclopedia_decoy_txt="${sep=' ' encyclopedia_decoy_txt_files}"
        if [[ ! -z "$encyclopedia_decoy_txt" ]]
        then
            for f in ${sep=' ' encyclopedia_decoy_txt_files}; do ln -s "$f" "./$(basename $f)"; done
        fi

        # symlink mzml.elib files. These are only needed when creating quant library. 
        # Since these are optional, I need to check if the variable has been specified. 
        # If not specified, then skip creating the symlink
        mzml_elib="${sep=' ' mzml_elib_files}"
        if [[ ! -z "$mzml_elib" ]]
        then
            for f in ${sep=' ' mzml_elib_files}; do ln -s "$f" "./$(basename $f)"; done
        fi

        # Run encyclopedia
        java ${"-Xmx" + memory} \
        -jar /code/encyclopedia-${encyclopedia_version}-executable.jar \
        -libexport \
        -o ${output_library_file} \
        -i ./ \
        ${"-f " + fasta} \
        ${"-l " + library_elib} \
        ${"-a " + align_between_files} \
        ${"-blib " + blib} \
        ${"-fixed " + fixed} \
        ${"-foffset " + foffset} \
        ${"-ftol " + ftol} \
        ${"-ftolunits " + ftolunits} \
        ${"-localizationModification " + localizationModification} \
        ${"-minNumOfQuantitativePeaks " + minNumOfQuantitativePeaks} \
        ${"-minQuantitativeIonNumber " + minQuantitativeIonNumber} \
        ${"-numberOfExtraDecoyLibrariesSearche " + numberOfExtraDecoyLibrariesSearche} \
        ${"-numberOfQuantitativePeaks " + numberOfQuantitativePeaks} \
        ${"-numberOfThreadsUsed " + numberOfThreadsUsed} \
        ${"-percolatorLocation " + percolatorLocation} \
        ${"-percolatorProteinThreshold " + percolatorProteinThreshold} \
        ${"-percolatorThreshold " + percolatorThreshold}
    }

    runtime {
        docker: "proteowizard/panorama-encyclopedia:${encyclopedia_version}"
    }

    output {
        File output_library_elib = "${output_library_file}"
        File? peptides_report = basename("${output_library_file}") + ".peptides.txt"
        File? proteins_report = basename("${output_library_file}") + ".proteins.txt"
    }

    parameter_meta {
        memory: "Amount of memory to use for EncyclopeDIA run"
    }

    meta {
        author: "Brian Connolly"
        email: "bdconnol@uw.edu"
        description: "Execute encyclopeDIA to create chromatogram library"
    }
}


task upload_file {
    String panorama_folder
    String apikey
    File file_to_be_uploaded

    command {
        java -jar /code/PanoramaClient.jar \
             -u \
             -w "${panorama_folder}" \
             -f ${file_to_be_uploaded}\
             -k "${apikey}"
    }

    runtime {
        docker: "proteowizard/panorama-client-java:latest"
    }

    parameter_meta {
        file_url: "WebDAV URL where file will be uploaded"
        apikey: "Panorama Server API key"
        file_to_be_uploaded: "File to be uploaded"
    }

    meta {
        author: "Vagisha Sharma"
        email: "vsharma@uw.edu"
        description: "Upload file to a folder on Panorama Server"
    }
}

