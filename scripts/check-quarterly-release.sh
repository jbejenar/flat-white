#!/usr/bin/env bash
set -euo pipefail

# Scheduled discovery must not rebuild an existing release. Draft releases
# also count: a held draft needs review. Manual builds must use an unused tag.
event_name="${1:?event name required}"
repository="${2:?owner/repository required}"
tag="${3:?release tag required}"
target_sha="${4:-}"

# GraphQL variables must remain literal; gh supplies their values separately.
# shellcheck disable=SC2016
response="$(gh api graphql \
  -f query='query($owner:String!,$name:String!,$tag:String!,$ref:String!){repository(owner:$owner,name:$name){release(tagName:$tag){url isDraft} ref(qualifiedName:$ref){target{__typename oid ... on Tag{target{__typename oid}}}}}}' \
  -f owner="${repository%%/*}" -f name="${repository#*/}" -f tag="$tag" -f ref="refs/tags/$tag")"
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
  if [[ "$event_name" == "schedule" ]]; then
    echo "::notice::Skipping scheduled build: release already exists at $release_url" >&2
    echo 'build_required=false'
    exit 0
  fi
  echo "::error::Release already exists at $release_url. Review the existing release or choose an unused patch version; it will not be overwritten." >&2
  exit 1
fi

if [[ -n "$target_sha" ]]; then
  tag_commit="$(jq -er '
    .data.repository |
    if (has("ref") | not) then error("Cannot check the release tag")
    elif .ref == null then ""
    elif .ref.target.__typename == "Commit" then .ref.target.oid
    elif .ref.target.__typename == "Tag" and .ref.target.target.__typename == "Commit"
      then .ref.target.target.oid
    else error("Release tag does not resolve to a commit") end |
    select(type == "string")' <<< "$response")"
  if [[ -n "$tag_commit" && "$tag_commit" != "$target_sha" ]]; then
    echo "::error::Tag $tag points to $tag_commit, not the built commit $target_sha. Choose an unused version." >&2
    exit 1
  fi
fi
echo 'build_required=true'
