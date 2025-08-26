# /rebase

Use the git-rebase-resolver agent to rebase the current branch onto the default
branch for this project. Provide the agent with the working directory of the
project you are rebasing, as well as the topic branch (current branch) and
target branch (default branch – usually `origin/HEAD`)

The agent should take care of fetching the latest version of the target branch.

If the process is successful, push the result to the remote origin using
`--force-with-lease` and `--no-verify`, and utilize `npm ci` to install
dependencies if the agent suggests it.
