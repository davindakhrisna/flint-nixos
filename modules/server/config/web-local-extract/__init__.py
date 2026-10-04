"""Bounded page extraction using Hermes's SSRF-safe HTTP client and stdlib."""
from html.parser import HTMLParser

from agent.web_search_provider import WebSearchProvider
from tools.url_safety import create_ssrf_safe_client

MAX_BYTES = 2 * 1024 * 1024


class PageText(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.hidden = 0
        self.in_title = False
        self.title = []
        self.parts = []

    def handle_starttag(self, tag, attrs):
        if tag in {"script", "style", "noscript", "template"}:
            self.hidden += 1
        if tag == "title":
            self.in_title = True
        if tag in {"p", "div", "br", "li", "h1", "h2", "h3", "section"}:
            self.parts.append("\n")

    def handle_endtag(self, tag):
        if tag in {"script", "style", "noscript", "template"}:
            self.hidden = max(0, self.hidden - 1)
        if tag == "title":
            self.in_title = False
        if tag in {"p", "div", "li", "h1", "h2", "h3", "section"}:
            self.parts.append("\n")

    def handle_data(self, data):
        if self.in_title:
            self.title.append(data)
        elif not self.hidden:
            self.parts.append(data)


class LocalExtract(WebSearchProvider):
    @property
    def name(self):
        return "local-extract"

    def is_available(self):
        return True

    def supports_search(self):
        return False

    def supports_extract(self):
        return True

    def extract(self, urls, **kwargs):
        results = []
        max_chars = max(1, min(int(kwargs.get("max_chars") or 50000), 200000))
        with create_ssrf_safe_client(follow_redirects=True, timeout=20, trust_env=False) as client:
            for url in urls:
                try:
                    with client.stream("GET", url) as response:
                        response.raise_for_status()
                        chunks, size = [], 0
                        for chunk in response.iter_bytes():
                            size += len(chunk)
                            if size > MAX_BYTES:
                                raise ValueError("Page exceeds the 2 MiB extraction limit")
                            chunks.append(chunk)
                        content_type = response.headers.get("content-type", "").lower()
                        if not any(kind in content_type for kind in ("text/", "json", "xml", "html")):
                            raise ValueError("Use a document tool for non-text pages")
                        text = b"".join(chunks).decode(response.encoding or "utf-8", errors="replace")
                    title = ""
                    if "html" in content_type:
                        parser = PageText()
                        parser.feed(text)
                        title = "".join(parser.title).strip()
                        text = "\n".join(line.strip() for line in "".join(parser.parts).splitlines() if line.strip())
                    text = text[:max_chars]
                    results.append({"url": url, "title": title, "content": text, "raw_content": text})
                except Exception as exc:
                    results.append({"url": url, "error": str(exc)})
        return results


def register(ctx):
    ctx.register_web_search_provider(LocalExtract())
