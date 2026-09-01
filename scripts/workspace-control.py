#!/usr/bin/env python3
import fcntl
import json
import os
import signal
import subprocess
import sys
import time
import uuid
from contextlib import contextmanager


class WorkspaceError(RuntimeError):
    pass


def numbered(workspace):
    name = workspace["name"]
    return name.isdecimal() and 1 <= int(name) <= 10 and str(int(name)) == name


def sorted_numbered(workspaces):
    selected = [workspace for workspace in workspaces if numbered(workspace)]
    selected.sort(key=lambda workspace: int(workspace["name"]))
    names = [workspace["name"] for workspace in selected]
    ids = [workspace["id"] for workspace in selected]
    if len(names) != len(set(names)) or len(ids) != len(set(ids)):
        raise WorkspaceError("Numbered desktops are not uniquely identified")
    if [int(name) for name in names] != list(range(1, len(names) + 1)):
        raise WorkspaceError("Numbered desktops must be consecutive from 1")
    return selected


def reordered_ids(workspaces, source_id, target_id, placement):
    ordered = sorted_numbered(workspaces)
    ids = [workspace["id"] for workspace in ordered]
    if source_id not in ids or target_id not in ids:
        raise WorkspaceError("Only existing numbered desktops can be reordered")
    if source_id == target_id:
        return ids

    ids.remove(source_id)
    target_index = ids.index(target_id)
    if placement == "after":
        target_index += 1
    elif placement != "before":
        raise WorkspaceError("Invalid desktop drop placement")
    ids.insert(target_index, source_id)
    return ids


def rename_steps(workspaces, source_id, target_id, placement, temporary_name):
    ordered = sorted_numbered(workspaces)
    original_ids = [workspace["id"] for workspace in ordered]
    final_ids = reordered_ids(workspaces, source_id, target_id, placement)
    if original_ids == final_ids:
        return []

    old_index = original_ids.index(source_id)
    new_index = final_ids.index(source_id)
    steps = [(source_id, temporary_name)]
    if old_index < new_index:
        affected = range(old_index + 1, new_index + 1)
    else:
        affected = range(old_index - 1, new_index - 1, -1)
    for index in affected:
        steps.append((original_ids[index], str(final_ids.index(original_ids[index]) + 1)))
    steps.append((source_id, str(new_index + 1)))
    return steps


