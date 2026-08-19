# Waiting for GitLab CI Pipelines & Jobs

To wait for a long-running GitLab pipeline, deploy, or job to finish, use the bundled poller as a **background task**. The harness wakes the session automatically when the process exits — no MCP polling, no `polling-agent`, and zero context burned while waiting.

Script: `~/.claude/skills/bstock-engineering/scripts/gitlab-ci-poll.sh`

It talks to `gitlab.bstock.io` via `glab` (already authenticated). Verify once with `glab auth status` if a call fails.

## How to use it

1. Resolve the target id first (you usually already have it — e.g. the pipeline id returned when creating an MR, or use `glab` to look one up).
2. Launch the script with the **`Bash` tool and `run_in_background: true`**. Do **not** `&`-background it yourself, and do **not** poll it on an interval — the harness tracks the process and re-invokes you on exit.
3. When the `<task-notification>` arrives, `Read` the output file and summarize the result.

```
Bash(run_in_background: true):
  ~/.claude/skills/bstock-engineering/scripts/gitlab-ci-poll.sh --project 506 --pipeline 362418
```

## Targets

| Flag | Polls |
|------|-------|
| `--pipeline <id>` | a specific pipeline |
| `--job <id>` | a single job (e.g. a deploy or a specific stage) |
| `--ref <branch>` | the latest pipeline on a branch/ref (handy right after pushing) |
| `--mr <iid>` | the latest pipeline for a merge request |

`--project` accepts a numeric id (preferred — see `project-ids.md`) or a `group/sub/path`.

## Options

| Option | Default | Notes |
|--------|---------|-------|
| `--interval <sec>` | `30` | poll cadence; safe to leave (no foreground tool timeout in background) |
| `--timeout <sec>` | `3600` | give up after this long → exit 124 |
| `--log-lines <n>` | `40` | lines of each failed job's log to tail |
| `--no-logs` | off | skip failed-job log tailing |
| `--success-grep <re>` | off | on success, grep the job/pipeline trace(s) for case-insensitive extended regex `<re>` and print matching lines in the summary — use it to surface a value the job emits (e.g. a published prerelease version) so it lands in the wake-up without a follow-up trace fetch |
| `--host <host>` | `gitlab.bstock.io` | |

## Output & exit codes

On completion it prints the final status, elapsed time, and web URL. For a pipeline target it then prints a **job table** — `id · status · stage · name` for every job — so you wake up holding each job id and can fast-follow a targeted `glab api projects/<id>/jobs/<job-id>/trace` on whatever you want to inspect, without a separate "list the jobs" call. On **failure** it additionally tails each failed job's log (default 40 lines, `--log-lines` to adjust) so the actual error is already in front of you, not just "failed".

The poller's job is to wake you up *oriented* — terminal status, the job roster, and a failure tail — not to parse logs for you. Deciding which job's full trace to pull, and reading test vs. lint vs. tsc output, is your call once you're awake: grab the id from the table and fast-follow.

| Exit | Meaning |
|------|---------|
| `0` | success / skipped / manual |
| `1` | failed (logs tailed) |
| `2` | canceled |
| `124` | timed out |
| `3` | usage / auth error |

## When NOT to use this

This is for **waiting**. To read pipeline/job *details into context* or to *act* on GitLab (create/merge MRs, retry pipelines, post notes), use `glab` directly — not this poller.
