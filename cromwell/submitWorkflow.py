#!/usr/bin/env python3
#
# Use this script to submit a Cromwell workflow to the MacCoss
# lab Cromwell server, m002.grid.gs.washington.edu.
#
# This is a wrapper script to make it easier to submit the workflow
# and track it's status
#
# TODO: Copy contents of workflow run metadata to Panorama server along
# TODO:   with other logs and output from run
# TODO:   - Obsufcate all places where apikey is stored in metadata file.

import requests
import logging
import datetime
import argparse
import subprocess
import sys
import os
import time
import json
import pytz
# import shutil

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s: %(levelname)s: %(message)s"
)
LOGGER = logging.getLogger()


def upload_logs(temp_dir, inputs_file, workflow_name):
    # Recursively upload all files in the "dir" directory to
    # the PanoramaWeb server.
    #
    # The logs will be uploaded to the "name" directory in the
    # WebDav URL specified in the workflow inputs file (inputs_file):
    # - For MsconvertWorkflow we will use the folder specified in
    #   "msconvert_workflow.url_webdav_converted_files_folder" input.
    # - For PanoramaSkylineWorkflow, we will use the folder specified in
    #   "panorama_skyline_workflow_scatter.url_target_panorama_folder"
    #   input.
    # - For DIA_* and DDA* workflows we will use the folder specified in
    #   "*.url_labkey_webdav_output_files_folder" input 
    #
    from urllib.parse import urlparse

    # The Panorama Server api key will be read from the inputs file.
    # The folder where logs should be uploaded will be read from
    # inputs file.
    try:
        with open(inputs_file, "r") as fh:
            inputs_str = fh.read()
        inputs = json.loads(inputs_str)
        pweb_key = ""
        upload_folder_url = ""
        for key in inputs:
            if "apikey" in str(inputs[key]):
                pweb_key = str(inputs[key])
            elif "url_webdav_converted_files_folder" in str(key):
                upload_folder_url = str(inputs[key])
            elif "url_target_panorama_folder" in str(key):
                upload_folder_url = str(inputs[key])
            elif "url_labkey_webdav_output_files_folder" in str(key):
                upload_folder_url = str(inputs[key])

        # Check that api key and upload folder url were found in the
        # inputs file
        if pweb_key == "":
            LOGGER.error(
                "Workflow inputs file did not contain API key for Panorama "
                "server. Logs could not be uploaded to Panorama server. "
            )
            LOGGER.error("Workflow log files are available at %s", temp_dir)
            return [False, upload_folder_url]
        else:
            pweb_user = 'apikey'
            pweb_pass = pweb_key.rstrip().lstrip()
        if upload_folder_url == "":
            LOGGER.error(
                "Workflow inputs file did not contain the upload folder on "
                "Panorama server. Logs could not be uploaded to "
                "Panorama server. "
            )
            LOGGER.error("Workflow log files are available at %s", temp_dir)
            return [False, upload_folder_url]
    except OSError as err:
        LOGGER.warn(
            "Unable to open the inputs file, '%s', Logs could not be uploaded"
            "Panorama server. Error message is %s",
            args.inputs,
            err.strerror,
        )
        LOGGER.error("Workflow log files are available at {}".format(temp_dir))
        return [False, upload_folder_url]

    # If running the panorama_skyline_workflow, the url_target_panorama_folder
    # is not a webdav URL. So we will need to create one to upload the logs
    # and other files.
    #
    # This assumes you are using the URLs in the new format, which is the
    # default on PanoramaWeb
    if workflow_name == "panorama_skyline_workflow":
        parsed_url = urlparse(upload_folder_url)
        url_path = os.path.dirname(parsed_url.path)
        upload_folder_url = "{}://{}/_webdav/{}/@files/".format(
            parsed_url.scheme, parsed_url.netloc, url_path
        )

    LOGGER.info("Uploading workflow log files to %s", upload_folder_url)

    # Authenticate to server
    parsed_url = urlparse(upload_folder_url)
    csrf_url = "{}://{}/home/login-whoami.api".format(
        parsed_url.scheme, parsed_url.netloc
    )
    try:
        csrf_response = requests.get(csrf_url, auth=(pweb_user, pweb_pass))
        csrf_response_json = csrf_response.json()
        csrf_response.close()

        csrf_header = csrf_response_json["CSRF"]
        csrf_cookies = requests.utils.dict_from_cookiejar(
            csrf_response.cookies
        )
    except (
        requests.exceptions.HTTPError,
        requests.exceptions.ConnectionError,
        requests.exceptions.Timeout,
        requests.exceptions.RequestException,
    ) as err:
        LOGGER.error(
            "Logs could not be uploaded Panorama server. There was an error "
            "authenticating to the server: %s",
            err,
        )
        LOGGER.error("Workflow log files are available at {}".format(temp_dir))
        return [False, upload_folder_url]

    #
    # Upload the files to PanoramaWeb server
    #
    upload_folder_dir_url = "{}".format(upload_folder_url)
    url = "{}?Accept=application/json&overwrite=T&X-LABKEY-CSRF={}".format(
        upload_folder_dir_url, csrf_header
    )

    try:
        # Check if new directory already exists
        dir_check_response = requests.get(
            upload_folder_dir_url,
            auth=(pweb_user, pweb_pass),
            cookies=csrf_cookies
        )
        dir_check_response.close()
        if dir_check_response.status_code != 200:
            # HTTP response code = 200 means the directory does not exists
            # Create the new directory
            LOGGER.info(
                "Create new webDAV directory, '%s', on PanoramaWeb",
                upload_folder_url,
            )

            create_dir_response = requests.request(
                "MKCOL",
                url,
                auth=(pweb_user, pweb_pass),
                cookies=csrf_cookies
            )
            create_dir_response.close()

            # Check if upload was successful
            #   HTTP response code of 201 indicates success.
            #   All other response codes indicate failure
            if create_dir_response.status_code != 201:
                LOGGER.error(
                    "New webDAV directory, '%s', could not be created. "
                    "There was an error: %s",
                    upload_folder_url,
                    create_dir_response.status_code,
                )
                LOGGER.error(
                    "Workflow log files are available at %s", temp_dir
                )
                return [False, upload_folder_dir_url]
    except (
        requests.exceptions.HTTPError,
        requests.exceptions.ConnectionError,
        requests.exceptions.Timeout,
        requests.exceptions.RequestException,
    ) as err:
        LOGGER.error(
            "New webDAV directory, '%s', could not be created. Error is: %s",
            upload_folder_url,
            err,
        )
        LOGGER.info(
            "There was problem uploading the workflow log files to "
            "PanoramaWeb. You can review the logs in '%s' directory.",
            temp_dir,
        )
        return [False, upload_folder_dir_url]

    # Upload the files
    upload_status = "success"
    temp_filelist = os.listdir(temp_dir)
    for fname in temp_filelist:
        if os.path.isdir(fname):
            continue

        url = "{}?Accept=application/json&overwrite=T&X-LABKEY-CSRF={}".format(
            upload_folder_dir_url, csrf_header
        )

        # Create the dictionary containing the file name and other file attr
        ufh = open("{}/{}".format(temp_dir, fname), "rb")
        files = {
            "file": (
                fname,
                ufh,
                "application/octet-stream",
                {"Expires": "0"},
            )
        }

        # Upload the file
        LOGGER.info("Upload log file, '%s', to PanoramaWeb", fname)
        try:
            # Upload the file
            upload_response = requests.post(
                url,
                files=files,
                auth=(pweb_user, pweb_pass),
                cookies=csrf_cookies
            )
            upload_response.close()
            ufh.close()

            # Check if upload was successful
            #   HTTP response code of 207 indicates success.
            #   All other response codes indicate failure
            if upload_response.status_code != 207:
                LOGGER.error(
                    "Log file, '%s', could not be uploaded Panorama server. "
                    "There was an error: %s",
                    fname,
                    upload_response.status_code,
                )
                LOGGER.error(
                    "Workflow log files are available at %s", temp_dir
                )
                upload_status = "failed"
        except (
            requests.exceptions.HTTPError,
            requests.exceptions.ConnectionError,
            requests.exceptions.Timeout,
            requests.exceptions.RequestException,
        ) as err:
            LOGGER.error(
                "Log file, '%s', could not be uploaded Panorama server. "
                "There was an error: %s",
                fname,
                err,
            )
            LOGGER.error("Workflow log files are available at %s", temp_dir)
            upload_status = "failed"

    if upload_status == "success":
        # All log files were uploaded to PanoramaWeb. Remove
        # the temporary directory
        LOGGER.info(
            "All files uploaded to PanoramaWeb."
            "Removing temporary directory '%s'",
            temp_dir,
        )
        delete_status = os.system("rm -rf {}".format(temp_dir))
        if delete_status > 0:
            LOGGER.warn(
                "There was problem removing the temp directory, %s. "
                "Error Number was %s",
                temp_dir, delete_status
            )

        return [True, upload_folder_dir_url]
    else:
        LOGGER.info(
            "There was problem uploading the workflow log files to "
            "PanoramaWeb. You can review the logs in '%s' directory.",
            temp_dir,
        )
        return [False, upload_folder_dir_url]


