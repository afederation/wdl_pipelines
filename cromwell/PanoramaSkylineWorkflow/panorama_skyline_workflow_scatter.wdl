# Import one or more RAW files into a Skyline document with cromwell
# and upload the document to a Panorama server
#
# This pipeline will
# 1. Download RAW files and a template Skyline document from a Panorama server.
# 2. Using Skyline, import the RAW file(s) into the Skyline document.
#    Save the Skyline document as a shared zip file.
# 3. Upload the zip file to PanoramaWeb and queue a document import job


workflow panorama_skyline_workflow {

    String url_webdav_skyline_template
    String url_webdav_raw_files_folder
    String url_target_panorama_folder
    String panorama_apikey
	String raw_file_ext
	String? output_skyline_zip

    # Get a list of all the raw files in the specified folder
    call list_raw_files {
        input:
            raw_files_folder_url=url_webdav_raw_files_folder,
            apikey=panorama_apikey,
            ext=raw_file_ext
    }

    # Download all the raw files
    scatter (rawfile_name in read_lines(list_raw_files.file_list)) {
        call download_file as download_raw_file {
            input:
                file_url=url_webdav_raw_files_folder + "/" + rawfile_name,
                apikey=panorama_apikey
        }
    }

    # Download the Skyline template file
    call download_file as download_skyline_template {
        input:
            file_url=url_webdav_skyline_template,
            apikey=panorama_apikey
    }

    # Import the raw files into the Skyline document
    call skyline_import_raw {
        input:
            skyline_file=download_skyline_template.downloaded_file,
            raw_files=download_raw_file.downloaded_file,
			shared_zip=output_skyline_zip
    }

    # Upload the document to the specified folder on a Panorama server and queue an import job
    call upload_and_import_skyzip {
        input:
            panorama_folder= url_target_panorama_folder,
            apikey=panorama_apikey,
            sky_zip=skyline_import_raw.output_sky_zip
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


task list_raw_files {
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


task skyline_import_raw {
    File skyline_file
    Array[File] raw_files
    String skyline_file_basename=basename(skyline_file, ".sky")
	String? shared_zip

    command {
        ln -s "${skyline_file}" .
        wine SkylineCmd --in="${skyline_file_basename}.sky" --import-file=${sep=' --import-file=' raw_files}  --save --log-file="${skyline_file_basename}.log" --share-zip${"=" + shared_zip} --log-file="${skyline_file_basename}.log"
    }

    runtime {
        docker: "proteowizard/pwiz-skyline-i-agree-to-the-vendor-licenses:latest"
    }

    output {
        File output_sky_zip = glob("*.sky.zip")[0]
        File skyline_log = "${skyline_file_basename}.log"
        File task_log = stdout()
    }
}


task upload_and_import_skyzip {
    String panorama_folder
    String apikey
    File sky_zip

    command {
        java -jar /code/PanoramaClient.jar \
             -i \
             -p "${panorama_folder}" \
             -s "${sky_zip}"\
             -k "${apikey}"
    }

    runtime {
        docker: "proteowizard/panorama-client-java:1.1"
    }

    output {
        File task_log = stdout()
    }
}