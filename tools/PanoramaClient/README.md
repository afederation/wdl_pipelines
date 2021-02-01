**PanoramaClient** is a Java client to upload and download files from a Panorama Server.  The client can also be used to upload and import a Skyline document to a Panorama server.
The main class is PanoramaClient.  There are 5 command-line usage modes:
1. Downloads a single file: `--download OR -d`
2. Download all files matching a file extension (optional) in a given folder: `--download_files OR -d`
3. List all the files matching a file extension (optional) in a given folder: `--list_files OR -l`
4. Upload a file to a folder: `--upload OR -u`
5. Upload and import a Skyline document in a folder: `--import_skydoc OR -i`

```
usage: [-a | -d | -i | -l | -u]
 -a,--download_files   Download files from a Panorama folder
 -d,--download         Download a file
 -i,--import_skydoc    Upload and import a Skyline document
 -l,--list_files       List files in a Panorama folder
 -u,--upload           Upload a file
```
Arguments for each usage mode can be found in the usage messages below. Optional arguments are in square brackets ```[]```.


Authentication with the Panorama server is done using an API key. 
The API key is a long, randomly generated token that provides an alternative authentication credential. 
It has the prefix "apikey|". To get this key login to the Panorama server and 
1. Click your username in the top right corner and select **Api Keys** from the menu
2. Click **Generate API Key** and then click **Copy to Clipboard**. 

If an API key is not provoded the client will attempt to look for login credentials in a `.netrc` file. For instructions on creating 
a `.netrc` file look at the documentation [Create a netrc file](https://www.labkey.org/Documentation/wiki-page.view?name=netrc).


### Download a single file
```
Download a file
usage: -d [-k <arg>] [-t <arg>] -w <arg>
 -k,--api_key <arg>              Panorama server API key
 -t,--dest_download_path <arg>   Destination download folder path
 -w,--webdav_url <arg>           WebDav URL of the file on the Panorama
                                 server
```

### Download all files matching a file extension (optional) in a given folder
```
Download files from a Panorama folder
usage: -a [-e <arg>] [-k <arg>] [-t <arg>] -w
       <arg>
 -e,--extension <arg>            File extension
 -k,--api_key <arg>              Panorama server API key
 -t,--dest_download_path <arg>   Destination download folder path
 -w,--webdav_url <arg>           WebDav URL of the folder on the Panorama
                                 server
```

### List all the files matching a file extension (optional) in a given folder
```
List files in a Panorama folder
usage: -l [-e <arg>] [-k <arg>] [-o <arg>] -w
       <arg>
 -e,--extension <arg>     File extension
 -k,--api_key <arg>       Panorama server API key
 -o,--output_file <arg>   Output file
 -w,--webdav_url <arg>    WebDav URL of the folder on the Panorama server
```

### Upload a file to a folder
```
Upload a file
usage: java -jar panoramaclient.jar -u -f <arg> -w <arg> [-k <arg>] [-c]
 -f,--source_file_path <arg>   Path of the file to be uploaded
 -w,--webdav_url <arg>         WebDav URL of the folder on the Panorama
                               server
 -k,--api_key <arg>            Panorama server API key
 -c,--create_dir               Create the target directory if it does not
                               exist
```

A **_WebDAV URL_** is required for downloading, uploading and getting a list of files in a folder on Panorama. 
Follow these steps to get the WebDAV URL of a file or folder on a Panorama server:
1. From the **Admin** menu (gear icon in the top right) select **Go To Module** > **File Content**. 
2. In the files browser (also called the Files Web Part or FWP) check the box next to file or folder of interest.
3. The WebDAV URL is displayed at the bottom of the Files Web Part. Right-click the URL and select the menu item to copy the 
link address. 
   1. **Copy Link Address** in Google Chrome
   2. **Copy Link Location** in Firefox
   
   
### Upload and import a Skyline document in a folder
```
Upload and import a Skyline document
usage: -i [-k <arg>] -p <arg> -s <arg>
 -k,--api_key <arg>               Panorama server API key
 -p,--panorama_folder_url <arg>   URL of the folder on the Panorama server
 -s,--skydoc_path <arg>           Path of the Skyline document to be
                                  uploaded and imported
```

The URL required for Skyline document upload and import is not a WebDAV URL. To get this URL navigate to the home page of the folder
where the document should be imported and simply copy the URL from the browser's address bar.

