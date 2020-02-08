# Clubhouse Ticket Link Action

It adds a link to the ticket for the PR and adds the CH to the title.

Options:

  * `AUTOLINK_PREFIX` - Set this instead of STORY_BASE_URL if you just want to rely on github's prefix-based autolinking feature to create links
  * `COMMENT_ONLY` - Set this to "1" just add a comment with a Clubhouse link and only do it when a PR is first opened.  This avoids conflicts that
    could cause you to lose manually PR description changes made while the github action is running.

Add this to a `.yml` file in `.github/workflows/` to enable as follows:

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
        AUTOLINK_PREFIX: "CH-"
        CREATE_TICKET_URL: https://app.clubhouse.io/launchdarkly/stories/new?template_id=<xxxxxx-xxxx-xxxx-xxxxxxxxxxx>
```
