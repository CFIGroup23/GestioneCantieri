#!/usr/bin/env bash
# Prepara librerie e modello Whisper small (int8) per trascrivere i vocali.
# Idempotente: se tutto è già pronto esce subito.
# Ordine delle fonti del modello:
#   1. $MODEL_DIR (già pronto in questa sessione)
#   2. cache condivisa del progetto ($CACHE_DIR, sopravvive alle sessioni): ~2 s
#   3. download da GitHub k2-fsa/sherpa-onnx (~640 MB) + estrazione: ~1,5 min,
#      poi il modello viene salvato nella cache condivisa per le volte successive.
set -euo pipefail

MODEL_DIR="${GMG_WHISPER_DIR:-$HOME/.cache/gmg-whisper-small}"
CACHE_DIR="${GMG_WHISPER_CACHE:-/mnt/project-files/strumenti/whisper-small}"
URL="https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-small.tar.bz2"
FILES=(small-encoder.int8.onnx small-decoder.int8.onnx small-tokens.txt)

log() { echo "[prepara] $*" >&2; }

# Un solo prepara alla volta (l'hook di avvio e trascrivi.py possono partire insieme)
mkdir -p "$MODEL_DIR"
exec 9>"$MODEL_DIR/.lock"
flock 9

have_all() {
  local d="$1"
  for f in "${FILES[@]}"; do [ -s "$d/$f" ] || return 1; done
}

# Librerie Python (pypi è raggiungibile dal proxy, huggingface no)
if ! python3 -c "import sherpa_onnx; sherpa_onnx.OfflineRecognizer" 2>/dev/null; then
  log "installo sherpa-onnx"
  pip install -q --root-user-action=ignore sherpa-onnx >&2
fi
command -v ffmpeg >/dev/null || log "ATTENZIONE: ffmpeg non trovato"

if have_all "$MODEL_DIR"; then
  log "modello già pronto in $MODEL_DIR"
  exit 0
fi

if have_all "$CACHE_DIR"; then
  log "copio il modello dalla cache del progetto"
  for f in "${FILES[@]}"; do cp "$CACHE_DIR/$f" "$MODEL_DIR/$f.tmp" && mv "$MODEL_DIR/$f.tmp" "$MODEL_DIR/$f"; done
else
  log "scarico il modello da GitHub (~640 MB)"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL -o "$tmp/m.tar.bz2" "$URL"
  tar xjf "$tmp/m.tar.bz2" -C "$tmp" --wildcards $(printf '*%s ' "${FILES[@]}")
  for f in "${FILES[@]}"; do mv "$tmp/sherpa-onnx-whisper-small/$f" "$MODEL_DIR/$f"; done
  if mkdir -p "$CACHE_DIR" 2>/dev/null; then
    log "salvo il modello nella cache del progetto"
    for f in "${FILES[@]}"; do cp "$MODEL_DIR/$f" "$CACHE_DIR/$f.tmp" && mv "$CACHE_DIR/$f.tmp" "$CACHE_DIR/$f"; done
  fi
fi

have_all "$MODEL_DIR" && log "pronto: $MODEL_DIR"
