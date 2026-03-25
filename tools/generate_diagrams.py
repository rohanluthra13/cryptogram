#!/usr/bin/env python3
"""
Generate Mermaid diagrams from the Simple Cryptogram Swift codebase.

Two diagram types:
1. Auto-generated call graphs — extracted from method definitions and calls
2. Annotation-driven logic flows — from @flow/@step/@branch comments in code

Usage:
    python3 tools/generate_diagrams.py
"""

import re
import os
from pathlib import Path
from dataclasses import dataclass, field


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------

@dataclass
class SwiftMethod:
    name: str
    kind: str  # "func" or "var"
    access: str  # "private", "public", etc.
    mark_section: str
    line_start: int
    line_end: int
    body_lines: list = field(default_factory=list)


@dataclass
class MethodCall:
    caller: str
    callee: str


@dataclass
class FlowStep:
    step_id: str
    label: str
    line_number: int
    shape: str = "rect"  # "rect", "diamond", "rounded"


@dataclass
class FlowBranch:
    from_step: str  # step id this branch follows
    condition: str
    label: str
    target: str  # target step id
    line_number: int


@dataclass
class Flow:
    name: str
    description: str
    steps: list = field(default_factory=list)      # FlowStep
    branches: list = field(default_factory=list)    # FlowBranch
    source_file: str = ""


# ---------------------------------------------------------------------------
# Regex patterns
# ---------------------------------------------------------------------------

# Match func/var declarations (handles access modifiers, @attributes, async, etc.)
METHOD_DECL_RE = re.compile(
    r'^(\s*)'
    r'(?:(?:private|internal|public|open|fileprivate)\s*(?:\(set\))?\s+)?'
    r'(?:static\s+)?'
    r'(?:@\w+\s+)*'
    r'(func|var)\s+(\w+)',
)

MARK_RE = re.compile(r'//\s*MARK:\s*-?\s*(.+)')

# Flow annotations
FLOW_RE = re.compile(r'//\s*@flow\s+([\w-]+)(?::\s*(.+))?')
STEP_RE = re.compile(r'//\s*@step\s+([\w-]+):\s*(.+)')
BRANCH_RE = re.compile(r'//\s*@branch\s+([\w-]+):\s*(.+?)\s*->\s*([\w-]+)')
END_RE = re.compile(r'//\s*@end\s+([\w-]+)')

# Cross-file: viewModel.xxx( calls
VM_CALL_RE = re.compile(r'viewModel\.(\w+)\s*\(')
VM_PROP_RE = re.compile(r'viewModel\.(\w+)(?!\s*\()')


# ---------------------------------------------------------------------------
# Parsing: Swift methods and call graphs
# ---------------------------------------------------------------------------

def parse_swift_methods(filepath: str) -> list:
    """Extract method declarations with their line ranges and MARK sections."""
    lines = Path(filepath).read_text().splitlines()
    methods = []
    current_mark = "Other"

    # First pass: collect method starts and MARK sections
    method_starts = []
    for i, line in enumerate(lines):
        mark_match = MARK_RE.search(line)
        if mark_match:
            current_mark = mark_match.group(1).strip()
            # Clean up parenthetical notes like "(was GameStateManager)"
            current_mark = re.sub(r'\s*\(was .*?\)', '', current_mark)
            continue

        method_match = METHOD_DECL_RE.match(line)
        if method_match:
            indent, kind, name = method_match.groups()
            # Only top-level methods (indent <= 4 spaces) to skip closures
            if len(indent) <= 4:
                access = "internal"
                for acc in ("private", "public", "open", "fileprivate", "internal"):
                    if acc in line.split(kind)[0]:
                        access = acc
                        break
                method_starts.append((i, name, kind, access, current_mark))

    # Second pass: determine line ranges
    for idx, (line_num, name, kind, access, mark) in enumerate(method_starts):
        end = method_starts[idx + 1][0] - 1 if idx + 1 < len(method_starts) else len(lines) - 1
        body = lines[line_num:end + 1]
        methods.append(SwiftMethod(
            name=name,
            kind=kind,
            access=access,
            mark_section=mark,
            line_start=line_num + 1,  # 1-indexed
            line_end=end + 1,
            body_lines=body,
        ))

    return methods


