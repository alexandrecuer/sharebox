# Ruby on Rails SharingFile System

Uses the following gems :
* [paperclip](https://github.com/thoughtbot/paperclip) for documents processing
* [devise](https://github.com/plataformatec/devise) for user authentification

## Installation on a Microsoft Window development machine
### Requirements
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
If not, you will have to modify the system and users paths so that they begin with C:\Program Files\ImageMagick-7.0.6-Q16\

On windows 10, from the control panel :
``
Security and System > System > Advanced System Parameters > Environment Variables
``

Gem file is configured to use postgreSQL, so please install PGQSL window binary
[EDB POSTGRES](https://www.enterprisedb.com/)

If you want to use another DBMS, you will have to change the gem file

### Installation
Clone the repository into your C:/Sites directory

Edit the set_env_var.bat file with your personal credentials and run this bat file from the main DOS shell. 
It will fix the environment details in all subsequent shells such as git bash or window power shell 

Please note that document storage is configured for Amazon S3

#### Use local file system for storage
If you want to use local file system for storage, please remove the paperclip section in the \config\environments\developpment.rb
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

#### Database configuration
Modify the \config\environments\database.yml with yout database credentials. 
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
To go faster, you don't have to run all the migrations from scratch :
```
$ rails db:schema:load
```

Please note that the bcrypt gem needed for devise may malfunction.
To correct, you have to reinstall manually
```
$ gem uninstall bcrypt
$ gem uninstall bcrypt-ruby
$ gem install bcrypt --platform=ruby
```

# Installation on Heroku (for production)
You will need a S3 bucket as Heroku has an ephemeral file system

