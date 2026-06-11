# Set Target Directory
$TargetDir = "$env:UserProfile"
$KeyFile = Join-Path -Path $TargetDir -ChildPath "encryption_key.txt1"

# Read Key and IV
$KeyData = Get-Content -Path $KeyFile
$EncryptionKey = $KeyData[0]
$EncryptionIV = $KeyData[1]

# Function to decrypt file
function Decrypt-File {
    param (
        [string]$FilePath,
        [string]$Key,
        [string]$IV
    )

    $EncryptedBytes = [System.IO.File]::ReadAllBytes($FilePath)

    $AES = [System.Security.Cryptography.Aes]::Create()
    $AES.Key = [System.Convert]::FromBase64String($Key)
    $AES.IV = [System.Convert]::FromBase64String($IV)

    $Decryptor = $AES.CreateDecryptor()
    $PlainBytes = $Decryptor.TransformFinalBlock($EncryptedBytes, 0, $EncryptedBytes.Length)

    $OriginalFilePath = $FilePath -replace '\.encrypted$',''
    [System.IO.File]::WriteAllBytes($OriginalFilePath, $PlainBytes)

    Remove-Item -Path $FilePath -Force
}

# Decrypt all encrypted files
Get-ChildItem -Path $TargetDir -Recurse -File -Filter "*.encrypted" | ForEach-Object {
    Decrypt-File -FilePath $_.FullName -Key $EncryptionKey -IV $EncryptionIV
}

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

Set-DesktopBackground -ImagePath "C:\Windows\Web\Wallpaper\Windows\img0.jpg"

Remove-Item -Path "C:\Users\User\Desktop\RansomNote.txt" -Force
Remove-Item -Path "C:\Users\User\wallpaper.png" -Force
Remove-Item -Path "C:\Users\User\encryption_key.txt1" -Force

Read-Host "Waiting to terminate"