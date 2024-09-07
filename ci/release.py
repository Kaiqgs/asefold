#!/usr/bin/env python3
from datetime import datetime, timedelta

import time
from watchdog.events import FileSystemEvent, FileSystemEventHandler
from watchdog.observers import Observer
from watchdog.observers.polling import PollingObserver
import watchdog
import warnings
import argparse
import json
import re
import subprocess

RM_ALIAS = "_~rm_me_~"
ASE_EXTENSION_FOLDER = "/home/kags/.config/aseprite/extensions/asefold"
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
are_we_running = False

def preprocess_extension(is_release):
    with open(EXPORT_FILE, "r") as f:
        content = f.read()

    result = content[::]
    for pattern, replacement in REMOVE_PATTERNS:
        if not is_release:
            break
        result = re.sub(pattern, replacement, result)
    
    # result = result.replace(RM_ALIAS, "").replace(f"\n{RM_ALIAS}", "").replace(f"\r{RM_ALIAS}", "")

    result = "\n".join([line for line in result.split("\n") if line ])

    with open(EXTENSION_FILE, "w+") as f:
        f.write(result)
    
    print(len(content), len(result))



# add automatically all scripts in package contributes in ZIP
def preprocess_package(is_release):
    with open(PACKAGE_FILE, "r") as f:
        package_json = json.loads(f.read())
    contributes_scripts = [script["path"].replace("./", "") for script in package_json["contributes"]["scripts"]]
    # assert (is_release and len(contributes_scripts) == 1 and contributes_scripts[0] == "extension.lua") or not is_release
    if is_release:
        data = package_json['contributes']['scripts']
        warnings.warn(f"You are throwing away: {data}")
        package_json["contributes"]["scripts"] = [{"path": "./extension.lua"}]
        with open(PACKAGE_FILE, "w+") as f:
            json.dump(package_json, f, indent=2)
            contributes_scripts = [script["path"].replace("./", "") for script in package_json["contributes"]["scripts"]]
        package_json["contributes"]["scripts"] = data

    contributes_files = " ".join(contributes_scripts)
    print(contributes_files)
    return package_json, contributes_files


class AsefoldHandler(FileSystemEventHandler):
    def __init__(self, args:argparse.Namespace, *argses, **kwargs):
        super().__init__(*argses, **kwargs)
        self.args = args
        self.last_modified = datetime.now()
    def on_any_event(self, event):
        if datetime.now() - self.last_modified < timedelta(seconds=1):
            return
        else:
            self.last_modified = datetime.now()
        # time.sleep(.5)
        # print(f"Event: {event} {are_we_running}")
        if not event.is_directory:
            # and event.src_path != self.last_event
            # print("Running")
            run(self.args)

    # def on_created(self, event:FileSystemEvent):
    #     print(f"Event: {event}")
    #
    # def on_deleted(self, event:FileSystemEvent):
    #     print(f"Event: {event}")

def run(args:argparse.Namespace):
    package_json, contribute_files = preprocess_package(args.release)
    version = package_json["version"]
    preprocess_extension(args.release)
    rm_extension = f"&& rm {EXTENSION_FILE}"
    rm_extension = "" if args.keep else rm_extension
    # all_files_by_space
    all_files = f"extension-keys.aseprite-keys package.json LICENSE {contribute_files}"
    command = ""
    if not args.move:
        command = f"zip {ZIP_FILE.format(version)} {all_files} {rm_extension} && echo 'finished exporting {ZIP_FILE.format(version)}'"
    else:
        # this shit does not work, aseprite does not reload from files
        command = f"cp {all_files} {ASE_EXTENSION_FOLDER}"
    print(f"Running: `{command}`")
    subprocess.Popen(command, shell = True).communicate()

    with open(PACKAGE_FILE, "w+") as f:
        json.dump(package_json, f, indent=2)
    # print("...")


def main():
    argparser = argparse.ArgumentParser()
    argparser.add_argument("--keep", "-k", action="store_true")
    argparser.add_argument("--release", "-r", action="store_true")
    argparser.add_argument("--move", "-m", action="store_true")
    argparser.add_argument("--watch", "-w", action="store_true")
    args = argparser.parse_args()

    if args.watch:
        watcher = AsefoldHandler(args)
        observer = PollingObserver()
        observer.schedule(watcher, path=EXPORT_FILE, recursive=True)
        observer.start()
        try:
            while True:
                time.sleep(.1)
                pass
                # run(args)
        except KeyboardInterrupt:
            observer.stop()
        observer.join()
        return

    run(args)


if __name__ == "__main__":
    main()
