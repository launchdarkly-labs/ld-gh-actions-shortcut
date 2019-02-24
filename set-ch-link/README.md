# Clubhouse Ticket Link Action

It adds a link to the ticket for the PR and adds the CH to the title.  Add this to your `.github/main.workflow` to enable:


```
workflow "Pull request" {
  on = "pull_request"
  resolves = ["Set Clubhouse Link"]
}

action "Set Clubhouse Link" {
  secrets = [ "GITHUB_TOKEN" ]
  uses = "launchdarkly/ld-gh-actions-clubhouse/set-ch-link@master"
  env = {
    STORY_LINK_TEXT="<!-- Story link goes here -->"
    STORY_BASE_URL="https://app.clubhouse.io/launchdarkly/story"
  }
}
```
