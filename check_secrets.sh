#!/usr/bin/env bash
set -euo pipefail

# These two values are passed in by the workflow's `env:` block, which maps:
#   - a GitHub Actions *Secret*   (sensitive)     -> MY_SECRET
#   - a GitHub Actions *Variable* (non-sensitive) -> MY_GREETING
#
# The `${VAR:?message}` form exits with the given message if the var is
# unset or empty. On your very first run (before you add the secret), this
# will fail on purpose with a clear message — that is expected.

: "${MY_SECRET:?MY_SECRET is not set. Add a repository SECRET named MY_SECRET.}"
: "${MY_GREETING:?MY_GREETING is not set. Add a repository VARIABLE named MY_GREETING.}"

# POC: echo BOTH values directly to compare how they appear in the logs.
#
# The Variable is non-sensitive and will appear in clear text.
echo "Variable MY_GREETING : ${MY_GREETING}"

# The Secret is echoed directly here too, but GitHub auto-masks any
# registered secret value in the log output, so you'll see *** instead
# of the real value. That redaction is the whole point of this demo.
echo "Secret   MY_SECRET   : ${MY_SECRET}"

# Optional experiment: GitHub's masking is a literal string match on the
# registered secret. If you TRANSFORM the secret (e.g. reverse it or
# base64-encode it), the transformed text no longer matches and is NOT
# masked. That's why masking is only a backstop, never a reason to print
# real secrets. Uncomment to see it with your throwaway value:
# echo "Reversed (NOT masked): $(echo -n "$MY_SECRET" | rev)"
