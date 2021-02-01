cwlVersion: v1.0
class: Workflow

label: "Convert RAW files using msconvert"

doc: |
      Documentation on how to use this workflow can be found here:
      https://github.com/uw-maccosslab/maccoss-tools/?????

requirements:
    ScatterFeatureRequirement: {}
    SubworkflowFeatureRequirement: {}

inputs:
    raw_file_list_url:
        type: string
    msconvert_config_url:
        type: string
    user:
        type: string
    password:
        type: string
    upload_url:
        type: string
    upload_url_folder: 
        type: string
    upload_experiment_name: 
        type: string
outputs: []
steps:
    download_raw_file_list:
        run: download-file.cwl
        in:
            user: user
            password: password
            url: raw_file_list_url
        out: [download_file_name]
    download_msconvert_config:
        run: download-file.cwl
        in:
            user: user
            password: password
            url: msconvert_config_url
        out: [download_file_name]
    read_raw_file_list:
        in:
            raw_file_list_url: raw_file_list_url
            raw_file_list_file: download_raw_file_list/download_file_name
        out: [raw_file_list]    
        run: 
            class: ExpressionTool
            requirements: 
                InlineJavascriptRequirement: {}
            inputs:
                raw_file_list_url: string
                raw_file_list_file: File
            outputs: 
                raw_file_list:
                    type:
                        type: array
                        items: string
            expression: 
                "${var url_base = inputs.raw_file_list_url.split('/').slice(-1)[0];
                var lines = inputs.raw_file_list_file.contents.split('\\n');
                var nblines = lines.length;
                var download_urls = [];
                for (var i = 0; i < nblines; i++) {
                    url = url_base + lines[i];
                    download_urls.push(url);
                }
                return download_urls;
                }"
    msconvert_workflow:
        in: 
            raw_file_url: read_raw_file_list/raw_file_list
            user: user
            password: password
            upload_url: upload_url
            upload_url_folder: upload_url_folder
            upload_experiment_name: upload_experiment_name
            msconvert_config_file: download_msconvert_config/download_file_name
        out: []
        scatter: raw_file_url
        run: msconvert_scatter.cwl
        





    