class Controller:
    def __init__(self, runner=subprocess.run, environ=os.environ):
        self.runner = runner
        self.environ = environ

    def log(self, message):
        print(f"workspace-control: {message}", file=sys.stderr)

    def notify(self, message):
        self.log(message)
        try:
            self.runner(["notify-send", "Workspace Reordering", message], check=False)
        except OSError:
            pass

    def run(self, command):
        try:
            result = self.runner(command, capture_output=True, text=True, check=False)
        except OSError as error:
            raise WorkspaceError(str(error)) from error
        if result.returncode != 0:
            raise WorkspaceError((result.stderr or result.stdout or "hyprctl failed").strip())
        return result.stdout.strip()

    def dispatch(self, dispatcher, *arguments):
        reply = self.run(["hyprctl", "--", "dispatch", dispatcher, *map(str, arguments)])
        if reply != "ok":
            raise WorkspaceError(f"{dispatcher} failed: {reply or 'empty response'}")

    def workspaces(self):
        reply = self.run(["hyprctl", "workspaces", "-j"])
        try:
            workspaces = json.loads(reply)
        except json.JSONDecodeError as error:
            raise WorkspaceError(f"Invalid workspace JSON: {error.msg}") from error
        if not isinstance(workspaces, list):
            raise WorkspaceError("Hyprland returned an invalid workspace list")
        return workspaces

    def active_workspace(self):
        reply = self.run(["hyprctl", "activeworkspace", "-j"])
        try:
            workspace = json.loads(reply)
        except json.JSONDecodeError as error:
            raise WorkspaceError(f"Invalid active workspace JSON: {error.msg}") from error
        if not isinstance(workspace, dict) or "id" not in workspace:
            raise WorkspaceError("Hyprland returned an invalid active workspace")
        return workspace

    @contextmanager
    def lock(self):
        runtime_dir = self.environ.get("XDG_RUNTIME_DIR")
        signature = self.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
        if not runtime_dir or not signature:
            raise WorkspaceError("Hyprland session environment is unavailable")
        lock_path = os.path.join(runtime_dir, f"workspace-control-{signature}.lock")
        with open(lock_path, "w", encoding="utf-8") as lock_file:
            deadline = time.monotonic() + 1
            while True:
                try:
                    fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    break
                except BlockingIOError:
                    if time.monotonic() >= deadline:
                        raise WorkspaceError("Another desktop reorder is still running")
                    time.sleep(0.05)
            try:
                yield
            finally:
                fcntl.flock(lock_file, fcntl.LOCK_UN)

    def snapshot(self):
        workspaces = self.workspaces()
        return sorted_numbered(workspaces)

    def verify_names(self, expected):
        actual = {workspace["id"]: workspace["name"] for workspace in self.workspaces()}
        if any(actual.get(workspace_id) != name for workspace_id, name in expected.items()):
            raise WorkspaceError("Hyprland did not apply the expected desktop names")

    def restore(self, original):
        rollback_prefix = f"workspace-control-rollback-{uuid.uuid4().hex}"
        failures = []
        for index, workspace_id in enumerate(original):
            try:
                self.dispatch("renameworkspace", workspace_id, f"{rollback_prefix}-{index}")
            except WorkspaceError as error:
                failures.append(f"{workspace_id}: {error}")
        for workspace_id, name in original.items():
            try:
                self.dispatch("renameworkspace", workspace_id, name)
            except WorkspaceError as error:
                failures.append(f"{workspace_id}: {error}")
        if failures:
            raise WorkspaceError("Rollback incomplete: " + "; ".join(failures))
        self.verify_names(original)

    def reorder(self, source_id, target_id, placement):
        with self.lock():
            workspaces = self.snapshot()
            self._reorder_locked(workspaces, source_id, target_id, placement)

    def adjacent(self, direction, wrap=False):
        workspaces = self.snapshot()
        active_id = self.active_workspace()["id"]
        ids = [workspace["id"] for workspace in workspaces]
        if active_id not in ids:
            raise WorkspaceError("The active desktop is not numbered")
        index = ids.index(active_id)
        destination = index + ({"previous": -1, "next": 1}.get(direction, 0))
        if direction not in ("previous", "next"):
            raise WorkspaceError("Invalid desktop direction")
        if destination < 0 or destination >= len(workspaces):
            if not wrap:
                return None
            destination %= len(workspaces)
        return workspaces[index], workspaces[destination]

    def focus(self, number):
        with self.lock():
            self.dispatch("workspace", f"name:{number}")

    def move(self, number):
        with self.lock():
            self.dispatch("movetoworkspace", f"name:{number}")

    def cycle(self, direction):
        with self.lock():
            adjacent = self.adjacent(direction, wrap=True)
            if adjacent:
                self.dispatch("workspace", f"name:{adjacent[1]['name']}")

    def move_relative(self, direction):
        with self.lock():
            adjacent = self.adjacent(direction)
            if adjacent:
                self.dispatch("movetoworkspace", f"name:{adjacent[1]['name']}")

    def shift(self, direction):
        with self.lock():
            workspaces = self.snapshot()
            active_id = self.active_workspace()["id"]
            ids = [workspace["id"] for workspace in workspaces]
            if active_id not in ids:
                raise WorkspaceError("The active desktop is not numbered")
            index = ids.index(active_id)
            target_index = index + ({"previous": -1, "next": 1}.get(direction, 0))
            if direction not in ("previous", "next"):
                raise WorkspaceError("Invalid desktop direction")
            if target_index < 0 or target_index >= len(ids):
                return
            placement = "before" if direction == "previous" else "after"
            self._reorder_locked(workspaces, active_id, ids[target_index], placement)

    def _reorder_locked(self, workspaces, source_id, target_id, placement):
        original = {workspace["id"]: workspace["name"] for workspace in workspaces}
        final_ids = reordered_ids(workspaces, source_id, target_id, placement)
        if final_ids == [workspace["id"] for workspace in workspaces]:
            return
        temporary_name = f"workspace-control-{uuid.uuid4().hex}"
        steps = rename_steps(workspaces, source_id, target_id, placement, temporary_name)
        mutated = False
        try:
            for workspace_id, name in steps:
                self.dispatch("renameworkspace", workspace_id, name)
                mutated = True
            self.verify_names({workspace_id: str(index + 1) for index, workspace_id in enumerate(final_ids)})
        except BaseException:
            if mutated:
                try:
                    self.restore(original)
                except WorkspaceError as rollback_error:
                    self.notify(str(rollback_error))
            raise


def main(arguments):
    if len(arguments) < 2:
        raise WorkspaceError("Missing workspace-control command")
    controller = Controller()
    command = arguments[1]
    if command in ("focus", "move") and len(arguments) == 3 and arguments[2] in {str(number) for number in range(1, 11)}:
        getattr(controller, command)(arguments[2])
    elif command in ("cycle", "move-relative", "shift") and len(arguments) == 3:
        getattr(controller, command.replace("-", "_"))(arguments[2])
    elif command == "reorder" and len(arguments) == 5:
        controller.reorder(int(arguments[2]), int(arguments[3]), arguments[4])
    else:
        raise WorkspaceError("Invalid workspace-control command")


if __name__ == "__main__":
    def interrupted(signum, frame):
        raise KeyboardInterrupt

    signal.signal(signal.SIGINT, interrupted)
    signal.signal(signal.SIGTERM, interrupted)
    try:
        main(sys.argv)
    except (WorkspaceError, ValueError, KeyboardInterrupt) as error:
        Controller().notify(str(error))
        sys.exit(1)
