Get-ChildItem *.pdf -Recurse | Where-Object {
  {$_.PsIsContainer -eq $True}
} | ForEach-Object {
  $txtfile = Join-Path $_.Directory ($_.BaseName + '.ps')
  if (Test-Path -LiteralPath $txtfile) {
    Remove-Item $txtfile -Force
  }
}
