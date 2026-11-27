#!/usr/bin/env python3
"""Synthesises every sound in THE UNCHOSEN (no samples, no licences).

usage: python3 tools/synth_audio.py assets/audio [--samples DIR] [names...]
needs: numpy, scipy, ffmpeg (libvorbis)

With --samples pointing at a checkout of
https://github.com/facebookincubator/Meta-open-sound (CC0 1.0), the music is
played on its real 88-key piano and doors, steps, rain, cars and trains use
its field recordings. Without it, everything falls back to pure synthesis
(noise, sines and simple physical models), so the soundtrack can always be
regenerated, tweaked and versioned like code.
"""
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np
from scipy import signal

SR = 44100
rng = np.random.default_rng(200)
SAMPLES = None   # path to Meta-open-sound, set from the command line
_cache = {}
USED = set()
NOTE_NAMES = ["C", "Cs", "D", "Ds", "E", "F", "Fs", "G", "Gs", "A", "As", "B"]


def load(path):
    """Any audio file -> mono float32 at SR (via ffmpeg)."""
    if path in _cache:
        return _cache[path].copy()
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", path, "-ac", "1", "-ar", str(SR),
                          "-f", "f32le", "-"], check=True, capture_output=True).stdout
    x = np.frombuffer(raw, dtype=np.float32).astype(np.float64)
    _cache[path] = x
    return x.copy()


def rec(name, take=1):
    """A field recording from the Meta-open-sound corpus, or None."""
    if not SAMPLES:
        return None
    base = os.path.join(SAMPLES, "corpora/oculus-audio-pack/ogg")
    for pattern in ("%s_%02d.ogg", "%s_OS_%02d.ogg"):
        path = os.path.join(base, pattern % (name, take))
        if os.path.exists(path):
            USED.add(os.path.basename(path))
            return load(path)
    print("  (no recording %s, synthesising)" % name)
    return None


def piano_sample(n, layer):
    if not SAMPLES:
        return None
    name = "%s%d" % (NOTE_NAMES[n % 12], n // 12 - 1)
    path = os.path.join(SAMPLES, "systems/instruments/meta-piano/ogg", "INSPiano_Vel%02d_%s_01.ogg" % (layer, name))
    if os.path.exists(path):
        USED.add("piano")
        return load(path)
    return None


def fit(x, sec, fade=0.05):
    """Trim or pad to sec, with a short fade at the end."""
    n = int(SR * sec)
    y = np.zeros(n)
    m = min(n, len(x))
    y[:m] = x[:m]
    f = min(int(SR * fade), m)
    if f > 0:
        y[m - f:m] *= np.linspace(1, 0, f)
    return y


def tile(x, sec, fade=0.5):
    """Repeat a short loop to sec with crossfades."""
    out = np.zeros(int(SR * sec))
    f = int(SR * fade)
    step = len(x) - f
    pos = 0
    w = np.ones(len(x))
    w[:f] = np.linspace(0, 1, f)
    w[-f:] = np.linspace(1, 0, f)
    while pos < len(out):
        j = min(len(out), pos + len(x))
        out[pos:j] += (x * w)[: j - pos]
        pos += step
    return out


# ------------------------------------------------------------------ helpers
def t_axis(sec):
    return np.arange(int(SR * sec)) / SR


def noise(sec):
    return rng.standard_normal(int(SR * sec))


def lp(x, hz, order=2):
    b, a = signal.butter(order, hz / (SR / 2), "low")
    return signal.lfilter(b, a, x)


def hp(x, hz, order=2):
    b, a = signal.butter(order, hz / (SR / 2), "high")
    return signal.lfilter(b, a, x)


def bp(x, lo, hi, order=2):
    b, a = signal.butter(order, [lo / (SR / 2), hi / (SR / 2)], "band")
    return signal.lfilter(b, a, x)


def env_ad(n, attack, decay):
    a = int(SR * attack)
    e = np.ones(n)
    if a > 0:
        e[:a] = np.linspace(0, 1, a)
    e[a:] = np.exp(-np.arange(n - a) / (SR * decay))
    return e


def reverb(x, sec=2.5, mix=0.35, tone=4000):
    n = int(SR * sec)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / (SR * sec / 6.0))
    ir = lp(ir, tone)
    ir /= np.sqrt(np.sum(ir ** 2))
    wet = signal.fftconvolve(x, ir)[: len(x)]
    return x * (1 - mix) + wet * mix


