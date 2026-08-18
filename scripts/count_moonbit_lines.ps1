param(
  [string]$Root = (Join-Path $PSScriptRoot "..")
)

$resolvedRoot = (Resolve-Path $Root).Path
$sourceFiles = Get-ChildItem -LiteralPath (Join-Path $resolvedRoot "src") -Recurse -File -Filter "*.mbt" |
  Where-Object { $_.Extension -eq ".mbt" -and $_.FullName -notmatch "[\\/](_build|target|\.mooncakes)[\\/]" }

$productionFiles = @($sourceFiles | Where-Object { $_.Name -notlike "*_wbtest.mbt" -and $_.Name -notlike "*_test.mbt" })
$testFiles = @($sourceFiles | Where-Object { $_.Name -like "*_wbtest.mbt" -or $_.Name -like "*_test.mbt" })

function Get-LineCounts([System.IO.FileInfo]$File) {
  $nonEmpty = 0
  $code = 0
  foreach ($line in Get-Content -LiteralPath $File.FullName) {
    $trimmed = $line.Trim()
    if ($trimmed.Length -eq 0) {
      continue
    }
    $nonEmpty++
    if ($trimmed -notmatch '^///?' -and $trimmed -notmatch '^//') {
      $code++
    }
  }
  [pscustomobject]@{ File = $File.FullName.Substring($resolvedRoot.Length + 1); NonEmpty = $nonEmpty; Code = $code }
}

$productionCounts = @($productionFiles | ForEach-Object { Get-LineCounts $_ })
$testCounts = @($testFiles | ForEach-Object { Get-LineCounts $_ })
$productionNonEmpty = ($productionCounts | Measure-Object -Property NonEmpty -Sum).Sum
$productionCode = ($productionCounts | Measure-Object -Property Code -Sum).Sum
$testNonEmpty = ($testCounts | Measure-Object -Property NonEmpty -Sum).Sum
$testCode = ($testCounts | Measure-Object -Property Code -Sum).Sum

Write-Output "MoonBit source scale for $resolvedRoot"
Write-Output ("production_files={0}" -f $productionFiles.Count)
Write-Output ("production_nonempty_lines={0}" -f $productionNonEmpty)
Write-Output ("production_code_lines={0}" -f $productionCode)
Write-Output ("test_files={0}" -f $testFiles.Count)
Write-Output ("test_nonempty_lines={0}" -f $testNonEmpty)
Write-Output ("test_code_lines={0}" -f $testCode)
Write-Output "-- production files --"
$productionCounts | Sort-Object File | ForEach-Object { "{0}`t{1}`t{2}" -f $_.NonEmpty, $_.Code, $_.File }
Write-Output "-- test files --"
$testCounts | Sort-Object File | ForEach-Object { "{0}`t{1}`t{2}" -f $_.NonEmpty, $_.Code, $_.File }
