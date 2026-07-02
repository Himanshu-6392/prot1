$content = Get-Content "lib\core\theme\app_theme.dart" -Raw
$newContent = $content -replace 'const IconThemeData\(', 'IconThemeData('
$newContent = $newContent -replace 'const BottomNavigationBarThemeData\(', 'BottomNavigationBarThemeData('
$newContent = $newContent -replace 'const BorderSide\(', 'BorderSide('
$newContent = $newContent -replace 'const DividerThemeData\(', 'DividerThemeData('
$newContent = $newContent -replace 'const BottomSheetThemeData\(', 'BottomSheetThemeData('
$newContent = $newContent -replace 'const UnderlineTabIndicator\(', 'UnderlineTabIndicator('
$newContent = $newContent -replace 'const SliderThemeData\(', 'SliderThemeData('
$newContent = $newContent -replace 'const ProgressIndicatorThemeData\(', 'ProgressIndicatorThemeData('

if ($content -ne $newContent) {
    Set-Content -Path "lib\core\theme\app_theme.dart" -Value $newContent -NoNewline
    Write-Host "Updated app_theme.dart"
} else {
    Write-Host "No changes"
}
