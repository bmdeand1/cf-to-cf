import functions_framework
import urllib

import google.auth.transport.requests
import google.oauth2.id_token


@functions_framework.http
def hello_http(request):
   endpoint = "${invokee_url}"

   req = urllib.request.Request(endpoint)
   auth_req = google.auth.transport.requests.Request()
   id_token = google.oauth2.id_token.fetch_id_token(auth_req, endpoint)
   req.add_header("Authorization", f"Bearer {id_token}")

   response = urllib.request.urlopen(req)
   
   return response.read()
