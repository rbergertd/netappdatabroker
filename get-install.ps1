$netAppUsername = 'ryan.berger@techdata.com'
$netAppPassword = 'C@Pc0m102019'
$netAppDataBrokerName = 'ourazurebroker'
$URI = 'https://netapp-cloud-account.auth0.com/oauth/token'
$BODY = @{
    username  = 'ryan.berger@techdata.com'
    scope   = 'profile'
    audience = 'https://api.cloud.netapp.com'
    client_id     = 'UaVhOIXMWQs5i1WdDxauXe5Mqkb34NJQ'
    grant_type   = 'password'
    password    = 'C@Pc0m102019'
}

$Result = Invoke-RestMethod -Uri $URI -Method POST -Body $BODY
$Result_To_JSON = $Result | ConvertTo-Json
$token = ( $Result_To_JSON | ConvertFrom-Json ).access_token
Write-Output $token

$URI2 = 'https://cloudsync.netapp.com/api/data-brokers'
#$token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6Ik5rSXlPVFUzUWpZek1ESkRPVGd5TlRJMU1EUkZNVFpFUTBFd1JEUkJRVGxFT1VFMU5UUkNOZyJ9.eyJodHRwOi8vY2xvdWQubmV0YXBwLmNvbS9mdWxsX25hbWUiOiJSeWFuIEJlcmdlciIsImh0dHA6Ly9jbG91ZC5uZXRhcHAuY29tL2VtYWlsX3ZlcmlmaWVkIjp0cnVlLCJodHRwOi8vY2xvdWQubmV0YXBwLmNvbS9jb25uZWN0aW9uX2lkIjoiY29uX1I3TFE5OFFMamZ2bkhWQUciLCJodHRwOi8vY2xvdWQubmV0YXBwLmNvbS9pc19mZWRlcmF0ZWQiOmZhbHNlLCJpc3MiOiJodHRwczovL25ldGFwcC1jbG91ZC1hY2NvdW50LmF1dGgwLmNvbS8iLCJzdWIiOiJhdXRoMHw1ZDQ4MzQ1YThjYmI5ODBjN2RmMjU1YzUiLCJhdWQiOiJodHRwczovL2FwaS5jbG91ZC5uZXRhcHAuY29tIiwiaWF0IjoxNTY3NjE2Nzg1LCJleHAiOjE1Njc3MDMxODUsImF6cCI6IlVhVmhPSVhNV1FzNWkxV2REeGF1WGU1TXFrYjM0TkpRIiwic2NvcGUiOiJwcm9maWxlIGNjOnVwZGF0ZS1wYXNzd29yZCIsImd0eSI6InBhc3N3b3JkIn0.QlztjQ_TWwYoYRCGRDUMxBgbx-uyxWfi6z4C1ghC0-Uc2eBnLDmSIuPn55Q2KurOV4aOkvg-CNtGRa_OUFq2Hlvmy8UlR4Dzhx62I2u7Us0eJzjUrQy1f7_kkO80kwh4szuQxLp1k7h5C9LMqneZG5ZF_iycEoywhktDJJk21pVZZ6m9xibVUM-LcyQW8mOzwS3kmNu2cP-Omv20O4HmJ8E8xQrTtTOR1j6AJ_b1NE4TBrK8_d60YGvpiq2N8kSr8aua0ZhBjHmsU8D7bTdhlozbV7-C79lozJSWi5Vvhio6yq4GPcRagQAuKFlpeyyeri-oWhSh2wBo61yrciW2ZA'

$Headers = New-Object 'System.Collections.Generic.Dictionary[String,String]'
$Headers.Add("Authorization","Bearer $token")

$BODY3 = "'{`"name`": `"" + $netAppDataBrokerName + "`",`"type`": `"AZURE`"}'"
Write-Output $BODY3
$CONTENT_TYPE = 'application/json'
$Result3 = Invoke-RestMethod -Uri $URI2 -Method POST -Body $BODY3 -Headers $Headers -ContentType $CONTENT_TYPE
Write-Output $Result3

