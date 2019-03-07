# A social network tool with your clients for your business

This application can also be qualified as a Ruby on Rails SharingFile System

If you deliver files and documents to your clients and if you want to record your clients'satisfaction, this tool is for you

If you are a developper, check online class documentation :
https://alexandrecuer.github.io/sharebox/

[![Build Status](https://travis-ci.org/alexandrecuer/sharebox.svg?branch=master)](https://travis-ci.org/alexandrecuer/sharebox)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/ed6f26a2613349e0a92b404d515a4b29)](https://www.codacy.com/app/alexandrecuer/sharebox?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=alexandrecuer/sharebox&amp;utm_campaign=Badge_Grade)

Check online prototype : https://desolate-earth-32333.herokuapp.com/

Uses the following gems :
* [paperclip](https://github.com/thoughtbot/paperclip) for documents processing
* [devise](https://github.com/plataformatec/devise) for user authentification
* [passenger](https://www.phusionpassenger.com/library/walkthroughs/deploy/ruby/heroku/standalone/oss/deploy_app_main.html) as the application server (in standalone mode)
* [aws-sdk](https://github.com/aws/aws-sdk-ruby) for storage on S3
* [bootstrap](https://github.com/twbs/bootstrap-rubygem) as the frontoffice framework
* [font-awesome](https://github.com/bokmann/font-awesome-rails) for icons and cosmectic details

## Will have to switch from paperclip to [ActiveStorage](http://guides.rubyonrails.org/active_storage_overview.html) as paperclip is now deprecated

<img src=public/images/doc/colibri_front.png>

# Deployment to Heroku through GitHub integration
This application has been designed for an automatic deployment from github to the heroku cloud
You will need a S3 bucket as Heroku has an ephemeral file system
## Fork and customize the repository to your needs
Assuming you have a GitHub account and you are logged in, fork the sharebox repository into your GitHub account

<img src=public/images/doc/01_fork.png>

To customize the application to your needs, edit the following files 
- config/config.yml
- config/initializers/devise.rb

<img src=public/images/doc/02_customization.png>

You have to setup the following parameters :
- in config.yml, site_name and admin_mel
- in devise.rb, config.mailer_sender

admin_mel will receive activity notifications : new shares, pending users. Pending users are unregistered users benefiting from at least one shared access to a folder

config.mailer_sender will be the sending email as far as authentification issues are considered (eg password changes)

You can find the two site’s logos in the /app/assets/images directory 

<img src=public/images/doc/03_site_logos.png>

colibri.jpg is the main logo appearing above the login box

logo.jpg is the logo used in emails sent by private users to public users

The sharebox repository Gemfile may suggest a ruby version not suitable with the recommanded heroku stack, that is to say created with a deprecated heroku stack

~~For the heroku-18 stack, please note you will  have to proceed to the following modifications~~
~~- in the Gemfile, change ``ruby '2.3.3'`` to ``ruby '2.5.1'``~~
~~- in the Gemfile.lock, RUBY VERSION section, change ``ruby 2.3.3p222`` to ``ruby 2.5.1p57``~~

## Create a new Heroku app and link it to the GitHub repository previously forked
Create an heroku account if you do not have one yet, and once logged in, access to the heroku dashboard in order to create a new heroku app, here named « cerema-autun »

<img src=public/images/doc/04_create_app.png>

Once the application is created, you will be redirected to the application control panel

Go to the deploy tab and choose the GitHub deployment method (Please note you need to be logged into your GitHub account)

<img src=public/images/doc/05_connect_to_github_1.png>

<img src=public/images/doc/06_connect_to_github_2.png>

Your GitHub and heroku accounts are now linked together.

## Fill all the needed config variables
Before proceeding to a deployment, fill all the needed config vars.

11 config vars are needed by the sharebox application and if one is missing, the deployment will fail.

<img src=public/images/doc/07_config_vars.png>

If the bucket does not exist, it will be created when the first file will be uploaded to S3.

Everything is ready for a manual deploy.

## Proceed to a manual deploy
<img src=public/images/doc/08_manual_deploy.png>

The manual deploy will initialize the missing config variables, related to Heroku and create an empty database. 
Just create the database tables with a rake db:schema:load command in the Heroku console and your app is on line.

<img src=public/images/doc/09_create_table.png>

Please note that the first user to register in the system will be given admin rights !!

# Installation on a Microsoft Window development machine
## Requirements
Window All-In-One rails installer [Ruby on Rails](http://railsinstaller.org/en) >= 5.1.4 + NodeJS

[ImageMagick](http://www.imagemagick.org) for documents processing

Gem file is configured to use postgreSQL, so please install PGQSL window binary
[EDB POSTGRES](https://www.enterprisedb.com/)

If you want to use another DBMS, you will have to change the gem file

### Rails

After having run RailsInstaller, launch a git bash, verify ruby version ``ruby -v``, install Rails ``gem install rails`` and verify the version :
```
$ rails -v
Rails 5.1.5
```
Check you can create a new application named blog ``rails new blog``

The system will create the app files and launch the command ``bundle install`` to fetch some gems

Launch the server with the command ``rails server``. The server should be up on port 3000. Browse the adress http://localhost:3000 in Mozilla.

### ImageMagick

For a more detailed procedure, check https://github.com/thoughtbot/paperclip#requirements

ImageMagick uses two utilities file.exe and convert.exe

You will have to install file.exe from [gnuwin32](http://gnuwin32.sourceforge.net/packages/file.htm)

When you install ImageMagick, don't forget to include the required legacy utilities among which you will find convert.exe

<img src=public/images/doc/imagemagick.png height=300>

Modify the system and user paths so that they begin with something like C:\Program Files\ImageMagick-7.0.6-Q16\ and C:\Program Files (x86)\GnuWin32.

On windows 10, from the control panel :
``
Security and System > System > Advanced System Parameters > Environment Variables
``

Please note Window has got its own convert utility. Paperclip will not work with the Window convert.exe. ImageMagick's convert.exe should come first
```
$ where convert
c:\Program Files\ImageMagick-7.0.6-Q16\convert.exe
c:\Windows\System32\convert.exe
```
Check if everything is OK in the rails git bash :
```
$ which file
/c/Program Files (x86)/GnuWin32/bin/file
$ which convert
/c/Program Files/ImageMagick-7.0.6-Q16/convert
```

### NodeJS

Install [NodeJS](https://nodejs.org/en/download/)

## Installation
Clone/Unzip the repository into your local rails directory, for example C:/Sites/. 
Open the resulting app directory in a git bash 
```
$ cd /c/Sites/sharebox
```
Install the required gems ``$ bundle install`` or ``$ bundle update``

Please note that the bcrypt gem needed for devise may malfunction.
To correct, you have to reinstall manually
```
$ gem uninstall bcrypt
$ gem uninstall bcrypt-ruby
$ gem install bcrypt --platform=ruby
```

### Setting environmental variables
The application uses several variables, which you have to fix in the environment
<table><tr><td valign=top>For S3 storage
<table>
    <tr>
        <td><sub>S3_BUCKET_NAME</sub></td>
        <td><sub><a href=https://devcenter.heroku.com/articles/s3#s3-setup>Heroku specific doc</a></sub></td>
    </tr>
    <tr>
        <td><sub>AWS_REGION</sub></td>
        <td rowspan=2><sub><a href=https://docs.aws.amazon.com/fr_fr/general/latest/gr/rande.html#s3_region>AWS regional parameters</a><br><sub> ex : AWS_REGION=eu-west-3 and AWS_HOST_NAME=s3.eu-west-3.amazonaws.com</sub></sub></td> 
    </tr>
    <tr>
        <td><sub>AWS_HOST_NAME</sub></td>
    </tr>
    <tr>
        <td><sub>AWS_URL</sub></td>
        <td><sub>S3_BUCKET_NAME.AWS_HOST_NAME</sub></td>
    </tr>
    <tr>
        <td><sub>AWS_ACCESS_KEY_ID</sub></td>
        <td rowspan=2><sub><a href=https://console.aws.amazon.com/iam/home#/users>IAM - Identity and Access Management</a></sub></td>
    </tr>
    <tr>
        <td><sub>AWS_SECRET_ACCESS_KEY</sub></td>
    </tr>
</table>
</td><td valign=top>For Mail delivery
<table>
    <tr>
        <td><sub>GMAIL_USERNAME</sub></td>
        <td rowspan=2>
          SendGrid is the preferred option<br>
          <sub><a href=https://sendgrid.com/>sendgrid</a></sub><br><br>
          <sub><a href=https://mail.google.com/>gmail</a></sub><br>
          <sub>Please note gmail is not a reliable solution as a backoffice mailer</sub><br>
          <sub>if, however, you were considering using gmail for mail delivery, you may need to configure your google account in order to allow external applications to use it</sub><br>
          <sub><a href=https://www.google.com/settings/security/lesssecureapps>lesssecureapps</a></sub><br>
          <sub><a href=https://accounts.google.com/DisplayUnlockCaptcha>unlockcaptach</a></sub><br>
        </td>
    </tr>
    <tr>
        <td><sub>GMAIL_PASSWORD</sub></td>
    </tr>
    <tr>
        <td><sub>SMTP_ADDRESS</sub></td>
        <td rowspan=2><sub>example if using sendgrid :<br><sub>SMTP_ADDRESS="smtp.sengrid.net" and SMTP_PORT=587</sub></sub></td>
    </tr>
    <tr>
      <td><sub>SMTP_PORT</sub></td>
    </tr>
    <tr>
      <td><sub>DOMAIN</sub></td>
      <td><sub>In development mode :<br><sub>localhost</sub><br>For a production server :<br><sub>ip address or domain name of the server</sub></sub></td>
    </tr>
</table>
</td></tr></table>
        
##### First option
Edit the set_env_var.bat file, fill it with your personal credentials and run this bat file from the main DOS shell. It will fix the environment details in all subsequent shells such as git bash or window power shell. You can start the server from a git bash with the classic method :
```
$ rails server
```

##### Second option 
On Windows, this second option may permit to override specific problems related to environment variables beginning with /. Edit the .env file and fill it with your personal credentials. Install [node-foreman](https://github.com/strongloop/node-foreman) and start the server from a git bash with the following command :
```
$ nf -p 3000 start -s -j Procfile_dev
```

### Database configuration
Modify the \config\environments\database.yml with your database credentials. 
Generally, the postgreSQL Window installer creates a user "postgres" for which you were asked a password during the installation process. 
```
default: &default
  adapter: postgresql
  encoding: unicode
  # For details on connection pooling, see Rails configuration guide
  # http://guides.rubyonrails.org/configuring.html#database-pooling
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: postgres
  password: your_pass
  host: localhost
```

Create the database and the tables
```
$ rake db:create
$ rails db:migrate
```
To create the database structure and the tables, you don't have to run all the migrations from scratch :
```
$ rails db:schema:load
```

## File storage

Document storage is configured for : 
- Amazon S3 in production mode 
- local file system in development mode. In that case, the aws-sdk gem is not used.

Switching between S3 mode and local storage mode can be done by modifying the value of config.local_storage 
- in /config/environments/development.rb 
- and in /config/environments/production.rb

with config.local_storage = 1, local storage will be activated<br>
with config.local_storage = 0, all files will go in the defined S3 bucket

<table>
  <tr>
    <td></td>
    <td valign=top>S3 storage</td>
    <td valign=top>local storage</td>
  </tr>
  <tr>
    <td>\config\environments\developpment.rb</td>
    <td width=50%><sub>
      config.paperclip_defaults = {<br>
        storage: :s3,<br>
        s3_credentials: {<br>
          bucket: ENV.fetch('S3_BUCKET_NAME'),<br>
          access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),<br>
          secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),<br>
          s3_region: ENV.fetch('AWS_REGION'),<br>
          s3_host_name: ENV.fetch('AWS_HOST_NAME'),<br>
        }<br>
      }
      </sub>
    </td>
    <td></td>
  </tr>
  <tr>
    <td>\app\models\asset.rb</td>
    <td width=50%><sub>
      has_attached_file :uploaded_file,<br>
      url: ENV.fetch('AWS_URL'),<br>
      path: '/forge/attachments/:id/:filename',<br>
      s3_permissions: :private
      </sub>
    </td>
    <td width=50%><sub>
      has_attached_file :uploaded_file,<br>
      url: '/forge/get/:id/:filename',<br>      
      path: ':rails_root/forge/attachments/:id/:filename'<br>
      </td>
  </tr>
  <tr>
    <td>\app\controllers\assets_controller.rb</td>
    <td><sub>
      redirect_to asset.uploaded_file.expiring_url(10)
      </sub>
    </td>
    <td><sub>
      send_file asset.uploaded_file.path, :type => asset.uploaded_file_content_type
      </sub>
    </td>
  </tr>
</table>

### Use Amazon S3
You may encounter difficulties due to some SSL defaults on your development machine.

To override, create a file /config/initializers/paperclip.rb with the following command
```
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
```
Caution : only for a development purpose; not suitable for a production server !

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

# Working behind a proxy server

If you work behind a proxy, please set http_proxy and https_proxy variables
```
$ export https_proxy="http://user_name:password@proxy_url:proxy_port"
$ export http_proxy="http://user_name:password@proxy_url:proxy_port"
```
