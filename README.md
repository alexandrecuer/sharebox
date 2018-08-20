# Ruby on Rails SharingFile System

[![Build Status](https://travis-ci.org/alexandrecuer/sharebox.svg?branch=master)](https://travis-ci.org/alexandrecuer/sharebox)

Check online prototype : https://desolate-earth-32333.herokuapp.com/

Uses the following gems :
* [paperclip](https://github.com/thoughtbot/paperclip) for documents processing
* [devise](https://github.com/plataformatec/devise) for user authentification
* [passenger](https://www.phusionpassenger.com/library/walkthroughs/deploy/ruby/heroku/standalone/oss/deploy_app_main.html) as the application server (in standalone mode)
* [aws-sdk](https://github.com/aws/aws-sdk-ruby) for storage on S3

## Will have to switch from paperclip to [ActiveStorage](http://guides.rubyonrails.org/active_storage_overview.html) as paperclip is now deprecated

---
- [Installation on a Microsoft Window development machine](#installation-on-a-microsoft-window-development-machine)
  - [Requirements](#requirements)
    - [Rails](#rails)
    - [ImageMagick](#imagemagick)
    - [NodeJS](#nodejs)
  - [Installation](#installation)
    - [Setting environmental variables](#setting-environmental-variables)
    - [Database configuration](#database-configuration)
  - [File storage](#file-storage)
    - [Use Amazon S3](#use-amazon-s3)
- [Configuring mail services](#configuring-mail-services)
- [Installation on Heroku (for production)](#installation-on-heroku-for-production)
  - [From a development server](#from-a-development-server)
  - [From a github repository](#from-a-github-repository)
- [Customization](#customization)
- [Working behind a proxy server](#working-behind-a-proxy-server)
---

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
        <td rowspan=2><sub><a href=https://mail.google.com/>gmail</a></sub></td>
    </tr>
    <tr>
        <td><sub>GMAIL_PASSWORD</sub></td>
    </tr>
    <tr>
        <td><sub>SMTP_ADDRESS</sub></td>
        <td rowspan=2><sub>example if using gmail :<br><sub>SMTP_ADDRESS="smtp.gmail.com" and SMTP_PORT=587</sub></sub></td>
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
- local file system in development mode. In that case, the aws-sdk gem is not needed.

Switching between S3 mode and local storage mode can be done by modifying the value of config.local_storage 
- in /config/environments/development.rb 
- and in /config/environments/production.rb

with config.local_storage = 1, local storage will be activated<br>
with config.local_storage = 0, all files will go in the defined S3 bucket

<table>
  <tr>
    <td></td>
    <td valign=top>S3 storage</td>
    <td valogn=top>local storage</td>
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


# Configuring mail services
Assuming you are using gmail for mail delivery, you may need to configure your google account in order to allow external applications to use it 

<img src=public/images/doc/gmail_less_secure_apps.png>

https://www.google.com/settings/security/lesssecureapps

On a production server, it may be necessary to clear the captcha in order to define the production server as an authorized application with auto sign-in activated

https://accounts.google.com/DisplayUnlockCaptcha

The captcha is cleared for a few minutes. During that time, you can realize a password modification in order for your production server to be integrated in the list of authorized applications with auto sign-in activated.

<img src=public/images/doc/gmail_less_secure_captcha.png>


# Installation on Heroku (for production)
You will need an heroku account and a S3 bucket as Heroku has an ephemeral file system

## From a development server

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
## From a github repository

This is called github integration by the heroku team.

If you don't have a github account, create one and fork the sharebox repository to your account.




# Customization

Please modify \app\views\layouts\application.html.erb

# Working behind a proxy server

If you work behind a proxy, please set http_proxy and https_proxy variables
```
$ export https_proxy="http://user_name:password@proxy_url:proxy_port"
$ export http_proxy="http://user_name:password@proxy_url:proxy_port"
```
