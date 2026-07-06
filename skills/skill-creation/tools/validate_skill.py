#!/usr/bin/env python3
"""Meta-dev wrapper around the vendored quick_validate.

The vendored validator enforces the portable agentskills.io spec, which
rejects Claude-Code-specific frontmatter keys (model, disable-model-invocation,
...). This wrapper validates a skill WITHOUT penalizing documented CC keys:
it copies the skill to a temp dir, strips the CC-only keys from the copy's
frontmatter, and runs the vendored validator on the sanitized copy. The
vendored scripts/ stay byte-identical to upstream (see docs/vendoring.md).

Usage (from the skill-creation directory):
    python3 tools/validate_skill.py <skill_directory>
"""
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# Documented Claude Code skill frontmatter keys absent from the portable spec.
CC_ONLY_KEYS = {
    "model", "disable-model-invocation", "user-invocable", "context", "agent",
    "hooks", "paths", "argument-hint", "arguments", "when_to_use", "effort",
    "shell", "disallowed-tools",
}


def strip_cc_keys(frontmatter: str):
    kept, dropped = [], []
    skipping_block = False
    for line in frontmatter.splitlines():
        is_top_level = line and not line[0] in (" ", "\t", "-")
        if is_top_level:
            key = line.split(":", 1)[0].strip() if ":" in line else None
            if key in CC_ONLY_KEYS:
                dropped.append(key)
                skipping_block = True  # also drop the key's indented children
                continue
            skipping_block = False
        elif skipping_block:
            continue
        kept.append(line)
    return "\n".join(kept), dropped


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: python3 tools/validate_skill.py <skill_directory>")
        return 1
    skill = Path(sys.argv[1]).resolve()
    src = skill / "SKILL.md"
    if not src.exists():
        print(f"No SKILL.md in {skill}")
        return 1

    text = src.read_text()
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if m:
        cleaned, dropped = strip_cc_keys(m.group(1))
        if dropped:
            print(f"note: ignoring Claude-Code-only key(s): {', '.join(sorted(set(dropped)))}")
            text = f"---\n{cleaned}\n---\n" + text[m.end():]

    skill_creation_dir = Path(__file__).resolve().parent.parent
    with tempfile.TemporaryDirectory() as td:
        tmp_skill = Path(td) / skill.name
        shutil.copytree(skill, tmp_skill)
        (tmp_skill / "SKILL.md").write_text(text)
        result = subprocess.run(
            [sys.executable, "-m", "scripts.quick_validate", str(tmp_skill)],
            cwd=skill_creation_dir,
        )
        return result.returncode


if __name__ == "__main__":
    sys.exit(main())
