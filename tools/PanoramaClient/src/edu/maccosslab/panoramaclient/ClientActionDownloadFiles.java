package edu.maccosslab.panoramaclient;

import org.labkey.remoteapi.Connection;

import java.io.File;
import java.util.List;

public class ClientActionDownloadFiles extends ClientAction<ActionOptions.DownloadFiles>
{
    @Override
    public boolean doAction(ActionOptions.DownloadFiles options) throws ClientException
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
        return downloadFiles(webdavUrlParts.getContainerPath(), webdavUrlParts.getPathInFwp(), downloadDir, options.getExtension(), connection);
    }

    public boolean downloadFiles(String containerPath, String fwpFolderPath, String targetFolder, String extension, Connection connection) throws ClientException
    {
        LOG.info("Files will be downloaded to " + targetFolder);

        ClientActionListFiles cmdListFiles = new ClientActionListFiles();
        List<String> fileNames = cmdListFiles.listFiles(containerPath, fwpFolderPath, extension, connection);
        if(fileNames != null && fileNames.size() > 0)
        {
            String pathStringForMsg = " container '" + containerPath + "'" + (fwpFolderPath.length() > 0 ? " and FWP folder '" + fwpFolderPath + "'" : "");
            LOG.info("Found " + fileNames.size() + " files " + (extension != null ? "matching the extension \"" + extension + "\"" : "") + " in " + pathStringForMsg);
            ClientActionDownload cmdDownload = new ClientActionDownload();
            for(String sourceFile: fileNames)
            {
                String sourceFilePath = fwpFolderPath.length() > 0 ? fwpFolderPath + "/" + sourceFile : sourceFile;
                cmdDownload.downloadFile(containerPath, sourceFilePath, targetFolder, connection);
            }
            return true;
        }
        else
        {
            LOG.warn("No files " + (extension != null ? "matching the extension \"" + extension + "\"" : "") + " found in containerPath '" + containerPath + "' and FWP folder '" + fwpFolderPath + "'");
            return false;
        }
    }
}
