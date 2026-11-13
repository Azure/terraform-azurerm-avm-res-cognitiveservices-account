# AVM Triage Report for owner `segraef` - 2026-11-13

**Mode:** `deep` - full code-delta + upstream-schema + thread analysis

## Triage summary

```text
Total open:              6
Copilot-ready now:       1 (16.7%) - documentation scope only
Copilot-ready (blocked): 2         - existing implementation PRs
Needs owner:             3 (50.0%) - design or upstream-contract decisions
```

### Module issues analysed

| Repo | Open | High | Medium | Low | Copilot-ready now | Copilot-ready (blocked) | Needs owner |
|------|------|------|--------|-----|-------------------|-------------------------|-------------|
| Azure/terraform-azurerm-avm-res-cognitiveservices-account | 6 | 3 | 2 | 1 | 1 | 2 | 3 |
| **Total** | **6** | **3** | **2** | **1** | **1** | **2** | **3** |

The one Copilot-ready item is a documentation-only scope, not a verified automatic migration. No comments, assignments, closures or merges were performed. The owner requested local implementation in one consolidated PR, not separate cloud assignments.

Ownership source: the current raw [Terraform resource module index](https://raw.githubusercontent.com/Azure/Azure-Verified-Modules/main/docs/static/module-indexes/TerraformResourceModules.csv), which lists `segraef` as primary owner. Scope is this repository only. Implementation baseline: `b9cddea` on `main`. The existing local checkout was clean and matched `origin/main`, so no duplicate shallow clone was needed.

Baseline validation: `pwsh -NoLogo -NoProfile -Command 'Import-Module Avm.Authoring; avm test unit'` passed, 17 runs.

The classifications below describe the incoming backlog. Work started on the consolidated branch does not mean that its fixes are merged or released.

Assignable now: 1/6 (16.7%). Not assignable now: 5/6 (83.3%), including two issues already covered by pending PRs. All implementation stays on the owner-requested consolidated branch.

---

## All Issues - Flat List (6 total)

### `Azure/terraform-azurerm-avm-res-cognitiveservices-account` (6 open)

| # | Title | Type | Priority | Action | Dependencies / Code surface / Upstream |
|---|-------|------|----------|--------|---------------------------------------|
| [Azure/terraform-azurerm-avm-res-cognitiveservices-account#95](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/95) | Migration path from terraform-azurerm-openai | documentation | High | Copilot-ready | Bound scope: explain input/address mapping and controlled state handoff, without claiming a tested automated migration. `_header.md`; legacy `azurerm_cognitive_account.this` and keyed deployments become `azapi_resource.this[0]` and keyed deployment submodules. Shares migration documentation with #202, but generic guidance does not depend on that fix. Old module source confirms different generated name/subdomain/tag defaults. |
| [Azure/terraform-azurerm-avm-res-cognitiveservices-account#202](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/202) | Upgrade recreates every deployment | bug | High | Copilot-ready (after PR #215 review or consolidated replacement) | `main.tf`, `main.rai_policy.tf`, `_header.md`; generic moves target singleton modules, while actual calls use `for_each`. The RAI policy move has the same defect. TFRMNFR1 requires parent-owned cardinality. Remove invalid moves and document consumer-declared per-key moves. Removing moves alone does not prevent recreation. Real-state upgrade verification remains required. |
| [Azure/terraform-azurerm-avm-res-cognitiveservices-account#246](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/246) | Multiple private DNS zones produce duplicate names | bug | High | Copilot-ready (after PR #254 review or consolidated replacement) | `main.privateendpoint.tf`, `tests/unit/private_endpoints.tftest.hcl`; utility output repeats the config name. ARM `Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01` contains named `privateDnsZoneConfigs`. PR #254 fixes the basic case, but replacing dots with dashes can collide and ignores resource-group differences. The consolidated fix hashes full IDs while preserving empty/single-zone behavior. |
| [Azure/terraform-azurerm-avm-res-cognitiveservices-account#204](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/204) | Support modelProviderData | feature-request | Medium | Needs investigation | `variables.tf`, `main.tf`, `modules/deployment/{main,variables}.tf`; overlaps #202 at the deployment call, but no semantic ordering dependency is established. PR #249 implements the proposed fields. Neither Microsoft Learn nor the authoritative REST `DeploymentProperties` schema for stable `2026-05-01` lists `modelProviderData`. The API version exists and is not preview; absence from the schema is not proof that the service rejects it. Obtain a published contract or a successful live request before treating the mapping as confirmed. |
| [Azure/terraform-azurerm-avm-res-cognitiveservices-account#247](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/247) | Support AzureRM 5.x | provider-update | Medium | Needs design decision | `terraform.tf`, `diagnostic.tf`, `lock.tf`, `main_role_assignments.tf`, `main.tf`, `main.aiservies.tf`, CMK interface and examples. Current AzureRM is 5.13.0, but published TFFR3 permits AzureRM only in the 4.x range for narrow unsupported data-plane exceptions. Do not widen the constraint to 5.x. PR #253 includes #252, yet retains the blocking 4.x requirement and uses forbidden key/identity data lookups. A compliant AzAPI migration requires the current CMK variant-2 contract and diagnostic-settings v2, explicit compatibility decisions and real-state upgrade tests. |
| [Azure/terraform-azurerm-avm-res-cognitiveservices-account#120](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/120) | Max Capacity parameter | feature-request | Low | Needs design decision | Deployment `scale.capacity` is an explicit requested value, not an upper bound. Thread agrees quota computation can be composed by the caller, but the owner later asked whether to use a utility, in-module clamping or documentation. No final decision. Quota reads are not reservations. Add explanatory documentation without introducing silent clamping, a new utility repository or an unapproved public input. |

**Excluded (false positive):** none.

### Previous-triage diff (if applicable)

No prior report was supplied or found in this repository. Historical resolved, new, updated and reopened-duplicate deltas cannot be established; this run is the baseline.

### Thread evolution and staleness

| Issue | Last human signal | Owner response | Relevant evolution |
|-------|-------------------|----------------|--------------------|
| #95 | 2025-09-06, reporter, 433 days ago | No response by current indexed owner in captured thread | A previous maintainer promised investigation; reporter asked twice for progress. Immediate-attention and response-overdue labels justify High priority despite documentation scope. |
| #120 | 2026-06-17, segraef, 149 days ago | Yes | Discussion evolved from a utility suggestion to three possible approaches, plus the need for a utility owner. Won't-fix label is not a recorded final design choice. |
| #202 | 2026-07-06, reporter's initial body, 130 days ago | No human comment in issue thread | Explicit reproduction and per-key workaround; PR #215 also addresses RAI policies. In-PR status is not evidence that the defect is released. |
| #204 | 2026-07-11, reporter's initial body, 125 days ago | No human comment in issue thread | Proposed API version and interface are explicit, but schema support is unconfirmed. Adopted PR #249 replaces original #205. |
| #246 | 2026-10-29, nabeleon94, 15 days ago | No | Reporter supplied the ARM DuplicateResourceName response. Follow-up links implementation PR #254. |
| #247 | 2026-10-25, Meertman, 19 days ago | No | Another consumer confirms the blocker and offers prerelease testing. The proposed migration PRs still retain the conflicting provider requirement. |

Bot comments were inspected and treated as SLA/governance signals, not technical confirmation. No reporter is currently waiting on an unanswered maintainer reproduction question.

### Open pull request triage

| PR | State observed | Disposition for the consolidated PR |
|----|----------------|------------------------------------|
| [Azure/terraform-azurerm-avm-res-cognitiveservices-account#215](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/pull/215) | Blocked; CLA only | Adopt the invalid-move removal and consumer guidance. Correct the misleading version range, omit unverified cross-provider promises, avoid the shell generator, and require a real-state migration before release. |
| [Azure/terraform-azurerm-avm-res-cognitiveservices-account#245](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/pull/245) | Conflicts; CLA only | Utility 0.7.0 and legacy naming 0.4.4 updates are superseded on current main by interfaces 0.9.0 and `avm-utl-naming` 0.2.0. Adopt only the remaining example time-provider 0.14.2 update. Do not downgrade current dependencies. |
| [Azure/terraform-azurerm-avm-res-cognitiveservices-account#249](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/pull/249) | Blocked; historical PR check failed | Hold pending authoritative attestation-property evidence. Prior unit and E2E successes do not test a live partner-model request. Historical PR-check failures include baseline interface/tag drift and a provider-download failure; do not ascribe all failures to this feature. Its ModTM test mock is also stale after main retired ModTM. |
| [Azure/terraform-azurerm-avm-res-cognitiveservices-account#252](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/pull/252) | Blocked; CLA only | Review with #253, not as an independent provider-5 fix. Diagnostic settings use the legacy public shape rather than canonical v2. Newly authored resources also need the current resource-type and ignore-body controls. |
| [Azure/terraform-azurerm-avm-res-cognitiveservices-account#253](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/pull/253) | Blocked; includes #252; CLA only | Do not blindly merge. It retains AzureRM `< 5.0`, resolves key URIs/client IDs through data sources contrary to current CMK guidance, and lacks real-state migration evidence. Preserve its PATCH-only encryption insight when redesigning. |
| [Azure/terraform-azurerm-avm-res-cognitiveservices-account#254](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/pull/254) | Blocked; CLA only | Adopt the multi-zone normalization and regression test, strengthen names against normalized-name/resource-group collisions, and retain single-zone behavior. Credit the contributor. |

No existing PR was closed or modified. Their authors' work must be credited, and any supersession/closure must be approved separately.

### Authoritative evidence

The Microsoft documentation MCP was used for ARM reference search and fetch. No Terraform Registry MCP was available, so public Registry REST endpoints were used for current versions.

- [Deployment ARM reference, 2026-05-01](https://learn.microsoft.com/azure/templates/microsoft.cognitiveservices/2026-05-01/accounts/deployments?pivots=deployment-language-terraform).
- [Authoritative Cognitive Services REST schema, 2026-05-01](https://github.com/Azure/azure-rest-api-specs/blob/main/specification/cognitiveservices/resource-manager/Microsoft.CognitiveServices/CognitiveServices/stable/2026-05-01/cognitiveservices.json). `DeploymentProperties` does not declare `modelProviderData`; no supported field shape was inferred from the issue.
- [Private DNS zone group ARM reference, 2024-05-01](https://learn.microsoft.com/azure/templates/microsoft.network/2024-05-01/privateendpoints/privatednszonegroups?pivots=deployment-language-terraform).
- [TFFR3 provider policy](https://azure.github.io/Azure-Verified-Modules/spec/TFFR3), read from its current raw source: AzAPI 2.12 through less than 3.0; narrow AzureRM exception is 4.x, not 5.x.
- [Current Terraform interfaces](https://azure.github.io/Azure-Verified-Modules/specs/tf/interfaces/), including the full canonical CMK variant-2, diagnostics, lock and RBAC declarations. CMK key/identity data lookups are explicitly prohibited.
- [TFRMNFR1 submodule cardinality](https://azure.github.io/Azure-Verified-Modules/spec/TFRMNFR1): cardinality belongs on the parent module call.
- [AzureRM Registry metadata](https://registry.terraform.io/v1/providers/hashicorp/azurerm): 5.13.0; [AzAPI Registry metadata](https://registry.terraform.io/v1/providers/Azure/azapi): 2.13.0.
- [Archived OpenAI module implementation](https://github.com/Azure/terraform-azurerm-openai/blob/main/main.tf), used for legacy address and input mapping only.

---

## Combined Action Plan

### Act now

| Repo | # | Action |
|------|---|--------|
| Azure/terraform-azurerm-avm-res-cognitiveservices-account | [Azure/terraform-azurerm-avm-res-cognitiveservices-account#202](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/202) | Remove impossible generic moves; document per-key state transitions and stop-on-replacement requirements. |
| Azure/terraform-azurerm-avm-res-cognitiveservices-account | [Azure/terraform-azurerm-avm-res-cognitiveservices-account#246](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/246) | Apply deterministic unique config names and test the three reported zones plus collision cases. |
| Azure/terraform-azurerm-avm-res-cognitiveservices-account | [Azure/terraform-azurerm-avm-res-cognitiveservices-account#95](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/95) | Add practical migration guidance, with explicit limits on what has been verified. |

### Copilot-ready batch (pending approval per issue)

| Repo | Issues |
|------|--------|
| Azure/terraform-azurerm-avm-res-cognitiveservices-account | [Azure/terraform-azurerm-avm-res-cognitiveservices-account#95](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/95), documentation only. Implement locally in the requested single PR rather than assign another agent. |

### PR-in-flight - review before assigning Copilot

| Repo | Issue | Note |
|------|-------|------|
| Azure/terraform-azurerm-avm-res-cognitiveservices-account | [Azure/terraform-azurerm-avm-res-cognitiveservices-account#202](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/202) | [Azure/terraform-azurerm-avm-res-cognitiveservices-account#215](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/pull/215): fold reviewed work into the consolidated PR. |
| Azure/terraform-azurerm-avm-res-cognitiveservices-account | [Azure/terraform-azurerm-avm-res-cognitiveservices-account#246](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/246) | [Azure/terraform-azurerm-avm-res-cognitiveservices-account#254](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/pull/254): fold reviewed work into the consolidated PR. |
| Azure/terraform-azurerm-avm-res-cognitiveservices-account | [Azure/terraform-azurerm-avm-res-cognitiveservices-account#204](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/204) | [Azure/terraform-azurerm-avm-res-cognitiveservices-account#249](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/pull/249): upstream property contract remains unconfirmed. |
| Azure/terraform-azurerm-avm-res-cognitiveservices-account | [Azure/terraform-azurerm-avm-res-cognitiveservices-account#247](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/247) | [Azure/terraform-azurerm-avm-res-cognitiveservices-account#252](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/pull/252) and [Azure/terraform-azurerm-avm-res-cognitiveservices-account#253](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/pull/253): stacked migration needs redesign and upgrade verification. |

### Document & close (draft text for approval first)

| Repo | Issues | Topic |
|------|--------|-------|
| Azure/terraform-azurerm-avm-res-cognitiveservices-account | [Azure/terraform-azurerm-avm-res-cognitiveservices-account#120](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/120) | Documentation explains caller-owned capacity selection. Close only if the owner chooses that scope instead of a quota utility or new input. No comment or closure text has been posted. |

### Ordering / "ship-together" chains

- **Encryption/provider migration:** [Azure/terraform-azurerm-avm-res-cognitiveservices-account#252](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/pull/252) -> [Azure/terraform-azurerm-avm-res-cognitiveservices-account#253](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/pull/253) -> resolution of [Azure/terraform-azurerm-avm-res-cognitiveservices-account#247](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/247). PR 253 includes 252's interface migration; both touch the provider graph and `_header.md`. Neither removes the provider-4 constraint as submitted. Current CMK and diagnostic contract decisions must precede implementation.
- **Deployment migration documentation:** [Azure/terraform-azurerm-avm-res-cognitiveservices-account#202](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/202) and [Azure/terraform-azurerm-avm-res-cognitiveservices-account#215](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/pull/215) ship together: removing moves without instructions still leaves consumers exposed to recreation.
- **Shared deployment call, coordination only:** [Azure/terraform-azurerm-avm-res-cognitiveservices-account#202](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/202) and [Azure/terraform-azurerm-avm-res-cognitiveservices-account#204](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/204) both touch `main.tf` near `module.deployment`, but address migration and optional attestation are distinct behaviors. File overlap alone does not establish an execution dependency.

---

## Open questions for you

1. For [Azure/terraform-azurerm-avm-res-cognitiveservices-account#247](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/247), approve a breaking migration to canonical CMK variant 2 and diagnostic-settings v2, or retain legacy inputs temporarily while planning that release? Simply permitting AzureRM 5.x conflicts with current AVM policy.
2. For [Azure/terraform-azurerm-avm-res-cognitiveservices-account#120](https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/issues/120), is the documented consumer-side capacity pattern the final supported scope, or should a separately owned quota utility remain on the roadmap?
3. After the consolidated PR is validated, may the superseded contributor PRs be closed with attribution? No closures or explanatory comments are authorized by this report.

---

## Next steps

Continue the existing consolidated branch rather than assign parallel cloud agents. Run the new provider-mocked regressions and managed authoring gates, publish one draft PR with exact results, and keep unresolved upstream/design items visible rather than claiming the entire backlog is fixed.

Release remains gated on a real-state deployment/RAI policy upgrade and a no-change follow-up plan. No live Azure apply, destructive migration or production plan is authorized by this triage.

### Consolidated implementation validation

The final implementation uses Avm.Authoring 0.44.0, installed from the registered Microsoft Artifact Registry. The initial 0.14.0 pre-commit run passed but reintroduced retired ModTM resources; that generated telemetry drift was discarded. It is not retained as final validation evidence.

Commands below run from the repository root in PowerShell after `Import-Module Avm.Authoring -RequiredVersion 0.44.0`:

| Command | Result |
|---------|--------|
| `avm transform` | Passed after refreshing two stale, ignored example provider lock files. |
| `avm format` | Passed. |
| `avm docs` | Passed; root and changed example READMEs generated and reviewed. |
| `avm test unit` | Passed: 19 runs, including both new DNS regressions. |
| `avm test` | Passed: module validation and initialization/validation of all seven examples; no Azure deployment. |
| `avm pre-commit` | Blocked: required Pester 5.7.1 could not be downloaded because the public Gallery package connection failed. |
| `AVM_NO_AUTO_INSTALL=1 pwsh -NoLogo -NoProfile -Command 'Import-Module Avm.Authoring -RequiredVersion 0.44.0; avm pr-check'` | Blocked on a clean committed worktree: Pester 5.7.1 is missing. Automatic installation was disabled only for this diagnostic after repeated download failures; the gate failed rather than skipping the dependency. |

No Pester dependency was suppressed, no local rule exception was added, and no existing business-resource provider contract was widened. Live Azure integration, E2E and real-state upgrade tests were not run.
