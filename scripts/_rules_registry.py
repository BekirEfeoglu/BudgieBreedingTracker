"""Meta-layer registry and inventory guards.

Split out of `_rules_collectors.py` on 2026-07-26, when that module passed 1,100
lines. These nine collectors all answer the same question — does a
hand-maintained list still match the directory it claims to enumerate — for the
`.claude/` meta-layer and the wiki's inventory pages.

Imports one way only: from `_rules_collectors`, never back into it.
"""

import re
from pathlib import Path
from typing import Optional

from _rules_collectors import extract_markdown_section

# ── Agent, skill and rule registration ───────────────────────────────
# 2026-07-26: every guard family above exists because the same literal is
# repeated across two surfaces with nothing tying the copies together. The
# meta-layer that governs those guards had none of its own —
# documentation-sync.md mandates three-place registration for a new agent or
# skill, and agents-index.md states "Review profiles must not declare
# Write/Edit tools", yet verify_rules.py never read `.claude/agents/` or
# `.claude/skills/` at all. The read-only check is the sharp one: a profile
# dispatched as an auditor that silently gained an edit tool could modify the
# code it was sent to inspect. Checking it here also makes the agents-index
# Mode column machine-read rather than decorative.

_FRONTMATTER_RE = re.compile(r"\A---\n(.*?)\n---", re.DOTALL)
_BACKTICKED_CELL_RE = re.compile(r"`([^`]+)`")
# Tools that let a profile mutate the tree. NotebookEdit is listed even though
# no profile declares it today — it is an edit tool, and the point of the check
# is to catch the one nobody thought about.
_WRITE_TOOLS = frozenset({"Write", "Edit", "NotebookEdit"})


def frontmatter_field(text: str, field: str) -> Optional[str]:
    """Return a scalar YAML frontmatter field, or ``None`` when absent."""
    match = _FRONTMATTER_RE.search(text)
    if not match:
        return None
    prefix = f"{field}:"
    for line in match.group(1).splitlines():
        if line.startswith(prefix):
            return line[len(prefix):].strip()
    return None


def catalog_rows(text: str) -> Optional[dict]:
    """Map a markdown table's backticked first cell to its last cell.

    Rows whose first cell is not `code` are skipped, which is exactly what
    keeps the agents-index "Common Sequences" table, CLAUDE.md's stats rows and
    every `| --- |` separator out of the catalogs.

    Returns ``None`` when the section yields no catalog row at all, following
    this module's convention that an absent surface skips rather than reporting
    that every name on the other side drifted.
    """
    rows: dict = {}
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue
        # A line starting with "|" always splits into at least one cell, so
        # cells[0] is safe without an emptiness guard.
        cells = [cell.strip() for cell in stripped.strip("|").split("|")]
        name = _BACKTICKED_CELL_RE.fullmatch(cells[0])
        if name:
            rows[name.group(1)] = cells[-1]
    return rows or None


def two_way_gaps(
    left: Optional[dict],
    right: Optional[dict],
    only_left: str,
    only_right: str,
) -> list:
    """Two-way name diff rendered through two message templates.

    ``None`` on either side means that surface is absent, so report nothing
    rather than claiming every name drifted.
    """
    if left is None or right is None:
        return []
    messages = [only_left.format(name=name) for name in sorted(set(left) - set(right))]
    messages += [
        only_right.format(name=name) for name in sorted(set(right) - set(left))
    ]
    return messages


def collect_agent_surfaces(root: Path) -> dict:
    """Collect agent profile stems + declared tools, and the index catalog."""
    agents_dir = root / ".claude" / "agents"
    profiles = None
    if agents_dir.exists():
        profiles = {}
        for profile in sorted(agents_dir.glob("*.md")):
            declared = frontmatter_field(profile.read_text(encoding="utf-8"), "tools")
            profiles[profile.stem] = (
                {tool.strip() for tool in declared.split(",") if tool.strip()}
                if declared
                else set()
            )

    index_file = root / "obsidian-brain" / "sources" / "agents-index.md"
    index = None
    if index_file.exists():
        index = catalog_rows(
            extract_markdown_section(
                index_file.read_text(encoding="utf-8"), "## Catalog"
            )
        )

    return {"profiles": profiles, "index": index}