def get_log_file_from_cromwell(
    server, file_path, type, scp_port=22, scp_user=None, scp_key=None
):
    # Download a log file from the cromwell server
    # server: name or ip of the cromwell server
    # file_path: the path on the cromwell server of the file
    #            to be downloaded
    # type: how to perform the download. Currently only scp is supported
    # scp_user: user name to be used to authenticate to Cromwell server
    # scp_key: location of ssh key to be used by scp.
    #
    # TODO Add error handing
    logging.getLogger("paramiko").setLevel(logging.WARNING)
    if type == "scp":
        from scp import SCPClient, SCPException
        from paramiko import SSHClient, AutoAddPolicy

        # Check if ssh private key exists
        expanded_scp_key = os.path.expanduser(scp_key)
        if not os.path.isfile(expanded_scp_key):
            logstatus = (
                "SSH keyfile does not exist '{}'. Download of "
                "log file will be skipped".format(expanded_scp_key)
            )
            logmsgs = "LOGFILE DOWNLOAD ERROR"
            return logmsgs, logstatus

        ssh = SSHClient()
        # ssh.load_system_host_keys()
        ssh.set_missing_host_key_policy(AutoAddPolicy())
        ssh.connect(
            server, port=scp_port, username=scp_user,
            key_filename=expanded_scp_key, timeout=300
        )

        # Create SCP client
        scp = SCPClient(ssh.get_transport())

        # Download the file
        try:
            local_file_path = os.path.basename(file_path)
            scp.get(file_path, local_file_path)
            scp.close()
            ssh.close()
        except SCPException as err:
            err.args
            logstatus = (
                "Unable to download log file, '{}': {} ".format(
                    local_file_path, err.args
                )
            )
            logmsgs = "LOGFILE DOWNLOAD ERROR"
            return logmsgs, logstatus

        try:
            with open(local_file_path, "r") as lfh:
                logmsgs = lfh.read()
            logstatus = "True"
            os.remove(local_file_path)
        except IOError:
            logstatus = "Unable to open downloaded log file, '{}'".format(
                local_file_path
            )
            logmsgs = "LOGFILE DOWNLOAD ERROR"

        return logmsgs, logstatus
    else:
        # A non-supported download method was selected
        logstatus = (
            "Download method of '{}' was specified and "
            "this is not supported".format(type)
        )
        logmsgs = "LOGFILE DOWNLOAD ERROR"
        return logmsgs, logstatus


