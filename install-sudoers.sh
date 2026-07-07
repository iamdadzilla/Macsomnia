#!/bin/bash
set -euo pipefail

# Grants the current user password-free use of /usr/bin/pmset, so Macsomnia
# can disable/enable sleep without a password prompt. Run once.

RULE_FILE="/etc/sudoers.d/macsomnia"
TMP_FILE="$(mktemp)"
USER_NAME="$(id -un)"

printf '%s ALL=(root) NOPASSWD: /usr/bin/pmset\n' "$USER_NAME" > "$TMP_FILE"

# Validate before installing — never install an unparseable sudoers file.
if ! sudo visudo -cf "$TMP_FILE" >/dev/null; then
    echo "Refusing to install: sudoers syntax check failed." >&2
    rm -f "$TMP_FILE"
    exit 1
fi

sudo install -m 0440 -o root -g wheel "$TMP_FILE" "$RULE_FILE"
rm -f "$TMP_FILE"

echo "Installed $RULE_FILE for user '$USER_NAME'."
echo "Verifying password-free pmset..."
if sudo -n /usr/bin/pmset -g >/dev/null 2>&1; then
    echo "OK — Macsomnia can now run pmset without a password."
else
    echo "WARNING: password-free pmset did not work. Check the rule." >&2
    exit 1
fi