def readonly_tool_violations(surfaces: dict) -> list:
    """Profiles the index calls read-only that declare a mutating tool.

    Mode text is matched loosely on purpose: "Read-only; external profile"
    counts, while "Docs-only write" and "Write-enabled" do not.
    """
    profiles = surfaces["profiles"]
    index = surfaces["index"]
    if profiles is None or index is None:
        return []

    violations = []
    for name, mode in sorted(index.items()):
        if "read-only" not in mode.lower():
            continue
        mutating = sorted(profiles.get(name, set()) & _WRITE_TOOLS)
        if mutating:
            violations.append(
                f"{name}: index'te read-only ama {', '.join(mutating)} bildiriyor"
            )
    return violations


def collect_skill_surfaces(root: Path) -> dict:
    """Collect skill names + declared `allowed-tools`, and the index catalog.

    A skill's value is ``None`` when it declares no `allowed-tools` at all,
    which is materially different from declaring an empty list: an absent field
    imposes no restriction, so the skill is simply unconstrained.
    """
    skills_dir = root / ".claude" / "skills"
    skills = None
    if skills_dir.exists():
        skills = {}
        for skill in sorted(skills_dir.glob("*/SKILL.md")):
            declared = frontmatter_field(skill.read_text(encoding="utf-8"), "allowed-tools")
            skills[skill.parent.name] = (
                {tool.strip() for tool in declared.split(",") if tool.strip()}
                if declared
                else None
            )

    index_file = root / "obsidian-brain" / "sources" / "skills-index.md"
    index = None
    if index_file.exists():
        index = catalog_rows(
            extract_markdown_section(
                index_file.read_text(encoding="utf-8"), "## Catalog"
            )
        )

    return {"skills": skills, "index": index}


def skill_posture_violations(surfaces: dict) -> list:
    """Advisory skills whose declared tools contradict the catalog.

    A skill's `allowed-tools` RESTRICTS the session while the skill is active;
    omitting the field imposes no restriction rather than granting one. So a
    catalog row saying `No` means nothing unless the skill actually declares a
    list — which is why an absent field is reported here rather than skipped,
    the opposite of how an agent profile's missing `tools:` is treated. Two of
    these are vendored, and re-vendoring upstream would silently drop the line;
    this is what turns that red instead of letting the posture rot back.
    """
    skills = surfaces["skills"]
    index = surfaces["index"]
    if skills is None or index is None:
        return []

    violations = []
    for name, posture in sorted(index.items()):
        if not posture.strip().lower().startswith("no"):
            continue
        if name not in skills:
            continue  # a ghost row; the two-way registry check owns that
        declared = skills[name]
        if declared is None:
            violations.append(
                f"{name}: index'te salt-tavsiye ama allowed-tools bildirmiyor "
                "(kisitsiz kalir)"
            )
            continue
        mutating = sorted(declared & _WRITE_TOOLS)
        if mutating:
            violations.append(
                f"{name}: index'te salt-tavsiye ama {', '.join(mutating)} bildiriyor"
            )
    return violations


def collect_script_inventory_surfaces(root: Path) -> dict:
    """Collect `scripts/` filenames and the names CLAUDE.md documents.

    Added 2026-07-26 after a sweep found three inventories had rotted silently:
    CLAUDE.md § Script Tests listed 13 of 15 test files, the wiki's script page
    11 of 15, and two agent profiles had no routing row. Counts stayed green
    throughout because nothing tied a directory listing to a prose list.
    """
    scripts_dir = root / "scripts"
    files = None
    if scripts_dir.exists():
        files = {
            path.name
            for path in scripts_dir.iterdir()
            if path.suffix in {".py", ".sh", ".sql"}
        }

    claude_md = root / "CLAUDE.md"
    documented = claude_md.read_text(encoding="utf-8") if claude_md.exists() else None
    # A CLAUDE.md that names no script at all is not a stale inventory, it is
    # an absent surface — same convention as every other collector here.
    if documented is not None and "scripts/" not in documented:
        documented = None
    return {"files": files, "documented": documented}


