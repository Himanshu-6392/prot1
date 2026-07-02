$files = Get-ChildItem -Path "lib" -Filter *.dart -Recurse
foreach ($file in $files) {
    if ($file.Name -ne "colors.dart") {
        $content = Get-Content $file.FullName -Raw
        $newContent = $content -replace 'const Icon\(', 'Icon('
        $newContent = $newContent -replace 'const Center\(', 'Center('
        $newContent = $newContent -replace 'const Divider\(', 'Divider('
        $newContent = $newContent -replace 'const CircularProgressIndicator\(', 'CircularProgressIndicator('
        $newContent = $newContent -replace 'const TagChip\(', 'TagChip('
        $newContent = $newContent -replace 'const VerifiedBadge\(', 'VerifiedBadge('
        $newContent = $newContent -replace 'const BottomNavigationBarItem\(', 'BottomNavigationBarItem('
        $newContent = $newContent -replace 'const Text\(', 'Text('
        $newContent = $newContent -replace 'const Padding\(', 'Padding('
        $newContent = $newContent -replace 'const SizedBox\(', 'SizedBox('
        $newContent = $newContent -replace 'const Column\(', 'Column('
        $newContent = $newContent -replace 'const Row\(', 'Row('
        $newContent = $newContent -replace 'const Expanded\(', 'Expanded('
        $newContent = $newContent -replace 'const Spacer\(', 'Spacer('
        $newContent = $newContent -replace 'const ShimmerBox\(', 'ShimmerBox('
        $newContent = $newContent -replace 'const RequestCardShimmer\(', 'RequestCardShimmer('
        $newContent = $newContent -replace 'const LenderCardShimmer\(', 'LenderCardShimmer('
        $newContent = $newContent -replace 'const DropdownMenuItem\(', 'DropdownMenuItem('
        $newContent = $newContent -replace 'const InputDecoration\(', 'InputDecoration('
        
        if ($content -ne $newContent) {
            Set-Content -Path $file.FullName -Value $newContent -NoNewline
            Write-Host "Updated: $($file.FullName)"
        }
    }
}
Write-Host "Done"
