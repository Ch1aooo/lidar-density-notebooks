"""Finish a GitHub Pages export; run from the sharing repository root."""
from datetime import datetime
from html.parser import HTMLParser
from pathlib import Path
from zoneinfo import ZoneInfo
import sys

root = Path.cwd()
date = (datetime.strptime(sys.argv[1], "%Y-%m-%d") if len(sys.argv) > 1
        else datetime.now(ZoneInfo("Europe/Amsterdam")))
site = root / "site"
template = (root / "web/index.html").read_text(encoding="utf-8")
(site / "index.html").write_text(template.replace("__PUBLISHED_DATE__", date.strftime("%d %B %Y")), encoding="utf-8")
(site / ".nojekyll").touch()

lock = """<script data-published-control-lock>(()=>{const lock=()=>document.querySelectorAll('.part1-controls input,.part1-controls select,.part1-controls button').forEach(el=>{el.disabled=true;el.title='Published snapshot: use local Julia to recompute this control.';});new MutationObserver(lock).observe(document.body,{childList:true,subtree:true});lock();})();</script>"""
for state in site.glob("*.plutostate"):
    page = state.with_suffix(".html")
    html = page.read_text(encoding="utf-8")
    if "data-published-control-lock" not in html:
        page.write_text(html.replace("</body>", lock + "</body>"), encoding="utf-8")

class Links(HTMLParser):
    def handle_starttag(self, tag, attrs):
        for key, value in attrs:
            if key == "href" and value and not value.startswith(("https:", "http:", "#", "mailto:")):
                assert (site / value.split("#")[0]).is_file(), f"Missing share target: {value}"

Links().feed((site / "index.html").read_text(encoding="utf-8"))
for path in site.iterdir():
    assert path.stat().st_size < 95_000_000, f"Split the oversized publication file: {path.name}"
print("Landing links and publication file sizes verified.")
