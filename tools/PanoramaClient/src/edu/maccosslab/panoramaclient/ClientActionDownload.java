package edu.maccosslab.panoramaclient;

import org.labkey.remoteapi.CommandException;
import org.labkey.remoteapi.CommandResponse;
import org.labkey.remoteapi.Connection;

import java.io.File;
import java.io.IOException;

public class ClientActionDownload extends ClientAction<ActionOptions.Download>
{
    @Override
    public boolean doAction(ActionOptions.Download options) throws ClientException
    {
        WebdavUrlParts webdavUrlParts = ClientAction.getWebdavUrl(options.getWebdavUrl());

        String downloadDir = options.getDestDirPath();
        if(downloadDir == null || downloadDir.trim().length() == 0)
        {
            downloadDir = System.getProperty("user.dir");
        }
        else
        {
            File dir = new File(downloadDir);
            if(!dir.exists())
            {
                throw new ClientException("Destination directory does not exist: " + downloadDir);
            }
            if(!dir.isDirectory())
            {
                throw new ClientException("Destination path is not a directory: " + downloadDir);
            }
        }

        Connection connection = getConnection(webdavUrlParts, options.getApiKey());
        downloadFile(webdavUrlParts.getContainerPath(), webdavUrlParts.getPathInFwp(), downloadDir, connection);
        return true;
    }

    void downloadFile(String containerPath, String sourceFilePath, String targetFolder, Connection connection) throws ClientException
    {
        LOG.info("File will be downloaded to " + targetFolder);

        WebDavCommand.Download cmd = new WebDavCommand.Download();
        int idx = sourceFilePath.lastIndexOf('/');
        String fileName = sourceFilePath.substring(idx + 1);
        String targetFilePath = targetFolder + File.separatorChar + fileName;
        try
        {
            CommandResponse response = cmd.download(connection, containerPath, sourceFilePath, targetFilePath);
            if (response.getStatusCode() != 200)
            {
                throw new ClientException("Received HTTP status code " + response.getStatusCode());
            }
            LOG.info("File downloaded to " + targetFilePath);
        }
        catch (IOException | CommandException e)
        {
            throw new ClientException("Error downloading file: " + e.getMessage(), e);
        }
    }
}
