This workflow will convert one or more RAW files using msconvert. The workflow will use cromwell's [local backend](https://cromwell.readthedocs.io/en/develop/backends/Local/). Each workflow tasks will be run in a Docker container running on your local workstation.

This pipeline will 
1. Download a list of RAW files to be converted from a folder on a Panorama Server
2. Download a file, which contains the msconvert configuration to be used during the conversion, from a folder on a Panorama Server
3. For each RAW file in the list the pipeline will 
   1. Download RAW file from the Panorama Server
   2. Convert RAW file using msconvert (using the configuration options specified in the downloaded config file)
   3. Upload converted file to the Panorama Server


Assumptions: 
1. The list of RAW files will be written in a text file, with 1 file per line
2. Directory structure of files on Panorama Server: (It will be easier to describe if we use an example. For this doc, we will working in the folder `00Developer/bdconnoll/cromwell`, which means the URL to Files is https://panoramaweb.org/00Developer/bdconnoll/cromwell/filecontent-begin.view 
   - The file which contains the list of RAW files must be in the same directory, in the fileroot, as RAW files. They can be at the root of the FileRoot or in a subdirectory. 
   - The msconvert configuration file can be stored in any location on the Panorama Server
   - The converted files will uploaded the same directory as the RAW files, unless the "outdir" variable is specified in the msconvert configuration file. 
     - If the "outdir" variable is specified, then the converted files will be stored in the directory "outdir" relative to the RAW files


## Requirements
In order to use run this workflow you will need to install the following on your workstation: 
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




