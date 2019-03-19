# Understanding Microsoft's OAuth2 Implmentation

This directory contains references to code shown in the Swimlane blog series titled Understanding Microsoft's OAuth2 Implmentation.


### Generating our authorization URL

Using PowerShell Core, we need to generate our “Authorization” URL.  We can do this using this our [Get-MSGraphOAuthCode.ps1](Get-MSGraphOAuthCode.ps1) function:

```powershell
$ClientId = 'a6b6008e-1cd0-42b7-9649-3d4fec3e3748'
$redirectURL = 'https://localhost'
$scopes = "https://graph.microsoft.com/Mail.Read https://graph.microsoft.com/People.Read https://graph.microsoft.com/User.Read"

Get-MSGraphOAuthCode -ClientId $ClientId -RedirectUrl $redirectURL -Scope $scopes
```

You should receive output similar to the following:

```output
https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=a6b6008e-1cd0-42b7-9649-3d4fec3e3748&response_type=code&redirect_uri=https%3a%2f%2flocalhost&response_mode=query&scope=openid%20profile%20email%20offline_access%20https%3a%2f%2fgraph.microsoft.com%2fMail.Read+https%3a%2f%2fgraph.microsoft.com%2fPeople.Read+https%3a%2f%2fgraph.microsoft.com%2fUser.Read&state=12345"
```

Copy this URL into your browser and authenticate using the appropriate credentials.

### Getting an access_token

You can use oru [Request-MSGraphAccessToken.ps1](Request-MSGraphAccessToken.ps1) PowerShell Core function to get a access_token and refresh_token using your Authorization Code from before.

You can call this function by providing these parameters:

```powershell
$ClientId = 'a6b6008e-1cd0-42b7-9649-3d4fec3e3748'
$ClientSecret = 'ewwgyTWNYK80)@@?rlCC874'
$redirectURL = 'https://localhost'
$scopes = "https://graph.microsoft.com/Mail.Read https://graph.microsoft.com/People.Read https://graph.microsoft.com/User.Read"
$authCode = 'OAQABAAIAAACEfexXxjamQb3OeGQ4GugvnGFvbHYFYZni_m3t5tMUiNhTtWKE-VLVBw6ZNHJsZD3c_hrD4O34ShrbtE8HeyOyDLT-l-lEHihr7cH7whdismVsGpUbfq1J5562eeWunMTU83fJ9IT7HfC6bbkAeBdR7GCrHFTcowvc84AeB9QgaC9Jl-rMJ-5yRhfZCCVpIkt1Pgp2E0iy4PJEX4l7lI534PAEr12DYdIYTvOwWnyLcbSKhmib4eTwkNUFuC2_JK-ruhOdZa5hQs_GOcrxHwio5mzholXvTcy6aLIqVjtrxWUM47wqPp5bMHty1_t-YzVvhRNXsojQLzPT8370nOW9I01WRvLh3db2-4rLv96b9IYmQYPKER24bKIkm5XSpEnlmsqL3-SIIDuAFqat0jyeuQo37QYSIgcvsOzDHrhCcl35XSeDv1CiytYPFvHjjl7i0Zi5o5h1QULlyJjUxnl1som6trEpTdjiN4bGSZFgYmXQxFQYFYYlGaPB8XWZzDdhtQozMupeRGxD6zvIv44qMMAg-RwBwuFKi0tW4_c66O8PxEy2P3hVXY16aVKfsO5BU4ef_igvCY8neoeXxJd0-8vOGQGBshf6aKRettNTWiCBHzm64GpNUkDdqUn_yQ7GShRRUDU-BigRnnLmpgYUvZac3xKSPIy4vaUHdVXCkSAA'

Request-MSGraphAccessToken -ClientId $ClientId -ClientSecret $ClientSecret -AuthCode $authCode -RedirectUrl $redirectURL -Scope $scopes
```

### Access Microsoft Graph API People Endpoint

Using the two functions above, we can call the following to get access to the Microsoft Graph API People endpoint:

```powershell
$ClientId = 'a6b6008e-1cd0-42b7-9649-3d4fec3e3748'
$ClientSecret = 'ewwgyTWNYK80)@@?rlCC874'
$redirectURL = 'https://localhost'
$scopes = "https://graph.microsoft.com/Mail.Read https://graph.microsoft.com/People.Read https://graph.microsoft.com/User.Read"

$Authorization = Get-MSGraphOAuthCode -ClientId $ClientId -RedirectUrl $redirectURL -Scope $scopes
# Get our authorization code from our web browser and set it as the value for our $AuthCode variable
$authCode = 'OAQABAAIAAACEfexXxjamQb3OeGQ4Gugvj3p8GWJ3Dfp8zQEOj11gj0nQzme5WBcWRgJR41sxh2h19SpUsZrVmgsUJo8qErEucTbPdlHKSVNH-qD6Qddpn0rj55XmIwYS4Xr5cnmuqn5YHUYQGz-GNb5k6XwsFMvKljzvv4pA5AceDLFKV3OKppO8PBVo0ibbD_DtwMGAszM6vdm5LXrJLUCqaknpUZfQb5RANTFJjt5IYNH1K_fqQ_TWBEKMVSNbSWgJMdWwA9E6BQQZbd0jrIztyavhEJziFyv5ZUyKRft9AqfccE7ZbfJQK4DNcZ-nP_Z8N5LOZxCs-bYP3BuhflpjRHW5P8cjqAQblIN0hYfuPWAeZGcTG9xUexFeWgdzDqkUpmqEM25jY4t7hdGRhfdL6bnkRGPgQocefj1oc-aMtk2f6-t39N1TU24F_NKSMvDk62bOVdhaKQGEgj9BgHcM9-C9GOhCPwd2rbXOne3EOi95ncC7qFfelJlDHahL3VHizcwr3xtl7ChyBBpI0T-WXaZlt82y2T9Nct1_cBC9ltYD4Kyn66I6GV3icrxyl1jX4mD2pE1uf-8adS968NbniH8VIkSgm8O_yh77beQexVamryOJMIybTbK7eaK9giJJEUTK049iie2EpM3EQIylSjcPASq2U6zdj0VJ3SClzo68mPGmKSAA'

$Tokens = Request-MSGraphAccessToken -ClientId $ClientId -ClientSecret $ClientSecret -AuthCode $authCode -RedirectUrl $redirectURL -Scope $scopes

# Now we can call the people endpoint on the Graph API
$params = @{
   Method  = 'Get'
   Headers = @{
       Authorization = "bearer $($Tokens.access_token)"
   }
   Uri     = 'https://graph.microsoft.com/v1.0/me/people'
}

# Call the Graph API and loop through each of the returned values and output them
((Invoke-RestMethod @params).value).ForEach({
	Write-Output $_
})
```