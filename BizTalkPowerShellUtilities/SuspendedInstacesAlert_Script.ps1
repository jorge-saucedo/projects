[ARRAY]$suspendedMessages = get-wmiobject MSBTS_ServiceInstance -namespace 'root\MicrosoftBizTalkServer' -filter '(ServiceStatus = 4 or ServiceStatus = 16 or ServiceStatus = 32 or ServiceStatus = 64)'

if($suspendedMessages.Count -gt 0)
{
    #error message
    $errorMessage = "There are " + $suspendedMessages.Count + " suspended messages instances"

        #email notification
    $From = "fromEail@email.com"
    $To = "toEmail@email.com"
    $Subject = "Suspended messages instances status alert"
    $SMTPServer = "smtp.server.com"
    Send-MailMessage -From $From -to $To -Subject $Subject -Body $errorMessage -SmtpServer $SMTPServer –DeliveryNotificationOption OnSuccess
}