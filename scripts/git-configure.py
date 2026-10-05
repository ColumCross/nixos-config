import json
import os
import re
import stat
import subprocess
import tempfile
from pathlib import Path


PRIVATE_VARIABLES = Path("/etc/nixos/private-variables.json")
EMAIL = re.compile(r"^[^@/\s]+@[^@/\s]+\.[^@/\s]+$")


def fail(message):
    raise SystemExit(f"git-configure: {message}")


try:
    mode = stat.S_IMODE(PRIVATE_VARIABLES.stat().st_mode)
except FileNotFoundError:
    fail(f"missing {PRIVATE_VARIABLES}")
if mode & 0o077:
    fail(f"{PRIVATE_VARIABLES} must be owner-only (0600), not {mode:03o}")

try:
    git = json.loads(PRIVATE_VARIABLES.read_text(encoding="utf-8"))["git"]
    name = git["userName"]
    email = git["userEmail"]
except (json.JSONDecodeError, KeyError, TypeError) as error:
    fail(f"invalid git configuration: {error}")

if not isinstance(name, str) or not name or "\n" in name:
    fail("git.userName must be a non-empty single-line string")
if not isinstance(email, str) or not EMAIL.fullmatch(email):
    fail("git.userEmail must be a simple email address")

identity_path = Path.home() / ".config/git/identity"
identity_path.parent.mkdir(parents=True, exist_ok=True)
os.chmod(identity_path.parent, 0o700)

with tempfile.NamedTemporaryFile(dir=identity_path.parent, delete=False) as handle:
    temporary = Path(handle.name)
    try:
        os.fchmod(handle.fileno(), 0o600)
        subprocess.run(
            ["git", "config", "--file", str(temporary), "user.name", name],
            check=True,
        )
        subprocess.run(
            ["git", "config", "--file", str(temporary), "user.email", email],
            check=True,
        )
    except (OSError, subprocess.CalledProcessError) as error:
        temporary.unlink(missing_ok=True)
        fail(f"could not write {identity_path}: {error}")

try:
    temporary.replace(identity_path)
except OSError as error:
    temporary.unlink(missing_ok=True)
    fail(f"could not write {identity_path}: {error}")
