#!/usr/bin/env bash
set -euo pipefail

# Scheduled discovery must not rebuild an existing release. Draft releases
# also count: a failed publication needs an explicit operator retry.
# Manual runs remain available for retries and patch releases.
event_name="${1:?event name required}"
repository="${2:?owner/repository required}"
tag="${3:?release tag required}"

if [[ "$event_name" != "schedule" ]]; then
  echo 'build_required=true'
  exit 0
fi

# GraphQL variables must remain literal; gh supplies their values separately.
# shellcheck disable=SC2016
response="$(gh api graphql \
  -f query='query($owner:String!,$name:String!,$tag:String!){repository(owner:$owner,name:$name){release(tagName:$tag){url isDraft}}}' \
  -f owner="${repository%%/*}" -f name="${repository#*/}" -f tag="$tag")"
# Fail closed on API errors or an inaccessible repository. Only a successful
# query returning release:null means that this quarter has not been built.
release_url="$(jq -er '
  if (.errors | length) > 0 or .data.repository == null or
     (.data.repository | has("release") | not) then
    error("Cannot determine whether the quarterly release exists")
  elif .data.repository.release == null then ""
  else .data.repository.release.url | select(type == "string" and length > 0)
  end' <<< "$response")"

if [[ -n "$release_url" ]]; then
  echo "::notice::Skipping scheduled build: release already exists at $release_url" >&2
  echo 'build_required=false'
else
  echo 'build_required=true'
fi
