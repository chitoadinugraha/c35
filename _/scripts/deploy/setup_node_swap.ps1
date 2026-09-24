# Add a 4Gi swap file on the OKE worker (safety net for image builds; not for YB hot path).
# Usage:
#   .\_\scripts\deploy\setup_node_swap.ps1
#   .\_\scripts\deploy\setup_node_swap.ps1 -SizeGi 4 -Swappiness 10

param(
    [int]$SizeGi = 4,
    [int]$Swappiness = 10,
    [string]$SwapFile = "/var/swapfile"
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { throw 'kubectl required' }

$node = kubectl get nodes -o jsonpath='{.items[0].metadata.name}'
if (-not $node) { throw 'no nodes found' }

Write-Host "==> setup ${SizeGi}Gi swap on node $node (swappiness=$Swappiness)"

$script = @"
set -e
if swapon --show | grep -q '$SwapFile'; then
  echo 'swap already active'
  swapon --show
  exit 0
fi
if [ ! -f '$SwapFile' ]; then
  fallocate -l ${SizeGi}G '$SwapFile' || dd if=/dev/zero of='$SwapFile' bs=1M count=$((SizeGi * 1024))
  chmod 600 '$SwapFile'
  mkswap '$SwapFile'
fi
swapon '$SwapFile' || true
grep -q '$SwapFile' /etc/fstab || echo '$SwapFile none swap sw 0 0' >> /etc/fstab
sysctl -w vm.swappiness=$Swappiness
grep -q '^vm.swappiness' /etc/sysctl.conf && sed -i 's/^vm.swappiness.*/vm.swappiness=$Swappiness/' /etc/sysctl.conf || echo "vm.swappiness=$Swappiness" >> /etc/sysctl.conf
free -h
"@

kubectl debug "node/$node" -it --image=busybox:latest -- chroot /host sh -c $script

Write-Host '==> done — verify in root console Swap row after node-stats redeploy'
