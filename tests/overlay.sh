#!/bin/bash
# Static checks of what the overlay ships, runnable anywhere without a build.
#
# phpinfo.php published the whole PHP configuration to anybody on port 80
# (semgrep phpinfo-use). It is gone, and this keeps it from coming back under
# any name, as a phpinfo() call in some other page, or as a link to it.
# keel-health.php is the probe that replaced it: it proves PHP executes
# through FastCGI and answers "ok" as plain text, nothing else.
set -Eeuo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
overlay=$here/../overlay
probe=$overlay/var/www/keel-health.php
expected="<?php header('Content-Type: text/plain'); echo 'ok';"
failed=0

fail() {
    echo "overlay: $*" >&2
    failed=1
}

found=$(find "$overlay" -iname '*phpinfo*')
[ -z "$found" ] || fail "ships a phpinfo file: $found"

if grep -rIil 'phpinfo' "$overlay" >/dev/null; then
    fail "mentions phpinfo in: $(grep -rIil 'phpinfo' "$overlay" | tr '\n' ' ')"
fi

if [ ! -f "$probe" ]; then
    fail "no PHP probe at /var/www/keel-health.php"
elif [ "$(cat "$probe")" != "$expected" ]; then
    fail "keel-health.php is not exactly: $expected"
elif grep -q '?>' "$probe"; then
    # A closing tag lets a trailing newline reach the body.
    fail "keel-health.php has a closing tag"
fi

[ "$failed" -eq 0 ] || exit 1
echo "overlay: no phpinfo shipped; keel-health.php answers ok and nothing else"
