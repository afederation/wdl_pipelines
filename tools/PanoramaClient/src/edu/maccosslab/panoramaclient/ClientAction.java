package edu.maccosslab.panoramaclient;

import org.apache.log4j.Logger;
import org.labkey.remoteapi.ApiKeyCredentialsProvider;
import org.labkey.remoteapi.Connection;
import org.labkey.remoteapi.NetrcCredentialsProvider;

import java.io.IOException;

public abstract class ClientAction<T extends ActionOptions>
{
    static final Logger LOG = Logger.getLogger(ClientAction.class);

    public abstract boolean doAction(T commandOptions) throws ClientException;

    static Connection getConnection(WebdavUrlParts webdavUrlParts, String apiKey) throws ClientException
    {
        return getConnection(webdavUrlParts.getServerUrl(), apiKey);
    }

    static Connection getConnection(String serverUri, String apiKey) throws ClientException
    {
        if(apiKey != null && apiKey.trim().length() > 0)
        {
            return new Connection(serverUri.toString(), new ApiKeyCredentialsProvider(apiKey));
        }
        else
        {
            return getConnection(serverUri);
        }
    }

    static Connection getConnection(String serverUri) throws ClientException
    {
        try
        {
            return new Connection(serverUri.toString(), new NetrcCredentialsProvider(serverUri));
        }
        catch (IOException e)
        {
            throw new ClientException("Netrc lookup failed.", e);
        }
    }

    static WebdavUrlParts getWebdavUrl(String urlString) throws ClientException
    {
        if(urlString == null || urlString.trim().length() == 0)
        {
            throw new ClientException("Webdav URL string cannot be empty");
        }

        return URLHelper.buildWebdavUrlParts(urlString);
    }
}
