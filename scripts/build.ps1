[CmdletBinding(DefaultParameterSetName = "Setup")]
Param(
  # Specifies a parameter to clean the build environment.
  [Parameter(Mandatory = $False, HelpMessage = "Cleans the build environment.", ParameterSetName = "Clean")]
  [Alias("C", "-Clean")]
  [switch]
  $Clean,
  # Specifies a parameter to perform the setup task for the build environment.
  [Parameter(Mandatory = $False, HelpMessage = "Performs the setup task for the build environment.", ParameterSetName = "Setup")]
  [Alias("Init", "-Init", "S", "-Setup")]
  [switch]
  $Setup,
  # Specifies a parameter to perform the build task.
  [Parameter(Mandatory = $False, HelpMessage = "Performs the build task.", ParameterSetName = "Build")]
  [Alias("B", "-Build", "Compile", "-Compile")]
  [switch]
  $Build,
  # Specifies a parameter to perform the install task.
  [Parameter(Mandatory = $False, HelpMessage = "Performs the install task.", ParameterSetName = "Install")]
  [Alias("I")]
  [switch]
  $Install
)

Function Get-CurrentVersion() {
  Param()

  If (-not (Test-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("src", "info.json")) -PathType Leaf)) {
    Throw "Failed to find `info.json` file in folder: `"$(Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("src", "info.json")))`""
  }

  $Json = (Get-Content -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("src", "info.json")) | ConvertFrom-Json);
  Return $Json.version;
}

$script:Version = Get-CurrentVersion;

Function Invoke-Clean() {
  Param()

  Remove-Item -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("build")) -Recurse -ErrorAction SilentlyContinue;
  Remove-Item -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @(".temp")) -Recurse -ErrorAction SilentlyContinue;
}

Function Invoke-Setup() {
  Param()

  $Null = (New-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("build")) -ItemType Directory);
}

Function Invoke-Build() {
  Param(
    # Specifies to instead run the command with only the native windows compress archive.
    [Parameter(Mandatory = $False, HelpMessage = "Run the command with only the native windows compress archive.")]
    [switch]
    $NativeOnly = $False
  )

  $DisableRemove = $False;

  If (-not (Test-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("build")) -PathType Container)) {
    Invoke-Setup;
  }

  If ($NativeOnly -eq $False) {
    Copy-Item -Recurse -Path (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("src")) -Destination (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("build"));
    Rename-Item -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("build", "src")) -NewName "genshin-impact-skin-edited_$($script:Version)";
  }

  If ($NativeOnly -eq $False -and $Null -ne (Get-Module "7Zip4Powershell")) {
    Try {
      Import-Module "7Zip4Powershell";
      Compress-7Zip -ArchiveFileName (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("build", "genshin-impact-skin-edited_$($script:Version).zip")) -Path (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("build", "genshin-impact-skin-edited_$($script:Version)")) -Format "Zip" -CompressionLevel "Normal" -TempFolder "$((Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @(".temp")))" -SkipEmptyDirectories
    } Catch {
      Write-Error -Exception $_.Exception -Message "Failed to import module `"7Zip4Powershell`" or failed to compress 7-Zip."
      $DisableRemove = $True;
    }
  } Else {
    Compress-Archive -LiteralPath (Get-ChildItem -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("src"))) -DestinationPath (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("build", "genshin-impact-skin-edited_$($script:Version).zip"));
  }

  If ($DisableRemove -eq $False) {
    Remove-Item -Recurse -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("build", "genshin-impact-skin-edited_$($script:Version)"));
  } Else {
    Invoke-Build -NativeOnly;
  }
}

Function Invoke-Install() {
  Param()

  If (-not (Test-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("build", "genshin-impact-skin-edited_$($script:Version).zip")) -PathType Leaf)) {
    Invoke-Build;
  }

  Copy-Item -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("build", "genshin-impact-skin-edited_$($script:Version).zip")) -Destination (Join-Path -Path $env:AppData -ChildPath "Factorio" -AdditionalChildPath @("mods"))
}

Function Invoke-Init() {
  Param()

  If ($PSCmdlet.ParameterSetName -eq "Setup") {
    Invoke-Setup;
  } ElseIf ($PSCmdlet.ParameterSetName -eq "Clean") {
    Invoke-Clean;
  } ElseIf ($PSCmdlet.ParameterSetName -eq "Build") {
    Invoke-Build;
  } ElseIf ($PSCmdlet.ParameterSetName -eq "Install") {
    Invoke-Install;
  }
}

Invoke-Init;