cwlVersion: v1.0
class: Workflow
inputs: 
    raw_file_url: string
    user: string
    password: string
    upload_url: string
    upload_url_folder: string
    upload_experiment_name: string
    msconvert_config_file: File
outputs: []
steps:
    download_raw_file:
        run: download-file.cwl
        in:
            user: user
            password: password
            url: raw_file_url
        out: [download_file_name]
    msconvert:
        run: msconvert.cwl
        in:
            config_file: msconvert_config_file
            raw_file: download_raw_file/download_file_name
        out: [converted_file]
    upload_converted_file:
        run: upload-file.cwl
        in:
            user: user
            password: password
            url: upload_url
            url_folder: upload_url_folder
            experiment_name: upload_experiment_name
            file_to_be_uploaded: msconvert/converted_file
        out: []