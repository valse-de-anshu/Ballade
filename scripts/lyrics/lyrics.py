#!/usr/bin/env python3
"""
Lyrics fetcher — multi-source waterfall with disk cache.

Source priority:
  1. Disk cache  (instant, no network)
  2. Embedded LYRICS/SYLT tag in audio file  (via mutagen, no network)
  3. Local .lrc file next to track  (no network)
  4. lrclib.net  (free, no key, huge catalog)
  5. NetEase Cloud Music  (free, great for anime/K-pop/Asian music)
  6. Megalobiz  (different database, good fallback for Western music)

Output format (single line to stdout):
  time§text§time§text§...§ok     on success
  not_found                       when no synced lyrics found
  no_info                         when title is missing
"""

import sys
import os
import re
import json
import hashlib
import urllib.request
import urllib.parse

try:
    import mutagen
    from mutagen import File as MutagenFile
    from mutagen.id3 import ID3, SYLT, USLT
    MUTAGEN_OK = True
except ImportError:
    MUTAGEN_OK = False

# ─── Cache ────────────────────────────────────────────────────────────────────

CACHE_DIR = os.path.expanduser("~/.cache/qs-lyrics")

def _cache_key(title: str, artist: str) -> str:
    raw = f"{title.lower().strip()}|{artist.lower().strip()}"
    return hashlib.md5(raw.encode()).hexdigest()