def hide_secrets_inputs(text):
    # Replace any secrets in text with 'XXXXXXXXXXXX'
    # There are a number of possible secrets
    # Input must be a string. The input text will be returned
    # with any secrets replaced with 'XXXXXXXXXXXX'
    ntext = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    nchar = 'X'
    # Panorama API key is 33 characters in length.
    if "apikey|" in text:
        o_arr = text.split("apikey|")
        for i in range(1, len(o_arr), 2):
            if len(o_arr[i]) == 32:
                o_arr[i] = ntext
            else:
                a = o_arr[i][32:]
                o_arr[i] = "{}{}".format(ntext, a)

        replaced_text = "apikey|".join(o_arr)
        return replaced_text
    else:
        # replace all characters in text with "X"'s
        replaced_text = nchar * len(text)
        return replaced_text


def hide_secrets_text(text):
    # Replace any secrets in text with 'XXXXXXXXXXXX'
    # There are a number of possible secrets
    # Input must be a string. The input text will be returned
    # with any secrets replaced with 'XXXXXXXXXXXX'
    nchar = 'X'
    # Panorama API key is 33 characters in length.
    if "apikey|" in text:
        secret_length = 32
        o_arr = text.split("apikey|")
        for i in range(1, len(o_arr), 2):
            if len(o_arr[i]) == 32:
                o_arr[i] = nchar * secret_length
            else:
                a = o_arr[i][32:]
                o_arr[i] = "{}{}".format(nchar * secret_length, a)

        replaced_text = "apikey|".join(o_arr)
        return replaced_text
    else:
        # Limelight user key is 44 characters in length.
        secret_length = 44
        o_arr = text.split("limelight_user_key")
        for i in range(1, len(o_arr), 2):
            if len(o_arr[i]) == secret_length:
                o_arr[i] = nchar * secret_length
            elif len(o_arr[i]) == secret_length + 1:
                a = o_arr[i][1:]
                o_arr[i] = "{}{}".format(a, nchar * secret_length)
            elif len(o_arr[i]) < secret_length:
                # if text is less than 44 characters in length, then
                # this string is not the user key
                replaced_text = text
            elif len(o_arr[i]) > secret_length + 1:
                a = o_arr[i][secret_length:]
                o_arr[i] = "{}{}{}".format(
                    o_arr[i][1], nchar * secret_length, a
                )
        replaced_text = "limelight_user_key".join(o_arr)
        return replaced_text


