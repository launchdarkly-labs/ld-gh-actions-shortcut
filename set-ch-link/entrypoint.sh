#!/usr/bin/env bash

OK=ok.sh

number=$(jq -r .number "$GITHUB_EVENT_PATH")
action=$(jq -r .action "$GITHUB_EVENT_PATH")
if  [[ "$action" != "edited" ]] && [[ "$action" != "opened" ]]; then
    exit 0
fi

body=$(jq -r .pull_request.body "$GITHUB_EVENT_PATH")
body=${body//$'\r'/} # Remove /r, which confuses jq in ok.sh
title=$(jq -r .pull_request.title "$GITHUB_EVENT_PATH")
title=${title//$'\r'/} # Remove /r, which confuses jq in ok.sh
branch=$(jq -r .pull_request.head.ref "$GITHUB_EVENT_PATH")

echo "Current PR title is '${title}'"
echo "Github ref is '$branch'"

pattern='.*\bch\([[:digit:]]\+\)\b.*'
story_from_title=$(expr "$title" : "$pattern")
story=$(expr "$branch" : "$pattern")

# Check title first for the CH story
story="$story_from_title"
if [[ -z "$story" ]]; then
    story="$story" # fall back to the CH story # from the branch
    echo "Found CH story number '${story}' in branch name"
else
    echo "Found CH story number '${story}' in PR title"
fi

link_url="$STORY_BASE_URL/$story"

if [[ -n "$story" ]]; then
    new_body=${body/$STORY_LINK_TEXT/$link_url} # replace the story link text
fi

# If we still don't have the url in the body, tack it on the beginning
if [[ "$new_body" != *"$link_url"* ]] && [[ -n "$story" ]] ; then
    new_body="$link_url\n$new_body"
fi

# Strip out branch name from the PR title
new_title="${title/$branch/}"

# Strip out uppercase branch name
new_title="${new_title/${branch^}/}"

# Add the clubhouse number to the PR title if it isn't already there
if [[ "$new_title" != *"$story"* ]]; then
    new_title="[ch${story}] $new_title"
fi

cat > ~/.netrc <<-EOF
machine api.github.com
    login $GITHUB_ACTOR
    password $GITHUB_TOKEN
EOF

if [[ "$story" != "" && ( "$body" != "$new_body" || "$title" != "$new_title" ) ]]; then
    "$OK" update_pull_request "$GITHUB_REPOSITORY" "$number" "body='$new_body'" "title='$new_title'"
fi

# If we have no story add a comment to create one
if [[ "$action" = "opened" ]] && [[ -z "$story" ]] && [[ -n "$CREATE_STORY_URL" ]]; then
    "$OK" add_comment "$GITHUB_REPOSITORY" "$number" \
        "We could not find a CH story in this PR.  Please find or [create a story]($CREATE_STORY_URL) and add it to the PR title or description."
fi