def extract_calls(method: SwiftMethod, known_methods: set) -> list:
    """Find calls to known methods within a method body."""
    calls = []
    seen = set()
    for line in method.body_lines:
        stripped = line.strip()
        # Skip comments
        if stripped.startswith('//'):
            continue
        for target in known_methods:
            if target == method.name:
                continue  # skip self-recursion unless meaningful
            # Look for method calls: name( or self.name( or self?.name(
            pattern = rf'(?:self\.?|self\?\.)?\b{re.escape(target)}\s*\('
            if re.search(pattern, line) and target not in seen:
                calls.append(MethodCall(caller=method.name, callee=target))
                seen.add(target)
    return calls


def extract_cross_file_calls(filepath: str, vm_methods: set, vm_properties: set) -> tuple:
    """Extract viewModel.method() and viewModel.property references from a view file."""
    lines = Path(filepath).read_text().splitlines()
    method_calls = set()
    prop_reads = set()

    for line in lines:
        stripped = line.strip()
        if stripped.startswith('//'):
            continue
        for match in VM_CALL_RE.finditer(line):
            name = match.group(1)
            if name in vm_methods:
                method_calls.add(name)
        for match in VM_PROP_RE.finditer(line):
            name = match.group(1)
            if name in vm_properties:
                prop_reads.add(name)

    return method_calls, prop_reads


# ---------------------------------------------------------------------------
# Parsing: Flow annotations
# ---------------------------------------------------------------------------

def parse_flow_annotations(filepath: str) -> list:
    """Extract @flow/@step/@branch/@end annotations from a Swift file."""
    lines = Path(filepath).read_text().splitlines()
    flows = {}
    active_flow = None
    last_step_id = None

    for i, line in enumerate(lines):
        # Check for @flow start
        flow_match = FLOW_RE.search(line)
        if flow_match:
            name = flow_match.group(1)
            desc = flow_match.group(2) or name
            active_flow = Flow(name=name, description=desc, source_file=filepath)
            flows[name] = active_flow
            last_step_id = None
            continue

        # Check for @end
        end_match = END_RE.search(line)
        if end_match:
            active_flow = None
            last_step_id = None
            continue

        if active_flow is None:
            continue

        # Check for @step
        step_match = STEP_RE.search(line)
        if step_match:
            step_id = step_match.group(1)
            label = step_match.group(2)
            active_flow.steps.append(FlowStep(
                step_id=step_id,
                label=label,
                line_number=i + 1,
            ))
            last_step_id = step_id
            continue

        # Check for @branch — format: @branch <from-step-id>: <label> -> <target-step-id>
        branch_match = BRANCH_RE.search(line)
        if branch_match:
            from_step = branch_match.group(1)
            label = branch_match.group(2)
            target = branch_match.group(3)
            active_flow.branches.append(FlowBranch(
                from_step=from_step,
                condition=from_step,
                label=label,
                target=target,
                line_number=i + 1,
            ))
            continue

    return list(flows.values())


# ---------------------------------------------------------------------------
# Mermaid generation: Call graphs
# ---------------------------------------------------------------------------

def generate_vm_callgraph(methods: list, calls: list) -> str:
    """Generate Mermaid flowchart for PuzzleViewModel internal calls."""
    # Group methods by MARK section
    sections = {}
    for m in methods:
        sections.setdefault(m.mark_section, []).append(m)

    # Filter to sections that have meaningful methods
    skip_sections = {"PuzzleViewModel", "Supporting Types", "Settings Access",
                     "Core State (was GameStateManager)", "Loading / Error",
                     "Statistics Cache", "Computed Properties",
                     "Daily State (was DailyPuzzleManager)",
                     "Author (was AuthorService)", "NoOpProgressStore"}

    # Build set of methods involved in calls (callers or callees)
    involved = set()
    for c in calls:
        involved.add(c.caller)
        involved.add(c.callee)

    lines = ["flowchart TD"]

    # Create subgraphs
    section_ids = {}
    for section_name, section_methods in sections.items():
        if section_name in skip_sections:
            continue
        # Only include methods that participate in calls
        visible = [m for m in section_methods if m.name in involved]
        if not visible:
            continue

        safe_id = re.sub(r'[^a-zA-Z0-9]', '_', section_name)
        section_ids[section_name] = safe_id
        lines.append(f"    subgraph {safe_id}[\"{section_name}\"]")
        seen_names = set()
        for m in visible:
            if m.name in seen_names:
                continue  # skip overloaded methods (same node)
            seen_names.add(m.name)
            if m.kind == "var":
                lines.append(f"        {m.name}([{m.name}])")
            else:
                lines.append(f"        {m.name}[\"{m.name}()\"]")
        lines.append("    end")

    # Add edges
    lines.append("")
    for c in calls:
        if c.caller in involved and c.callee in involved:
            lines.append(f"    {c.caller} --> {c.callee}")

    return "\n".join(lines)