def convert_to_local_time(datetime_str):
    # Convert datetime string to local_tz timezone. This function
    # assumes that the incoming datetime string is using the UTC
    # timezone. This is a good assumption for Cromwell as Cromwell
    # writes all dates in Metadata in UTC by default.
    try:
        local_tz = pytz.timezone('America/Los_Angeles')

        # Create datetime object from string
        dto = datetime.datetime.strptime(datetime_str, "%Y-%m-%dT%H:%M:%S.%fZ")

        # datetime strings generated by Cromwell are always in UTC. Add the
        # timezone to the datetime object
        utc_tz = pytz.timezone('UTC')
        dto_utc = utc_tz.localize(dto)

        # Convert to local_tz
        dto_local = dto_utc.astimezone(local_tz)
    except ValueError:
        # The datetime is in the wrong format. Will use inst["start"] string
        LOGGER.warn(
            "There was a problem converting datetime to local timezone ",
            "The datetime string from the metadata will be used. This ",
            "datetime is in UTC timezone"
        )
        dto_local = datetime_str

    return dto_local


#
# Variables
#
cromwell_server_url = "http://m002.grid.gs.washington.edu:8000"
start_date = "{:%Y%m%d-%H%M%z}".format(datetime.datetime.now())
java_home = "/usr/lib/jvm/jre-1.8.0-openjdk.x86_64"
cromwell_bin = "/net/maccoss/vol1/maccoss_shared/bdconnol/cromwell/cromwell-51.jar"

# Variables for downloading logs from cromwell server
cromwell_server = "m002.grid.gs.washington.edu"
cromwell_scp_port = "22"
cromwell_scp_user = "cromwell-transfer"
cromwell_scp_key = "~/cromwell/.ssh_cromwell_rsa"


# Values for testing locally
# cromwell_server = "127.0.0.1"
# cromwell_scp_port = "8222"
# cromwell_scp_key = "/Users/bconn/.ssh/ssh_cromwell_rsa"
# cromwell_server_url = "http://127.0.0.1:8000"
# cromwell_bin = "~/bin/cromwell/cromwell-47.jar"

#
# Parse our arguments
#
parser = argparse.ArgumentParser(
    description="Submit a workflow to the MacCoss Lab Cromwell Server"
)
parser.add_argument("--workflow", help="Workflow File")
parser.add_argument("--inputs", help="Workflow Inputs")

args = parser.parse_args()

# Check for required arguments
if not args.workflow:
    LOGGER.error(
        "You must specify a workflow document on the command line. "
        "add the --workflow option and try again"
    )
    parser.print_usage()
    sys.exit(1)
else:
    if not os.path.isfile(args.workflow):
        LOGGER.error(
            "The workflow document specified on the command line. "
            "is not valid. Please check the path and try again"
        )
        sys.exit(1)

if not args.inputs:
    LOGGER.error(
        "You must specify a workflow document on the command line. "
        "add the --workflow option and try again"
    )
    parser.print_usage()
    sys.exit(1)
else:
    if not os.path.isfile(args.inputs):
        LOGGER.error(
            "The workflow document specified on the command line. "
            "is not valid. Please check the path and try again"
        )
        sys.exit(1)


#
# Find workflow name
#

try:
    workflow_name = None
    with open(args.workflow, "r") as fh:
        wf_lines = fh.readlines()
except OSError as err:
    LOGGER.error(
        "Unable to open the workflow file, '%s', "
        "Error message is %s",
        args.workflow,
        err.strerror,
    )
    sys.exit(1)

for line in wf_lines:
    if "workflow" in line:
        # Assume that words are separated by spaces in WDL file
        wf_list = line.lstrip().split(' ')
        try:
            wf_i = wf_list.index("workflow")
        except ValueError:
            LOGGER.error(
                "Workflow file is incorrectly formatted. Please review "
                "the file and try again"
            )
            sys.exit(1)
        workflow_name = wf_list[wf_i + 1]
        break

if workflow_name is None:
    LOGGER.error(
        "Workflow file is incorrectly formatted. Unable to find "
        "the word 'workflow' in the file. Please review "
        "the file and try again"
    )
    sys.exit(1)

workflow_exec_name = "{}".format(workflow_name)


#
# Submit the workflow
#

LOGGER.info(
    "Submitting the %s workflow to the Cromwell server running at %s",
    args.workflow,
    cromwell_server_url,
)

cmd = "{}/bin/java -jar {} submit {} -i {} -h {} -t wdl".format(
    java_home, cromwell_bin, args.workflow, args.inputs, cromwell_server_url
)

try:
    submit = subprocess.run(
        cmd,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=600,
        universal_newlines=True,
    )
except subprocess.TimeoutExpired:
    submit.kill()
    outs, errs = submit.communicate()
    LOGGER.error("'%s' command timed out after 10min", cmd)
    LOGGER.error(
        "Workflow submission failed with a timeout error. "
        "Check you network connection and try again"
    )
    sys.exit(1)


