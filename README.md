# Ruby on Rails SharingFile System

Check online prototype : https://desolate-earth-32333.herokuapp.com/

Uses the following gems :
* [paperclip](https://github.com/thoughtbot/paperclip) for documents processing
* [devise](https://github.com/plataformatec/devise) for user authentification
* [passenger](https://www.phusionpassenger.com/library/walkthroughs/deploy/ruby/heroku/standalone/oss/deploy_app_main.html) as the application server (in standalone mode)

# Installation on a Microsoft Window development machine
## Requirements
Window All-In-One rails installer [Ruby on Rails](http://railsinstaller.org/en) >= 5.1.4

[ImageMagick](http://www.imagemagick.org) for documents processing

Check https://github.com/thoughtbot/paperclip#requirements

ImageMagick uses two utilities file.exe and convert.exe
```
$ which file
/c/Program Files (x86)/GnuWin32/bin/file
$ which convert
/c/Program Files/ImageMagick-7.0.6-Q16/convert
```

Please note Window has got its own convert utility. Paperclip will not work with the Window convert.exe

So check that ImageMagick's convert.exe comes first
```
$ where convert
c:\Program Files\ImageMagick-7.0.6-Q16\convert.exe
c:\Windows\System32\convert.exe
```
If not, you will have to modify the system and user paths so that they begin with something like C:\Program Files\ImageMagick-7.0.6-Q16\

On windows 10, from the control panel :
``
Security and System > System > Advanced System Parameters > Environment Variables
``

Gem file is configured to use postgreSQL, so please install PGQSL window binary
[EDB POSTGRES](https://www.enterprisedb.com/)

If you want to use another DBMS, you will have to change the gem file

## Installation
Clone/Unzip the repository into your local rails'applications directory, for example C:/Sites/sharebox
Open your local app directory in a git bash 
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

### Settings environmental variables
##### First option
Edit the set_env_var.bat file, fill it with your personal credentials and run this bat file from the main DOS shell. It will fix the environment details in all subsequent shells such as git bash or window power shell. You can start the server from a git bash with the classic method :
```
$ rails server
```
Type http://localhost:3000 in Mozilla

##### Second option 
On Windows, this second option may permit to simply override specific problems related to environment variables beginning with /. Edit the .env file and fill it with your personal credentials. Install [node-foreman](https://github.com/strongloop/node-foreman) and start the server from a git bash with the following command :
```
$ nf start -s -j Procfile_dev
```
Type http://localhost:5000 in Mozilla


### Use local file system for storage
Document storage is configured for Amazon S3 but using local file system is possible

Remove the paperclip section in the \config\environments\developpment.rb
```
config.paperclip_defaults = {
    storage: :s3,
    s3_credentials: {
        bucket: ENV.fetch('S3_BUCKET_NAME'),
        access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
        secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
        s3_region: ENV.fetch('AWS_REGION'),
        s3_host_name: ENV.fetch('AWS_HOST_NAME'),
    }
}
```
Modify the get method in the \app\controllers\assets_controller.rb so that it uses send_file and not redirect_to
```
send_file asset.uploaded_file.path, :type => asset.uploaded_file_content_type
#redirect_to asset.uploaded_file.expiring_url(10)
```
Modify the asset model \app\models\model.rb
```
has_attached_file :uploaded_file,
     url: '/forge/get/:id/:filename',             
     path: ':rails_root/forge/attachments/:id/:filename'
     #url: ENV.fetch('AWS_URL'),
     #path: '/forge/attachments/:id/:filename',
     #s3_permissions: :private
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

# Configuring mail services
Assuming you are using gmail for mail delivering, you may need to configure your google account in order to allow external applications to use it 

<img src=public/images/doc/gmail_less_secure_apps.png>

https://www.google.com/settings/security/lesssecureapps

# Installation on Heroku (for production)
You will need a S3 bucket as Heroku has an ephemeral file system

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
Once succesfully logged, create a new heroku app and push the files with git :
```
$ heroku create
$ git init
$ git add .
$ git commit -a -m "Switch to production"
$ git push heroku master
```
Fix environmental variables
```
$ heroku config:set S3_BUCKET_NAME="your_bucket"
$ heroku config:set AWS_REGION="your_region"
$ heroku config:set AWS_HOST_NAME="your_host_name"
$ heroku config:set AWS_URL="your_url"
$ heroku config:set AWS_ACCESS_KEY_ID="your_access_key"
$ heroku config:set AWS_SECRET_ACCESS_KEY="your_secret_access_key"
```
If for some reason, one variable is not correctly fixed, you can correct it from the heroku dashboard.

Go to https://dashboard.heroku.com/apps > Settings > Reveal Config Vars

Create the database and the tables
```
$ rake db:create
$ rails db:schema:load
```

