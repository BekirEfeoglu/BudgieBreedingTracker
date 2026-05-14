# Obsidian Brain — BudgieBreedingTracker

Knowledge wiki for the BudgieBreedingTracker Flutter project. Maintained by LLM; read by humans.

## Quick Navigation

| Section | Start Here |
|---------|-----------|
| App overview | [[overview]] |
| All pages | [[index]] |
| Architecture | [[architecture/layers]] |
| 25 Feature modules | [[features/_features-index]] |
| Data layer (Drift + Supabase) | [[data-layer/drift]] |
| Domain services | [[domain/services-index]] |
| CI/CD & infrastructure | [[infrastructure/ci-cd]] |
| 24 Anti-patterns | [[patterns/anti-patterns]] |
| Rules → wiki map | [[sources/rules-index]] |
| Change log | [[log]] |

## How to Use

- **Find a concept**: open `index.md` and navigate by section.
- **Understand a rule**: check `patterns/` — each file maps to a `.claude/rules/` source.
- **Add a page**: write the file, add an entry to `index.md`, append a log entry to `log.md`.
- **Cross-links** use `[[page-name]]` (Obsidian wikilinks). Paths are relative to `obsidian-brain/`.
- **Source of truth**: the actual source code and `.claude/rules/` files always win over this wiki.

## Maintenance

See [[CLAUDE.md]] for the wiki schema and update contract.
