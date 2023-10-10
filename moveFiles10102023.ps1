$logfile = ".\file_move.txt"
$old_document_share = “./”
$new_document_share = “./NewLocation”
$date_time = Get-Date -Format g
$batch_list = (Get-Content .\files.csv) -split ‘,’
foreach ($batch_name in $batch_list){
# move folder that match batch name
write-host $batch_name
$folders = Get-ChildItem -Recurse $old_document_share\* | Where-Object{($_.Extension -eq ".pdf") -and ($_.name.EndsWith($batch_name))}
foreach ($folder in $folders)
{
write-host $folder
$get_acl = Get-Acl $folder.FullName | ft $folder.FullName | out-file $logfile -append 
$output_details = $date_time | out-file $logfile -append
$move_item =Move-Item -Path $folder -Destination $new_document_share
}
}
