<#
  .SYNOPSIS
    Updates the Download Count for my PSGallery Badge
#>

Function Get-PSGalleryDownloads() {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.String[]] $PackageName
    )
    begin {

    }
    Process {
        try {
            $TotalDownloads = 0
            $ReturnObject = @{
                Total = $TotalDownloads
            }
            $PackageName | ForEach-Object {
                $PackageDownloads = $null
                Write-Verbose "PackageName: $_"
                $URL = "https://img.shields.io/powershellgallery/dt/$_.json"
                Write-Verbose $URL
                $PackageDownloads = (((Invoke-WebRequest $Url) | ConvertFrom-Json).Value)
                Write-Verbose "$_ downloads: $PackageDownloads"
                switch ($PackageDownloads) {
                    { $_ -match 'k' } {
                        $PackageDownloadsInt = [math]::Round([float]$PackageDownloads.Split('k')[0] * 1000)
                        $TotalDownloads = $TotalDownloads + $PackageDownloadsInt
                    } { $_ -match 'm' } {
                        $PackageDownloadsInt = [math]::Round([float]$PackageDownloads.Split('k')[0] * 1000000)
                        $TotalDownloads = $TotalDownloads + $PackageDownloadsInt
                    } DEFAULT {
                        $TotalDownloads = $TotalDownloads + $PackageDownloads
                    }
                }

                Write-Verbose "CurrentTotal: $TotalDownloads"
                $ReturnObject["$_"] = $PackageDownloads
            }
            $ReturnObject['Total'] = $TotalDownloads
            $ReturnObject
        } catch {
        }
    }
    end {}
}

Function Get-CurrentProfileDownloadsValue() {
    (((Invoke-WebRequest 'https://raw.githubusercontent.com/jimbrig/jimbrig/main/TEMPLATE.md').Content | Select-String -Pattern '-~(\d+|\d{1,3}(,\d{3})*)(\.\d+)?-').matches.value -replace '-') -replace '~'
}

$PSGalleryPackages = @(
    'Add-GodModeShortcut'
    'ConvertTo-Markdown'
    'ConvertTo-NuSpec'
    'Export-PowerCfg'
    'Extract-DacPac'
    'Extract-IconFromExe'
    'Format-ShortDateRegistry'
    'Get-GitHubRelease'
    'Get-InstalledApps'
    'Get-OLEDBProvider'
    'Install-1PasswordCLI'
    'Install-NerdFont'
    'Install-OfficeRibbonXEditor'
    'Invoke-CompactWSLDisk'
    'New-RestorePoint'
    'New-TrayNotify'
    'PSClearHost'
    'PSEdgeKeywords'
    'PSWindowsTroubleShooters'
    'PSXLDevTools'
    'Read-HostSecret'
    'Remove-OldDrivers'
    'Set-FolderIcon'
    'Set-OfficeInsider'
    'Test-IsAdmin'
    'Update-PSModules'
    'Set-FolderIcon'
    'Export-PowerQuery'
    'Get-GitHubRelease'
    'ConvertTo-NuSpec'
    'Trace-NetworkAdapter'
    'Extract-DacPac'    
)

$PSGalleryDownloads = (Get-PSGalleryDownloads -PackageName $PSGalleryPackages).Total
$ProfileDownloads = Get-CurrentProfileDownloadsValue
Write-Output "Current PSGallery Downloads : $PSGalleryDownloads"
Write-Output "Current Profile Downloads   : $ProfileDownloads"


if ($PSGalleryDownloads -gt $ProfileDownloads) {
    ## NEED TO UPDATE LINK IN README
    Write-Output 'Updating Git Profile README.ME badge.'
    $FormatedDownloadsNum = [String]::Format('{0:N0}', $PSGalleryDownloads)
    $Readme_path = [System.IO.Path]::Combine($GITHUB_WORKSPACE, 'TEMPLATE.md')
    $OriginalREADME_CONTENT = Get-Content $Readme_path
    $NewREADME_CONTENT = $OriginalREADME_CONTENT -replace '-~(\d+|\d{1,3}(,\d{3})*)(\.\d+)?-', "-~$FormatedDownloadsNum`-"
    Set-Content -Path $Readme_path -Value $NewREADME_CONTENT
    git config --local user.name 'Jimmy Briggs'
    git config --local user.email 'jimmy.briggs@jimbrig.com'
    git commit -m "chore: Updating PSGallery Downloads badge from $ProfileDownloads to $FormatedDownloadsNum" -a
    try {
        git push --quiet
    } catch {}
}
