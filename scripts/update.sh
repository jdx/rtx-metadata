#!/usr/bin/env bash
# shellcheck disable=SC1091
source env_parallel.bash
set -euxo pipefail

export RTX_NODE_MIRROR_URL="https://nodejs.org/dist/"

fetch() {
  docker run jdxcode/rtx -y ls-remote "$1" > "versions/$1" || true
}

docker run jdxcode/rtx plugins --all | env_parallel --env fetch fetch {}

git config --local user.email "123107610+rtx-vm@users.noreply.github.com"
git config --local user.name "rtx"
git add versions
if [ "$DRY_RUN" == 0 ] && ! git diff-index --quiet HEAD; then
  git commit -m "Update release metadata"
  git push
fi
