## Authenticating function to function calls 

Demo to show how to configure an invoker Cloud Function (2nd Gen) to call a second Cloud Function. Official Google documentation [here](https://cloud.google.com/functions/docs/securing/authenticating#functions-bearer-token-example-python). Chosen runtime Python 3.10.

The main.tf includes:

1. GCS bucket to store cloud function's code

2. Service Account including Cloud Role invoker role and Computer Engine Admin (Careful!!! The Compute Engine Admin role is used for demo purposes only. Make sure your Service Accounts include the bare minimun permissions needed.)

3. Invoker Cloud Function code.

This demo can be run as follows:

1. Run `terraform init`

2. Run `terraform apply`

3. Call cf-one url and verify web returns content served from cf-two -> "Hello World from fun 2!"
