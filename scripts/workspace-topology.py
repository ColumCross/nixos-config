#!/usr/bin/env python3
import json
import os
import socket
import subprocess
import sys
import time


LEFT_DISPLAY = "HP Inc. HP E243 CNC8501MRZ"
RIGHT_DISPLAY = "HP Inc. HP E243 CNK828106Z"
LAPTOP_DISPLAY = "eDP-1"
LID_STATE_PATH = "/proc/acpi/button/lid/LID0/state"


class TopologyError(RuntimeError):
    pass


def targets(monitors, include_laptop=True):
    names = {monitor.get("description"): monitor["name"] for monitor in monitors}
    laptop = next((monitor["name"] for monitor in monitors if monitor.get("name") == LAPTOP_DISPLAY), None)
    left = names.get(LEFT_DISPLAY)
    right = names.get(RIGHT_DISPLAY)
    if left and right:
        result = {"1": left, "2": right}
        if laptop and include_laptop:
            result["3"] = laptop
        return result
    return {"1": laptop} if laptop and include_laptop else {}


def displays(monitors):
    names = {monitor.get("description"): monitor["name"] for monitor in monitors}
    return names.get(LEFT_DISPLAY), names.get(RIGHT_DISPLAY)


class Controller:
    def __init__(self, runner=subprocess.run):
        self.runner = runner

    def run(self, command):
        try:
            result = self.runner(command, capture_output=True, text=True, check=False)
        except OSError as error:
            raise TopologyError(str(error)) from error
        if result.returncode != 0:
            raise TopologyError((result.stderr or result.stdout or "hyprctl failed").strip())
        return result.stdout.strip()

    def dispatch(self, dispatcher, *arguments):
        reply = self.run(["hyprctl", "--", "dispatch", dispatcher, *arguments])
        if reply != "ok":
            raise TopologyError(f"{dispatcher} failed: {reply or 'empty response'}")

    def monitors(self):
        try:
            monitors = json.loads(self.run(["hyprctl", "monitors", "-j"]))
        except json.JSONDecodeError as error:
            raise TopologyError(f"Invalid monitor JSON: {error.msg}") from error
        if not isinstance(monitors, list):
            raise TopologyError("Hyprland returned an invalid monitor list")
        return monitors

    def active_workspace(self):
        try:
            workspace = json.loads(self.run(["hyprctl", "activeworkspace", "-j"]))
        except json.JSONDecodeError as error:
            raise TopologyError(f"Invalid active workspace JSON: {error.msg}") from error
        if not isinstance(workspace, dict) or "id" not in workspace:
            raise TopologyError("Hyprland returned an invalid active workspace")
        return workspace

    def lid_is_open(self):
        try:
            with open(LID_STATE_PATH, encoding="utf-8") as lid_state:
                return lid_state.read().strip().endswith("open")
        except OSError:
            return True

    def reconcile_monitor(self, monitors, lid_open):
        left, right = displays(monitors)
        laptop = next((monitor["name"] for monitor in monitors if monitor.get("name") == LAPTOP_DISPLAY), None)
        if not laptop:
            return
        if not lid_open and (left or right):
            self.run(["hyprctl", "keyword", "monitor", f"{LAPTOP_DISPLAY},disable"])
        elif left and right:
            self.run(["hyprctl", "keyword", "monitor", os.environ["WORKSPACE_TOPOLOGY_DOCKED_LAPTOP_RULE"]])
        else:
            self.run(["hyprctl", "keyword", "monitor", os.environ["WORKSPACE_TOPOLOGY_UNDOCKED_LAPTOP_RULE"]])

    def apply(self, lid_open=None):
        monitors = self.monitors()
        lid_open = self.lid_is_open() if lid_open is None else lid_open
        self.reconcile_monitor(monitors, lid_open)
        active = self.active_workspace()
        assignments = targets(monitors, include_laptop=lid_open)
        for workspace, monitor in assignments.items():
            self.dispatch("workspace", f"name:{workspace}")
            self.dispatch("moveworkspacetomonitor", f"name:{workspace}", monitor)
        if assignments:
            selector = str(active["id"]) if active["id"] > 0 else f"name:{active['name']}"
            self.dispatch("workspace", selector)


def listen(controller):
    controller.apply()
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR")
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not runtime_dir or not signature:
        raise TopologyError("Hyprland session environment is unavailable")
    socket_path = os.path.join(runtime_dir, "hypr", signature, ".socket2.sock")
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as event_socket:
        event_socket.connect(socket_path)
        with event_socket.makefile(encoding="utf-8") as events:
            for event in events:
                if event.startswith(("monitoradded", "monitorremoved")):
                    time.sleep(0.5)
                    controller.apply()


def main(arguments):
    controller = Controller()
    if arguments == ["listen"]:
        listen(controller)
    elif arguments == ["lid", "open"]:
        controller.apply(lid_open=True)
    elif arguments == ["lid", "close"]:
        controller.apply(lid_open=False)
    else:
        raise TopologyError("Invalid workspace-topology command")


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except TopologyError as error:
        print(f"workspace-topology: {error}", file=sys.stderr)
        sys.exit(1)
