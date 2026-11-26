#!/usr/bin/env bash
# Crée le repo GitHub à partir de ce dossier et pousse main.
# Usage : ./scripts/00-init.sh <nom-du-repo> [--public|--private]
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

name="${1:?Usage : ./scripts/00-init.sh <nom-du-repo> [--public|--private]}"
visibility="${2:---public}"

gh auth status >/dev/null 2>&1 || { echo "Lance d'abord : gh auth login"; exit 1; }

if [[ ! -d .git ]]; then
    git init --quiet -b main
fi
git add -A
git commit --quiet -m "Projet de démo Mergify" 2>/dev/null || true

gh repo create "$name" "$visibility" --source . --remote origin --push
gh label create urgent --color D93F0B --description "Passe devant dans la merge queue" --force >/dev/null

url="$(gh repo view --json url -q .url)"
cat <<EOF

✅ Repo créé : $url

Étape suivante, à faire à la main :
  1. Installe l'app Mergify sur ce repo : https://github.com/apps/mergify
  2. Vérifie qu'il n'y a pas de règle « Require branches to be up to date » sur main
     (ça bloque les merges de batch).
  3. Lance un scénario, par exemple : ./scripts/01-conflit-semantique.sh --sans-queue
EOF
