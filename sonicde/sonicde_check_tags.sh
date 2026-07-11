#!/bin/sh
# Compare source-versions with public Sonic-DE git tags.

set -eu

TOPDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE_VERSIONS=${1:-"$TOPDIR/source-versions"}

if [ ! -r "$SOURCE_VERSIONS" ]; then
  printf '%s\n' "Error: cannot read $SOURCE_VERSIONS" >&2
  exit 1
fi

if [ -t 1 ]; then
  C_RESET='\033[0m'
  C_GREEN='\033[32m'
  C_YELLOW='\033[33m'
  C_RED='\033[31m'
else
  C_RESET=''
  C_GREEN=''
  C_YELLOW=''
  C_RED=''
fi

compare_versions() {
  awk -v A="$1" -v B="$2" 'BEGIN {
    na = split(A, a, ".")
    nb = split(B, b, ".")
    max = (na > nb ? na : nb)
    for (i = 1; i <= max; i++) {
      va = (i <= na ? a[i] + 0 : 0)
      vb = (i <= nb ? b[i] + 0 : 0)
      if (va < vb) {
        print -1
        exit
      }
      if (va > vb) {
        print 1
        exit
      }
    }
    print 0
  }'
}

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

printf '%-34s %-12s %-12s %-8s %s\n' "package" "local" "latest" "status" "notes"

print_row() {
  color=''
  case "$4" in
    OK) color=$C_GREEN ;;
    UPDATE|NO_TAGS) color=$C_YELLOW ;;
    ERROR) color=$C_RED ;;
  esac
  printf '%-34s %-12s %-12s %b%-8s%b %s\n' "$1" "$2" "$3" "$color" "$4" "$C_RESET" "$5"
}

while IFS=' ' read -r src version rest; do
  case "$src" in
    ''|'#'*) continue ;;
  esac

  repo_url="https://github.com/Sonic-DE/$src.git"
  tag_file="$tmpdir/$src.tags"
  parsed_file="$tmpdir/$src.parsed"

  if ! git ls-remote --tags "$repo_url" > "$tag_file" 2>/dev/null; then
    print_row "$src" "$version" "-" "ERROR" "repo/tag query failed"
    continue
  fi

  awk '
    {
      ref = $2
      sub(/^refs\/tags\//, "", ref)
      sub(/\^\{\}$/, "", ref)
      if (seen[ref]++)
        next
      if (ref ~ /^v?[0-9]+(\.[0-9]+)*$/) {
        norm = ref
        sub(/^v/, "", norm)
        print "V|" ref "|" norm
      } else {
        print "S|" ref
      }
    }
  ' "$tag_file" > "$parsed_file"

  latest_raw=''
  latest_norm=''
  exact_match='no'
  vprefix_match='no'
  special_tags=''

  while IFS='|' read -r kind raw norm; do
    case "$kind" in
      V)
        if [ "$raw" = "$version" ]; then
          exact_match='yes'
        fi
        if [ "$raw" = "v$version" ]; then
          vprefix_match='yes'
        fi
        if [ -z "$latest_norm" ]; then
          latest_raw=$raw
          latest_norm=$norm
        else
          cmp=$(compare_versions "$norm" "$latest_norm")
          if [ "$cmp" -gt 0 ]; then
            latest_raw=$raw
            latest_norm=$norm
          fi
        fi
        ;;
      S)
        if [ -z "$special_tags" ]; then
          special_tags=$raw
        else
          special_tags="$special_tags,$raw"
        fi
        ;;
    esac
  done < "$parsed_file"

  if [ -z "$latest_norm" ]; then
    status='NO_TAGS'
    latest_display='-'
  else
    latest_display=$latest_raw
    cmp=$(compare_versions "$version" "$latest_norm")
    if [ "$cmp" -lt 0 ]; then
      status='UPDATE'
    else
      status='OK'
    fi
  fi

  notes=''
  if [ "$exact_match" = 'yes' ]; then
    notes='exact'
  elif [ "$vprefix_match" = 'yes' ]; then
    notes='v-prefix'
  elif [ -n "$latest_norm" ]; then
    notes='missing-exact'
  fi

  if [ -n "$special_tags" ]; then
    if [ -n "$notes" ]; then
      notes="$notes; special=$special_tags"
    else
      notes="special=$special_tags"
    fi
  fi

  print_row "$src" "$version" "$latest_display" "$status" "$notes"
done < "$SOURCE_VERSIONS"
