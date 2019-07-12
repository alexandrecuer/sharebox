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

<img src=imagemagick.png height=300>

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
## database

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
## launch the server in development mode

#### First option
Edit the set_env_var.bat file, fill it with your personal credentials and run this bat file from the main DOS shell. It will fix the environment details in all subsequent shells such as git bash or window power shell. You can start the server from a git bash with the classic method :
```
$ rails server
```

#### Second option 
On Windows, this second option may permit to override specific problems related to environment variables beginning with /. Edit the .env file and fill it with your personal credentials. Install [node-foreman](https://github.com/strongloop/node-foreman) and start the server from a git bash with the following command :
```
$ nf -p 3000 start -s -j Procfile_dev
```
