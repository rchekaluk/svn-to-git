#!/usr/bin/bash

# Migration from SVN repo to Git with all history
# Author: Ahmed Khan <a.manzoor743@gmail.com>
# This script was created following this amazing article by Giovanni Zito
# https://www.linkedin.com/pulse/migrating-from-svn-git-8-steps-preserving-history-giovanni-zito/

set -e  # Exit immediately if any command exits with a non-zero status

# Source the configuration file
source config.sh

# Use explicit SVN credentials if provided
SVN_USERNAME="$1"
SVN_PASSWORD="$2"

if [ -n "$SVN_USERNAME" ]; then
    svn_username_switch="--username $SVN_USERNAME"
fi

# Use revision range if provided
SVN_REVISION_RANGE="$3"

if [ -n "$SVN_REVISION_RANGE" ]; then
    svn_revision_switch="--revision $SVN_REVISION_RANGE"
fi

# Function to handle errors
handle_error() {
    local exit_code=$?
    echo "Error occurred on line $1. Exiting." >&2
    exit $exit_code
}

# Trap errors and call the handle_error function
trap 'handle_error $LINENO' ERR

# Check if the required variables are set
if [[ -z "$TARGET_DIR" || -z "$SVN_HOST" || -z "$AUTHORS_FILE" ]]; then
    echo "Error: Please set all required variables in config.sh"
    exit 1
fi


# Step 2. Initializing the git repository
if [ ! -d "$TARGET_DIR" ]; then
    mkdir "$TARGET_DIR"
fi

cd $TARGET_DIR

# use this for standard layout
if [ -n "$SVN_PASSWORD" ]; then
  echo $SVN_PASSWORD | env GIT_ASKPASS= SSH_ASKPASS= git svn init "$SVN_HOST" $INIT_SWITCHES $svn_username_switch
else
  git svn init "$SVN_HOST" $INIT_SWITCHES
fi

# use this for non standard layout
# git svn init $SVN_HOST 

# import users into the git repository you just created:
# Check if AUTHORS_FILE exists, and create if necessary
if [ ! -f "$AUTHORS_FILE" ]; then
    # You may want to replace the following line with the appropriate command
    # to create AUTHORS_FILE or provide the correct path if it's predefined.
    echo "Looks like you've not imported the svn users, import them in file $AUTHORS_FILE and try again."
    exit 1
fi

git config svn.authorsfile $AUTHORS_FILE

# Step 3. Import the repo from SVNx
# https://stackoverflow.com/questions/21040553/git-svn-clone-password-pass-gives-unknown-option-password
if [ -n "$SVN_PASSWORD" ]; then
  echo $SVN_PASSWORD | env GIT_ASKPASS= SSH_ASKPASS= git svn fetch $FETCH_SWITCHES $svn_username_switch $svn_revision_switch
else
  git svn fetch $FETCH_SWITCHES $svn_username_switch $svn_revision_switch
fi

# echo These are imported branches:
# git branch -a
# [OPTIONAL]: Step 4. Conversion of tags
for t in `git branch -a | grep 'tags/' | sed s_remotes/origin/tags/__` ; do
 git tag $t origin/tags/$t
 git branch -d -r origin/tags/$t
done

# git tag -l

# [OPTIONAL]: Step 5. Converting branches
git branch -r | sed 's/origin\///' | while read -r t; do
  echo "$t"
  git branch "$t" "origin/$t"
  git branch -D -r "origin/$t"
done

# Step 6. Cleaning the SVN stuff
git config --remove-section svn-remote.svn
git config --remove-section svn
rm -fr .git/svn .git/{logs,}/refs/remotes/svn

# for t in 'git branch -r | sed s_origin/__' ; do
#   echo $t
#   git branch $t origin/$t
#   git branch -D -r origin/$t
# done
