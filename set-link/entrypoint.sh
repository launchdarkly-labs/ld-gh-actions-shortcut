#!/usr/bin/env bash

OK=ok.sh

echo "Received event:"
cat "$GITHUB_EVENT_PATH"
echo

number=$(jq -r .number "$GITHUB_EVENT_PATH")
action=$(jq -r .action "$GITHUB_EVENT_PATH")
if  [[ "$action" != "edited" ]] && [[ "$action" != "opened" ]] && [[ "$action" != "reopened" ]]; then
    exit 0
fi

body=$(jq -r .pull_request.body "$GITHUB_EVENT_PATH")
body=${body//$'\r'/} # Remove /r, which confuses jq in ok.sh
title=$(jq -r .pull_request.title "$GITHUB_EVENT_PATH")
title=${title//$'\r'/} # Remove /r, which confuses jq in ok.sh
branch=$(jq -r .pull_request.head.ref "$GITHUB_EVENT_PATH")

echo "Current PR title is '${title}'"
echo "Github branch is '$branch'"

pattern='.*\b\{sc,sc-,ch,ch-\}->\([[:digit:]]\+\)\b.*'
story_from_title=$(expr "$title" : "$pattern")
story_from_branch=$(expr "$branch" : "$pattern")

link_pattern='.*\story/\([[:digit:]]\+\)\b.*'
story_from_body=$(expr "$body" : "$pattern")
story_from_body_link=$(expr "$body" : "$link_pattern")

if [[ -n "$AUTOLINK_PREFIX" ]]; then
  autolink_pattern="${AUTOLINK_PREFIX}\([[:digit:]]\+\)\b.*"
  story_from_autolink=$(expr "$body" : "$autolink_pattern")
fi

# Check title first for the CH story
# shellcheck disable=SC2206
stories=($story_from_title $story_from_branch $story_from_body $story_from_autolink $story_from_body_link)
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
if [[ "$new_body" != *"$link_url"* ]] && [[ -n "$story" ]] ; then
    new_body="$link_url\n$new_body"
fi

branch_with_spaces_for_dashes="${branch//[_-]/ }"

# Strip out branch name from the PR title
new_title="${title/$branch/}"
new_title="${title/$branch_with_spaces_for_dashes/}"

# Strip out uppercase branch name
new_title="${new_title/${branch^}/}"
new_title="${new_title/${branch_with_spaces_for_dashes^}/}"

# Add the story number to the PR title if it isn't already there
if [[ "$new_title" != *"$story"* ]]; then
    new_title="[sc${story}] $new_title"
fi

cat > ~/.netrc <<-EOF
machine api.github.com
    login $GITHUB_ACTOR
    password $GITHUB_TOKEN
EOF

if [[ "$story" != "" && ( "$body" != "$new_body" || "$title" != "$new_title" ) ]]; then
    args=("title='$new_title'")
    if [[ "$COMMENT_ONLY" != "1" && "$SKIP_LINK" != "1" ]]; then
        args+=("body='$new_body'")
    fi
    "$OK" update_pull_request "$GITHUB_REPOSITORY" "$number" "${args[@]}"
    if [[ "$COMMENT_ONLY" == "1" && "$SKIP_LINK" != "1" && "$action" == "opened" ]]; then
        "$OK" add_comment "$GITHUB_REPOSITORY" "$number" "Shortcut link is $link_url."
    fi
fi

# If we have no story add a comment to create one
draft=$(jq -r .pull_request.draft "$GITHUB_EVENT_PATH")
if { [[ "$action" = "opened" ]] || [[ "$action" = "reopened" ]]; } && [[ -z "$story" ]] && [[ "$draft" != "true" ]] && [[ -n "$CREATE_STORY_URL" ]]; then
    "$OK" add_comment "$GITHUB_REPOSITORY" "$number" \
        "We could not find a Shortcut story in this PR.  Please find or [create a story]($CREATE_STORY_URL) and add it to the PR title or description."
fi
