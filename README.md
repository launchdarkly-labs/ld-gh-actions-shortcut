# Clubhouse Ticket Link Action

It adds a link to the ticket for the PR and adds the CH to the title.  Add this to a `.yml` file in `.github/workflows/` to enable as follows:

```
on: pull_request
name: Pull request
jobs:
  setClubhouseLinkInPR:
    name: Set Clubhouse Link in PR
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: Set Clubhouse Link in PR
      uses: launchdarkly/ld-gh-actions-clubhouse/set-ch-link@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        STORY_BASE_URL: https://app.clubhouse.io/launchdarkly/story
        STORY_LINK_TEXT: <!-- Story link goes here -->
        CREATE_TICKET_URL: https://app.clubhouse.io/launchdarkly/stories/new?template_id=<xxxxxx-xxxx-xxxx-xxxxxxxxxxx>
```
