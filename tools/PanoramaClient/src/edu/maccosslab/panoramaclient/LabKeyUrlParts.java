package edu.maccosslab.panoramaclient;

public class LabKeyUrlParts
{
    private final String _serverUrl;
    private final String _containerPath;

    public LabKeyUrlParts(String serverUri, String containerPath)
    {
        _serverUrl = serverUri;
        _containerPath = containerPath;
    }

    public String getServerUrl()
    {
        return _serverUrl;
    }

    public String getContainerPath()
    {
        return _containerPath;
    }
}
