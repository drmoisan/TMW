param(
    [Parameter(Mandatory = $true)][string]$Path
)

$files = Get-ChildItem -Path $Path -Recurse -Filter coverage.cobertura.xml -ErrorAction Stop
if ($files.Count -eq 0) {
    Write-Output "No coverage.cobertura.xml files found under $Path"
    exit 2
}

$totalLinesCovered = 0
$totalLinesValid = 0
$totalBranchesCovered = 0
$totalBranchesValid = 0

foreach ($f in $files) {
    $xml = [xml](Get-Content -LiteralPath $f.FullName)
    $lc = [int]$xml.coverage.'lines-covered'
    $lv = [int]$xml.coverage.'lines-valid'
    $bc = [int]$xml.coverage.'branches-covered'
    $bv = [int]$xml.coverage.'branches-valid'
    $totalLinesCovered += $lc
    $totalLinesValid += $lv
    $totalBranchesCovered += $bc
    $totalBranchesValid += $bv
    Write-Output ("{0}: lines={1}/{2} branches={3}/{4}" -f $f.Directory.Name, $lc, $lv, $bc, $bv)
}

$line = if ($totalLinesValid -gt 0) { $totalLinesCovered / $totalLinesValid } else { 0 }
$branch = if ($totalBranchesValid -gt 0) { $totalBranchesCovered / $totalBranchesValid } else { 0 }
Write-Output ("AGGREGATE: lines-covered={0}/{1} branches-covered={2}/{3} line={4:P2} branch={5:P2}" -f $totalLinesCovered, $totalLinesValid, $totalBranchesCovered, $totalBranchesValid, $line, $branch)
