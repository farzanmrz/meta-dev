#!/usr/bin/env python3
"""Validator for Claude Code agent files, mirroring validate_skill.py's style.

Enforces standards/agent.md: frontmatter shape (name/description required;
model, tools/disallowedTools, color loosely checked) plus a minimal body
heuristic. Uses PyYAML if available, else a naive frontmatter parser.

Usage:
    python3 validate_agent.py <agent-md-path>
"""
import re
import sys
from pathlib import Path

try:
    import yaml
    HAVE_YAML = True
except ImportError:
    HAVE_YAML = False

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
CLAUDE_MODEL_RE = re.compile(r"^claude-[a-z0-9.-]+$")
KNOWN_MODELS = {"sonnet", "opus", "haiku", "fable", "inherit"}
KNOWN_COLORS = {"red", "blue", "green", "yellow", "purple", "orange", "pink", "cyan", "magenta"}
IGNORED_WHEN_PLUGIN = {"hooks", "mcpServers", "permissionMode"}


def naive_parse_frontmatter(text: str) -> dict:
    """Best-effort key: value / simple-list parser used when PyYAML is absent."""
    data, list_key = {}, None
    for line in text.splitlines():
        if not line.strip():
            continue
        if line[0] in " \t" and line.strip().startswith("-") and list_key:
            data.setdefault(list_key, []).append(line.strip().lstrip("-").strip())
            continue
        list_key = None
        if ":" not in line:
            continue
        key, _, value = (p.strip() for p in line.partition(":"))
        if value.startswith("[") and value.endswith("]"):
            inner = value[1:-1].strip()
            data[key] = [v.strip().strip("'\"") for v in inner.split(",")] if inner else []
        elif value == "":
            list_key = key  # possible upcoming block list
        else:
            data[key] = value.strip("'\"")
    return data


def split_frontmatter(text: str):
    m = re.match(r"^---\n(.*?)\n---\n?(.*)$", text, re.S)
    return (m.group(1), m.group(2)) if m else (None, text)


def is_valid_name(name: str) -> bool:
    return isinstance(name, str) and 3 <= len(name) <= 64 and "--" not in name and bool(NAME_RE.match(name))


def is_valid_model(model: str) -> bool:
    return model in KNOWN_MODELS or bool(CLAUDE_MODEL_RE.match(model))


def check_frontmatter(fm: dict, errors: list, warnings: list) -> None:
    name = fm.get("name")
    if not name:
        errors.append("missing required field: name")
    elif not is_valid_name(str(name)):
        errors.append(f"invalid name '{name}': must be lowercase alnum+hyphens, 3-64 chars, no leading/trailing/double hyphen")

    desc = fm.get("description")
    if not desc:
        errors.append("missing required field: description")
    else:
        desc = str(desc)
        if len(desc) < 50:
            errors.append(f"description too short ({len(desc)} chars, need >=50)")
        if len(desc) > 1024:
            warnings.append(f"description is long ({len(desc)} chars, >1024)")
        if "<example>" in desc:
            warnings.append("description contains '<example>' (deprecated format)")

    if fm.get("model"):
        model = str(fm["model"])
        if not is_valid_model(model):
            errors.append(f"invalid model '{model}': must be one of {sorted(KNOWN_MODELS)} or match ^claude-[a-z0-9.-]+$")
    else:
        warnings.append("model omitted (fine if deliberate; default is 'inherit')")

    for key in ("tools", "disallowedTools"):
        value = fm.get(key)
        if value not in (None, ""):
            if isinstance(value, str):
                warnings.append(f"{key} is a comma-string, not a YAML list (accepted, but prefer a list)")
            elif not isinstance(value, list):
                errors.append(f"{key} must be a list (or comma-separated string)")

    color = fm.get("color")
    if color and str(color) not in KNOWN_COLORS:
        warnings.append(f"color '{color}' not in known set {sorted(KNOWN_COLORS)}")

    present_ignored = sorted(k for k in IGNORED_WHEN_PLUGIN if k in fm)
    if present_ignored:
        warnings.append(f"key(s) {', '.join(present_ignored)} present (ignored when this agent is plugin-shipped)")


def check_body(body: str, errors: list, warnings: list) -> None:
    non_empty = [ln for ln in body.splitlines() if ln.strip()]
    if len(non_empty) < 10:
        errors.append(f"body too short ({len(non_empty)} non-empty lines, need >=10)")
    if not re.search(r"^#{1,6}\s*when to invoke", body, re.I | re.M):
        warnings.append('body has no "When to invoke" heading')
    if re.search(r"\bI am\b|\bI will\b", body):
        warnings.append('body may use first person ("I am"/"I will"); should be second person')


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: python3 validate_agent.py <agent-md-path>")
        return 1

    path = Path(sys.argv[1]).resolve()
    if not path.exists():
        print(f"ERROR: file not found: {path}")
        return 1

    fm_text, body = split_frontmatter(path.read_text())
    if fm_text is None:
        print("ERROR: no YAML frontmatter (expected --- ... --- block)")
        print("Agent INVALID (1 errors)")
        return 1

    errors, warnings = [], []
    if HAVE_YAML:
        try:
            fm = yaml.safe_load(fm_text) or {}
        except yaml.YAMLError as e:
            print(f"ERROR: frontmatter is not valid YAML: {e}")
            print("Agent INVALID (1 errors)")
            return 1
    else:
        fm = naive_parse_frontmatter(fm_text)

    if not isinstance(fm, dict):
        errors.append("frontmatter did not parse to a mapping")
        fm = {}

    check_frontmatter(fm, errors, warnings)
    check_body(body, errors, warnings)

    for e in errors:
        print(f"ERROR: {e}")
    for w in warnings:
        print(f"warn: {w}")

    if errors:
        print(f"Agent INVALID ({len(errors)} errors)")
        return 1

    print("Agent is valid!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
