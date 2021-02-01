This workflow will import a single RAW file into a Skyline document using the cromwell [local backend](https://cromwell.readthedocs.io/en/develop/backends/Local/). What this means is that it will execute the majority of the workflow tasks on your local workstation.

This pipeline will 
1. Download a RAW file and template Skyline document from PanoramaWeb
2. Using Skyline, import the RAW document into the Skyline document. Save the Skyline project as a zip file.
3. Upload the zip file to PanoramaWeb


## Requirements
In order to use run this workflow you will need to install the following on your workstation: 
- Cromwell
- Docker (to run Skyline)
- Python 3.6+

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

### Install Python 

There are many ways to install Python on your workstation. This documentation will show how to install Python using conda. If you do not want to use conda, you can 
- Download the latest Python 3 release from 
  - https://www.python.org/downloads/mac-osx/
  - https://www.python.org/downloads/windows/
- Installation instructions are at 
  - Windows: https://docs.python.org/3/using/windows.html
  - Mac: https://docs.python.org/3/using/mac.html


#### Install Python on a Mac workstation using conda 

The first step is to install miniconda on your workstation. Follow the instructions at https://conda.io/projects/conda/en/latest/user-guide/install/macos.html. 
- I recommend install `Miniconda` instead of `Anaconda`. 
- I recommend downloading the `Miniconda3 MacOSX 64-bit` installer
- Choose the default installation location  
  - This will install miniconda in the directory `~/miniconda`
- When asked `Do you wish the installer to initialize Miniconda3` answer no

The next step is to create a conda environment for Python. Open a new Terminal, first activate the conda base environment 

```
eval "$(/Users/bconn/miniconda3/bin/conda shell.bash hook)"
```

Now create the environment by running 

```
conda create --name maccoss-python3 python=3.7
```
Choose all the default answers when asked. 

Now that the environment is created, you can use it anytime by running 

```
$ conda activate maccoss-python3
```
To deactivate an active environment, use
```
$ conda deactivate
```

#### Install Python on a Windows workstation using conda 

The first step is to install miniconda on your workstation. Follow the instructions at https://conda.io/projects/conda/en/latest/user-guide/install/macos.html. 
- I recommend install `Miniconda` instead of `Anaconda`. 
- I recommend downloading the `Miniconda3 Windows 64-bit` installer
- Choose “just me” for installation type
- Choose the default installation location  
- Next, the installer is going to ask whether I want to do either of two things.
  - Add “Anaconda” to my “PATH” environment variable. It says not to do it right in the installer text, so I’m going to leave it un-checked.
  - Register “Anaconda” as my “default Python 3.7” environment. This comes checked, I recommend unchecking it
- When it says “Completed”, click “Next.”
- Uncheck the “learn more” boxes checked and click “Finish.”

To use conda the easiest way it to look at your “Start” menu, you may also notice a new folder called "Anaconda3 (64-bit)" with an icon beneath it called "Anaconda Prompt"

The next step is to create a conda environment for Python. Open the "Anaconda Prompt" application 

Now create the environment by running 

```
conda create --name maccoss-python3 python=3.7
```
Choose all the default answers when asked. 

Now that the environment is created, you can use it anytime by running 

```
$ conda activate maccoss-python3
```
To deactivate an active environment, use
```
$ conda deactivate
```


#### Install the required python packages 

To use this script, you will need to use install a number of Python packages. To install these packages activate the `maccoss-python3` conda environment and run 

```
pip install labkey
pip install awscli
pip install requests
```


### Setup .netrc 

This is required to download and upload the files from your Panorama server. A netrc file (.netrc or _netrc) is used to hold credentials necessary to login to your LabKey Server and authorize access to data stored there. The netrc file contains configuration and autologin information when using APIs. It may be used when working with SAS Macros, Transformation Scripts in Java or using the Rlabkey package.

To create the `.netrc` file, follow the instructions on the [Create a netrc file](https://www.labkey.org/Documentation/wiki-page.view?name=netrc) documentation. 


## Executing the workflow 

Edit the `import_single.wdl` and update the `download_run`, `download_file` and `upload_file` tasks. In each task update the command to use the full path for the python file. 

Verify the wdl is valid

```
java -jar PATH_TO_CROMWELL_JARS/womtool-47.jar validate import_single.wdl
```
If the wdl is valid you will see 
```
Success!
```

Create workflow inputs document by running 

```
java -jar PATH_TO_CROMWELL_JARS/womtool-47.jar inputs import_single.wdl  > import_single_inputs.json
```

Edit the newly receated inputs inputs document and enter in the variables values. See `import_single_inputs.json.sample` for an example of what the values should look like.

Run the workflow by running 

```
java -jar PATH_TO_CROMWELL_JARS/cromwell-47.jar run import_single.wdl -i import_single_inputs.json
```

When the workflow is executed a successful run will end with output similar to 

```log
[2020-01-10 11:04:20,72] [info] SingleWorkflowRunnerActor workflow finished with status 'Succeeded'.
{
  "outputs": {
    "import_raw_into_skyline.run_skyline.skyline_log": "/Users/bconn/Dropbox/maccoss/development/maccoss/maccoss-tools/wdl-pipelines/run-skyline-docker/cromwell-executions/import_raw_into_skyline/35a42618-0a91-48ce-992c-c9cee9bf7866/call-run_skyline/execution/Site20_STUDY9S_Cond_6ProtMix_QC_01.log",
    "import_raw_into_skyline.download_run.raw_file": "/Users/bconn/Dropbox/maccoss/development/maccoss/maccoss-tools/wdl-pipelines/run-skyline-docker/cromwell-executions/import_raw_into_skyline/35a42618-0a91-48ce-992c-c9cee9bf7866/call-download_run/execution/Site20_STUDY9S_Cond_6ProtMix_QC_01.RAW",
    "import_raw_into_skyline.download_run.download_file_log": "/Users/bconn/Dropbox/maccoss/development/maccoss/maccoss-tools/wdl-pipelines/run-skyline-docker/cromwell-executions/import_raw_into_skyline/35a42618-0a91-48ce-992c-c9cee9bf7866/call-download_run/execution/stdout",
    "import_raw_into_skyline.upload_file.upload_file_log": "/Users/bconn/Dropbox/maccoss/development/maccoss/maccoss-tools/wdl-pipelines/run-skyline-docker/cromwell-executions/import_raw_into_skyline/35a42618-0a91-48ce-992c-c9cee9bf7866/call-upload_file/execution/stdout",
    "import_raw_into_skyline.run_skyline.sky_file": "/Users/bconn/Dropbox/maccoss/development/maccoss/maccoss-tools/wdl-pipelines/run-skyline-docker/cromwell-executions/import_raw_into_skyline/35a42618-0a91-48ce-992c-c9cee9bf7866/call-run_skyline/execution/Site20_STUDY9S_Cond_6ProtMix_QC_01.sky.zip",
    "import_raw_into_skyline.download_skyline_template.download_file": "/Users/bconn/Dropbox/maccoss/development/maccoss/maccoss-tools/wdl-pipelines/run-skyline-docker/cromwell-executions/import_raw_into_skyline/35a42618-0a91-48ce-992c-c9cee9bf7866/call-download_skyline_template/execution/Study9S_Site20_v2.sky",
    "import_raw_into_skyline.download_skyline_template.download_file_log": "/Users/bconn/Dropbox/maccoss/development/maccoss/maccoss-tools/wdl-pipelines/run-skyline-docker/cromwell-executions/import_raw_into_skyline/35a42618-0a91-48ce-992c-c9cee9bf7866/call-download_skyline_template/execution/stdout"
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




