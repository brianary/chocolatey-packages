import-module au
. $PSScriptRoot\..\_scripts\all.ps1

$releases    = 'https://github.com/arp242/uni/releases'

function global:au_SearchReplace {
   @{
        ".\tools\chocolateyInstall.ps1" = @{
            "(?i)(^\s*[$]packageName\s*=\s*)('.*')"= "`$1'$($Latest.PackageName)'"
            "(?i)(^\s*[$]fileType\s*=\s*)('.*')"   = "`$1'$($Latest.FileType)'"
        }

        "$($Latest.PackageName).nuspec" = @{
            "(\<releaseNotes\>).*?(\</releaseNotes\>)" = "`${1}$($Latest.ReleaseNotes)`$2"
        }

        ".\legal\VERIFICATION.txt" = @{
          "(?i)(\s+x32:).*"            = "`${1} $($Latest.URL32)"
          "(?i)(checksum32:).*"        = "`${1} $($Latest.Checksum32)"
          "(?i)(Get-RemoteChecksum).*" = "`${1} $($Latest.URL32)"
        }
    }
}

function global:au_BeforeUpdate { Get-RemoteFiles -Purge }
function global:au_AfterUpdate
{
    Set-DescriptionFromReadme -SkipFirst 2
    Push-Location tools
    7z x uni-v*-windows-amd64.exe_x64.gz
    Move-Item .\uni-v*-windows-amd64.exe uni.exe -Force
    Remove-Item uni-v*-windows-amd64.exe_x64.gz -Force
    Pop-Location
}

function global:au_GetLatest {
    $download_page = Invoke-WebRequest -Uri $releases -UseBasicParsing

    $re  = "uni-v.*-windows-amd64\.exe\.gz"
    $url = $download_page.links | ? href -match $re | select -First 1 -expand href
    $url = 'https://github.com' + $url

    $version = $url -split '-|.exe' | select -First 1 -Skip 1

    return @{
        URL64        = $url
        Version      = $version.Trim('v')
        
        ReleaseNotes = "$releases/tag/${version}"
    }
}

update -ChecksumFor none
