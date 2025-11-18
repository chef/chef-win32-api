## Purpose

This document defines the operational standards and step-by-step workflow for AI-assisted and human contributors working in the `chef-win32-api` repository. It ensures consistent task intake (Jira or freeform), structured planning, safe implementation, test & coverage enforcement, DCO compliance, branch & PR hygiene, label usage, and iterative confirmation-driven collaboration. All actions MUST follow the guardrails herein; deviation requires explicit maintainer approval.

---
## Repository Structure (Concise Overview)

```
.
├── CHANGES                  # Historical changelog
├── README.md                # Project description & usage examples
├── RELEASE.md               # Manual gem release guidance (Windows / Docker)
├── Rakefile                 # Build, test, extension, style tasks
├── Gemfile                  # Declares gemspec + dependency source
├── chef-win32-api.gemspec   # Gem specification incl. native extension
├── ext/                     # Native C extension sources
│   └── win32/
│       ├── api.c            # Core Windows API wrapper implementation
│       └── extconf.rb       # Extension build script
├── lib/
│   └── win32/
│       └── api.rb           # Ruby loader (requires compiled .so)
├── test/                    # test-unit based test suites
│   ├── test_win32_api.rb
│   ├── test_win32_api_callback.rb
│   └── test_win32_api_function.rb
├── .rubocop.yml             # Style/lint (Cookstyle + RuboCop) config
├── appveyor.yml             # (Legacy/Windows CI) - may be historical
├── Dockerfile               # Environment for building/testing
├── Dockerfile.trunk         # Alternate build/lint/trunk pipeline docker
├── build-gem.bat            # Windows gem packaging helper
├── .github/
│   ├── workflows/
│   │   ├── lint.yml         # Runs Cookstyle lint on pushes/PRs
│   │   └── unit-test.yml    # Matrix (Ruby 3.1 & 3.4) Windows unit tests
│   └── dependabot.yml       # Dependency update automation
└── (No Expeditor / policy files detected)
```

Notes:
- No `LICENSE`, `SECURITY.md`, `CODE_OF_CONDUCT`, or `CODEOWNERS` files currently present. Treat licensing as defined by gemspec (`Artistic-2.0`). Do NOT introduce or modify policy/legal files without explicit instruction.
- No coverage tooling config present (e.g., SimpleCov). This document introduces an approach to add coverage measurement when needed.

---
## Tooling & Ecosystem

Language: Ruby (>= 3.1) with a native C extension targeting Windows APIs.

Build/Test Stack:
1. Native Extension: Built via `extconf.rb` + `rake-compiler` / `rake compile` (invoked by default Rake task chain `clobber compile test:all`).
2. Test Framework: `test-unit` (see gemspec dev dependency `test-unit >= 3.6.7`).
3. Linting/Style: `cookstyle` (Chef-flavored RuboCop) using `.rubocop.yml` (Rubocop target version 2.7 but gemspec requires Ruby >= 3.1—maintain compatibility).
4. CI: GitHub Actions workflows (`lint.yml`, `unit-test.yml`) + Dependabot updates.
5. Optional Local Docker Build: Provided Dockerfiles for consistent environment.

Coverage Strategy (to reach & enforce >=80%):
– Adopt SimpleCov when adding or modifying tests. (Add `simplecov` to development dependencies if coverage enforcement requested.)
– Baseline currently unknown (no coverage tool). When introducing coverage, create `test/test_helper.rb` requiring SimpleCov and ensure each test file requires it first.

---
## MCP (Jira) Integration

If a Jira issue ID (e.g., `PROJ-123`) is supplied, AI/human contributors MUST fetch and analyze it using the Atlassian MCP server before coding.

Standard Call Pattern:
1. Input Provided: Jira ID (e.g., `ABC-123`).
2. Action: Invoke MCP: `atlassian-mcp-server -> getIssue <JIRA_ID>` (conceptual call – executed through the integrated MCP tooling, not manual REST here).
3. Parse Fields: Summary, Description, Acceptance Criteria (AC bullets), Linked Issues, Story Points (if any), Labels, Components.
4. Output Structured Plan (sections):
   - Objective
   - Impacted Files / Modules
   - Data Flow / API Surface Changes
   - Test Strategy (unit, edge cases, negative paths)
   - Risk & Mitigations
   - Coverage Considerations
5. Prompt user: present plan & ask confirmation BEFORE implementation: "Continue to next step? (yes/no)".

If NO Jira ID: treat task as “freeform” and produce an analogous structured plan referencing repository files.

---
## Workflow Overview (High-Level Lifecycle)

