#!/usr/bin/env python3
"""Generate 2 quality Marathi articles daily for मराठीदीप using Gemini + credited images."""

from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CONTENT_DIR = ROOT / "Content"
IMAGES_DIR = ROOT / "Resources" / "images"

SECTIONS: dict[str, dict[str, str]] = {
    "ai": {
        "title": "AI",
        "focus": "कृत्रिम बुद्धिमत्ता, मशीन लर्निंग, generative AI, आणि रोजच्या साधनांचा व्यावहारिक उपयोग",
        "image_fallbacks": "artificial intelligence computer, robot technology, machine learning",
    },
    "technology": {
        "title": "Technology",
        "focus": "सॉफ्टवेअर, इंटरनेट, गॅझेट्स, सायबरसुरक्षा आणि डिजिटल उत्पादकता",
        "image_fallbacks": "laptop computer desk, smartphone technology, internet network",
    },
    "health": {
        "title": "Health",
        "focus": "आरोग्य, पोषण, झोप, मानसिक स्वास्थ्य आणि प्रतिबंधात्मक काळजी",
        "image_fallbacks": "healthy food vegetables, doctor hospital, yoga meditation",
    },
    "finance": {
        "title": "Finance",
        "focus": "बचत, बजेट, गुंतवणूक मूलतत्त्वे, विमा आणि आर्थिक नियोजन",
        "image_fallbacks": "money coins savings, bank finance, calculator budget",
    },
    "fitness": {
        "title": "Fitness",
        "focus": "व्यायाम, स्ट्रेचिंग, घरगुती वर्कआउट आणि सक्रिय जीवनशैली",
        "image_fallbacks": "person jogging outdoor, yoga stretch, gym workout",
    },
    "education": {
        "title": "Education",
        "focus": "शिक्षण पद्धती, कौशल्य विकास, परीक्षा तयारी आणि शिकण्याच्या सवयी",
        "image_fallbacks": "students studying library, classroom school, books education",
    },
    "travel": {
        "title": "Travel",
        "focus": "महाराष्ट्रातील पर्यटन — किल्ले, समुद्रकिनारे, डोंगरस्थान, तीर्थक्षेत्रे, स्थानिक अन्न, प्रवास नियोजन आणि उपयुक्त टिप्स",
        "image_fallbacks": "Maharashtra fort landscape, India hill station, beach Maharashtra",
    },
    "schemes": {
        "title": "Schemes",
        "focus": "भारत व महाराष्ट्र शासकीय योजना — पात्रता, फायदे, अर्ज प्रक्रिया आणि अधिकृत स्रोत तपासणी; नेहमी अटी बदलू शकतात हे स्पष्ट करा",
        "image_fallbacks": "India agriculture farmer, government office India, rural India village",
    },
}

USER_AGENT = "MarathiDeepBot/1.0 (https://github.com/bandalrahul/MarathiDeep; content-automation)"
DEFAULT_MODELS = [
    os.environ.get("GEMINI_MODEL", "gemini-3.6-flash"),
    "gemini-flash-latest",
    "gemini-3.5-flash",
]