# Check if the workflow submission succeeded.
# The cromwell program returns a "0" for almost all conditions,
# so we will need to check both return code and messages in stdout and stderr

# Check return code
if submit.returncode:
    LOGGER.error(
        "The workflow submission has failed with return code '%d'",
        submit.returncode
    )
    LOGGER.error(
        "The error messages are '%s %s' ", submit.stdout, submit.stderr
    )

# Check contents of stderr for any error messages
outs = str(submit.stdout)
errs = submit.stderr
if "error" in errs.lower():
    LOGGER.error(
        "The workflow submission has failed. The error messages are: \n'%s' ",
        submit.stderr,
    )
    LOGGER.error("The output messages are: \n'%s'", submit.stdout)
    sys.exit(1)

# Check for other errors
if len(outs) == 0:
    LOGGER.error(
        "The workflow submission has failed. The error messages are: \n'%s' ",
        submit.stderr,
    )
    LOGGER.error("The output messages are: \n'%s'", submit.stdout)
    sys.exit(1)

if "Workflow failed to submit" in outs:
    LOGGER.error(
        "The workflow submission has failed. The error messages are: \n'%s' ",
        submit.stderr,
    )
    LOGGER.error("The output messages are: \n'%s'", submit.stdout)
    sys.exit(1)

if "Connection attempt failed" in outs:
    LOGGER.error(
        "The workflow submission has failed. The error messages are: \n'%s' ",
        submit.stderr,
    )
    LOGGER.error("The output messages are: \n'%s'", submit.stdout)
    sys.exit(1)

if "Workflow" not in outs:
    LOGGER.error(
        "The workflow submission has failed. The error messages are: \n'%s' ",
        submit.stderr,
    )
    LOGGER.error("The output messages are: \n'%s'", submit.stdout)
    sys.exit(1)


# It looks like the workflow submission has succeeded.
# Find the workflow ID
outs_array = outs.split(" ")
wi = outs_array.index("Workflow")
workflow_id = outs_array[wi + 1]
LOGGER.info("The workflow was successfully submitted to Cromwell server")
LOGGER.info("The workflow id is %s", workflow_id)

# Create a temporary directory to hold all logs and other information
try:
    temp_dir = "cromwell-{}-logs".format(workflow_id)
    os.mkdir(temp_dir)
except OSError:
    LOGGER.warn(
        "There was a problem creating the temporary directory to hold the "
        "workflow logs. No logs will be uploaded to PanoramaWeb with this run"
    )
else:
    LOGGER.info("Create directory for logs and outputs: %s ", temp_dir)

# Write stdout and stderr of submission to a file.
try:
    fh = open("{}/workflow-submit.log".format(temp_dir), "w")
    fh.write("Workflow submit output messages")
    fh.write("=================================================\n")
    fh.write(outs)
    fh.write("\n\n")
    fh.close()
except IOError:
    LOGGER.warn(
        "Unable to write to submission output file, '%s'",
        "{}/workflow-submit.log".format(temp_dir),
    )

try:
    fh = open("{}/workflow-submit.log".format(temp_dir), "a")
    fh.write("Workflow submit error messages (if any)")
    fh.write("=================================================\n")
    fh.write(errs)
    fh.write("\n\n")
    fh.close()
except IOError:
    LOGGER.warn(
        "Unable to write to submission output file, '%s'",
        "{}/workflow-submit.log".format(temp_dir),
    )

# Copy workflow file to the temp_dir
try:
    cp_status = os.system(
        "cp {} {}/{}".format(
            args.workflow, temp_dir, os.path.basename(args.workflow)
        )
    )
    if cp_status != 0:
        LOGGER.warn(
            "Unable to copy the workflow file, '%s', to logs directory. "
            "Error message is %s",
            args.inputs,
            cp_status,
        )
except OSError as err:
    LOGGER.warn(
        "Unable to copy the workflow file, '%s', to logs directory. "
        "Error message is %s",
        args.inputs,
        err.strerror,
    )

# Copy inputs file to the temp dir, but remove the API key if it exists
try:
    with open(args.inputs, "r") as fh:
        inputs_str = fh.read()
    inputs = json.loads(inputs_str)
    for key in inputs:
        if "apikey" in str(inputs[key]):
            inputs[key] = hide_secrets_inputs(str(inputs[key]))
        elif "limelight_user_key" in str(inputs[key]):
            inputs[key] = hide_secrets_inputs(str(inputs[key]))
    fh = open("{}/{}".format(temp_dir, os.path.basename(args.inputs)), "w")
    json.dump(inputs, fh)
    fh.close()