def loopable(x, fade=1.5):
    """Crossfades the tail into the head so the file loops without a seam."""
    f = int(SR * fade)
    head = x[:f].copy()
    tail = x[-f:].copy()
    w = np.linspace(0, 1, f)
    x = x[:-f].copy()
    x[:f] = head * w + tail * (1 - w)
    return x


def norm(x, peak=0.9):
    m = np.max(np.abs(x)) + 1e-9
    return x / m * peak


def place(dst, src, at):
    i = int(SR * at)
    j = min(len(dst), i + len(src))
    if i < len(dst):
        dst[i:j] += src[: j - i]


def write(path, x, quality=4):
    x = np.clip(x, -1, 1)
    pcm = (x * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wav = tmp.name
    with wave.open(wav, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis",
                    "-q:a", str(quality), path], check=True)
    os.remove(wav)
    print(f"{os.path.basename(path):24s} {len(x) / SR:6.1f}s")


# ------------------------------------------------------------- instruments
def piano_n(n, sec=4.0, vel=0.6):
    """A piano note by MIDI number: the real upright when available."""
    layer = 1 if vel < 0.3 else 2
    smp = piano_sample(int(n), layer)
    if smp is not None:
        x = fit(smp, sec, fade=min(1.0, sec * 0.3))
        return x / (np.max(np.abs(x)) + 1e-9) * vel * 1.6
    return piano_n(n, sec, vel)


def piano(freq, sec=4.0, vel=0.6):
    """Soft felt piano: slightly inharmonic partials, fast decay of highs."""
    t = t_axis(sec)
    out = np.zeros_like(t)
    for k in range(1, 9):
        f = freq * k * np.sqrt(1 + 0.0004 * k * k)
        if f > SR / 2.2:
            break
        amp = vel / (k ** 1.6)
        dec = 2.8 / (1 + 0.6 * k)
        out += amp * np.sin(2 * np.pi * f * t + rng.uniform(0, 6)) * np.exp(-t / dec)
    hammer = lp(noise(0.02), 2500) * 0.08 * vel
    out[: len(hammer)] += hammer
    a = int(SR * 0.004)
    out[:a] *= np.linspace(0, 1, a)
    return lp(out, 3200)


def pad(freqs, sec, bright=900, wobble=0.15):
    t = t_axis(sec)
    out = np.zeros_like(t)
    for f in freqs:
        for det in (-0.35, 0.0, 0.41):
            ph = rng.uniform(0, 6)
            lfo = 1 + 0.002 * np.sin(2 * np.pi * (0.07 + rng.uniform(0, 0.05)) * t + ph)
            saw = signal.sawtooth(2 * np.pi * (f + det) * lfo * t + ph)
            out += saw * (0.6 + wobble * np.sin(2 * np.pi * 0.05 * t + ph))
    out = lp(out, bright, order=4)
    return out


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


# ------------------------------------------------------------------ music
def music_corridor():
    """A held breath: low drone, a distant chord that never resolves."""
    sec = 48
    t = t_axis(sec)
    drone = np.sin(2 * np.pi * midi(38) * t) * 0.5 + np.sin(2 * np.pi * midi(45) * t + 1) * 0.25
    drone *= 0.6 + 0.4 * np.sin(2 * np.pi * t / sec) ** 2
    chord = pad([midi(n) for n in (50, 57, 60, 64)], sec, bright=700) * 0.05
    chord *= 0.5 + 0.5 * np.sin(2 * np.pi * t / 24 - 1.2) ** 2
    out = drone * 0.4 + chord
    for at, n in [(6, 76), (19, 72), (31, 74), (40, 69)]:
        place(out, piano_n(n, 6, 0.18), at)
    out = reverb(out, 4.0, 0.5, 2500)
    return norm(loopable(out, 3.0), 0.55)


