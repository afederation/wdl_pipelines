cwlVersion: v1.0
class: CommandLineTool

label: "Convert RAW file"

doc: |
      Run msconvert to transform a RAW file to different format

baseCommand: ["wine", "msconvert"]

requirements:
    InlineJavascriptRequirement: {}
    DockerRequirement:
        dockerPull: chambm/pwiz-skyline-i-agree-to-the-vendor-licenses:latest

inputs:
    raw_file:
        type: File
        inputBinding:
            position: 1
    config_file:
        type: File
        inputBinding:
            prefix: -c 
            separate: true
            position: 2


outputs:
    converted_file: 
        type: File
        outputBinding:
            glob: $(inputs.raw_file.basename.split('.')[0]).*

