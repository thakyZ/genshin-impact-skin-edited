using namespace System;
using namespace System.Collections.ObjectModel;
using namespace System.Management.Automation;
using namespace System.IO;

[CmdletBinding(DefaultParameterSetName = "Setup")]
Param(
  # Specifies a parameter to clean the build environment.
  [Parameter(Mandatory = $False, HelpMessage = "Cleans the build environment.", ParameterSetName = "Clean")]
  [switch]
  $Clean,
  # Specifies a parameter to perform the setup task for the build environment.
  [Parameter(Mandatory = $False, HelpMessage = "Performs the setup task for the build environment.", ParameterSetName = "Setup")]
  [Alias("Init")]
  [switch]
  $Setup,
  # Specifies a parameter to perform the build task.
  [Parameter(Mandatory = $False, HelpMessage = "Performs the build task.", ParameterSetName = "Build")]
  [Alias("Compile")]
  [switch]
  $Build,
  # Specifies a parameter to perform the install task.
  [Parameter(Mandatory = $False, HelpMessage = "Performs the install task.", ParameterSetName = "Install")]
  [switch]
  $Install
)

DynamicParam {
  [ParameterAttribute] $ModAttribute = [ParameterAttribute]::new();
  $ModAttribute.Position = 0;
  $ModAttribute.Mandatory = $True;
  $ModAttribute.HelpMessage = "The mod to run this task with.";
  [FileSystemInfo[]] $Items = (Get-ChildItem -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..') | Where-Object { (Get-ChildItem -LiteralPath $_ | Where-Object { Return $_.Name -eq 'info.json' }).Count -eq 1 });
  [string[]] $ModFolders = $Items.Name;
  [ValidateSetAttribute] $ValidateSetAttribute = [ValidateSetAttribute]::new($ModFolders);
  [Collection[Attribute]] $AttributeCollection = [Collection[Attribute]]::new();
  $AttributeCollection.Add($ModAttribute);
  $AttributeCollection.Add($ValidateSetAttribute);
  [RuntimeDefinedParameter] $ModParam = [RuntimeDefinedParameter]::new('Mod', [string], $AttributeCollection);
  $ParamDictionary = [RuntimeDefinedParameterDictionary]::new();
  $ParamDictionary.Add('Mod', $ModParam);
  return $ParamDictionary;
} Begin {
  [string]        $script:Mod = $PSBoundParameters.Mod;
  [DirectoryInfo] $script:ProjectDir     = (Get-Item -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath ".."));
  [DirectoryInfo] $script:ModDirectory   = (Get-Item -LiteralPath (Join-Path -Path $script:ProjectDir -ChildPath $Mod));
  [FileInfo]      $script:ModInfo        = (Get-Item -LiteralPath (Join-Path -Path $script:ModDirectory -ChildPath "info.json"));
  [string]        $script:BuildDirectory = (Join-Path -Path $script:ProjectDir -ChildPath "build");
  [string]        $script:TempDirectory  = (Join-Path -Path $script:ProjectDir -ChildPath ".temp");

  Function Get-CurrentVersion {
    [CmdletBinding()]
    Param()

    If (-not (Test-Path -LiteralPath $script:ModInfo -PathType Leaf)) {
      Throw "Failed to find ``info.json`` file in folder: `"$($script:ModInfo.FullName)`""
    }

    [Hashtable] $Json = (Get-Content -LiteralPath $script:ModInfo | ConvertFrom-Json -AsHashtable -Depth 2);
    Return $Json.version;
  }

  $script:Version = Get-CurrentVersion;

  Function Invoke-Clean() {
    [CmdletBinding()]
    Param()

    Remove-Item -LiteralPath $script:BuildDirectory -Recurse -ErrorAction Continue;
    Remove-Item -LiteralPath $script:TempDirectory -Recurse -ErrorAction Continue;
  }

  Function Invoke-Setup() {
    Param()

    If (-not [Directory]::Exists($script:BuildDirectory)) {
      New-Item -Path $script:BuildDirectory -ItemType Directory | Out-Null
    }
  }

  Function Invoke-Build() {
    Param(
      # Specifies to instead run the command with only the native windows compress archive.
      [Parameter(Mandatory = $False, HelpMessage = "Run the command with only the native windows compress archive.")]
      [switch]
      $NativeOnly = $False
    )

    $DisableRemove = $False;

    If (-not [Directory]::Exists($script:BuildDirectory)) {
      Invoke-Setup;
    }

    If ($NativeOnly -eq $False) {
      Copy-Item -Recurse -Path $script:ModDirectory -Destination $script:BuildDirectory;
      Rename-Item -LiteralPath (Join-Path -Path $script:BuildDirectory -ChildPath $script:Mod) -NewName "$($script:Mod)_$($script:Version)";
    }

    If ($NativeOnly -eq $False -and $Null -ne (Get-Module -Name "7Zip4Powershell" -ErrorAction SilentlyContinue)) {
      Try {
        Import-Module "7Zip4Powershell";
        Compress-7Zip -ArchiveFileName (Join-Path -Path $script:BuildDirectory -ChildPath "$($script:Mod)_$($script:Version).zip") -Path (Join-Path -Path $script:BuildDirectory -ChildPath "$($script:Mod)_$($script:Version)") -Format "Zip" -CompressionLevel "Normal" -TempFolder "$($script:TempDirectory)" -SkipEmptyDirectories
      } Catch {
        Write-Error -Exception $_.Exception -Message "Failed to import module `"7Zip4Powershell`" or failed to compress 7-Zip."
        $DisableRemove = $True;
      }
    } Else {
      Compress-Archive -LiteralPath (Get-ChildItem -LiteralPath $script:ModDirectory) -DestinationPath (Join-Path -Path $script:BuildDirectory -ChildPath "$($script:Mod)_$($script:Version).zip");
    }

    If ($DisableRemove -eq $False) {
      Remove-Item -Recurse -LiteralPath (Join-Path -Path $script:BuildDirectory -ChildPath "$($script:Mod)_$($script:Version)");
    } Else {
      Invoke-Build -NativeOnly;
    }
  }

  Function Invoke-Install() {
    [CmdletBinding()]
    Param()

    If (-not (Test-Path -LiteralPath (Join-Path -Path  $script:BuildDirectory -ChildPath "$($script:Mod)_$($script:Version).zip") -PathType Leaf)) {
      Invoke-Build;
    }

    Copy-Item -LiteralPath (Join-Path -Path  $script:BuildDirectory -ChildPath "$($script:Mod)_$($script:Version).zip") -Destination (Join-Path -Path $env:AppData -ChildPath "Factorio" -AdditionalChildPath @("mods"))
  }
} Process {
  If ($PSCmdlet.ParameterSetName -eq "Setup") {
    Invoke-Setup;
  } ElseIf ($PSCmdlet.ParameterSetName -eq "Clean") {
    Invoke-Clean;
  } ElseIf ($PSCmdlet.ParameterSetName -eq "Build") {
    Invoke-Build;
  } ElseIf ($PSCmdlet.ParameterSetName -eq "Install") {
    Invoke-Install;
  }
} End {

}