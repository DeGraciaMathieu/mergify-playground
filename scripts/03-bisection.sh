#!/usr/bin/env bash
# Scénario 3 — bissection et CI en deux étapes.
# 5 PR, dont une piège : elle change le seuil de livraison gratuite.
# Les tests unitaires ne le voient pas (la PR entre dans la file),
# seuls les tests d'intégration, joués dans la file, le détectent.
# Le batch casse, Mergify le découpe, éjecte la PR piège et merge les autres.
#
# Usage : ./scripts/03-bisection.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

preflight

prs=()
for i in 1 2 3 4 5; do
    new_branch "demo/$STAMP-bisect-$i"
    if [[ "$i" == 3 ]]; then
        perl -pi -e 's/FREE_SHIPPING_THRESHOLD = 5000;/FREE_SHIPPING_THRESHOLD = 50000;/' src/Shipping.php
        title="Ajuste le seuil de livraison gratuite"
    else
        changelog_entry "Retouche n°$i"
        title="Retouche n°$i"
    fi
    prs+=("$(commit_and_open_pr "$title")")
done
trap_pr="${prs[2]}"
say "PR ouvertes : ${prs[*]} (la PR piège est #$trap_pr)"

say "Attente des tests rapides : toutes passent, y compris la piège"
for pr in "${prs[@]}"; do wait_for_check "$pr" preliminary-tests; done

say "Mise en file"
for pr in "${prs[@]}"; do queue "$pr"; done

note "Attendu : le premier batch (#${prs[0]}, #${prs[1]}, #$trap_pr) casse sur pre-merge-tests,"
note "Mergify passe en « bisecting », éjecte #$trap_pr avec un commentaire, et merge les 4 autres."
