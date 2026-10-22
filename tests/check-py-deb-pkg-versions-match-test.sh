#!/usr/bin/env bash
# check-py-deb-pkg-versions-match-test.sh: run the version comparison step of
# check-py-deb-pkg-versions-match.yml against Debian/Python version pairs. Needs python3-yaml.
set -euo pipefail

workflow="$(dirname "${BASH_SOURCE[0]}")/../.github/workflows/check-py-deb-pkg-versions-match.yml"
step=$(python3 -c '
import sys, yaml
steps = yaml.safe_load(open(sys.argv[1]))["jobs"]["check-version"]["steps"]
print(next(s["run"] for s in steps if s.get("id") == "check-version"))
' "$workflow")

failures=0
expect() {
  local want=$1 deb=$2 py=$3 got
  if DEB_VERSION=$deb CURRENT_PY_VERSION=$py CHANGELOG=debian/changelog VERSION_FILE=__version__.py \
    bash -c "$step" >/dev/null 2>&1; then got=pass; else got=fail; fi
  if [ "$got" != "$want" ]; then
    echo "FAIL: changelog '$deb', __version__ '$py': want $want, got $got"
    failures=$((failures + 1))
  fi
}

expect pass 1.2.0-1 1.2.0
expect pass 1:1.2.0-1 1.2.0
expect pass 1.2.0 1.2.0
expect fail 1.2.1-1 1.2.0
expect pass 1.1.0-beta3 1.1.0-beta3
expect pass 1.1.0-beta3 1.1.0b3
expect pass 1.1.0~beta3-1 1.1.0b3
expect pass 1.1.0-b2 1.1.0-b2
expect pass 1.0.2b4 1.0.2b4
expect pass 0.0.1~rc1 0.0.1rc1
expect pass 1.0.0~c1-1 1.0.0rc1
expect pass 1.0.0~rc-1 1.0.0rc0
expect pass 1.0.0~ALPHA.2-1 1.0.0a2
expect fail 1.1.0-beta4 1.1.0-beta3
expect fail 1.0.2b5 1.0.2b4
expect fail 1.1.0-b3 1.1.0-b2
expect fail 1.1.0-beta1 1.1.0
expect fail 0.0.1-1 0.0.1rc1
expect fail 1.0.0~a1 1.0.0b1
expect pass 2.0.0~dev20250115.1 2.0.0
expect pass 1.1.6-dev.1 1.1.6.dev1
expect pass 1.0.2-2 1.0.2.post1
expect pass 1.0.8-4 1.0.8-4
expect pass 1.0.4+nmu1 1.0.4
expect pass 1.0.0+b1 1.0.0
expect pass 1.0.0-custom1 1.0.0

if [ "$failures" -ne 0 ]; then
  exit 1
fi
echo "all version cases pass"
