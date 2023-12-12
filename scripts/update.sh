#!/usr/bin/env bash
# shellcheck disable=SC1091
source env_parallel.bash
set -euxo pipefail

export RTX_NODE_MIRROR_URL="https://nodejs.org/dist/"
export RTX_USE_VERSIONS_HOST="0"

fetch() {
  case "$1" in
    awscli-local) # TODO: remove this when it is working
      echo "Skipping $1"
      return
      ;;
    jfrog-cli|minio|tiny|teleport-ent|flyctl|vim|awscli|checkov|snyk)
      echo "Skipping $1"
      return
      ;;
  esac
  lines=$(wc -l < "docs/$1")
  if ! docker run -e GITHUB_API_TOKEN -e RTX_USE_VERSIONS_HOST \
      jdxcode/rtx -y ls-remote "$1" > "docs/$1"; then
    echo "Failed to fetch versions for $1"
    return
  fi
  new_lines=$(wc -l < "docs/$1")
  if [ "$lines" == "$new_lines" ]; then
    echo "No new versions for $1" >/dev/null
  elif [ ! "$new_lines" -gt 1 ]; then
    echo "No versions for $1" >/dev/null
  else
    case "$1" in
      rust)
        if [ "$new_lines" -gt 10 ]; then
          git add "docs/$1"
        fi
        ;;
      java)
        sort -V "docs/$1" -o "docs/$1"
        git add "docs/$1"
        ;;
      vault|consul|nomad|terraform|packer|vagrant)
        sort -V "docs/$1" -o "docs/$1"
        git add "docs/$1"
        ;;
      *)
        git add "docs/$1"
        ;;
    esac
    echo "New versions for $1"
  fi
}

docker run jdxcode/rtx plugins --all | env_parallel -j4 --env fetch fetch {}

if [ "$DRY_RUN" == 0 ] && ! git diff-index --cached --quiet HEAD; then
  git diff --compact-summary --cached
  git config --local user.email "123107610+rtx-vm@users.noreply.github.com"
  git config --local user.name "rtx"
  git commit -m "Update release metadata"
  git push
fi
