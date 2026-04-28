---
name: bstock-merge-requests
description: Use this skill whenever the user wants to create or update a GitLab merge request for a B-Stock project, especially when the request involves B-Stock conventions like Jira ticket IDs, semantic MR prefixes (`MAJOR`, `MINOR`, `PATCH`, `NO-RELEASE`), merge request templates, changelog `<details open>` blocks, assignee handling, or project-specific checklist validation. Also use it when the user says things like “create an MR,” “open a merge request,” “I just pushed my branch,” or “write the MR description” in a B-Stock repo context. This skill is for B-Stock repositories and workflows, not generic GitLab merge request creation.
---

Use this skill to create or update B-Stock GitLab merge requests consistently.

## Scope

Use this skill for B-Stock repositories and B-Stock merge request conventions. Do not use it as a general GitLab merge request skill for unrelated repositories unless the user explicitly wants to apply B-Stock MR conventions outside B-Stock.

## What this skill covers

- Creating a new B-Stock merge request
- Updating an existing B-Stock merge request's title, description, or metadata
- Choosing and applying the correct semantic version prefix
- Filling the project's merge request template correctly
- Handling Jira ticket references and changelog details blocks
- Validating checklist items conservatively based on actual evidence

## Example triggers

- "Create a merge request for these changes."
- "I've finished implementing the risky buyers grid feature on branch `mg-SPR-3998-add-risky-buyers-grid`. Can you open the MR?"
- "I just pushed my branch and git is suggesting I create a merge request."
- "Can you write the MR description and make sure the title follows B-Stock conventions?"
- "Please update this B-Stock MR so the semver prefix and checklist are correct."

## Gather this first

Before creating or updating an MR, gather:
- current branch name
- target branch (usually `main`)
- project context (for example `fe-core`, `home-portal`, or another B-Stock repo)
- Jira ticket ID(s) associated with the work
- semantic version type (`MAJOR`, `MINOR`, `PATCH`, `NO-RELEASE`)
- short summary of the work
- related MRs, if any
- whether the user wants draft/prep help only or actual MR creation/update in GitLab

## Prerequisites and execution mode

For actual MR creation:
- all desired changes should already be committed to the feature branch
- the feature branch should already be pushed to GitLab
- the working tree should usually be clean unless the user explicitly says to ignore that

If the branch is not ready for creation, do not bluff your way through it. Explain what is missing and offer to draft the title, description, and checklist content first.

Before creating or updating a B-Stock MR in GitLab, verify that GitLab MCP tools are available by checking for the presence of `mcp__gitlab__create_merge_request` in the available tools.

If GitLab MCP tools are unavailable:
- do not attempt live MR creation or MR updates in GitLab
- tell the user: "GitLab MCP tools are unavailable. Please run `/mcp` to authenticate or restart Claude to restore access. I can still draft the merge request title, description, semver recommendation, and checklist guidance for you."
- continue in draft/prep mode if that would still help

## Communication style

Be concise. Surface uncertainty clearly. Confirm important details before consequential actions. Do not claim that checklist items are complete unless you have verified them.

## MR title format

Format titles as:

`{SEMANTIC_PREFIX}: {JIRA_ID} {Brief description}`

Examples:
- `MINOR: SPR-3998 Add risky buyers grid to CSP`
- `PATCH: SPR-4321 Fix cookie consent banner styling`
- `MAJOR: SPR-4400 Remove deprecated manifest API endpoints`

Keep the title at or under 128 characters.

## Semantic versioning

The semantic versioning prefix determines the release impact once the branch is merged.

- `MAJOR` and `MINOR` should be used for breaking API changes, major user interface changes, or feature additions.
- `PATCH` should be used when there are no breaking changes.
- `NO-RELEASE` should be used when there are no visible changes to the user in a `*-portal` project or to the package consumer in a library project like `fe-core` or `bstock-eslint-config`.

If the user does not specify the semver prefix, infer it from the code changes, branch context, Jira context, and the user-facing impact. If you are not confident, say so clearly instead of guessing silently.

### Changelog details block for MAJOR and MINOR

For `MAJOR` and `MINOR` MRs, the MR description should include a changelog entry inside a `<details open>` block.

Do not edit `CHANGELOG.md` directly. That file is managed automatically by semantic-release, which reads the merged MR description and appends the entry after release tagging.

Use this format:

```markdown
<details open>

### Nonbreaking
- [JIRA-ID](https://bstock.atlassian.net/browse/JIRA-ID) Concise description of the changes

</details>
```

Use `### Breaking` instead of `### Nonbreaking` for `MAJOR` changes.

Warn the user if a `MAJOR` or `MINOR` MR is missing this block.

## MR configuration standards

When creating B-Stock MRs, use these defaults unless the user asks otherwise:
- `remove_source_branch: true`
- `squash: true`
- assign the MR to the MR creator

Do not guess the assignee. If you do not yet know the creator's user ID, create the MR without an assignee, retrieve the MR, read the creator ID associated with the GitLab MCP token, and then update the MR with that creator ID as the assignee using `mcp__gitlab__update_merge_request`.

## Merge request template usage

Always use the project's merge request template as the basis for the MR body.

### Critical: templates are unique per project

**Every project has its own template files with its own filenames, sections, and checklist items.** Do not assume a template's filename, content, or checklist from memory or from another project. Always discover and read the actual template from the repository for each MR you create.

Template filenames vary significantly across projects. For example, some projects use `PATCH.md` while others use `PATCH - Tweaks and Refinements.md`. Guessing the filename will cause a lookup failure that silently falls through to the wrong fallback.

