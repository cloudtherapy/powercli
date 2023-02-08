# Connect and Disconnect to vCenter

<#
    .SYNOPSIS
    Connect or disconnect to/from vCenter server
    .DESCRIPTION
    Connect or disconnect to/from vCenter server
    .PARAMETER Environment
    Specify target VCenter environment: hci, norwood
    .INPUTS
    None.
    .OUTPUTS
    None.
    .EXAMPLE
    Connect to vCenter in TierPoint:
    PS> connect-vc.ps1 -VCServer fqdn.vcenter.local
    .LINK
    https://github.com/cloudtherapy/powercli/
#>

param(
    [Switch] $Disconnect,
    [String] $VCServer,
    [String] $VC_User="administrator@vsphere.local"
)

# Ignore SSL warning for VCenter connection
Set-PowerCLIConfiguration -Scope User -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Import PowerCLI Modules
Import-Module VMware.VimAutomation.Core -WarningAction SilentlyContinue

# Disconnect from VCServer if flag enabled
if ($Disconnect) {
	Write-Output "Disconnected from VCenter ${VCServer}"
	Disconnect-VIServer $VCServer -Confirm:$false
	exit 1
}

# Connect to VCenter 
if ($env:vcenter_pass) {
	Write-Output "Connected to VCenter ${VCServer}"
	Connect-VIServer $VCServer -User $VC_User -Password $env:vcenter_pass | Out-Null
} else {
	Write-Output "ERROR: Please set environment variable vcenter_pass"
	exit 1
}

# Verify VCenter Connection
if ($global:defaultviserver.Name -eq $VCServer) {
	Write-Output "VCenter Connection Successful"
    exit 0
} else {
	Write-Output "ERROR: VCenter Connection Failed. Please validate connectivity and credentials"
	exit 1
}