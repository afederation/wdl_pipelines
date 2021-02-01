package edu.maccosslab.panoramaclient;

import org.apache.http.HttpEntity;
import org.apache.http.client.methods.HttpEntityEnclosingRequestBase;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.client.utils.URIBuilder;
import org.apache.http.entity.mime.MultipartEntityBuilder;
import org.json.simple.JSONObject;
import org.labkey.remoteapi.Command;
import org.labkey.remoteapi.CommandException;
import org.labkey.remoteapi.CommandResponse;
import org.labkey.remoteapi.Connection;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public abstract class WebDavCommand<ResponseType extends CommandResponse> extends Command<ResponseType>
{
    public WebDavCommand()
    {
        super(URLHelper.WEBDAV, "NO_ACTION");
    }

    @Override
    protected String getQueryString()
    {
        return null;
    }

    @Override
    protected URI getActionUrl(Connection connection, String folderPath) throws URISyntaxException
    {
        URI uri = new URI(connection.getBaseUrl().replace('\\', '/'));
        StringBuilder path = new StringBuilder(uri.getPath() != null && !"".equals(uri.getPath()) ? uri.getPath() : "/");
        String controller = this.getControllerName();
        if (controller.charAt(0) != '/' && path.charAt(path.length() - 1) != '/') {
            path.append('/');
        }

        path.append(controller);
        String folder;
        if (null != folderPath && folderPath.length() > 0) {
            folder = folderPath.replace('\\', '/');
            if (folder.charAt(0) != '/' && path.charAt(path.length() - 1) != '/') {
                path.append('/');
            }

            path.append(folder);
        }

        if(path.charAt(path.length() - 1) != '/')
        {
            path.append('/');
        }
        path.append(URLHelper.FILE_ROOT);
        String pathAfterFileRoot = pathAfterFileRoot();
        if(pathAfterFileRoot != null && pathAfterFileRoot.length() > 0 && pathAfterFileRoot.charAt(0) != '/')
        {
            path.append('/');
        }
        path.append(pathAfterFileRoot);

        return (new URIBuilder(uri)).setPath(path.toString()).build();
    }

    public ResponseType executeCmd(Connection connection, String folderPath) throws IOException, CommandException, ClientException
    {
        try
        {
            return super.execute(connection, folderPath);
        }
        catch(CommandException e)
        {
            ClientException ex = getIfPermissionsException(folderPath, e);
            if(ex != null) throw ex;
            throw e;
        }
    }

    public static ClientException getIfPermissionsException(String folderPath, CommandException e)
    {
        if (e.getStatusCode() == 401)
        {
            return new ClientException("User could not be authenticated with the given credentials. Error message: " + e.getMessage());
        }
        else if (e.getStatusCode() == 403)
        {
            return new ClientException("User does not have the required permissions in the folder '" + folderPath + "'. Error message: " + e.getMessage());
        }
        return null;
    }

    protected Command.Response executeGetResponse(Connection connection, String folderPath) throws CommandException, IOException, ClientException
    {
        try
        {
            return super._execute(connection, folderPath);
        }
        catch(CommandException e)
        {
            ClientException ex = getIfPermissionsException(folderPath, e);
            if(ex != null) throw ex;
            throw e;
        }
    }

    abstract String getFwpPath();
    String pathAfterFileRoot()
    {
        String _folderPath = getFwpPath();
        return (_folderPath != null && _folderPath.trim().length() > 0) ? _folderPath.trim() : "";
    }

    public static class Upload extends WebDavCommand<CommandResponse>
    {
        private String _sourceFilePath;
        private String _folderPath; // Part of the path after the file root. e.g sub-folder path in the FWP.

        public CommandResponse upload(Connection connection, String containerPath, String folderPath, String sourceFilePath) throws IOException, CommandException, ClientException
        {
            this._sourceFilePath = sourceFilePath;
            _folderPath = folderPath;
            return super.executeCmd(connection, containerPath);
        }

        @Override
        String getFwpPath()
        {
            return _folderPath;
        }

        @Override
        protected HttpUriRequest createRequest(URI uri)
        {
            HttpPost request = new HttpPost(uri);
            HttpEntity multipartEntity = MultipartEntityBuilder.create().addBinaryBody("file", new File(_sourceFilePath)).build();
            request.setEntity(multipartEntity);
            return request;
        }
    }

    public static class Download extends WebDavCommand<CommandResponse>
    {
        private String _sourceFile;

        @Override
        String getFwpPath()
        {
            return _sourceFile;
        }

        public CommandResponse download(Connection connection, String containerPath, String sourceFile, String targetFilePath) throws CommandException, IOException, ClientException
        {
            _sourceFile = sourceFile;

            Response response = super.executeGetResponse(connection, containerPath);
            try (BufferedInputStream is = new BufferedInputStream(response.getInputStream()))
            {
                try (BufferedOutputStream fos = new BufferedOutputStream(new FileOutputStream(new File(targetFilePath))))
                {
                    byte[] bytes = new byte[8096];
                    int bytesRead;
                    while ((bytesRead = is.read(bytes)) != -1)
                    {
                        fos.write(bytes, 0, bytesRead);
                    }
                }
            }
            return createResponse(response.getText(), response.getStatusCode(), response.getContentType(), new JSONObject());
        }
    }

    public static class ListFiles extends WebDavCommand<ListFilesResponse>
    {
        private String _folderPath; // Part of the path after the file root. e.g sub-folder path in the FWP.

        public ListFilesResponse list(Connection connection, String containerPath, String folderPath) throws IOException, CommandException, ClientException
        {
            _folderPath = folderPath;
            return super.executeCmd(connection, containerPath);
        }

        @Override
        String getFwpPath()
        {
            return _folderPath;
        }

        @Override
        protected HttpUriRequest createRequest(URI uri)
        {
            HttpEntityEnclosingRequestBase request = new HttpEntityEnclosingRequestBase()
            {
                @Override
                public String getMethod()
                {
                    // JSON for DavController.JsonAction
                    // PROPFIND for DavController.PropfindAction
                    return "JSON";
                }
            };
            request.setURI(uri);
            return request;
        }

        @Override
        protected ListFilesResponse createResponse(String text, int status, String contentType, JSONObject json)
        {
            return new ListFilesResponse(text, status, contentType, json, this);
        }
    }

    public static class ListFilesResponse extends CommandResponse
    {
        private List<String> _fileNames;

        public ListFilesResponse(String text, int statusCode, String contentType, JSONObject json, Command sourceCommand)
        {
            super(text, statusCode, contentType, json, sourceCommand);
        }

        public List<String> getFiles()
        {
            if (_fileNames == null)
            {
                List<Map<String, Object>> fileList = getProperty("files");
                if (fileList == null)
                    throw new IllegalStateException("No file list returned from the server.");

                _fileNames = new ArrayList<>();
                for (Map<String, Object> fileDetails: fileList)
                {
                    Object isCollection = fileDetails.get("collection");
                    if(isCollection != null && Boolean.parseBoolean(isCollection.toString()))
                    {
                        // Ignore directories
                        continue;
                    }
                    _fileNames.add((String) fileDetails.get("text")); // Just the filename
                }
            }
            return _fileNames;
        }
    }

    public static class CreateDir extends WebDavCommand<CommandResponse>
    {
        private String _folderPath; // Part of the path after the file root. e.g sub-folder path in the FWP.

        public CommandResponse create(Connection connection, String containerPath, String folderPath) throws IOException, CommandException, ClientException
        {
            _folderPath = folderPath;
            return super.executeCmd(connection, containerPath);
        }

        @Override
        String getFwpPath()
        {
            return _folderPath;
        }

        @Override
        protected HttpUriRequest createRequest(URI uri)
        {
            HttpEntityEnclosingRequestBase request = new HttpEntityEnclosingRequestBase()
            {
                @Override
                public String getMethod()
                {
                    return "MKCOL";
                }
            };
            request.setURI(uri);
            return request;
        }
    }

    public static class CheckWebdavDirExists extends WebDavCommand<CommandResponse>
    {
        private String _folderPath; // Part of the path after the file root. e.g sub-folder path in the FWP.

        public CommandResponse check(Connection connection, String containerPath, String folderPath) throws IOException, CommandException, ClientException
        {
            _folderPath = folderPath;
            return super.executeCmd(connection, containerPath);
        }

        @Override
        String getFwpPath()
        {
            return _folderPath;
        }

        @Override
        protected HttpUriRequest createRequest(URI uri)
        {
           return new HttpGet(uri);
        }
    }
}
