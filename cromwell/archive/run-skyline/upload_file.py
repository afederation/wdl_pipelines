#!/usr/bin/env python3
"""
This script will upload a file from a Panorama Server.

Output logs messages will be written to standard out

If the download fails for any reason, the script will exit with a
non-zero return code.

"""
import argparse
from urllib.parse import urlparse
import requests
import logging
import sys


logging.basicConfig(level=logging.INFO, format='%(asctime)s: %(levelname)s: %(message)s')
logger = logging.getLogger()

#
# Parse our arguments.
#
parser = argparse.ArgumentParser(
    description="Upload file from a Panorama Server"
)
parser.add_argument("--url", help="URL for the Panorama server")
parser.add_argument(
    "--folder",
    help="The folder on Panorama Server where files will be uploaded"
)
parser.add_argument("--file-name")
parser.add_argument(
    "--experiment",
    help="The name of the experiment where file should be uploaded",
    default=""
)
parser.add_argument("--debug", action="store_true", help="Show debug messages")
args = parser.parse_args()

# Check for require arguments
if not args.url:
    logger.error(
        "A url to a Panorama server must be specified on the command line"
    )
    parser.print_usage()
    sys.exit(1)
if not args.folder:
    logger.error(
        "Folder on Panorama server must be specified on the command line"
    )
    parser.print_usage()
    sys.exit(1)
if not args.file_name:
    logger.error(
        "The file to be uploaded must be specified on the command line"
    )
    parser.print_usage()
    sys.exit(1)
if args.debug: 
    logger.info("Args: %s" % args)


# Verify URL is a URL
parsed_url = urlparse(args.url)
if not parsed_url.scheme:
    raise ValueError("URL specified is not valid. Please enter valid URL")
if not parsed_url.netloc:
    raise ValueError("URL specified is not valid. Please enter valid URL")

# Authenticate to server
csrf_url = "{}/login/{}/whoami.api".format(
    args.url,
    args.folder
)
try:
    csrf_response = requests.get(csrf_url)
    csrf_response_json = csrf_response.json()
    csrf_response.close()

    csrf_header = csrf_response_json['CSRF']
    csrf_cookies = requests.utils.dict_from_cookiejar(csrf_response.cookies)
except requests.exceptions.HTTPError as errh:
    logger.error(
        "Authenticating to the server failed with Http Error %s",
        errh
    )
    sys.exit(1)
except requests.exceptions.ConnectionError as errc:
    logger.error(
        "Authenticating to the server Download failed with Error Connecting %s",
        errc
    )
    sys.exit(1)
except requests.exceptions.Timeout as errt:
    logger.error(
        "Authenticating to the server Download failed with Timeout Error %s",
        errt
    )
    sys.exit(1)
except requests.exceptions.RequestException as err:
    logger.error(
        "Authenticating to the server Download failed with error %s",
        err
    )
    sys.exit(1)

# Create URL which will be used to upload the file
url = "{}/_webdav/{}/%40files/{}/?Accept=application/json&overwrite=T&X-LABKEY-CSRF={}".format(
    args.url,
    args.folder,
    args.experiment,
    csrf_header
)

# Create the dictionary containing the file name and other file attributes
files = {
    'file': (
        args.file_name.split('/')[-1:][0], open(args.file_name, 'rb'),
        'application/octet-stream',
        {'Expires': '0'}
    )
}

# Upload the file
logger.info(
    "Upload %s to %s folder on %s",
    args.file_name,
    args.folder,
    args.url
)
try:
    # Upload the file
    upload_response = requests.post(url, files=files, cookies=csrf_cookies)

    # Check if upload was successful
    #   HTTP response code of 207 indicates success.
    #   All other response codes indicate failure
    if upload_response.status_code == 207:
        logger.info("%s successfully uploaded", args.file_name)
    else:
        upload_text = upload_response.text.split('{')[1].split('}')[0].split(',')
        logger.error(
            "Upload of %s has failed", args.file_name
        )
        logger.error(
            "HTTP reponse from the server is %s. "
            "Status message from the server is %s",
            upload_response.status_code,
            upload_text
        )
        sys.exit(1)
except requests.exceptions.HTTPError as errh:
    logger.error("Download failed with Http Error %s", errh)
    sys.exit(1)
except requests.exceptions.ConnectionError as errc:
    logger.error("Download failed with Error Connecting %s", errc)
    sys.exit(1)
except requests.exceptions.Timeout as errt:
    logger.error("Download failed with Timeout Error %s", errt)
    sys.exit(1)
except requests.exceptions.RequestException as err:
    logger.error("Download failed with error %s", err)
    sys.exit(1)
