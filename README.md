# mys3ql = mysql + s3

Simple backup of your MySQL database onto Amazon S3.

See [Example: mysqldump + mysqlbinlog for Backup and Restore](https://dev.mysql.com/doc/refman/5.7/en/mysqlbinlog-backup.html#mysqlbinlog-backup-example).


## Quick start

Install and configure as below.

To perform a full backup:

    $ mys3ql full

If you are using MySql's binary logging (see below), back up the binary logs like this:

    $ mys3ql incremental

To restore from the latest backup (plus binlogs if present):

    $ mys3ql restore

To restore a recent subset of binlogs:

    $ mys3ql restore --after NUMBER

– where NUMBER is a 6-digit binlog file number.

By default mys3ql looks for a configuration file at `~/.mys3ql`.  You can override this like so:

    $ mys3ql [command] -c FILE
    $ mys3ql [command] --config=FILE


## Installation

First install the gem:

    $ gem install mys3ql

Second, create your config file:

    mysql:
      # Database to back up
      database:
      # MySql credentials
      user:
      password:
      # Path (with trailing slash) to mysql commands e.g. mysqldump
      bin_path: /usr/local/mysql/bin/
      # If you are using MySql binary logging:
      # Path to the binary logs, should match the log_bin option in your my.cnf.
      # Comment out if you are not using mysql binary logging
      bin_log: /var/lib/mysql/binlog/mysql-bin

    s3:
      # S3 credentials
      access_key_id: XXXXXXXXXXXXXXXXXXXX
      secret_access_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      # Bucket in which to store your backups
      bucket: db_backups
      # AWS region your bucket lives in.
      # (I suspect you only need to specify this when your 'location' is in a different region.)
      #region: eu-west-1

If you only have one database to back up on your server, you can put the config file at `~/.mys3ql`.  Otherwise, tell the `mys3ql` command where the config file is with the `--config=FILE` switch.

## Binary logging

To use incremental backups you need to enable binary logging by making sure that the MySQL config file (`/etc/my.cnf`) has the following line in it:

    log_bin = /var/db/mysql/binlog/mysql-bin

The MySQL user needs to have the RELOAD and the SUPER privileges.  These can be granted with the following SQL commands (which need to be executed as the MySQL root user):

    GRANT RELOAD ON *.* TO 'user_name'@'%' IDENTIFIED BY 'password';
    GRANT SUPER ON *.* TO 'user_name'@'%' IDENTIFIED BY 'password';

You may need to run mys3ql's incremental backup with special permissions (sudo) depending on the ownership of the binlogs directory.

N.B. the binary logs contain updates to all the databases on the server.  This means you can only switch on incremental backups for one database per server, because the logs will be purged each time a database is dumped.


## Inspiration

Marc-André Cournoyer's [mysql_s3_backup](https://github.com/macournoyer/mysql_s3_backup).


## Intellectual property

Copyright 2011-2021 Andy Stewart (boss@airbladesoftware.com).

Released under the MIT licence.
