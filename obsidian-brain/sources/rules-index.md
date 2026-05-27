# Rules → Wiki Page Map

Maps every `.claude/rules/*.md` file to the wiki page(s) that synthesize it.

| Rules File | Primary Wiki Page | Secondary Pages |
|-----------|------------------|----------------|
| `accessibility.md` | [[patterns/accessibility]] | [[patterns/anti-patterns]] (A5) |
| `admin.md` | [[features/admin]] | [[patterns/security]], [[infrastructure/edge-functions]] |
| `ai-workflow.md` | [[infrastructure/branch-workflow]] | [[infrastructure/scripts]] |
| `architecture.md` | [[architecture/layers]] | [[architecture/data-flow]], [[architecture/online-first-exemption]] |
| `assets-images.md` | [[patterns/assets-images]] | [[patterns/anti-patterns]] (#12, #13) |
| `background-sync.md` | [[data-layer/sync-strategy]] | [[domain/sync-service]], [[architecture/offline-first]] |
| `branch-workflow.md` | [[infrastructure/branch-workflow]] | [[infrastructure/ci-cd]] |
| `breeding-eggs.md` | [[features/breeding]] | [[features/eggs]], [[features/chicks]], [[domain/eggs-service]], [[domain/incubation-service]] |
| `calendar.md` | [[features/calendar]] | [[domain/calendar-service]], [[domain/notification-service]] |
| `chat.md` | (response style — no wiki page needed) | |
| `ci-actions.md` | [[infrastructure/ci-cd]] | [[infrastructure/scripts]] |
| `code-review.md` | (checklist — referenced by [[patterns/anti-patterns]]) | |
| `coding-standards.md` | [[patterns/anti-patterns]] | [[architecture/layers]] |
| `community.md` | [[features/community]] | [[architecture/online-first-exemption]], [[features/messaging]] |
| `data-io.md` | [[domain/data-io]] | [[domain/encryption-service]], [[features/premium]] |
| `data-layer.md` | [[data-layer/drift]] | [[data-layer/supabase]], [[data-layer/repositories]] |
| `datetime-format.md` | [[patterns/datetime-format]] | [[domain/notification-service]] |
| `edge-functions.md` | [[infrastructure/edge-functions]] | [[domain/premium-service]], [[domain/notification-service]], [[domain/moderation-service]] |
| `empty-loading-error-states.md` | [[patterns/empty-loading-error-states]] | [[patterns/ui-patterns]] |
| `encryption.md` | [[domain/encryption-service]] | [[patterns/security]], [[domain/data-io]] |
| `error-handling.md` | [[patterns/error-handling]] | [[patterns/observability]] |
| `feature-flags.md` | [[patterns/feature-flags]] | [[infrastructure/environment]] |
| `forms-validation.md` | [[patterns/forms-validation]] | [[patterns/ui-patterns]] |
| `gamification.md` | [[domain/gamification-service]] | [[features/gamification]], [[features/community]] |
| `genetics.md` | [[domain/genetics-engine]] | [[features/genetics]], [[domain/local-ai]] |
| `git-rules.md` | [[infrastructure/branch-workflow]] | |
| `home-widget.md` | [[domain/home-widget-service]] | [[domain/notification-service]] |
| `local-ai.md` | [[domain/local-ai]] | [[domain/genetics-engine]] |
| `localization.md` | [[patterns/l10n]] | [[patterns/anti-patterns]] (#11) |
| `marketplace.md` | [[features/marketplace]] | [[domain/premium-service]], [[features/community]] |
| `messaging.md` | [[features/messaging]] | [[architecture/online-first-exemption]], [[domain/presence-service]] |
| `migrations.md` | [[data-layer/migrations]] | [[data-layer/drift]], [[data-layer/supabase]] |
| `moderation.md` | [[domain/moderation-service]] | [[infrastructure/edge-functions]], [[features/community]] |
| `new-feature-checklist.md` | (checklist — not directly a wiki page) | [[data-layer/repositories]], [[architecture/layers]] |
| `notifications.md` | [[domain/notification-service]] | [[features/notifications]] |
| `observability.md` | [[patterns/observability]] | [[patterns/error-handling]] |
| `performance.md` | [[patterns/performance]] | [[data-layer/drift]] |
| `premium-revenuecat.md` | [[domain/premium-service]] | [[features/premium]], [[infrastructure/edge-functions]] |
| `presence.md` | [[domain/presence-service]] | [[features/messaging]], [[features/community]] |
| `providers.md` | [[patterns/providers]] | [[patterns/ui-patterns]] |
| `release-ops.md` | [[infrastructure/release-ops]] | [[infrastructure/ci-cd]] |
| `security.md` | [[patterns/security]] | [[patterns/observability]], [[domain/auth-service]], [[domain/encryption-service]] |
| `statistics.md` | [[features/statistics]] | [[domain/data-io]], [[patterns/performance]] |
| `test-stability.md` | [[patterns/testing]] (stability section) | [[patterns/anti-patterns]] (A1) |
| `testing.md` | [[patterns/testing]] | |
| `ui-patterns.md` | [[patterns/ui-patterns]] | [[patterns/forms-validation]], [[patterns/empty-loading-error-states]] |

## Rule Files Without Dedicated Wiki Pages

- `chat.md` — response style instructions for LLM (Turkish replies, brevity). No wiki page needed.
- `code-review.md` — PR checklist. Referenced by [[patterns/anti-patterns]] and [[infrastructure/branch-workflow]].
- `new-feature-checklist.md` — step-by-step checklist. Distilled into [[data-layer/repositories]], [[architecture/layers]], and feature pages.

## See Also

- [[index]] — full wiki page catalog
- [[CLAUDE.md]] — wiki schema and update contract
