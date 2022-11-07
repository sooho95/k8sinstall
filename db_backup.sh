#!/bin/bash

DATE=$(date +"%Y-%m-%H:%M")
BACKUP_DIR=/db-backup/
mysqldump -u backup -p1234 intraweb > $BACKUP_DIR"intraweb-$DATE".sql
mysqldump -u backup -p1234 extraweb > $BACKUP_DIR"extraweb-$DATE".sql
mysqldump -u backup -p1234 mail > $BACKUP_DIR"mail-$DATE".sql


cd /db-backup
tar -cvf ./backupDB-$DATE.tar.gz intraweb-$DATE.sql extraweb-$DATE.sql mail-$DATE.sql
rm -f *.sql 

find /db-backup -name '*.gz' -ctime +150 -exec rm {} \;

sshpass -p 'rocky' scp -o StrictHostKeyChecking=no /db-backup/backupDB-$DATE.tar.gz db@211.100.2.64:/home/db
