#!/bin/bash

#This script seletively grabs all the information in LDAP and displays it in .csv format
#Remember to use colon (:) as the delimiter when opening the file in excel

#Created by light-saber
#Date 2014.07.13

ldapsearch -x "(objectClass=totalOfficeAccount)" | grep dn | grep -v "toadmin" | grep -v "smbadmin" | awk -F "=|," '{print $2}' > users.txt

if [ -s "list.csv" ]; then
        rm list.csv
        echo "Already existing output file deleted"
fi
echo "Creating new output file"

echo "Fullname:Login:Email Address:Alternate Email Address:Quota:Current Usage:Group" >>list.csv

while read line
do
        fullname=$(ldapsearch -x | grep -A 1 uid=$line | grep cn: | awk  '{print $2,$3}')
        email=$(ldapsearch -x uid=$line | grep mail: | awk '{print $2}')
        alternatemail=$(printf %s $(ldapsearch -x uid=$line | grep mailAlternateAddress: | awk '{print $2,","}'))
        quota=$(ldapsearch -x  uid=$line | grep quota | awk '{print $2}')
        used=$( sudo -u postgres psql -d dovecot -c "SELECT * from quota where username='$email'" 2>/dev/null | awk "NR==3" | cut -d " " -f4 | awk '{foo = $1/1024/1024; print foo}')
        group=$(printf %s $(ldapsearch -x maildrop=$email | grep "cn=" | awk -F "=|," '{print $2,","}'))
        echo "$fullname:$line:$email:$alternatemail:$quota:$used:$group" >> list.csv
done < users.txt

rm users.txt
echo "New list.csv file created"
echo "Remember to use colon (:) as the delimiter when opening in Excel"
echo "Thank you!"
echo "This file will be mailed to the given address"

cp list.csv /tmp
(uuencode /tmp/list.csv list.csv; echo "PFA the complete list of users") | mailx -s "Complete list of users" -a "From:toadmin@abc.com" "me@abc.com" 