1. Intake & Clarify (Jira fetch or freeform analysis)
2. Repo Analysis (confirm structure / affected components)
3. Plan Draft (design + test strategy + risk)
4. User Confirmation Gate
5. Branch Creation & Incremental Implementation
6. Test + Coverage (iterate until >=80%)
7. Lint / Style Fixes
8. Commit(s) with DCO Sign-off
9. Push & PR Creation (HTML structured description)
10. Labeling & Status Checks
11. Review Feedback Iterations (repeat steps 5–10 as needed)
12. Merge (maintainer only) or Close

Every major step ends with:
– Summary
– Remaining Steps Checklist
– Explicit prompt: "Continue to next step? (yes/no)"

---
## Detailed Step Instructions

### 1. Intake & Clarify
Collect task input: Jira ID or textual description. If Jira ID provided, perform MCP fetch (see above). Extract AC & constraints. List assumptions (max 2) if any ambiguity; request clarification only if blocking.

### 2. Repository Analysis
Confirm impacted extension code (`ext/win32/api.c`) vs Ruby loader (`lib/win32/api.rb`) vs tests. Determine if changes require new C functions, Ruby wrappers, or test adjustments. Identify if additional native prototypes imply adjusting callback logic, function pointer invocation tables, or error handling.

### 3. Plan Draft
Create structured bullets: Files to modify, New functions, Edge Cases (null pointer, invalid handle, wrong prototype, memory boundary), Test Cases (positive/negative), Coverage Hotspots (new branches / error paths), Rollback Strategy.

### 4. Confirmation Gate
Show plan. Ask: "Continue to next step? (yes/no)". Abort if no.

### 5. Branch Creation & Implementation
Branch naming: EXACT Jira ID if present (e.g., `ABC-123`). If no Jira ID: use slug `task-short-slug` (kebab-case). Avoid slashes beyond standard feature naming to simplify automation.

Commands (example):
```bash
git fetch origin
git checkout -b ABC-123
```
Implement minimal vertical slice: code + matching tests. Avoid large multi-concern commits.

### 6. Tests & Coverage
Run full test suite:
```bash
bundle install
bundle exec rake
```
If coverage added (recommended for substantive changes):
```ruby
# test/test_helper.rb (create if absent)
require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
  minimum_coverage 80
end
```
Ensure each test file requires `test_helper` first. Iterate until coverage >= 80%; if failing, list uncovered files & propose additional tests before proceeding.

### 7. Lint / Style
```bash
bundle exec rake style
```
Fix offenses before commit. Keep diffs focused.

### 8. Commit with DCO
All commits MUST include a sign-off line:
```
Signed-off-by: Full Name <email@example.com>
```
Refuse to push if missing. Sample commit:
```bash
git add ext/win32/api.c test/test_win32_api.rb
git commit -m "ABC-123: Add extended pointer validation" -m "Signed-off-by: Jane Doe <jane.doe@example.com>"
```

### 9. Push & PR Creation
```bash
git push -u origin ABC-123
gh pr create --fill
```
Then edit PR description to HTML template:
```html
<h2>Summary</h2>
<p>Short functional description.</p>
<h2>Jira</h2>
<p><a href="https://jira.example.com/browse/ABC-123">ABC-123</a></p>
<h2>Changes</h2>
<ul>
  <li>Updated api.c: added error code propagation for callbacks.</li>
  <li>Added tests for invalid prototype handling.</li>
</ul>
<h2>Tests & Coverage</h2>
<p>All tests passing. Coverage: 84% ( +3% ).</p>
<h2>Risk & Mitigations</h2>
<p>Moderate: native pointer logic. Mitigated via boundary tests.</p>
<h2>Labels Applied</h2>
<p>enhancement, test</p>
<h2>DCO</h2>
<p>All commits signed-off.</p>
```

### 10. Labels & Status Checks
Apply relevant labels (see Label Reference). Ensure CI jobs pass:
- Lint (Cookstyle)
- Unit Test (Windows matrix Ruby 3.1 / 3.4)
If a job fails: fix code, amend commit (keep DCO), force push only to feature branch (NOT default) if necessary.

### 11. Review Iterations
Address feedback incrementally. Each revision: re-run tests, update coverage note in PR if it changes. Maintain checklist updates in comments if large.

### 12. Merge (Maintainers Only)
Preferred strategy: Squash or rebase preserving meaningful commit messages with sign-off lines. Ensure the *final* squashed commit (if used) retains a DCO sign-off.

---
## Branching & PR Standards

Branch Naming:
1. Jira-based: `^[A-Z]+-[0-9]+$` (exact).
2. Freeform: `topic-short-slug` (lowercase kebab-case, <= 5 hyphenated segments).

