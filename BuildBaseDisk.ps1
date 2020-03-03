# based off of
# http://rakhesh.com/windows/notes-of-uefi-gpt-uefi-boot-process-disk-partitions-and-hyper-v-differencing-disks-with-a-generation-2-vm/

$NewVHDFullName = "$PSScriptRoot\2016EvalGui_$(get-date -f 'MMddyyyyHHmm')`.vhdx"
New-VHD -path $NewVHDFullName -SizeBytes 25GB -Dynamic | Mount-VHD -Passthru | Initialize-Disk -PartitionStyle GPT

$NewDiskNumber = (get-disk | measure -Maximum -Property number).Maximum

remove-partition -DiskNumber $NewDiskNumber -PartitionNumber 1 -Confirm:$false

new-partition -DiskNumber $NewDiskNumber -Size 500MB -GptType "{de94bba4-06d1-4d40-a16a-bfd50179d6ac}" # Recovery
new-partition -DiskNumber $NewDiskNumber -Size 100MB -GptType "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" # ESP
new-partition -DiskNumber $NewDiskNumber -size 128MB -GptType "{e3c9e316-0b5c-4db8-817d-f92df00215ae}" # MSR
New-Partition -DiskNumber $NewDiskNumber -Size 20GB  -GptType "{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}" -AssignDriveLetter | Format-Volume -FileSystem NTFS -Confirm:$False -NewFileSystemLabel 'Server2016Eval' -Force # OS
New-Partition -DiskNumber $NewDiskNumber -UseMaximumSize -GptType "{de94bba4-06d1-4d40-a16a-bfd50179d6ac}"  # Recovery

$MountedISO = Mount-DiskImage -ImagePath 'F:\ISOs\windows Server 2016\Evaluation\14393.0.160715-1616.RS1_RELEASE_SERVER_EVAL_X64FRE_EN-US.ISO' -PassThru

Check that I: is the correct drive
$NewWindowsDrive = 'I'
Expand-WindowsImage -imagePath "$($MountedISO.DevicePath)sources\install.wim" -Index 4 -ApplyPath "$NewWindowsDrive`:"

# WinRe tools partition
# Correct drive letters.
# I: in this case is the new expanded windows image from above
$RecoveryDriveLetter = 'R'
Get-Partition -DiskNumber $NewDiskNumber -PartitionNumber 1 | Format-Volume -FileSystem FAT32 -NewFileSystemLabel RECOVERY -Force -Confirm:$false
Get-Partition -DiskNumber $NewDiskNumber -PartitionNumber 1 | Set-Partition -NewDriveLetter $RecoveryDriveLetter
mkdir "$RecoveryDriveLetter`:\Recovery\WindowsRE"
& $({xcopy /H "$NewWindowsDrive`:\Windows\System32\Recovery\winre.wim" "$RecoveryDriveLetter`:\Recovery\WindowsRE\"})
& $({ReAgentc.exe /setreimage /path R:\Recovery\WindowsRE\ /target "$NewWindowsDrive`:\Windows"})
Remove-PartitionAccessPath -AccessPath "$RecoveryDriveLetter`:" -DiskNumber $NewDiskNumber -PartitionNumber 1

# confirm
ReAgentc.exe /info /target "$NewWindowsDrive`:\Windows"


# EFI System Partition
$PartitionDriveLeter = 'Q'
Get-Partition -DiskNumber $NewDiskNumber -PartitionNumber 2 | Add-PartitionAccessPath -AccessPath "$PartitionDriveLeter`:"
& $({format "$PartitionDriveLeter`:" /fs:FAT32 /v:EFS})

& $({bcdboot "$NewWindowsDrive`:\Windows" /S "$PartitionDriveLeter`:" /f UEFI})

Get-Partition -DiskNumber $NewDiskNumber -PartitionNumber 2 | Remove-PartitionAccessPath -AccessPath "$PartitionDriveLeter`:"
