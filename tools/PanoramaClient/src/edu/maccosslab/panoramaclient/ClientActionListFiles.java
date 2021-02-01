package edu.maccosslab.panoramaclient;

import org.labkey.remoteapi.CommandException;
import org.labkey.remoteapi.Connection;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.List;
import java.util.stream.Collectors;

public class ClientActionListFiles extends ClientAction<ActionOptions.ListFiles>
{
    @Override
    public boolean doAction(ActionOptions.ListFiles options) throws ClientException
    {
        WebdavUrlParts webdavUrlParts = ClientAction.getWebdavUrl(options.getWebdavUrl());

        String apiKey = options.getApiKey();
        String extension = options.getExtension();

        String outputFilePath = options.getOutputFile();
        File outputFile = outputFilePath != null ? new File(outputFilePath) : null;

        Connection connection = getConnection(webdavUrlParts, apiKey);
        List<String> files = listFiles(webdavUrlParts.getContainerPath(), webdavUrlParts.getPathInFwp(), extension, connection);
        if(files.size() > 0)
        {
            printFileList(files, outputFile);
            return true;
        }
        else
        {
            LOG.warn("No files " + (extension != null ? "matching the extension \"" + extension + "\"" : "") + " found in containerPath '"
                    + webdavUrlParts.getContainerPath() + "' and FWP folder '" + webdavUrlParts.getPathInFwp() + "'");
            return false;
        }
    }

    private void printFileList(List<String> files, File outputFile) throws ClientException
    {
        if(outputFile == null)
        {
            for(String file: files)
            {
                LOG.info(file);
            }
        }
        else
        {
            try (BufferedWriter writer = new BufferedWriter(new FileWriter(outputFile)))
            {
                for(String file: files)
                {
                    writer.write(file);
                    writer.newLine();
                }
            }
            catch (IOException e)
            {
                throw new ClientException("Error writing to file " + outputFile.getAbsolutePath(), e);
            }
            LOG.info("File list written to " + outputFile);
        }
    }


    List<String> listFiles(String containerPath, String fwpFolderPath, String extension, Connection connection) throws ClientException
    {
        String pathStringForMsg = " container \'" + containerPath + "\'" + (fwpFolderPath.length() > 0 ? " and FWP folder \'" + fwpFolderPath + "\'"
                : "");
        LOG.info("Getting a list of files in" + pathStringForMsg);

        WebDavCommand.ListFiles cmd = new WebDavCommand.ListFiles();
        try
        {
            WebDavCommand.ListFilesResponse response = cmd.list(connection, containerPath, fwpFolderPath);
            if (response.getStatusCode() != 200)
            {
                throw new ClientException("Received HTTP status code " + response.getStatusCode());
            }
            List<String> fileNames = response.getFiles();
            if(extension == null || extension.trim().length() == 0 || "*".equalsIgnoreCase(extension))
            {
                return fileNames;
            }
            String ext = "." + extension.trim().toLowerCase();
            return fileNames.stream().filter(f -> f.toLowerCase().endsWith(ext)).collect(Collectors.toList());
        }
        catch (IOException | CommandException e)
        {
            throw new ClientException("Error getting file listing in " + pathStringForMsg + ": " + e.getMessage(), e);
        }
    }
}
