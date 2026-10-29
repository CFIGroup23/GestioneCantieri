#!/usr/bin/env bash
# All'avvio di una sessione cloud prepara in background modello e librerie per
# trascrivere i vocali, così quando arriva un vocale è già tutto pronto.
# Non blocca l'avvio: il log va in ~/.cache/gmg-whisper-prepara.log
[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0
dir="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
mkdir -p "$HOME/.cache"
nohup bash "$dir/trascrizione/prepara.sh" >"$HOME/.cache/gmg-whisper-prepara.log" 2>&1 &
exit 0