except OSError as err:
    LOGGER.warn(
        "Unable to open the inputs file, '%s', to logs directory. "
        "Error message is %s",
        args.inputs,
        err.strerror,
    )


#
# Monitor the workflow progress
#
# Check the status of the workflow
status_url = "{}/api/workflows/v1/{}/status".format(
    cromwell_server_url, workflow_id
)
status_headers = {"accept": "application/json"}

workflow_status = None
counter = 0
counter_404 = 0
while workflow_status == None:
    # if counter > 3600:
    #     LOGGER.error(
    #         "Submission of workflow to Cromwell server did not succeed "
    #         "within 5 minutes. You can manually check the status of the "
    #         "request by going to %s/api/workflows/v1/%s/status",
    #         cromwell_server_url,
    #         workflow_id,
    #     )
    #     sys.exit(1)

    try:
        resp = requests.get(status_url, headers=status_headers)
        resp.raise_for_status()
    except requests.exceptions.HTTPError as errh:
        # The status URL is not immediately available after submission of
        # workflow. Until is available, the server will respond with a 404
        # We will wait up to 1 minute for the status URL to be available.
        if resp.status_code == 404:
            LOGGER.info("Waiting for workflow to be available on server...")
            counter += 5
            counter_404 += 5
            if counter_404 >= 60:
                LOGGER.error(
                    "Workflow is not available on the server within 1 minute. "
                    "This usually means an error occurred. "
                    "You can manually check the status of the "
                    "request by going to %s/api/workflows/v1/%s/status",
                    cromwell_server_url,
                    workflow_id,
                )
                sys.exit(1)
            time.sleep(5)
            continue
        else:
            LOGGER.error(
                "Status request failed with HTTP Error %s. URL of request was %s",
                errh,
                status_url,
            )
            sys.exit(1)
    except requests.exceptions.ConnectionError as errc:
        LOGGER.error(
            "Status request failed with Error Connecting %s URL of request was %s",
            errc,
            status_url
        )
        sys.exit(1)
    except requests.exceptions.Timeout as errt:
        LOGGER.error(
            "Status request failed with Timeout Error %s URL of request was %s",
            errt,
            status_url
        )
        sys.exit(1)
    except requests.exceptions.RequestException as err:
        LOGGER.error(
            "Status request failed with error %s URL of request was %s",
            err,
            status_url
        )
        sys.exit(1)

    # Check the status response from the server
    if resp.status_code == 200:
        try:
            status_response = json.loads(resp.text)
        except json.JSONDecodeError as err:
            LOGGER.warn(
                "Status request did not return the proper content %s "
                "URL of request was %s",
                err.msg,
                status_url
            )
            LOGGER.warn("Trying status request again")
            counter += 5
            time.sleep(5)
            continue

        # Check the status code returned from the server
        LOGGER.info("Workflow status is %s", status_response["status"])
        if str(status_response["status"]).lower() == "succeeded":
            break
        elif str(status_response["status"]).lower() == "failed":
            break
        else:
            counter += 5
            time.sleep(5)
        continue
    else:
        LOGGER.error(
            "Status request failed with an error code %s. "
            "URL of request was %s. The response from the server: %s",
            resp.status_code,
            status_url,
            resp.text,
        )
        sys.exit(1)


# Workflow has submission has completed. Check status from the Cromwell server
if str(status_response["status"]).lower() == "succeeded":
    LOGGER.info("Workflow has successfully completed")
elif str(status_response["status"]).lower() == "failed":
    LOGGER.info("Workflow has failed")


# status_headers = {'accept': 'application/json'}
# temp_dir = "cromwell-22cbd9bc-691d-4997-bd50-c6ddca2a5629-logs"
# workflow_id = '22cbd9bc-691d-4997-bd50-c6ddca2a5629'
#
# Download all logs from the Cromwell server.
#

# The first step is to download the metadata. This is a json file
# which contains all information about the workflow run
metadata_url = "{}/api/workflows/v1/{}/metadata".format(
    cromwell_server_url, workflow_id
)
try:
    resp = requests.get(metadata_url, headers=status_headers)
    resp.raise_for_status()
except (
    requests.exceptions.HTTPError,
    requests.exceptions.ConnectionError,
    requests.exceptions.Timeout,
    requests.exceptions.RequestException,
) as err:
    LOGGER.error(
        "Download of workflow metadata has failed. We will upload any logs "
        "files which exist. The error was %s. URL of request was %s",
        err,
        metadata_url,
    )
    [upload_status, up_url] = upload_logs(temp_dir, args.inputs, workflow_name)
    sys.exit(1)