Draft PR Criteria:
– Incomplete test coverage
– Pending design clarification
– Experimental spike

Ready (non-draft) Criteria:
– All acceptance criteria met
– Tests passing locally
– Coverage >= 80%
– Lint clean

Required Status Checks (inferred from workflows):
– `lint` (GitHub Actions) must succeed
– `Unit Test` matrix jobs must succeed

Re-run Workflows:
Via GitHub UI (Re-run failed jobs) or by pushing a no-op commit:
```bash
git commit --allow-empty -m "ABC-123: CI re-run" -m "Signed-off-by: Jane Doe <jane.doe@example.com>"
git push
```

Merge Strategy Guidance:
– Prefer Squash for single-feature changes.
– Use Rebase if preserving a logical progression of native + test commits.
– Avoid Merge commits unless synchronizing large rebases.

---
## Commit & DCO Policy

Mandatory DCO: Every commit ends with exactly one sign-off line:
`Signed-off-by: Full Name <email@domain>`

Rules:
1. Name must match an identifiable contributor (no handles only).
2. Email must be valid format.
3. Amend (`git commit --amend -s`) if omitted.
4. Reject generating non-compliant commit messages.

Verification:
```bash
git log -n 5 --pretty=format:"%h %s%n%b" | grep -i "Signed-off-by:" || echo "Missing sign-off!"
```

---
## Testing & Coverage Enforcement

Test Commands:
```bash
bundle install
bundle exec rake test:all   # or just: bundle exec rake
```
Focused subsets:
```bash
bundle exec rake test:function
bundle exec rake test:callback
```

Edge Case Checklist (sample for new APIs):
– Null pointer inputs
– Invalid function name resolution
– Wide vs ANSI function naming
– Callback parameter count mismatch
– Large buffer boundaries (off-by-one)

Coverage (<80% Remediation):
1. Generate report (after integrating SimpleCov): open `coverage/index.html`.
2. Identify low-hit branches in `api.c` (error paths, prototype validation, wide char handling).
3. Add targeted tests; re-run.
4. Document delta in PR.

---
## Labels Reference

Repository labels (fetched via `gh api`):

| Label | Description |
|-------|-------------|
| bug | Something isn't working |
| documentation | Improvements or additions to documentation |
| duplicate | This issue or pull request already exists |
| enhancement | New feature or request |
| good first issue | Good for newcomers |
| help wanted | Extra attention is needed |
| invalid | This doesn't seem right |
| oss-standards | Related to OSS Repository Standardization |
| question | Further information is requested |
| wontfix | This will not be worked on |

Suggested Mapping for Automation / AI Selection:
– Feature work → enhancement
– Defect fix → bug
– Refactor / maintenance → enhancement or (if added later) chore
– Docs-only → documentation
– Test improvements → (add test label if created) else documentation (note rationale)
– CI / workflow changes → (add ci label if exists) else enhancement

If a required semantic label missing, document need in PR description.

---
## CI / Automation Summary

GitHub Actions Workflows:
1. `lint.yml`
   - Triggers: `push` to `main`, all `pull_request`
   - Ensures Cookstyle compliance (Ruby 3.1). Concurrency configured to cancel in-progress duplicate refs.
2. `unit-test.yml`
   - Triggers: `push`, `pull_request`
   - Matrix: Ruby 3.1 & 3.4 on `windows-latest`
   - Runs install + `bundle exec rake` (builds native extension + tests)

Dependabot: `.github/dependabot.yml` (keeps dependencies updated – ensure PRs follow DCO before merging).

Expeditor: Not detected. (If added later: document channels, auto-versioning, merge automation, label triggers.)

---
## Security & Protected Files

Never modify without explicit maintainer approval:
– Policy/Legal placeholders (LICENSE once added, SECURITY.md, CODE_OF_CONDUCT, CODEOWNERS)
– GitHub workflow YAML unless task scope explicitly covers CI changes
– Secrets, credentials, tokens (never print or alter encrypted values)
– Release automation scripts for unrelated feature tasks

No force-push to `main`. Only push feature branches. Do not merge PR.

---
## Prompts Pattern (Interaction Model)

For each major step the AI assistant MUST:
1. Provide a concise Step Summary.
2. Supply a Remaining Steps Checklist (markdown list with checked/unchecked states).
3. End with explicit question:
   "Continue to next step? (yes/no)"

On "yes" proceed; on "no" pause and request clarification or revision input.

