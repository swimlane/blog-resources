import json, requests


# Add your credentials here
##########################################################
__CLIENT_ID__ = ''
__CLIENT_SECRET__ = ''
__TENANT_ID__ = ''
##########################################################

class MDATPConnector(object):

    __TOKEN_URL__ = 'https://login.windows.net/{tenant}/oauth2/token'
    __API_VERSION__ = 'v1.0'
    __APP_URL__ = 'https://api.securitycenter.windows.com'

    def __init__(self, client_id, client_secret, tenant_id):
        self.client_id = client_id
        self.client_secret = client_secret
        self.tenant_id = tenant_id

        self.session = requests.Session()
        self.session.verify = True

    @property
    def token(self):
        return self._token

    @token.setter
    def token(self, value):
        self._token = value

    def get_token(self):
        body = {
            'resource' : self.__APP_URL__,
            'client_id' : self.client_id,
            'client_secret' : self.client_secret,
            'grant_type' : 'client_credentials'
        }
        url = self.__TOKEN_URL__.format(tenant=self.tenant_id)
        response = self.session.request('POST', url, data=body).json()
        self.token = response['access_token']

    def invoke(self, method, url, data=None):
        self.get_token()
        self.session.headers = {
            'Content-Type' : 'application/json',
            'Accept' : 'application/json',
            'Authorization' : "Bearer " + self.token
        }
        self.session.verify = True
        response = self.session.request(method, url, data=data)
        return response


class MDATPQuery(object):

    __ENDPOINT__ = 'advancedqueries/run'

    def __init__(self, mdatp_connector, query):
        self.connector = mdatp_connector
        self.query = query

    def execute(self):
        return_list = []
        url = self.connector.__APP_URL__ + '/api/' + self.__ENDPOINT__
        parameters = {}
        parameters.update({
            'Query' : self.query
        })
        response = self.connector.invoke(
            'POST',
            url, 
            data=json.dumps(parameters).encode("utf-8")
        )
        for result in json.loads(response.content)['Results']:
            return_list.append(result)
        return {
            'query_results': json.dumps(return_list)
        }

connector = MDATPConnector(
    __CLIENT_ID__,
    __CLIENT_SECRET__,
    __TENANT_ID__
)

query = '''
"RegistryEvents | limit 10"
'''
query = '''
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
'''

mdatp = MDATPQuery(
    connector,
    query
)

print(mdatp.execute())