#!/usr/bin/env python3
"""Generates all original synthesized game audio as 16-bit mono WAVs in
assets/audio/. Pure stdlib; every sound is procedurally created so the
project ships zero third-party audio. Run: python3 tools/generate_audio.py"""
import math, os, random, struct, wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)
random.seed(42)


def save(name, samples):
    samples = [max(-1.0, min(1.0, s)) for s in samples]
    with wave.open(os.path.join(OUT, name + ".wav"), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(s * 32000)) for s in samples))
    print("wrote", name + ".wav")


def env(i, n, a=0.01, r=0.3):
    t = i / n
    attack = min(1.0, t / max(a, 1e-6))
    release = min(1.0, (1.0 - t) / max(r, 1e-6))
    return min(attack, release)


def sine(f, t):
    return math.sin(2 * math.pi * f * t)


def tone(freqs, dur, amp=0.5, a=0.01, r=0.3, vibrato=0.0):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        v = sum(sine(f * (1 + vibrato * sine(5, t)), t) for f in freqs) / len(freqs)
        out.append(v * amp * env(i, n, a, r))
    return out


def noise(dur, amp=0.3, lp=0.2, a=0.01, r=0.4):
    n = int(SR * dur)
    out, prev = [], 0.0
    for i in range(n):
        prev = prev * (1 - lp) + random.uniform(-1, 1) * lp
        out.append(prev * amp * env(i, n, a, r))
    return out


def mix(*layers):
    n = max(len(l) for l in layers)
    return [sum(l[i] if i < len(l) else 0.0 for l in layers) for i in range(n)]


def chord_pad(root, intervals, dur, amp=0.16):
    """Slow ambient pad on a root frequency with soft chorus."""
    n = int(SR * dur)
    freqs = [root * 2 ** (s / 12) for s in intervals]
    out = []
    for i in range(n):
        t = i / SR
        v = 0.0
        for k, f in enumerate(freqs):
            det = 1.0 + 0.002 * sine(0.1 + 0.07 * k, t)
            v += sine(f * det, t) * (0.8 ** k)
        fade = min(1.0, i / (SR * 1.5), (n - i) / (SR * 1.5))
        out.append(v / len(freqs) * amp * fade)
    return out


# --- UI ---------------------------------------------------------------
save("ui_hover", tone([1200], 0.05, 0.15, 0.005, 0.5))
save("ui_click", mix(tone([850], 0.06, 0.3, 0.002, 0.6), tone([1700], 0.03, 0.12, 0.002, 0.6)))
save("ui_error", tone([220, 233], 0.25, 0.3, 0.005, 0.35))
save("ui_confirm", mix(tone([660], 0.09, 0.25, 0.005, 0.4), tone([990], 0.14, 0.2, 0.03, 0.4)))
save("toast", tone([880, 1108], 0.18, 0.2, 0.01, 0.5))
save("warning", mix(tone([440], 0.16, 0.3, 0.005, 0.3), tone([415], 0.3, 0.25, 0.1, 0.4)))

# --- Money / retail ---------------------------------------------------
save("cash", mix(tone([1318], 0.07, 0.25, 0.002, 0.5), tone([1975], 0.12, 0.18, 0.02, 0.5),
                 noise(0.05, 0.08, 0.6)))
save("purchase", mix(tone([987, 1244], 0.12, 0.22, 0.005, 0.4), tone([1479], 0.2, 0.15, 0.05, 0.5)))
save("scanner_beep", tone([1860], 0.09, 0.3, 0.002, 0.2))
save("doorbell", mix(tone([987], 0.25, 0.2, 0.01, 0.6), tone([784], 0.4, 0.18, 0.12, 0.6)))

# --- Machines ---------------------------------------------------------
def machine_hum(name, base, dur=2.0, wob=0.5, amp=0.22):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        v = 0.55 * sine(base, t) + 0.3 * sine(base * 2.01, t) + 0.15 * sine(base * 2.98, t)
        v *= 1.0 + 0.12 * sine(wob, t)
        v += 0.05 * random.uniform(-1, 1)
        out.append(v * amp)
    return out