def music_life():
    """Inside a life: rain-soft pad and a few piano notes, A minor-ish."""
    sec = 64
    t = t_axis(sec)
    chords = [(45, 52, 57, 60, 64), (41, 48, 57, 60, 65), (48, 55, 60, 64, 67), (43, 50, 59, 62, 67)]
    out = np.zeros_like(t)
    seg = sec / len(chords)
    for i, ch in enumerate(chords):
        p = pad([midi(n) for n in ch], seg + 4, bright=800) * 0.04
        p *= np.minimum(1, np.minimum(t_axis(seg + 4) / 2.0, (seg + 4 - t_axis(seg + 4)) / 2.0))
        place(out, p, i * seg - (2 if i else 0))
    melody = [(2, 69), (5, 72), (8, 71), (14, 67), (18, 69), (22, 64), (30, 65), (33, 69),
              (36, 72), (40, 71), (46, 67), (50, 71), (53, 72), (58, 74)]
    for at, n in melody:
        place(out, piano_n(n, 5, 0.22), at)
    for at, n in [(0, 45), (16, 41), (32, 48), (48, 43)]:
        place(out, piano_n(n, 7, 0.25), at)
    out = reverb(out, 3.5, 0.45, 3000)
    return norm(loopable(out, 3.0), 0.6)


def music_ending():
    """Open ending: the melody from inside the life, slower, not resolved."""
    sec = 70
    t = t_axis(sec)
    out = pad([midi(n) for n in (45, 52, 60, 64)], sec, bright=600) * 0.035
    out *= np.minimum(1, np.minimum(t / 6.0, (sec - t) / 8.0))
    notes = [(3, 69), (7, 72), (11, 71), (17, 67), (23, 69), (27, 64), (33, 65), (39, 69),
             (44, 72), (48, 71), (55, 74), (61, 71)]
    for at, n in notes:
        place(out, piano_n(n, 8, 0.25), at)
        place(out, piano_n(n - 24, 8, 0.12), at)
    out = reverb(out, 5.0, 0.55, 2600)
    return norm(out, 0.6)


# --------------------------------------------------------------- ambience
def amb_corridor():
    sec = 30
    t = t_axis(sec)
    room = rec("AMBHome_RoomTone_LOOP")
    hvac = rec("MACHHvac_HVAC_LOOP")
    if room is not None and hvac is not None:
        x = fit(room, sec) * 1.0 + tile(hvac, sec, 1.0) * 0.25
        x += np.sin(2 * np.pi * 50 * t) * 0.004
        return norm(loopable(lp(x, 2500), 2.0), 0.35)
    room = lp(noise(sec), 220) * 0.6
    hum = np.sin(2 * np.pi * 50 * t) * 0.05 + np.sin(2 * np.pi * 100 * t) * 0.02
    air = bp(noise(sec), 300, 1200) * 0.05 * (0.6 + 0.4 * np.sin(2 * np.pi * 0.07 * t))
    return norm(loopable(room + hum + air, 2.0), 0.35)


def rain(sec, heavy=1.0):
    base = bp(noise(sec), 400, 6000) * 0.25 * heavy
    # individual drops
    drops = np.zeros(int(SR * sec))
    for at in rng.uniform(0, sec, int(sec * 160 * heavy)):
        d = bp(noise(0.03), 1500, 7000) * env_ad(int(SR * 0.03), 0.0005, 0.006)
        place(drops, d * rng.uniform(0.05, 0.4), at)
    rumble = lp(noise(sec), 150) * 0.5
    return base + drops + rumble


def amb_rain():
    sec = 40
    t = t_axis(sec)
    city = rec("RAIN_CityRain_LOOP")
    x = fit(city, sec) if city is not None else rain(sec, 1.0)
    # distant traffic swells
    traffic = lp(noise(sec), 300) * (0.3 + 0.3 * np.sin(2 * np.pi * t / 13.0) ** 2)
    return norm(loopable(x + traffic, 2.0), 0.4)


