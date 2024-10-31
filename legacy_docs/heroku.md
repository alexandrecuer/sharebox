# Deployment to Heroku through GitHub integration
This application has been designed for an automatic deployment from github to the heroku cloud
You will need a S3 bucket as Heroku has an ephemeral file system
Here are the main steps :
- Fork and customize the repository to your needs
- Create a new Heroku app and link it to the GitHub repository previously forked
- Fill all the eleven needed config variables (AWS_ACCESS_KEY_ID, AWS_HOST_NAME, AWS_REGION, AWS_SECRET_ACCESS_KEY, AWS_URL, DOMAIN, GMAIL_PASSWORD, GMAIL_USERNAME, S3_BUCKET_NAME, SMTP_ADDRESS, SMTP_PORT plus an extra one: TEAM)
- Proceed to a manual deploy

To customize the application to your needs, check the following files 
- config/config.yml (site_name and admin_mel)
- config/initializers/devise.rb (config.mailer_sender)

admin_mel will receive activity notifications : new shares, pending users. Pending users are unregistered users benefiting from at least one shared access to a folder

config.mailer_sender will be the sending email as far as authentification issues are considered (eg password changes)

You can find the two site’s logos in the /app/assets/images directory

Please note that the first user to register in the system will be given admin rights !!

for more details : [deploy on heroku in images](files/deploy_on_heroku.pdf)


# Installation on Heroku (for production) from a development server
If you don't want to use the github integration method, an alternative option is possible

Install [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)

Or https://cli-assets.heroku.com/branches/stable/heroku-windows-amd64.exe

Open your local app directory in a git bash, and login to Heroku :
```
$ cd /c/Sites/sharebox
$ heroku login
Enter your Heroku credentials:
Email: alexandre.cuer@cerema.fr
Password: *************
Logged in as alexandre.cuer@cerema.fr
```
Once succesfully logged, create a new heroku app :
```
$ heroku create
Creating app... done, desolate-earth-32333
https://desolate-earth-32333.herokuapp.com/ | https://git.heroku.com/desolate-earth-32333.git
```
Heroku will define a random name for your production server, here : desolate-earth-32333.

Push the files with git.
```
$ git init
$ git add .
$ git commit -a -m "Switch to production"
$ git push heroku master
```
Fix environmental variables (we assume you are using gmail)
```
$ heroku config:set S3_BUCKET_NAME="your_bucket"
$ heroku config:set AWS_REGION="your_region"
$ heroku config:set AWS_HOST_NAME="your_host_name"
$ heroku config:set AWS_URL="your_url"
$ heroku config:set AWS_ACCESS_KEY_ID="your_access_key"
$ heroku config:set AWS_SECRET_ACCESS_KEY="your_secret_access_key"
$ heroku config:set GMAIL_USERNAME="your_gmail_address"
$ heroku config:set GMAIL_PASSWORD="your_gmail_password"
$ heroku config:set SMTP_ADDRESS="smtp.gmail.com"
$ heroku config:set SMTP_PORT=587
$ heroku config:set DOMAIN="desolate-earth-32333.herokuapp.com"
```
If for some reason, one variable is not correctly fixed, you can correct it from the heroku dashboard.

Go to https://dashboard.heroku.com/apps > Settings > Reveal Config Vars

Create the database and the tables
```
$ heroku run rake db:schema:load
```