def generate_cross_file_callgraph(view_calls: dict, vm_methods: list) -> str:
    """Generate Mermaid showing View -> ViewModel call relationships."""
    # Group VM methods by section for coloring context
    method_sections = {}
    for m in vm_methods:
        method_sections[m.name] = m.mark_section

    lines = ["flowchart LR"]

    # View nodes
    lines.append("    subgraph Views")
    for view_name in view_calls:
        lines.append(f"        {view_name}[\"{view_name}\"]")
    lines.append("    end")
    lines.append("")

    # Collect all called methods
    all_called = set()
    for calls_and_props in view_calls.values():
        all_called.update(calls_and_props[0])  # method calls

    # Group called methods by section
    called_by_section = {}
    for name in all_called:
        section = method_sections.get(name, "Other")
        section = re.sub(r'\s*\(was .*?\)', '', section)
        called_by_section.setdefault(section, []).append(name)

    lines.append("    subgraph PuzzleViewModel")
    for section, names in sorted(called_by_section.items()):
        safe_id = "vm_" + re.sub(r'[^a-zA-Z0-9]', '_', section)
        lines.append(f"        subgraph {safe_id}[\"{section}\"]")
        for name in sorted(names):
            lines.append(f"            vm_{name}[\"{name}()\"]")
        lines.append("        end")
    lines.append("    end")
    lines.append("")

    # Edges
    for view_name, (method_calls, prop_reads) in view_calls.items():
        for name in sorted(method_calls):
            lines.append(f"    {view_name} --> vm_{name}")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Mermaid generation: Annotated flows
# ---------------------------------------------------------------------------

