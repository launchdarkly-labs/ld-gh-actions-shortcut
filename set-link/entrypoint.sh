#!/usr/bin/env bash

set -euxo pipefail

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
user="$(jq -r .pull_request.user.login "$GITHUB_EVENT_PATH")"

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

story="${stories[0]}"
if [[ -z "$story" ]]; then
  echo "Could not find Shortcut story"
else
  echo "Found Shortcut story number '${story}'"
fi

# If we have an autolink prefix to use, we use that instead of a link
# See https://help.github.com/en/github/administering-a-repository/configuring-autolinks-to-reference-external-resources
if [[ -n "$AUTOLINK_PREFIX" ]]; then
  link_url="$AUTOLINK_PREFIX$story"
else
  link_url="$STORY_BASE_URL/$story"
fi

if [[ -n "$story" ]]; then
  new_body=${body/$STORY_LINK_TEXT/$link_url} # replace the story link text
fi

# If we still don't have the url in the body, tack it on the beginning
if [[ "$new_body" != *"$link_url"* && -n "$story" ]]; then
  new_body="$link_url\n$new_body"
fi

new_title="${title}"

formatted_title="$(cut <<<"${new_title}" -d "/" -f3)"

echo "Formatted title is '${formatted_title}'"
if [[ "$formatted_title" != " " && "$formatted_title" != "" ]]; then
  new_title="${formatted_title}"
fi

# Remove the story from anywhere in the name, removes [123456], [sc-123456], [sc 123456], [SC-123456]
story_removed_title=${new_title/"[sc-$story]"/""}
story_removed_title=${story_removed_title/"[sc $story]"/""}
story_removed_title=${story_removed_title/"[$story]"/""}
story_removed_title=${story_removed_title/"[SC-$story]"/""}
before_story_removed="${new_title}"

echo "New title with removed ticket is '${new_title}'"

# Add the story number to the PR title if it isn't already there
if [[ "$story_removed_title" != *"[sc-$story]"* ]]; then
  new_title="[sc-${story}] ${story_removed_title^}"
fi

echo "Final new title is '${new_title}'"

SKIP_COMMENT="0"
"$OK" -j list_issue_comments "$GITHUB_REPOSITORY" "$number" | jq -e '. | map(select(.user?.login? == "shortcut-integration[bot]")) | .[0]' >/dev/null || SKIP_COMMENT="$?"

if [[ "$story" != "" ]] && { [[ "$body" != "$new_body" || "$title" != "$new_title" ]]; }; then
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

    if [[ "${story_removed_title}" != "${before_story_removed}" ]]; then
      echo "$OK" add_comment "$GITHUB_REPOSITORY" "$number" "Ahem, @${user}.  I know it's fun to add the shortcut ticket number to the PR name manually, but I'm here to help (also, it's one of the only reasons I exist).  It's less fun for me if you do it :("
    fi
  fi
fi

# If we have no story add a comment to create one
draft=$(jq -r .pull_request.draft "$GITHUB_EVENT_PATH")
if [[ "$SKIP_COMMENT" == "0" ]] && { [[ "$action" = "opened" || "$action" = "reopened" ]]; } && [[ -z "$story" && "$draft" != "true" && -n "$CREATE_STORY_URL" ]]; then
  echo "$OK" add_comment "$GITHUB_REPOSITORY" "$number" \
    "We could not find a Shortcut story in this PR.  Please find or [create a story]($CREATE_STORY_URL) and add it to the PR title or description."
fi
