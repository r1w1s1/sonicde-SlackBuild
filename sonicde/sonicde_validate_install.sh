#!/bin/bash
# -----------------------------------------------------------------------------
# Purpose: Validate a SonicDE install after building this SlackBuild module.
# -----------------------------------------------------------------------------

set -u

CWD=$(cd $(dirname $0) ; pwd)
ADM_DIR=${ADM_DIR:-/var/lib/pkgtools}
CHECK_TAGS=${CHECK_TAGS:-no}

failures=0

heading() {
  echo
  echo "== $* =="
}

fail() {
  echo "!! $*"
  failures=$((failures + 1))
}

pass() {
  echo "++ $*"
}

findpkg() {
  local PKGNAME="$1"
  local FOUND=""

  if [ -d ${ADM_DIR}/packages ]; then
    pushd ${ADM_DIR}/packages >/dev/null || return 0
      FOUND=$(ls -1t | grep -E "^${PKGNAME}-[^-]+-[^-]+-[^-]+$" 2>/dev/null | head -n1)
    popd >/dev/null || return 0
  fi

  echo ${FOUND}
}

heading "SonicDE package count"
SONIC_COUNT=$(ls ${ADM_DIR}/packages/sonic-* ${ADM_DIR}/packages/xdg-desktop-portal-sonicde-* 2>/dev/null | wc -l)
echo "Installed SonicDE packages: ${SONIC_COUNT}"
if [ "${SONIC_COUNT}" -gt 0 ]; then
  pass "SonicDE packages are installed."
else
  fail "No SonicDE packages found."
fi

heading "Old SonicDE versions"
OLD_SONIC=$(ls ${ADM_DIR}/packages/sonic-* 2>/dev/null | grep -E '6\.27\.0|6\.7\.2' | grep -v 'sonic-pipewire-6\.7\.2' | grep -v 'sonic-frameworks-crash-handler-6\.27\.0' || true)
if [ -n "${OLD_SONIC}" ]; then
  echo "${OLD_SONIC}"
  fail "Old SonicDE packages remain installed."
else
  pass "No old SonicDE 6.27.0/6.7.2 packages found, except allowed sonic-pipewire 6.7.2 and sonic-frameworks-crash-handler 6.27.0."
fi

heading "Core package versions"
for pkg in \
  sonic-frameworks-core-addons \
  sonic-frameworks-windowsystem \
  sonic-workspace \
  sonic-login-manager \
  sonic-dr-robotnik ; do
  FOUND=$(findpkg ${pkg})
  if [ -n "${FOUND}" ]; then
    pass "${FOUND}"
  else
    fail "${pkg} is not installed."
  fi
done

heading "Tag checker"
if [ "${CHECK_TAGS}" = "yes" -o "${CHECK_TAGS}" = "YES" ]; then
  if [ -x ${CWD}/sonicde_check_tags.sh ]; then
    TAG_UPDATES=$(${CWD}/sonicde_check_tags.sh | grep UPDATE || true)
    if [ -n "${TAG_UPDATES}" ]; then
      echo "${TAG_UPDATES}"
      fail "Tag checker reports updates."
    else
      pass "No tag updates reported."
    fi
  else
    fail "sonicde_check_tags.sh is missing or not executable."
  fi
else
  echo "Skipping network tag check. Run with CHECK_TAGS=yes to enable it."
fi

heading "Replaced KDE packages"
LEFTOVERS=""
while read -r OLD NEW ; do
  [ -z "${OLD}" ] && continue
  case "${OLD}" in \#*) continue ;; esac
  [ "${OLD}" = "${NEW}" ] && continue
  FOUND=$(findpkg ${OLD})
  if [ -n "${FOUND}" ]; then
    LEFTOVERS="${LEFTOVERS}${FOUND} -> ${NEW}
"
  fi
done < ${CWD}/package-renames

if [ -n "${LEFTOVERS}" ]; then
  printf "%b" "${LEFTOVERS}"
  fail "Some replaced KDE packages are still installed."
else
  pass "No replaced KDE packages remain installed."
fi

heading "PolkitQt6 CMake export"
POLKIT_TARGET=/usr/lib64/cmake/PolkitQt6-1/PolkitQt6-1Targets.cmake
if [ -r ${POLKIT_TARGET} ]; then
  BAD_POLKIT=$(grep -n 'polkit-gobject\|PkgConfig::POLKIT\|/usr/include/polkit-1' ${POLKIT_TARGET} || true)
  if [ -n "${BAD_POLKIT}" ]; then
    echo "${BAD_POLKIT}"
    fail "PolkitQt6 CMake export still leaks polkit internals."
  else
    pass "PolkitQt6 CMake export looks clean."
  fi
else
  fail "${POLKIT_TARGET} not found."
fi

heading "Result"
if [ ${failures} -eq 0 ]; then
  echo "SonicDE install validation passed."
  exit 0
else
  echo "SonicDE install validation failed: ${failures} issue(s)."
  exit 1
fi
