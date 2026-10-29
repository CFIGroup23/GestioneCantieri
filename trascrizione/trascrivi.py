#!/usr/bin/env python3
"""Trascrive vocali WhatsApp (.ogg/.opus/.m4a/.mp3/.wav/.mp4) in italiano con Whisper small.

Uso:
    python3 trascrizione/trascrivi.py vocale1.ogg [vocale2.ogg ...]

Carica il modello una volta sola e trascrive tutti i file passati. Se il modello
non è pronto lancia prima prepara.sh. L'audio è diviso in blocchi di massimo
~28 s (limite di Whisper: 30 s), tagliando nei punti di silenzio per non
spezzare le parole.
"""
import argparse
import os
import subprocess
import sys
import time
from pathlib import Path

import numpy as np

SR = 16000
HERE = Path(__file__).resolve().parent
MODEL_DIR = Path(os.environ.get("GMG_WHISPER_DIR", Path.home() / ".cache/gmg-whisper-small"))
FILES = ("small-encoder.int8.onnx", "small-decoder.int8.onnx", "small-tokens.txt")


def ensure_model():
    if all((MODEL_DIR / f).is_file() for f in FILES):
        try:
            import sherpa_onnx
            sherpa_onnx.OfflineRecognizer
            return
        except (ImportError, AttributeError):
            pass
    subprocess.run(["bash", str(HERE / "prepara.sh")], check=True)


def load_audio(path):
    """Decodifica con ffmpeg in float32 mono 16 kHz, senza file intermedi."""
    out = subprocess.run(
        ["ffmpeg", "-nostdin", "-v", "error", "-i", str(path),
         "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"],
        check=True, capture_output=True,
    ).stdout
    return np.frombuffer(out, dtype=np.float32)


def split_on_silence(audio, max_s=28.0, min_s=15.0, win_s=0.3):
    """Divide l'audio in blocchi <= max_s, tagliando nel punto più silenzioso
    tra min_s e max_s di ogni blocco."""
    max_n, min_n, win = int(max_s * SR), int(min_s * SR), int(win_s * SR)
    chunks, start = [], 0
    while len(audio) - start > max_n:
        seg = audio[start + min_n:start + max_n]
        # energia media su finestre mobili, scelgo la più bassa
        energy = np.convolve(seg ** 2, np.ones(win) / win, mode="valid")
        cut = start + min_n + int(np.argmin(energy)) + win // 2
        chunks.append(audio[start:cut])
        start = cut
    chunks.append(audio[start:])
    return [c for c in chunks if len(c) > SR // 4]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("files", nargs="+", type=Path)
    ap.add_argument("--lingua", default="it")
    ap.add_argument("--threads", type=int, default=os.cpu_count() or 4)
    args = ap.parse_args()

    ensure_model()
    import sherpa_onnx

    t0 = time.time()
    rec = sherpa_onnx.OfflineRecognizer.from_whisper(
        encoder=str(MODEL_DIR / FILES[0]),
        decoder=str(MODEL_DIR / FILES[1]),
        tokens=str(MODEL_DIR / FILES[2]),
        language=args.lingua,
        task="transcribe",
        num_threads=args.threads,
    )
    print(f"[modello caricato in {time.time() - t0:.1f} s]", file=sys.stderr)

    for path in args.files:
        t1 = time.time()
        audio = load_audio(path)
        chunks = split_on_silence(audio)
        streams = []
        for c in chunks:
            s = rec.create_stream()
            s.accept_waveform(SR, c)
            streams.append(s)
        rec.decode_streams(streams)
        text = " ".join(s.result.text.strip() for s in streams).strip()
        dur = len(audio) / SR
        print(f"=== {path.name} ({dur:.0f} s audio, {time.time() - t1:.1f} s) ===")
        print(text)
        print()


if __name__ == "__main__":
    main()
