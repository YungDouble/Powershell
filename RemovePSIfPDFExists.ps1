Get-ChildItem *.pdf -Recurse | Where-Object {
  -not $_.PSIsContainer
} | ForEach-Object {
  $txtfile = Join-Path $_.Directory ($_.BaseName + '.ps')
  if (Test-Path -LiteralPath $txtfile) {
    Remove-Item $txtfile -Force
  }
}