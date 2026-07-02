$files = Get-ChildItem -Path "lib" -Filter *.dart -Recurse
foreach ($file in $files) {
    if ($file.Name -ne "colors.dart") {
        $content = Get-Content $file.FullName -Raw
        $newContent = $content -replace 'const BoxDecoration', 'BoxDecoration'
        $newContent = $newContent -replace 'const LinearGradient', 'LinearGradient'
        $newContent = $newContent -replace 'const RadialGradient', 'RadialGradient'
        
        if ($content -ne $newContent) {
            Set-Content -Path $file.FullName -Value $newContent -NoNewline
            Write-Host "Updated: $($file.FullName)"
        }
    }
}
Write-Host "Done"
