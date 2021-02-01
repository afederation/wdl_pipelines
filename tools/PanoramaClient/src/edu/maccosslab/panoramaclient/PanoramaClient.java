package edu.maccosslab.panoramaclient;

import org.apache.commons.cli.*;
import org.apache.log4j.Logger;

import java.io.PrintWriter;
import java.util.*;

public class PanoramaClient
{
    private static final Logger LOG = Logger.getLogger(PanoramaClient.class);

    private CLOptionsGroup[] _availableOptGroups = new CLOptionsGroup[]{
            new CLOptionsGroup.DownloadFile(),
            new CLOptionsGroup.DownloadFiles(),
            new CLOptionsGroup.UploadFile(),
            new CLOptionsGroup.ListFiles(),
            new CLOptionsGroup.ImportSkyDoc()
    };

    private Map<String, CLOptionsGroup> _optionsMap;
    private Options _mainOptions;

    public PanoramaClient ()
    {
        _optionsMap = new HashMap<>();
        Arrays.stream(_availableOptGroups).forEach(opt -> _optionsMap.put(opt.getMainOption().getLongOpt(), opt));

        _mainOptions = getMainOptions();
    }

    private Options getMainOptions()
    {
        if(_mainOptions == null)
        {
            _mainOptions = new Options();
            OptionGroup optionsGroup = new OptionGroup();
            Arrays.stream(_availableOptGroups).forEach(opt -> optionsGroup.addOption(opt.getMainOption()));
            _mainOptions.addOptionGroup(optionsGroup);
        }
        return _mainOptions;
    }

    public CLOptionsGroup getClOptionsGroup(String optLogName)
    {
        return _optionsMap.get(optLogName);
    }

    public CLOptionsGroup getMainOptionsGroup(String[] args) throws ParseException
    {
        if(args == null || args.length == 0)
        {
            throw new ParseException("No arguments found on the command-line");
        }

        CommandLineParser parser = new DefaultParser();

        // Get the first command-line argument.  This should be one of main options, e.g.
        // -d (download file) OR -a (download all files) OR -l (get a list of files) etc.
        String[] commandArgs = new String[] {args[0]};
        CommandLine cl = parser.parse(getMainOptions(), commandArgs);

        if(cl == null || cl.getOptions().length == 0)
        {
            throw new ParseException("No options parsed from the command-line.");
        }

        for(Option opt: getMainOptions().getOptions())
        {
            if(cl.hasOption(opt.getOpt()))
            {
                return getClOptionsGroup(opt.getLongOpt());
            }
        }

        return null;
    }

    private void printHelp()
    {
        HelpFormatter formatter = new HelpFormatter();
        try (PrintWriter pw = new PrintWriter(System.out))
        {
            formatter.printHelp(pw, formatter.getWidth(), "java -jar panoramaclient.jar", null,
                    getMainOptions(), formatter.getLeftPadding(), formatter.getDescPadding(), null, true);

            for(CLOptionsGroup commandOpts: _availableOptGroups)
            {
                pw.println("");
                commandOpts.printHelp(pw, formatter);
            }
            pw.flush();
        }
    }

    public static void main(String[] args)
    {
        PanoramaClient client = new PanoramaClient();

        CLOptionsGroup optionsGroup = null;
        try
        {
            optionsGroup = client.getMainOptionsGroup(args);
        }
        catch (ParseException e)
        {
            LOG.error("Error parsing command line arguments. " + e.getMessage());
            client.printHelp();
            System.exit(1);
        }

        if(optionsGroup == null)
        {
            LOG.error("Could not get the main option from " + Arrays.toString(args));
            client.printHelp();
            System.exit(1);
        }


        ActionOptions actionOpts = null;
        try
        {
            actionOpts = optionsGroup.getActionOptions(args);
        }
        catch (ParseException e)
        {
            LOG.error(e.getMessage());
            optionsGroup.printHelp();
            System.exit(1);
        }

        if(actionOpts == null)
        {
            LOG.error("Could not get the sub-options for main option \'" + optionsGroup.getMainOption().getLongOpt()
                    + "\' from " + Arrays.toString(args));
            client.printHelp();
            System.exit(1);
        }

        try
        {
            if(!actionOpts.getAction().doAction(actionOpts))
            {
                LOG.error("Action was unsuccessful");
                System.exit(2);
            };
        }
        catch (ClientException e)
        {
            if(e.getCause() != null)
            {
                LOG.error(e.getMessage(), e);
            }
            else
            {
                LOG.error(e.getMessage());
            }

            System.exit(1);
        }
    }
}