def amb_room():
    """Son Mektup: a quiet flat, a wall clock, rain far behind the glass."""
    sec = 30
    room = rec("AMBHome_RoomTone_LOOP", 2)
    x = fit(room, sec) * 0.8 if room is not None else lp(noise(sec), 250) * 0.4
    for i in range(sec):
        tick = bp(noise(0.012), 2500, 6000) * env_ad(int(SR * 0.012), 0.0005, 0.003)
        place(x, tick * (0.10 if i % 2 else 0.07), i + 0.4)
    city = rec("RAIN_CityRain_LOOP")
    x += lp(fit(city[int(SR * 5):], sec), 900) * 0.25 if city is not None else lp(rain(sec, 0.4), 900) * 0.2
    return norm(loopable(x, 2.0), 0.3)


def amb_stairwell():
    """Yanlış Kapı: a concrete stairwell, a ventilation hum, the street below."""
    sec = 30
    hvac = rec("MACHHvac_HVAC_LOOP")
    hum = rec("MACHMisc_MachineHum_LOOP", 2)
    x = tile(hvac, sec, 1.0) * 0.4 if hvac is not None else lp(noise(sec), 300) * 0.3
    if hum is not None:
        x += fit(hum, sec) * 0.3
    city = rec("RAIN_CityRain_LOOP")
    if city is not None:
        x += lp(fit(city[int(SR * 12):], sec), 600) * 0.2
    steps = [rec("FEETHmn_ShoeConcreteWalk", k) for k in (1, 2)]
    if steps[0] is not None:
        for i in range(5):
            place(x, reverb(steps[i % 2], 1.5, 0.6) * 0.08, 17.0 + i * 0.6)
    return norm(loopable(reverb(x, 1.8, 0.25), 2.0), 0.3)


# ------------------------------------------------------------- door loops
def engine(sec, rpm_hz=28):
    t = t_axis(sec)
    x = np.zeros_like(t)
    for k, a in [(1, 1.0), (2, 0.6), (3, 0.3), (4, 0.15)]:
        x += a * np.sin(2 * np.pi * rpm_hz * k * t + rng.uniform(0, 6))
    x *= 1 + 0.15 * lp(noise(sec), 8)
    return lp(x, 400)


def horn(sec=0.6, f=415):
    t = t_axis(sec)
    x = signal.square(2 * np.pi * f * t) + 0.8 * signal.square(2 * np.pi * f * 1.26 * t)
    x = bp(x, 300, 2500) * env_ad(len(t), 0.01, 0.4) * np.minimum(1, (sec - t) * 20)
    return x


def door_traffic():
    sec = 24
    city = rec("RAIN_CityRain_LOOP")
    idle = rec("VEHCar_CarEngineSlow_LOOP")
    if city is not None and idle is not None:
        x = fit(city[int(SR * 10):], sec) * 1.0 + tile(idle, sec, 0.8) * 0.35
    else:
        x = rain(sec, 0.8) + engine(sec) * 0.3
    for at in (4.0, 15.5):
        place(x, horn(0.5) * 0.25, at)
    place(x, horn(0.25, 380) * 0.18, 16.3)
    return norm(loopable(x, 1.5), 0.6)


def door_pen():
    sec = 20
    x = lp(noise(sec), 400) * 0.08  # quiet room
    t = 0.5
    while t < sec - 1:
        stroke = rng.uniform(0.6, 2.4)
        n = int(SR * stroke)
        scratch = bp(noise(stroke), 2000, 8000) * 0.3
        scratch *= (0.5 + 0.5 * np.abs(np.sin(2 * np.pi * rng.uniform(3, 6) * t_axis(stroke)))) ** 2
        scratch *= np.minimum(1, np.minimum(t_axis(stroke) * 20, (stroke - t_axis(stroke)) * 20))
        place(x, scratch, t)
        t += stroke + rng.uniform(0.4, 2.8)
    clock = np.zeros(int(SR * sec))
    for i in range(sec):
        place(clock, bp(noise(0.01), 2000, 5000) * 0.15, i + 0.25)
    page = rec("PAPRHndl_BookPageTurns")
    if page is not None:
        place(x, page * 0.25, 9.0)
    return norm(loopable(x + clock, 1.0), 0.5)


