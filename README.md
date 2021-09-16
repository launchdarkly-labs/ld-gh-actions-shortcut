# Shortcut Ticket Link Action

It adds a link to the ticket for the PR and adds the CH to the title.

Options:

  * `AUTOLINK_PREFIX` - Set this instead of STORY_BASE_URL if you just want to rely on github's prefix-based autolinking feature to create links
  * `COMMENT_ONLY` - Set this to "1" just add a comment with a Shortcut link and only do it when a PR is first opened.  This avoids conflicts that
    could cause you to lose manually PR description changes made while the github action is running.
  * `SKIP_LINK` - Set this to "1" to avoid adding a link either in a comment or in the body.

Add this to a `.yml` file in `.github/workflows/` to enable as follows:

``` yaml
on: pull_request
name: Pull request
jobs:
  setClubhouseLinkInPR:
    name: Set Clubhouse Link in PR
    runs-on: ubuntu-latest
    steps:
    - name: Set Clubhouse Link in PR
      uses: launchdarkly/ld-gh-actions-clubhouse/set-ch-link@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        STORY_BASE_URL: https://app.shortcut.com/launchdarkly/story
        STORY_LINK_TEXT: <!-- Story link goes here -->
        AUTOLINK_PREFIX: "SC-"
        CREATE_TICKET_URL: https://app.shortcut.com/launchdarkly/stories/new?template_id=<xxxxxx-xxxx-xxxx-xxxxxxxxxxx>
```

If your repository is mirrored (i.e. public/private) and you only want the action to run on one of the repositories, include an [`if` conditional](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions#jobsjob_idif) at the job level:

``` yaml
on: pull_request
name: Pull request
jobs:
  setClubhouseLinkInPR:
    if: github.repository == 'org-name/mirrored-repo-private'
    name: Set Shortcut Link in PR
    runs-on: ubuntu-latest
    steps:
    - name: Set Shortcut Link in PR
      uses: launchdarkly/ld-gh-actions-clubhouse/set-ch-link@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        STORY_BASE_URL: https://app.shortcut.com/launchdarkly/story
        STORY_LINK_TEXT: <!-- Story link goes here -->
        AUTOLINK_PREFIX: "SC-"
        CREATE_TICKET_URL: https://app.shortcut.com/launchdarkly/stories/new?template_id=<xxxxxx-xxxx-xxxx-xxxxxxxxxxx>
```
