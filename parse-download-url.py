#!/usr/bin/env python3

# The original author of this program, clover-linux-installer, is StarBrilliant.
# This file is released under General Public License version 3.
# You should have received a copy of General Public License text alongside with
# this program. If not, you can obtain it at http://gnu.org/copyleft/gpl.html .
# This program comes with no warranty, the author will not be resopnsible for
# any damage or problems caused by this program.

import json
import sys
import re

if __name__ == '__main__':
    regex = re.compile(r'CloverV2-.*\.zip', re.IGNORECASE)
    obj = json.load(sys.stdin.buffer)
    urls = [i['browser_download_url'] for i in obj['assets'] if regex.fullmatch(i['name'])]
    print(urls[0])
