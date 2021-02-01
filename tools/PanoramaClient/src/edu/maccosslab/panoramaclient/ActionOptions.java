package edu.maccosslab.panoramaclient;

public abstract class ActionOptions
{
    private String apiKey;

    public String getApiKey()
    {
        return apiKey;
    }

    public void setApiKey(String apiKey)
    {
        this.apiKey = apiKey;
    }

    public abstract ClientAction getAction();

    static abstract class WebdavActionOptions<T extends ClientAction> extends ActionOptions
    {
        private String webdavUrl;

        public String getWebdavUrl()
        {
            return webdavUrl;
        }

        public void setWebdavUrl(String webdavUrl)
        {
            this.webdavUrl = webdavUrl;
        }
    }

    public static class Download extends WebdavActionOptions
    {
        private String destDirPath;

        public String getDestDirPath()
        {
            return destDirPath;
        }

        public void setDestDirPath(String destDirPath)
        {
            this.destDirPath = destDirPath;
        }

        @Override
        public ClientActionDownload getAction()
        {
            return new ClientActionDownload();
        }
    }

    public static class DownloadFiles extends WebdavActionOptions
    {
        private String extension;
        private String destDirPath;

        public String getDestDirPath()
        {
            return destDirPath;
        }

        public void setDestDirPath(String destDirPath)
        {
            this.destDirPath = destDirPath;
        }
        public String getExtension()
        {
            return extension;
        }

        public void setExtension(String extension)
        {
            this.extension = extension;
        }

        @Override
        public ClientActionDownloadFiles getAction()
        {
            return new ClientActionDownloadFiles();
        }
    }

    public static class Upload extends WebdavActionOptions
    {
        private String srcFilePath;
        private boolean createTargetDir;

        public String getSrcFilePath()
        {
            return srcFilePath;
        }

        public void setSrcFilePath(String srcFilePath)
        {
            this.srcFilePath = srcFilePath;
        }

        public boolean isCreateTargetDir()
        {
            return createTargetDir;
        }

        public void setCreateTargetDir(boolean createTargetDir)
        {
            this.createTargetDir = createTargetDir;
        }

        @Override
        public ClientActionUpload getAction()
        {
            return new ClientActionUpload();
        }
    }

    public static class ListFiles extends WebdavActionOptions
    {
        private String extension;
        private String outputFile;

        public String getExtension()
        {
            return extension;
        }

        public void setExtension(String extension)
        {
            this.extension = extension;
        }

        public String getOutputFile()
        {
            return outputFile;
        }

        public void setOutputFile(String outputFile)
        {
            this.outputFile = outputFile;
        }

        @Override
        public ClientActionListFiles getAction()
        {
            return new ClientActionListFiles();
        }
    }

    public static class ImportSkyDoc extends ActionOptions
    {
        private String skyDocPath;
        private String panoramaFolderUrl;

        public String getSkyDocPath()
        {
            return skyDocPath;
        }

        public void setSkyDocPath(String skyDocPath)
        {
            this.skyDocPath = skyDocPath;
        }

        public String getPanoramaFolderUrl()
        {
            return panoramaFolderUrl;
        }

        public void setPanoramaFolderUrl(String panoramaFolderUrl)
        {
            this.panoramaFolderUrl = panoramaFolderUrl;
        }

        @Override
        public ClientActionImportSkyDoc getAction()
        {
            return new ClientActionImportSkyDoc();
        }
    }
}