
function Get-MDATPToken {
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1',
                   PositionalBinding=$false)]
    Param (
        # Your application client id
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipelineByPropertyName=$true
                   )]
        $ClientId,
        
        # Your application client secret
        [Parameter(Mandatory=$true,
                   Position=1,
                   ValueFromPipelineByPropertyName=$true
                   )]
        $ClientSecret,
        
        # Your Azure AD tenant id
        [Parameter(Mandatory=$true,
                   Position=2,
                   ValueFromPipelineByPropertyName=$true
                   )]
        $TenantId
    )
    
    $resourceAppIdUri = 'https://api.securitycenter.windows.com'
    $oAuthUri = "https://login.windows.net/$TenantId/oauth2/token"
    $body = [Ordered] @{
        resource = "$resourceAppIdUri"
        client_id = "$ClientId"
        client_secret = "$ClientSecret"
        grant_type = 'client_credentials'
    }

    $response = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $body -ErrorAction Stop

    Write-Output $response.access_token
}


function Invoke-MDATPTQuery {
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1',
                   PositionalBinding=$false)]
    Param (
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipelineByPropertyName=$true
                   )]
        $Query,
        
        [Parameter(Mandatory=$true,
                   Position=1,
                   ValueFromPipelineByPropertyName=$true
                   )]
        $Token
    )

    $headers = @{ 
        'Content-Type' = 'application/json'
        Accept = 'application/json'
        Authorization = "Bearer $Token" 
    }

    $url = "https://api.securitycenter.windows.com/api/advancedqueries/run"
    $body = ConvertTo-Json -InputObject @{ 'Query' = $Query }

    $webResponse = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body -ErrorAction Stop

    Write-Output $webResponse.Schema, $webResponse.Results
}

$query = @"
"RegistryEvents | limit 10"
"@

$query = @"
let minTimeRange = ago(7d);
let outlookLinks = 
    MiscEvents
    | where EventTime > minTimeRange and ActionType == "BrowserLaunchedToOpenUrl" and isnotempty(RemoteUrl)
	| where 
			InitiatingProcessFileName =~ "outlook.exe" 		
	        or InitiatingProcessFileName =~ "runtimebroker.exe"
    | project EventTime, MachineId, ComputerName, RemoteUrl, InitiatingProcessFileName, ParsedUrl=parse_url(RemoteUrl)
    | extend WasOutlookSafeLink=(tostring(ParsedUrl.Host) endswith "safelinks.protection.outlook.com")
    | project EventTime, MachineId, ComputerName, WasOutlookSafeLink, InitiatingProcessFileName,
            OpenedLink=iff(WasOutlookSafeLink, url_decode(tostring(ParsedUrl["Query Parameters"]["url"])), RemoteUrl);
let alerts =
    AlertEvents
    | summarize (FirstDetectedActivity, Title)=argmin(EventTime, Title) by AlertId, MachineId
    | where FirstDetectedActivity > minTimeRange;
alerts | join kind=inner (outlookLinks) on MachineId | where FirstDetectedActivity - EventTime between (0min..3min)
| summarize FirstDetectedActivity=min(FirstDetectedActivity), AlertTitles=makeset(Title) by OpenedLink, InitiatingProcessFileName, EventTime=bin(EventTime, 1tick), ComputerName, MachineId, WasOutlookSafeLink
"@

$ClientId = ''
$ClientSecret = ''
$TenantId = ''

$Token = Get-MDATPToken -ClientId $ClientId -ClientSecret $ClientSecret -TenantId $TenantId
Invoke-MDATPTQuery -Token $Token -Query $query