def door_tv():
    sec = 22
    t = t_axis(sec)
    # voices: band-limited noise shaped by syllable envelopes and a moving formant
    voice = np.zeros_like(t)
    pos = 0.3
    while pos < sec - 1:
        phrase = rng.uniform(1.0, 3.0)
        tt = t_axis(phrase)
        syll = np.abs(np.sin(2 * np.pi * rng.uniform(3.5, 5.5) * tt)) ** 1.5
        f0 = rng.uniform(110, 210)
        buzz = signal.sawtooth(2 * np.pi * f0 * (1 + 0.05 * np.sin(2 * np.pi * 0.7 * tt)) * tt)
        v = bp(buzz, 300, 2500) * syll * np.minimum(1, np.minimum(tt * 10, (phrase - tt) * 10))
        place(voice, v * 0.4, pos)
        pos += phrase + rng.uniform(0.2, 1.2)
    laugh_at = 13.0
    place(voice, bp(noise(1.5), 500, 3000) * env_ad(int(SR * 1.5), 0.1, 0.5) * 0.3, laugh_at)
    whine = np.sin(2 * np.pi * 15734 / 4 * t) * 0.01
    x = lp(voice, 3000) + whine + lp(noise(sec), 300) * 0.1
    return norm(loopable(x, 1.0), 0.5)


def door_fluorescent():
    sec = 16
    t = t_axis(sec)
    buzz = signal.sawtooth(2 * np.pi * 100 * t) * 0.3 + np.sin(2 * np.pi * 200 * t) * 0.1
    buzz = bp(buzz, 80, 3000)
    flick = np.ones_like(t)
    for at in (5.0, 11.7):
        i = int(SR * at)
        for k in range(6):
            a = i + int(SR * 0.04 * k)
            flick[a: a + int(SR * 0.02)] = 0.1 if k % 2 == 0 else 1
            place(buzz, bp(noise(0.005), 1000, 6000) * 0.4, at + 0.04 * k)
    room = lp(noise(sec), 300) * 0.15
    hum = rec("MACHMisc_MachineHum_LOOP")
    if hum is not None:
        room = fit(hum, sec) * 0.5
    # a distant name being called
    call = np.zeros_like(t)
    tt = t_axis(1.2)
    v = bp(signal.sawtooth(2 * np.pi * 170 * tt), 400, 2000) * np.abs(np.sin(2 * np.pi * 2.5 * tt))
    place(call, reverb(v * env_ad(len(tt), 0.05, 0.6), 1.5, 0.6) * 0.15, 8.0)
    return norm(loopable(buzz * flick + room + call, 1.0), 0.45)


def door_train():
    sec = 26
    t = t_axis(sec)
    approach = np.exp(-((t - 13) / 5.0) ** 2)
    rumble = lp(noise(sec), 120) * (0.3 + 1.2 * approach)
    clack = np.zeros_like(t)
    tt = 0.0
    while tt < sec:
        place(clack, lp(noise(0.03), 900) * env_ad(int(SR * 0.03), 0.001, 0.01) * 0.6, tt)
        place(clack, lp(noise(0.03), 900) * env_ad(int(SR * 0.03), 0.001, 0.01) * 0.5, tt + 0.18)
        tt += 1.1
    clack *= 0.2 + approach
    chime = np.zeros_like(t)
    for i, n in enumerate((76, 72, 79)):
        place(chime, piano_n(n, 2.0, 0.3), 2.0 + i * 0.45)
    x = rumble + clack + reverb(chime, 2.0, 0.6) * 0.5
    passby = rec("TRNElec_TrainPassby")
    doors = rec("TRNDoor_TrainDoorsOpen")
    if passby is not None:
        x = fit(passby, sec) * 1.0 + reverb(chime, 2.0, 0.6) * 0.15
        if doors is not None:
            place(x, doors * 0.5, 20.0)
    return norm(loopable(x, 2.0), 0.55)


