---
name: trascrivi-vocale
description: Trascrive in italiano i vocali WhatsApp (.ogg/.opus o file audio senza estensione) mandati in chat, con lo script del repository GestioneCantieri. Usala ogni volta che arriva un vocale da trascrivere.
---

# Trascrivi vocale

1. Trova i file audio: quelli caricati in chat sono in `/mnt/project-files/uploads/hearth/` (nome = id, senza estensione; vanno bene così, ffmpeg riconosce il formato).
2. Lancia, con tutti i vocali del messaggio in un solo comando (il modello si carica una volta):

   ```bash
   python3 trascrizione/trascrivi.py <file1> [<file2> ...]
   ```

   dalla cartella del repository GestioneCantieri. Se modello e librerie non sono ancora pronti, lo script lancia da solo `trascrizione/prepara.sh` (circa 5 s se il modello è già nella cache del progetto `/mnt/project-files/strumenti/whisper-small/`, circa 1,5 min la prima volta). Non scaricare il modello a mano e non provare faster-whisper o huggingface (bloccato dal proxy).
3. La trascrizione di Whisper small storpia alcune parole (nomi di vie, termini edili): interpretale con il contesto e le foto, e nel riepilogo segnala le parti incerte invece di inventarle.
