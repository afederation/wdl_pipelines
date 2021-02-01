# Run Comet and Perculator on mzML files and upload to Limelight. 
# 
# This pipeline will 
# 1. Download fasta file
# 2. Download Crux params file 
# 3. Download list of files located in the url_labkey_webdav_input_files_folder folder
# 4. For each file in #2
#    1. Download sample file
#    2. Perform a comet search using crux
#    3. Run percolator, using crux, on the comet search results
#    4. Convert percolator and comet results to limelight format
#    5. Import the limelight results into the limelight server
#    6. Upload result files from comet, percolator and limelight to the 
#       url_labkey_webdav_output_files_folder folder
# 
# See the README.md for configuring your workstation to run this pipeline.
# 
# Versions: 
# - crux: This workflow will use the latest daily release of crux
# - Limelight Converter: This workflow will use the latest release
# - Limelight Importer: This workflow will use the latest release

workflow dda_crux_comet_percolator_limelight_workflow {

    String url_labkey_webdav_fasta
    String url_labkey_webdav_params
    String url_labkey_webdav_input_files_folder
    String url_labkey_webdav_output_files_folder
    String panorama_apikey
    String string_input_file_extension
    String url_external_limelight_webapp
    String string_limelight_project_id
    String string_limelight_user_key

    # Get a list of all the raw files in the specified folder
    call list_files {
        input:
            raw_files_folder_url=url_labkey_webdav_input_files_folder,
            ext=string_input_file_extension,
            apikey=panorama_apikey
    }

    # Download the fasta file
    call download_file as download_fasta_file {
        input:
            file_url=url_labkey_webdav_fasta,
            apikey=panorama_apikey
    }

    # Download the crux params file 
    call download_file as download_params_file {
        input:
            file_url=url_labkey_webdav_params,
            apikey=panorama_apikey
    }

    scatter (input_file_name in read_lines(list_files.file_list)) {
        call download_file as download_input_file {
            input:
                file_url=url_labkey_webdav_input_files_folder + "/" + input_file_name,
                apikey=panorama_apikey
        }

        call comet {
            input:
                input_file=download_input_file.downloaded_file,
                fasta_file=download_fasta_file.downloaded_file,
                params_file=download_params_file.downloaded_file,
                ext=string_input_file_extension
        }

        call percolator {
            input:
                comet_output=comet.comet_output,
                params_file=download_params_file.downloaded_file
        }

        call limelight_convert {
            input:
                percolator_output=percolator.percolator_output,
                fasta_file=download_fasta_file.downloaded_file,
                run_name=comet.run_name
        }

        call import_to_limelight {
            input:
                input_file=download_input_file.downloaded_file,
                crux_limelight=limelight_convert.crux_limelight,
                run_name=comet.run_name,
                limelight_webapp=url_external_limelight_webapp,
                limelight_project_id=string_limelight_project_id,
                limelight_user_key=string_limelight_user_key
        }

        call upload_file as upload_file_crux_limelight {
            input:
                panorama_folder= url_labkey_webdav_output_files_folder,
                apikey=panorama_apikey,
                file_to_be_uploaded=limelight_convert.crux_limelight
        }

        call upload_file as upload_file_limelight_import_log {
            input:
                panorama_folder=url_labkey_webdav_output_files_folder,
                apikey=panorama_apikey,
                file_to_be_uploaded=import_to_limelight.import_to_limelight_log
        }
        
        # Note: In the release build of crux v3.2, the PIN file output by crux-comet was 
        # named comet.target.pin. In Crux daily releases 3.2.fb7f902
        # or later, the file name was changed to comet.pin
        # On 11/9/2020, this workflow was changed to use Crux daily builds
        # instead of the release build (which was from 3/2018)
        call upload_multiple_files {
            input:
                panorama_folder=url_labkey_webdav_output_files_folder,
                apikey=panorama_apikey,
                crux_output=percolator.percolator_output,
                run_name=comet.run_name,
                files_to_be_uploaded=["comet.log.txt", "comet.params.txt", "comet.pin", "percolator.log.txt", "percolator.pout.xml", "percolator.params.txt"]
        }
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
        docker: "proteowizard/panorama-client-java:1.1"
    }

    output {
        File downloaded_file = basename("${file_url}")
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
        docker: "proteowizard/panorama-client-java:1.1"
    }

    output {
        File file_list = "file_list.txt"
    }
}