# Check the status response from the server
if resp.status_code == 200:
    try:
        workflow_metadata = json.loads(resp.text)
    except json.JSONDecodeError as err:
        LOGGER.warn(
            "Download of workflow metadata has failed. We will upload any "
            "logs files which exist. The download request did not return "
            "the proper content %s. URL of request was %s",
            err.msg,
            metadata_url,
        )
        [upload_status, up_url] = upload_logs(
            temp_dir, args.inputs, workflow_name
        )
        if upload_status:
            LOGGER.info(
                "Workflow logs and other files have been "
                "uploaded to {}".format(
                    up_url
                )
            )
        sys.exit(1)
else:
    LOGGER.error(
        "Download of workflow metadata has failed. We will upload any "
        "logs files which exist. "
        "Download of metadata request failed with an error code %s. "
        "URL of request was %s. The response from the server: %s",
        resp.status_code,
        metadata_url,
        resp.text,
    )
    [upload_status, up_url] = upload_logs(temp_dir, args.inputs, workflow_name)
    if upload_status:
        LOGGER.info(
            "Workflow logs and other files have been uploaded to {}".format(
                up_url
            )
        )
    sys.exit(1)

#
# Write workflow metadata to a file (Work in progress. See TODO)
# Prior to writing to the file, we need to remove any secrets from
# the file.
#
# wf_inputs = json.loads(workflow_metadata["submittedFiles"]['inputs'])
# wf_inputs['msconvert_workflow.panorama_apikey']='apikey|XXXXXXXXXXXXXXXXX'
# workflow_metadata["submittedFiles"]['inputs'] = json.dumps(wf_inputs)

# with open('{}/workflow-metadata.json'.format(temp_dir), 'w') as f:
#     f.write(json.dumps(workflow_metadata))


#
# Download all logs and log messages about the run
#
# workflow-execution.log: will contain the
#   - workflow log messages and status
#   - logs about the execution of each step
# workflow-<step-name>.log
#   - logs for each step(call) executed by workflow
#   - single file hold all output for the <step-name>
#   - if step is executed multiple times, say using a scatter over
#     multiple files, these will still be stored in a single file.
#
# Create the workflow-execution.log
LOGGER.info("Creating the workflow execution log...")

