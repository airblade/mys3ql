# mys3ql = mysql + s3

Simple backup of your MySql database onto Amazon S3.


## Quick start

Install and configure as below.

To perform a full backup:

    $ mys3ql full

If you are using MySql's binary logging (see below), back up the binary logs like this:

    $ mys3ql incremental


## Installation

First install the gem:

    $ gem install mys3ql
    
Second, create your `~/.mys3ql` config file:

    mysql:
      # Database to back up
      database: aircms_production
      # MySql credentials
      user: root
      password:
      # Path (with trailing slash) to mysql commands e.g. mysqldump
      bin_path: /usr/local/mysql/bin/
      # If you are using MySql binary logging:
      # Path to the binary logs, should match the bin_log option in your my.cnf.
      # Comment out if you are not using mysql binary logging
      bin_log: /Users/andy/Desktop/mysql-bin

    s3:
      # S3 credentials
      access_key_id: XXXXXXXXXXXXXXXXXXXX
      secret_access_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      # Bucket in which to store your backups
      bucket: db_backups


## Binary logging

To use incremental backups you need to enable binary logging by making sure that the MySQL config file (my.cnf) has the following line in it:

    log_bin = /var/db/mysql/binlog/mysql-bin

The MySQL user needs to have the RELOAD and the SUPER privileges, these can be granted with the following SQL commands (which need to be executed as the MySQL root user):

    GRANT RELOAD ON *.* TO 'user_name'@'%' IDENTIFIED BY 'password';
    GRANT SUPER ON *.* TO 'user_name'@'%' IDENTIFIED BY 'password';


## Inspiration

Marc-André Cournoyer's [mysql_s3_backup](https://github.com/macournoyer/mysql_s3_backup).


## To Do

- tests ;)
- restore (pull latest dump, pull bin files, pipe dump into mysql, pipe binfiles into mysql)
- remove old dump files (s3)
- fix verbosity/debugging flag