# --------------------------------------------------------------------- sfx
def sfx_ui():
    r = rec("UIClick_WoodConfirm")
    if r is not None:
        return norm(r, 0.4)
    return norm(bp(noise(0.05), 1500, 5000) * env_ad(int(SR * 0.05), 0.001, 0.008), 0.4)


def footstep():
    x = lp(noise(0.18), 600) * env_ad(int(SR * 0.18), 0.002, 0.03)
    x += bp(noise(0.18), 2000, 6000) * env_ad(int(SR * 0.18), 0.001, 0.01) * 0.3
    return x


def sfx_steps():
    out = np.zeros(int(SR * 2.4))
    takes = [rec("FEETHmn_ShoeConcreteWalk", k) for k in (1, 2, 3)]
    for i in range(4):
        st = takes[i % 3] if takes[0] is not None else footstep()
        place(out, st * (0.8 + 0.2 * (i % 2)), 0.1 + i * 0.55)
    return norm(reverb(out, 1.2, 0.3), 0.5)


def creak(sec=1.0, f=180):
    t = t_axis(sec)
    fm = f * (1 + 0.3 * np.sin(2 * np.pi * 1.3 * t) + 0.1 * lp(noise(sec), 20) * 5)
    phase = 2 * np.pi * np.cumsum(fm) / SR
    x = signal.sawtooth(phase) * (0.5 + 0.5 * (lp(noise(sec), 40) > 0))
    x = bp(x, 300, 3000) * np.minimum(1, np.minimum(t * 8, (sec - t) * 4))
    return x


def latch():
    x = bp(noise(0.06), 1500, 6000) * env_ad(int(SR * 0.06), 0.0005, 0.01)
    place(x, bp(noise(0.04), 800, 3000) * env_ad(int(SR * 0.04), 0.0005, 0.012) * 0.6, 0.02)
    return x


def sfx_door_open():
    out = np.zeros(int(SR * 2.0))
    knob = rec("DOORHdwr_OfficeDoorKnob")
    door = rec("DOORWood_FrontDoorOpen")
    place(out, knob * 0.8 if knob is not None else latch() * 0.8, 0.0)
    if door is not None:
        place(out, door * 0.7, 0.45)
    place(out, creak(1.3) * (0.10 if door is not None else 0.25), 0.5)
    return norm(reverb(out, 1.5, 0.3), 0.6)


def sfx_door_close():
    out = np.zeros(int(SR * 1.6))
    door = rec("DOORWood_OfficeDoorClose")
    if door is not None:
        place(out, door, 0.05)
        return norm(reverb(out, 1.5, 0.3), 0.7)
    place(out, creak(0.5, 150) * 0.15, 0.0)
    thud = lp(noise(0.4), 200) * env_ad(int(SR * 0.4), 0.002, 0.07)
    place(out, thud, 0.45)
    place(out, latch() * 0.7, 0.47)
    return norm(reverb(out, 1.5, 0.35), 0.7)


def sfx_enter():
    sec = 3.0
    t = t_axis(sec)
    swell = bp(noise(sec), 500, 6000) * (t / sec) ** 2
    tone = sum(np.sin(2 * np.pi * midi(n) * t) for n in (57, 64, 69, 76)) * 0.08 * (t / sec) ** 3
    x = (swell * 0.4 + tone) * np.minimum(1, (sec - t) * 3)
    return norm(reverb(x, 3.0, 0.5), 0.6)


def sfx_card():
    page = rec("PAPRHndl_BookPageTurns")
    if page is not None:
        env = np.abs(page)
        start = max(0, int(np.argmax(env > 0.2 * env.max())) - int(SR * 0.03))
        return norm(fit(page[start:], 0.45, 0.15), 0.35)
    x = bp(noise(0.25), 800, 5000) * env_ad(int(SR * 0.25), 0.03, 0.06)
    return norm(x, 0.35)


