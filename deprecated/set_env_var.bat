rem this file has to be run from a classic dos command shell not from the git shell
rem setx does not set the environment variable in the current command prompt but in all the subsequent ones
setx S3_BUCKET_NAME "your_bucket_name"

rem for REGION and HOST_NAME
rem check https://docs.aws.amazon.com/fr_fr/general/latest/gr/rande.html#s3_region
setx AWS_REGION "your_S3_region"
rem for example eu-west-3
setx AWS_HOST_NAME "your S3_host_name"

rem URL is BUCKET_NAME.HOST_NAME
setx AWS_URL "your_aws_url"

setx AWS_ACCESS_KEY_ID "your_access_key"
setx AWS_SECRET_ACCESS_KEY "your_secret_acces_key"

rem assuming you are using gmail
setx GMAIL_USERNAME "your_gmail_address"
setx GMAIL_PASSWORD "your_gmail_pass"
setx SMTP_ADDRESS "your_smtp_server_address"
setx SMTP_PORT your_smtp_server_port
setx DOMAIN localhost
