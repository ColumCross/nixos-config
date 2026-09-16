#!/usr/bin/env python3
import json
import os
import socket
import subprocess
import sys


LEFT_DISPLAY = "HP Inc. HP E243 CNC8501MRZ"
RIGHT_DISPLAY = "HP Inc. HP E243 CNK828106Z"
LAPTOP_DISPLAY = "eDP-1"


class TopologyError(RuntimeError):
    pass


def targets(monitors):
    names = {monitor.get("description"): monitor["name"] for monitor in monitors}
    laptop = next((monitor["name"] for monitor in monitors if monitor.get("name") == LAPTOP_DISPLAY), None)
    left = names.get(LEFT_DISPLAY)
    right = names.get(RIGHT_DISPLAY)
    if left and right:
        result = {"1": left, "2": right}
        if laptop:
            result["3"] = laptop
        return result
    return {"1": laptop} if laptop else {}


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

    def apply(self):
        active = self.active_workspace()
        assignments = targets(self.monitors())
        for workspace, monitor in assignments.items():
            self.dispatch("workspace", f"name:{workspace}")
            self.dispatch("moveworkspacetomonitor", f"name:{workspace}", monitor)
        if assignments:
            self.dispatch("workspace", f"id:{active['id']}")


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
                    controller.apply()


if __name__ == "__main__":
    try:
        listen(Controller())
    except TopologyError as error:
        print(f"workspace-topology: {error}", file=sys.stderr)
        sys.exit(1)
