#!/usr/bin/env bash
# Scénario 2 — le batching.
# N PR inoffensives mises en file d'un coup. Avec batch_size: 3, Mergify ne lance
# qu'un run de tests lents par paquet de 3, au lieu d'un par PR.
#
# Usage : ./scripts/02-batch.sh [nombre de PR, défaut 6]
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

count="${1:-6}"
preflight

prs=()
for i in $(seq 1 "$count"); do
    new_branch "demo/$STAMP-batch-$i"
    changelog_entry "Petite amélioration n°$i"
    prs+=("$(commit_and_open_pr "Petite amélioration n°$i")")
done
say "PR ouvertes : ${prs[*]}"

say "Attente des tests rapides"
for pr in "${prs[@]}"; do wait_for_check "$pr" preliminary-tests; done

say "Mise en file de toutes les PR"
for pr in "${prs[@]}"; do queue "$pr"; done

batches=$(( (count + 2) / 3 ))
note "Attendu : $batches draft PR de batch (3 PR chacune), deux testées en parallèle."
note "Soit $batches runs de tests lents au lieu de $count."
note "$(repo_url)/pulls?q=is%3Adraft"