task comet {
    File input_file
    File fasta_file
    File params_file
    String ext

    command {
        /crux comet \
            --parameter-file ${params_file} \
            ${input_file} ${fasta_file} \
            --output-dir ./crux_output 
        rc=$?
        tar czf crux_output.tar.gz ./crux_output
        rm -rf ./crux_output
        exit $rc
    }

    runtime {
        docker: "proteowizard/panorama-crux:latest"
    }

    output {
        File comet_output = "crux_output.tar.gz"
        String run_name = basename("${input_file}", ".${ext}")
    }
}

# Note: In the release build of crux v3.2, the PIN file output by crux-comet was 
# named comet.target.pin. In Crux daily releases 3.2.fb7f902
# or later, the file name was changed to comet.pin
# On 11/9/2020, this workflow was changed to use Crux daily builds
# instead of the release build (which was from 3/2018)
task percolator {
    File comet_output
    File params_file

    command {
        tar xzf ${comet_output}
        /crux percolator \
            --parameter-file ${params_file} \
            --output-dir crux_output \
            crux_output/comet.pin
        rc=$?
        tar czf crux_output.tar.gz ./crux_output
        rm -rf ./crux_output
        exit $rc  
    }

    runtime {
        docker: "proteowizard/panorama-crux:latest"
    }

    output {
        File percolator_output = "crux_output.tar.gz"
    }
}


task limelight_convert {
    File percolator_output
    File fasta_file
    String run_name

    command {
        tar xzf ${percolator_output}
        java -jar /code/cruxCometPercolator2LimelightXML.jar \
            -v \
            -d ./crux_output \
            -f ${fasta_file} \
            -o ${run_name}.crux.limelight.xml
        rc=$?
        rm -rf ./crux_output
        exit $rc
    }

    runtime {
        docker: "proteowizard/panorama-cruxcometpercolator2limelightxml:latest"
    }

    output {
        #File limelight_convert_log = "./??.log.txt"
        File crux_limelight = "./${run_name}.crux.limelight.xml"
    }
}


task import_to_limelight {
    File input_file
    File crux_limelight
    String limelight_webapp
    String limelight_project_id
    String run_name
    String limelight_user_key

    command {
        java -jar /code/limelightSubmitImport.jar \
            --limelight-web-app-url=${limelight_webapp} \
            -p ${limelight_project_id} \
            --user-submit-import-key=${limelight_user_key} \
            --search-description=\"${run_name}\" \
            -i ${crux_limelight} \
            -s ${input_file} > ${run_name}-limelight.log.txt
        
    }

    runtime {
        docker: "proteowizard/panorama-limelightsubmitimport:latest"
    }

    output {
        File import_to_limelight_log = "${run_name}-limelight.log.txt"
    }
}


task upload_file {
    String panorama_folder
    String apikey
    File file_to_be_uploaded

    command {
        java -jar /code/PanoramaClient.jar \
             -u \
             -c \
             -w "${panorama_folder}" \
             -f ${file_to_be_uploaded}\
             -k "${apikey}"
    }

    runtime {
        docker: "proteowizard/panorama-client-java:1.1"
    }
}


task upload_multiple_files {
    String panorama_folder
    String apikey
    File crux_output
    String run_name
    Array[String] files_to_be_uploaded

    command {
        tar xzf ${crux_output}
        echo ${sep=' ' files_to_be_uploaded}
        for file in ${sep=' ' files_to_be_uploaded}; do
            mv "./crux_output/$file" "./crux_output/${run_name}-$file"
            java -jar /code/PanoramaClient.jar \
                -u -c \
                -w "${panorama_folder}" \
                -f "./crux_output/${run_name}-$file" \
                -k "${apikey}"
            rc=$?
            if [[ "$rc" -ne 0 ]]; then
                echo "PanoramaClient Return Code: $rc"
                exit 1
            fi
        done
        rm -rf ./crux_output

    }

    runtime {
        docker: "proteowizard/panorama-client-java:1.1"
    }
}