# Convert RAW files with MSCONVERT using the cromwell
# [local backend](https://cromwell.readthedocs.io/en/develop/backends/Local/)
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
#
# TODO: Check if outdir (specified in cfg file) exists. If it does not, 
#       create the directory before upload.
# 

workflow run_msconvert {
    String raw_file_list_url
    String msconvert_config_url
    String panorama_server_url
    String panorama_server_folder
    String panorama_server_folder_path
    File netrc

    call download_file as download_raw_filelist {
        input:
            url=raw_file_list_url,
            netrc_file=netrc
    }

    call download_file as download_msconvert_config {
        input:
            url=msconvert_config_url,
            netrc_file=netrc
    }

    call check_for_output_dir {
        input: 
            config_file=download_msconvert_config.download_file_name,
            url_folder_path=panorama_server_folder_path,
    }

    scatter (rawfile in read_lines(download_raw_filelist.download_file_name)) {
        call download_raw_file as download_raw_file {
            input:
                url=raw_file_list_url,
                raw_file_path=rawfile,
                netrc_file=netrc
        }

        call msconvert {
            input:
                raw_file=download_raw_file.download_file_name,
                config_file=download_msconvert_config.download_file_name
        }

        call upload_file{
            input:
                url=panorama_server_url,
                url_folder=panorama_server_folder,
                experiment_name=check_for_output_dir.output_directory,
                file_to_be_uploaded=msconvert.converted_file,
                netrc_file=netrc
        }
    }

}

task download_file {
    String url
    File netrc_file

    command {
        ln -s "${netrc_file}" /root/.netrc
        python /maccoss/download_file.py --url "${url}"
    }

    runtime {
        docker: "proteowizard/panorama-files:1.1"
    }

    output {
        File download_file_log = stdout()
        File download_file_name = basename("${url}")
    }
}

task download_raw_file {
    String url
    String raw_file_path
    File netrc_file

    command<<<
        ln -s "${netrc_file}" /root/.netrc

        # Create URL for raw file using URL and raw_file_path variables. Assume
        # that raw_file_path is a relative path starting from the same location in
        # LabKey file-root as the file specified in the URL
        NURL=$(dirname "${url}")   
        RAWFILEURL="$NURL/${raw_file_path}"
        RAWFILENAME=$(basename "${raw_file_path}") 
        echo "$NURL and $RAWFILEURL and $RAWFILENAME"

        python /maccoss/download_file.py --url "$RAWFILEURL"
    >>>

    runtime {
        docker: "proteowizard/panorama-files:1.1"
    }

    output {
        File download_file_log = stdout()
        File download_file_name = basename("${raw_file_path}")
    }
}

task check_for_output_dir {
    # Simple step to create the output_directory variable. 
    # This variable will be used when uploading the converted files
    # The output_directory will be combination of the "panorama_server_folder_path"
    # input variable and outdir (if specified in the configuration file)

    File config_file
    String url_folder_path

    command<<<
        outdir=$(grep outdir "${config_file}")
        echo $outdir >&2
        cat "${config_file}" >&2
        folder_path="${url_folder_path}"

        if [[ -n "$outdir" ]]; then
            out=$(echo $outdir | awk -F= '{print $2}')
        else
            out=''
        fi

        if [[ -n "$folder_path" ]]; then
            out="$folder_path/$out"
        fi

        echo "$out"
    >>>

    output {
        String output_directory = read_string(stdout())
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
    String url
    String url_folder
    String experiment_name
    File file_to_be_uploaded
    File netrc_file

    command {
        ln -s "${netrc_file}" /root/.netrc
        python /maccoss/upload_file.py --url "${url}" --folder "${url_folder}" --experiment "${experiment_name}" --file-name "${file_to_be_uploaded}"
    }

    runtime {
        docker: "proteowizard/panorama-files:1.1"
    }

    output {
        File upload_file_log = stdout()
    }
}