def gemini_generate_json(prompt: str, system: str) -> dict[str, Any]:
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is not set")

    payload = {
        "systemInstruction": {"parts": [{"text": system}]},
        "contents": [{"role": "user", "parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.85,
            "responseMimeType": "application/json",
        },
    }

    last_error: Exception | None = None
    for model in DEFAULT_MODELS:
        if not model:
            continue
        url = (
            "https://generativelanguage.googleapis.com/v1beta/models/"
            f"{model}:generateContent?key={urllib.parse.quote(api_key)}"
        )
        req = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json", "User-Agent": USER_AGENT},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=120) as response:
                data = json.loads(response.read().decode("utf-8"))
            text = data["candidates"][0]["content"]["parts"][0]["text"]
            text = text.strip()
            if text.startswith("```"):
                text = re.sub(r"^```(?:json)?\s*", "", text)
                text = re.sub(r"\s*```$", "", text)
            print(f"Used Gemini model: {model}")
            return json.loads(text)
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            last_error = RuntimeError(f"Gemini HTTP {exc.code} ({model}): {detail[:400]}")
            print(last_error)
            continue
        except (KeyError, IndexError, TypeError, json.JSONDecodeError) as exc:
            last_error = RuntimeError(f"Unexpected Gemini response from {model}: {exc}")
            print(last_error)
            continue

    raise RuntimeError(str(last_error) if last_error else "Gemini generation failed")


def slugify(text: str) -> str:
    text = text.strip().lower()
    text = re.sub(r"[^\w\s-]", "", text, flags=re.UNICODE)
    text = re.sub(r"[\s_-]+", "-", text, flags=re.UNICODE)
    text = text.strip("-")
    if not text:
        text = "article"
    return text[:80]


def existing_titles(section: str) -> list[str]:
    folder = CONTENT_DIR / section
    titles: list[str] = []
    if not folder.exists():
        return titles
    for path in folder.glob("*.md"):
        if path.name == "index.md":
            continue
        content = path.read_text(encoding="utf-8")
        match = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
        if match:
            titles.append(match.group(1).strip())
    return titles


def pick_sections(count: int = 2) -> list[str]:
    keys = list(SECTIONS.keys())
    day_index = datetime.now(timezone.utc).timetuple().tm_yday
    start = (day_index * count) % len(keys)
    chosen: list[str] = []
    for offset in range(len(keys)):
        key = keys[(start + offset) % len(keys)]
        if key not in chosen:
            chosen.append(key)
        if len(chosen) == count:
            break
    return chosen


def generate_article(section: str) -> dict[str, Any]:
    meta = SECTIONS[section]
    known = existing_titles(section)
    known_block = "\n".join(f"- {title}" for title in known[:40]) or "- (none yet)"

    system = (
        "तुम्ही मराठीदीप या मराठी ज्ञान पोर्टलचे ज्येष्ठ संपादक आहात. "
        "तुम्ही विश्वासार्ह, व्यावहारिक आणि उच्च दर्जाचे मराठी लेख लिहिता. "
        "Medical/financial दावे सावधगिरीने आणि सामान्य माहिती म्हणून लिहा; वैयक्तिक सल्ला म्हणून सांगू नका. "
        "केवळ वैध JSON परत करा."
    )
    prompt = f"""
विभाग: {meta['title']} ({section})
फोकस: {meta['focus']}

खालील विद्यमान लेख शीर्षके पुन्हा वापरू नका:
{known_block}

एक पूर्णपणे नवीन, उपयुक्त लेख तयार करा. JSON schema:
{{
  "title": "मराठी शीर्षक (स्पष्ट, क्लिकबेट नसलेले)",
  "slug": "english-kebab-case-slug",
  "description": "1-2 वाक्यांत मराठी सारांश (SEO-friendly)",
  "tags": ["3-to-5", "english-or-marathi", "tags"],
  "image_query": "English Wikimedia Commons search: 3-5 short keywords for a PHOTOGRAPH (not painting/map/diagram). Prefer common nouns, e.g. 'India farmer field' or 'students library books'",
  "image_alt": "मराठी alt text for the image",
  "body_markdown": "पूर्ण लेख Markdown मध्ये. पहिली ओळ # शीर्षक असू नये (title स्वतंत्र आहे). किमान 700 मराठी शब्द. H2 उपशीर्षके, बुलेट्स, आणि शेवटी 'मुख्य मुद्दे' विभाग असावा. इंग्रजी पारिभाषिक शब्द आवश्यक असल्यास कंसात द्या."
}}
""".strip()

    article = gemini_generate_json(prompt, system)
    required = ["title", "slug", "description", "tags", "image_query", "image_alt", "body_markdown"]
    missing = [key for key in required if key not in article or not article[key]]
    if missing:
        raise RuntimeError(f"Gemini article missing fields: {missing}")

    article["slug"] = slugify(str(article["slug"]))
    if not isinstance(article["tags"], list):
        article["tags"] = [str(article["tags"])]
    article["tags"] = [str(tag).strip() for tag in article["tags"] if str(tag).strip()][:5]
    return article


def wikimedia_image(query: str) -> dict[str, str] | None:
    search_params = urllib.parse.urlencode(
        {
            "action": "query",
            "format": "json",
            "generator": "search",
            "gsrsearch": query,
            "gsrnamespace": "6",
            "gsrlimit": "12",
            "prop": "imageinfo",
            "iiprop": "url|extmetadata|mime|size",
            "iiurlwidth": "1600",
        }
    )
    url = f"https://commons.wikimedia.org/w/api.php?{search_params}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            data = json.loads(response.read().decode("utf-8"))
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        print(f"Wikimedia search failed for '{query}': {exc}")
        return None

    pages = (data.get("query") or {}).get("pages") or {}
    candidates: list[dict[str, str]] = []
    for page in pages.values():
        infos = page.get("imageinfo") or []
        if not infos:
            continue
        info = infos[0]
        mime = (info.get("mime") or "").lower()
        if not mime.startswith("image/"):
            continue
        if mime in {"image/svg+xml", "image/gif"}:
            continue
        meta = info.get("extmetadata") or {}
        artist = _clean_html((meta.get("Artist") or {}).get("value") or "Unknown")
        license_name = _clean_html((meta.get("LicenseShortName") or {}).get("value") or "Unknown license")
        license_url = _clean_html((meta.get("LicenseUrl") or {}).get("value") or "")
        description_url = info.get("descriptionurl") or page.get("title") or ""
        image_url = info.get("thumburl") or info.get("url")
        if not image_url:
            continue
        candidates.append(
            {
                "url": image_url,
                "artist": artist or "Unknown",
                "license": license_name,
                "license_url": license_url,
                "source_url": description_url,
                "title": page.get("title", "Wikimedia image"),
            }
        )

    return candidates[0] if candidates else None


def _clean_html(value: str) -> str:
    value = re.sub(r"<[^>]+>", " ", value)
    value = re.sub(r"\s+", " ", value)
    return value.strip()


def unsplash_image(query: str) -> dict[str, str] | None:
    access_key = os.environ.get("UNSPLASH_ACCESS_KEY")
    if not access_key:
        return None
    params = urllib.parse.urlencode(
        {
            "query": query,
            "per_page": "1",
            "orientation": "landscape",
            "content_filter": "high",
        }
    )
    url = f"https://api.unsplash.com/search/photos?{params}"
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Client-ID {access_key}",
            "Accept-Version": "v1",
            "User-Agent": USER_AGENT,
        },
    )
    with urllib.request.urlopen(req, timeout=60) as response:
        data = json.loads(response.read().decode("utf-8"))
    results = data.get("results") or []
    if not results:
        return None
    photo = results[0]
    user = photo.get("user") or {}
    return {
        "url": ((photo.get("urls") or {}).get("regular") or (photo.get("urls") or {}).get("full")),
        "artist": user.get("name") or "Unknown",
        "license": "Unsplash License",
        "license_url": "https://unsplash.com/license",
        "source_url": photo.get("links", {}).get("html") or "",
        "title": photo.get("alt_description") or query,
        "credit_extra": f'Photo by [{user.get("name", "Unknown")}]({user.get("links", {}).get("html", "#")}) on [Unsplash](https://unsplash.com)',
    }


