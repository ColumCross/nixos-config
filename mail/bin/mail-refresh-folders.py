import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


CATEGORY_LABELS = {
    "CATEGORY_PERSONAL",
    "CATEGORY_SOCIAL",
    "CATEGORY_PROMOTIONS",
    "CATEGORY_UPDATES",
    "CATEGORY_FORUMS",
}
SYSTEM_LABELS = {
    "INBOX": "inbox",
    "SPAM": "spam",
    "TRASH": "trash",
    "UNREAD": "unread",
    "STARRED": "flagged",
    "IMPORTANT": "important",
    "SENT": "sent",
    "DRAFT": "draft",
    "CHAT": "chat",
}
STATIC_VIEWS = [
    ("Inbox", "tag:inbox"),
    ("Unread", "tag:unread"),
    ("Starred", "tag:flagged"),
    ("Important", "tag:important"),
    ("Sent", "tag:sent"),
    ("Drafts", "tag:draft"),
    ("All Mail", "not tag:spam and not tag:trash"),
    ("Spam", "tag:spam"),
    ("Trash", "tag:trash"),
    ("Marked for Deletion", 'tag:"marked-for-deletion"'),
]


def fail(message):
    raise SystemExit(f"mail-refresh-folders: {message}")


if len(sys.argv) != 2:
    fail("usage: mail-refresh-folders <account>")

account = sys.argv[1]
home = Path.home()
try:
    configured = json.loads((home / ".config/mail/accounts.json").read_text(encoding="utf-8"))
    known = {entry["address"] for entry in configured["accounts"]}
except (OSError, ValueError, KeyError, TypeError) as error:
    fail(f"invalid runtime account configuration: {error}")
if account not in known:
    fail("unknown mail account")

repository = home / "Mail" / account / "gmail"
notmuch_config = home / ".config/notmuch" / f"{account}.conf"
environment = os.environ | {"NOTMUCH_CONFIG": str(notmuch_config)}
result = subprocess.run(
    ["gmi", "pull", "-q", "-t", "-C", str(repository)],
    check=False,
    capture_output=True,
    text=True,
    env=environment,
)
if result.returncode != 0:
    fail(result.stderr.strip() or result.stdout.strip() or "could not list Gmail labels")

try:
    lieer_config = json.loads((repository / ".gmailieer.json").read_text(encoding="utf-8"))
except (OSError, ValueError) as error:
    fail(f"could not read Lieer configuration: {error}")
translation = dict(SYSTEM_LABELS)
overlay = lieer_config.get("translation_list_overlay", [])
if not isinstance(overlay, list) or len(overlay) % 2:
    fail("invalid Lieer label translation overlay")
translation.update(dict(zip(overlay[::2], overlay[1::2])))

labels = []
for line in result.stdout.splitlines():
    fields = line.rsplit(maxsplit=1)
    if len(fields) != 2:
        continue
    label = fields[0].strip()
    if label and label not in CATEGORY_LABELS:
        labels.append(label)

views = list(STATIC_VIEWS)
existing_names = {name for name, _ in views}
for remote_label in sorted(set(labels), key=str.casefold):
    if remote_label in SYSTEM_LABELS or remote_label in CATEGORY_LABELS:
        continue
    display = remote_label.replace("=", "-")
    if display in existing_names:
        continue
    local_tag = translation.get(remote_label, remote_label)
    escaped = local_tag.replace("\\", "\\\\").replace('"', '\\"')
    views.append((display, f'tag:"{escaped}"'))
    existing_names.add(display)

target = home / ".config/aerc" / f"{account}.query-map"
target.parent.mkdir(parents=True, exist_ok=True)
with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=target.parent, delete=False) as handle:
    for display, query in views:
        handle.write(f"{display}={query}\n")
    handle.flush()
    os.fchmod(handle.fileno(), 0o600)
    temporary = Path(handle.name)
temporary.replace(target)
