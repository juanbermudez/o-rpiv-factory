---
name: usage
description: "Display skill usage analytics: top skills, undertriggering detection, and daily trends. Data from ${CLAUDE_PLUGIN_DATA}/f/skill-usage.jsonl."
argument-hint: ""
---

# Skill Usage Analytics

Display analytics for skill invocations logged by the skill-usage-logger hook.

## Instructions

1. **Check for data file** — The log file is at `${CLAUDE_PLUGIN_DATA}/f/skill-usage.jsonl`.
   - If `CLAUDE_PLUGIN_DATA` is not set or the file does not exist, output:
     > No usage data yet. Skills will be logged as you use them.
   - Then stop.

2. **Parse and analyze the log** using a single `python3` inline script:

```bash
python3 - <<'EOF'
import json, os, sys
from collections import Counter, defaultdict
from datetime import datetime, timezone, timedelta

data_dir = os.environ.get("CLAUDE_PLUGIN_DATA", "")
log_file = os.path.join(data_dir, "f", "skill-usage.jsonl") if data_dir else ""

if not log_file or not os.path.exists(log_file):
    print("No usage data yet. Skills will be logged as you use them.")
    sys.exit(0)

entries = []
with open(log_file) as f:
    for line in f:
        line = line.strip()
        if line:
            try:
                entries.append(json.loads(line))
            except json.JSONDecodeError:
                pass

if not entries:
    print("No usage data yet. Skills will be logged as you use them.")
    sys.exit(0)

# Top 10 skills all time
skill_counts = Counter(e["skill_name"] for e in entries)
print("## Top 10 Most-Used Skills (All Time)\n")
print(f"{'Rank':<6} {'Skill':<40} {'Count':<8}")
print("-" * 56)
for i, (skill, count) in enumerate(skill_counts.most_common(10), 1):
    print(f"{i:<6} {skill:<40} {count:<8}")

# Daily usage last 7 days
print("\n## Daily Usage (Last 7 Days)\n")
now = datetime.now(timezone.utc)
daily = defaultdict(int)
for e in entries:
    try:
        ts = datetime.fromisoformat(e["timestamp"].replace("Z", "+00:00"))
        if (now - ts).days < 7:
            day = ts.strftime("%Y-%m-%d")
            daily[day] += 1
    except (ValueError, KeyError):
        pass

print(f"{'Date':<12} {'Invocations':<12}")
print("-" * 24)
for i in range(6, -1, -1):
    day = (now - timedelta(days=i)).strftime("%Y-%m-%d")
    print(f"{day:<12} {daily.get(day, 0):<12}")

# Undertriggering detection (skills with 0 recorded uses)
# List known skills by scanning commands dir relative to this script
import glob, pathlib
script_env = os.environ.get("CLAUDE_PLUGIN_DATA", "")
commands_glob = os.path.join(pathlib.Path(__file__).parent.parent if hasattr(pathlib.Path(__file__), 'parent') else ".", "commands", "*.md")
# Fallback: just report which logged skills appear infrequent
avg = sum(skill_counts.values()) / len(skill_counts) if skill_counts else 0
undertriggered = [(s, c) for s, c in skill_counts.items() if c < max(1, avg * 0.25)]
if undertriggered:
    print("\n## Potentially Undertriggered Skills\n")
    print(f"{'Skill':<40} {'Count':<8} {'% of avg':<10}")
    print("-" * 58)
    for skill, count in sorted(undertriggered, key=lambda x: x[1]):
        pct = (count / avg * 100) if avg else 0
        print(f"{skill:<40} {count:<8} {pct:.0f}%")
else:
    print("\nNo undertriggered skills detected.")

print(f"\nTotal invocations logged: {len(entries)}")
EOF
```

3. **Display the output** from the script directly to the user.

## Notes

- The log file uses JSONL format (one JSON object per line).
- Each entry has: `timestamp` (ISO 8601), `skill_name`, `session_id`.
- Undertriggering is flagged when a skill's usage is below 25% of the average across all logged skills.