Example Interaction Snippet:
```
Plan Summary: Add pointer validation in api.c and new tests.
Remaining: [ ] Implement code  [ ] Add tests  [ ] Run coverage  [ ] Commit+PR
Continue to next step? (yes/no)
```

---
## Environment Preparation

Prerequisites:
– Ruby 3.1+ (match matrix target) & DevKit (on Windows) or build-essential (Linux for cross compile)
– Bundler
– GitHub CLI (`gh`) authenticated (avoid referencing shell profile; follow `gh auth login` interactive flow)
– (Optional) Docker if building inside container

Setup:
```bash
git clone https://github.com/chef/chef-win32-api.git
cd chef-win32-api
bundle install
bundle exec rake   # builds extension + runs tests
```

Optional Coverage Enablement (if adding SimpleCov):
```bash
echo "require 'simplecov'; SimpleCov.start" > test/test_helper.rb
sed -i '' '1irequire_relative "test_helper"' test/test_win32_api.rb
```
(Repeat for other test files; adjust platform-specific `sed` as needed.)

Docker (example build):
```bash
docker build -t chef-win32-api -f Dockerfile .
```

---
## Validation & Exit Criteria

Completion Definition for a Task:
1. All acceptance criteria (Jira or plan) satisfied.
2. Tests added/updated reflecting new logic & edge cases.
3. All tests green locally and in CI.
4. Coverage >= 80% (or justified exception documented in PR).
5. Lint/style passes (Cookstyle exit 0).
6. DCO sign-off present on every commit.
7. PR description uses required HTML template sections.
8. Appropriate labels applied.
9. Risks & mitigations articulated in PR.
10. User/maintainer approved final confirmation step.

If any criterion unmet, assistant must loop: identify gap → propose fix → request continuation approval.

---
## Safety & Guardrails Recap

DO NOT:
– Expose or modify secrets.
– Commit large binaries or OS-specific build artifacts.
– Edit licensing or governance docs without explicit request.
– Skip tests or reduce coverage without justification.
– Merge or release autonomously.

DO:
– Keep changes minimal & cohesive.
– Pair each code change with a test.
– Pause for confirmation at every major gate.

---
## Idempotency & Recovery

On re-run or resumed session:
1. Detect existing feature branch (`git branch --list <name>`). If exists, reuse.
2. If PR already open, update rather than recreate; reference PR number.
3. Recompute remaining checklist (exclude already-completed steps).
4. If coverage config absent but previously promised, (re)introduce before continuing.

---

## AI-Assisted Development & Compliance

- ✅ Create PR with `ai-assisted` label (if label doesn't exist, create it with description "Work completed with AI assistance following Progress AI policies" and color "9A4DFF")
- ✅ Include "This work was completed with AI assistance following Progress AI policies" in PR description

### Jira Ticket Updates (MANDATORY)

- ✅ **IMMEDIATELY after PR creation**: Update Jira ticket custom field `customfield_11170` ("Does this Work Include AI Assisted Code?") to "Yes"
- ✅ Use atlassian-mcp tools to update the Jira field programmatically
- ✅ **CRITICAL**: Use correct field format: `{"customfield_11170": {"value": "Yes"}}`
- ✅ Verify the field update was successful

### Documentation Requirements

- ✅ Reference AI assistance in commit messages where appropriate
- ✅ Document any AI-generated code patterns or approaches in PR description
- ✅ Maintain transparency about which parts were AI-assisted vs manual implementation

### Workflow Integration

This AI compliance checklist should be integrated into the main development workflow Step 4 (Pull Request Creation):

```
Step 4: Pull Request Creation & AI Compliance
- Step 4.1: Create branch and commit changes WITH SIGNED-OFF COMMITS
- Step 4.2: Push changes to remote
- Step 4.3: Create PR with ai-assisted label
- Step 4.4: IMMEDIATELY update Jira customfield_11170 to "Yes"
- Step 4.5: Verify both PR labels and Jira field are properly set
- Step 4.6: Provide complete summary including AI compliance confirmation
```

- **Never skip Jira field updates** - This is required for Progress AI governance
- **Always verify updates succeeded** - Check response from atlassian-mcp tools
- **Treat as atomic operation** - PR creation and Jira updates should happen together
- **Double-check before final summary** - Confirm all AI compliance items are completed

### Audit Trail

All AI-assisted work must be traceable through:

1. GitHub PR labels (`ai-assisted`)
2. Jira custom field (`customfield_11170` = "Yes")
3. PR descriptions mentioning AI assistance
4. Commit messages where relevant

---

## Final Note

This file is additive and non-destructive. Update carefully when workflows, labels, or tooling evolve. Always maintain the confirmation-driven model and DCO enforcement.
