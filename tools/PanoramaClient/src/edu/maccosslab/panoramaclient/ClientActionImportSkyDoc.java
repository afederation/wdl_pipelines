package edu.maccosslab.panoramaclient;

import org.labkey.remoteapi.CommandException;
import org.labkey.remoteapi.CommandResponse;
import org.labkey.remoteapi.Connection;
import org.labkey.remoteapi.PostCommand;
import org.labkey.remoteapi.query.Filter;
import org.labkey.remoteapi.query.SelectRowsCommand;
import org.labkey.remoteapi.query.SelectRowsResponse;

import java.io.File;
import java.io.IOException;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

public class ClientActionImportSkyDoc extends ClientAction<ActionOptions.ImportSkyDoc>
{
    @Override
    public boolean doAction(ActionOptions.ImportSkyDoc options) throws ClientException
    {
        String skyDocPath = options.getSkyDocPath();

        File file = new File(skyDocPath);
        if(!file.exists())
        {
            throw new ClientException("Source file does not exist: " + skyDocPath);
        }
        if(!file.isFile())
        {
            throw new ClientException("Not a file " + skyDocPath);
        }
        if(!skyDocPath.toLowerCase().endsWith(".sky.zip"))
        {
            throw new ClientException("Not a Skyline shared zip file " + file.getName());
        }

        String panoramaFolderUrl = options.getPanoramaFolderUrl();
        if(panoramaFolderUrl == null || panoramaFolderUrl.trim().length() == 0)
        {
            throw new ClientException("URL string cannot be empty");
        }

        LabKeyUrlParts labKeyUrlParts = URLHelper.buildLabKeyUrlParts(panoramaFolderUrl);

        Connection connection = getConnection(labKeyUrlParts.getServerUrl(), options.getApiKey());

        uploadAndImport(labKeyUrlParts.getServerUrl(), labKeyUrlParts.getContainerPath(), options.getSkyDocPath(), connection);
        return true;
    }

    void uploadAndImport(String serverUri, String containerPath, String skyZipPath, Connection connection) throws ClientException
    {
        LOG.info("Starting upload and import of Skyline document " + skyZipPath + " into Panorama folder '" + containerPath + "'");

        ClientActionUpload cmd = new ClientActionUpload();
        cmd.uploadFile(new WebdavUrlParts(serverUri, containerPath, ""), skyZipPath, connection);
        LOG.info("Uploaded Skyline document " + skyZipPath + " into Panorama folder " + containerPath);

        PostCommand<CommandResponse> importCmd = new PostCommand<>("targetedms", "skylineDocUploadApi");
        Map<String, Object> params = new HashMap<>();
        params.put("path", "./");
        params.put("file", new File(skyZipPath).getName());
        importCmd.setParameters(params);

        Long jobId;
        try
        {
            LOG.info("Starting Skyline document import");
            CommandResponse response = importCmd.execute(connection, containerPath);
            if (response.getStatusCode() != 200)
            {
                throw new ClientException("Error starting Skyline document import. Received HTTP status code " + response.getStatusCode());
            }

            jobId = response.getProperty("UploadedJobDetails[0].RowId");
        }
        catch (IOException | CommandException e)
        {
            throw new ClientException("Error starting Skyline document import on the server.", e);
        }

        // Example: https://panoramaweb-dr.gs.washington.edu/pipeline-status/00Developer/vsharma/PanoramaClientTest/details.view?rowId=85274
        // Example: https://panoramaweb-dr.gs.washington.edu/00Developer/vsharma/PanoramaClientTest/pipeline-status-details.view?rowId=85274
        String pipelineStatusUri = serverUri + "/" + containerPath + "/pipeline-status-details.view?rowId=" + jobId;
        LOG.info("Job submitted at: " + pipelineStatusUri + ". Checking status");
        try
        {
            SelectRowsCommand selectJobStatus = new SelectRowsCommand("pipeline", "job");
            selectJobStatus.setColumns(Collections.singletonList("Status"));
            Filter filter = new Filter("rowId", jobId);
            selectJobStatus.addFilter(filter);

            int i = 0;
            String status = null;
            while(!jobDone(status))
            {
                Thread.sleep(6 * 1000);

                status = getStatus(connection, containerPath, selectJobStatus, jobId);

                if(i % 10 == 0)
                {
                    LOG.info("Job status is: " + status);
                }
                i++;
            }
            LOG.info("Job done: " + pipelineStatusUri);
            LOG.info("Job status: " + status);
            if(!isComplete(status))
            {
                throw new ClientException("Skyline document was not imported. Error details can be found at " + pipelineStatusUri);
            }
        }
        catch (IOException | CommandException | InterruptedException e)
        {
            throw new ClientException("Error checking status of jobId " + jobId, e);
        }
    }

    private String getStatus(Connection connection, String containerPath, SelectRowsCommand cmd, long jobId) throws IOException, CommandException, ClientException, InterruptedException
    {
        int tryCount = 0;
        int maxTryCount = 5;
        while(++tryCount <= maxTryCount)
        {
            SelectRowsResponse response = cmd.execute(connection, containerPath);
            if(response.getStatusCode() == 200)
            {
                if(response.getRowCount().equals(0))
                {
                    throw new ClientException("No status returned for jobId " + jobId);
                }
                return (String) response.getRows().get(0).get("Status");
            }
            else
            {
                LOG.warn("Checking job status. Received unexpected HTTP status code " + response.getStatusCode());
            }
            Thread.sleep(5 * 1000); // Try again after 5 seconds.
        }
        throw new ClientException("Could not get status of jobId " + jobId + ". Giving up after trying " + maxTryCount + " times.");
    }

    private boolean jobDone(String status)
    {
        return status != null && (!(status.toLowerCase().contains("running") || status.toLowerCase().contains("waiting")));
    }

    private boolean isComplete(String status)
    {
        return status != null && status.toLowerCase().contains("complete");
    }
}
