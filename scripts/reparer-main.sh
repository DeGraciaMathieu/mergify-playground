#!/usr/bin/env bash
# Annule le dernier commit de main (après le scénario 1 en --sans-queue).
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

preflight
git switch --quiet main
git pull --quiet --ff-only origin main
say "Annulation de : $(git log -1 --format='%h %s')"
git revert --no-edit HEAD
git push --quiet origin main
note "main est réparé."
