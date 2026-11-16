<#
================================================================================
Script de Compilação e Criação de Instalador Windows (.msi e .zip)
DV Max - Desktop Media Client & File Organizer
================================================================================
Uso no PowerShell (Windows 10/11 ou CI):
  .\scripts\build_windows.ps1
  .\scripts\build_windows.ps1 -SkipBuild
  .\scripts\build_windows.ps1 -RequireMsi
================================================================================
#>

[CmdletBinding()]
param (
    [switch]$SkipBuild,
    [switch]$RequireMsi,
    [string]$Architecture = "x64"
)

$ErrorActionPreference = "Stop"
# Compress-Archive fica lento no Windows PowerShell quando desenha o progresso.
$ProgressPreference = "SilentlyContinue"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $true
}

function Assert-NativeExit {
    param([string]$Step)
    if ($LASTEXITCODE -ne 0) {
        throw "$Step falhou com código $LASTEXITCODE."
    }
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
Set-Location $RootDir

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "          DV Max - Build & Packaging para Windows (.msi)         " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Extrair versão do pubspec.yaml
if (-not (Test-Path "pubspec.yaml")) {
    Write-Error "pubspec.yaml não encontrado na raiz ($RootDir)."
    exit 1
}

$PubspecContent = Get-Content "pubspec.yaml" -Raw
if ($PubspecContent -match 'version:\s*([0-9]+\.[0-9]+\.[0-9]+)(\+([0-9]+))?') {
    $SemVer = $Matches[1]
    $BuildNum = if ($Matches[3]) { $Matches[3] } else { "1" }
} else {
    $SemVer = "1.0.0"
    $BuildNum = "1"
}

# Versão de 4 dígitos exigida pelo Windows Installer (ex: 1.1.0.2)
$MsiVersion = "$SemVer.$BuildNum"

Write-Host "Versão detectada: $SemVer (Build: $BuildNum - MSI: $MsiVersion)" -ForegroundColor Green

# 2. Compilar aplicação com Flutter
$ReleaseDir = Join-Path $RootDir "build\windows\x64\runner\Release"

if (-not $SkipBuild) {
    Write-Host "`n➔ [1/4] Compilando aplicação Flutter em modo Release (Windows x64)..." -ForegroundColor Cyan
    flutter build windows --release
    Assert-NativeExit "flutter build windows"
} else {
    Write-Host "`n➔ [1/4] Pulando compilação (-SkipBuild solicitado)." -ForegroundColor Yellow
}

if (-not (Test-Path $ReleaseDir)) {
    Write-Error "Diretório de build não encontrado em: $ReleaseDir"
    exit 1
}

$DistDir = Join-Path $RootDir "dist"
if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir | Out-Null
}

# ------------------------------------------------------------------------------
# 3. Gerar Pacote Portátil .zip
# ------------------------------------------------------------------------------
Write-Host "`n➔ [2/4] Criando arquivo portátil universal (.zip)..." -ForegroundColor Cyan
$ZipName = "DV_Max_${SemVer}_windows_${Architecture}.zip"
$ZipPath = Join-Path $DistDir $ZipName

if (Test-Path $ZipPath) { Remove-Item -Force $ZipPath }
Compress-Archive -Path "$ReleaseDir\*" -DestinationPath $ZipPath -Force
Write-Host "   Pacote zip criado: $ZipName" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. Criar Instalador .msi com WiX Toolset
# ------------------------------------------------------------------------------
Write-Host "`n➔ [3/4] Empacotando instalador .msi (Windows Installer)..." -ForegroundColor Cyan
$MsiName = "DV_Max_${SemVer}_${Architecture}.msi"
$MsiPath = Join-Path $DistDir $MsiName

# Detectar WiX v4/v5 ou WiX v3
$WixExe = Get-Command "wix" -ErrorAction SilentlyContinue
$CandleExe = Get-Command "candle.exe" -ErrorAction SilentlyContinue
$LightExe = Get-Command "light.exe" -ErrorAction SilentlyContinue

$IconPath = Join-Path $RootDir "windows\runner\resources\app_icon.ico"
if (-not (Test-Path $IconPath)) {
    $IconPath = ""
}

$BuildStage = Join-Path ([System.IO.Path]::GetTempPath()) ("dv_max_msi_" + [System.Guid]::NewGuid().ToString().Substring(0,8))
New-Item -ItemType Directory -Path $BuildStage | Out-Null

