#!/usr/bin/env python3
"""Fill the Votes column of the package table in README.md from the AUR and
sort the table by it: most votes first, ties by name. A package that is not on
the AUR yet gets no number and goes to the end."""
import json
import re
import urllib.parse
import urllib.request
from pathlib import Path

readme = Path(__file__).resolve().parent.parent / "README.md"
row_re = re.compile(r"^\| `(?P<name>[^`]+)` \|\s*(?P<votes>\d*)\s*\|(?P<rest>.*)$")

lines = readme.read_text().splitlines(keepends=True)
rows = [i for i, line in enumerate(lines) if row_re.match(line)]
if not rows or rows != list(range(rows[0], rows[-1] + 1)):
    raise SystemExit("README.md: no package table, or its rows are not together")
names = [row_re.match(lines[i])["name"] for i in rows]

query = urllib.parse.urlencode([("arg[]", n) for n in names])
with urllib.request.urlopen(f"https://aur.archlinux.org/rpc/v5/info?{query}", timeout=60) as r:
    reply = json.load(r)
if reply.get("type") != "multiinfo":
    raise SystemExit(f"AUR RPC: {reply.get('error', reply)}")
votes = {p["Name"]: p["NumVotes"] for p in reply["results"]}


def key(name):
    return (name not in votes, -votes.get(name, 0), name)


new = []
for name in sorted(names, key=key):
    m = row_re.match(lines[rows[names.index(name)]])
    new.append(f"| `{name}` | {votes.get(name, '')} |{m['rest']}\n")

lines[rows[0] : rows[-1] + 1] = new
text = "".join(lines)
if text != readme.read_text():
    readme.write_text(text)
    print("README.md: votes updated")
else:
    print("README.md: votes are current")
