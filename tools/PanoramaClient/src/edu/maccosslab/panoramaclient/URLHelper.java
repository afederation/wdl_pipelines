package edu.maccosslab.panoramaclient;

import java.net.MalformedURLException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;

public class URLHelper
{
    public static final String WEBDAV = "_webdav";
    public static final String FILE_ROOT = "@files";
    private static final String FILE_ROOT_ENCODED = "%40files";
    private static final String LABKEY_CTX = "labkey";

    public static WebdavUrlParts buildWebdavUrlParts(String url) throws ClientException
    {
        // Example URL: https://localhost:8080/labkey/_webdav/Project/@files/RawFiles
        // Example URL: https://panoramaweb.org/_webdav/Project/@files/RawFiles
        URI fullUri = createUri(url);

        String serverUrl = getServerUrl(fullUri);

        String path = getPathWithoutContext(fullUri.getPath());
        path = removeBeginningSlash(path);

        if(!path.startsWith(WEBDAV))
        {
            String pathMsg = path.length() > 0 ? ". Found path: \'" + path + "\'" : ". Found empty path";
            pathMsg += " in url \'" + url + "\'";
            throw new ClientException("Expect WebDAV URL path to start with " + WEBDAV + pathMsg);
        }

        String fileRoot = FILE_ROOT;
        int idx = path.indexOf(FILE_ROOT);
        if(idx == -1)
        {
            idx = path.indexOf(FILE_ROOT_ENCODED);
            fileRoot = FILE_ROOT_ENCODED;
        }
        if(idx == -1)
        {
            throw new ClientException("Expect WebDAV URL path to contain " + FILE_ROOT);
        }

        String containerPath = removeBeginningAndTralingSlash(path.substring(WEBDAV.length(), idx));
        if(containerPath.length() == 0)
        {
            throw new ClientException("Container path is empty in url \'" + url + "\'");
        }
        String pathInFwp = removeBeginningAndTralingSlash(path.substring(idx + fileRoot.length()));

        return new WebdavUrlParts(serverUrl, containerPath, pathInFwp);
    }

    public static LabKeyUrlParts buildLabKeyUrlParts(String url) throws ClientException
    {
        // Example URL: https://panoramaweb.org/controller/Project/begin.view?
        // Example URL: https://panoramaweb.org/labkey/Project/controller-begin.view?
        URI fullUri = createUri(url);

        String serverUrl = getServerUrl(fullUri);

        String path = getLabKeyPath(fullUri);

        return new LabKeyUrlParts(serverUrl, path);
    }

    private static URI createUri(String url) throws ClientException
    {
        URI uri;
        try
        {
            uri = new URI(url); // This will throw an exception if there are spaces in the string, for example
        }
        catch(URISyntaxException e)
        {
            try
            {
                URL fullUrl = new URL(url);
                uri = new URI(fullUrl.getProtocol(), fullUrl.getUserInfo(), fullUrl.getHost(), fullUrl.getPort(), fullUrl.getPath(), fullUrl.getQuery(), null);
            }
            catch(Exception ex)
            {
                throw new ClientException("Error parsing url " + url, ex);
            }
        }
        catch (Exception e)
        {
            throw new ClientException("Error parsing url " + url, e);
        }
        return uri.normalize();
    }

    private static String getServerUrl(URI uri)
    {
        StringBuilder serverUrl = new StringBuilder();
        String protocol = uri.getScheme();
        serverUrl.append(protocol).append("://").append(uri.getHost());
        int port = uri.getPort();
        // Append a port number for http connections not on port 80, and for https connections not on 443
        if (port != -1 && ((port != 80 && "http".equals(protocol)) || (port != 443 && "https".equals(protocol))))
        {
            serverUrl.append(":").append(port);
        }

        String path = removeBeginningSlash(uri.getPath());
        // We can only handle the case where the context is "labkey"
        if(path != null && path.startsWith(LABKEY_CTX))
        {
            serverUrl.append("/" + LABKEY_CTX);
        }

        return serverUrl.toString();
    }

    private static String getLabKeyPath(URI uri) throws ClientException
    {
        // New URL pattern  <protocol>://<domain>/<contextpath>/<containerpath>/<controller>-<action>
        // Old URL pattern  <protocol>://<domain>/<contextpath>/<controller>/<containerpath>/<action>

        String path = getPathWithoutContext(uri.getPath());
        path = removeBeginningAndTralingSlash(path);

        int idx = path.lastIndexOf("/");
        if(idx == -1)
        {
            String message = path.length() > 0 ? "Cannot parse container path from \'" + path + "\'" : "Path is empty";
            throw new ClientException(message);
        }

        boolean newUrlPattern = path.substring(idx).contains("-"); // <controller>-<action>

        String containerPath = path.substring(0, idx); // Remove the action part

        if(!newUrlPattern)
        {
            // The first part of the path is the controller name
            idx = containerPath.indexOf("/");
            if(idx == -1 || idx == containerPath.length() - 1)
            {
                throw new ClientException("Cannot remove controller name from container path \'" + containerPath + "\'");
            }
            containerPath = containerPath.substring(idx + 1);
        }

        return removeBeginningAndTralingSlash(containerPath);
    }

    private static String getPathWithoutContext(String path)
    {
        if(path != null)
        {
            path = removeBeginningSlash(path);
            if (path.startsWith(LABKEY_CTX))
            {
                path = path.substring(path.indexOf(LABKEY_CTX) + LABKEY_CTX.length());
            }
        }
        return path == null ? "" : path;
    }

    private static String removeBeginningAndTralingSlash(String path)
    {
        path = removeBeginningSlash(path);
        path = removeTrailingSlash(path);
        return path;
    }

    private static String removeBeginningSlash(String path)
    {
        if (path.startsWith("/"))
        {
            path = path.length() > 0 ? path.substring(1) : "";
        }
        return path;
    }

    private static String removeTrailingSlash(String path)
    {
        if (path.endsWith("/"))
        {
            path = path.length() > 0 ? path.substring(0, path.length() - 1) : "";
        }
        return path;
    }
}
