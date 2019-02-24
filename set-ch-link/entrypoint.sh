#!/usr/bin/env bash

OK=ok.sh

event=$(cat "$GITHUB_EVENT_PATH")
number=$(jq -r .number "$GITHUB_EVENT_PATH")
action=$(jq -r .action "$GITHUB_EVENT_PATH")
body=$(jq -r .pull_request.body "$GITHUB_EVENT_PATH")
body=${body//$'\r'/} # Remove /r, which confuses jq in ok.sh
title=$(jq -r .pull_request.title "$GITHUB_EVENT_PATH")
title=${title//$'\r'/} # Remove /r, which confuses jq in ok.sh

ticket=$(expr "$GITHUB_REF" : '.*ch\([[:digit:]]*\).*')
link_url="$STORY_LINK_URL/$ticket"

new_body=${body/$STORY_LINK_TEXT/$link_url}

new_title="$title"
if [[ ! "$new_title" =~ "$ticket" ]]; then
    new_title="[ch${ticket}] $title"
fi

cat > ~/.netrc <<-EOF
machine api.github.com
    login $GITHUB_ACTOR
    password $GITHUB_TOKEN
EOF

if [[ "$ticket" != "" ]] && ([[ "$body" != "$new_body" ]] || [[ "$title" != "$new_title" ]]); then
    "$OK" update_pull_request "$GITHUB_REPOSITORY" "$number" "body='$new_body'" "title='$new_title'"
fi
