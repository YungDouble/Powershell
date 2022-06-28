Get-ChildItem *.pdf -Recurse | Where-Object {
  {$_.PsIsContainer -eq $True}
} | ForEach-Object {
  $psfile = Join-Path $_.Directory ($_.BaseName + '.ps')
  if (Test-Path -LiteralPath $psfile) {
    Remove-Item $psfile -Force
  }
}