save("machine_hum_low", machine_hum("l", 62))
save("machine_hum_mid", machine_hum("m", 98))
save("machine_hum_high", machine_hum("h", 140, 1.2))
save("conveyor_loop", mix(machine_hum("c", 48, 1.5, 2.2, 0.12), noise(1.5, 0.06, 0.15, 0.01, 0.01)))
save("machine_start", mix(tone([90, 180], 0.5, 0.3, 0.02, 0.2), noise(0.3, 0.15, 0.3)))
save("machine_done", mix(tone([1046], 0.1, 0.25, 0.005, 0.4), tone([1568], 0.22, 0.2, 0.06, 0.5)))
save("machine_broken", mix(tone([110, 104], 0.6, 0.3, 0.01, 0.3), noise(0.5, 0.25, 0.5)))
save("repair", mix(noise(0.12, 0.3, 0.7), tone([740], 0.15, 0.15, 0.05, 0.5)))
save("packaging_snap", mix(noise(0.06, 0.4, 0.8), tone([520], 0.08, 0.2, 0.002, 0.3)))

# --- World ------------------------------------------------------------
save("door_open", mix(noise(0.35, 0.18, 0.25, 0.02, 0.5), tone([160], 0.3, 0.12, 0.05, 0.6)))
save("pickup", tone([392, 523], 0.09, 0.2, 0.004, 0.5))
save("putdown", mix(noise(0.08, 0.25, 0.6), tone([196], 0.1, 0.2, 0.004, 0.4)))
for i in (1, 2):
    save(f"footstep_hard_{i}", noise(0.07 + 0.01 * i, 0.22, 0.75, 0.004, 0.85))
    save(f"footstep_soft_{i}", noise(0.09 + 0.01 * i, 0.13, 0.3, 0.01, 0.8))
save("van", machine_hum("v", 55, 1.8, 3.0, 0.2))

# --- Stingers ---------------------------------------------------------
save("objective", mix(tone([784], 0.12, 0.2, 0.005, 0.4), tone([987], 0.14, 0.2, 0.08, 0.4),
                      tone([1174], 0.3, 0.2, 0.16, 0.5)))
save("achievement", mix(tone([659], 0.14, 0.2, 0.005, 0.4), tone([830], 0.16, 0.2, 0.09, 0.4),
                        tone([987], 0.2, 0.2, 0.16, 0.4), tone([1318], 0.42, 0.22, 0.24, 0.5)))
save("stage_up", mix(tone([523], 0.2, 0.2, 0.01, 0.5), tone([659], 0.24, 0.2, 0.12, 0.5),
                     tone([784], 0.3, 0.2, 0.22, 0.5), tone([1046], 0.6, 0.24, 0.3, 0.5)))
save("audit_stamp", mix(noise(0.1, 0.5, 0.9), tone([180], 0.14, 0.3, 0.002, 0.3)))
save("victory", mix(tone([523], 0.3, 0.2, 0.01, 0.6), tone([659], 0.35, 0.2, 0.15, 0.6),
                    tone([784], 0.4, 0.2, 0.3, 0.6), tone([1046], 0.8, 0.24, 0.45, 0.6),
                    tone([1318], 1.2, 0.16, 0.7, 0.6)))
save("defeat", mix(tone([392], 0.5, 0.22, 0.01, 0.5), tone([370], 0.7, 0.2, 0.3, 0.5),
                   tone([311], 1.2, 0.2, 0.55, 0.6)))

# --- Ambience loops ---------------------------------------------------
save("amb_workshop", mix(machine_hum("a", 44, 8.0, 0.23, 0.07), noise(8.0, 0.045, 0.06, 0.01, 0.01)))
save("amb_store", mix(machine_hum("s", 52, 8.0, 0.17, 0.05), noise(8.0, 0.035, 0.1, 0.01, 0.01),
                      tone([880], 8.0, 0.008, 0.5, 0.5, 0.3)))
save("amb_office", mix(machine_hum("o", 60, 8.0, 0.11, 0.04), noise(8.0, 0.03, 0.04, 0.01, 0.01)))
save("vent_hum", machine_hum("vent", 75, 6.0, 0.3, 0.09))

# --- Music: layered ambient chord loops -------------------------------
def music(name, roots, intervals, bar=3.0, amp=0.14):
    out = []
    for r in roots:
        out += chord_pad(r, intervals, bar, amp)
    save(name, out)

music("music_menu", [110.0, 87.3, 98.0, 110.0], [0, 7, 12, 16], 4.0, 0.15)
music("music_calm", [98.0, 110.0, 87.3, 130.8], [0, 7, 14, 19], 4.0, 0.11)
music("music_tension", [82.4, 92.5, 82.4, 73.4], [0, 3, 10, 14], 3.0, 0.13)

print("All audio generated.")
