Use this workflow to import raw files into a Skyline document and upload them to a Panorama server.
This workflow will
1. Download a template Skyline document (.sky file) from a Panorama server
2. Download raw files from a folder on a Panorama server
3. Import the raw files into the template Skyline document
4. Upload and import the Skyline document to a folder on a Panorama Server

The following inputs are needed to run this workflow:
1. Panorama API key: The API key is a long, randomly generated token that provides an alternative authentication credential. It has the prefix "apikey|"
   1. To generate an API key, login to the Panorama server
   2. Click your username in the top right corner and select **Api Keys** from the menu
   3. Click **Generate API Key** and then click **Copy to Clipboard**. 
2. WebDAV URL of the Skyline template file. 
   1. To get the WebDAV URL, open the **Admin** menu (gear icon in the top right) and select **Go To Module** > **File Content**. 
   2. In the files browser (also called the Files Web Part or FWP) check the box next to the template Skyline file (.sky extension)
   3. Right-click the **WebDav URL** at the bottom of the Files Web Part and select **Copy Link Address** from the menu
3. WebDAV URL of the folder on the Panorama server that contains the raw files (use the same steps listed above)
4. The URL of the folder on the Panorama server where the final Skyline document should be uploaded.  Navigate to the home page of the folder and simply copy the URL from the browser's address bar.
5. The file extension of the raw data files, e.g. one of RAW, mzXML, mzXML.

A template input JSON file is provided. To use it, edit the file and remove the .template extension. 

**_NOTE_: This WDL file makes use of the Docker image [vagisha11/panorama-client-java](https://hub.docker.com/repository/docker/vagisha11/panorama-client-java) available on DockerHub.** 
