<#This script will go through folders and if there is a .ps file AND a matching file with another extension, delte the .ps file #>

Get-ChildItem *.pdf -Recurse | Where-Object {
  -not $_.PSIsContainer
} | ForEach-Object {
  $txtfile = Join-Path $_.Directory ($_.BaseName + '.ps')
  if (Test-Path -LiteralPath $txtfile) {
    Remove-Item $txtfile -Force
  }
}
