#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
packs_dir="$root_dir/domain-packs"
managers_dir="$root_dir/managers"
json_file="$root_dir/managers.json"

usage() {
  printf 'Usage: %s <name> --domain <azure|proxmox|business|generic> [options]\n' "$0"
  printf '\nOptions:\n'
  printf '  --domain <d>         Domain pack to use (required)\n'
  printf '  --owner <name>       Owner (default: kbun)\n'
  printf '  --description <txt>  Short description\n'
  printf '  --dashboard <url>    Local dashboard URL\n'
  printf '  --docs <url>         Docs URL\n'
  printf '  --external <url>     External service URL\n'
  printf '  --force              Overwrite existing generated files\n'
  printf '  -h, --help           Show this help\n'
}

if [[ $# -lt 1 ]]; then usage >&2; exit 1; fi

NAME="$1"; shift
if [[ "$NAME" == "-h" || "$NAME" == "--help" ]]; then usage; exit 0; fi
if [[ ! "$NAME" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
  printf 'Name must be lowercase letters, numbers, hyphens — not start/end with hyphen.\n' >&2
  exit 1
fi

DOMAIN=""
OWNER="kbun"
DESCRIPTION=""
URL_DASHBOARD=""
URL_DOCS=""
URL_EXTERNAL=""
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain)      DOMAIN="${2:-}";        shift 2 ;;
    --owner)       OWNER="${2:-}";         shift 2 ;;
    --description) DESCRIPTION="${2:-}";   shift 2 ;;
    --dashboard)   URL_DASHBOARD="${2:-}"; shift 2 ;;
    --docs)        URL_DOCS="${2:-}";      shift 2 ;;
    --external)    URL_EXTERNAL="${2:-}";  shift 2 ;;
    --force)       FORCE=true;             shift   ;;
    -h|--help)     usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ -z "$DOMAIN" ]]; then
  printf 'Error: --domain is required. Choose: azure proxmox business generic\n' >&2
  exit 1
fi

pack_dir="$packs_dir/$DOMAIN"
if [[ ! -d "$pack_dir" ]]; then
  printf 'Error: Domain pack not found: %s\n' "$pack_dir" >&2
  exit 1
fi

manager_dir="$managers_dir/$NAME"
if [[ -d "$manager_dir" && "$FORCE" != true ]]; then
  printf 'Manager already exists: %s\n  Re-run with --force to overwrite generated files.\n' "$manager_dir" >&2
  exit 1
fi

DATE="$(date +%Y-%m-%d)"

# Copy and substitute templates
mkdir -p "$manager_dir"
while IFS= read -r -d '' tmpl; do
  rel="${tmpl#"$pack_dir"/}"
  dest_rel="${rel%.tmpl}"
  dest="$manager_dir/$dest_rel"
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$dest" && "$FORCE" != true ]]; then
    printf 'Keeping existing: %s\n' "$dest"
    continue
  fi
  sed \
    -e "s|{{NAME}}|$NAME|g" \
    -e "s|{{DOMAIN}}|$DOMAIN|g" \
    -e "s|{{OWNER}}|$OWNER|g" \
    -e "s|{{DATE}}|$DATE|g" \
    -e "s|{{DESCRIPTION}}|$DESCRIPTION|g" \
    "$tmpl" > "$dest"
  if [[ "$tmpl" == *.sh.tmpl ]]; then chmod +x "$dest"; fi
  printf 'Created: %s\n' "$dest"
done < <(find "$pack_dir" -name '*.tmpl' -print0)

# Build urls JSON fragment
urls_json="{"
sep=""
[[ -n "$URL_DASHBOARD" ]] && { urls_json+="${sep}\"dashboard\":\"$URL_DASHBOARD\""; sep=","; }
[[ -n "$URL_DOCS"      ]] && { urls_json+="${sep}\"docs\":\"$URL_DOCS\"";           sep=","; }
[[ -n "$URL_EXTERNAL"  ]] && { urls_json+="${sep}\"external\":\"$URL_EXTERNAL\"";   sep=","; }
urls_json+="}"

# Append entry to managers.json
python3 - "$json_file" "$NAME" "$DOMAIN" "$OWNER" "$DESCRIPTION" "$manager_dir" "$DATE" "$urls_json" << 'PYEOF'
import json, sys
path, name, domain, owner, desc, mpath, date, urls_str = sys.argv[1:]
data = json.load(open(path))
data.setdefault("managers", [])
data["managers"] = [m for m in data["managers"] if m["name"] != name]
data["managers"].append({
    "name": name,
    "domain": domain,
    "owner": owner,
    "path": f"managers/{name}",
    "created": date,
    "description": desc,
    "urls": json.loads(urls_str)
})
json.dump(data, open(path, "w"), indent=2)
print(f"Updated managers.json: added {name}")
PYEOF

"$root_dir/update-master-inventory.sh"

printf '\nManager created: %s\n' "$manager_dir"
