[Cromwell](https://cromwell.readthedocs.io/en/stable/) workflows written in the [Workflow Description Language](https://github.com/openwdl/wdl#getting-started-with-wdl) (WDL).
Each folder contains a different workflow.


# Running these workflows on M002 in MacCoss Lab 

How to Use the Cromwell workflow/pipeline

## Supported workflows 
----
### Msconvert: 
This workflow will convert all RAW files in a PanoramaWeb folder using msconvert. The workflow details are 
 
1. Create a list of RAW files in the PanoramaWeb folder
2. Download a file which contains the msconvert configuration to be used during the conversion.
3. For each file in #1
   1. Download RAW file
   2. Convert RAW file using msconvert
   3. Upload converted file.
4. Log files for each step in the workflow will be uploaded


### PanoramaSkyline
Import one or more RAW files into a Skyline document with cromwell and upload the document to a Panorama server. The workflow details are

1. Download RAW files and a template Skyline document from a Panorama server.
2. Using Skyline, import the RAW file(s) into the Skyline document. Save the Skyline document as a shared zip file.
3. Upload the zip file to PanoramaWeb and queue a document import job
   1. File will be uploaded to a subdirectory in the same folder where the RAW files are located
4. Log files for each step in the workflow will be uploaded



## Run Msconvert workflow using web-base UI
----
*Still in development. Check back soon*

## Run Msconvert workflow via command line 
----
To run the msconvert workflow via the command line, you will need to ssh into the server named panoramaweb.gs.washington.edu.

### How to SSH into panoramaweb

See https://wikisrv.gs.washington.edu/twiki/bin/view/Main/SshUsage for more information.  **Improved instructions are coming**


### Setup your working directories on panoramaweb 
In your home directory, create a new directory named `cromwell` and a directory to hold your workflow files. Run the commands below:

*This is a one-time configuration. If you previously created these directories, skip to the next section*

```
mkdir ~/cromwell
mkdir ~/cromwell/msconvert
```


### Create the msconvert workflow inputs files.
To run this workflow, you will need to create what is called an inputs file. You can think of the inputs as the variables for this workflow run. The first step is to create the inputs file. You will have a different inputs file for each set of RAW files that you process. This means the inputs file name should be unique. One option is to include the PanoramaWeb folder name in the name of the inputs file. For example, if your RAW files are located in the PanoramaWeb folder https://panoramaweb.org/home/Example%20Data/Workflow/project-begin.view?, then the will name the file 

```
msconvert_example_data_workflow_inputs.json
```

Below is an example inputs file. Copy the JSON below into the newly created file 
```
{
    "msconvert_workflow.url_webdav_raw_files_folder": "<Webdav URL of folder on Panorama that has raw files>",
    "msconvert_workflow.url_webdav_msconvert_config": "<Webdav URL of msconvert config file>",
    "msconvert_workflow.panorama_apikey": "<Panorama API key>",
    "msconvert_workflow.url_webdav_converted_files_folder": "<Webdav URL of folder on Panorama that where converted files will be uploaded>"
}
```

The next step is enter the input value for each variable.

#### PanoramaWeb folder which contains the RAW files. 
This input is named `msconvert_workflow.url_webdav_raw_files_folder`. You will need to find the WebDAV URL for this folder. To find the URL, you will do the following:

For the sake of this documentation, lets assume your RAW files are stored in the folder, https://panoramaweb.org/home/Example%20Data/Workflow/project-begin.view?. To find the WebDAV URL, you will 

1. Log into PanoramaWeb and goto the folder which contains the RAW files.
2. open the **Admin** menu (gear icon in the top right) and select **Go To Module** > **File Content**.
3. Right-click the **WebDav URL** at the bottom of the Files Web Part and select **Copy Link Address** from the menu

Open the inputs file and replace `<Webdav URL of folder on Panorama that has raw files>` with the copied URL.

**Note: This workflow will convert all RAW files in this folder**


#### msconvert configuration file 
The next input will be the URL of a [msconvert](http://proteowizard.sourceforge.net/tools/msconvert.html) configuration file. 

##### What is a msconvert configuration file? 
Each msconvert command line option can be specifed in a configuration file. Below is an example configuration file 

```
mzML=true
simAsSpectra=true
filter="peakPicking vendor msLevel=1-"
filter="demultiplex massError=10.0ppm optimization=overlap_only"
```

##### Create the configuration file
On your workstation, create the msconvert configuration file for your workflow run. Add each msconvert option to a new line in the file. If you are using multiple filters, enter each filter on it's own line. 


##### Upload the configuration file to PanoramaWeb
Using your browser, upload the configuration file to PanoramaWeb. You can upload the configuation file to the same folder as the RAW files or to a different one.

**Note: if you are using the same msconvert configuration settings as other runs, there is no need to upload a configuration file for each run, simply use the URL for a previously uploaded file**

Once the file has been uploaded, you will need to find the WebDAV URL for the file: 
1. In the files browser (also called the Files Web Part or FWP) check the box next to the uploaded file
2. Right-click the **WebDav URL** at the bottom of the Files Web Part and select **Copy Link Address** from the menu

Open the inputs file and replace `<Webdav URL of msconvert config file>` with the copied URL.



##### PanoramaWeb folder where converted files will be uploaded 
This input is named `msconvert_workflow.url_webdav_converted_files_folder`. In most cases, I recommend using the same WebDAV URL as the `msconvert_workflow.url_webdav_raw_files_folder` input. 

If you decide to upload to a different folder, then you will need to find the WebDAV URL for this folder. To find the URL, you will do the following:

For the sake of this documentation, lets assume your RAW files are stored in the folder, https://panoramaweb.org/home/Example%20Data/Workflow/project-begin.view?. To find the WebDAV URL, you will 

1. Log into PanoramaWeb and goto the folder which contains the RAW files.
2. open the **Admin** menu (gear icon in the top right) and select **Go To Module** > **File Content**.
3. Right-click the **WebDav URL** at the bottom of the Files Web Part and select **Copy Link Address** from the menu

Open the inputs file and replace `<Webdav URL of folder on Panorama that where converted files will be uploaded>` with the copied URL.


##### PanoramaWeb API Key
The API key is a long, randomly generated token that provides an alternative authentication credential. It has the prefix "apikey|"
1. To generate an API key, login to the Panorama server
2. Click your username in the top right corner and select **Api Keys** from the menu
3. Click **Generate API Key** and then click **Copy to Clipboard**. 

Open the inputs file and replace `<Panorama API key>` with the copied API Key.


### Run the workflow

To run the workflow, you will first need to setup your environment on PanoramaWeb. To setup your environment, you will run 

```
cd ~/cromwell/msconvert
source /net/maccoss/vol1/maccoss_shared/bdconnol/pipelines/submitSetup.sh
```


To run the workflow, cut and paste the command below: 

```
python /net/maccoss/vol1/maccoss_shared/bdconnol/pipelines/submitWorkflow.py --workflow /net/maccoss/vol1/maccoss_shared/bdconnol/pipelines/MsconvertWorkflow/workflow.wdl --inputs ./<inputs-file-name> --name <run-name>
```
Change 
- `<inputs-file-name>` to be the name of the file you created above
- `<run-name>` is the name of the run.
  - A new subdirectory will be created, with this name, which will contain the log files and converted files. 
  - I recommend using a name to describe msconvert settings that were used. 


As the workflow is executed, the script will output the status to the screen. You will see something like 

```
2020-07-13 16:05:58,692: INFO: The workflow was successfully submitted to Cromwell server
2020-07-13 16:05:58,692: INFO: The workflow id is 12795b6f-ab58-40c9-a9f2-7baa616b722d
2020-07-13 16:05:58,694: INFO: Create directory for logs and outputs: cromwell-12795b6f-ab58-40c9-a9f2-7baa616b722d-logs
2020-07-13 16:05:58,835: INFO: Waiting for workflow to be available on server...
2020-07-13 16:06:03,862: INFO: Workflow status is Submitted
2020-07-13 16:06:08,887: INFO: Workflow status is Submitted
2020-07-13 16:06:13,911: INFO: Workflow status is Submitted
2020-07-13 16:06:18,934: INFO: Workflow status is Submitted
2020-07-13 16:06:23,962: INFO: Workflow status is Running
2020-07-13 16:06:28,987: INFO: Workflow status is Running
2020-07-13 16:06:34,013: INFO: Workflow status is Running
2020-07-13 16:06:39,038: INFO: Workflow status is Running
2020-07-13 16:06:44,078: INFO: Workflow status is Running
2020-07-13 16:06:49,110: INFO: Workflow status is Succeeded
2020-07-13 16:06:49,111: INFO: Workflow has successfully completed
2020-07-13 16:06:49,581: INFO: Creating the workflow execution log...
2020-07-13 16:06:49,583: INFO: Collect log messages for call msconvert_workflow.download_raw_file-0
2020-07-13 16:06:54,558: INFO: Collect log messages for call msconvert_workflow.download_raw_file-1
2020-07-13 16:06:55,565: INFO: Collect log messages for call msconvert_workflow.download_raw_file-2
2020-07-13 16:06:56,570: INFO: Collect log messages for call msconvert_workflow.upload_file-0
2020-07-13 16:06:57,582: INFO: Collect log messages for call msconvert_workflow.upload_file-1
2020-07-13 16:06:58,610: INFO: Collect log messages for call msconvert_workflow.upload_file-2
2020-07-13 16:06:59,640: INFO: Collect log messages for call msconvert_workflow.msconvert-0
2020-07-13 16:07:00,668: INFO: Collect log messages for call msconvert_workflow.msconvert-1
2020-07-13 16:07:01,701: INFO: Collect log messages for call msconvert_workflow.msconvert-2
2020-07-13 16:07:02,740: INFO: Collect log messages for call msconvert_workflow.download_msconvert_config
2020-07-13 16:07:03,852: INFO: Collect log messages for call msconvert_workflow.list_raw_files
2020-07-13 16:07:04,899: INFO: Uploading workflow log files to https://panoramaweb.org/_webdav/00Developer/bdconnoll/cromwell/%40files/
2020-07-13 16:07:05,171: INFO: Create new directory, 'default2', in PanoramaWeb folder https://panoramaweb.org/_webdav/00Developer/bdconnoll/cromwell/%40files/
2020-07-13 16:07:05,362: INFO: Upload log file, 'workflow-submit.log', to PanoramaWeb
2020-07-13 16:07:05,461: INFO: Upload log file, 'workflow.wdl', to PanoramaWeb
2020-07-13 16:07:05,577: INFO: Upload log file, 'workflow_inputs.json', to PanoramaWeb
2020-07-13 16:07:05,655: INFO: Upload log file, 'workflow-execution.log', to PanoramaWeb
2020-07-13 16:07:05,773: INFO: All files uploaded to PanoramaWeb. Removing temporary directory 'cromwell-12795b6f-ab58-40c9-a9f2-7baa616b722d-logs'
```

When the workflow run is complete, all files and workflow logs will have been uploaded to a directory named `<run-name>` in the folder specified in the `msconvert_workflow.url_webdav_converted_files_folder` input.








## Run PanoramaSkyline workflow using web-base UI
----
*Still in development. Check back soon*

## Run PanoramaSkyline workflow via command line 
----
To run the PanoramaSkyline workflow via the command line, you will need to ssh into the server named panoramaweb.gs.washington.edu.

### How to SSH into panoramaweb

See https://wikisrv.gs.washington.edu/twiki/bin/view/Main/SshUsage for more information.  **Improved instructions are coming**


### Setup your working directories on panoramaweb 
In your home directory, create a new directory named `cromwell` and a directory to hold your workflow files. Run the commands below:

*This is a one-time configuration. If you previously created these directories, skip to the next section*

```
mkdir ~/cromwell
mkdir ~/cromwell/panorama_skyline
```


### Create the PanoramaSkyline workflow inputs files.
To run this workflow, you will need to create what is called an inputs file. You can think of the inputs as the variables for this workflow run. The first step is to create the inputs file. You will have a different inputs file for each set of RAW files that you process. This means the inputs file name should be unique. One option is to include the PanoramaWeb folder name in the name of the inputs file. For example, if your RAW files are located in the PanoramaWeb folder https://panoramaweb.org/home/Example%20Data/Workflow/project-begin.view?, then the will name the file 

```
panoramaskyline_example_data_workflow_inputs.json
```

Below is an example inputs file. Copy the JSON below into the newly created file 
```json
{
  "panorama_skyline_workflow.panorama_apikey": "<Panorama API key>",
  "panorama_skyline_workflow.url_webdav_skyline_template": "<Webdav URL of template .sky file>",
  "panorama_skyline_workflow.url_webdav_raw_files_folder": "<Webdav URL of folder on Panorama that has raw files>",
  "panorama_skyline_workflow.url_target_panorama_folder": "<URL of Panorama folder where the final .sky.zip will be uploaded>"
}
```

The next step is enter the input value for each variable.

#### PanoramaWeb folder which contains the RAW files. 
This input is named `panorama_skyline_workflow.url_webdav_raw_files_folder`. You will need to find the WebDAV URL for this folder. To find the URL, you will do the following:

For the sake of this documentation, lets assume your RAW files are stored in the folder, https://panoramaweb.org/home/Example%20Data/Workflow/project-begin.view?. To find the WebDAV URL, you will 

1. Log into PanoramaWeb and goto the folder which contains the RAW files.
2. open the **Admin** menu (gear icon in the top right) and select **Go To Module** > **File Content**.
3. Right-click the **WebDav URL** at the bottom of the Files Web Part and select **Copy Link Address** from the menu

Open the inputs file and replace `<Webdav URL of folder on Panorama that has raw files>` with the copied URL.

**Note: This workflow will import all RAW files in this folder**


#### Webdav URL for Skyline template document 
This input is named `panorama_skyline_workflow.url_webdav_skyline_template`. You will need to find the WebDAV URL for this folder. To find the URL, you will do the following:

For the sake of this documentation, lets assume your RAW files are stored in the folder, https://panoramaweb.org/home/Example%20Data/Workflow/project-begin.view?. To find the WebDAV URL, you will 

1. Log into PanoramaWeb and goto the folder which contains the Skyline template document.
2. open the **Admin** menu (gear icon in the top right) and select **Go To Module** > **File Content**.
3. In the files browser (also called the Files Web Part or FWP) check the box next to the uploaded file
4. Right-click the **WebDav URL** at the bottom of the Files Web Part and select **Copy Link Address** from the menu

Open the inputs file and replace `<Webdav URL of template .sky file>` with the copied URL.

**Note: This workflow will convert all RAW files in this folder**


##### PanoramaWeb folder where converted files will be uploaded 
This input is named `panorama_skyline_workflow.url_target_panorama_folder`. 

If you decide to upload to a different folder, then you will need to find the WebDAV URL for this folder. To find the URL, you will do the following:

For the sake of this documentation, lets assume you would like to import the Skyline document into the folder, https://panoramaweb.org/home/Example%20Data/Workflow/project-begin.view?. 

Open the inputs file and replace `<URL of Panorama folder where the final .sky.zip will be uploaded>` with the URL.


##### PanoramaWeb API Key
The API key is a long, randomly generated token that provides an alternative authentication credential. It has the prefix "apikey|"
1. To generate an API key, login to the Panorama server
2. Click your username in the top right corner and select **Api Keys** from the menu
3. Click **Generate API Key** and then click **Copy to Clipboard**. 

Open the inputs file and replace `<Panorama API key>` with the copied API Key.


### Run the workflow

To run the workflow, you will first need to setup your environment on PanoramaWeb. To setup your environment, you will run 

```
cd ~/cromwell/panorama_skyline
source /net/maccoss/vol1/maccoss_shared/bdconnol/pipelines/submitSetup.sh
```


To run the workflow, cut and paste the command below: 

```
python /net/maccoss/vol1/maccoss_shared/bdconnol/pipelines/submitWorkflow.py --workflow /net/maccoss/vol1/maccoss_shared/bdconnol/pipelines/PanoramaSkylineWorkflow/workflow.wdl --inputs ./<inputs-file-name> --name <run-name>
```
Change 
- `<inputs-file-name>` to be the name of the file you created above
- `<run-name>` is the name of the run.
  - A new subdirectory will be created, with this name, which will contain the log files and converted files. 


As the workflow is executed, the script will output the status to the screen. You will see something like 

```
2020-07-13 16:05:58,692: INFO: The workflow was successfully submitted to Cromwell server
2020-07-13 16:05:58,692: INFO: The workflow id is 12795b6f-ab58-40c9-a9f2-7baa616b722d
2020-07-13 16:05:58,694: INFO: Create directory for logs and outputs: cromwell-12795b6f-ab58-40c9-a9f2-7baa616b722d-logs
2020-07-13 16:05:58,835: INFO: Waiting for workflow to be available on server...
2020-07-13 16:06:03,862: INFO: Workflow status is Submitted
2020-07-13 16:06:08,887: INFO: Workflow status is Submitted
2020-07-13 16:06:13,911: INFO: Workflow status is Submitted
2020-07-13 16:06:18,934: INFO: Workflow status is Submitted
2020-07-13 16:06:23,962: INFO: Workflow status is Running
2020-07-13 16:06:28,987: INFO: Workflow status is Running
2020-07-13 16:06:34,013: INFO: Workflow status is Running
2020-07-13 16:06:39,038: INFO: Workflow status is Running
2020-07-13 16:06:44,078: INFO: Workflow status is Running
2020-07-13 16:06:49,110: INFO: Workflow status is Succeeded
2020-07-13 16:06:49,111: INFO: Workflow has successfully completed
2020-08-07 13:21:10,540: INFO: Workflow has successfully completed
2020-08-07 13:21:10,914: INFO: Creating the workflow execution log...
2020-08-07 13:21:10,916: INFO: Collect log messages for call panorama_skyline_workflow.list_raw_files
2020-08-07 13:21:12,577: INFO: Collect log messages for call panorama_skyline_workflow.download_raw_file-0
2020-08-07 13:21:13,604: INFO: Collect log messages for call panorama_skyline_workflow.download_raw_file-1
2020-08-07 13:21:14,621: INFO: Collect log messages for call panorama_skyline_workflow.download_raw_file-2
2020-08-07 13:21:15,600: INFO: Collect log messages for call panorama_skyline_workflow.download_skyline_template
2020-08-07 13:21:16,594: INFO: Collect log messages for call panorama_skyline_workflow.upload_and_import_skyzip
2020-08-07 13:21:17,608: INFO: Collect log messages for call panorama_skyline_workflow.skyline_import_raw
2020-08-07 13:21:18,623: INFO: Uploading workflow log files to https://panoramaweb.org/_webdav//00Developer/bdconnoll/cromwell/PanoramaSkyline/@files/
2020-08-07 13:21:18,731: INFO: Upload log file, 'workflow-submit.log', to PanoramaWeb
2020-08-07 13:21:18,817: INFO: Upload log file, 'workflow.wdl', to PanoramaWeb
2020-08-07 13:21:18,904: INFO: Upload log file, 'workflow_inputs.json', to PanoramaWeb
2020-08-07 13:21:19,020: INFO: Upload log file, 'workflow-execution.log', to PanoramaWeb
2020-08-07 13:21:19,115: INFO: All files uploaded to PanoramaWeb.Removing temporary directory 'cromwell-a157b893-5fb1-4fd8-ad89-b9941afa05bc-logs'
2020-08-07 12:34:05,087: INFO: Workflow logs and other files have been uploaded to https://panoramaweb.org/00Developer/bdconnoll/cromwell/PanoramaSkyline/project-begin.view?
2020-08-07 12:34:05,087: INFO: The workflow execution log can be viewed at https://panoramaweb.org/00Developer/bdconnoll/cromwell/PanoramaSkyline/project-begin.view?/workflow-execution.log
```

When the workflow run is complete, all files and workflow logs will have been uploaded to a directory named `<run-name>` in the folder specified in the `msconvert_workflow.url_webdav_converted_files_folder` input.




# Running the workflow from your workstation via command-line

### Setup 

Install the following: 
- Cromwell

#### Install Cromwell 
Cromwell is easy to install. It is shipped as number of JAR files.  To install all you need to do is 

1. Download 
   1. Goto https://github.com/broadinstitute/cromwell/releases/latest
   2. Download `cromwell-XX.jar` and `womtool-XX.jar`
2. Copy the download jar files into a directory in your home directory. 
   1. I used `~/bin/cromwell/`

#### Install Java JRE
Cromwell's documentation says Java 8 is required. Not sure if that means newer ones are supported. I ran these scripts with JAVA-8. You will need to install the JRE on your workstation. Cromwell's documentation says to install https://www.oracle.com/technetwork/java/javase/overview/java8-2100321.html


#### Create a SSH-Tunnel to access m002.grid.gs.washington.edu
The MacCoss cromwell server, m002, is running in the Genome Sciences datacenter and is not available from the lab or outside the UW. To run a workflow on this server you will need to create a SSH tunnel through the server nexus. 

If you are running at Mac, the first thing to do is open the Terminal app. Once it is open run the following command 

```
ssh -L 8000:m002.grid.gs.washington.edu:8000 nexus.gs.washington.edu
```

If you are running a Windows workstation, you will need to use Putty. 

1. Launch PuTTY and enter the hostname `nexus.gs.washington.edu` and port. Port should be set to 22
2. On the left side, in the Category window, go to Connection -> SSH -> Tunnels.
3. For 'Source Port' enter `8000` (this can be configured to whatever you want, just remember it).
4. Under 'Destination' enter `m002.gs.washington.edu:8000` 
5. Press the 'Add' button.  You should see 'L8000' in the 'Forwarded ports:' box.
6. Then select the 'Open' button.  This should open and terminal window and you should be prompted to login.


### Submitting a workflow 

To submit the workflow to the m002 server the first step is to change to the directory where the Workflow WDL file is located 

```
cd <WORKFLOW DIR>
~/bin/java/bin/java -jar ~/bin/cromwell/cromwell-47.jar submit workflow.wdl -i workflow_inputs.json -h http://127.0.0.1:8000 -t wdl
```

You will see output similar to 
```
[2020-06-12 09:20:30,25] [info] Slf4jLogger started
[2020-06-12 09:20:32,13] [info] Workflow c5dc1674-c120-4c42-94b9-e580db7b8458 submitted to http://127.0.0.1:8000
```
where `c5dc1674-c120-4c42-94b9-e580db7b8458` is the id of the workflow

Query the status of the workflow by running 

```
curl -q -X GET "http://127.0.0.1:8000/api/workflows/v1/c5dc1674-c120-4c42-94b9-e580db7b8458/status" -H  "accept: application/json"
{"status":"Succeeded","id":"c5dc1674-c120-4c42-94b9-e580db7b8458"}%
```



## Requirements to run these workflows on your workstation
Install the following: 
- Cromwell
- Docker

### Install Cromwell 
Cromwell is easy to install. It is shipped as number of JAR files.  To install all you need to do is 

1. Download 
   1. Goto https://github.com/broadinstitute/cromwell/releases/latest
   2. Download `cromwell-XX.jar` and `womtool-XX.jar`
2. Copy the download jar files into a directory in your home directory. 
   1. I used `~/bin/cromwell/`

### Install Java JRE
Cromwell's documentation says Java 8 is required. Not sure if that means newer ones are supported. I ran these scripts with JAVA-8. You will need to install the JRE on your workstation. Cromwell's documentation says to install https://www.oracle.com/technetwork/java/javase/overview/java8-2100321.html

### Install Docker 
Install docker on your workstation
- Mac: https://docs.docker.com/docker-for-mac/install/
- Windows: https://docs.docker.com/docker-for-windows/install/

Contact me if you need help installing or using the Docker on your workstation.

### Setup .netrc 

This is required to download and upload the files from your Panorama server. A netrc file (.netrc or _netrc) is used to hold credentials necessary to login to your LabKey Server and authorize access to data stored there. The netrc file contains configuration and autologin information when using APIs. It may be used when working with SAS Macros, Transformation Scripts in Java or using the Rlabkey package.

To create the `.netrc` file, follow the instructions on the [Create a netrc file](https://www.labkey.org/Documentation/wiki-page.view?name=netrc) documentation. 


## Executing the workflow 

Verify the wdl is valid

```
java -jar PATH_TO_CROMWELL_JARS/womtool-47.jar validate workflow.wdl
```
If the wdl is valid you will see 
```
Success!
```

Create workflow inputs document by running 

```
java -jar PATH_TO_CROMWELL_JARS/womtool-47.jar inputs workflow.wdl  > workflow_inputs.json
```

Edit the newly receated inputs document and enter in the variables values. See `workflow_inputs.json.sample` for an example of what the values should look like.

Run the workflow by running 

```
java -jar PATH_TO_CROMWELL_JARS/cromwell-47.jar run workflow.wdl -i workflow_inputs.json
```

When the workflow is executed a successful run will end with output similar to 

```log
[2020-01-10 11:04:20,72] [info] SingleWorkflowRunnerActor workflow finished with status 'Succeeded'.
{
  "outputs": {
  ...
  },
  "id": "35a42618-0a91-48ce-992c-c9cee9bf7866"
}
[2020-01-10 11:04:23,05] [info] Workflow polling stopped
[2020-01-10 11:04:23,08] [info] 0 workflows released by cromid-d30c3d6
[2020-01-10 11:04:23,08] [info] Shutting down WorkflowStoreActor - Timeout = 5 seconds
[2020-01-10 11:04:23,08] [info] Shutting down WorkflowLogCopyRouter - Timeout = 5 seconds
[2020-01-10 11:04:23,09] [info] Shutting down JobExecutionTokenDispenser - Timeout = 5 seconds
[2020-01-10 11:04:23,09] [info] JobExecutionTokenDispenser stopped
[2020-01-10 11:04:23,10] [info] Aborting all running workflows.
[2020-01-10 11:04:23,10] [info] WorkflowStoreActor stopped
[2020-01-10 11:04:23,10] [info] WorkflowLogCopyRouter stopped
[2020-01-10 11:04:23,10] [info] Shutting down WorkflowManagerActor - Timeout = 3600 seconds
[2020-01-10 11:04:23,10] [info] WorkflowManagerActor All workflows finished
[2020-01-10 11:04:23,10] [info] WorkflowManagerActor stopped
[2020-01-10 11:04:23,31] [info] Connection pools shut down
[2020-01-10 11:04:23,31] [info] Shutting down SubWorkflowStoreActor - Timeout = 1800 seconds
[2020-01-10 11:04:23,31] [info] Shutting down JobStoreActor - Timeout = 1800 seconds
[2020-01-10 11:04:23,31] [info] Shutting down CallCacheWriteActor - Timeout = 1800 seconds
[2020-01-10 11:04:23,31] [info] SubWorkflowStoreActor stopped
[2020-01-10 11:04:23,32] [info] Shutting down ServiceRegistryActor - Timeout = 1800 seconds
[2020-01-10 11:04:23,32] [info] Shutting down DockerHashActor - Timeout = 1800 seconds
[2020-01-10 11:04:23,32] [info] Shutting down IoProxy - Timeout = 1800 seconds
[2020-01-10 11:04:23,32] [info] CallCacheWriteActor Shutting down: 0 queued messages to process
[2020-01-10 11:04:23,32] [info] JobStoreActor stopped
[2020-01-10 11:04:23,32] [info] CallCacheWriteActor stopped
[2020-01-10 11:04:23,32] [info] KvWriteActor Shutting down: 0 queued messages to process
[2020-01-10 11:04:23,32] [info] WriteMetadataActor Shutting down: 0 queued messages to process
[2020-01-10 11:04:23,32] [info] IoProxy stopped
[2020-01-10 11:04:23,32] [info] ServiceRegistryActor stopped
[2020-01-10 11:04:23,33] [info] DockerHashActor stopped
[2020-01-10 11:04:23,34] [info] Shutting down connection pool: curAllocated=0 idleQueues.size=0 waitQueue.size=0 maxWaitQueueLimit=256 closed=false
[2020-01-10 11:04:23,34] [info] Shutting down connection pool: curAllocated=0 idleQueues.size=0 waitQueue.size=0 maxWaitQueueLimit=256 closed=false
[2020-01-10 11:04:23,34] [info] Shutting down connection pool: curAllocated=0 idleQueues.size=0 waitQueue.size=0 maxWaitQueueLimit=256 closed=false
[2020-01-10 11:04:23,34] [info] Shutting down connection pool: curAllocated=0 idleQueues.size=0 waitQueue.size=0 maxWaitQueueLimit=256 closed=false
[2020-01-10 11:04:23,36] [info] Database closed
[2020-01-10 11:04:23,36] [info] Stream materializer shut down
[2020-01-10 11:04:23,36] [info] WDL HTTP import resolver closed
```

If the run succeeds or fails you can review the logs from in the directory `./cromwell-executions/WORKFLOW-RUN-ID/WORKFLOW-CALL-NAME/`. This directory will contain all scripts run in the step. It will contains the output, logs and output files. This makes for easy debugging, however it means that any files with sensitive information in them will not be purged automatically. This is problem and needs to be investigated 
