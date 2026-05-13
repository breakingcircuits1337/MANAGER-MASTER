#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
json_file="$root_dir/managers.json"
readme="$root_dir/README.md"
dashboard="$root_dir/dashboard/index.html"
updated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if ! command -v python3 &>/dev/null; then
  printf 'python3 is required\n' >&2
  exit 1
fi

# ── README inventory section ──────────────────────────────────────────────────
section="$(python3 - "$json_file" "$updated_at" << 'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
ts   = sys.argv[2]
mgrs = data.get("managers", [])

lines = []
lines.append("<!-- MASTER_MANAGER_INVENTORY_START -->")
lines.append("## Managers\n")
lines.append(f"Last updated: `{ts}`\n")
lines.append("| Name | Domain | Owner | Description | Dashboard | External |")
lines.append("|---|---|---|---|---|---|")
if not mgrs:
    lines.append("| None yet | - | - | - | - | - |")
for m in mgrs:
    urls  = m.get("urls", {})
    dash  = f"[open]({urls['dashboard']})" if urls.get("dashboard") else "-"
    ext   = f"[open]({urls['external']})" if urls.get("external") else "-"
    lines.append(f"| `{m['name']}` | `{m['domain']}` | `{m['owner']}` | {m.get('description','-')} | {dash} | {ext} |")
lines.append("<!-- MASTER_MANAGER_INVENTORY_END -->")
print("\n".join(lines))
PYEOF
)"

if grep -q '<!-- MASTER_MANAGER_INVENTORY_START -->' "$readme" 2>/dev/null; then
  tmp="$(mktemp)"
  awk -v sec="$section" '
    /<!-- MASTER_MANAGER_INVENTORY_START -->/ { print sec; in_s=1; next }
    /<!-- MASTER_MANAGER_INVENTORY_END -->/   { in_s=0; next }
    !in_s { print }
  ' "$readme" > "$tmp"
  mv "$tmp" "$readme"
else
  printf '\n%s\n' "$section" >> "$readme"
fi

# ── HTML dashboard ────────────────────────────────────────────────────────────
python3 - "$json_file" "$updated_at" "$root_dir" > "$dashboard" << 'PYEOF'
import json, sys, html

data    = json.load(open(sys.argv[1]))
ts      = sys.argv[2]
root    = sys.argv[3]
mgrs    = data.get("managers", [])

def btn(label, url, cls=""):
    return f'<a class="btn {cls}" href="{html.escape(url)}" target="_blank">{html.escape(label)}</a>'

cards = []
for m in mgrs:
    urls  = m.get("urls", {})
    btns  = []
    if urls.get("dashboard"): btns.append(btn("Dashboard", urls["dashboard"], "primary"))
    if urls.get("docs"):      btns.append(btn("Docs",      urls["docs"]))
    if urls.get("external"):  btns.append(btn("External",  urls["external"]))
    for ex in urls.get("extras", []):
        btns.append(btn(ex["label"], ex["url"], "extra"))
    btn_html = "\n        ".join(btns) if btns else "<span class='no-url'>No URLs configured</span>"
    cards.append(f"""
  <div class="card">
    <div class="card-header">
      <span class="name">{html.escape(m['name'])}</span>
      <span class="badge">{html.escape(m['domain'])}</span>
    </div>
    <p class="desc">{html.escape(m.get('description', ''))}</p>
    <p class="owner">Owner: <strong>{html.escape(m['owner'])}</strong></p>
    <div class="btns">
        {btn_html}
    </div>
  </div>""")

cards_html = "\n".join(cards) if cards else '<p class="empty">No managers yet. Run <code>./create-manager.sh</code> to add one.</p>'

print(f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>MASTER-MANAGER Dashboard</title>
<style>
  *{{box-sizing:border-box;margin:0;padding:0}}
  body{{font-family:system-ui,sans-serif;background:#0f1117;color:#e2e8f0;min-height:100vh}}
  header{{background:#1a1f2e;border-bottom:1px solid #2d3748;padding:1.5rem 2rem;display:flex;align-items:center;gap:1rem}}
  header h1{{font-size:1.5rem;font-weight:700;letter-spacing:.05em}}
  header .ts{{margin-left:auto;font-size:.75rem;color:#718096}}
  .terminal-btn{{text-decoration:none;background:#2d3748;color:#68d391;border:1px solid #276749;padding:.35rem .85rem;border-radius:.4rem;font-size:.8rem;font-weight:600;transition:opacity .15s;white-space:nowrap}}
  .terminal-btn:hover{{opacity:.8}}
  .grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:1.5rem;padding:2rem}}
  .card{{background:#1a1f2e;border:1px solid #2d3748;border-radius:.75rem;padding:1.5rem;display:flex;flex-direction:column;gap:.75rem}}
  .card-header{{display:flex;align-items:center;gap:.75rem}}
  .name{{font-size:1.1rem;font-weight:600}}
  .badge{{background:#2b4a8c;color:#90cdf4;font-size:.7rem;padding:.2rem .6rem;border-radius:999px;font-weight:600;text-transform:uppercase}}
  .desc{{color:#a0aec0;font-size:.875rem;line-height:1.5}}
  .owner{{font-size:.8rem;color:#718096}}
  .btns{{display:flex;flex-wrap:wrap;gap:.5rem;margin-top:.25rem}}
  .btn{{text-decoration:none;padding:.4rem .9rem;border-radius:.4rem;font-size:.8rem;font-weight:600;transition:opacity .15s}}
  .btn:hover{{opacity:.8}}
  .btn.primary{{background:#3182ce;color:#fff}}
  .btn:not(.primary):not(.extra){{background:#2d3748;color:#e2e8f0}}
  .btn.extra{{background:#22543d;color:#9ae6b4}}
  .no-url{{color:#4a5568;font-size:.8rem;font-style:italic}}
  .empty{{color:#4a5568;padding:2rem;text-align:center;font-size:1rem}}
  footer{{text-align:center;padding:1.5rem;font-size:.75rem;color:#4a5568;border-top:1px solid #1a1f2e}}
</style>
</head>
<body>
<header>
  <h1>&#9881; MASTER-MANAGER</h1>
  <a class="terminal-btn" href="ai-controller://open" title="Open Konsole in AI-CONTROLLER">&#9654; Terminal</a>
  <span class="ts">Updated: {ts}</span>
</header>
<div class="grid">
{cards_html}
</div>
<footer>Source: {html.escape(root)}/managers.json &nbsp;|&nbsp; <a href="../README.md" style="color:#4a5568">README</a></footer>
</body>
</html>""")
PYEOF

printf 'Updated README: %s\n' "$readme"
printf 'Updated dashboard: %s\n' "$dashboard"