def undocumented_scripts(surfaces: dict) -> list:
    """Scripts CLAUDE.md never names.

    One-way: CLAUDE.md legitimately names paths outside `scripts/` (for example
    `ios/ci_scripts/ci_post_clone.sh`), so the reverse direction is not checked.
    """
    files = surfaces["files"]
    documented = surfaces["documented"]
    if files is None or documented is None:
        return []
    return sorted(name for name in files if name not in documented)


def collect_agent_routing_surfaces(root: Path) -> dict:
    """Collect agent profile stems and the text of the routing rule.

    agents-index.md's own maintenance contract says adding a profile updates
    `.claude/rules/ai-workflow.md` in the same change; this is that leg.
    """
    agents_dir = root / ".claude" / "agents"
    profiles = None
    if agents_dir.exists():
        profiles = {path.stem for path in agents_dir.glob("*.md")}

    routing = root / ".claude" / "rules" / "ai-workflow.md"
    text = routing.read_text(encoding="utf-8") if routing.exists() else None
    return {"profiles": profiles, "routing_text": text}


def unrouted_agents(surfaces: dict) -> list:
    """Profiles with no mention in the routing rule."""
    profiles = surfaces["profiles"]
    text = surfaces["routing_text"]
    if profiles is None or text is None:
        return []
    return sorted(name for name in profiles if f"`{name}`" not in text)


# ── Wiki inventory pages vs the directories they enumerate ───────────
# Same shape as the script inventory: a hand-maintained list of everything in a
# directory, with nothing tying it to the directory. `scripts.md` had drifted to
# 11 of 15 test files. These four were complete when the check was added
# (2026-07-26) — this keeps them that way.
#
# Each page is matched by the exact token IT uses, never a bare directory name:
# "more" and "home" are real feature modules and would match almost any prose,
# making a substring check vacuous where it matters most.

_FEATURE_LINK_RE = re.compile(r"\[\[features/([a-z_]+)\]\]")
_SERVICE_LIST_RE = re.compile(r"service directories in `lib/domain/services/` \(([^)]+)\)")
_TABLE_FILE_RE = re.compile(r"([a-z_]+_table\.dart)")
_TEST_FILE_RE = re.compile(r"(test_[a-z0-9_]+\.py)")


def _dir_names(path: Path) -> Optional[set]:
    return {d.name for d in path.iterdir() if d.is_dir()} if path.exists() else None


def _page_tokens(path: Path, pattern: re.Pattern) -> Optional[set]:
    if not path.exists():
        return None
    found = set(pattern.findall(path.read_text(encoding="utf-8")))
    return found or None


def collect_wiki_inventory_surfaces(root: Path) -> dict:
    """Collect (disk, page) name pairs for each enumerated wiki inventory."""
    wiki = root / "obsidian-brain"
    tables_dir = root / "lib" / "data" / "local" / "database" / "tables"
    scripts_dir = root / "scripts"

    services_page = wiki / "domain" / "services-index.md"
    services_listed = None
    if services_page.exists():
        match = _SERVICE_LIST_RE.search(services_page.read_text(encoding="utf-8"))
        if match:
            services_listed = {name.strip() for name in match.group(1).split(",")}

    return {
        "features": (
            _dir_names(root / "lib" / "features"),
            _page_tokens(wiki / "features" / "_features-index.md", _FEATURE_LINK_RE),
        ),
        "domain services": (
            _dir_names(root / "lib" / "domain" / "services"),
            services_listed,
        ),
        "drift tables": (
            {p.name for p in tables_dir.glob("*.dart")} if tables_dir.exists() else None,
            _page_tokens(wiki / "data-layer" / "tables-catalog.md", _TABLE_FILE_RE),
        ),
        "script tests": (
            {p.name for p in scripts_dir.glob("test_*.py")} if scripts_dir.exists() else None,
            _page_tokens(wiki / "infrastructure" / "scripts.md", _TEST_FILE_RE),
        ),
    }


