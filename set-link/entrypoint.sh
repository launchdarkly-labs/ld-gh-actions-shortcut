#!/usr/bin/env bash

set -euo pipefail

shopt -s extglob

[[ -z ${GITHUB_TOKEN:-} ]] && printf >&2 "error: GITHUB_TOKEN missing\n" && exit 1

OK=ok.sh
AUTOLINK_PREFIX="${AUTOLINK_PREFIX:-}"
STORY_BASE_URL="${STORY_BASE_URL:-}"
STORY_LINK_TEXT="${STORY_LINK_TEXT:-}"
COMMENT_ONLY="${COMMENT_ONLY:-}"
SKIP_LINK="${SKIP_LINK:-}"

echo "Received event:"
cat "$GITHUB_EVENT_PATH"
echo

number=$(jq -r .number "$GITHUB_EVENT_PATH")
action=$(jq -r .action "$GITHUB_EVENT_PATH")
if [[ "$action" != "edited" ]] && [[ "$action" != "opened" ]] && [[ "$action" != "reopened" ]]; then
  exit 0
fi

body="$(jq -r .pull_request.body "$GITHUB_EVENT_PATH")"
body=${body//$'\r'/} # Remove /r, which confuses jq in ok.sh
title="$(jq -r .pull_request.title "$GITHUB_EVENT_PATH")"
title=${title//$'\r'/} # Remove /r, which confuses jq in ok.sh
branch="$(jq -r .pull_request.head.ref "$GITHUB_EVENT_PATH")"

echo "Current PR title is '${title}'"
echo "Github branch is '$branch'"

stories=()

pattern=".*\bsc-?([[:digit:]]+)\b.*"
[[ $title =~ $pattern ]] && stories+=("${BASH_REMATCH[1]}")
[[ $branch =~ $pattern ]] && stories+=("${BASH_REMATCH[1]}")

link_pattern=".*story/([[:digit:]]+)\b.*"
[[ $body =~ $pattern ]] && stories+=("${BASH_REMATCH[1]}")
[[ $body =~ $link_pattern ]] && stories+=("${BASH_REMATCH[1]}")

if [[ -n "$AUTOLINK_PREFIX" ]]; then
  autolink_pattern="${AUTOLINK_PREFIX}([[:digit:]]+)\b.*"
  [[ $body =~ $autolink_pattern ]] && stories+=("${BASH_REMATCH[1]}")
fi

story=""
if (( ${#stories[@]} == 0 )); then
  echo "Could not find Shortcut story"
else
  story="${stories[0]}"
  echo "Found Shortcut story number '${story}'"
fi

# If we have an autolink prefix to use, we use that instead of a link
# See https://help.github.com/en/github/administering-a-repository/configuring-autolinks-to-reference-external-resources
if [[ -n "$AUTOLINK_PREFIX" ]]; then
  link_url="$AUTOLINK_PREFIX$story"
else
  link_url="$STORY_BASE_URL/$story"
fi

new_body="$body"
if [[ -n "$story" ]]; then
  new_body="${new_body/$STORY_LINK_TEXT/$link_url}" # replace the story link text

  # If we still don't have the url in the body, tack it on the beginning
  if [[ "$new_body" != *"$link_url"* ]]; then
    new_body="$link_url\n$new_body"
  fi
fi

new_title="${title}"
if [[ $title =~ ^[a-zA-Z]+/[Ss][Cc](-| )[[:digit:]]+/(.+) ]]; then
  formatted_title="${BASH_REMATCH[2]}"
  echo "Formatted title is '${formatted_title}'"
  if [[ "$formatted_title" != " " && "$formatted_title" != "" ]]; then
    new_title="$(IFS=- read -ra str <<<"${formatted_title^}"; printf ' %s' "${str[@]}")"
  fi
fi

if [[ -n $story ]]; then
  # Remove the story from anywhere in the name, removes [123456], [sc-123456], [sc 123456]
  while [[ $new_title =~ (.*)\[([Ss][Cc](-| )?)$story\](.*) ]]; do new_title=${BASH_REMATCH[1]}${BASH_REMATCH[4]}; done
  while [[ $new_title =~ (.*)([Ss][Cc](-| )?)$story(.*) ]]; do new_title=${BASH_REMATCH[1]}${BASH_REMATCH[4]}; done
  while [[ $new_title =~ (.*)\[$story\](.*) ]]; do new_title=${BASH_REMATCH[1]}${BASH_REMATCH[2]}; done
  while [[ $new_title =~ (.*)$story(.*) ]]; do new_title=${BASH_REMATCH[1]}${BASH_REMATCH[2]}; done
  new_title="${new_title//+( )/ }"
  new_title="${new_title#"${new_title%%[![:space:]]*}"}"
  new_title="${new_title%"${new_title##*[![:space:]]}"}"

  echo "New title with removed ticket is '${new_title}'"

  # Add the story number to the PR title if it isn't already there
  if [[ "$new_title" != *"[sc-$story]"* ]]; then
    new_title="[sc-${story}] ${new_title}"
  fi
fi

echo "Final new title is '${new_title}'"

SKIP_COMMENT="0"
"$OK" -j list_issue_comments "$GITHUB_REPOSITORY" "$number" | jq -e '. | map(select(.user?.login? == "shortcut-integration[bot]")) | .[0]' >/dev/null || SKIP_COMMENT="$?"

if [[ -n $story ]] && { [[ "$body" != "$new_body" || "$title" != "$new_title" ]]; }; then
  args=()
  [[ "$title" != "$new_title" ]] && args+=("title='$new_title'")
  if [[ "$body" != "$new_body" && "$COMMENT_ONLY" != "1" && "$SKIP_LINK" != "1" ]]; then
    args+=("body='$new_body'")
  fi

  if ((${#args[@]} > 0)); then
    "$OK" update_pull_request "$GITHUB_REPOSITORY" "$number" "${args[@]}"
  fi

  if [[ "$COMMENT_ONLY" == "1" && "$SKIP_LINK" != "1" && "$SKIP_COMMENT" == "0" && "$action" == "opened" ]]; then
    echo "$OK" add_comment "$GITHUB_REPOSITORY" "$number" "Shortcut link is $link_url."
  fi
fi

# If we have no story add a comment to create one
draft=$(jq -r .pull_request.draft "$GITHUB_EVENT_PATH")
if [[ "$SKIP_COMMENT" == "0" ]] && { [[ "$action" == "opened" || "$action" == "reopened" ]]; } && [[ -z "$story" && "$draft" != "true" && -n "$CREATE_STORY_URL" ]]; then
  echo "$OK" add_comment "$GITHUB_REPOSITORY" "$number" \
    "We could not find a Shortcut story in this PR.  Please find or [create a story]($CREATE_STORY_URL) and add it to the PR title or description."
fi
