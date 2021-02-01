#!/usr/bin/env python3
"""
This script will download a file from a Panorama Server.

The downloaded file will be stored in the current working directory

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
parser = argparse.ArgumentParser(description="Download file from a Panorama Server")
parser.add_argument("--url")
parser.add_argument("--debug", action="store_true", help="Show debug messages")
args = parser.parse_args()

# Check for require arguments
if not args.url:
    logger.error("A url to the file must be specified on the command line")
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

# Download the file
local_filename = args.url.split('/')[-1]
logger.info("Download %s from %s", local_filename, args.url)
try:
    with open(local_filename, 'wb') as f:
        resp = requests.get(args.url, stream=True)
        resp.raise_for_status()
        for chunk in resp.iter_content(chunk_size=1024):
            if chunk:  # filter out keep-alive new chunks
                f.write(chunk)
except requests.exceptions.HTTPError as errh:
    logger.error("Download failed with Http Error %s",errh)
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

logger.info("%s successfully downloaded", local_filename)
