# Script to change wallpaper on all users via PsExec
# Requires domain admin privileges

param (
    [string]$WallpaperURL = "https://raw.githubusercontent.com/eforentropy/test/refs/heads/main/medusa2.png"
)

$WallpaperPath = "C:\\wallpaper.png"

# Download wallpaper from URL
Invoke-WebRequest -Uri $WallpaperURL -OutFile $WallpaperPath

# Define registry paths for all users
$RegPath = "HKU:\{0}\Control Panel\Desktop"

# Get all user SIDs from registry
$UserSIDs = Get-ChildItem "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\ProfileList" | Select-Object -ExpandProperty PSChildName

foreach ($SID in $UserSIDs) {
    $CurrentRegPath = $RegPath -f $SID
    if (Test-Path $CurrentRegPath) {
        Set-ItemProperty -Path $CurrentRegPath -Name Wallpaper -Value $WallpaperPath
        Set-ItemProperty -Path $CurrentRegPath -Name WallpaperStyle -Value 6  # Fill
        Set-ItemProperty -Path $CurrentRegPath -Name TileWallpaper -Value 0
    }
}

# Refresh wallpaper for all users
$code = @'
using System.Runtime.InteropServices;
namespace Win32{
    public class Wallpaper{
        [DllImport("user32.dll", CharSet=CharSet.Auto)]
        static extern int SystemParametersInfo (int uAction , int uParam , string lpvParam , int fuWinIni);
        public static void SetWallpaper(string thePath){
            SystemParametersInfo(20,0,thePath,3);
        }
    }
}
'@

if ($error[0].exception -like "*Cannot add type. The type name 'Win32.Wallpaper' already exists.*") {
    write-host "Win32.Wallpaper assemblies already loaded"
    write-host "Proceeding"
} else {
    add-type $code
}

[Win32.Wallpaper]::SetWallpaper($WallpaperPath)

Write-Host "Wallpaper successfully applied to all users."
