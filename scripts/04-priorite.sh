#!/usr/bin/env bash
# Scénario 4 — le hotfix qui passe devant.
# 4 PR normales en file, puis une PR avec le label « urgent ».
# La priority_rule « hotfix » (allow_checks_interruption: true) la fait passer en tête.
#
# Usage : ./scripts/04-priorite.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

preflight

prs=()
for i in 1 2 3 4; do
    new_branch "demo/$STAMP-normale-$i"
    changelog_entry "Fonctionnalité n°$i"
    prs+=("$(commit_and_open_pr "Fonctionnalité n°$i")")
done

new_branch "demo/$STAMP-hotfix"
changelog_entry "Correctif urgent"
hotfix="$(commit_and_open_pr "Correctif urgent" urgent)"
say "PR normales : ${prs[*]} — hotfix : #$hotfix"

say "Attente des tests rapides"
for pr in "${prs[@]}" "$hotfix"; do wait_for_check "$pr" preliminary-tests; done

say "Mise en file des PR normales"
for pr in "${prs[@]}"; do queue "$pr"; done

note "On laisse la file démarrer ses checks…"
sleep "${HOTFIX_DELAY:-90}"

say "Mise en file du hotfix"
queue "$hotfix"
note "Attendu : les checks en cours sont interrompus, #$hotfix est testé et mergé en premier."
