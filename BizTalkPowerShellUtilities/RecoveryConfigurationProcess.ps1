#BizTalk Database name
$BTSDBServerName = "BTSServername"

 #configuration File path
$confFilePath = ".\FTP_EdiTransfer.BindingInfo.xml.txt"

# Import external assembly and create a new object
[void] [System.reflection.Assembly]::LoadWithPartialName("Microsoft.BizTalk.ExplorerOM")
$Catalog = New-Object Microsoft.BizTalk.ExplorerOM.BtsCatalogExplorer
$controlProgram = $true



$optionSelected = $false
while($optionSelected -ne $true)
{
    $inputOption = Read-Host  "Select `n [1] to configure DR Handlers (Configure FTPRECEIVE3 handler) `n [2] to restore production configuration"
    if(($inputOption -eq '1') -or ($inputOption -eq '2'))
    {
        $optionSelected = $true
    }
    else
    {
        Write-Host "Input validation error. Select valid option." -ForegroundColor Red
    }
}

 
try
{
    #BizTalk Config
    $Catalog.ConnectionString = "SERVER=" + $BTSDBServerName + ";DATABASE=BizTalkMgmtDb;Integrated Security=SSPI"  #connectionstring to the mgmt db
}
catch
{
  Write-Host "Unable to establishing a connection to SQL Server, please review the BizTalk DataBase Server Name:" -ForegroundColor Red
  Write-Host $_ -ForegroundColor Red
  Write-Host $_.ScriptStackTrace -ForegroundColor Red
  $controlProgram = $false
}

if($controlProgram)
{
    if((Test-Path -path  $confFilePath)-eq $false)
    {
       Write-Host "Unable to locate the configuration file: " $confFilePath "`nProcess stopped."-ForegroundColor Red
       $controlProgram = $false
    }
}
 
if($controlProgram)
{
    #read line per line the configuration file, skipping the firts line
    foreach($line in Get-Content $confFilePath | select-object -skip 1) 
    {
        #split line to get the ReceivePort name and ReceiveLocation name
        $ConfigArray =$line.Split(";")

        #validate format line
        if($ConfigArray.Count -ne 3)
        {
            Write-Host "Configuration file line is not in correct format. Process stopped. Please review" -ForegroundColor Red
            Write-Host "Configuration file path: " $confFilePath -ForegroundColor Red
            Write-Host "Configuration line: " $line -ForegroundColor Red
            break;
        }
               
        
        $rcvPort = $ConfigArray[0]
        $rcvLocation = $ConfigArray[1]
        if($inputOption -eq '1')
        {
            $rcvHandler = "FTPRECEIVE3"
        }
        else
        {
            $rcvHandler = $ConfigArray[2]
        }
        


        #get all associated Handlers from Host
        foreach ($handler in $catalog.ReceiveHandlers | Where {$_.Name -eq $rcvHandler}) 
        { 
            #get FTP habñer from host
            if($handler.TransportType.Name -eq "FTP")
            {
                $BTSFTPHandler = $handler

                #Get the receive port
                foreach ($receivePort in $catalog.ReceivePorts | Where {$_.Name -eq $rcvPort})
                {
                    #get receive Location
                    foreach($receiveLoc in $receivePort.ReceiveLocations  | Where {$_.Name -eq $rcvLocation})
                    {
                        #set handler to receive location
                        $receiveLoc.ReceiveHandler = $BTSFTPHandler
                        Write-host "Assigning " $BTSFTPHandler.Name " receive handler to "$receiveLoc.Name " receive location" -ForegroundColor Green
                    }
                }
            }
        }
        #save changes
        Write-host "Saving catalog changes..." -ForegroundColor DarkCyan
        try
        {
            $Catalog.SaveChanges()
        }
        catch
        {
          Write-Host "An error ocurred saving catalog changes." -ForegroundColor Red
          Write-Host $_ -ForegroundColor Red
          Write-Host $_.ScriptStackTrace -ForegroundColor Red
        }
        Write-host "Changes saved" -ForegroundColor Green
      
    }
}

 Read-Host "Press Enter to conitnue..."