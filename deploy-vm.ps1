# Deploy a VM in vCenter

<#
    .SYNOPSIS
    Deploy virtual machine(s) in vSphere from Content Library
    .DESCRIPTION
    Deploy virtual machine(s) from existing OVA templates found in the Content Library
    .PARAMETER Environment
    Specify target VCServer
    .INPUTS
    None.
    .OUTPUTS
    None.
    .EXAMPLE
    Build virtual machine:
    PS> deploy-vm.ps1 -Hosts vm-monkey
    .LINK
    https://github.com/cloudtherapy/powercli/
#>

param(
    [String] $VCenter = "<vcenter_fqdn_or_ip_address>",
    [String] $DiskFormat="Thin",
    [String] $ContentLibrary="<content_library>",
    [String] $SourceOva = "<source_ova>",
    [String] $OSCustomSpec = "<os_specification>",
    [String] $Folder="Discovered virtual machine",
    [String] $CustomNotes="Created by PowerCLI",
	[String] $NetworkName="<virtual_network>",
    [Switch] $Destroy,
    [String] $ClusterName="<cluster_name>",
    [String] $DatastoreName="<datastore_name>",
	[Array] $Hosts='vm-powercli',
	[DateTime] $Date
)

#Requires -Version 7.1

$Date=Get-Date
$CustomNotes="Created by PowerCLI - Date: $Date"

. .\connect-vc.ps1 -VCServer $VCenter
if ($LASTEXITCODE -eq 1) {
    exit 1
}

# Ignore SSL warning for VCenter connection
Set-PowerCLIConfiguration -Scope User -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Import PowerCLI Modules
Import-Module VMware.VimAutomation.Core -WarningAction SilentlyContinue

# Configure target environment

## ESX Cluster
$Cluster = Get-Cluster -Name $ClusterName

if ($Destroy) {
	$pcliContext = Get-PowerCLIContext
	$Hosts | ForEach-Object -Parallel  {
		Use-PowerCLIContext -PowerCLIContext $Using:pcliContext -SkipImportModuleChecks
		Write-Output "Stopping $_"
		Stop-VM $_ -Confirm:$false | Out-Null
		Remove-VM -VM $_ -DeletePermanently -Confirm:$False | Out-Null
		Write-Output "VM $_ Destroyed"
		Start-Sleep -Seconds 5
	} -ThrottleLimit 5
	. .\connect-vc.ps1 -VCServer $VCenter -Disconnect
	exit 1
}

# Fetch OVA from Content Library and Launch VM
$ova = Get-ContentLibraryItem -ContentLibrary $ContentLibrary -Name $SourceOva

# Get OS customization spec
$CustomSpec = Get-OSCustomizationSpec $OSCustomSpec
$pcliContext = Get-PowerCLIContext
$Hosts | ForEach-Object -Parallel  {
	Use-PowerCLIContext -PowerCLIContext $Using:pcliContext -SkipImportModuleChecks
	Write-Output "Launching $_"
	New-VM -ContentLibraryItem $Using:ova -Name $_ -ResourcePool $Using:Cluster -Datastore $Using:Datastore -Location $Using:Folder -Confirm:$false | Out-Null
	$VM = Get-VM $_
	Set-VM $VM -OSCustomizationSpec $Using:CustomSpec -Notes $Using:CustomNotes -Confirm:$false | Out-Null
	$VM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $Using:NetworkName -Confirm:$false | Out-Null
	Start-VM $VM | Out-Null
	Write-Output "VM $_ Started"
	Start-Sleep -Seconds 5
} -ThrottleLimit 5

. .\connect-vc.ps1 -VCServer $VCenter -Disconnect