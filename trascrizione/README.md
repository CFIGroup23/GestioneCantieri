# Trascrizione vocali

Trascrive in italiano i vocali WhatsApp con Whisper small (int8) tramite
[sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx), tutto in locale.

```bash
python3 trascrizione/trascrivi.py vocale1.ogg vocale2.ogg
```

- `prepara.sh` installa `sherpa-onnx` e mette il modello in `~/.cache/gmg-whisper-small`.
  Lo prende dalla cache del progetto (`/mnt/project-files/strumenti/whisper-small`,
  ~2 s) o, la prima volta, lo scarica da GitHub (~640 MB, ~1,5 min) e lo salva lì.
- Nelle sessioni cloud l'hook `.claude/hooks/session-start.sh` lancia `prepara.sh` in
  background all'avvio, quindi di solito il modello è già pronto. Log in
  `~/.cache/gmg-whisper-prepara.log`.
- `trascrivi.py` lancia `prepara.sh` da solo se serve, carica il modello una volta
  (~4 s) e divide l'audio in blocchi da max 28 s tagliando sui silenzi.
  Velocità indicativa: ~0,5 s per secondo di audio con 4 core.
- Variabili: `GMG_WHISPER_DIR` (cartella del modello), `GMG_WHISPER_CACHE` (cache condivisa).

huggingface.co è bloccato dal proxy delle sessioni cloud, per questo si usa il
modello pubblicato nelle release GitHub di sherpa-onnx.
