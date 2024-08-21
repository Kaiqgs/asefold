#!/usr/bin/env python3
import sys
import argparse
import json
import re
import subprocess

RM_ALIAS = "_~rm_me_~"
EXPORT_FILE = "asefold.lua"
EXTENSION_FILE = "extension.lua"
ZIP_FILE = "asefold.v{}.aseprite-extension"
PACKAGE_FILE = "package.json"
REMOVE_PATTERNS = [
    [
        r".*_ignore_start_(.|\s|)*?_ignore_end_\s", ""
    ],
    [
        r".*inspect\..*", ""
    ],
    [
        r".*print\(.*", ""
    ],
]

def preprocess_extension():
    with open(EXPORT_FILE, "r") as f:
        content = f.read()

    result = content[::]
    for pattern, replacement in REMOVE_PATTERNS:
        result = re.sub(pattern, replacement, result)
    
    # result = result.replace(RM_ALIAS, "").replace(f"\n{RM_ALIAS}", "").replace(f"\r{RM_ALIAS}", "")

    result = "\n".join([line for line in result.split("\n") if line ])

    with open(EXTENSION_FILE, "w+") as f:
        f.write(result)
    
    print(len(content), len(result))

def get_version():
    with open(PACKAGE_FILE, "r") as f:
        return json.loads(f.read())["version"]

def main():
    argparser = argparse.ArgumentParser()
    argparser.add_argument("--keep", "-k", action="store_true")
    args = argparser.parse_args()
    preprocess_extension()
    version = get_version()
    rm_extension = f"&& rm {EXTENSION_FILE}"
    rm_extension = "" if args.keep else rm_extension
    subprocess.Popen(f"zip {ZIP_FILE.format(version)} {EXTENSION_FILE} extension-keys.aseprite-keys package.json LICENSE {rm_extension} && echo 'finished exporting {ZIP_FILE.format(version)}'", shell=True)



if __name__ == "__main__":
    main()
