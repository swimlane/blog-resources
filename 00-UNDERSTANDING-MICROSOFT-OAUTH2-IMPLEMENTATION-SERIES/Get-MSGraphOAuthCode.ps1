function Get-MSGraphOAuthCode {
    [CmdletBinding()]
    param (
        # Provide your Application ID
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Parameter Set 1')]
        [string]
        $ClientId,
 
        # Provide your applications redirect URL
        [Parameter(Mandatory=$true,
                   Position=1,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Parameter Set 1')]
        [string]
        $RedirectUrl,
 
        # Provide your applications scopes
        [Parameter(Mandatory=$true,
                   Position=2,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Parameter Set 1')]
        [string]
        $Scope
    )
 
    if ($ClientId -notmatch '%'){
        $ClientId = [System.Web.HttpUtility]::UrlEncode($ClientId)
    }
    if ($RedirectUrl -notmatch '%'){
        $RedirectUrl = [System.Web.HttpUtility]::UrlEncode($RedirectUrl)
    }
    if ($Scope -notmatch '%'){
        $Scope = [System.Web.HttpUtility]::UrlEncode($Scope)
    }
 
$commonOAuthURL = @"
https://login.microsoftonline.com/common/oauth2/v2.0/authorize
?client_id=$ClientId
&response_type=code
&redirect_uri=$RedirectUrl
&response_mode=query
&scope=openid%20profile%20email%20offline_access%20$Scope
&state=12345
"@

    Write-Output "Copy this URL into your browser and authenticate using the appropriate credentials: $($commonOAuthURL -replace '\r*\n', '')"
}