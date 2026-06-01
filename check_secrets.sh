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

echo "----------------------------------------"
echo "Masking experiments (throwaway value only):"
echo

# 1) Wrapped in asterisks. The secret's own characters are still contiguous,
#    so the literal match still finds them. Expected: the middle stays ***.
echo "1. Wrapped     : *${MY_SECRET}*"

# 2) Reversed. The literal registered string no longer appears in the output,
#    so there is nothing for the masker to match. Expected: leaks in clear.
echo "2. Reversed    : $(printf '%s' "$MY_SECRET" | rev)"

# 3) Base64-encoded. This is the open question — I'm not certain whether
#    GitHub also registers/masks the base64 form of a secret. The run itself
#    is the test. Expected: unknown; watch what actually prints.
echo "3. Base64      : $(printf '%s' "$MY_SECRET" | base64)"

echo
echo "Takeaway: any transform that breaks the literal value defeats masking,"
echo "which is why masking is only a backstop, never a reason to print real secrets."
