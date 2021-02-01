# Run Comet and Perculator on mzML files and upload to Limelight
# 
# This pipeline will 
# 1. Download fasta file
# 2. Download list of files located in the url_webdav_input_files_folder folder
# 3. For each file in #2
#    1. Download sample file
#    2. Perform a comet search using crux
#    3. Run percolator, using crux, on the comet search results
#    4. Convert percolator and comet results to limelight format
#    5. Import the limelight results into the limelight server
#    6. Upload result files from comet, percolator and limelight to the 
#       url_webdav_output_files_folder folder
# 
# See the README.md for configuring your workstation to run this pipeline.
# 

workflow dda_crux_comet_percolator_limelight_workflow {

    String url_webdav_fasta
    String url_webdav_input_files_folder
    String url_webdav_output_files_folder
    String panorama_apikey
    String input_file_extension
    String limelight_web_app_url
    String limelight_project_id
    String limelight_user_key

    # Get a list of all the raw files in the specified folder
    call list_files {
        input:
            raw_files_folder_url=url_webdav_input_files_folder,
            ext=input_file_extension,
            apikey=panorama_apikey
    }

    # Download the fasta file
    call download_file as download_fasta_file {
        input:
            file_url=url_webdav_fasta,
            apikey=panorama_apikey
    }

    scatter (input_file_name in read_lines(list_files.file_list)) {
        call download_file as download_input_file {
            input:
                file_url=url_webdav_input_files_folder + "/" + input_file_name,
                apikey=panorama_apikey
        }

        call comet {
            input:
                input_file=download_input_file.downloaded_file,
                fasta_file=download_fasta_file.downloaded_file,
                ext=input_file_extension
        }

        call percolator {
            input:
                comet_output=comet.comet_output
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
                limelight_web_app_url=limelight_web_app_url,
                limelight_project_id=limelight_project_id,
                limelight_user_key=limelight_user_key
        }

        call upload_file as upload_file_crux_limelight{
            input:
                panorama_folder= url_webdav_output_files_folder,
                apikey=panorama_apikey,
                file_to_be_uploaded=limelight_convert.crux_limelight
        }

        call upload_file as upload_file_limelight_import_log{
            input:
                panorama_folder=url_webdav_output_files_folder,
                apikey=panorama_apikey,
                file_to_be_uploaded=import_to_limelight.import_to_limelight_log
        }
        
        call upload_multiple_files {
            input:
                panorama_folder=url_webdav_output_files_folder,
                apikey=panorama_apikey,
                crux_output=percolator.percolator_output,
                files_to_be_uploaded=["comet.log.txt", "comet.params.txt", "comet.target.pin", "percolator.log.txt", "percolator.pout.xml", "percolator.params.txt"]
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
        File task_log = stdout()
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
        File task_log = stdout()
    }
}


task comet {
    File input_file
    File fasta_file
    String ext

    command {
        /crux comet \
            --decoy_search 1 \
            --output_percolatorfile 1 \
            ${input_file} ${fasta_file} \
            --output-dir ./crux_output \
            --overwrite T
        rc=$?
        tar czf crux_output.tar.gz ./crux_output
        rm -rf ./crux_output
        exit $rc
    }

    runtime {
        docker: "proteowizard/panorama-crux:3.2"
    }

    output {
        File comet_output = "crux_output.tar.gz"
        File comet_task_log = stdout()
        String run_name = basename("${input_file}", ".${ext}")
    }
}


task percolator {
    File comet_output

    command {
        tar xzf ${comet_output}
        /crux percolator \
            --pout-output T \
            --output-dir crux_output \
            --overwrite T \
            crux_output/comet.target.pin
        rc=$?
        tar czf crux_output.tar.gz ./crux_output
        rm -rf ./crux_output
        exit $rc  
    }

    runtime {
        docker: "proteowizard/panorama-crux:3.2"
    }

    output {
        File percolator_output = "crux_output.tar.gz"
        File percolator_task_log = stdout()
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
        #rm -rf ./crux_output
        exit $rc
    }

    runtime {
        docker: "proteowizard/panorama-limelight:2.1.0"
    }

    output {
        #File limelight_convert_log = "./??.log.txt"
        File crux_limelight = "./${run_name}.crux.limelight.xml"
        File limelight_convert_task_log = stdout()
    }
}


task import_to_limelight {
    File input_file
    File crux_limelight
    String limelight_web_app_url
    String limelight_project_id
    String run_name
    String limelight_user_key

    command {
        java -jar /code/limelightSubmitImport.jar \
            --limelight-web-app-url=${limelight_web_app_url} \
            -p ${limelight_project_id} \
            --user-submit-import-key=${limelight_user_key} \
            --search-description=\"${run_name}\" \
            -i ${crux_limelight} \
            -s ${input_file} > ${run_name}-limelight.log.txt
        
    }

    runtime {
        docker: "proteowizard/panorama-limelight:2.1.0"
    }

    output {
        File import_to_limelight_log = "${run_name}-limelight.log.txt"
        File import_to_limelight_task_log = stdout()
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

    output {
        File task_log = stdout()
    }
}


task upload_multiple_files {
    String panorama_folder
    String apikey
    File crux_output
    Array[String] files_to_be_uploaded

    command {
        tar xzf ${crux_output}
        echo ${sep=' ' files_to_be_uploaded}
        for file in ${sep=' ' files_to_be_uploaded}; do 
            java -jar /code/PanoramaClient.jar \
                -u -c \
                -w "${panorama_folder}" \
                -f "./crux_output/$file" \
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

    output {
        File task_log = stdout()
    }

}