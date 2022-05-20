#!/bin/bash
# ./backupScript.sh >> /ESXi-NAS/kmail/backupLogs.log 2>&1
# "At 23:00 on Saturday."
# 0 23 * * 6 ./backupScript.sh >> /ESXi-NAS/kmail/backupLogs.log 2>&1

before="$(date +%s)"
echo -e "\n ###################### Full Backup Started `date`##################### "

echo -e "\nStart Creating Directory Structure `date`"
for i in /ESXi-NAS/kmail{tmp,domains,admins,accounts,userPass,userData,aliases,signatures,tmp/signatures,,filters,filters/tmp,filters/name,distributionLists,mailBoxes}
do
        [ ! -d "$i" ] &&  mkdir -p "$i"
done

# Backup domains
echo -e "\nBacking up domains `date`"
zmprov gad > /ESXi-NAS/kmail/domains/domains.txt
echo "All domain listed `date`"

# Find all admin accounts
echo -e "\nFind all admin accounts `date`"
zmprov gaaa > /ESXi-NAS/kmail/admins/admins.txt
echo "Admin accounts found `date`"


#Find all Email Accounts
echo -e "\nFind all email accounts `date`"
zmprov -l gaa > /ESXi-NAS/kmail/accounts/userAccounts.txt
echo "All email accounts listed `date`"

#remove spam, ham and virus emails from the file
echo -e "\nRemove ham, spam and virus emails `date`"
sed  -i -r '/^spam|^ham|^virus|^galsync/d' /ESXi-NAS/kmail/accounts/userAccounts.txt
echo "Removed ham, spam and virus emails `date`"

# Get all Distribution lists and it's members
echo -e "\nGet all Distribution lists and it's members `date`"
zmprov gadl > /ESXi-NAS/kmail/distributionLists/distributinlist.txt
for i in `cat /ESXi-NAS/kmail/distributionLists/distributinlist.txt`; do zmprov gdlm $i > /ESXi-NAS/kmail/distributionLists/$i.txt ;echo "$i"; done
echo "Distribution lists and members done `date`"


# Find all email account's passwords
echo -e "\nFind all email account's passwords `date`"
for i in `cat /ESXi-NAS/kmail/accounts/userAccounts.txt`; do zmprov  -l ga $i userPassword | grep userPassword: | awk '{ print $2}' > /ESXi-NAS/kmail/userPass/$i.shadow; done
echo "All email account's passwords done `date`"

# Backup all user names , Display names and Given Names
echo -e "\nBackup all user names , Display names and Given Names `date`"
for i in `cat /ESXi-NAS/kmail/accounts/userAccounts.txt`; do zmprov ga $i  | grep -i Name: > /ESXi-NAS/kmail/userData/$i.txt ; done
echo "User names , Display names and Given Names done `date`"

# backup aliases
echo -e "\nBackup aliases `date`"
for i in `cat /ESXi-NAS/kmail/accounts/userAccounts.txt`; do zmprov ga  $i | grep zimbraMailAlias |awk '{print $2}' > /ESXi-NAS/kmail/aliases/$i.txt ;echo $i ;done
echo "Backup aliases done `date`"


# Some of your email accounts don't have alias. So the above created files may be an empty file. Remove those empty files as follows,
find /ESXi-NAS/kmail/aliases/ -type f -empty | xargs -n1 rm -v

# # Backup all email signatures
# echo -e "\nBackup all email signatures `date`"

# for i in `cat /ESXi-NAS/kmailaccounts/userAccounts.txt`; do
#         zmprov ga $i zimbraPrefMailSignatureHTML > /ESXi-NAS/kmailtmp/signature;
#         sed -i -e "1d" /ESXi-NAS/kmailtmp/signature ;
#         sed 's/zimbraPrefMailSignatureHTML: //g' /ESXi-NAS/kmailtmp/signature > /ESXi-NAS/kmailsignatures/$i.signature ;
#         rm -rf /ESXi-NAS/kmailtmp/signature;
#         `zmprov ga $i zimbraSignatureName > /ESXi-NAS/kmailtmp/name` ;
#         sed -i -e "1d" /ESXi-NAS/kmailtmp/name ;
#         sed 's/zimbraSignatureName: //g' /ESXi-NAS/kmailtmp/name > /ESXi-NAS/kmailsignatures/$i.name ;
#         rm -rf /ESXi-NAS/kmailtmp/name ;
#         echo "Signature  downloaded for .... $i `date`"
# done
# find /ESXi-NAS/kmailsignatures/ -type f -empty | xargs -n1 rm -v
# echo "Backup all email signatures done `date`"


# # Backup all email account filters
# echo -e "\nBackup all email account filters `date`"

# for i in `cat /ESXi-NAS/kmailaccounts/userAccounts.txt` ; do
#         zmprov ga $i zimbraMailSieveScript > /ESXi-NAS/kmailtmp/filter
#         sed -i -e "1d" /ESXi-NAS/kmailtmp/filter
#         sed 's/zimbraMailSieveScript: //g' /ESXi-NAS/kmailtmp/filter  > /ESXi-NAS/kmailfilter/$i.filter
#         rm -f /ESXi-NAS/kmailtmp/filter
#         echo "Filter  downloaded for .... $i `date`"
# done
# echo "Backup all email account filters done `date`"




# backup all email account
echo "\nBacking up email accounts `date`  "

for email in `cat /ESXi-NAS/kmail/accounts/userAccounts.txt`; do  echo "Started $email-- `date`";  /opt/zimbra/bin/zmmailbox -z -m $email getRestURL '//?fmt=tgz' >  /ESXi-NAS/kmail/mailBoxes/$email-$(date -d 'yesterday' '+%Y%m%d').tgz ;   echo "$email Done-- `date`"; done

# Calculates and outputs total time taken
after="$(date +%s)"
elapsed="$(expr $after - $before)"
hours=$(($elapsed / 3600))
elapsed=$(($elapsed - $hours * 3600))
minutes=$(($elapsed / 60))
seconds=$(($elapsed - $minutes * 60))
echo Backup started at: "$before"
echo Backup completed at: "$after"
echo Time taken: "$hours hours $minutes minutes $seconds seconds"

