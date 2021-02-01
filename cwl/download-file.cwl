cwlVersion: v1.0
class: CommandLineTool

label: "Download a file from a Panorama Server"

doc: |
      Documentation on how use download_file.py can be found here:
      https://github.com/uw-maccosslab/panorama-examples/tree/master/docker/panorama-files#using-the-docker-image

baseCommand: ["/bin/bash", "download.sh"]

requirements:
    InlineJavascriptRequirement: {}
    InitialWorkDirRequirement:
        listing:
        - entryname: download.sh
          entry: |-
            url=$(inputs.url)
            s=\${url#*//}
            echo "machine \${s%%/*} login $(inputs.user) password $(inputs.password) " > ~/.netrc
            python /maccoss/download_file.py --url $(inputs.url)
            rm ~/.netrc
            pwd 
            ls -la 

    DockerRequirement:
        dockerPull: proteowizard/panorama-files:1.1

inputs:
    url:
        type: string
    user:
        type: string
    password:
        type: string


outputs:
    download_file_name:
        type: File
        outputBinding:
            glob: $(inputs.url.split('/').slice(-1)[0])

#stdout: $(inputs.url.split('/').slice(-1)[0])_download_file.log
