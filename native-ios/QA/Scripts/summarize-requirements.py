#!/usr/bin/env python3
"""Print requirement counts and refresh docs/REQUIREMENTS_PROGRESS.md from the canonical CSV."""
import csv
from collections import Counter, defaultdict
from pathlib import Path

root = Path(__file__).resolve().parents[3]
tracker = root / "native-ios/QA/REQUIREMENTS_TRACEABILITY.csv"
output = root / "docs/REQUIREMENTS_PROGRESS.md"
with tracker.open(newline="", encoding="utf-8-sig") as stream:
    rows = list(csv.DictReader(stream))
allowed = {"NOT STARTED", "IN PROGRESS", "IMPLEMENTED — UNVERIFIED", "VERIFIED", "BLOCKED"}
invalid = [(row.get("ID"), row.get("Status")) for row in rows if row.get("Status") not in allowed]
if invalid:
    raise SystemExit(f"Invalid tracker status values: {invalid}")
counts = Counter(row["Status"] for row in rows)
categories = defaultdict(Counter)
for row in rows:
    categories[row.get("Category", "Uncategorized")][row["Status"]] += 1
lines = [
    "# Requirements progress (generated)",
    "",
    f"Source: `{tracker.relative_to(root)}`; requirements counted: **{len(rows)}**.",
    "",
    "This is a count of tracker rows, not a completion percentage. `VERIFIED` reflects only the evidence recorded on that row; visual approval remains separately identified.",
    "",
    "| Status | Requirements |",
    "|---|---:|",
]
for status in ("VERIFIED", "IMPLEMENTED — UNVERIFIED", "IN PROGRESS", "NOT STARTED", "BLOCKED"):
    lines.append(f"| {status} | {counts[status]} |")
lines += ["", "## By category", "", "| Category | Total | Verified | Implemented, unverified | In progress | Not started | Blocked |", "|---|---:|---:|---:|---:|---:|---:|"]
for category in sorted(categories):
    c = categories[category]
    lines.append(f"| {category} | {sum(c.values())} | {c['VERIFIED']} | {c['IMPLEMENTED — UNVERIFIED']} | {c['IN PROGRESS']} | {c['NOT STARTED']} | {c['BLOCKED']} |")
lines += ["", "Review requirement-level evidence and next actions in the canonical tracker; do not infer completion from these counts.", ""]
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text("\n".join(lines), encoding="utf-8")
print(output)
print("\n".join(lines))
