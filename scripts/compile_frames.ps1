Param(
  # Specifies to use preview mode on Aseprite operations.
  [Parameter(Mandatory = $False, HelpMessage = "Use preview mode on Aseprite operations.")]
  [switch]
  $Preview
)

$Folders = (Get-ChildItem -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("src", "images")) | Where-Object { (Get-ChildItem -LiteralPath $_.FullName -Filter "*.png").Length -eq 275 })

ForEach ($Folder in $Folders) {
  Try {
    $Null = (New-Item -Path (Join-Path -Path $Folder.FullName -ChildPath "idle") -ItemType Directory);
  } Catch {
    Write-Error -Exception $_.Exception -Message "Failed to create new folder at path `"$(Join-Path -Path $Folder.FullName -ChildPath "idle")`"";
    Exit 1;
  }
  Try {
    $Null = (New-Item -Path (Join-Path -Path $Folder.FullName -ChildPath "run") -ItemType Directory);
  } Catch {
    Write-Error -Exception $_.Exception -Message "Failed to create new folder at path `"$(Join-Path -Path $Folder.FullName -ChildPath "run")`"";
    Exit 1;
  }

  $ItemsAll = (Get-ChildItem -LiteralPath $Folder.FullName -Filter "*.png");
  $ItemsForRun = ($ItemsAll | Where-Object { [int]::Parse($_.BaseName) -le 160 });
  ForEach ($Item in $ItemsForRun) {
    Try {
      Move-Item -LiteralPath $Item.FullName -Destination (Join-Path -Path $Folder.FullName -ChildPath "run" -AdditionalChildPath @("$($Item.Name)"));
    } Catch {
      Write-Error -Exception $_.Exception -Message "Failed to move item from path `"$($Item.FullName)`" to `"$(Join-Path -Path $Folder.FullName -ChildPath "run" -AdditionalChildPath @("$($Item.Name)"))`"";
      Exit 1;
    }
  }
  $ItemsForIdle = ($ItemsAll | Where-Object { [int]::Parse($_.BaseName) -ge 161 -and [int]::Parse($_.BaseName) -le 272 });
  For ($Index = 0; $Index -lt $ItemsForIdle.Length; $Index++) {
    $Item = $ItemsForIdle[$Index];
    Try {
      Move-Item -LiteralPath $Item.FullName -Destination (Join-Path -Path $Folder.FullName -ChildPath "idle" -AdditionalChildPath @("$($Item.Name)"));
    } Catch {
      Write-Error -Exception $_.Exception -Message "Failed to move item from path `"$($Item.FullName)`" to `"$(Join-Path -Path $Folder.FullName -ChildPath "idle" -AdditionalChildPath @("$($Item.Name)"))`"";
      Exit 1;
    }
    Try {
      Rename-Item -LiteralPath (Join-Path -Path $Folder.FullName -ChildPath "idle" -AdditionalChildPath @("$($Item.Name)")) -NewName "$($Index).png";
    } Catch {
      Write-Error -Exception $_.Exception -Message "Failed to rename item at path `"$(Join-Path -Path $Folder.FullName -ChildPath "idle" -AdditionalChildPath @("$($Item.Name)"))`" to new name `"$($Index).png`"";
      Exit 1;
    }
  }
  Try {
    Rename-Item -LiteralPath (Join-Path -Path $Folder.FullName -ChildPath "273.png") -NewName "icon.png";
  } Catch {
    Write-Error -Exception $_.Exception -Message "Failed to rename item at path `"$(Join-Path -Path $Folder.FullName -ChildPath "273.png")`" to new name `"icon.png`"";
    Exit 1;
  }
  Try {
    Rename-Item -LiteralPath (Join-Path -Path $Folder.FullName -ChildPath "274.png") -NewName "dead.png";
  } Catch {
    Write-Error -Exception $_.Exception -Message "Failed to rename item at path `"$(Join-Path -Path $Folder.FullName -ChildPath "274.png")`" to new name `"icon.png`"";
    Exit 1;
  }
  Try {
    Rename-Item -LiteralPath (Join-Path -Path $Folder.FullName -ChildPath "275.png") -NewName "unknown.png";
  } Catch {
    Write-Error -Exception $_.Exception -Message "Failed to rename item at path `"$(Join-Path -Path $Folder.FullName -ChildPath "275.png")`" to new name `"icon.png`"";
    Exit 1;
  }
}

$Folders2 = (Get-ChildItem -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath @("src", "images")) -Directory | Where-Object {
    [bool]$Output = $False;
    ForEach ($Folder in (Get-ChildItem -LiteralPath $_.FullName -Directory)) {
      If (-not (Test-Path -LiteralPath "$($Folder.FullName).png" -PathType Leaf)) {
        [bool]$Output += $True;
      }
    }
    Return $Output;
  });

Function Get-AsepriteCommand() {
  Param()

  $Output = (Get-Command -Name "aseprite" -ErrorAction SilentlyContinue);

  If ($Null -eq $Output) {
    $Drives = (Get-PSDrive | Where-Object { $_.Root -match "^\w:\\$" });
    ForEach ($Drive in $Drives) {
      If (Test-Path -LiteralPath (Join-Path -Path $Drives.Root -ChildPath "Program Files" -AdditionalChildPath @("Aseprite", "aseprite.exe")) -PathType Leaf) {
        $Output = (Get-Command (Join-Path -Path $Drives.Root -ChildPath "Program Files" -AdditionalChildPath @("Aseprite", "aseprite.exe")) -ErrorAction SilentlyContinue);
        Break;
      }
    }
  }

  Return $Output;
}

$Aseprite = (Get-AsepriteCommand);

ForEach ($Folder2 in $Folders2) {
  Write-Host "Running task on $($Folder2.Name)"
  ForEach ($SubFolder in (Get-ChildItem -LiteralPath $Folder2.FullName -Directory)) {
    Write-Host "  Running sub-task on $($SubFolder.Name)"
    If (-not (Test-Path -LiteralPath "$($SubFolder.FullName).png")) {
      $Columns = -1;
      If ($PSVersionTable.PSVersion.Major -ge 6) {
        $Columns = ($SubFolder.BaseName -eq "idle" ? ((Get-ChildItem -LiteralPath $SubFolder.FullName -Filter "*.png").Length -eq 256 ? 64 : 28) : ($SubFolder.BaseName -eq "run" ? 20 : -1));
      } Else {
        If ($SubFolder.BaseName -eq "idle") {
          $Columns = 64;
        } ElseIf ($SubFolder.BaseName -eq "run") {
          $Columns = 20;
        } Else {
          $Columns = -1;
        }
      }
      $Arguments = @("--sheet `"$($SubFolder.FullName).png`"");
      If ($Preview) {
        $Arguments += $PreviewTemp;
      }
      $Arguments += @("--batch", "--sheet-type rows", "--sheet-columns $($Columns)");
      ForEach ($Item in (Get-ChildItem -LiteralPath $SubFolder.FullName -Filter "*.png")) {
        $Arguments += $Item.FullName;
      }
      $Process = (Start-Process -NoNewWindow -FilePath $Aseprite.Source -ArgumentList $Arguments -PassThru -RedirectStandardOutput (Join-Path -Path $PSScriptRoot -ChildPath "aseprite_output.log"));
      Wait-Process -Id $Process.Id;
      Remove-Item -Path "aseprite_output.log" -ErrorAction SilentlyContinue;
    }
  }
}