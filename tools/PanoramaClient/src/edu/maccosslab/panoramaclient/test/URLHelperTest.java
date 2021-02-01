package edu.maccosslab.panoramaclient.test;

import edu.maccosslab.panoramaclient.ClientException;
import edu.maccosslab.panoramaclient.LabKeyUrlParts;
import edu.maccosslab.panoramaclient.URLHelper;
import edu.maccosslab.panoramaclient.WebdavUrlParts;
import org.junit.Assert;
import org.junit.Test;

public class URLHelperTest
{
    @Test
    public void testBuildUrlParts()
    {
        testBuildLabKeyUrlParts();
        testBuildWebdavUrlParts();
    }

    @Test
    public void testGetWebdavPathParts() throws ClientException
    {
        WebdavUrlParts webdavUrl = URLHelper.buildWebdavUrlParts("http://localhost:8080/labkey/_webdav/home/@files/");
        Assert.assertEquals(0, webdavUrl.getWebdavPathParts().size());

        webdavUrl = URLHelper.buildWebdavUrlParts("http://localhost:8080/labkey/_webdav/home/@files/Test%20Folder");
        var pathParts = webdavUrl.getWebdavPathParts();
        Assert.assertEquals(1, pathParts.size());
        Assert.assertEquals("Test Folder", pathParts.get(0));

        webdavUrl = URLHelper.buildWebdavUrlParts("http://localhost:8080/labkey/_webdav/home/@files/Test%20Folder/test1");
        pathParts = webdavUrl.getWebdavPathParts();
        Assert.assertEquals(2, pathParts.size());
        Assert.assertEquals("Test Folder/test1", pathParts.get(1));
        Assert.assertEquals("Test Folder", pathParts.get(0));

        webdavUrl = URLHelper.buildWebdavUrlParts("http://localhost:8080/labkey/_webdav/home/@files/Test%20Folder/test%201/test%202");
        pathParts = webdavUrl.getWebdavPathParts();
        Assert.assertEquals(3, pathParts.size());
        Assert.assertEquals("Test Folder/test 1/test 2", pathParts.get(2));
        Assert.assertEquals("Test Folder/test 1", pathParts.get(1));
        Assert.assertEquals("Test Folder", pathParts.get(0));
    }

    private void testBuildWebdavUrlParts()
    {
        String serverBaseUrl = "http://localhost:8080/labkey";

        testValidWebdavUrl("http://localhost:8080/labkey/_webdav/home/@files/", serverBaseUrl, "home", "");
        testValidWebdavUrl("http://localhost:8080//labkey//_webdav//home project//@files/", serverBaseUrl, "home project", "");
        testValidWebdavUrl("http://localhost:8080//labkey//_webdav//home project//folder//@files", serverBaseUrl, "home project/folder", "");
        testValidWebdavUrl("http://localhost:8080//labkey//_webdav//home project//folder//@files/RawFiles//", serverBaseUrl, "home project/folder", "RawFiles");
        testValidWebdavUrl("http://localhost:8080//labkey//_webdav//home project//folder//%40files/RawFiles//test.raw", serverBaseUrl, "home project/folder", "RawFiles/test.raw");
        testValidWebdavUrl("http://localhost:8080//labkey//_webdav//home%20project//%40files/", serverBaseUrl, "home project", "");

        testInValidWebdavUrl(serverBaseUrl, "Expect WebDAV URL path to start with _webdav. Found empty path in url 'http://localhost:8080/labkey'");
        testInValidWebdavUrl("http://localhost:8080/labkey/project/home/begin.view?", "Expect WebDAV URL path to start with _webdav. " +
                "Found path: 'project/home/begin.view' in url 'http://localhost:8080/labkey/project/home/begin.view?'");
        testInValidWebdavUrl("http://panoramaweb.org/_webdav/project/home/begin.view?", "Expect WebDAV URL path to contain @files");
        testInValidWebdavUrl("http://panoramaweb.org/_webdav/@files/", "Container path is empty in url 'http://panoramaweb.org/_webdav/@files/'");
    }

    private void testBuildLabKeyUrlParts()
    {
        // Test old pattern URLs
        String serverBaseUrl = "http://localhost:8080/labkey";

        testValidLabKeyUrl("http://localhost:8080/labkey/project/home/begin.view?", serverBaseUrl, "home");
        testValidLabKeyUrl("http://localhost:8080//labkey//project//home project//begin.view?", serverBaseUrl, "home project");
        testValidLabKeyUrl("http://localhost:8080//labkey//project//home project//folder//begin.view?", serverBaseUrl, "home project/folder");

        testInValidLabKeyUrl(serverBaseUrl, "Path is empty");
        testInValidLabKeyUrl("http://localhost:8080/labkey/begin.view?", "Cannot parse container path from 'begin.view'");
        testInValidLabKeyUrl("http://localhost:8080/labkey/project/begin.view?", "Cannot remove controller name from container path 'project'");

        // Test new pattern URLs
        testValidLabKeyUrl("http://localhost:8080/labkey/home/project-begin.view?", serverBaseUrl, "home");
        testValidLabKeyUrl("http://localhost:8080//labkey//home project//project-begin.view?", serverBaseUrl, "home project");
        testValidLabKeyUrl("http://localhost:8080//labkey//home project//folder//project-begin.view?", serverBaseUrl, "home project/folder");

        testInValidLabKeyUrl("http://localhost:8080/labkey/project-begin.view?", "Cannot parse container path from 'project-begin.view'");
    }

    private void testValidLabKeyUrl(String url, String serverUrl, String containerPath)
    {
        try
        {
            LabKeyUrlParts urlParts = URLHelper.buildLabKeyUrlParts(url);
            Assert.assertEquals("Incorrect server base url", serverUrl, urlParts.getServerUrl());
            Assert.assertEquals("Incorrect container path", containerPath, urlParts.getContainerPath());
        }
        catch (ClientException e)
        {
            Assert.fail("Failed to parse valid url " + url + ". Error was: " + e.getMessage());
        }
    }

    private void testInValidLabKeyUrl(String url, String errMsg)
    {
        try
        {
            URLHelper.buildLabKeyUrlParts(url);
        }
        catch (ClientException e)
        {
            Assert.assertEquals(errMsg, e.getMessage());
            return;
        }
        Assert.fail("Expected exception " + errMsg);
    }

    private void testValidWebdavUrl(String url, String serverUrl, String containerPath, String fwpPath)
    {
        try
        {
            WebdavUrlParts urlParts = URLHelper.buildWebdavUrlParts(url);
            Assert.assertEquals("Incorrect server base url", serverUrl, urlParts.getServerUrl());
            Assert.assertEquals("Incorrect container path", containerPath, urlParts.getContainerPath());
            Assert.assertEquals("Incorrect FWP path", fwpPath, urlParts.getPathInFwp());
        }
        catch (ClientException e)
        {
            Assert.fail("Failed to parse valid url " + url + ". Error was: " + e.getMessage());
        }
    }

    private void testInValidWebdavUrl(String url, String errMsg)
    {
        try
        {
            URLHelper.buildWebdavUrlParts(url);
        }
        catch (ClientException e)
        {
            Assert.assertEquals(errMsg, e.getMessage());
            return;
        }
        Assert.fail("Expected exception " + errMsg);
    }
}