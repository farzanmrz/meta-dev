#!/usr/bin/env python3
"""Meta-dev wrapper around the vendored quick_validate.

The vendored validator enforces the portable agentskills.io spec, which rejects
Claude-Code-specific frontmatter keys (model, disable-model-invocation, ...). A
skill validator FOR Claude Code must not treat Claude Code's own frontmatter as
foreign: this wrapper VALIDATES those keys' values itself (a bad `model`, a
non-boolean `disable-model-invocation`, an unknown `effort` are real errors it
catches), then strips them from a temp copy so the portable validator can check
the rest. The vendored scripts/ stay byte-identical to upstream (docs/vendoring.md).

Usage (from the skill-creation directory):
    python3 tools/validate_skill.py <skill_directory>
"""
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

_BOOL = {"true", "false"}
_MODEL_ALIASES = {"sonnet", "opus", "haiku", "fable", "inherit"}
_EFFORT = {"low", "medium", "high", "xhigh", "max"}


def _check_model(v):
    if v in _MODEL_ALIASES or v.startswith("claude-"):
        return None
    return f"model: {v!r} is not a known tier ({', '.join(sorted(_MODEL_ALIASES))}) or a claude-* id"


def _check_bool(key):
    return lambda v: None if v.lower() in _BOOL else f"{key}: {v!r} must be true or false"


def _check_effort(v):
    return None if v in _EFFORT else f"effort: {v!r} must be one of {', '.join(sorted(_EFFORT))}"


# Claude Code frontmatter keys absent from the portable spec.
# value → a validator(value)->error|None for scalar keys; None for block/structural
# keys (presence allowed, shape not further constrained here).
CC_KEYS = {
    "model": _check_model,
    "disable-model-invocation": _check_bool("disable-model-invocation"),
    "user-invocable": _check_bool("user-invocable"),
    "effort": _check_effort,
    "context": None, "agent": None, "hooks": None, "paths": None,
    "argument-hint": None, "arguments": None, "when_to_use": None,
    "shell": None, "allowed-tools": None, "disallowed-tools": None,
}


def parse_and_check(frontmatter: str):
    """Strip CC-only keys from the frontmatter and validate their values.

    Returns (kept_frontmatter, cc_keys_seen, errors).
    """
    kept, seen, errors = [], [], []
    skipping_block = False
    for line in frontmatter.splitlines():
        is_top_level = line and line[0] not in (" ", "\t", "-")
        if is_top_level:
            key = line.split(":", 1)[0].strip() if ":" in line else None
            if key in CC_KEYS:
                seen.append(key)
                skipping_block = True  # also drop the key's indented children
                check = CC_KEYS[key]
                if check is not None:  # a scalar key we can value-check
                    value = line.split(":", 1)[1].strip() if ":" in line else ""
                    if not value:
                        errors.append(f"{key}: expected a value")
                    else:
                        err = check(value)
                        if err:
                            errors.append(err)
                continue
            skipping_block = False
        elif skipping_block:
            continue  # indented child of a stripped CC key
        kept.append(line)
    return "\n".join(kept), seen, errors


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
    cc_errors = []
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if m:
        cleaned, seen, cc_errors = parse_and_check(m.group(1))
        if seen:
            print(f"Claude Code frontmatter checked: {', '.join(sorted(set(seen)))}", flush=True)
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

    # Claude Code frontmatter errors override the portable verdict; print them
    # last so the final line is the real result, not the portable "valid".
    if cc_errors:
        for e in cc_errors:
            print(f"error (Claude Code frontmatter): {e}")
        print(f"Skill is INVALID — {len(cc_errors)} Claude Code frontmatter error(s).")
        return 1
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
