#!/usr/bin/env python3
"""0.3 'Emotional Depth' data pass over the three lives.

Adds interludes (short moments lived step by step), silences after weighty
decisions and cross-life echoes. Nothing already written is rewritten:
interludes are spliced in by redirecting `next` pointers, echoes are extra
variants or conditional beats. Idempotent: running it twice changes nothing.

usage: python3 tools/add_depth_03.py data/stories
"""
import json
import os
import sys

d = sys.argv[1] if len(sys.argv) > 1 else "data/stories"


def load(name):
    with open(os.path.join(d, name + ".json"), encoding="utf-8") as f:
        return json.load(f)


def save(name, story):
    with open(os.path.join(d, name + ".json"), "w", encoding="utf-8") as f:
        json.dump(story, f, ensure_ascii=False, indent="\t")


def splice(nodes, nid, node, after, field_path):
    """Insert interlude `nid` so that field_path (list of (node, key...)) now
    leads to it, and it leads on to `after`."""
    if nid in nodes:
        return
    node["next"] = after
    nodes[nid] = node
    for path in field_path:
        ref = nodes[path[0]]
        for k in path[1:-1]:
            ref = ref[k]
        assert ref[path[-1]] == after, (path, ref[path[-1]])
        ref[path[-1]] = nid


def add_variant(node, variant):
    vs = node.setdefault("variants", [])
    if variant not in vs:
        vs.append(variant)


def pause(nodes, ids_seconds):
    for nid, sec in ids_seconds.items():
        nodes[nid]["pause"] = sec


# ------------------------------------------------------------------ 200 TL
s = load("200_tl")
N = s["nodes"]
errand_case = next((i for i, c in enumerate(N["c_route"]["cases"]) if c["next"] in ("c_market1", "c_walk_market")), 0)
splice(N, "c_walk_market", {
    "type": "interlude", "perspective": "cocuk", "art": "walk_to_market", "walk": True,
    "beats": [
        "Market sokağın sonunda. Kırk adım, belki elli.",
        "Avucundaki para ıslanmasın diye yumruğunu sıkıyorsun.",
        {"text": "Arkanda bir araba seni bekliyor. Buna alışık değilsin.",
         "variants": [{"if": {"change_his": True},
                       "text": "“Üstü senin” dedi. Üstünün ne kadar olacağını kafanda sayıyorsun; sayı bir türlü bitmiyor."}]},
        "Kapının zili çalıyor. İçerisi sıcak.",
    ]}, "c_market1", [("c_route", "cases", errand_case, "next")])
splice(N, "a_drive", {
    "type": "interlude", "perspective": "adam", "art": "car_away",
    "beats": [
        "Dikiz aynasında market kapısı.",
        "Biraz daha küçük.",
        "Kapıdan küçük bir şey çıkıyor. Ya da çıkmıyor; ayna çok küçük.",
        "Bir sonraki ışık da yeşil. Bugün her şey yolunda gidiyor.",
    ]}, "a_left2", [("a_left", "next")])
splice(N, "c_uphill", {
    "type": "interlude", "perspective": "cocuk", "art": "walk_home", "walk": True,
    "beats": [
        "Yokuş. Ayakkabının içi çoktan ıslanmış.",
        {"text": "Cebindeki bozukluklar her adımda şıngırdıyor.",
         "variants": [
             {"if": {"brought_bag": True}, "text": "Poşet her adımda biraz daha ağırlaşıyor. Ekmek ıslanıyor."},
             {"if": {"gift": True}, "text": "Elin cebinde; kâğıt paranın kenarını yokluyorsun. Hâlâ orada."},
             {"if": {"returned_goods": True}, "text": "Avucundaki paranın kimin olduğunu düşünüyorsun. Sonra düşünmemeye çalışıyorsun."},
         ]},
        "Pencerede babanın gölgesi bir geçip bir duruyor.",
        {"text": "Kapının önündesin. İçeriden televizyon sesi geliyor.",
         "variants": [{"if": {"yanlis_kapi:y_let_in": True},
                       "text": "Kapının önündesin. Babanın ayakkabıları kapıda; tabanlarında başka bir apartmanın tozu."}]},
    ]}, "b_ch", [("c_walk", "next")])
pause(N, {"a3_open": 2.5, "a_wait": 2.0, "c_car_gone": 2.0, "b4": 3.0, "b_night": 2.5})
add_variant(N["b_night"], {"if": {"yanlis_kapi:y_let_in": True},
    "text": "Gece. Uyuyamıyorsun. Gözünün önüne bir apartman merdiveninde çiçek tutan bir el geliyor. Oğlunun kapısının altından ince bir ışık sızıyor."})
# where the words sit, so they never cover what the moment is about
N["a_drive"]["text_at"] = "bottom"
N["c_uphill"]["text_at"] = "middle"
save("200_tl", s)

# -------------------------------------------------------------- Son Mektup
s = load("son_mektup")
N = s["nodes"]
splice(N, "m_night", {
    "type": "interlude", "perspective": "baba", "art": "night_letter",
    "beats": [
        "Saat ikiyi geçiyor. Lambanın altında yalnızca kâğıt ve ellerin var.",
        "Duvardaki saat. Senin nefesin. Başka ses yok.",
        {"text": "Bir satır yazıyorsun, siliyorsun. Bir satır daha.",
         "variants": [
             {"if": {"m_apology": True}, "text": "“Özür dilerim” yazıyorsun. Kelime kâğıtta senden daha cesur duruyor."},
             {"if": {"m_explain": True}, "text": "Borcu, eczaneyi, patronu yazıyorsun. Her açıklama bir öncekinden uzun."},
             {"if": {"m_unsaid": True}, "text": "Havadan sudan, torunlardan. Asıl cümle kalemin ucunda bekliyor."},
         ]},
        {"if": {"200_tl:father_harsh": True}, "text": "Pencerenin dışında yağmur. O akşamki gibi."},
        {"if": {"yanlis_kapi:y_let_in": True},
         "text": "Bir apartman merdiveni geliyor aklına; yıllar önce bir yabancıya tuttuğun bir kapı. Neden şimdi?"},
        "Kâğıdın sonuna geldin. Gerisini kalem değil, sen bileceksin.",
    ]}, "m4", [("m3_small", "right", "next"), ("m3_evening", "left", "next"), ("m3_evening", "right", "next")])
pause(N, {"m6": 2.5, "o_letter": 2.0, "k_door": 3.0})
save("son_mektup", s)

# ------------------------------------------------------------- Yanlış Kapı
s = load("yanlis_kapi")
N = s["nodes"]
splice(N, "y_stairs", {
    "type": "interlude", "perspective": "kurye", "art": "stair_wait", "walk": True,
    "beats": [
        "Birinci kat. Işık otomatiği tıkırdıyor.",
        "İkinci kat. Arkanda ayak sesleri; senin adımlarına uyuyor.",
        "Üçüncü kat. Işık sönüyor. Karanlıkta kimse düğmeye basmıyor.",
        "Dördüncü kat. Işık geri geliyor. Daire 9.",
    ]}, "y4", [("y3_in", "next")])
pause(N, {"y2": 2.5, "s1": 2.0, "n_hall": 2.5, "n_last": 2.5})
add_variant(N["y1"], {"if": {"200_tl:father_honked": True},
    "text": "Eski bir apartman. Zil paneli. Dördüncü kat, daire 9: S. A. Az önce bir kırmızı ışıkta korna çaldın; elin hâlâ direksiyondaymış gibi."})
save("yanlis_kapi", s)
print("depth pass applied")
