#!/usr/bin/env python3
"""Walks every possible playthrough of a story JSON and reports problems
(missing targets, unreachable nodes, interludes without beats or art,
silences that are too long).

usage: python3 tools/validate_story.py data/stories/200_tl.json
Same rules as scripts/story_manager.gd: "if" flags are AND-ed, a missing
flag counts as false, first matching variant wins.
"""
import json
import sys
from collections import Counter


def matches(cond, flags):
    return all(flags.get(k, False) == v for k, v in (cond or {}).items())


def pick(node, flags):
    for v in node.get("variants", []):
        if matches(v.get("if"), flags):
            return v["text"]
    return node.get("text", "")


def main(path):
    story = json.load(open(path, encoding="utf-8"))
    nodes = story["nodes"]
    errors = []
    for nid, n in nodes.items():
        for key in ("next",):
            if key in n and n[key] not in nodes:
                errors.append(f"{nid}: next -> missing {n[key]}")
        for side in ("left", "right"):
            if side in n and n[side]["next"] not in nodes:
                errors.append(f"{nid}: {side} -> missing {n[side]['next']}")
        for c in n.get("cases", []):
            if c["next"] not in nodes:
                errors.append(f"{nid}: case -> missing {c['next']}")
        if n.get("type") == "interlude":
            beats = n.get("beats", [])
            if len(beats) < 3:
                errors.append(f"{nid}: interlude needs at least 3 beats")
            if not n.get("art"):
                errors.append(f"{nid}: interlude needs art")
        if n.get("pause", 0) > 4:
            errors.append(f"{nid}: pause longer than 4s")
    seen = set()
    endings = Counter()
    decisions = []
    lengths = []

    def walk(nid, flags, cards, shown, depth):
        if depth > 200:
            errors.append("loop near " + nid)
            return
        n = nodes[nid]
        seen.add(nid)
        flags = dict(flags)
        flags.update(n.get("set", {}))
        t = n["type"]
        if t == "branch":
            for c in n["cases"]:
                if matches(c["if"], flags):
                    return walk(c["next"], flags, cards, shown, depth + 1)
            return walk(n["next"], flags, cards, shown, depth + 1)
        if t == "ending":
            lines = tuple(pick(l, flags) for l in n["lines"])
            endings[lines] += 1
            decisions.append(cards)
            lengths.append(shown)
            return
        if t == "card":
            for side in ("left", "right"):
                o = n[side]
                f2 = dict(flags)
                f2.update(o.get("set", {}))
                walk(o["next"], f2, cards + 1, shown + 1, depth + 1)
            return
        walk(n["next"], flags, cards, shown + 1, depth + 1)

    walk(story["start"], {}, 0, 0, 0)
    unreached = sorted(set(nodes) - seen)
    print(f"nodes: {len(nodes)}  playthroughs: {len(decisions)}  distinct endings: {len(endings)}")
    print(f"decisions per run: {min(decisions)}-{max(decisions)}   screens per run: {min(lengths)}-{max(lengths)}")
    if unreached:
        errors.append("unreachable: " + ", ".join(unreached))
    for e in errors:
        print("ERROR", e)
    if "-v" in sys.argv:
        for lines, count in endings.most_common():
            print(count, "|", " / ".join(lines))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