try {
    if ($WixExe) {
        Write-Host "   Detectado WiX Toolset v4/v5 (wix.exe)" -ForegroundColor Green
        if (-not $IconPath) {
            throw "Ícone não encontrado em windows\runner\resources\app_icon.ico."
        }

        # WiX lê $(var.*) na hora do build. Here-string literal para o PowerShell não expandir.
        $WxsPath = Join-Path $BuildStage "dv_max.wxs"
        $WxsContent = @'
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">
  <Package Name="DV Max"
           Manufacturer="Marcus Software"
           Version="$(var.MsiVersion)"
           UpgradeCode="4a7e8b91-3c2d-4e5f-a6b7-8c9d0e1f2a3b"
           Language="1046"
           Scope="perMachine">

    <MajorUpgrade DowngradeErrorMessage="Uma versao mais recente do DV Max ja esta instalada." />
    <MediaTemplate EmbedCab="yes" />

    <Icon Id="AppIcon.ico" SourceFile="$(var.IconPath)" />
    <Property Id="ARPPRODUCTICON" Value="AppIcon.ico" />
    <Property Id="ARPHELPLINK" Value="https://github.com/marcusedu/dv_max_easy" />

    <Feature Id="MainApplication" Title="DV Max" Level="1">
      <ComponentGroupRef Id="AppFiles" />
      <ComponentRef Id="ApplicationShortcut" />
    </Feature>
  </Package>

  <Fragment>
    <StandardDirectory Id="ProgramFiles64Folder">
      <Directory Id="INSTALLFOLDER" Name="DV Max" />
    </StandardDirectory>

    <ComponentGroup Id="AppFiles" Directory="INSTALLFOLDER">
      <Files Include="$(var.SourceDir)\**" />
    </ComponentGroup>

    <StandardDirectory Id="ProgramMenuFolder">
      <Directory Id="ApplicationProgramsFolder" Name="DV Max">
        <Component Id="ApplicationShortcut" Guid="7b8a9c0d-1e2f-4a4b-8c6d-7e8f9a0b1c2d">
          <Shortcut Id="ApplicationStartMenuShortcut"
                    Name="DV Max"
                    Description="Cliente desktop para baixar video e audio"
                    Target="[INSTALLFOLDER]dv_max_easy.exe"
                    WorkingDirectory="INSTALLFOLDER"
                    Icon="AppIcon.ico" />
          <RemoveFolder Id="CleanUpShortCut" Directory="ApplicationProgramsFolder" On="uninstall" />
          <RegistryValue Root="HKLM" Key="Software\MarcusSoftware\DVMax" Name="installed" Type="integer" Value="1" KeyPath="yes" />
        </Component>
      </Directory>
    </StandardDirectory>
  </Fragment>
</Wix>
'@
        $Utf8 = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($WxsPath, $WxsContent, $Utf8)

        $SourceDir = $ReleaseDir.TrimEnd('\')
        $IconForWix = $IconPath

        Write-Host "   Compilando MSI com: wix build..." -ForegroundColor Cyan
        & wix build $WxsPath -o $MsiPath -arch $Architecture `
            -d "MsiVersion=$MsiVersion" `
            -d "SourceDir=$SourceDir" `
            -d "IconPath=$IconForWix"
        Assert-NativeExit "wix build"
        if (-not (Test-Path $MsiPath)) {
            throw "wix build terminou sem gerar $MsiPath."
        }
        Write-Host "   Instalador .msi criado com sucesso via WiX v4/v5!" -ForegroundColor Green

    } elseif ($CandleExe -and $LightExe) {
        Write-Host "   Detectado WiX Toolset v3 (candle.exe / light.exe)" -ForegroundColor Green
        if (-not $IconPath) {
            throw "Ícone não encontrado em windows\runner\resources\app_icon.ico."
        }

        $WxsPath = Join-Path $BuildStage "dv_max_v3.wxs"
        $WxsContent = @"
<?xml version="1.0" encoding="utf-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*"
           Name="DV Max"
           Language="1046"
           Version="$MsiVersion"
           Manufacturer="Marcus Software"
           UpgradeCode="4a7e8b91-3c2d-4e5f-a6b7-8c9d0e1f2a3b">

    <Package InstallerVersion="300" Compressed="yes" InstallScope="perMachine" Platform="$Architecture" />
    <MajorUpgrade DowngradeErrorMessage="Uma versao mais recente do DV Max ja esta instalada." />
    <MediaTemplate EmbedCab="yes" />

    <Icon Id="AppIcon.ico" SourceFile="$IconPath" />
    <Property Id="ARPPRODUCTICON" Value="AppIcon.ico" />
    <Property Id="ARPHELPLINK" Value="https://github.com/marcusedu/dv_max_easy" />

    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFiles64Folder">
        <Directory Id="INSTALLFOLDER" Name="DV Max" />
      </Directory>
      <Directory Id="ProgramMenuFolder">
        <Directory Id="ApplicationProgramsFolder" Name="DV Max" />
      </Directory>
    </Directory>

    <DirectoryRef Id="ApplicationProgramsFolder">
      <Component Id="ApplicationShortcut" Guid="7b8a9c0d-1e2f-4a4b-8c6d-7e8f9a0b1c2d">
        <Shortcut Id="ApplicationStartMenuShortcut"
                  Name="DV Max"
                  Description="Cliente desktop para baixar video e audio"
                  Target="[INSTALLFOLDER]dv_max_easy.exe"
                  WorkingDirectory="INSTALLFOLDER"
                  Icon="AppIcon.ico" />
        <RemoveFolder Id="CleanUpShortCut" Directory="ApplicationProgramsFolder" On="uninstall" />
        <RegistryValue Root="HKLM" Key="Software\MarcusSoftware\DVMax" Name="installed" Type="integer" Value="1" KeyPath="yes" />
      </Component>
    </DirectoryRef>

    <Feature Id="MainApplication" Title="DV Max" Level="1">
      <ComponentGroupRef Id="AppFiles" />
      <ComponentRef Id="ApplicationShortcut" />
    </Feature>
  </Product>
</Wix>
"@
        $Utf8 = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($WxsPath, $WxsContent, $Utf8)

        $HarvestWxs = Join-Path $BuildStage "files.wxs"
        & heat dir "$ReleaseDir" -cg AppFiles -dr INSTALLFOLDER -scom -sfrag -srd -ag -out "$HarvestWxs"
        Assert-NativeExit "heat"
        & candle -arch "$Architecture" -out "$BuildStage\" "$WxsPath" "$HarvestWxs"
        Assert-NativeExit "candle"
        & light -ext WixUIExtension -out "$MsiPath" "$BuildStage\dv_max_v3.wixobj" "$BuildStage\files.wixobj"
        Assert-NativeExit "light"
        if (-not (Test-Path $MsiPath)) {
            throw "light terminou sem gerar $MsiPath."
        }
        Write-Host "   Instalador .msi criado com sucesso via WiX v3!" -ForegroundColor Green

    } elseif ($RequireMsi) {
        throw "WiX Toolset não está no PATH. Instale com: dotnet tool install --global wix --version 5.0.2 e coloque %USERPROFILE%\.dotnet\tools no PATH."
    } else {
        Write-Host "`n   [AVISO] WiX Toolset não foi encontrado no PATH do sistema." -ForegroundColor Yellow
        Write-Host "   Para gerar o arquivo .msi nativo no Windows, instale o WiX com um dos comandos:" -ForegroundColor Yellow
        Write-Host "     dotnet tool install --global wix --version 5.0.2" -ForegroundColor White
        Write-Host "   ou" -ForegroundColor Yellow
        Write-Host "     winget install WiX" -ForegroundColor White
        Write-Host "   O arquivo portátil .zip foi gerado em: $ZipPath" -ForegroundColor Green
    }
} finally {
    if (Test-Path $BuildStage) {
        Remove-Item -Recurse -Force $BuildStage
    }
}

# ------------------------------------------------------------------------------
# 5. Checksum SHA-256
# ------------------------------------------------------------------------------
Write-Host "`n➔ [4/4] Calculando checksums SHA-256..." -ForegroundColor Cyan

if (Test-Path $ZipPath) {
    $ZipHash = (Get-FileHash -Path $ZipPath -Algorithm SHA256).Hash
    Set-Content -Path "$ZipPath.sha256" -Value "$ZipHash *$ZipName"
}

if (Test-Path $MsiPath) {
    $MsiHash = (Get-FileHash -Path $MsiPath -Algorithm SHA256).Hash
    Set-Content -Path "$MsiPath.sha256" -Value "$MsiHash *$MsiName"
}

if ($RequireMsi -and -not (Test-Path $MsiPath)) {
    throw "-RequireMsi foi pedido e o arquivo $MsiPath não existe."
}

Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host "          Pacotes para Windows gerados com sucesso!              " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
if (Test-Path $MsiPath) {
    $MsiSize = [math]::Round((Get-Item $MsiPath).Length / 1MB, 2)
    Write-Host "📦 Instalador MSI: $MsiPath ($MsiSize MB)" -ForegroundColor Green
}
$ZipSize = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
Write-Host "📦 Arquivo Zip:    $ZipPath ($ZipSize MB)" -ForegroundColor Green
Write-Host "📋 Checksums em:   $DistDir\*.sha256"
