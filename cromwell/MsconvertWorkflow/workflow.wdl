# Convert RAW files with MSCONVERT using the cromwell
# 
# This pipeline will 
# 1. Download file contains the RAW files to be converted
# 2. Download file containing the msconvert configuration to be used
#    during the conversion.
# 3. For each file in #1
#    1. Download RAW file
#    2. Convert RAW file using msconvert
#    3. Upload converted file. File will be uploaded either to same 
#       fileroot location as #1 or will be uploaded to a subdirectory
#       specified in "outdir" folder in msconvert configuration file
# 
# See the README.md for configuring your workstation to run this pipeline.
# 

workflow msconvert_workflow {

    String url_webdav_msconvert_config
    String url_webdav_raw_files_folder
    String url_webdav_converted_files_folder
    String panorama_apikey

    # Get a list of all the raw files in the specified folder
    call list_raw_files {
        input:
            raw_files_folder_url=url_webdav_raw_files_folder,
            apikey=panorama_apikey
    }

    # Download the Skyline template file
    call download_file as download_msconvert_config {
        input:
            file_url=url_webdav_msconvert_config,
            apikey=panorama_apikey
    }

    scatter (rawfile_name in read_lines(list_raw_files.file_list)) {
        call download_file as download_raw_file {
            input:
                file_url=url_webdav_raw_files_folder + "/" + rawfile_name,
                apikey=panorama_apikey
        }

        call msconvert {
            input:
                raw_file=download_raw_file.downloaded_file,
                config_file=download_msconvert_config.downloaded_file
        }

        call upload_file{
            input:
                panorama_folder= url_webdav_converted_files_folder,
                apikey=panorama_apikey,
                file_to_be_uploaded=msconvert.converted_file
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
        docker: "vagisha11/panorama-client-java:1.0"
    }

    output {
        File downloaded_file = basename("${file_url}")
        File task_log = stdout()
    }
}

task list_raw_files {
    String raw_files_folder_url
    String ext="RAW"
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
        docker: "vagisha11/panorama-client-java:1.0"
    }

    output {
        File file_list = "file_list.txt"
        File task_log = stdout()
    }
}

task msconvert {
    File raw_file
    File config_file

    command<<<
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
        File run_msconvert_log = stdout()
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
        docker: "vagisha11/panorama-client-java:1.0"
    }

    output {
        File task_log = stdout()
    }
}