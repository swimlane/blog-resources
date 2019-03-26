function Request-AccessToken {
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1',
                   PositionalBinding=$false,
                   ConfirmImpact='Medium')]
    Param (
        # Provide an Azure Active Directory Directory ID
        [Parameter(Mandatory=$false,
                   Position=0,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Parameter Set 1')]
        [string]
        $TenantId,
       
        # Provide your Application ID
        [Parameter(Mandatory=$true,
                   Position=1,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Parameter Set 1')]
        [string]
        $ClientId,
 
        # Provide your application secret
        [Parameter(Mandatory=$true,
                   Position=2,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Parameter Set 1')]
        [string]
        $ClientSecret,
 
        # Provide the returned authorization code
        [Parameter(Mandatory=$true,
                   Position=3,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Parameter Set 1')]
        [string]
        $AuthCode,
 
        # Provide your applications scopes
        [Parameter(Mandatory=$true,
                   Position=4,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Parameter Set 1')]
        [string]
        $Scope,
 
        # Provide your applications redirect URL
        [Parameter(Mandatory=$true,
                   Position=5,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Parameter Set 1')]
        [string]
        $RedirectUrl,
 
        # Grant Type supported
        [Parameter(Mandatory=$false,
                   Position=6,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Parameter Set 1')]
        [ValidateSet('authorization_code')]
        $GrantType
    )
   
    begin {
        if ($TenantId){
            $AzureADUrl   = "https://login.microsoftonline.com/$TenantId/oauth2/token"
        }
        else{
            $AzureADUrl   = "https://login.microsoftonline.com/common/oauth2/token"
        }
       
        if ($ClientId -notmatch '%'){
            $ClientId = [System.Web.HttpUtility]::UrlEncode($ClientId)
        }
        if ($ClientSecret -notmatch '%'){
            $ClientSecret = [System.Web.HttpUtility]::UrlEncode($ClientSecret)
        }
        if ($RedirectUrl -notmatch '%'){
            $RedirectUrl = [System.Web.HttpUtility]::UrlEncode($RedirectUrl)
        }
        if ($Scope -notmatch '%'){
            $Scope = [System.Web.HttpUtility]::UrlEncode($Scope)
        }
 
        $GrantType    = 'authorization_code'
 
$AccessTokenRequestBody = @"
grant_type=$GrantType
&code=$AuthCode
&client_id=$ClientId
&client_secret=$ClientSecret
&scope=$Scope
&redirect_uri=$RedirectUrl
"@

    }
   
    process {
        try {
            $params = @{
                Method      = 'Post'
                Uri         = $AzureADUrl
                ContentType = 'application/x-www-form-urlencoded'
                Body        = $AccessTokenRequestBody
 
            }
 
            $response = Invoke-RestMethod @params
 
            return $response
        }
        catch {
            Write-Error -ErrorRecord $Error[0]
        }
    }
   
    end {
    }
}