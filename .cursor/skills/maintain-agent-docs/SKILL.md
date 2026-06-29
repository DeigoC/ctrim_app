---
name: maintain-agent-docs
description: Update ctrim_app Cursor rules, skills, AGENTS.md, and copilot-instructions when conventions change. Use after completing a feature, fixing a non-obvious bug, or when the user asks to capture knowledge for future agents.
disable-model-invocation: false
---

# Maintain agent docs — ctrim_app

Run this at the end of a significant feature or debug session, or when the user says "update agent docs" / "capture this for the agent".

## Checklist

```
- [ ] Did work introduce a pattern worth documenting? (If no, stop.)
- [ ] Identify target file(s) — see table below
- [ ] Edit minimally; remove outdated guidance in the same pass
- [ ] Add one line to AGENTS.md → Recent agent-relevant changes
- [ ] If .github/copilot-instructions.md mirrors the change, update it too
- [ ] Do not commit unless user asked
```

## Where to put what

| If you changed… | Update |
|-----------------|--------|
| Model conventions | `.cursor/rules/ctrim-app-models.mdc` |
| Firebase / Firestore | `.cursor/rules/ctrim-app-firebase.mdc` |
| Tests | `.cursor/rules/ctrim-app-tests.mdc` |
| Project-wide constraints | `.cursor/rules/ctrim-app-overview.mdc` |
| Info section / Quill / Firestore info | `.cursor/skills/ctrim-app-info-section/` |
| Web auth / firestore.rules | `.cursor/skills/ctrim-app-web-debug/` |
| New feature workflow | `.cursor/skills/ctrim-app-new-feature/` |
| Debug workflow | `.cursor/skills/ctrim-app-fix-bug/` |
| High-level summary | `AGENTS.md` |

## Changelog format (AGENTS.md)

```markdown
- **YYYY-MM-DD** — One sentence: what changed and where agents should look.
```

Keep the section to the **5 most recent** entries; drop older lines.

## Anti-patterns

- Do not duplicate the same fact in rules, skills, and AGENTS.md — rules = constraints, skills = workflows, AGENTS.md = index + changelog
- Do not document every commit
- Do not rename skill folders without updating descriptions
