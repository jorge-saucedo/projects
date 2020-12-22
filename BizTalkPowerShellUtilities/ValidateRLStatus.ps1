#BizTalk Database name
$BTSDBServerName = "BTSServerName"

#Receive Port Name
$rcvPort = "RP.Name"

#Receive Location Name
$rcvLocation = "RL.Name"

#Recive Location Status
$rcvLocatoinStatus = $false

# Import external assembly and create a new object
[void] [System.reflection.Assembly]::LoadWithPartialName("Microsoft.BizTalk.ExplorerOM")
$Catalog = New-Object Microsoft.BizTalk.ExplorerOM.BtsCatalogExplorer

#BizTalk Config
$Catalog.ConnectionString = "SERVER=" + $BTSDBServerName + ";DATABASE=BizTalkMgmtDb;Integrated Security=SSPI"  #connectionstring to the mgmt db



foreach ($receivePort in $catalog.ReceivePorts | Where {$_.Name -eq $rcvPort})
{
    foreach($receiveLoc in $receivePort.ReceiveLocations  | Where {$_.Name -eq $rcvLocation})
    {
         $rcvLocatoinStatus = $receiveLoc.Enable
         if($rcvLocatoinStatus -eq $false)
         {
            #enable receiveLocation
            $receiveLoc.Enable = $true
            $Catalog.SaveChanges()
         }
    }
}

if($rcvLocatoinStatus -eq $false)
{
    #error message
    $errorMessage = "The receive location " + $rcvLocation + " was on disable status and was automaticaly enabled by ReceiveLocationWatcher!"

    #event viewer msg report
    Write-EventLog -LogName "Application" -Source "BizTalk Server" -EventID 3001 -EntryType Information -Message $errorMessage -Category 1 -RawData 10,20

    #email notification
    $From = "from@email.com"
    $To = "to@email.com"
    $Subject = $rcvLocation + " status alert"
    $SMTPServer = "smtp.server.com"
    Send-MailMessage -From $From -to $To -Subject $Subject -Body $errorMessage -SmtpServer $SMTPServer –DeliveryNotificationOption OnSuccess
}
