# Import a single RAW file into a Skyline document using the cromwell
# [local backend](https://cromwell.readthedocs.io/en/develop/backends/Local/)
# 
# This pipeline will 
# 1. Download a RAW file and template Skyline document from PanoramaWeb
# 2. Using Skyline, import the RAW document into the Skyline document.
#    Save the Skyline project as a zip file.
# 3. Upload the zip file to PanoramaWeb
# 
# See the README.md for configuring your workstation to run this pipeline.
# 
#
# Todos
# ==========================
# Todo: find a way to determine "run_name" from the name of the downloaded file
# Todo: find a way to determine "skyline_template_doc_name" from the name 
#       of the downloaded file
# Todo: Change the upload_file task to create the Experiment directory in the 
#       PanoramaWeb folders FileRoot prior to uploading the zip file.
# 

workflow import_single {
    String experiment_name
    String run_name
    String raw_file_url
    String skyline_template_url
    String skyline_template_doc_name
    String panorama_server_url
    String panorama_folder

    call download_run {
        input:
            url=raw_file_url,
            run_name=run_name
    }

    call download_file as download_skyline_template {
        input:
            url=skyline_template_url,
            file_name=skyline_template_doc_name
    }

    call run_skyline {
        input:
            raw_file=download_run.raw_file,
            skyline_template=download_skyline_template.download_file,
            run_name=run_name
    }

    call upload_file{
        input:
            url=panorama_server_url,
            url_folder=panorama_folder,
            experiment_name=experiment_name,
            file_to_be_uploaded=run_skyline.sky_file
    }
}


task download_run {
    String url
    String run_name

    command {
        # Change the command below to be the fullpath to download_file.py
        python ./panorama-examples/cromwell/run-skyline/download_file.py --url "${url}"
    }

    output {
        # TODO: Create way to make the name of the file for raw_file dynamicallty
        # generated in the command portion of this task
        File raw_file = "${run_name}.RAW"
        File download_file_log = stdout()
    }
}

task download_file {
    String url
    String file_name

    command {
        # Change the command below to be the fullpath to download_file.py
        python ./panorama-examples/cromwell/run-skyline/download_file.py --url "${url}"
    }

    output {
        # TODO: Create way to make the name of the file for raw_file dynamicallty
        # generated in the command portion of this task
        File download_file = "${file_name}"
        File download_file_log = stdout()
    }
}

task upload_file {
    String url
    String url_folder
    String experiment_name
    File file_to_be_uploaded

    command {
        # Change the command below to be the fullpath to upload_file.py
        python ./panorama-examples/cromwell/run-skyline/upload_file.py --url "${url}" --folder "${url_folder}" --experiment "${experiment_name}" --file-name "${file_to_be_uploaded}"
    }

    output {
        File upload_file_log = stdout()
    }
}

task run_skyline {
    File raw_file
    File skyline_template
    String run_name
 
    command {
        wine SkylineCmd --in="${skyline_template}" --import-file="${raw_file}" --save --share-zip="./${run_name}.sky.zip" --log-file="${run_name}.log"
        # ls -la ../input
        # cp "${raw_file}" "${run_name}.sky.zip" 
    }

    runtime {
        docker: "chambm/pwiz-skyline-i-agree-to-the-vendor-licenses:latest"
    }

    output {
        File sky_file = "${run_name}.sky.zip"
        File skyline_log = "${run_name}.log"
        #File skyline_log = stdout()
    }
}

