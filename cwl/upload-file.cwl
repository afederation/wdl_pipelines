cwlVersion: v1.0
class: CommandLineTool

label: "Upload a file to a Panorama Server"

doc: |
      Documentation on how use download_file.py can be found here:
      https://github.com/uw-maccosslab/panorama-examples/tree/master/docker/panorama-files#using-the-docker-image

baseCommand: ["/bin/bash", "upload.sh"]

requirements:
    InlineJavascriptRequirement: {}
    InitialWorkDirRequirement:
        listing:
        - entryname: upload.sh
          entry: |-
            url=$(inputs.url)
            s=\${url#*//}
            echo "machine \${s%%/*} login $(inputs.user) password $(inputs.password) " > ~/.netrc
            python /maccoss/upload_file.py --url $(inputs.url) --folder $(inputs.url_folder) --experiment $(inputs.experiment_name) --file-name $(inputs.file_to_be_uploaded.path)
            rm ~/.netrc

    DockerRequirement:
        dockerPull: proteowizard/panorama-files:1.1

inputs:
    url:
        type: string
    url_folder: 
        type: string
    experiment_name: 
        type: string
    user:
        type: string
    password:
        type: string
    file_to_be_uploaded:
        type: File?


outputs: []

#stdout: $(inputs.url.split('/').slice(-1)[0])_download_file.log
