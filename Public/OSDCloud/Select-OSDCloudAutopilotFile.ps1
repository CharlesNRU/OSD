<#
.SYNOPSIS
Selects AutoPilot Profiles

.DESCRIPTION
Selects AutoPilot Profiles

.LINK
https://osdcloud.osdeploy.com

.NOTES
21.3.12  Initial Release
#>
function Select-OSDCloudAutopilotFile {
    [CmdletBinding()]
    param ()

    $i = $null
    $GetOSDCloudOfflineAutoPilotProfiles = Find-OSDCloudAutopilotFile

    if ($GetOSDCloudOfflineAutoPilotProfiles) {
        $AutoPilotProfiles = foreach ($Item in $GetOSDCloudOfflineAutoPilotProfiles) {
            $i++
            $JsonConfiguration = Get-Content -Path $Item.FullName | ConvertFrom-Json

            $ObjectProperties = @{
                Selection           = $i
                Name                = $Item.Name
                FullName            = $Item.FullName
                Profile             = $JsonConfiguration.Comment_File
                Tenant              = $JsonConfiguration.CloudAssignedTenantDomain
                ZtdCorrelationId    = $JsonConfiguration.ZtdCorrelationId
                FullContent         = $JsonConfiguration
            }
            New-Object -TypeName PSObject -Property $ObjectProperties
        }

        $AutoPilotProfiles | Select-Object -Property Selection, Profile, FullName | Format-Table | Out-Host

        do {
            $SelectReadHost = Read-Host -Prompt "Enter the Selection of the AutoPilot Profile to apply, or press S to Skip"
        }
        until (((($SelectReadHost -ge 0) -and ($SelectReadHost -in $AutoPilotProfiles.Selection -or ($SelectReadHost -eq 'S')))))
        
        if ($SelectReadHost -eq 'S') {
            Return $false
        }
        $AutoPilotProfiles = $AutoPilotProfiles | Where-Object {$_.Selection -eq $SelectReadHost}

        Return $AutoPilotProfiles.FullContent
    }
}