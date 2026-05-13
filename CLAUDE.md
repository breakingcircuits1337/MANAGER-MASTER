# MASTER-MANAGER Agent Instructions

This workspace is the meta-control-plane for all domain-specific manager workspaces.

## Default Manager Creation Flow

When asked to create, add, or set up a new manager:

1. Load the `new-project` skill before acting.
2. Ask only for missing blocking information (name, domain, description).
3. Run `create-manager.sh <name> --domain <azure|proxmox|business|generic>` to stamp out the manager.
4. Run `update-master-inventory.sh` before finishing.
5. Report the manager path, what was created, and the dashboard URL.

## Standard Commands

Create a new manager:

```bash
./create-manager.sh <name> --domain <azure|proxmox|business|generic> --owner kbun --description "..."
```

Refresh master inventory and dashboard:

```bash
./update-master-inventory.sh
```

Backup everything (snapshot + git bare clone):

```bash
./backup.sh
```

## Defaults

- Owner: kbun
- Managers folder: `managers/`
- Dashboard: `dashboard/index.html`
- GitHub: git@github.com:breakingcircuits1337/MANAGER-MASTER.git

## Blocking Questions

Ask before continuing when missing:

- Manager name
- Domain (azure, proxmox, business, or generic)
- Any destructive operation (deletion, overwrite with --force)

## Inventory Requirement

`managers.json` is the source of truth. `README.md` and `dashboard/index.html` are generated from it.
Always run `update-master-inventory.sh` after any change to `managers.json`.

## Backup Before Destructive Actions

Always run `./backup.sh` before deleting or overwriting a manager.
