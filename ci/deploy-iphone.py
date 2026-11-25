#!/usr/bin/env python3
"""Build the current checkout, install it on an iPhone, and check launch survival.

Requires Xcode, XcodeGen, and an Apple account configured in Xcode. Set
LOGBOOK_DEVELOPMENT_TEAM to the existing team ID. LOGBOOK_DEVICE_UDID selects
a phone when several are connected. Build products and evidence stay in /tmp
unless LOGBOOK_DEPLOY_RESULTS names another directory.
The team-specific bundle ID defaults to com.logbook.<lowercase team ID>.
LOGBOOK_BUNDLE_ID can override it; its dedicated App Group is group.<bundle ID>.
Register that group for the app and widget in Xcode Signing & Capabilities once.
"""

import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile
import time


ROOT = Path(__file__).resolve().parents[1]


def deploy():
    team = os.environ.get("LOGBOOK_DEVELOPMENT_TEAM")
    if not team:
        sys.exit("Set LOGBOOK_DEVELOPMENT_TEAM to your existing Apple Developer team ID.")
    results = Path(os.environ.get("LOGBOOK_DEPLOY_RESULTS") or tempfile.mkdtemp(prefix="logbook-iphone-")).resolve()
    results.mkdir(parents=True, exist_ok=True)
    print(f"Deployment evidence: {results}", flush=True)

    def device_command(arguments, name):
        output = results / f"{name}.json"
        subprocess.run(["xcrun", "devicectl", *arguments, "--timeout", "120",
                        "--json-output", str(output)], stdout=subprocess.DEVNULL, check=True)
        return json.loads(output.read_text())["result"]

    devices = device_command(["list", "devices"], "devices")["devices"]
    requested = os.environ.get("LOGBOOK_DEVICE_UDID")
    phones = []
    for device in devices:
        properties = device.get("properties", {})
        hardware = properties.get("hardware", device.get("hardwareProperties", {}))
        connection = properties.get("connection", device.get("connectionProperties", {}))
        if hardware.get("deviceType") != "iPhone" or hardware.get("reality") != "physical":
            continue
        if connection.get("state", connection.get("tunnelState")) not in ("connected", "available"):
            continue
        if requested and requested not in (device["identifier"], hardware.get("udid")):
            continue
        phones.append((device, hardware))
    if len(phones) != 1:
        sys.exit("Connect and unlock one iPhone, or select it with LOGBOOK_DEVICE_UDID.")
    device, hardware = phones[0]
    identifier = device["identifier"]
    print(f"Building Logbook for {hardware.get('marketingName', 'iPhone')}.", flush=True)

    # Generate away from the working project, preserving local Xcode settings.
    source = results / "source"
    shutil.copytree(ROOT / "native-ios", source,
                    ignore=shutil.ignore_patterns("*.xcodeproj", "QA", "DerivedData"))
    spec = source / "project.yml"
    contents = spec.read_text()
    bundle_id = os.environ.get("LOGBOOK_BUNDLE_ID", f"com.logbook.{team.lower()}")
    app_group = f"group.{bundle_id}"
    contents = contents.replace("com.example.logbook", bundle_id)
    contents = contents.replace(f"group.{bundle_id}", app_group)
    # This companion contains its SwiftUI executable in one modern watch target.
    contents = contents.replace("type: application.watchapp2", "type: application")
    contents = contents.replace("WKWatchKitApp: true", "WKApplication: true")
    contents = contents.replace("      - target: LogbookWidgets\n",
                                "      - target: LogbookWidgets\n      - target: LogbookWatch\n        embed: true\n", 1)
    spec.write_text(contents)
    shared = source / "Shared/SharedStateFile.swift"
    shared.write_text(shared.read_text().replace("group.com.example.logbook", app_group))
    subprocess.run(["xcodegen", "generate", "--spec", str(spec)], cwd=source, check=True)
    derived = results / "DerivedData"
    command = ["xcodebuild", "-project", str(source / "Logbook.xcodeproj"),
               "-scheme", "Logbook", "-configuration", "Debug",
               "-destination", f"platform=iOS,id={hardware['udid']}",
               "-derivedDataPath", str(derived), "-allowProvisioningUpdates",
               "-allowProvisioningDeviceRegistration", f"DEVELOPMENT_TEAM={team}",
               "CODE_SIGN_STYLE=Automatic", "build"]
    print(f"Build log: {results / 'build.log'}", flush=True)
    with (results / "build.log").open("w") as log:
        subprocess.run(command, cwd=source, stdout=log, stderr=subprocess.STDOUT, check=True)
    app = derived / "Build/Products/Debug-iphoneos/Logbook.app"
    with (app / "Info.plist").open("rb") as info:
        bundle = plistlib.load(info)["CFBundleIdentifier"]
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    device_command(["device", "install", "app", "--device", identifier, str(app)], "install")
    launch = device_command(["device", "process", "launch", "--device", identifier, bundle], "launch")
    pid = launch["process"]["processIdentifier"]
    time.sleep(15)
    processes = device_command(["device", "info", "processes", "--device", identifier], "processes")
    if not any(process.get("processIdentifier") == pid for process in processes["runningProcesses"]):
        sys.exit(f"Logbook process {pid} exited within 15 seconds. Inspect device crash logs.")
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    summary = {"source_commit": commit, "bundle_id": bundle, "process_id": pid,
               "app_group": app_group, "development_team": team,
               "launch_survived_seconds": 15, "device_model": hardware.get("marketingName"),
               "source_changes": subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT, text=True)}
    (results / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print("Logbook installed and launched; its process remained alive after 15 seconds.")


if __name__ == "__main__":
    try:
        deploy()
    except (subprocess.CalledProcessError, KeyError, OSError) as error:
        sys.exit(f"Deployment stopped: {error}. Review the deployment evidence directory printed above.")
