#!/bin/bash
# -----------------------------------------------------------------------------
# Purpose: A script to checkout SonicDE sources from GitHub tags and create
#          tarballs for the SonicDE SlackBuild tree.
# -----------------------------------------------------------------------------

# Defaults:
CWD=$(pwd)
CLEANUP="NO"
FORCE="NO"
MYDIR="${CWD}/_sonicde_checkouts"
SONICGITURI="https://github.com/Sonic-DE/"
TOPDIR=$(cd $(dirname $0); pwd)

while getopts "cfhk:o:" Option
do
  case $Option in
    c ) CLEANUP="YES"
        ;;
    f ) FORCE="YES"
        ;;
    k ) TOPDIR="${OPTARG}"
        ;;
    o ) MYDIR="$(cd ${OPTARG} ; pwd)"
        ;;
    h|* )
        echo "$(basename $0) [<param> <param> ...] [<module> [<module[:package[,package]]>] ...]"
        echo "Parameters are:"
        echo "  -c            Cleanup afterwards (delete the cloned repos)."
        echo "  -f            Force overwriting of tarballs if they exist."
        echo "  -h            This help."
        echo "  -k <dir>      Location of SonicDE sources if not $(cd $(dirname $0); pwd)/."
        echo "  -o <dir>      Temporary checkout directory instead of $MYDIR/."
        exit
        ;;
  esac
done

shift $(($OPTIND - 1))

MODS=${1:-"sonic"}

if ! [ -f ${TOPDIR}/sonicde.SlackBuild -a -d ${TOPDIR}/src ]; then
  echo ">> Error: '$TOPDIR' does not seem to contain sonicde.SlackBuild plus src/"
  echo ">> Either place this script in the sonicde directory before running it,"
  echo ">> Or specify the SonicDE toplevel source directory with the '-k' parameter"
  exit 1
fi

if ! [ -r ${TOPDIR}/source-versions ]; then
  echo ">> Error: '${TOPDIR}/source-versions' is missing."
  exit 1
fi

mkdir -p "${MYDIR}"
if [ $? -ne 0 ]; then
  echo "Error creating '${MYDIR}' - aborting."
  exit 1
fi
cd "${MYDIR}"

source_name() {
  local pkg="$1"
  if [ -f ${TOPDIR}/pkgsrc/${pkg} ]; then
    basename $(cat ${TOPDIR}/pkgsrc/${pkg})
  else
    echo ${pkg}
  fi
}

source_loc() {
  local pkg="$1"
  if [ -f ${TOPDIR}/pkgsrc/${pkg} ]; then
    dirname $(cat ${TOPDIR}/pkgsrc/${pkg})
  else
    echo .
  fi
}

source_version() {
  local src="$1"
  grep -E "^${src}[[:space:]]+" ${TOPDIR}/source-versions | awk '{print $2}' | tail -n 1
}

echo ">> Checking out SonicDE sources..."
for SRCSET in $MODS ; do
  SET=$(echo $SRCSET | cut -d: -f1)
  SRC="$(echo $SRCSET | cut -d: -f2- | tr ',' ' ')"
  if [ "$SET" == "$SRC" ]; then
    SRC="$(cat ${TOPDIR}/modules/${SET} | grep -v " *#" | grep -v "^$")"
  fi

  echo ">>   Module ${SET}..."
  for PKG in $SRC ; do
    SRCNAME=$(source_name ${PKG})
    SRCLOC=$(source_loc ${PKG})
    VERSION=$(source_version ${SRCNAME})

    if [ -z "${VERSION}" ]; then
      echo ">>     No version listed for ${SRCNAME}; skipping."
      continue
    fi

    mkdir -p ${SRCLOC} ${TOPDIR}/src/${SRCLOC}
    TARBALL=${TOPDIR}/src/${SRCLOC}/${SRCNAME}-${VERSION}.tar.gz
    CHECKOUT=${SRCLOC}/${SRCNAME}-${VERSION}

    if [ "$FORCE" = "NO" -a -f ${TARBALL} ]; then
      echo ">>     Not overwriting existing file '${TARBALL}'"
      echo ">>     Use '-f' to force overwriting existing files"
      continue
    fi

    rm -rf ${CHECKOUT}
    echo ">>     Fetching ${SRCNAME} tag ${VERSION}..."
    git clone ${SONICGITURI}${SRCNAME}.git ${CHECKOUT}
    if [ $? -ne 0 ]; then
      echo ">>     Failed to checkout ${SRCNAME}."
      rm -rf ${CHECKOUT}
      continue
    fi

    pushd ${CHECKOUT} >/dev/null
      git checkout ${VERSION}
      if [ $? -ne 0 ]; then
        echo ">>     Failed to checkout tag ${VERSION} for ${SRCNAME}."
        popd >/dev/null
        rm -rf ${CHECKOUT}
        continue
      fi
    popd >/dev/null

    echo ">>     Removing git metadata..."
    find ${CHECKOUT} -name ".git*" -depth -exec rm -rf {} \;

    echo ">>     Creating ${TARBALL}..."
    ( cd ${SRCLOC} ; tar -zcf ${TARBALL} ${SRCNAME}-${VERSION} )

    if [ "$CLEANUP" = "YES" ]; then
      rm -rf ${CHECKOUT}
    fi
  done
done

cd $CWD
# Done!