def wiki_inventory_gaps(surfaces: dict) -> list:
    """Names on disk that their wiki inventory page never lists.

    One-way: a page may legitimately name something extra (a removed table it
    warns about, a planned module), and the two-way direction would fight that.
    """
    gaps = []
    for label, (disk, page) in sorted(surfaces.items()):
        if disk is None or page is None:
            continue
        for name in sorted(disk - page):
            gaps.append(f"{label}: {name} diskte var, wiki envanterinde yok")
    return gaps


def collect_rule_registration_surfaces(root: Path) -> dict:
    """Collect rule filenames and the CLAUDE.md § Rules table rows.

    The § Rules section is extracted first because CLAUDE.md has other tables
    with backticked first cells (the CI job list, for one).
    """
    rules_dir = root / ".claude" / "rules"
    files = None
    if rules_dir.exists():
        files = {rule.name: rule for rule in sorted(rules_dir.glob("*.md"))}

    claude_md = root / "CLAUDE.md"
    listed = None
    if claude_md.exists():
        listed = catalog_rows(
            extract_markdown_section(claude_md.read_text(encoding="utf-8"), "## Rules")
        )

    return {"files": files, "listed": listed}



# ── Router guards / feature flags vs the rules that enumerate them ────
# The reverse leg of the symbol-drift guard. `check_rule_symbol_drift.py` proves
# every symbol a doc NAMES still exists; nothing proved the opposite direction —
# that a set the code defines is still fully named by the doc claiming to list
# it. `FounderGuard` gated three whole feature areas to founder-only while all
# three guard listings named two guards, and `FeatureFlags` grew to six flags
# while feature-flags.md documented one (both found 2026-07-26).
#
# One-way by design: the rule may discuss guards/flags that no longer exist
# (documenting a removal is legitimate); it may not omit one that does.

_GUARD_CLASS_RE = re.compile(r"^class\s+(\w*Guard)\b", re.MULTILINE)
_FLAG_RE = re.compile(r"^\s*static\s+const\s+bool\s+(\w+)\s*=", re.MULTILINE)


def collect_router_guard_surfaces(root: Path) -> dict:
    """Guard classes on disk + the text of the canonical Route Guards table."""
    guards_dir = root / "lib" / "router" / "guards"
    guards = None
    if guards_dir.exists():
        guards = set()
        for path in guards_dir.glob("*.dart"):
            guards.update(_GUARD_CLASS_RE.findall(path.read_text(encoding="utf-8")))
        guards = guards or None

    rule = root / ".claude" / "rules" / "security.md"
    text = rule.read_text(encoding="utf-8") if rule.exists() else None
    return {"guards": guards, "rule_text": text}


def undocumented_router_guards(surfaces: dict) -> list:
    """Guard classes security.md's Route Guards section never names."""
    guards = surfaces["guards"]
    text = surfaces["rule_text"]
    if guards is None or text is None:
        return []
    return sorted(name for name in guards if f"`{name}`" not in text)


def collect_feature_flag_surfaces(root: Path) -> dict:
    """Static FeatureFlags members + the text of the rule documenting them."""
    source = root / "lib" / "core" / "constants" / "feature_flags.dart"
    flags = None
    if source.exists():
        flags = set(_FLAG_RE.findall(source.read_text(encoding="utf-8"))) or None

    rule = root / ".claude" / "rules" / "feature-flags.md"
    text = rule.read_text(encoding="utf-8") if rule.exists() else None
    return {"flags": flags, "rule_text": text}


def undocumented_feature_flags(surfaces: dict) -> list:
    """FeatureFlags members feature-flags.md never names."""
    flags = surfaces["flags"]
    text = surfaces["rule_text"]
    if flags is None or text is None:
        return []
    return sorted(name for name in flags if f"`{name}`" not in text)
