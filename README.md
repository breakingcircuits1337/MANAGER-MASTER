# MASTER-MANAGER

Meta-control-plane for all domain-specific manager workspaces.

## Create a Manager

```bash
./create-manager.sh <name> --domain <azure|proxmox|business|generic> --owner kbun --description "..."
```

## Refresh Dashboard & Inventory

```bash
./update-master-inventory.sh
```

## Backup

```bash
./backup.sh             # snapshot + git bare clone
./backup.sh --snapshot  # snapshot only
./backup.sh --git       # git push only
```

## Domain Packs

| Domain | Purpose |
|---|---|
| `azure` | Azure cloud projects with Terraform scaffolding |
| `proxmox` | Proxmox VM and container management |
| `business` | Client, invoice, and contract management |
| `generic` | Bare-bones template for any custom domain |

<!-- MASTER_MANAGER_INVENTORY_START -->
## Managers

Last updated: `2026-05-13T01:58:21Z`

| Name | Domain | Owner | Description | Dashboard | External |
|---|---|---|---|---|---|
| None yet | - | - | - | - | - |
<!-- MASTER_MANAGER_INVENTORY_END -->
