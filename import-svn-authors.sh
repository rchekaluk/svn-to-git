#!/usr/bin/bash

# Source the configuration file
source config.sh

# Use explicit SVN credentials if provided
SVN_USERNAME="$1"
SVN_PASSWORD="$2"

if [ -n "$SVN_USERNAME" ]; then
    svn_username_switch="--username $SVN_USERNAME"
fi

if [ -n "$SVN_PASSWORD" ]; then
    svn_password_switch="--password $SVN_PASSWORD"
fi

if [ -n "$SVN_USERNAME" -a -n "$SVN_PASSWORD" ]; then
    noninteractive_switch="--non-interactive"
fi

svn log $SVN_HOST --quiet $svn_username_switch $svn_password_switch $noninteractive_switch | 
grep -E "r[0-9]+ \| .+ \|" | 
cut -d'|' -f2 | 
sed 's/ //g' | 
sort | 
uniq > $AUTHORS_FILE

# Function to format an author
format_author() {
    local username="$1"
    echo "$username = $username <${username}@${AUTHORS_EMAIL_DOMAIN}>"
}

# Check if the input file exists
if [ ! -f "$AUTHORS_FILE" ]; then
    echo "Error: File $AUTHORS_FILE not found."
    exit 1
fi

# Format authors and update the file in place
while IFS= read -r username; do
    formatted_author=$(format_author "$username")
    # Use sed to find and replace the original line with the formatted line
    sed -i "s/^$username.*/$formatted_author/" "$AUTHORS_FILE"
done < "$AUTHORS_FILE"

echo "Formatting completed. $AUTHORS_FILE updated with formatted authors."

echo Authors have been imported successfully into the $AUTHORS_FILE. Update them as required and run import-svn-repo.sh script
