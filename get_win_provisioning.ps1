# Validate Powershell version qualified for version 5.1 or 7.4, if not then show warning message.
[string]::Concat("[INFO]Powershell version " , $PSVersionTable.PSVersion.Major, ".", $PSVersionTable.PSVersion.Minor, " detected in your environment.")
if  ( -not ( ( ( 5 -eq $PSVersionTable.PSVersion.Major ) -and ( 1 -eq $PSVersionTable.PSVersion.Minor ) ) -or
             ( ( 7 -eq $PSVersionTable.PSVersion.Major ) -and ( 4 -eq $PSVersionTable.PSVersion.Minor ) ) ) ) 
{
  [string]::Concat("[WARNING]Powershell version 5.1 or 7.4 is supported, for other Powershell versions it is not validated.")
  $confirmation = Read-Host "Not a validated Powershell version, Are you Sure You Want To Proceed? [y/n]"
  while($confirmation -ne "y")
  {
    if ($confirmation -eq 'n') {exit}
    $confirmation = Read-Host "Not a validated Powershell version, Are you Sure You Want To Proceed? [y/n]"
  }
}

# Retrieve Server Name/CPU Cores/Memory/Storage/OS etc. provisioning metrics
try {
  $Server_Name                   = hostname
  $CPU_Cores                     = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
  [int]$Memory_MB                = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB * 1024
  $Storage                       = Get-CimInstance -ClassName Win32_LogicalDisk | ? {$_. DriveType -eq 3}    # 3:'Local Disk'
  [int]$Provisioned_Storage_GB   = 0
  [int]$Free_Storage_GB          = 0
  foreach ($s in $Storage){
    $Provisioned_Storage_GB      = $s.Size / 1GB + $Provisioned_Storage_GB
    $Free_Storage_GB             = $s.FreeSpace / 1GB + $Free_Storage_GB
  }
  $Storage_Type                  = (Get-PhysicalDisk | Select FriendlyName, MediaType).MediaType
  $Operating_System              = (Get-CimInstance Win32_OperatingSystem).Caption
  $Is_Virtual?                   = "please update value to FALSE/TRUE"
  $Cpu_String                    = (Get-CimInstance Win32_processor).Name
}
catch {
  Write-Error "[ERROR]Failed to fetch part of metrics, please try to break down command to row to solve the error first."
  Exit
}

# Print out the detected provisioning information to terminal screen
[string]::Concat("Server Name             :" , $Server_Name)
[string]::Concat("CPU Cores               :" , $CPU_Cores)
[string]::Concat("Memory (MB)             :" , $Memory_MB)
[string]::Concat("Provisioned Storage (GB):" , $Provisioned_Storage_GB)
[string]::Concat("Used Storage (GB)       :" , $Provisioned_Storage_GB - $Free_Storage_GB)
[string]::Concat("Storage Type            :" , $Storage_Type)
[string]::Concat("Operation System        :" , $Operating_System)
[string]::Concat("Is_Virtual?             :" , $Is_Virtual?)
[string]::Concat("CPU String              :" , $Cpu_String)	

# Export detected provisioning information to CSV file
$data = @(
  [PSCustomObject]@{
    "Server Name"                 = $Server_Name
    "CPU Cores"                   = $CPU_Cores
    "Memory (MB)"                 = $Memory_MB
    "Provisioned Storage (GB)"    = $Provisioned_Storage_GB  
    "Operating System"            = $Operating_System
    "Is Virtual?"                 = $Is_Virtual?
    "Hypervisor Name"             = ""
    "Cpu String"                  = $Cpu_String
    "Environment"                 = ""
    "SQL Edition"                 = ""
    "Application"                 = ""
    "Cpu Utilization Peak (%)"    = ""
    "Memory Utilization Peak (%)" = ""
    "Time In-Use (%)"             = ""
    "Annual Cost (USD)"           = ""
    "Storage Type"                = $Storage_Type
    "Used Storage (GB)"           = $Provisioned_Storage_GB - $Free_Storage_GB
    }
)

try {
  $OutFile = [string]::Concat($Server_Name , "_Provisioning.csv")
  [string]::Concat("OutFile:" , $OutFile)

  if (!(Test-Path $OutFile)) {
    New-Item -Path $OutFile -ItemType File
  }

  $data | Export-Csv -Path $OutFile -NoTypeInformation
}
catch {
  Write-Error "[ERROR]Error occured while trying to export data to CSV file"
  Exit
}
