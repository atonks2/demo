#!/bin/sh

[ $# -eq 0 ] && { echo "Usage: $0 version_tag"; exit 1; }

# releases should be created from main branch
if [ "$(git branch --show-current)" != "main" ]
then
    echo "switching to branch 'main'"
    git checkout main > /dev/null 2>&1
fi
echo "after get current branch"
status=$(git status --porcelain)

# only 2 files should be changed
if [ "$(echo "$status" | wc -l)" -ne 2 ]
then
  echo "Only version.go and CHANGELOG.md should be updated!"
  if [ -n "$status" ]
  then
    printf "Pending changes:\n%s\n" "$status"
  fi
  exit
elif ! echo "$status" | grep -q "CHANGELOG.md" && ! echo "$status" | grep -q "version.go"
then
    echo "version.go and changelog.md must be updated to proceed"
    exit
fi
echo "checked files changed"
# make sure this is a new tag
if ! git rev-parse $1 | grep -q 'unknown revision or path'; then
   echo "$1 already exists!"
   exit
fi
echo "checked existing tag"

firstLine=$(head -n 1 CHANGELOG.md)
expectedHeader=$(printf "## $1 (Released %s)" "$(date +"%Y-%m-%d")")
if [ "$firstLine" != "$expectedHeader" ]
then
  echo "Did you update the CHANGELOG's header? Expected \"$expectedHeader\", found \"$firstLine\""
  exit
fi
echo "checked changelog header"
# see https://github.com/moovfinancial/engineering-guide#open-source-releases
git add CHANGELOG.md version.go
git commit -m "release $1"
git tag "$1"
git push origin main
git push origin "$1"
