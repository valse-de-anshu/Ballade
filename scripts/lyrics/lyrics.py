#!/usr/bin/env python3
import sys
import urllib.request
import urllib.parse
import json
import re

def _clean_str(text: str) -> str:
    if not text:
        return ""
    text = re.sub(r'^\(\d+\)\s*', '', text)
    text = re.sub(r'\s*-\s*YouTube$', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\s*\((Official Music Video|Official Video|Official Audio|Lyric Video|Audio|Video|HD|HQ)\)', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\s*\[(Official Music Video|Official Video|Official Audio|Lyric Video|Audio|Video|HD|HQ|MV)\]', '', text, flags=re.IGNORECASE)
    return text.strip()

def _parse_lrc(lrc_text: str) -> list:
    lines = []
    for raw in lrc_text.splitlines():
        raw = raw.strip()
        if not raw:
            continue
        try:
            tag_end = raw.index("]")
            time_str = raw[1:tag_end]
            text = raw[tag_end + 1:].strip()
            mins, secs = time_str.split(":")
            timestamp = int(mins) * 60 + float(secs)
            lines.append({"time": timestamp, "text": text})
        except Exception:
            continue
    return sorted(lines, key=lambda x: x["time"])

def _is_match(d: dict, title: str, artist: str) -> bool:
    if not d.get("syncedLyrics"):
        return False
    r_title  = (d.get("trackName")  or "").lower()
    r_artist = (d.get("artistName") or "").lower()
    t = title.lower()

    t_clean = re.sub(r'\s*\((feat|ft|with).+?\)', '', t, flags=re.IGNORECASE).strip()
    r_title_clean = re.sub(r'\s*\((feat|ft|with).+?\)', '', r_title, flags=re.IGNORECASE).strip()

    title_match = (t_clean in r_title_clean or r_title_clean in t_clean or t in r_title or r_title in t)
    if not title_match:
        return False

    if not artist or artist.lower() == "youtube":
        return True

    a = artist.lower()
    artist_match = (a in r_artist or r_artist in a or
                    any(word in r_artist for word in a.split() if len(word) > 3))
    return artist_match

def fetch_lrclib(title: str, artist: str, duration: float) -> list:
    title = _clean_str(title)
    artist = _clean_str(artist)

    # Handle "Artist - Song" in title when artist is empty or YouTube
    if (" - " in title) and (not artist or artist.lower() == "youtube"):
        parts = title.split(" - ", 1)
        artist = parts[0].strip()
        title = parts[1].strip()

    urls = []
    if title and artist and artist.lower() != "youtube":
        urls.append(f"https://lrclib.net/api/get?track_name={urllib.parse.quote(title)}&artist_name={urllib.parse.quote(artist)}&duration={int(duration)}")
        urls.append(f"https://lrclib.net/api/search?track_name={urllib.parse.quote(title)}&artist_name={urllib.parse.quote(artist)}")
        urls.append(f"https://lrclib.net/api/search?q={urllib.parse.quote(title + ' ' + artist)}")

    urls.append(f"https://lrclib.net/api/search?q={urllib.parse.quote(title)}")

    for url in urls:
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=10) as r:
                data = json.loads(r.read().decode())
            if isinstance(data, list):
                match = next((d for d in data if _is_match(d, title, artist)), None)
                if match and match.get("syncedLyrics"):
                    return _parse_lrc(match["syncedLyrics"])
            elif isinstance(data, dict) and data.get("syncedLyrics"):
                return _parse_lrc(data["syncedLyrics"])
        except Exception:
            continue
    return []

def main():
    if len(sys.argv) < 2:
        print("no_info", flush=True)
        sys.exit(0)
    title    = sys.argv[1] if len(sys.argv) > 1 else ""
    artist   = sys.argv[2] if len(sys.argv) > 2 else ""
    duration = float(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3].replace('.', '', 1).isdigit() else 0.0

    if not title:
        print("no_info", flush=True)
        sys.exit(0)
    lines = fetch_lrclib(title, artist, duration)
    if not lines:
        print("not_found", flush=True)
        sys.exit(0)
    parts = []
    for line in lines:
        parts.append(str(line["time"]))
        parts.append(line["text"].replace("§", ""))
    parts.append("ok")
    print("§".join(parts), flush=True)

if __name__ == "__main__":
    main()