$filePath = "c:\Users\Usuario\Documents\GitHub\Ruptura_Temporal-Godot-Mobile\scripts\main.gd"
$lines = [System.IO.File]::ReadAllLines($filePath)

Write-Host "Total lines: $($lines.Count)"

# Show what's at the boundaries
for ($i = 51069; $i -le 51070; $i++) {
    Write-Host "$($i+1): [$($lines[$i])]"
}
Write-Host "---"
for ($i = 51183; $i -le 51186; $i++) {
    Write-Host "$($i+1): [$($lines[$i])]"
}
