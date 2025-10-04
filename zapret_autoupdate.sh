#!/bin/sh

# Script: /opt/zapret/zapret_autoupdate.sh
# Purpose: Auto-pull git updates for zapret and run autosetup.sh if changes detected

git stash
git checkout main 
git pull
/opt/zapret/zapret_autoupdate.sh