def image_query_candidates(primary: str, section: str) -> list[str]:
    """Build increasingly broad search queries for credited stock photos."""
    stopwords = {
        "a",
        "an",
        "the",
        "of",
        "in",
        "on",
        "for",
        "with",
        "and",
        "to",
        "photograph",
        "photo",
        "image",
        "picture",
        "showing",
        "standing",
        "sitting",
    }
    queries: list[str] = []
    primary = (primary or "").strip()
    if primary:
        queries.append(primary)
        words = [w for w in re.split(r"\s+", primary) if w.lower() not in stopwords]
        if len(words) > 4:
            queries.append(" ".join(words[:4]))
        if len(words) > 2:
            queries.append(" ".join(words[:2]))

    fallbacks = SECTIONS[section].get("image_fallbacks", "")
    for part in fallbacks.split(","):
        part = part.strip()
        if part:
            queries.append(part)

    queries.append(SECTIONS[section]["title"])

    seen: set[str] = set()
    unique: list[str] = []
    for query in queries:
        key = query.lower()
        if key not in seen:
            seen.add(key)
            unique.append(query)
    return unique


def find_credited_image(primary_query: str, section: str) -> tuple[dict[str, str], str]:
    """Try Unsplash then Wikimedia across primary + fallback queries."""
    for query in image_query_candidates(primary_query, section):
        try:
            image = unsplash_image(query)
            if image and image.get("url"):
                print(f"Image via Unsplash for query: {query}")
                return image, "Unsplash"
        except Exception as exc:  # noqa: BLE001
            print(f"Unsplash fallback ({query}): {exc}")

        image = wikimedia_image(query)
        if image and image.get("url"):
            print(f"Image via Wikimedia for query: {query}")
            return image, "Wikimedia Commons"

    raise RuntimeError(f"No credited image found for query: {primary_query}")


