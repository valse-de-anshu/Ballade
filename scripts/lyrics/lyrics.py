#!/usr/bin/env python3
"""
Lyrics fetcher — multi-source waterfall with disk cache and robust metadata harmonizer.

Source priority:
  1. Disk cache  (instant, no network)
  2. Embedded LYRICS/SYLT tag in audio file  (via mutagen, no network)
  3. Local .lrc file next to track or in rmpc library  (no network)
  4. lrclib.net  (high-accuracy synchronized catalog with strict artist/title scoring)
  5. NetEase Cloud Music  (Asian music / anime / J-pop / K-pop)
  6. Megalobiz  (verified query matching)
  7. YouTube Closed Captions  (subtitles for YouTube videos / slowed edits / remixes)

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
import shutil
import subprocess
import tempfile

YTDLP_OK = shutil.which("yt-dlp") is not None

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

# ─── Metadata Harmonizer ──────────────────────────────────────────────────────

def harmonize_metadata(raw_title: str, raw_artist: str = "") -> dict:
    """
    Intelligently harmonizes title and artist from raw MPRIS/browser/YouTube metadata.
    Separates 'Artist - Title', cleans video descriptors, loop tags, and remix fluff,
    while capturing variant flags (e.g. 'slowed', 'remix') for precision search.
    """
    title = (raw_title or "").strip()
    artist = (raw_artist or "").strip()

    # 1. Strip browser/YouTube suffixes & notification badges
    title = re.sub(r'^\(\d+\)\s*', '', title)
    title = re.sub(r'\s*-\s*YouTube(?:\s*Music)?$', '', title, flags=re.IGNORECASE)
    title = re.sub(r'\s*\|\s*Spotify$', '', title, flags=re.IGNORECASE)
    title = re.sub(r'\s*\|\s*SoundCloud$', '', title, flags=re.IGNORECASE)

    # 2. Known music channels / aggregators that are NOT the song artist
    known_channels = {
        "youtube", "youtube music", "spotify", "unknown", "play", "music", "vevo",
        "trap nation", "trap city", "monstercat", "spinnin' records", "selected.",
        "ncs", "nocopyrightsounds", "chilledcow", "lofi girl", "mrsuicidesheep",
        "t-series", "zee music company", "sony music india", "tips official", "yrf",
        "speed records", "saregama music", "saregama", "white hill music", "geet mp3",
        "t-series apna punjab", "eros now", "desi music factory", "sonymusicindiavevo",
        "raider.", "raider", "cloudkid", "proximity", "xclusivmusic"
    }

    # Strip channel suffixes from title
    title = re.sub(
        r'\s*-\s*(?:T-Series|Zee Music Company|Sony Music India|Tips Official|YRF|Speed Records|'
        r'Saregama Music|Saregama|White Hill Music|Geet MP3|T-Series Apna Punjab|Eros Now|'
        r'Desi Music Factory|SonyMusicIndiaVEVO|Vevo|Trap Nation|Trap City|Monstercat|'
        r'Spinnin\' Records|Selected\.|NCS|NoCopyrightSounds)\s*$',
        '', title, flags=re.IGNORECASE
    )

    if artist.lower() in known_channels:
        artist = ""

    # Detect variant tags before stripping fluff (e.g. slowed, ultra slowed, remix)
    variant = ""
    variant_match = re.search(r'\b(ultra slowed|slowed|sped up|speed up|nightcore|daycore|remix|acoustic|instrumental)\b', title, re.IGNORECASE)
    if variant_match:
        variant = variant_match.group(1).lower()

    # 3. Detect "Artist - Title" patterns & segment pipes
    extracted_artist = artist
    extracted_title = title
    alt_title = ""

    # Check pipe separators first (common on YouTube for segmenting track / movie / credits)
    if " | " in title:
        pipe_parts = [p.strip() for p in title.split("|") if p.strip()]
        if len(pipe_parts) >= 2:
            first_seg = pipe_parts[0]
            if " - " in first_seg:
                sub_parts = first_seg.split(" - ", 1)
                extracted_artist = sub_parts[0].strip()
                extracted_title = sub_parts[1].strip()
                alt_title = sub_parts[0].strip()
            else:
                extracted_title = first_seg
                if not extracted_artist:
                    extracted_artist = pipe_parts[1]
    else:
        separators = [
            r'\s*[\-–—]\s*',  # Hyphen, en-dash, em-dash
            r'\s*//\s*',       # Double slash
            r'\s*:\s*',        # Colon
            r'\s*~\s*',        # Tilde
            r'\s*·\s*',        # Middle dot
        ]
        for sep in separators:
            parts = re.split(sep, title, maxsplit=1)
            if len(parts) == 2 and parts[0].strip() and parts[1].strip():
                cand_artist = parts[0].strip()
                cand_title = parts[1].strip()
                if not extracted_artist or extracted_artist.lower() in cand_artist.lower() or cand_artist.lower() in extracted_artist.lower():
                    extracted_artist = cand_artist
                    extracted_title = cand_title
                    break
                elif extracted_artist and not any(part in extracted_artist.lower() for part in cand_artist.lower().split()):
                    extracted_artist = cand_artist
                    extracted_title = cand_title
                    break

    # Handle Japanese / bracket patterns e.g. Artist「Title」
    m_bracket = re.match(r'^(.*?)\s*[「『](.*?)[」』]', extracted_title)
    if m_bracket:
        if not extracted_artist:
            extracted_artist = m_bracket.group(1).strip()
        extracted_title = m_bracket.group(2).strip()

    # 4. Clean fluff from Title
    def clean_title_str(t: str) -> str:
        s = t
        fluff_keywords = (
            r'slowed|sped\s*up|speed\s*up|reverb|loop|nightcore|daycore|remix|edit|'
            r'clean|explicit|version|official|audio|video|lyrics?|visualizer|'
            r'8d\s*audio|lofi|bass\s*boost|best\s*part|chorus|trend|tiktok|'
            r'1\s*hour|10\s*hours|\d+\s*hours?|\d+\s*mins?|hd|hq|4k|8k|mv|live|'
            r'full\s*song|title\s*track|from\s*"|from\s+|prod|feat|ft\.'
        )
        bracket_fluff = re.compile(rf'\s*[\(\[][^\)\]]*(?:{fluff_keywords})[^\)\]]*[\)\]]', re.IGNORECASE)
        for _ in range(4):
            s = bracket_fluff.sub('', s)

        s = re.sub(r'\s*[\(\[]?(?:feat|ft|featuring)\.?\s+[^\)\]]+[\)\]]?', '', s, flags=re.IGNORECASE)
        s = re.sub(r'\s*[\-|]\s*(?:Official|Lyrics?|Audio|Video|HD|4K|MV).*$', '', s, flags=re.IGNORECASE)
        s = re.sub(r'^["\']|["\']$', '', s.strip())
        return s.strip()

    final_title = clean_title_str(extracted_title)
    if not final_title:
        final_title = extracted_title
    final_alt_title = clean_title_str(alt_title) if alt_title else ""

    # Clean artist
    final_artist = extracted_artist
    final_artist = re.sub(r'\s*[\(\[](?:Topic|Official|Vevo)[\)\]]', '', final_artist, flags=re.IGNORECASE)
    final_artist = re.sub(r'\s*-\s*Topic$', '', final_artist, flags=re.IGNORECASE)
    final_artist = re.sub(r'^["\']|["\']$', '', final_artist.strip())

    # Extract primary artist (first name in collaborations)
    primary_artist = ""
    if final_artist:
        p_parts = re.split(r'[,&/|]|\b(?:feat|ft|with|and|x)\b', final_artist, flags=re.IGNORECASE)
        if p_parts and p_parts[0].strip():
            primary_artist = p_parts[0].strip()

    return {
        "title": final_title,
        "alt_title": final_alt_title,
        "artist": final_artist,
        "primary_artist": primary_artist or final_artist,
        "variant": variant,
        "raw_context": f"{raw_title} {raw_artist}".strip()
    }

# ─── Matching & Verification Engine ──────────────────────────────────────────

def _norm_str(s: str) -> str:
    if not s:
        return ""
    s = s.lower()
    s = re.sub(r'[\(\[][^\)\]]*[\)\]]', '', s)
    s = re.sub(r'[^\w\s]', ' ', s)
    return re.sub(r'\s+', ' ', s).strip()

def _score_candidate(target_title: str, target_artist: str, target_duration: float, target_variant: str,
                     cand_title: str, cand_artist: str, cand_duration: float = 0,
                     target_alt_title: str = "", raw_context: str = "") -> float:
    """
    Computes a match confidence score between 0.0 and 1.0.
    CRITICAL: Returns 0.0 (REJECT) if the candidate artist does not match when an artist is known
    or cannot be verified in the raw context. Completely eliminates pulling random songs!
    """
    t_title = _norm_str(target_title)
    c_title = _norm_str(cand_title)
    if not c_title or (not t_title and not target_alt_title):
        return 0.0

    def calc_title_score(t, c):
        if not t or not c:
            return 0.0
        if t == c:
            return 1.0
        t_w = set(t.split())
        c_w = set(c.split())
        if t_w == c_w:
            return 0.95
        union = len(t_w | c_w)
        if not union:
            return 0.0
        inter = len(t_w & c_w)
        if t_w.issubset(c_w) or c_w.issubset(t_w):
            ratio = inter / union
            return ratio if ratio >= 0.35 else 0.0
        sc = inter / union
        return sc if sc >= 0.5 else 0.0

    s1 = calc_title_score(t_title, c_title)
    s2 = calc_title_score(_norm_str(target_alt_title), c_title) if target_alt_title else 0.0
    title_score = max(s1, s2)
    if title_score <= 0.0:
        return 0.0

    # Artist verification: MUST MATCH OR BE VERIFIED IN CONTEXT
    artist_score = 0.0
    t_art = _norm_str(target_artist)
    c_art = _norm_str(cand_artist)
    raw_norm = _norm_str(raw_context)

    if t_art and t_art not in ("unknown", "", "youtube"):
        if t_art == c_art or t_art in c_art or c_art in t_art:
            artist_score = 1.0
        else:
            t_parts = [_norm_str(p) for p in re.split(r'[,&/|]|\b(?:feat|ft|with|and|x)\b', target_artist.lower()) if len(p.strip()) > 2]
            c_parts = [_norm_str(p) for p in re.split(r'[,&/|]|\b(?:feat|ft|with|and|x)\b', cand_artist.lower()) if len(p.strip()) > 2]
            if any(tp in cp or cp in tp for tp in t_parts for cp in c_parts):
                artist_score = 0.9
            elif raw_norm:
                c_tokens = [w for w in c_art.split() if len(w) >= 4]
                if any(w in raw_norm for w in c_tokens):
                    artist_score = 0.95
                else:
                    return 0.0  # REJECT: artist mismatch
            else:
                return 0.0  # REJECT: artist mismatch
    elif raw_norm and c_art:
        c_tokens = [w for w in c_art.split() if len(w) >= 4]
        if any(w in raw_norm for w in c_tokens):
            artist_score = 0.95
        else:
            if len(t_title) <= 8:
                return 0.0  # Reject ambiguous short titles with unverified artist
            artist_score = 0.4
    else:
        artist_score = 0.5

    # Variant match bonus (e.g. slowed, ultra slowed, remix)
    variant_bonus = 0.0
    if target_variant and target_variant.lower() in cand_title.lower():
        variant_bonus = 0.15

    # Duration bonus/penalty
    duration_factor = 1.0
    if target_duration > 15 and cand_duration > 15:
        diff = abs(target_duration - cand_duration)
        if diff <= 10:
            duration_factor = 1.05
        elif diff > 90 and not target_variant:
            duration_factor = 0.85

    score = (title_score * 0.7 + artist_score * 0.3 + variant_bonus) * duration_factor
    return min(1.0, score)

# ─── Helpers ─────────────────────────────────────────────────────────────────

def _parse_lrc(lrc_text: str) -> list:
    """Parse LRC format into [{time, text}, ...] sorted by time."""
    lines = []
    for raw in lrc_text.splitlines():
        raw = raw.strip()
        if not raw:
            continue
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

def _http_get(url: str, timeout: int = 4, headers: dict = None) -> bytes:
    hdrs = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"}
    if headers:
        hdrs.update(headers)
    req = urllib.request.Request(url, headers=hdrs)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()

# ─── Source 1: Embedded Audio Tags ───────────────────────────────────────────

def _from_embedded(file_url: str) -> list:
    if not MUTAGEN_OK or not file_url or not file_url.startswith("file://"):
        return []
    path = urllib.parse.unquote(file_url[7:])
    if not os.path.exists(path):
        return []
    try:
        audio = MutagenFile(path, easy=False)
        if audio is None:
            return []
        for tag_key in audio.keys():
            if tag_key.startswith("SYLT"):
                sylt = audio[tag_key]
                lines = []
                for text, ts_ms in sylt.text:
                    if text.strip():
                        lines.append({"time": ts_ms / 1000.0, "text": text.strip()})
                if lines:
                    return sorted(lines, key=lambda x: x["time"])
        for tag_key in audio.keys():
            if tag_key.startswith("LYRICS") or tag_key == "lyrics":
                tag = audio[tag_key]
                raw = tag.text if hasattr(tag, "text") else str(tag)
                if isinstance(raw, list):
                    raw = raw[0] if raw else ""
                if raw and "[" in raw:
                    parsed = _parse_lrc(raw)
                    if parsed: return parsed
        for key in ("LYRICS", "lyrics", "UNSYNCEDLYRICS"):
            if key in audio:
                val = audio[key]
                if isinstance(val, list):
                    val = val[0] if val else ""
                if val and "[" in raw:
                    parsed = _parse_lrc(val)
                    if parsed: return parsed
    except Exception:
        pass
    return []

# ─── Source 2: Local .lrc Files ───────────────────────────────────────────────

def _from_local_lrc(file_url: str, title: str, artist: str) -> list:
    candidates = []
    if file_url and file_url.startswith("file://"):
        path = urllib.parse.unquote(file_url[7:])
        base, _ = os.path.splitext(path)
        candidates.append(base + ".lrc")
        candidates.append(os.path.join(os.path.dirname(path), "lyrics", os.path.basename(base) + ".lrc"))

    # Also search rmpc / user music library lyrics hubs
    hub_dirs = [
        os.path.expanduser("~/.local/share/rmpc/lyrics"),
        os.path.expanduser("~/Music/internal_music/lyrics")
    ]
    if title:
        safe_t = re.sub(r'[^\w\s-]', '', title).strip()
        for h in hub_dirs:
            if os.path.exists(h):
                candidates.append(os.path.join(h, f"{safe_t}.lrc"))
                if artist:
                    safe_a = re.sub(r'[^\w\s-]', '', artist).strip()
                    candidates.append(os.path.join(h, f"{safe_a} - {safe_t}.lrc"))

    for lrc_path in candidates:
        if os.path.exists(lrc_path):
            try:
                with open(lrc_path, "r", encoding="utf-8", errors="ignore") as f:
                    parsed = _parse_lrc(f.read())
                    if parsed: return parsed
            except Exception:
                pass
    return []

# ─── Source 3: lrclib.net ─────────────────────────────────────────────────────

def _from_lrclib(title: str, artist: str, primary_artist: str, duration: float, variant: str,
                 alt_title: str = "", raw_context: str = "") -> list:
    base = "https://lrclib.net/api"
    urls = []
    art = primary_artist or artist

    # 1. Direct GET if both title and artist are known (and not a variant)
    if art and title and not variant:
        urls.append(f"{base}/get?track_name={urllib.parse.quote(title)}&artist_name={urllib.parse.quote(art)}")

    # 2. Combined fuzzy search (returns up to 20 candidates scored in one shot)
    if art and title:
        if variant:
            urls.append(f"{base}/search?q={urllib.parse.quote(f'{art} {title} {variant}')}")
        urls.append(f"{base}/search?q={urllib.parse.quote(f'{art} {title}')}")
    elif title:
        urls.append(f"{base}/search?q={urllib.parse.quote(title)}")

    # 3. Fallback search on alternative title if distinct
    if alt_title and alt_title.lower() != title.lower():
        urls.append(f"{base}/search?q={urllib.parse.quote(alt_title)}")

    best_match = None
    best_score = 0.0

    for url in urls:
        try:
            raw = _http_get(url, timeout=3)
            data = json.loads(raw)
            candidates = [data] if isinstance(data, dict) else (data if isinstance(data, list) else [])

            for item in candidates:
                synced = item.get("syncedLyrics")
                if not synced:
                    continue
                cand_title = item.get("trackName", "")
                cand_artist = item.get("artistName", "")
                cand_dur = float(item.get("duration", 0))

                score = _score_candidate(
                    target_title=title,
                    target_artist=artist or primary_artist,
                    target_duration=duration,
                    target_variant=variant,
                    cand_title=cand_title,
                    cand_artist=cand_artist,
                    cand_duration=cand_dur,
                    target_alt_title=alt_title,
                    raw_context=raw_context
                )

                if score > best_score and score >= 0.70:
                    best_score = score
                    best_match = synced
                    if score >= 0.95:
                        return _parse_lrc(best_match)
        except Exception:
            continue

        # If this query found a strong match (>= 0.85), don't do subsequent searches
        if best_match and best_score >= 0.85:
            return _parse_lrc(best_match)

    if best_match and best_score >= 0.70:
        return _parse_lrc(best_match)

    return []

# ─── Source 4: NetEase Cloud Music ────────────────────────────────────────────

def _from_netease(title: str, artist: str, primary_artist: str, duration: float, variant: str,
                  alt_title: str = "", raw_context: str = "") -> list:
    query_artist = primary_artist or artist
    query = f"{query_artist} {title}".strip() if query_artist else title
    url = f"https://music.163.com/api/search/get/web?csrf_token=&s={urllib.parse.quote(query)}&type=1&offset=0&limit=6"
    try:
        data = json.loads(_http_get(url, timeout=2, headers={"Referer": "https://music.163.com/"}))
        songs = data.get("result", {}).get("songs", [])
        best_id = None
        best_score = 0.0

        for song in songs:
            name = song.get("name", "")
            artists_str = " ".join(a.get("name", "") for a in song.get("artists", []))
            cand_dur = float(song.get("duration", 0)) / 1000.0

            score = _score_candidate(
                target_title=title,
                target_artist=artist or primary_artist,
                target_duration=duration,
                target_variant=variant,
                cand_title=name,
                cand_artist=artists_str,
                cand_duration=cand_dur,
                target_alt_title=alt_title,
                raw_context=raw_context
            )

            if score > best_score and score >= 0.70:
                best_score = score
                best_id = song.get("id")
                if score >= 0.95:
                    break

        if best_id:
            lyric_url = f"https://music.163.com/api/song/lyric?os=pc&id={best_id}&lv=1&kv=1&tv=-1"
            lyric_data = json.loads(_http_get(lyric_url, timeout=2, headers={"Referer": "https://music.163.com/"}))
            for key in ("klyric", "lrc"):
                lrc_text = lyric_data.get(key, {}).get("lyric", "")
                if lrc_text:
                    parsed = _parse_lrc(lrc_text)
                    if parsed: return parsed
    except Exception:
        pass
    return []

# ─── Source 5: Megalobiz ─────────────────────────────────────────────────────

def _from_megalobiz(title: str, artist: str, primary_artist: str, duration: float, variant: str,
                    alt_title: str = "", raw_context: str = "") -> list:
    query_artist = primary_artist or artist
    query = f"{query_artist} {title}".strip() if query_artist else title
    search_url = f"https://www.megalobiz.com/search/all?qry={urllib.parse.quote(query)}&searchButton=Search"
    try:
        html = _http_get(search_url, timeout=3).decode("utf-8", errors="ignore")
        # Extract result links and titles
        matches = re.findall(r'href="(/lrc/maker/[^"]+)"[^>]*title="([^"]+)"', html)
        for link, link_title in matches:
            score = _score_candidate(
                target_title=title,
                target_artist=artist or primary_artist,
                target_duration=duration,
                target_variant=variant,
                cand_title=link_title,
                cand_artist=query_artist,
                cand_duration=0,
                target_alt_title=alt_title,
                raw_context=raw_context
            )
            if score >= 0.70:
                lrc_url = "https://www.megalobiz.com" + link
                lrc_html = _http_get(lrc_url, timeout=3).decode("utf-8", errors="ignore")
                lrc_match = re.search(r'<div[^>]*id="entity_lyric_text"[^>]*>(.*?)</div>', lrc_html, re.DOTALL)
                if lrc_match:
                    raw = lrc_match.group(1)
                    raw = re.sub(r'<[^>]+>', '', raw)
                    raw = raw.replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>').replace('&quot;', '"')
                    parsed = _parse_lrc(raw)
                    if parsed: return parsed
    except Exception:
        pass
    return []

# ─── Source 6: YouTube Closed Captions (yt-dlp) ───────────────────────────────

def _clean_youtube_url(url: str) -> str:
    if not url:
        return ""
    if "youtube.com/watch" in url:
        m = re.search(r'[?&]v=([a-zA-Z0-9_-]{11})', url)
        if m:
            return f"https://www.youtube.com/watch?v={m.group(1)}"
    elif "youtu.be/" in url:
        m = re.search(r'youtu\.be/([a-zA-Z0-9_-]{11})', url)
        if m:
            return f"https://www.youtube.com/watch?v={m.group(1)}"
    return url

def _parse_vtt(vtt_text: str) -> list:
    lines = []
    blocks = vtt_text.split("\n\n")
    for block in blocks:
        block = block.strip()
        if not block or block.startswith("WEBVTT") or block.startswith("Kind:") or block.startswith("Language:"):
            continue
        ts_match = re.search(r"(\d{2}):(\d{2}):(\d{2}[.,]\d+)\s*-->", block)
        if not ts_match:
            ts_match = re.search(r"(\d{2}):(\d{2}[.,]\d+)\s*-->", block)
            if ts_match:
                mins = int(ts_match.group(1))
                secs = float(ts_match.group(2).replace(",", "."))
                timestamp = mins * 60 + secs
            else:
                continue
        else:
            hrs = int(ts_match.group(1))
            mins = int(ts_match.group(2))
            secs = float(ts_match.group(3).replace(",", "."))
            timestamp = hrs * 3600 + mins * 60 + secs

        text_lines = [line.strip() for line in block.splitlines() if "-->" not in line and not line.isdigit()]
        text_lines = [re.sub(r"<[^>]+>", "", l).strip() for l in text_lines if l.strip()]
        if not text_lines:
            continue

        # Handle YouTube rolling auto-sub duplicates (skip previous repeated line)
        if lines and len(text_lines) > 1 and text_lines[0].lower() == lines[-1]["text"].lower():
            text_lines = text_lines[1:]

        text = " ".join(text_lines).strip()
        text = text.replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>').replace('&quot;', '"').replace('&#39;', "'").replace('&nbsp;', ' ')
        text = re.sub(r"^♪\s*|\s*♪$", "", text).strip()
        if text:
            # If same text as previous, skip duplicate
            if lines and lines[-1]["text"].lower() == text.lower():
                continue
            lines.append({"time": timestamp, "text": text})
    return sorted(lines, key=lambda x: x["time"])

def _from_youtube_cc(title: str, artist: str, file_url: str) -> list:
    if not YTDLP_OK:
        return []

    clean_url = _clean_youtube_url(file_url)
    query = ""
    if clean_url:
        query = clean_url
    elif title and ("youtube" in artist.lower() or not artist or artist.lower() in ("unknown", "play")):
        query = f"ytsearch1:{title}"
    elif title:
        query = f"ytsearch1:{title} {artist}".strip()
    else:
        return []

    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            out_tmpl = os.path.join(tmpdir, "sub.%(ext)s")
            cmd = [
                "yt-dlp",
                "--no-warnings", "--quiet", "--no-playlist",
                "--socket-timeout", "4",
                "--extractor-retries", "1",
                "--write-auto-sub", "--write-sub",
                "--sub-format", "vtt/lrc/best",
                "--sub-langs", "en.*,hi.*,ja.*,ko.*,orig.*,best",
                "--skip-download",
                "-o", out_tmpl,
                query
            ]
            subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)

            def _sub_priority(f):
                f_lower = f.lower()
                if f_lower.endswith(".en.vtt") or f_lower.endswith(".en.lrc"):
                    return 0
                if ".en-orig" in f_lower or ".en" in f_lower or "english" in f_lower:
                    return 1
                if f_lower.endswith(".hi.vtt") or f_lower.endswith(".hi.lrc"):
                    return 2
                if ".hi-orig" in f_lower or ".hi" in f_lower or "hindi" in f_lower or "hin" in f_lower:
                    return 3
                return 4

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

# ─── Main Waterfall Fetcher ───────────────────────────────────────────────────

def fetch_lyrics(raw_title: str, raw_artist: str, duration: float, file_url: str, mode: str = "lyrics") -> list:
    # 1. Harmonize metadata
    meta = harmonize_metadata(raw_title, raw_artist)
    title = meta["title"]
    alt_title = meta["alt_title"]
    artist = meta["artist"]
    primary_artist = meta["primary_artist"]
    variant = meta["variant"]
    raw_context = meta["raw_context"]

    if not title and not alt_title:
        return []

    # 2. Check CC mode explicitly
    if mode == "cc":
        return _from_youtube_cc(title, artist, file_url)

    # 3. Check disk cache
    cached = _load_cache(title, artist)
    if cached:
        return cached

    lines = []

    # 4. Embedded tags
    if not lines and file_url:
        lines = _from_embedded(file_url)

    # 5. Local .lrc
    if not lines:
        lines = _from_local_lrc(file_url, title, artist)

    # 6. lrclib.net (primary synced provider with strict matching)
    if not lines:
        lines = _from_lrclib(title, artist, primary_artist, duration, variant, alt_title=alt_title, raw_context=raw_context)

    # 7. NetEase Cloud Music
    if not lines:
        lines = _from_netease(title, artist, primary_artist, duration, variant, alt_title=alt_title, raw_context=raw_context)

    # 8. Megalobiz
    if not lines:
        lines = _from_megalobiz(title, artist, primary_artist, duration, variant, alt_title=alt_title, raw_context=raw_context)

    # 9. Fallback: YouTube CC for YouTube tracks only when external lyric servers find nothing
    if not lines and ("youtube.com" in file_url or "youtu.be" in file_url):
        lines = _from_youtube_cc(title, artist, file_url)

    # Save to disk cache if verified lines were found
    if lines:
        _save_cache(title, artist, lines)

    return lines

# ─── Entry Point ─────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        print("no_info", flush=True)
        sys.exit(0)

    title    = sys.argv[1] if len(sys.argv) > 1 else ""
    artist   = sys.argv[2] if len(sys.argv) > 2 else ""
    dur_arg  = sys.argv[3] if len(sys.argv) > 3 else "0"
    duration = float(dur_arg) if dur_arg.replace('.', '', 1).isdigit() else 0.0
    if duration > 10000:
        duration = duration / 1_000_000.0  # Convert microseconds to seconds if needed

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
        parts.append(str(round(line["time"], 2)))
        parts.append(line["text"].replace("§", ""))
    parts.append("ok")
    print("§".join(parts), flush=True)

if __name__ == "__main__":
    main()