try:
    # Open logs file
    wf_exec_fh = open("{}/workflow-execution.log".format(temp_dir), "w")

    # Write header information for the log file
    wf_exec_fh.write(
        "Workflow execution log for {} workflow\n".format(workflow_exec_name)
    )
    wf_exec_fh.write("=================================================\n")
    wf_exec_fh.write("=================================================\n")
    wf_exec_fh.write("Workflow ID: {}\n".format(workflow_id))
    wf_exec_fh.write(
        "Workflow Status: {}\n".format(workflow_metadata["status"])
    )
    # Convert workflow start and end dates to local timezone
    wf_start_dto = convert_to_local_time(workflow_metadata["start"])
    wf_end_dto = convert_to_local_time(workflow_metadata["end"])
    wf_exec_fh.write("Workflow Start Time: {}\n".format(wf_start_dto))
    wf_exec_fh.write("Workflow End Time: {}\n".format(wf_end_dto))

    wf_exec_fh.write("Workflow file: {}\n".format(args.workflow))
    wf_exec_fh.write("Workflow inputs file: {}\n".format(args.inputs))
    wf_exec_fh.write("=================================================\n")
    wf_exec_fh.write("=================================================\n\n")

    # Write log information for each call in the workflow
    for call in workflow_metadata["calls"]:
        for inst in workflow_metadata["calls"][call]:
            # Convert start and end dates to local timezone
            start_dto = convert_to_local_time(inst["start"])
            end_dto = convert_to_local_time(inst["end"])

            if str(inst["shardIndex"]) == "-1":
                call_name = call
            else:
                call_name = "{}-{}".format(call, inst["shardIndex"])
            LOGGER.info("Collect log messages for call {}".format(call_name))
            wf_exec_fh.write("\n")
            wf_exec_fh.write("=============================================\n")
            wf_exec_fh.write("=============================================\n")
            wf_exec_fh.write("Call Name: {}\n".format(call_name))
            wf_exec_fh.write(
                "Call Status: {}\n".format(inst["executionStatus"])
            )
            wf_exec_fh.write(
                "Call Results from Cache?: {}\n".format(
                    inst["callCaching"]["hit"]
                )
            )
            wf_exec_fh.write("Call Start: {}\n".format(start_dto))
            wf_exec_fh.write("Call End: {}\n".format(end_dto))
            for key, value in inst["inputs"].items():
                if key == "apikey":
                    input_value = hide_secrets_inputs(value)
                elif key == "limelight_user_key":
                    input_value = hide_secrets_inputs(value)
                else:
                    input_value = value
                wf_exec_fh.write(
                    "Call Input: {}={}\n".format(key, input_value)
                )
            # If the call was not executed because a previous run in the cache,
            # then the stderr and stdout files specified in the metadata are
            # wrong. The log files are in the `cacheCopy` subdirectory.
            if inst["callCaching"]["hit"] is False:
                stdout_file = inst["stdout"]
                stderr_file = inst["stderr"]
            else:
                stdout_file = "{}/cacheCopy/execution/stdout".format(
                    inst["callRoot"]
                )
                stderr_file = "{}/cacheCopy/execution/stderr".format(
                    inst["callRoot"]
                )

            # Copy log messages from call stdout to workflow_execution log file
            wf_exec_fh.write("\n")
            wf_exec_fh.write(
                "Call output messages: "
                "(Messages below copied from call log file {}:{}\n".format(
                    cromwell_server, stdout_file
                )
            )
            wf_exec_fh.write("==================\n")

            logmsgs, logstatus = get_log_file_from_cromwell(
                cromwell_server,
                stdout_file,
                "scp",
                cromwell_scp_port,
                cromwell_scp_user,
                cromwell_scp_key,
            )
            if logstatus == "True":
                logmsgs_cleaned = hide_secrets_text(logmsgs)
                wf_exec_fh.write(logmsgs_cleaned + "\n")
            else:
                wf_exec_fh.write(
                    "Log file could not be downloaded. Error was {}\n".format(
                        logstatus
                    )
                )
                LOGGER.warn(
                    "Log file could not be downloaded. Error was {}\n".format(
                        logstatus
                    )
                )
            wf_exec_fh.write("\n")

            # Copy log messages from call stderr to workflow_execution log file
            wf_exec_fh.write(
                "Call error messages: "
                "(Messages below copied from call log file {}:{}\n".format(
                    cromwell_server, stderr_file
                )
            )
            wf_exec_fh.write("==================\n")

            logmsgs, logstatus = get_log_file_from_cromwell(
                cromwell_server,
                stderr_file,
                "scp",
                cromwell_scp_port,
                cromwell_scp_user,
                cromwell_scp_key,
            )
            if logstatus == "True":
                logmsgs_cleaned = hide_secrets_text(logmsgs)
                wf_exec_fh.write(logmsgs_cleaned + "\n")
            else:
                wf_exec_fh.write(
                    "Log file could not be downloaded. Error was {}\n".format(
                        logstatus
                    )
                )
                LOGGER.warn(
                    "Log file could not be downloaded. Error was {}\n".format(
                        logstatus
                    )
                )

            # If this calls was not successful, then it will output messages
            # into the `failures` node. Grab these nodes and write them
            # to the logfile
            if inst["executionStatus"] == "Failed":
                wf_exec_fh.write("\n")
                wf_exec_fh.write(
                    "Cromwell Server error message was {}\n".format(
                        inst["failures"][0]["message"]
                    )
                )
                # wf_exec_fh.write("Output below from file = {}.background\n".format(inst['stderr']))
                # logmsgs, logstatus = get_log_file_from_cromwell(cromwell_server, "{}.background".format(stderr_file ), 'scp', cromwell_scp_port, cromwell_scp_user, cromwell_scp_key)
                # if logstatus:
                #     logmsgs_cleaned = hide_secrets_text(logmsgs)
                #     wf_exec_fh.write(logmsgs_cleaned + "\n")
                # else:
                #     wf_exec_fh.write("Log file could not be downloaded. Error was {}\n".format(logstatus))
                #     LOGGER.warn("Log file could not be downloaded. Error was %s\n".format(logstatus))

            wf_exec_fh.write("=============================================\n")
            wf_exec_fh.write("=============================================\n")
            wf_exec_fh.write("\n\n")

    wf_exec_fh.close()
except IOError:
    LOGGER.warn(
        "Unable to write execution log file, '%s'",
        "{}/workflow-execution.log".format(temp_dir),
    )
    [upload_status, up_url] = upload_logs(temp_dir, args.inputs, args.name)
    if upload_status:
        LOGGER.info(
            "Workflow logs and other files have been uploaded to {}".format(
                up_url
            )
        )

#
# Upload all logs in the 'temp_dir' to PanoramaWeb server
#
# The logs will be uploaded to the WebDav URL specified in the
# workflow inputs:
# - For MsconvertWorkflow we will use the folder specified in
#   "msconvert_workflow.url_webdav_converted_files_folder" input.
# - For PanoramaSkylineWorkflow, we will use the folder specified in
#   "panorama_skyline_workflow_scatter.url_target_panorama_folder"
#   input.
#
[upload_status, up_url] = upload_logs(
    temp_dir, args.inputs, workflow_name
)
if upload_status:
    LOGGER.info(
        "Workflow logs and other files have been uploaded to {}".format(
            up_url
        )
    )
    LOGGER.info(
        "The workflow execution log can be viewed at "
        "{}/workflow-execution.log".format(up_url)
    )
