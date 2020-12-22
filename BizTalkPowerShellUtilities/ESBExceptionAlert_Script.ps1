$dataSource = "BTSServerDb"
$database = "EsbExceptionDb"
$auth = "Integrated Security=SSPI;"
$connectionString = "Provider=sqloledb; " + "Data Source=$dataSource; " + "Initial Catalog=$database; " + "$auth; "

$currentDTWOTime = Get-Date -Format "yyyy-MM-dd "
$currentDTMinutes = Get-Date -Format "mm"
$currentDTHours = Get-Date -Format "HH"


if($currentDTMinutes -ge 30)
{
    $beginDT = "'" + $currentDTWOTime + " " + $currentDTHours + ":00.000"+ "'"  
    $endDT = "'" + $currentDTWOTime + " " + $currentDTHours + ":30.000"+ "'"
}
else
{
    $beginDT = "'" + $currentDTWOTime + " " + ($currentDTHours -1) + ":30.000"  + "'"
    $endDT = "'" + $currentDTWOTime + " " + $currentDTHours + ":00.000" + "'"
}



$sql = "SELECT count(1) as Exceptions FROM Fault F WITH(NOLOCK) where dateadd(HOUR, -6,F.InsertedDate) between " + $beginDT + " and " + $endDT

$connection = New-Object System.Data.OleDb.OleDbConnection $connectionString
$command = New-Object System.Data.OleDb.OleDbCommand $sql,$connection
$connection.Open()
$adapter = New-Object System.Data.OleDb.OleDbDataAdapter $command
$dataset = New-Object System.Data.DataSet
try 
{ 
    [void] $adapter.Fill($dataSet)
    $connection.Close()
    $result = $dataset.Tables[0].Rows[0]
}
catch 
{ 
    $connection.Close()
}


if($result[0] -gt 0)
{
     #error message
    $errorMessage = "There are " + $result[0] + " new EsbException messages"

        #email notification
    $From = "emailFrom@email.com"
    $To = "emailTo@email.com"
    $Subject = "EsbException messages alert"
    $SMTPServer = "smtp.server.com"
    Send-MailMessage -From $From -to $To -Subject $Subject -Body $errorMessage -SmtpServer $SMTPServer –DeliveryNotificationOption OnSuccess
}