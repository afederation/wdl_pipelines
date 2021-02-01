This workflow will run Comet and Perculator on mzML files and upload the results to Limelight. Each workflow tasks will be run in a Docker container.

This pipeline will 
1. Download fasta file from a folder on a Panorama Server
2. Download list of sample files from a folder on a Panorama Server
3. For each file in the list the pipeline will
   1. Download sample file from the Panorama Server
   2. Perform a comet search using crux
   3. Run percolator, using crux, on the comet search results
   4. Convert percolator and comet results to limelight format
   5. Import the limelight results into the limelight server
   6. Upload result files from comet, percolator and limelight to a folder on a Panorama Server

**_NOTE_: This WDL file makes use of a number of Docker images which are available on Dockerhub
- [proteowizard/panorama-client-java](https://hub.docker.com/repository/docker/proteowizard/panorama-client-java)
  - Dockerfile is located in https://github.com/uw-maccosslab/pipelines/docker/PanoramaClient
- [proteowizard/panorama-crux](https://hub.docker.com/repository/docker/proteowizard/panorama-crux)
  - Dockerfile is located in https://github.com/uw-maccosslab/pipelines/docker/panorama-crux
- [proteowizard/panorama-limelight](https://hub.docker.com/repository/docker/proteowizard/panorama-limelight)
  - Dockerfile is located in https://github.com/uw-maccosslab/pipelines/docker/panorama-limelight


# Inputs 
The following inputs are needed to run this workflow:
1. Panorama API key: The API key is a long, randomly generated token that provides an alternative authentication credential. It has the prefix "apikey|"
   1. To generate an API key, login to the Panorama server
   2. Click your username in the top right corner and select **Api Keys** from the menu
   3. Click **Generate API Key** and then click **Copy to Clipboard**. 
2. WebDAV URL of the Fasta file. 
   1. To get the WebDAV URL, open the **Admin** menu (gear icon in the top right) and select **Go To Module** > **File Content**. 
   2. In the files browser (also called the Files Web Part or FWP) check the box next to the template Skyline file (.sky extension)
   3. Right-click the **WebDav URL** at the bottom of the Files Web Part and select **Copy Link Address** from the menu
3. WebDAV URL of the folder on the Panorama server that contains the sample files (use the same steps listed above)
4. WebDAV URL of the folder on the Panorama server where the converted files will be uploaded. (use the same steps listed above)
5. Extension of the input files. At this time, only `mzML` files have been tested
6. URL for Limelight server
7. Limelight project identifier
8. Limelight user key


# Run this workflow 


A template input JSON file is provided. To use it, edit the file and remove the .template extension. 