def download_image(image_url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(image_url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=90) as response:
        dest.write_bytes(response.read())


def credit_markdown(image: dict[str, str], provider: str) -> str:
    if image.get("credit_extra"):
        return f'*{image["credit_extra"]}*'
    license_bit = image["license"]
    if image.get("license_url"):
        license_bit = f'[{image["license"]}]({image["license_url"]})'
    return (
        f'*Image: [{image.get("title", "source")}]({image["source_url"]}) '
        f'by {image["artist"]} via {provider} · {license_bit}*'
    )


def write_article(section: str, article: dict[str, Any], image: dict[str, str], provider: str) -> Path:
    section_dir = CONTENT_DIR / section
    section_dir.mkdir(parents=True, exist_ok=True)

    slug = article["slug"]
    path = section_dir / f"{slug}.md"
    suffix = 2
    while path.exists():
        path = section_dir / f"{slug}-{suffix}.md"
        suffix += 1

    extension = ".jpg"
    lower_url = image["url"].lower()
    if ".png" in lower_url:
        extension = ".png"
    elif ".webp" in lower_url:
        extension = ".webp"

    image_name = f"{section}-{path.stem}{extension}"
    image_path = IMAGES_DIR / image_name
    download_image(image["url"], image_path)

    now = datetime.now().astimezone().strftime("%Y-%m-%d %H:%M")
    tags = ", ".join(article["tags"])
    body = str(article["body_markdown"]).strip()
    body = re.sub(r"^#\s+.*\n+", "", body)

    markdown = f"""---
date: {now}
description: {article['description'].strip()}
tags: {tags}
---
# {article['title'].strip()}

![{article['image_alt'].strip()}](/images/{image_name})
{credit_markdown(image, provider)}

{body}
"""
    path.write_text(markdown.strip() + "\n", encoding="utf-8")
    return path


def generate_one(section: str) -> Path:
    print(f"Generating article for section: {section}")
    article = generate_article(section)
    image, provider = find_credited_image(str(article["image_query"]), section)
    path = write_article(section, article, image, provider)
    print(f"Wrote {path.relative_to(ROOT)} with image credit via {provider}")
    return path


def main() -> int:
    count = int(os.environ.get("ARTICLE_COUNT", "2"))
    sections = pick_sections(count)
    written: list[Path] = []
    errors: list[str] = []
    for section in sections:
        try:
            written.append(generate_one(section))
        except Exception as exc:  # noqa: BLE001
            message = f"{section}: {exc}"
            errors.append(message)
            print(f"ERROR generating {message}", file=sys.stderr)

    if written:
        print("Generated files:")
        for path in written:
            print(f" - {path.relative_to(ROOT)}")
    if errors:
        print(f"Failed sections ({len(errors)}):", file=sys.stderr)
        for message in errors:
            print(f" - {message}", file=sys.stderr)
    if not written:
        raise RuntimeError("No articles generated")
    # Partial success still exits 0 so commit/push can save what we wrote.
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}", file=sys.stderr)
        raise
