import json
import os
import re
import stat
import sys
import tempfile
from email.utils import formataddr
from pathlib import Path


PRIVATE_VARIABLES = Path("/etc/nixos/private-variables.json")
EMAIL = re.compile(r"^[^@/\s]+@[^@/\s]+\.[^@/\s]+$")


def fail(message):
    raise SystemExit(f"mail-configure: {message}")


def write_private(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    os.chmod(path.parent, 0o700)
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=path.parent, delete=False) as handle:
        handle.write(content)
        handle.flush()
        os.fchmod(handle.fileno(), 0o600)
        temporary = Path(handle.name)
    temporary.replace(path)


def address(value, field):
    if not isinstance(value, str) or not EMAIL.fullmatch(value):
        fail(f"{field} must be a simple email address")
    return value


try:
    mode = stat.S_IMODE(PRIVATE_VARIABLES.stat().st_mode)
except FileNotFoundError:
    fail(f"missing {PRIVATE_VARIABLES}")
if mode & 0o077:
    fail(f"{PRIVATE_VARIABLES} must be owner-only (0600), not {mode:03o}")

try:
    variables = json.loads(PRIVATE_VARIABLES.read_text(encoding="utf-8"))
    mail = variables["mail"]
    entries = mail["accounts"]
    default = mail["defaultAccount"]
    binds_path = Path(mail["aercBindsPath"])
except (json.JSONDecodeError, KeyError, TypeError) as error:
    fail(f"invalid mail configuration: {error}")

if not isinstance(entries, list) or not entries:
    fail("mail.accounts must be a non-empty list")

accounts = []
seen = set()
for index, entry in enumerate(entries):
    if not isinstance(entry, dict):
        fail(f"mail.accounts[{index}] must be an object")
    account = address(entry.get("address"), f"mail.accounts[{index}].address")
    if account in seen:
        fail(f"duplicate account {account}")
    seen.add(account)
    display = entry.get("displayName", account)
    if not isinstance(display, str) or not display or "\n" in display:
        fail(f"mail.accounts[{index}].displayName must be one line")
    aliases = entry.get("aliases", [])
    if not isinstance(aliases, list):
        fail(f"mail.accounts[{index}].aliases must be a list")
    accounts.append({"address": account, "displayName": display, "aliases": [address(alias, f"mail.accounts[{index}].aliases") for alias in aliases]})

if default not in seen:
    fail("mail.defaultAccount must name a configured account")
accounts.sort(key=lambda entry: entry["address"] != default)
if not binds_path.is_absolute() or not binds_path.is_file() or not os.access(binds_path, os.R_OK):
    fail("mail.aercBindsPath must be an absolute readable binds.conf file")

BASE_QUERY_MAP = """Inbox=tag:inbox
Unread=tag:unread
Starred=tag:flagged
Important=tag:important
Sent=tag:sent
Drafts=tag:draft
All Mail=not tag:spam and not tag:trash
Spam=tag:spam
Trash=tag:trash
Marked for Deletion=tag:\"marked-for-deletion\"
"""

home = Path.home()
config = home / ".config"
mail_config = config / "mail"
aerc_config = config / "aerc"
notmuch_config = config / "notmuch"
mail_config.mkdir(parents=True, exist_ok=True)
aerc_config.mkdir(parents=True, exist_ok=True)
notmuch_config.mkdir(parents=True, exist_ok=True)

write_private(mail_config / "accounts.json", json.dumps({"defaultAccount": default, "accounts": accounts}, indent=2) + "\n")
write_private(mail_config / "accounts.tsv", "".join(f"{entry['address']}\t{entry['displayName']}\n" for entry in accounts))

temporary_link = aerc_config / ".binds.conf.tmp"
temporary_link.unlink(missing_ok=True)
temporary_link.symlink_to(binds_path)
temporary_link.replace(aerc_config / "binds.conf")

account_sections = []
for entry in accounts:
    account = entry["address"]
    query_map = aerc_config / f"{account}.query-map"
    if not query_map.exists():
        write_private(query_map, BASE_QUERY_MAP)
    identities = [formataddr((entry["displayName"], account))] + [formataddr((entry["displayName"], alias)) for alias in entry["aliases"]]
    account_sections.append(
        f"""[{account}]
source = notmuch://{home}/Mail/{account}
query-map = {aerc_config}/{account}.query-map
exclude-tags = spam,trash
default = Inbox
from = {identities[0]}
aliases = {','.join(identities)}
outgoing = mail-send {account}
postpone = local-drafts
check-mail = 0
restrict-delete = true
"""
    )
    write_private(
        notmuch_config / f"{account}.conf",
        f"""[database]
path={home}/Mail/{account}

[user]
name={entry['displayName']}
primary_email={account}
other_email={';'.join(entry['aliases'])}

[new]
tags=
ignore=/.*[.](json|lock|bak)$/

[search]
exclude_tags=spam;trash
""",
    )

write_private(aerc_config / "accounts.conf", "\n".join(account_sections))