def _load_cache(title: str, artist: str):
    os.makedirs(CACHE_DIR, exist_ok=True)
    path = os.path.join(CACHE_DIR, _cache_key(title, artist) + ".json")
    if os.path.exists(path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            if isinstance(data, list) and len(data) > 0:
                return data
        except Exception:
            pass
    return None

def _save_cache(title: str, artist: str, lines: list):
    os.makedirs(CACHE_DIR, exist_ok=True)
    path = os.path.join(CACHE_DIR, _cache_key(title, artist) + ".json")
    try:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(lines, f, ensure_ascii=False)
    except Exception:
        pass

# ─── Helpers ─────────────────────────────────────────────────────────────────

def _clean(text: str) -> str:
    if not text:
        return ""
    text = re.sub(r'^\(\d+\)\s*', '', text)
    text = re.sub(r'\s*-\s*YouTube$', '', text, flags=re.IGNORECASE)
    # Strip common Indian / Bollywood record label suffixes
    text = re.sub(
        r'\s*-\s*(?:T-Series|Zee Music Company|Sony Music India|Tips Official|YRF|Speed Records|Saregama Music|Saregama|White Hill Music|Geet MP3|T-Series Apna Punjab|Eros Now|Desi Music Factory|SonyMusicIndiaVEVO)\s*$',
        '', text, flags=re.IGNORECASE
    )
    # Strip common music video descriptors
    text = re.sub(
        r'\s*[\(\[](?:Official Music Video|Official Video|Official Audio|'
        r'Lyric Video|Lyrical Video|Full Song|Full Audio Song|Audio Song|Song Video|'
        r'4K Video|New Song|Video Song|Title Track|Remix|Slowed\s*(?:and|&|\+)\s*Reverb|'
        r'From\s*"[^"]+"|From\s*[^\)\]]+|Lofi Mix|8D Audio|'
        r'Audio|Video|HD|HQ|MV|4K|8K|Live|Visualizer)[\)\]]',
        '', text, flags=re.IGNORECASE
    )
    return text.strip()

def _parse_lrc(lrc_text: str) -> list:
    """Parse LRC format into [{time, text}, ...] sorted by time."""
    lines = []
    for raw in lrc_text.splitlines():
        raw = raw.strip()
        if not raw:
            continue
        # Handle multiple timestamps on one line: [mm:ss.xx][mm:ss.xx]text
        tags = re.findall(r'\[(\d+:\d+(?:\.\d+)?)\]', raw)
        text = re.sub(r'\[\d+:\d+(?:\.\d+)?\]', '', raw).strip()
        for tag in tags:
            try:
                parts = tag.split(":")
                mins = int(parts[0])
                secs = float(parts[1])
                timestamp = mins * 60 + secs
                lines.append({"time": timestamp, "text": text})
            except Exception:
                continue
    return sorted(lines, key=lambda x: x["time"])

def _title_match(a: str, b: str) -> bool:
    """Fuzzy title comparison."""
    def norm(s):
        s = s.lower()
        s = re.sub(r'\s*[\(\[](feat|ft|with|prod|x)[^\)\]]*[\)\]]', '', s, flags=re.IGNORECASE)
        s = re.sub(r'[^\w\s]', '', s)
        return s.strip()
    a, b = norm(a), norm(b)
    return a in b or b in a or a[:15] == b[:15]

def _artist_match(a: str, b: str) -> bool:
    """Fuzzy artist comparison supporting multi-artist Indian tracks."""
    if not a or a.lower() in ("youtube", "", "unknown"):
        return True
    a_lower, b_lower = a.lower(), b.lower()
    if a_lower in b_lower or b_lower in a_lower:
        return True
    delims = r'[,&/|]|\b(?:feat|ft|with|and|x)\b'
    a_parts = [p.strip() for p in re.split(delims, a_lower) if len(p.strip()) > 2]
    b_parts = [p.strip() for p in re.split(delims, b_lower) if len(p.strip()) > 2]
    for ap in a_parts:
        if any(ap in bp or bp in ap for bp in b_parts) or ap in b_lower:
            return True
    return False

def _http_get(url: str, timeout: int = 8, headers: dict = None) -> bytes:
    hdrs = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"}
    if headers:
        hdrs.update(headers)
    req = urllib.request.Request(url, headers=hdrs)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()

# ─── Source 1: Embedded audio tags ───────────────────────────────────────────

def _from_embedded(file_url: str) -> list:
    """Read SYLT (synced) or plain LYRICS tag from audio file using mutagen."""
    if not MUTAGEN_OK or not file_url or not file_url.startswith("file://"):
        return []
    path = urllib.parse.unquote(file_url[7:])
    if not os.path.exists(path):
        return []
    try:
        audio = MutagenFile(path, easy=False)
        if audio is None:
            return []
        # SYLT = synchronized lyrics (ID3, MP3/FLAC with ID3)
        for tag_key in audio.keys():
            if tag_key.startswith("SYLT"):
                sylt = audio[tag_key]
                lines = []
                for text, ts_ms in sylt.text:
                    if text.strip():
                        lines.append({"time": ts_ms / 1000.0, "text": text.strip()})
                if lines:
                    return sorted(lines, key=lambda x: x["time"])
        # LYRICS: tag (some taggers write plain LRC here)
        for tag_key in audio.keys():
            if tag_key.startswith("LYRICS") or tag_key == "lyrics":
                tag = audio[tag_key]
                raw = tag.text if hasattr(tag, "text") else str(tag)
                if isinstance(raw, list):
                    raw = raw[0] if raw else ""
                if raw and "[" in raw:
                    parsed = _parse_lrc(raw)
                    if parsed:
                        return parsed
        # Vorbis comment "LYRICS" (FLAC/OGG)
        for key in ("LYRICS", "lyrics", "UNSYNCEDLYRICS"):
            if key in audio:
                val = audio[key]
                if isinstance(val, list):
                    val = val[0] if val else ""
                if val and "[" in val:
                    parsed = _parse_lrc(val)
                    if parsed:
                        return parsed
    except Exception:
        pass
    return []

# ─── Source 2: Local .lrc file ────────────────────────────────────────────────

def _from_local_lrc(file_url: str) -> list:
    if not file_url or not file_url.startswith("file://"):
        return []
    path = urllib.parse.unquote(file_url[7:])
    base, _ = os.path.splitext(path)
    lrc_path = base + ".lrc"
    if os.path.exists(lrc_path):
        try:
            with open(lrc_path, "r", encoding="utf-8", errors="ignore") as f:
                return _parse_lrc(f.read())
        except Exception:
            pass
    return []

# ─── Source 3: lrclib.net ─────────────────────────────────────────────────────

def _from_lrclib(title: str, artist: str, duration: float) -> list:
    base = "https://lrclib.net/api"
    urls = []
    if title and artist and artist.lower() not in ("youtube", "", "unknown"):
        if duration > 0:
            urls.append(
                f"{base}/get?track_name={urllib.parse.quote(title)}"
                f"&artist_name={urllib.parse.quote(artist)}"
                f"&duration={int(duration)}"
            )
        urls.append(
            f"{base}/search?track_name={urllib.parse.quote(title)}"
            f"&artist_name={urllib.parse.quote(artist)}"
        )
    urls.append(f"{base}/search?q={urllib.parse.quote(title + ' ' + artist)}")
    urls.append(f"{base}/search?q={urllib.parse.quote(title)}")

    # Try base title without parentheticals (e.g. "Kesariya (From Brahmastra)" -> "Kesariya")
    base_title = re.sub(r'\s*[\(\[][^\)\]]+[\)\]]', '', title).strip()
    if base_title and base_title != title:
        urls.append(f"{base}/search?q={urllib.parse.quote(base_title)}")

    for url in urls:
        try:
            data = json.loads(_http_get(url))
            if isinstance(data, list):
                for strict in (True, False):
                    for d in data:
                        if not d.get("syncedLyrics"):
                            continue
                        tm = _title_match(title, d.get("trackName", "")) or _title_match(base_title, d.get("trackName", ""))
                        am = _artist_match(artist, d.get("artistName", ""))
                        if strict and tm and am:
                            return _parse_lrc(d["syncedLyrics"])
                        if not strict and tm:
                            return _parse_lrc(d["syncedLyrics"])
            elif isinstance(data, dict) and data.get("syncedLyrics"):
                return _parse_lrc(data["syncedLyrics"])
        except Exception:
            continue
    return []

# ─── Source 4: NetEase Cloud Music ────────────────────────────────────────────

def _netease_search_id(title: str, artist: str) -> int | None:
    """Search NetEase and return first matching song ID."""
    query = f"{title} {artist}".strip()
    url = (
        "https://music.163.com/api/search/get/web"
        f"?csrf_token=&s={urllib.parse.quote(query)}&type=1&offset=0&limit=5"
    )
    try:
        data = json.loads(_http_get(url, headers={"Referer": "https://music.163.com/"}))
        songs = data.get("result", {}).get("songs", [])
        for song in songs:
            name = song.get("name", "")
            artists_str = " ".join(a.get("name", "") for a in song.get("artists", []))
            if _title_match(title, name) and _artist_match(artist, artists_str):
                return song.get("id")
    except Exception:
        pass
    return None

def _from_netease(title: str, artist: str) -> list:
    song_id = _netease_search_id(title, artist)
    if not song_id:
        return []
    url = f"https://music.163.com/api/song/lyric?os=pc&id={song_id}&lv=1&kv=1&tv=-1"
    try:
        data = json.loads(_http_get(url, headers={"Referer": "https://music.163.com/"}))
        for key in ("klyric", "lrc"):
            lrc_text = data.get(key, {}).get("lyric", "")
            if lrc_text:
                parsed = _parse_lrc(lrc_text)
                if parsed:
                    return parsed
    except Exception:
        pass
    return []

# ─── Source 5: Megalobiz ─────────────────────────────────────────────────────

def _from_megalobiz(title: str, artist: str) -> list:
    """Search megalobiz.com LRC database."""
    query = f"{artist} {title}".strip() if artist else title
    search_url = f"https://www.megalobiz.com/search/all?qry={urllib.parse.quote(query)}&searchButton=Search"
    try:
        html = _http_get(search_url, timeout=10).decode("utf-8", errors="ignore")
        match = re.search(r'href="(/lrc/maker/[^"]+)"', html)
        if not match:
            return []
        lrc_url = "https://www.megalobiz.com" + match.group(1)
        lrc_html = _http_get(lrc_url, timeout=10).decode("utf-8", errors="ignore")
        lrc_match = re.search(
            r'<div[^>]*id="entity_lyric_text"[^>]*>(.*?)</div>',
            lrc_html, re.DOTALL
        )
        if lrc_match:
            raw = lrc_match.group(1)
            raw = re.sub(r'<[^>]+>', '', raw)
            raw = raw.replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>').replace('&quot;', '"')
            parsed = _parse_lrc(raw)
            if parsed:
                return parsed
    except Exception:
        pass
    return []

# ─── Source 6: YouTube Closed Captions / Subtitles (yt-dlp) ───────────────────

def _parse_vtt(vtt_text: str) -> list:
    lines = []
    blocks = vtt_text.split("\n\n")
    for block in blocks:
        block = block.strip()
        if not block or block.startswith("WEBVTT") or block.startswith("Kind:") or block.startswith("Language:"):
            continue
        ts_match = re.search(r"(\d{2}):(\d{2}):(\d{2}\.\d+)\s*-->", block)
        if not ts_match:
            ts_match = re.search(r"(\d{2}):(\d{2}\.\d+)\s*-->", block)
            if ts_match:
                mins = int(ts_match.group(1))
                secs = float(ts_match.group(2))
                timestamp = mins * 60 + secs
            else:
                continue
        else:
            hrs = int(ts_match.group(1))
            mins = int(ts_match.group(2))
            secs = float(ts_match.group(3))
            timestamp = hrs * 3600 + mins * 60 + secs

        text_lines = [line.strip() for line in block.splitlines() if "-->" not in line and not line.isdigit()]
        text = " ".join(text_lines).strip()
        # Clean inline HTML tags, color spans, and word-level timestamps (e.g. <00:00:01.234>)
        text = re.sub(r"<[^>]+>", "", text)
        text = text.replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>').replace('&quot;', '"').replace('&#39;', "'").replace('&nbsp;', ' ')
        text = re.sub(r"^♪\s*|\s*♪$", "", text).strip()
        if text and (not lines or lines[-1]["text"] != text):
            lines.append({"time": timestamp, "text": text})
    return sorted(lines, key=lambda x: x["time"])

def _from_youtube_cc(title: str, artist: str, file_url: str) -> list:
    query = ""
    if "youtube.com" in file_url or "youtu.be" in file_url:
        query = file_url
    elif title and ("youtube" in artist.lower() or not artist or artist.lower() in ("unknown", "play")):
        query = f"ytsearch1:{title}"
    elif title:
        query = f"ytsearch1:{title} {artist}"
    else:
        return []

    import subprocess, tempfile
    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            out_tmpl = os.path.join(tmpdir, "sub.%(ext)s")
            cmd = [
                "yt-dlp",
                "--no-warnings", "--quiet", "--no-playlist",
                "--write-auto-sub", "--write-sub",
                "--sub-langs", "hi,hi.*,hin,hi-orig,en,en.*,en-orig,all",
                "--skip-download",
                "-o", out_tmpl,
                query
            ]
            subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=300)

            # Sort files with Hindi subtitles first, then English, then others
            def _sub_priority(f):
                f_lower = f.lower()
                if ".hi" in f_lower or "hindi" in f_lower or "hin" in f_lower:
                    return 0
                if ".en" in f_lower or "english" in f_lower:
                    return 1
                return 2

            filenames = sorted(os.listdir(tmpdir), key=_sub_priority)
            for fname in filenames:
                fpath = os.path.join(tmpdir, fname)
                with open(fpath, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                    if fname.endswith(".lrc"):
                        parsed = _parse_lrc(content)
                        if parsed: return parsed
                    elif fname.endswith(".vtt"):
                        parsed = _parse_vtt(content)
                        if parsed: return parsed
    except Exception:
        pass
    return []

# ─── Main waterfall ───────────────────────────────────────────────────────────

def fetch_lyrics(title: str, artist: str, duration: float, file_url: str, mode: str = "lyrics") -> list:
    title  = _clean(title)
    artist = _clean(artist)

    # Split "Artist - Title" pattern when artist is empty/YouTube
    if " - " in title and (not artist or artist.lower() == "youtube"):
        parts = title.split(" - ", 1)
        artist = parts[0].strip()
        title  = parts[1].strip()

    # Explicit CC Mode: fetch YouTube video captions ONLY when requested via CC button
    if mode == "cc":
        return _from_youtube_cc(title, artist, file_url)

    # Standard Lyrics Mode: fetch song lyrics automatically from music sources
    cached = _load_cache(title, artist)
    if cached:
        return cached

    lines = []

    # 1. Embedded audio tag
    if not lines:
        lines = _from_embedded(file_url)

    # 2. Local .lrc file
    if not lines:
        lines = _from_local_lrc(file_url)

    # 3. lrclib.net
    if not lines:
        lines = _from_lrclib(title, artist, duration)

    # 4. NetEase Cloud Music
    if not lines:
        lines = _from_netease(title, artist)

    # 5. Megalobiz
    if not lines:
        lines = _from_megalobiz(title, artist)

    # Cache the result if found
    if lines:
        _save_cache(title, artist, lines)

    return lines

# ─── Entry point ─────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        print("no_info", flush=True)
        sys.exit(0)

    title    = sys.argv[1] if len(sys.argv) > 1 else ""
    artist   = sys.argv[2] if len(sys.argv) > 2 else ""
    duration = float(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3].replace('.','',1).isdigit() else 0.0
    file_url = sys.argv[4] if len(sys.argv) > 4 else ""
    mode     = sys.argv[5] if len(sys.argv) > 5 else "lyrics"

    if not title:
        print("no_info", flush=True)
        sys.exit(0)

    lines = fetch_lyrics(title, artist, duration, file_url, mode)

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