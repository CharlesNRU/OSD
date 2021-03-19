<#
.SYNOPSIS
Clear, Initialize, 2 Partition, and Format a USB Disk for use with OSDCloud

.Description
Clear, Initialize, 2 Partition, and Format a USB Disk for use with OSDCloud

.PARAMETER WorkspacePath
Directory for the Workspace.  Contains the Media directory

.LINK
https://osdcloud.osdeploy.com

.NOTES
21.3.18     Initial Release
#>
function New-OSDCloud.usb {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$WorkspacePath
    )
    #=======================================================================
    #	Start the Clock
    #=======================================================================
    $osdcloudusbStartTime = Get-Date
    #=======================================================================
    #	Block
    #=======================================================================
    Block-StandardUser
    Block-WindowsMajorLt10
    Block-PowerShellVersionLt5
    Block-WindowsReleaseIdLt1703
    #=======================================================================
    #	Set Variables
    #=======================================================================
    $ErrorActionPreference = 'Stop'
    $BootLabel = 'USBBoot'
    $DataLabel = 'OSDCloud'
    #=======================================================================
    #	Set WorkspacePath
    #=======================================================================
    if ($PSBoundParameters.ContainsKey('WorkspacePath')) {
        Set-OSDCloud.workspace -WorkspacePath $WorkspacePath -ErrorAction Stop | Out-Null
    }
    $WorkspacePath = Get-OSDCloud.workspace -ErrorAction Stop
    #=======================================================================
    #	Setup Workspace
    #=======================================================================
    if (-NOT ($WorkspacePath)) {
        Write-Warning "You need to provide a path to your Workspace with one of the following examples"
        Write-Warning "New-OSDCloud.iso -WorkspacePath C:\OSDCloud"
        Write-Warning "New-OSDCloud.workspace -WorkspacePath C:\OSDCloud"
        Break
    }

    if (-NOT (Test-Path $WorkspacePath)) {
        New-OSDCloud.workspace -WorkspacePath $WorkspacePath -Verbose -ErrorAction Stop
    }

    if (-NOT (Test-Path "$WorkspacePath\Media")) {
        New-OSDCloud.workspace -WorkspacePath $WorkspacePath -Verbose -ErrorAction Stop
    }

    if (-NOT (Test-Path "$WorkspacePath\Media\sources\boot.wim")) {
        Write-Warning "Nothing is going well for you today my friend"
        Break
    }
    #=======================================================================
    #	New-Bootable.usb
    #=======================================================================
    $NewOSDBootUSB = New-Bootable.usb -DataLabel 'OSDCloud'
    #=======================================================================
    #	Get-Partition.usb
    #=======================================================================
    $GetUSBBootPartition = Get-Partition.usb | Where-Object {($_.DiskNumber -eq $NewOSDBootUSB.DiskNumber) -and ($_.PartitionNumber -eq 2)}
    if (-NOT ($GetUSBBootPartition)) {
        Write-Warning "Something went very very wrong in this process"
        Break
    }
    $GetUSBDataPartition = Get-Partition.usb | Where-Object {($_.DiskNumber -eq $NewOSDBootUSB.DiskNumber) -and ($_.PartitionNumber -eq 1)}
    if (-NOT ($GetUSBDataPartition)) {
        Write-Warning "Something went very very wrong in this process"
        Break
    }
    #=======================================================================
    #	Copy OSDCloud
    #=======================================================================
    if ((Test-Path -Path "$WorkspacePath\Media") -and (Test-Path -Path "$($GetUSBBootPartition.DriveLetter):\")) {
        robocopy "$WorkspacePath\Media" "$($GetUSBBootPartition.DriveLetter):\" *.* /e /ndl /njh /njs /np /b
    }
    if (Test-Path -Path "$WorkspacePath\AutoPilot") {
        robocopy "$WorkspacePath\AutoPilot" "$($GetUSBDataPartition.DriveLetter):\OSDCloud\AutoPilot" *.* /e /ndl /njh /njs /np /b
    }
    #=======================================================================
    #	Complete
    #=======================================================================
    $osdcloudusbEndTime = Get-Date
    $osdcloudusbTimeSpan = New-TimeSpan -Start $osdcloudusbStartTime -End $osdcloudusbEndTime
    Write-Host -ForegroundColor DarkGray    "========================================================================="
    Write-Host -ForegroundColor Yellow      "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) $($MyInvocation.MyCommand.Name) " -NoNewline
    Write-Host -ForegroundColor Cyan        "Completed in $($osdcloudusbTimeSpan.ToString("mm' minutes 'ss' seconds'"))"
    #=======================================================================
}