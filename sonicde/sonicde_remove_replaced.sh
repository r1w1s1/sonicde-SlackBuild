#!/bin/bash
# -----------------------------------------------------------------------------
# Purpose: Show or remove Slackware KDE/Plasma packages replaced by SonicDE.
# -----------------------------------------------------------------------------

ADM_DIR="/var/lib/pkgtools"
DRYRUN=0

findpkg() {
  local PKGNAME="${1}"
  local FOUND=""
  if [ -d ${ADM_DIR}/packages ]; then
    pushd ${ADM_DIR}/packages >/dev/null
      FOUND=$(ls -1t | grep -E "^${PKGNAME}-[^-]+-[^-]+-[^-]+$" 2>/dev/null | head -n1)
    popd >/dev/null
  fi
  echo ${FOUND}
}

doremove() {
  local PKGBASE="${1}"
  local PKGNAME
  PKGNAME="$(findpkg ${PKGBASE})"

  if [ -z "$PKGNAME" ]; then
    echo "++ Package '${PKGBASE}' is not installed."
  elif [ ${DRYRUN} -eq 1 ]; then
    echo "++ Package '${PKGNAME}' is installed and would be removed."
  else
    removepkg ${PKGNAME}
  fi
}

while getopts "hn" Option
do
  case $Option in
    n )
        DRYRUN=1
        ;;
    h|* )
        echo "$(basename $0) [<param>] [package ...]"
        echo "Parameters are:"
        echo "  -n            Show what the script would do, without removing packages."
        echo "  -h            This help."
        echo
        echo "With no package arguments, all left-column packages from package-renames"
        echo "are checked/removed."
        exit
        ;;
  esac
done

shift $(($OPTIND - 1))

cd $(dirname $0) ; CWD=$(pwd)

if [ -n "$*" ]; then
  PKGS="$*"
else
  PKGS="$(grep -Ev '(^ *#|^$)' ${CWD}/package-renames | awk '{print $1}')"
fi

for PKG in ${PKGS}; do
  doremove ${PKG}
done

# Done.