### Retrieval order

1. **List** the template directory to discover the actual filenames:
   ```
   mcp__gitlab__get_repository_tree(project_id, path=".gitlab/merge_request_templates", recursive=true)
   ```
   Then fetch the file whose name matches the semver prefix (MAJOR, MINOR, PATCH, or NO-RELEASE). Do not guess filenames — always list first.
2. If no `.gitlab/merge_request_templates` directory exists, call `mcp__gitlab__get_project` and read the `merge_requests_template` field — this is the project-level default template configured in GitLab settings (not stored as a repo file).
3. If both are empty or unavailable, use the fallback structure below.

### Template handling rules

- Keep section headers intact.
- Replace placeholder text with real content about the branch.
- Preserve emoji indicators and useful instructional notes from the template.
- Do not pre-check checklist items unless you have verified them.
- Keep the final description informative but not sprawling.

### Fallback structure

If no usable template exists, use a simple structure like:

```markdown
## Description

[Brief summary of the change and why it exists]

## Testing

[How reviewers or QA can test it]

## Screenshots

[Links, screenshots, or "N/A"]

## Notes

[Known caveats, rollout concerns, or reviewer guidance]
```

## Checklist validation requirements

Before checking any box in an MR template, inspect the actual file changes and only mark items that are supported by evidence.

### Validation process

1. Find the merge base between the current branch and the target branch:
   ```bash
   git merge-base HEAD target_branch
   ```
2. Use that merge base to inspect changed files:
   ```bash
   git diff --name-only <merge-base>..HEAD
   ```

Do not wrap `git merge-base` in shell variable assignment syntax like `MERGE_BASE=$(...)` if that environment would prompt for extra permission. Run the commands separately and reuse the earlier output.

### Specific validation rules

- **"Added changelog entry"** → Only check this if the MR description contains the required `<details open>` changelog block. Never base this on `CHANGELOG.md` file changes.
- **"Tests added/updated"** → Only check this if changed files include test files such as `.test.`, `.spec.`, `__tests__/`, or `/tests/`.
- **"Documentation updated"** → Only check this if changed files include documentation such as `.md`, `/docs/`, or `README` files.
- **"Linting/formatting applied"** → Only check this if you have actual evidence that linting passed.
- **"Type checking passes"** → Only check this if you have actual evidence that type checking passed.

When in doubt, leave the checkbox unchecked. It is better to be conservative than misleading.

## Writing the MR description

Write for code reviewers and QA engineers.

Emphasize:
- what changed
- why it changed
- any important user interface or API impact
- testing instructions
- what reviewers should pay attention to
- relevant URLs, screens, or environments when applicable

Be clear about how the branch differs from the target branch. Prefer concise, high-value detail over long repetitive prose.

## Workflow

### Draft/prep mode

Use this mode when GitLab MCP tools are unavailable or when the user only wants help preparing the MR.

1. Gather the required context.
2. Infer or confirm the Jira ticket and semver prefix.
3. Draft the MR title.
4. Retrieve or approximate the appropriate template structure if possible.
5. Draft the MR description and changelog details block when needed.
6. Suggest which checklist items could likely be checked once verified.
7. Show the user the proposed title, body, and any open questions.

### Creation/update mode

Use this mode when the user wants the MR created or updated in GitLab and MCP tools are available.

1. Validate prerequisites: branch ready, branch pushed, work complete enough for review.
2. Gather the required information.
3. Inspect branch changes for checklist validation.
4. Retrieve the per-prefix MR template first; fall back to the project-level template if needed.
5. Fill in the template while preserving structure.
6. Validate checklist items conservatively.
7. Summarize the proposed title, semver prefix, assignee behavior, and MR body unless the user clearly wants immediate execution.
8. Create or update the MR with the proper configuration.
9. Open the MR URL in the browser by default unless the user says not to.
10. Confirm the result and call out any uncertainties or follow-up actions.

## Error handling and fallbacks

- **401/403 errors** → Tell the user GitLab authentication may be missing or expired and prompt them to configure `BSTOCK_GITLAB_TOKEN` or refresh MCP access.
- **Missing Jira ticket** → Try to infer it from the branch name, commits, or context. If still unclear, ask the user. Only proceed without a Jira ID if the user explicitly confirms that is acceptable.
- **Missing semver prefix** → Infer it if possible and say when confidence is low.
- **Template retrieval failure** → Use the fallback structure and say that a repository template could not be loaded.
- **Unknown creator user ID** → Create the MR first, then retrieve it and assign the creator as the assignee.
- **Coverage parsing errors or similar GitLab/MCP quirks** → Acknowledge the issue, continue where safe, and avoid making unsupported claims.

## Quality checks

Before finalizing, make sure you have:
- chosen a semver prefix that matches the change scope
- included the Jira ticket in the title and description when appropriate
- confirmed the branch is pushed before live creation
- used the correct template or fallback structure
- included the changelog `<details open>` block for `MAJOR` and `MINOR` MRs
- avoided checking checklist items without evidence
- populated all required MR fields

## Integration points

- **Jira** → Link relevant tickets in the MR title and body. Updating Jira workflow state, such as moving to Technical Review, can be a useful follow-up when appropriate, but it is optional unless the user asks for it.
- **CI/CD** → Call out special build, deployment, migration, or rollout considerations when relevant.

Apply B-Stock conventions carefully, but stay practical: if live GitLab actions are unavailable, still help the user produce a strong MR draft instead of stopping cold.
