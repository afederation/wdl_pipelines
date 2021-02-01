package edu.maccosslab.panoramaclient.test;

import edu.maccosslab.panoramaclient.CLOptionsGroup;
import edu.maccosslab.panoramaclient.PanoramaClient;
import org.apache.commons.cli.ParseException;
import org.junit.Assert;
import org.junit.Test;

public class CLParserTest
{
    @Test
    public void testParseCommandLine()
    {
        PanoramaClient client = new PanoramaClient();
        testFailParsingMainOption(client, new String[]{}, "No arguments found on the command-line");
        testFailParsingMainOption(client, new String[] {"-x"}, "Unrecognized option: -x");

        testParseDownloadFile(client);
    }

    private void testParseDownloadFile(PanoramaClient client)
    {
        CLOptionsGroup optionsGroup = null;
        try
        {
            String downloadLongOpt = CLOptionsGroup.DownloadFile.downloadFileOpt.getLongOpt();
            optionsGroup = client.getMainOptionsGroup(new String[] {"--" + downloadLongOpt});
            Assert.assertTrue("Expected instance of CLOptionsDownloadFile", optionsGroup instanceof CLOptionsGroup.DownloadFile);
        }
        catch (ParseException e)
        {
            Assert.fail("Should not have failed." + e.getMessage());
        }

        testFailParsingSubOptions(optionsGroup, new String[] {}, "Missing required option: w");
        testFailParsingSubOptions(optionsGroup, new String[] {"-w"}, "Missing argument for option: w");
        testFailParsingSubOptions(optionsGroup, new String[] {"-w", "https://localhost:8080", "--not_an_opt"}, "Unrecognized option: --not_an_opt");
        testFailParsingSubOptions(optionsGroup, new String[] {"-w", "https://localhost:8080", "-k"}, "Missing argument for option: k");
        testFailParsingSubOptions(optionsGroup, new String[] {"-w", "https://localhost:8080", "-k", "apikey", "-t"}, "Missing argument for option: t");
        String apiKeyLongOpt = "-" + CLOptionsGroup.apiKeyOption.getLongOpt();
        testFailParsingSubOptions(optionsGroup, new String[] {"-w", "https://localhost:8080", apiKeyLongOpt, "apikey", "-t"}, "Missing argument for option: t");
    }

    private void testFailParsingMainOption(PanoramaClient client, String[] args, String errMsg)
    {
        try
        {
            client.getMainOptionsGroup(args);
        }
        catch (ParseException e)
        {
            Assert.assertEquals(errMsg, e.getMessage());
            return;
        }
        Assert.fail("Expected exception " + errMsg);
    }

    private void testFailParsingSubOptions (CLOptionsGroup optionsGroup, String[] args, String errMsg)
    {
        try
        {
            optionsGroup.getActionOptions(args);
        }
        catch (ParseException e)
        {
            Assert.assertEquals(errMsg, e.getMessage());
            return;
        }
        Assert.fail("Expected exception " + errMsg);
    }
}