def generate_flow_mermaid(flow: Flow) -> str:
    """Generate Mermaid flowchart from annotation-driven flow.

    Logic: steps are connected sequentially UNLESS a step is a branch target,
    in which case it's reached via its branch edge instead. A step that has
    branches coming *after* it becomes a decision diamond that fans out to
    the branch targets.
    """
    lines = ["flowchart TD"]

    # Index steps and branches
    step_ids = [s.step_id for s in flow.steps]
    step_labels = {s.step_id: s.label.replace('"', "'") for s in flow.steps}

    # Group branches by the step they follow (from_step)
    branch_sources = {}  # step_id -> [FlowBranch]
    for b in flow.branches:
        branch_sources.setdefault(b.from_step, []).append(b)

    # Collect all branch targets — these are reached via branch edges, not sequentially
    branch_targets = set()
    for b in flow.branches:
        branch_targets.add(b.target)

    # Emit nodes: steps as rectangles, decisions as diamonds
    for step_id in step_ids:
        label = step_labels[step_id]
        if step_id in branch_sources:
            # This step is also a decision point — render as diamond
            lines.append(f"    {step_id}{{\"{label}\"}}")
        else:
            lines.append(f"    {step_id}[\"{label}\"]")

    lines.append("")

    # Emit edges
    for i, step_id in enumerate(step_ids):
        if step_id in branch_sources:
            # Fan out to branch targets
            for b in branch_sources[step_id]:
                safe_label = b.label.replace('"', "'")
                lines.append(f"    {step_id} -->|\"{safe_label}\"| {b.target}")
        else:
            # Connect to next step sequentially, but only if the NEXT step
            # isn't reached exclusively via a branch
            if i + 1 < len(step_ids):
                next_id = step_ids[i + 1]
                # Walk forward to find the next step that isn't a branch target
                # OR is the immediate next (meaning it follows sequentially)
                if next_id not in branch_targets:
                    lines.append(f"    {step_id} --> {next_id}")
                else:
                    # Next step is a branch target — skip the sequential edge.
                    # But we should connect to the step after that if it exists
                    # and isn't also a branch target. In practice, after a branch
                    # target the flow continues from there, so no edge needed.
                    pass

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def write_mermaid_file(path: Path, title: str, mermaid_content: str, source_note: str = ""):
    """Write a .md file with a Mermaid code block."""
    with open(path, 'w') as f:
        f.write(f"# {title}\n\n")
        if source_note:
            f.write(f"_{source_note}_\n\n")
        f.write(f"_Auto-generated by `tools/generate_diagrams.py` — do not edit manually._\n\n")
        f.write("```mermaid\n")
        f.write(mermaid_content)
        f.write("\n```\n")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    base = Path(__file__).resolve().parent.parent
    swift_dir = base / "simple cryptogram"
    output_dir = base / "docs" / "diagrams"
    output_dir.mkdir(parents=True, exist_ok=True)

    # -----------------------------------------------------------------------
    # 1. PuzzleViewModel internal call graph
    # -----------------------------------------------------------------------
    vm_path = swift_dir / "ViewModels" / "PuzzleViewModel.swift"
    if vm_path.exists():
        methods = parse_swift_methods(str(vm_path))
        known = {m.name for m in methods}
        all_calls = []
        for m in methods:
            all_calls.extend(extract_calls(m, known))

        mermaid = generate_vm_callgraph(methods, all_calls)
        write_mermaid_file(
            output_dir / "puzzle-vm-callgraph.md",
            "PuzzleViewModel — Internal Call Graph",
            mermaid,
            source_note="Source: `simple cryptogram/ViewModels/PuzzleViewModel.swift`",
        )

        # Print summary
        unique_edges = set((c.caller, c.callee) for c in all_calls)
        print(f"  Call graph: {len(methods)} methods, {len(unique_edges)} call edges")

    # -----------------------------------------------------------------------
    # 2. Cross-file call graph (Views -> ViewModel)
    # -----------------------------------------------------------------------
    vm_method_names = {m.name for m in methods if m.kind == "func"}
    vm_property_names = {m.name for m in methods if m.kind == "var"}

    view_files = {
        "PuzzleView": swift_dir / "Views" / "PuzzleView.swift",
        "HomeView": swift_dir / "Views" / "HomeView.swift",
    }

    view_calls = {}
    for view_name, view_path in view_files.items():
        if view_path.exists():
            mc, pr = extract_cross_file_calls(str(view_path), vm_method_names, vm_property_names)
            view_calls[view_name] = (mc, pr)
            print(f"  {view_name}: {len(mc)} method calls, {len(pr)} property reads")

    if view_calls:
        mermaid = generate_cross_file_callgraph(view_calls, methods)
        write_mermaid_file(
            output_dir / "cross-file-callgraph.md",
            "Views to PuzzleViewModel — Call Graph",
            mermaid,
            source_note="Source: `PuzzleView.swift`, `HomeView.swift` → `PuzzleViewModel.swift`",
        )

    # -----------------------------------------------------------------------
    # 3. Annotation-driven logic flows
    # -----------------------------------------------------------------------
    flow_count = 0
    for swift_file in sorted(swift_dir.rglob("*.swift")):
        flows = parse_flow_annotations(str(swift_file))
        for flow in flows:
            if not flow.steps and not flow.branches:
                continue
            mermaid = generate_flow_mermaid(flow)
            rel_path = swift_file.relative_to(base)
            write_mermaid_file(
                output_dir / f"flow-{flow.name}.md",
                f"Flow: {flow.description}",
                mermaid,
                source_note=f"Source: `{rel_path}`",
            )
            flow_count += 1
            print(f"  Flow '{flow.name}': {len(flow.steps)} steps, {len(flow.branches)} branches")

    # -----------------------------------------------------------------------
    # Summary
    # -----------------------------------------------------------------------
    total = len(list(output_dir.glob("*.md")))
    print(f"\nGenerated {total} diagram(s) in docs/diagrams/")
    if flow_count == 0:
        print("  (No @flow annotations found yet — add them to Swift files to generate logic flow diagrams)")


if __name__ == "__main__":
    main()
