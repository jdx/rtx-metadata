#!/usr/bin/env bash
# shellcheck disable=SC1091
source env_parallel.bash
set -euxo pipefail

export RTX_NODE_MIRROR_URL="https://nodejs.org/dist/"

fetch() {
  lines=$(wc -l < "versions/$1")
  docker run jdxcode/rtx -y ls-remote "$1" > "versions/$1" || true
  new_lines=$(wc -l < "versions/$1")
  if [ "$lines" == "$new_lines" ]; then
    echo "No new versions for $1"
  elif [ ! "$new_lines" -gt 1 ]; then
    echo "No versions for $1"
  else
    echo "New versions for $1"
    git add "versions/$1"
  fi
}

docker run jdxcode/rtx plugins --all | env_parallel -j4 --env fetch fetch {}

git config --local user.email "123107610+rtx-vm@users.noreply.github.com"
git config --local user.name "rtx"
if [ "$DRY_RUN" == 0 ] && ! git diff-index --quiet HEAD; then
  git commit -m "Update release metadata"
  git push
fi
