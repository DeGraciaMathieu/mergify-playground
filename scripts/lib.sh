#!/usr/bin/env bash
# Fonctions partagées par les scénarios.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

STAMP="$(date +%H%M%S)"

say()  { printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
note() { printf '  %s\n' "$*"; }

preflight() {
    command -v gh >/dev/null || { echo "gh (GitHub CLI) est requis."; exit 1; }
    gh auth status >/dev/null 2>&1 || { echo "Lance d'abord : gh auth login"; exit 1; }
    if [[ -n "$(git status --porcelain)" ]]; then
        echo "Le working tree n'est pas propre : commit ou stash avant de lancer un scénario."
        exit 1
    fi
    git fetch --quiet origin main
}

# new_branch <nom> : crée une branche à partir du main distant.
new_branch() {
    git switch --quiet -c "$1" origin/main
}

# commit_and_open_pr <titre> [label] : commit, push et ouvre la PR. Affiche son numéro.
commit_and_open_pr() {
    local title="$1" label="${2:-}"
    local branch
    branch="$(git branch --show-current)"

    git add -A
    git commit --quiet -m "$title"
    git push --quiet -u origin "$branch" 2>/dev/null

    local args=(--base main --head "$branch" --title "$title" --body "Scénario de démo Mergify ($STAMP).")
    [[ -n "$label" ]] && args+=(--label "$label")
    gh pr create "${args[@]}" >/dev/null

    git switch --quiet main 2>/dev/null || git switch --quiet -c main origin/main
    gh pr view "$branch" --json number -q .number
}

# wait_for_check <pr> <check> : attend la fin d'un check sur une PR.
wait_for_check() {
    local pr="$1" check="$2" state
    printf '  ⏳ PR #%s : %s ' "$pr" "$check"
    while :; do
        state="$(gh pr view "$pr" --json statusCheckRollup \
            -q ".statusCheckRollup[] | select(.name == \"$check\") | .conclusion" 2>/dev/null | tail -1)"
        case "$state" in
            SUCCESS) echo "✅"; return 0 ;;
            FAILURE|CANCELLED|TIMED_OUT|ACTION_REQUIRED) echo "❌ ($state)"; return 1 ;;
        esac
        printf '.'
        sleep 10
    done
}

# queue <pr> : met la PR dans la merge queue.
queue() {
    gh pr comment "$1" --body "@mergifyio queue" >/dev/null
    note "📥 PR #$1 mise en file"
}

repo_url() {
    gh repo view --json url -q .url
}

# changelog_entry <texte> : modification inoffensive, un fichier par PR, donc jamais de conflit textuel.
changelog_entry() {
    mkdir -p changelog
    printf '%s\n' "$1" > "changelog/${STAMP}-$RANDOM.md"
}
