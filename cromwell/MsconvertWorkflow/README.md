This workflow will convert one or more RAW files using msconvert. The workflow will use cromwell's [local backend](https://cromwell.readthedocs.io/en/develop/backends/Local/). Each workflow tasks will be run in a Docker container.

This pipeline will 
1. Download RAW files to be converted from a folder on a Panorama Server
2. Download a file, which contains the msconvert configuration to be used during the conversion, from a folder on a Panorama Server
3. For each RAW file in the list the pipeline will 
   1. Download RAW file from the Panorama Server
   2. Convert RAW file using msconvert (using the configuration options specified in the downloaded config file)
   3. Upload converted file to the Panorama Server

**_NOTE_: This WDL file makes use of the Docker image [vagisha11/panorama-client-java](https://hub.docker.com/repository/docker/vagisha11/panorama-client-java) available on DockerHub.** 


# Inputs 
The following inputs are needed to run this workflow:
1. Panorama API key: The API key is a long, randomly generated token that provides an alternative authentication credential. It has the prefix "apikey|"
   1. To generate an API key, login to the Panorama server
   2. Click your username in the top right corner and select **Api Keys** from the menu
   3. Click **Generate API Key** and then click **Copy to Clipboard**. 
2. WebDAV URL of the MSConvert configuration file. 
   1. To get the WebDAV URL, open the **Admin** menu (gear icon in the top right) and select **Go To Module** > **File Content**. 
   2. In the files browser (also called the Files Web Part or FWP) check the box next to the template Skyline file (.sky extension)
   3. Right-click the **WebDav URL** at the bottom of the Files Web Part and select **Copy Link Address** from the menu
3. WebDAV URL of the folder on the Panorama server that contains the raw files (use the same steps listed above)
4. WebDAV URL of the folder on the Panorama server where the converted files will be uploaded. (use the same steps listed above)



# Run this workflow 


A template input JSON file is provided. To use it, edit the file and remove the .template extension. 


