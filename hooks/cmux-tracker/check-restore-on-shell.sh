#!/bin/bash
# check-restore-on-shell.sh — Au démarrage d'un shell zsh INTERACTIF dans cmux,
# vérifie s'il y a des sessions claude à restaurer après crash et envoie une
# notif macOS si oui. Debouncé via fichier sentinel pour ne pas spammer.
#
# Appelé depuis ~/.zshrc seulement si CMUX_WORKSPACE_ID est set.

set -uo pipefail

SENTINEL="$HOME/.claude/state/.last-restore-check"
DEBOUNCE_MIN=5
RESTORE_BIN="$HOME/.claude/scripts/cmux-tracker/cmux-restore.sh"

# Pas dans cmux ? On ne fait rien (sécurité, normalement le wrapper zsh garde déjà).
[ -z "${CMUX_WORKSPACE_ID:-}" ] && exit 0

# Debounce : pas plus d'un check toutes les DEBOUNCE_MIN minutes
if [ -f "$SENTINEL" ]; then
    last=$(stat -f %m "$SENTINEL" 2>/dev/null || echo 0)
    now=$(date +%s)
    age_min=$(( (now - last) / 60 ))
    [ "$age_min" -lt "$DEBOUNCE_MIN" ] && exit 0
fi

# Update sentinel maintenant pour ne pas re-trigger en parallèle
touch "$SENTINEL"

# Lance le check en background pour ne pas bloquer le shell
[ -x "$RESTORE_BIN" ] && "$RESTORE_BIN" --notify >/dev/null 2>&1 &
disown
