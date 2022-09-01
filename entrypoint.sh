#!/bin/sh -l

git_cmd() {
  echo $@
  if [[ "${DRY_RUN:-false}" == "false" ]]; then
    eval $@
  fi
}

git_setup() {
  cat <<- EOF > $HOME/.netrc
		machine github.com
		login $GITHUB_ACTOR
		password $GITHUB_TOKEN
		machine api.github.com
		login $GITHUB_ACTOR
		password $GITHUB_TOKEN
EOF
  chmod 600 $HOME/.netrc

  git_cmd git config --global user.email "$GITBOT_EMAIL"
  git_cmd git config --global user.name "$GITHUB_ACTOR"
  git_cmd git config --global --add safe.directory /github/workspace
}

PR_BRANCH="auto-$INPUT_PR_BRANCH-$GITHUB_SHA"
MESSAGE=$(git log -1 $GITHUB_SHA | grep "AUTO" | wc -l)

if [[ $MESSAGE -gt 0 ]]; then
  echo "Autocommit, NO ACTION"
  exit 0
fi

PR_TITLE=$(git log -1 --format="%s" $GITHUB_SHA)

git_setup
git_cmd git remote update
git_cmd git fetch --all
git_cmd git checkout -b "${PR_BRANCH}" origin/"${INPUT_PR_BRANCH}"
git_cmd git cherry-pick "${GITHUB_SHA}"
git_cmd git push -u origin "${PR_BRANCH}"
git_cmd hub pull-request -b "${INPUT_PR_BRANCH}" -h "${PR_BRANCH}" -l "${INPUT_PR_LABELS}" -a "${GITHUB_ACTOR}" -m "\"AUTO: ${PR_TITLE}\""
