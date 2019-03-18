#!/usr/bin/env bash

OK=ok.sh

event=$(cat "$GITHUB_EVENT_PATH")
number=$(jq -r .number "$GITHUB_EVENT_PATH")
action=$(jq -r .action "$GITHUB_EVENT_PATH")
body=$(jq -r .pull_request.body "$GITHUB_EVENT_PATH")
body=${body//$'\r'/} # Remove /r, which confuses jq in ok.sh
title=$(jq -r .pull_request.title "$GITHUB_EVENT_PATH")
title=${title//$'\r'/} # Remove /r, which confuses jq in ok.sh

ticket_from_title=$(expr "$title" : '.*ch\([[:digit:]]*\).*')
ticket_from_branch=$(expr "$GITHUB_REF" : '.*ch\([[:digit:]]*\).*')

# Check title first for the CH ticket
ticket="$ticket_from_title"
if [[ -n "$ticket" ]]; then
    ticket="$ticket_from_branch" # fall back to the CH ticket # from the branch
fi

link_url="$STORY_BASE_URL/$ticket"

new_body=${body/$STORY_LINK_TEXT/$link_url}

# If we still don't have the url in the body, tack it on the beginning
if [[ "$new_body" != *"$link_url"* ]]; then
    new_body="$link_url\n$new_body"
fi

# Strip out branch name from the PR title
new_title="${title/$GITHUB_REF/}"

# Strip out uppercase branch name
new_title="${new_title/${GITHUB_REF^}/}"

# Add the clubhouse number to the PR title if it isn't already there
if [[ "$new_title" != *"$ticket"* ]]; then
    new_title="[ch${ticket}] $new_title"
fi

cat > ~/.netrc <<-EOF
machine api.github.com
    login $GITHUB_ACTOR
    password $GITHUB_TOKEN
EOF

if [[ "$ticket" != "" ]] && ([[ "$body" != "$new_body" ]] || [[ "$title" != "$new_title" ]]); then
    "$OK" update_pull_request "$GITHUB_REPOSITORY" "$number" "body='$new_body'" "title='$new_title'"
fi
