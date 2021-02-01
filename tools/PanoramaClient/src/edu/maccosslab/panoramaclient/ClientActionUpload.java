package edu.maccosslab.panoramaclient;

import org.labkey.remoteapi.Command;
import org.labkey.remoteapi.CommandException;
import org.labkey.remoteapi.CommandResponse;
import org.labkey.remoteapi.Connection;

import java.io.File;
import java.io.IOException;

public class ClientActionUpload extends ClientAction<ActionOptions.Upload>
{
    @Override
    public boolean doAction(ActionOptions.Upload options) throws ClientException
    {
        var webdavUrlParts = ClientAction.getWebdavUrl(options.getWebdavUrl());

        String srcFilePath = options.getSrcFilePath();

        File srcFile = new File(srcFilePath);
        if(!srcFile.exists())
        {
            throw new ClientException("Source file does not exist: " + srcFilePath);
        }
        if(!srcFile.isFile())
        {
            throw new ClientException("Not a file " + srcFilePath);
        }

        Connection connection = getConnection(webdavUrlParts, options.getApiKey());

        LOG.info("Checking if folder exists on Panorama: '" + webdavUrlParts.getContainerPath() + "'");
        if (!containerExists(webdavUrlParts, connection))
        {
            throw new ClientException("Unable to upload. Folder does not exist on Panorama: '" + webdavUrlParts.getContainerPath() + "'");
        }

        LOG.info("Checking if target directory exists on Panorama: " + webdavUrlParts.combinePartsQuoted());
        if(!webdavDirExists(webdavUrlParts, connection))
        {
            if(options.isCreateTargetDir())
            {
                LOG.info("Creating target directory on Panorama: " + webdavUrlParts.combinePartsQuoted());
                createWebdavPath(webdavUrlParts, connection);
            }
            else
            {
                throw new ClientException("Unable to upload. Target directory does not exist on Panorama: " + webdavUrlParts.combinePartsQuoted());
            }
        }
        uploadFile(webdavUrlParts, srcFilePath, connection);
        LOG.info("File uploaded");
        return true;
    }

    private boolean containerExists(WebdavUrlParts webdavUrlParts, Connection connection) throws ClientException
    {
        Command<CommandResponse> cmd = new Command<>("project", "begin");
        try
        {
            CommandResponse response = cmd.execute(connection, webdavUrlParts.getContainerPath());
            if (response.getStatusCode() != 200)
            {
                return false;
            }
        }
        catch (IOException | CommandException e)
        {
            if(e instanceof CommandException)
            {
                CommandException ex = (CommandException)e;
                if(ex.getStatusCode() == 404)
                {
                    return false;
                }
                ClientException clEx = WebDavCommand.getIfPermissionsException(webdavUrlParts.getContainerPath(), ex);
                if(clEx != null) throw clEx;
            }
            throw new ClientException("Error checking if folder exists: '"
                    + webdavUrlParts.getContainerPath()
                    + "'. Error was: " + e.getMessage(), e);
        }
        return true;
    }

    private boolean webdavDirExists(WebdavUrlParts webdavUrlParts, Connection connection) throws ClientException
    {
        WebDavCommand.CheckWebdavDirExists cmd = new WebDavCommand.CheckWebdavDirExists();
        try
        {
            CommandResponse response = cmd.check(connection, webdavUrlParts.getContainerPath(), webdavUrlParts.getPathInFwp());
            if (response.getStatusCode() != 200)
            {
                return false;
            }
        }
        catch (IOException | CommandException e)
        {
            if(e instanceof CommandException && ((CommandException)e).getStatusCode() == 404)
            {
                return false;
            }
            throw new ClientException("Error checking if directory exists: "
                    + webdavUrlParts.combinePartsQuoted()
                    + ". Error was: " + e.getMessage(), e);
        }
        return true;
    }

    private void createWebdavPath(WebdavUrlParts webdavUrlParts, Connection connection) throws ClientException
    {
        for (String path: webdavUrlParts.getWebdavPathParts())
        {
            WebdavUrlParts partWebdavPathUrl = new WebdavUrlParts(webdavUrlParts.getServerUrl(), webdavUrlParts.getContainerPath(), path);
            tryTwiceCreateWebdavPath(connection, partWebdavPathUrl);
        }
    }

    private void tryTwiceCreateWebdavPath(Connection connection, WebdavUrlParts partWebdavPathUrl) throws ClientException
    {
        try
        {
            createWebdavPath(connection, partWebdavPathUrl);
        }
        catch (CommandException e)
        {
            // An exception can be thrown if the two processes try to create a directory simultaneously (e.g. two processes running on the MacCoss lab's Cromwell server
            // trying to upload files to the same directory on the Panorama server).
            // Usually the error is: HTTP 405 Method Not Allowed response status code indicates that the request method is known by the server but is not supported by the target resource
            LOG.warn("Error creating directory " + partWebdavPathUrl.combinePartsQuoted() + ". Error was: " + e.getMessage() + ". Trying again...");
            try
            {
                createWebdavPath(connection, partWebdavPathUrl);
            }
            catch (CommandException ex)
            {
                throw new ClientException("Error creating directory on Panorama: " + partWebdavPathUrl.combinePartsQuoted() + ". Error was: " + e.getMessage(), e);
            }
        }
    }

    private void createWebdavPath(Connection connection, WebdavUrlParts partWebdavPathUrl) throws ClientException, CommandException
    {
        LOG.info("Checking if directory exists: " + partWebdavPathUrl.combinePartsQuoted());
        if(webdavDirExists(partWebdavPathUrl, connection))
        {
            LOG.info("Directory exists: " + partWebdavPathUrl.combinePartsQuoted());
            return;
        }

        WebDavCommand.CreateDir cmd = new WebDavCommand.CreateDir();
        LOG.info("Creating directory: " + partWebdavPathUrl.combinePartsQuoted());
        try
        {
            CommandResponse response = cmd.create(connection, partWebdavPathUrl.getContainerPath(), partWebdavPathUrl.getPathInFwp());
            if (response.getStatusCode() != 201)
            {
                throw new ClientException("Could not create directory " + partWebdavPathUrl.combinePartsQuoted()
                        + ". HTTP status code: " + response.getStatusCode()
                        + ". Response text: " + response.getText());
            }
        }
        catch (IOException e)
        {
            throw new ClientException("Error creating directory on Panorama: " + partWebdavPathUrl.combinePartsQuoted() + ". Error was: " + e.getMessage(), e);
        }
    }

    void uploadFile(WebdavUrlParts webdavUrlParts, String srcFilePath, Connection connection) throws ClientException
    {
        LOG.info("Uploading " + srcFilePath + " to " + webdavUrlParts.combinePartsQuoted());

        WebDavCommand.Upload cmd = new WebDavCommand.Upload();
        try
        {
            CommandResponse response = cmd.upload(connection, webdavUrlParts.getContainerPath(), webdavUrlParts.getPathInFwp(), srcFilePath);
            if (response.getStatusCode() != 200 && response.getStatusCode() != 207)
            {
                throw new ClientException("File could not be uploaded. HTTP status code: " + response.getStatusCode() + ". Response text: " + response.getText());
            }
        }
        catch (IOException | CommandException e)
        {
            throw new ClientException("Error uploading file to " + webdavUrlParts.combinePartsQuoted() + ". Error was: " + e.getMessage(), e);
        }
    }
}