def sfx_swipe():
    w = rec("WHSH_WhooshSmall", 3)
    if w is not None:
        return norm(fit(w, 0.4, 0.05), 0.45)
    sec = 0.4
    t = t_axis(sec)
    x = bp(noise(sec), 600, 4000) * np.sin(np.pi * t / sec) ** 2
    return norm(x, 0.45)


def sfx_tap():
    r = rec("UIClick_WoodOpen")
    if r is not None:
        return norm(r, 0.25)
    return norm(lp(noise(0.06), 1800) * env_ad(int(SR * 0.06), 0.001, 0.012), 0.3)


def sfx_echo():
    out = np.zeros(int(SR * 4.0))
    for i, n in enumerate((81, 88)):
        place(out, piano_n(n, 3.5, 0.3), i * 0.12)
    return norm(reverb(out, 3.5, 0.7, 5000), 0.4)


def sfx_chapter():
    sec = 5.0
    t = t_axis(sec)
    boom = np.sin(2 * np.pi * 55 * t) * np.exp(-t / 1.4) + lp(noise(sec), 120) * np.exp(-t / 0.6) * 0.5
    out = boom * 0.7
    place(out, piano_n(57, 4.5, 0.4), 0.05)
    place(out, piano_n(45, 4.5, 0.3), 0.05)
    return norm(reverb(out, 4.0, 0.5, 2500), 0.7)


def from_rec(name, peak=0.6, sec=None, fallback=None, verb=0.0):
    def make():
        r = rec(name)
        if r is None:
            return fallback() if fallback else norm(sfx_tap(), 0.2)
        if sec:
            r = fit(r, sec, 0.2)
        if verb:
            r = reverb(r, 1.2, verb)
        return norm(r, peak)
    return make


def sfx_horn():
    out = np.zeros(int(SR * 1.4))
    place(out, horn(0.55) * 0.8, 0.0)
    place(out, horn(0.3, 380) * 0.6, 0.75)
    return norm(reverb(lp(out, 2500), 1.5, 0.35), 0.5)


SOUNDS = {
    "car_window": from_rec("VEHWndw_CarWindowOpen", 0.5),
    "coins": from_rec("OBJCoin_CoinDrop", 0.5),
    "knock": from_rec("DOORKnck_OfficeDoorKnock", 0.45, verb=0.2),
    "paper": from_rec("PAPRHndl_PaperCrumple", 0.35, sec=1.4),
    "car_door": from_rec("VEHDoor_CarDoorClose", 0.5, verb=0.2),
    "horn": sfx_horn,
    "corridor": amb_corridor,     # ambience in the corridor
    "rain": amb_rain,             # ambience inside 200 TL
    "room": amb_room,             # ambience inside Son Mektup
    "stairwell": amb_stairwell,   # ambience inside Yanlış Kapı
    "music_corridor": music_corridor,
    "music_life": music_life,
    "music_ending": music_ending,
    "door_traffic": door_traffic,
    "door_pen": door_pen,
    "door_tv": door_tv,
    "door_fluorescent": door_fluorescent,
    "door_train": door_train,
    "ui": sfx_ui,
    "steps": sfx_steps,
    "door_open": sfx_door_open,
    "door_close": sfx_door_close,
    "enter": sfx_enter,
    "card": sfx_card,
    "swipe": sfx_swipe,
    "tap": sfx_tap,
    "echo": sfx_echo,
    "chapter": sfx_chapter,
}

if __name__ == "__main__":
    args = sys.argv[1:]
    if "--samples" in args:
        i = args.index("--samples")
        SAMPLES = args[i + 1]
        del args[i:i + 2]
    out_dir = args[0] if args else "assets/audio"
    os.makedirs(out_dir, exist_ok=True)
    only = set(args[1:])
    for name, fn in SOUNDS.items():
        if only and name not in only:
            continue
        write(os.path.join(out_dir, name + ".ogg"), fn())
    if SAMPLES:
        print("recordings used:", ", ".join(sorted(USED)))
