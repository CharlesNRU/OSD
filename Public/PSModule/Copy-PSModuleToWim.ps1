<#
.SYNOPSIS
Copies the latest installed named PowerShell Module to a Windows Image .wim file (Mount | Copy | Dismount -Save)

.DESCRIPTION
Copies the latest installed named PowerShell Module to a Windows Image .wim file (Mount | Copy | Dismount -Save)

.PARAMETER ExecutionPolicy
Specifies the new execution policy. The acceptable values for this parameter are:
- Restricted. Does not load configuration files or run scripts. Restricted is the default execution policy.
- AllSigned. Requires that all scripts and configuration files be signed by a trusted publisher, including scripts that you write on the local computer.
- RemoteSigned. Requires that all scripts and configuration files downloaded from the Internet be signed by a trusted publisher.
- Unrestricted. Loads all configuration files and runs all scripts. If you run an unsigned script that was downloaded from the Internet, you are prompted for permission before it runs.
- Bypass. Nothing is blocked and there are no warnings or prompts.
- Undefined. Removes the currently assigned execution policy from the current scope. This parameter will not remove an execution policy that is set in a Group Policy scope.

.PARAMETER ImagePath
Specifies the location of the WIM or VHD file containing the Windows image you want to mount.

.PARAMETER Index
Index of the WIM to Mount
Default is 1

.PARAMETER Name
Name of the PowerShell Module to Copy

.LINK
https://osd.osdeploy.com/module/functions/psmodule/copy-psmoduletowim

.NOTES
21.2.9  Initial Release
#>
function Copy-PSModuleToWim {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Restricted','AllSigned','RemoteSigned','Unrestricted','Bypass','Undefined')]
        [string]$ExecutionPolicy,

        [Parameter(Mandatory = $true,ValueFromPipelineByPropertyName)]
        [string[]]$ImagePath,

        [Parameter(ValueFromPipelineByPropertyName)]
        [UInt32]$Index = 1,

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [SupportsWildcards()]
        [String[]]$Name
    )

    begin {
        #=======================================================================
        #	Require WinOS
        #=======================================================================
        if ((Get-OSDGather -Property IsWinPE)) {
            Write-Warning "$($MyInvocation.MyCommand) cannot be run from WinPE"
            Break
        }
        #=======================================================================
        #   Require Admin Rights
        #=======================================================================
        if ((Get-OSDGather -Property IsAdmin) -eq $false) {
            Write-Warning "$($MyInvocation.MyCommand) requires Admin Rights ELEVATED"
            Break
        }
        #=======================================================================
    }
    process {
        foreach ($Input in $ImagePath) {
            #=======================================================================
            #   Mount-MyWindowsImage
            #=======================================================================
            $MountMyWindowsImage = Mount-MyWindowsImage -ImagePath $Input -Index $Index
            #=======================================================================
            #   Copy-PSModuleToFolder
            #=======================================================================
            Copy-PSModuleToFolder -Name $Name -Destination "$($MountMyWindowsImage.Path)\Program Files\WindowsPowerShell\Modules" -RemoveOldVersions
            #=======================================================================
            #   Set-WindowsImageExecutionPolicy
            #=======================================================================
            if ($ExecutionPolicy) {
                Set-WindowsImageExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Path $MountMyWindowsImage.Path
            }
            #=======================================================================
            #   Dismount-MyWindowsImage
            #=======================================================================
            $MountMyWindowsImage | Dismount-MyWindowsImage -Save
            #=======================================================================
        }
    }
    end {}
}