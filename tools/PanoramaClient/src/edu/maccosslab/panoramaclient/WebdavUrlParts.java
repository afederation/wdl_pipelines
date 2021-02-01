package edu.maccosslab.panoramaclient;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class WebdavUrlParts extends LabKeyUrlParts
{
    private final String _pathInFwp;

    public WebdavUrlParts(String serverUrl, String containerPath, String pathInFwp)
    {
        super(serverUrl, containerPath);
        _pathInFwp = pathInFwp;
    }

    public String getPathInFwp()
    {
        return _pathInFwp;
    }

    public List<String> getWebdavPathParts()
    {
        if(_pathInFwp == null || _pathInFwp.length() == 0)
        {
            return Collections.emptyList();
        }

        String path = _pathInFwp;
        if(path.charAt(0) == '/')
        {
            path = path.length() > 1 ? path.substring(1) : "";
        }
        if(path.charAt(path.length() - 1) == '/')
        {
            path = path.length() > 1 ? path.substring(0, path.length() - 1) : "";
        }
        if(path.length() == 0)
        {
            return Collections.emptyList();
        }

        List<String> parts = new ArrayList<>();
        while(path != null)
        {
            parts.add(0, path);
            int idx = path.lastIndexOf('/');
            path = idx == -1 ? null : path.substring(0, idx);
        }
        return parts;
    }

    public String combineParts()
    {
        return getContainerPath() + '/' + URLHelper.FILE_ROOT + '/' + getPathInFwp();
    }

    public String combinePartsQuoted()
    {
        return "'" + combineParts() + "'";
    }
}
