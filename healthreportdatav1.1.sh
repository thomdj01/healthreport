#bin/bash

#This Script Will Produce the necessary CSVs for the health check word document deliverable
#version 1.1
#Dietrick Thomas
#
#
#

#this allows for the script to run from /home/tpx-admin

alias d='cd /tmp/'

d



#Get the Necessary Variables

echo "Creating Variables..."

#Declare colors for errors and other possible things
		
	red='\e[1;31m%s\e[0m\n\n'
	green='\e[1;32m%s\e[0m\n'
	yellow='\e[1;33m%s\e[0m\n'
	blue='\e[1;34m%s\e[0m\n'
	magenta='\e[1;35m%s\e[0m\n'
	cyan='\e[1;36m%s\e[0m\n'

#gets alerts dataset number
	alerts=`sudo -u extension psql -P "tuples_only" -P "footer=off" -c "SELECT table_name FROM information_schema.tables WHERE table_name LIKE  'dataset_' || (SELECT id FROM base_datasets WHERE name='Alerts')" extension_prod`

#gets deliveries dataset number 
	deliveries=`sudo -u extension psql -P "tuples_only" -P "footer=off" -c "SELECT table_name FROM information_schema.tables WHERE table_name LIKE  'dataset_' || (SELECT id FROM base_datasets WHERE name='Deliveries')" extension_prod`

#gets deliveries dataset number
	responses=`sudo -u extension psql -P "tuples_only" -P "footer=off" -c "SELECT table_name FROM information_schema.tables WHERE table_name LIKE  'dataset_' || (SELECT id FROM base_datasets WHERE name='Responses')" extension_prod`

#gets beds dataset number
	beds=`sudo -u extension psql -P "tuples_only" -P "footer=off" -c "SELECT table_name FROM information_schema.tables WHERE table_name LIKE  'dataset_' || (SELECT id FROM base_datasets WHERE name='Beds')" extension_prod`

#gets rooms dataset
	rooms=`sudo -u extension psql -P "tuples_only" -P "footer=off" -c "SELECT table_name FROM information_schema.tables WHERE table_name LIKE  'dataset_' || (SELECT id FROM base_datasets WHERE name='Rooms')" extension_prod`

#gets units dataset
	units=`sudo -u extension psql -P "tuples_only" -P "footer=off" -c "SELECT table_name FROM information_schema.tables WHERE table_name LIKE  'dataset_' || (SELECT id FROM base_datasets WHERE name='Units')" extension_prod`

#gets devices dataset
	devices=`sudo -u extension psql -P "tuples_only" -P "footer=off" -c "SELECT table_name FROM information_schema.tables WHERE table_name LIKE  'dataset_' || (SELECT id FROM base_datasets WHERE name='Devices')" extension_prod`

#gets devices dataset
	registrationhistory=`sudo -u extension psql -P "tuples_only" -P "footer=off" -c "SELECT table_name FROM information_schema.tables WHERE table_name LIKE  'dataset_' || (SELECT id FROM base_datasets WHERE name='RegistrationHistory')" extension_prod`

#gets to dataset
	to=`sudo -u extension psql -P "tuples_only" -P "footer=off" -c "SELECT table_name FROM information_schema.tables WHERE table_name LIKE  'dataset_' || (SELECT id FROM base_datasets WHERE name='To')" extension_prod`
	
	
	
#make directory to put csvs in
echo "Creating directory /tmp/healthreportdata/..."
mkdir /tmp/healthreportdata
filedir=/tmp/healthreportdata
sudo chmod -R o+rw $filedir
worddata=$filedir/wordDocumentData.txt

#Linebreak function
		function linebreak {
			printf '\n-------------------------\n\n' >> $worddata
		}
		
#New line function 
		function newline {
			printf "\n" >> $worddata
		}

###Executive summary chart
linebreak
echo "Executive Summary" > $worddata
linebreak

#Get Version Number

echo "Version Number:" >> $worddata
newline

rpm -qa --queryformat '%-50{NAME} %10{VERSION} %10{ARCH}\n' | grep extension-core >> $worddata

linebreak

#Get Audit Recipients
echo "Getting audit log destination settings..."
	
#Verify SMTP system notifications are configured
#stored in /etc/msmtprc

echo "Audit Destinations:" >> $worddata

printf "SMTP system notifications:\n\n" >> $worddata

#If the SMTP settings file exists, print it to the mhcr
if [ -e /etc/msmtprc ] ;
	then {
	sudo cat /etc/msmtprc | sed '1,7d' >> $worddata
	
	}
	else {
	printf "$red" "SMTP system notifications are not set up." >> $worddata
	
	}
fi	
	

#Verify SNMP system notifications are configured
#stored in /etc/snmp/snmpd.conf

printf "\n\nSNMP system notifications:\n\n" >> $worddata

if [ -e /etc/snmp/snmpd.conf ] ;
	then {
		
		#if [[ $(ls -alh /opt/EXTENSION/backups/ | grep "$backupDate") ]] ;
		if [[ $(sudo grep "trap" /etc/snmp/snmpd.conf) ]] ;
			then {
				sudo tail -2 /etc/snmp/snmpd.conf | sed 's/trap//' | sed 's/2sink//' >> $worddata
				
				}
			else {
				printf "$red" "SNMP system notifications are not set up." >> $worddata
				
			}
		fi	
	}
	else {
	printf "$red" "Did not find conf file." >> $worddata
	
	}
fi

	
#Verify Syslog system notifications are configured 
#stored in /etc/rsyslog.conf

printf "\n\nSyslog system notifications:\n\n" >> $worddata

if [ -e /etc/rsyslog.conf ] ;
	then {
		sudo cat /etc/rsyslog.conf | tail -2 | sed -n '1p' >> $worddata
		
	}
	else {
		printf "$red" "Syslog system notifications not found." >> $worddata
		
	} 

fi

linebreak

#Get Backup Locations

#Verify daily backups are exporting to an external location STILL IN DEVELOPMENT
	#Set variable for the backup directory
	
	echo "Backup information" >> $worddata
	
	echo "Checking backup information..."
	backupdir=/opt/EXTENSION/conf/.backup

	#Gather if extension appliance type is set to Primary or Secondary
	
	printf "Extension appliance type: " >> $worddata
	sudo cat $backupdir/.common/common.conf >> $worddata
	
	
	#Gather what times and if local daily backup is enabled

	printf "Local Machine Options: \n\n" >> $worddata 
	printf "Enable local daily backup: " >> $worddata
	sudo sed -n '1p' $backupdir/.local/local.conf >> $worddata
	printf "Number of backups to retain: " >> $worddata
	sudo sed -n '2p' $backupdir/.local/local.conf >> $worddata

	printf "\n\nDaily backup / cleanup time: " >> $worddata
	printf "\nHour: " >> $worddata
	sudo sed -n '2p' $backupdir/.crontime/crontime.conf >> $worddata
	printf "Minute: " >> $worddata
	sudo sed -n '1p' $backupdir/.crontime/crontime.conf >> $worddata
	
	
	#Check to see if SMB backups are set up
		if [ -e $backupdir/.smb/smb.conf ] && [ -s $backupdir/.smb/smb.conf ] ;
			then {
				if [ "$(sudo sed -n '1p' $backupdir/.smb/smb.conf)" == true ] ;
					then {
						echo Found SMB information
						printf "\nSMB backup information:\n" >> $worddata
						printf "\nEnabled: " >> $worddata
						sudo sed -n '1p' $backupdir/.smb/smb.conf >> $worddata
						printf "Domainname: " >> $worddata
						sudo sed -n '2p' $backupdir/.smb/smb.conf >> $worddata
						printf "Username: " >> $worddata
						sudo sed -n '3p' $backupdir/.smb/smb.conf >> $worddata
						printf "Password: " >> $worddata 
						sudo sed -n '4p' $backupdir/.smb/smb.conf >> $worddata
						printf "Server name or IP address: " >> $worddata
						sudo sed -n '5p' $backupdir/.smb/smb.conf >> $worddata
						printf "Server share name: " >> $worddata	
						sudo sed -n '6p' $backupdir/.smb/smb.conf >> $worddata
						}
					else {
						newline
						printf "$red" "++SMB Backup is not setup" >> $worddata
						}
				fi	
				}
			else {
				newline
				printf "$red" "SMB Backup is not setup" >> $worddata

				}
		fi
		
		#Check to see if FTP backups are set up
		if [ -e $backupdir/.ftp/ftp.conf ] && [ -s $backupdir/.ftp/ftp.conf ] ;
			then {
				if [ "$(sudo sed -n '1p' $backupdir/.ftp/ftp.conf)" == true ] ;
					then {
						echo Found FTP information
						printf "\n\nFTP backup information:\n" >> $worddata
						printf "\nEnabled: " >> $worddata
						sudo sed -n '1p' $backupdir/.ftp/ftp.conf >> $worddata
						printf "Destination Host: " >> $worddata
						sudo sed -n '2p' $backupdir/.ftp/ftp.conf >> $worddata
						printf "Destination Subdirectory: " >> $worddata
						sudo sed -n '3p' $backupdir/.ftp/ftp.conf >> $worddata
						printf "Username: " >> $worddata 
						sudo sed -n '4p' $backupdir/.ftp/ftp.conf >> $worddata
						printf "Password: " >> $worddata
						sudo sed -n '5p' $backupdir/.ftp/ftp.conf >> $worddata
						}
					else {
						newline
						printf "$red" "++FTP Backup is not setup" >> $worddata
						}
				fi	
			}
		else {
			newline
			printf "$red" "++FTP Backup is not setup" >> $worddata

			}
		fi
		
		#Check to see if SFTP backups are set up
		if [ -e $backupdir/.sftp/sftp.conf ] && [ -s $backupdir/.sftp/sftp.conf ] ;
			then {
				if [ "$(sed -n '1p' $backupdir/.sftp/sftp.conf)" == true ] ;
					then {
						echo Found SFTP information
						printf "\n\nSFTP backup information:\n" >> $worddata
						printf "\nEnabled: " >> $worddata
						sudo sed -n '1p' $backupdir/.sftp/sftp.conf >> $worddata
						printf "Destination Host: " >> $worddata
						sudo sed -n '2p' $backupdir/.sftp/sftp.conf >> $worddata
						printf "Destination Subdirectory: " >> $worddata
						sudo sed -n '3p' $backupdir/.sftp/sftp.conf >> $worddata
						printf "Username: " >> $worddata 
						sudo sed -n '4p' $backupdir/.sftp/sftp.conf >> $worddata
						}
					else {
					newline
					printf "$red" "++SFTP Backup is not setup" >> $worddata

						}
				fi		
			}
		else {
			newline
			printf "$red" "SFTP Backup is not setup" >> $worddata

			}
		fi

		#Check to see if transfer to secondary backups are set up
		
		if [ -e $backupdir/.scp/scp.conf ] && [ -s $backupdir/.scp/scp.conf ] ;
			then {
				if [ "$(sed -n '1p' $backupdir/.scp/scp.conf)" == true ] ;
					then {
						echo Found secondary backup settings...
						printf "\n\nTransfer to secondary backup information:\n" >> $worddata
						printf "\nEnabled: " >> $worddata
						sudo sed -n '1p' $backupdir/.scp/scp.conf >> $worddata
						printf "Secondary Appliance: " >> $worddata
						sudo sed -n '2p' $backupdir/.scp/scp.conf >> $worddata
						}
					else {
						newline
						printf "$red" "++Transfer to Secondary Backup is not setup" >> $worddata
						}
				fi
				}
			else {
			newline
			printf "$red" "Transfer to Secondary Backup is not setup" >> $worddata
			

				}
		fi
		
		
		echo Done
		
	linebreak 




#Clustered?

echo "Is the current appliance clustered?" >> $worddata


hostname -I >> $worddata

echo "If is more than one IP then the system is clustered." >> $worddata

linebreak

#Get hard drive size

echo "Hard Disk Space" >> $worddata


df -h >> $worddata

linebreak

#Get Ram

echo "RAM" >> $worddata


free -m >> $worddata

linebreak

#Get CPU Cores

echo "CPU information" >> $worddata

lscpu | egrep '^Thread|^Core|^Socket|^CPU\(' >> $worddata

linebreak

#Is remote access available?
#The firewall needs to check port 22 and whether or not it is open
#user should know whether or not RS can be used however

echo "RS Available?" >> $worddata

sudo iptables -L -vn | grep 22 >> $worddata

linebreak

###Current Devices chart

#Get devices currently is use
#this joins the devices dataset to the registration history dataset, $alerts23 is devices, $alerts55 is registration history.
#had to change the updated at to devices because if a site uses vocera or oai phones, we dont get that information from them.
echo "Devices" >> $worddata

sudo -u extension psql -c "\copy (
select distinct vendor,application_version,hardware_version,os_version, count(distinct $devices.id) from $devices left join $registrationhistory on $devices.id=$registrationhistory._device 
where status like 'Registered'
and $devices.updated_at > (now() - interval '14 days')
group by vendor,application_version,hardware_version,os_version
)
to '$filedir/devices.csv' CSV header delimiter ','" extension_prod

#format the file to look like this [data][data][data][data]
cat $filedir/devices.csv |  sed 's/,/][/g' | sed 's/^/[/g' | sed 's/$/]/g' >> $worddata

rm $filedir/devices.csv

linebreak

##### Current System chart

echo "Current System Chart" >> $worddata
linebreak

#Version Number again

echo "Version Number:" >> $worddata

newline

rpm -qa --queryformat '%-50{NAME} %10{VERSION} %10{ARCH}\n' | grep extension-core >> $worddata

linebreak

#Get standard solution

sudo -u extension psql -c "\copy (
select name from packages
)
to '$filedir/packages.csv' CSV header delimiter ','" extension_prod

cat $filedir/packages.csv | sed 's/,/\t/' >> $worddata

linebreak

rm $filedir/packages.csv


#Get number of users
userscount=`sudo -u extension psql -P "tuples_only" -P "footer=off" -c "select count(distinct id) from actors where type='User' and active='t'" extension_prod`

echo "Number of users:" >> $worddata
echo "$userscount" >> $worddata
linebreak

#get number of groups
#$alerts03 is to dataset, concrete_id 185 is groups
groupnumber=`sudo -u extension psql -P "tuples_only" -P "footer=off" -c "select id from base_datasets where name='Groups'" extension_prod`
groupcount=`sudo -u extension psql -P "tuples_only" -P "footer=off" -c "select count(distinct name) from $to where concrete_id=$groupnumber" extension_prod`

echo "Number of Groups" >> $worddata
echo "$groupcount" >> $worddata
linebreak




#get number of beds
#dataset 111 is beds dataset
bedcount=`sudo -u extension psql -P "tuples_only" -P "footer=off" -c "select count(distinct id) from $beds" extension_prod`

echo "Number of Beds" >> $worddata
echo "$bedcount" >> $worddata
linebreak

#get number of rooms
#dataset 167 is rooms dataset

roomcount=`sudo -u extension psql -P "tuples_only" -P "footer=off" -c "select count(distinct id) from $rooms" extension_prod`

echo "Number of rooms" >> $worddata
echo "$roomcount" >> $worddata
linebreak

#Get number of units
#dataset 173 is units dataset

unitcount=`sudo -u extension psql -P "tuples_only" -P "footer=off" -c "select count(distinct id) from $units" extension_prod`

echo "Number of units" >> $worddata
echo "$unitcount" >> $worddata
linebreak


#get active adapters

echo "Finding enabled adapters..."

echo "Active Adapters:" >> $worddata

sudo -u extension psql -c "\copy (
select reference_name from actors where active='t' and type='Interface'
)
to '$filedir/activeAdapters.txt'" extension_prod

cat $filedir/activeAdapters.txt >> $worddata

rm $filedir/activeAdapters.txt 

linebreak




#Print out a list of enabled adapters (active adapters)

#	echo "Finding enabled adapters..."
#	printf "Enabled Adapters:\n\nID   Reference Name\n" >> $worddata
#	sudo -u extension psql -c "\copy (select id,reference_name from actors where active='t' and type='Interface') to '$tmpfiledir/enabledadapters.txt'" extension_prod 
#	cat $tmpfiledir/enabledadapters.txt >> $worddata

#	linebreak





#in case an interval needs to be issued
#select alert_type,created_at from $alerts where $alerts.created_at > (now() - interval '14 days') order by created_at asc;
	
	
#Alerts Totals by hour	
#took out responses.action is not null from the deliveries and the alerts
#took out and $units.name is not null 
#took out and $responses._usr is not null
# took out $deliveries.recipient is not null
#and
echo "Getting hourly alerts..."

sudo -u extension psql -c "\copy (
select extract(hour from $alerts.created_at) as hour,base_datasets.name, count(distinct $alerts.id) as Alerts from $alerts
left join $deliveries on $deliveries._alert=$alerts.id
left join $beds on $alerts._bed=$beds.id 
left join $responses on $responses._alert=$alerts.id
left join $rooms on $beds._room=$rooms.id
left join $units on $rooms._unit=$units.id
left join base_datasets on base_datasets.id=$alerts.concrete_id
where $alerts.created_at > (now() - interval '14 days') 
group by hour,base_datasets.name
order by hour,base_datasets.name
)
to '$filedir/alerts_hourly_all.csv' CSV header delimiter ','" extension_prod

#this will get alerts tied with a delivery
sudo -u extension psql -c "\copy (
select extract(hour from $alerts.created_at) as hour,base_datasets.name,count(distinct $alerts.id) as Alerts from $alerts
left join $deliveries on $deliveries._alert=$alerts.id
left join $beds on $alerts._bed=$beds.id 
left join $responses on $responses._alert=$alerts.id
left join $rooms on $beds._room=$rooms.id
left join $units on $rooms._unit=$units.id
left join base_datasets on base_datasets.id=$alerts.concrete_id
where  $deliveries.status is not null
and $deliveries.status != 'Error'
and $alerts.created_at > (now() - interval '14 days') 
group by hour,base_datasets.name
order by hour,base_datasets.name
)
to '$filedir/alerts_hourly_with_deliveries.csv' CSV header delimiter ','" extension_prod


#Deliveries Totals By hour
#took out
#group by extract(hour from $alerts.created_at)
#and $responses._usr is not null
#and $units.name is not null  
#$deliveries.recipient is not null
#and 
echo "Getting hourly deliveries..."



sudo -u extension psql -c "\copy (

select extract(hour from $alerts.created_at) as hour,$deliveries.interface_name,count(distinct $deliveries.id) as Deliveries
from $alerts
left join $deliveries on $deliveries._alert=$alerts.id
left join $beds on $alerts._bed=$beds.id
left join $responses on $responses._alert=$alerts.id
left join $rooms on $beds._room=$rooms.id
left join $units on $rooms._unit=$units.id
where $deliveries.status is not null
and $deliveries.status != 'Error'
and $alerts.created_at > (now() - interval '14 days') 
group by hour,$deliveries.interface_name


)
to '$filedir/deliveries_hourly.csv' CSV header delimiter ','" extension_prod

#Responses Totals By hour
#took out
#$deliveries.recipient is not null
#and
#and $responses._usr is not null
#and $units.name is not null 

echo "Getting hourly responses..."


sudo -u extension psql -c "\copy (

select extract(hour from $alerts.created_at) as hour, count(distinct $responses.id) as Responses
from $alerts
left join $deliveries on $deliveries._alert=$alerts.id
left join $beds on $alerts._bed=$beds.id
left join $responses on $responses._alert=$alerts.id
left join $rooms on $beds._room=$rooms.id
left join $units on $rooms._unit=$units.id
where  $deliveries.status is not null
and $deliveries.status != 'Error'
and $responses.action is not null
and $alerts.created_at > (now() - interval '14 days') 
group by hour
)
to '$filedir/responses_hourly.csv' CSV header delimiter ','" extension_prod

#Alerts and Deliveries and Responses side by side
#$deliveries.recipient is not null
#and
#and $responses._usr is not null
#and $units.name is not null 
#and $responses.action is not null 

echo "Getting hourly alerts,deliveries, and responses side by side..."

sudo -u extension psql -c "\copy (

select  extract(hour from $alerts.created_at) as hour,count(distinct $alerts.id) as Alerts,count(distinct $deliveries.id) as Deliveries,count(distinct $responses.id) as Responses
from $alerts
left join $deliveries on $deliveries._alert=$alerts.id
left join $beds on $alerts._bed=$beds.id
left join $responses on $responses._alert=$alerts.id
left join $rooms on $beds._room=$rooms.id
left join $units on $rooms._unit=$units.id
where  $deliveries.status is not null
and $deliveries.status != 'Error'
and $alerts.created_at > (now() - interval '14 days') 
group by hour

)
to '$filedir/deliveries_responses_and_alerts.csv' CSV header delimiter ','" extension_prod

#alerts and alert type totals by unit
#removed and $responses.action is not null
echo "Getting alert types by unit..."


sudo -u extension psql -c "\copy (

select $units.name,$alerts.alert_type,count(distinct $alerts.id) as Total from $alerts
left join $deliveries on $deliveries._alert=$alerts.id
left join $beds on $alerts._bed=$beds.id left join $responses on $responses._alert=$alerts.id
left join $rooms on $beds._room=$rooms.id
left join $units on $rooms._unit=$units.id
where $deliveries.recipient is not null
and $deliveries.status is not null
and $deliveries.status != 'Error'
and $units.name is not null 
and $alerts.created_at > (now() - interval '14 days') 
group by $units.name,$alerts.alert_type
order by $units.name, Total desc, $alerts.alert_type

)
to '$filedir/alert_type_by_unit.csv' CSV header delimiter ','" extension_prod


#alerts by user top 10
#removed units.name 
echo "Getting Top 10 Users..."


sudo -u extension psql -c "\copy (

select $deliveries.recipient,count(distinct $alerts.id) from $alerts
left join $deliveries on $deliveries._alert=$alerts.id
left join $beds on $alerts._bed=$beds.id left join $responses on $responses._alert=$alerts.id
left join $rooms on $beds._room=$rooms.id
left join $units on $rooms._unit=$units.id
where $deliveries.recipient is not null
and $deliveries.status is not null
and $deliveries.status != 'Error'
and $responses.action is not null
and $responses._usr is not null
and $deliveries.status_text is null
and $alerts.created_at > (now() - interval '14 days') 
group by $deliveries.recipient
order by count desc 
limit 10

)
to '$filedir/users_top_ten.csv' CSV header delimiter ','" extension_prod

#delivery errors by unit
#and $units.name is not null

echo "Getting delivery errors by unit..."


sudo -u extension psql -c "\copy (

select $units.name,$deliveries.status_text,count(distinct $alerts.id) as Total from $alerts
left join $deliveries on $deliveries._alert=$alerts.id
left join $beds on $alerts._bed=$beds.id
left join $responses on $responses._alert=$alerts.id
left join $rooms on $beds._room=$rooms.id
left join $units on $rooms._unit=$units.id
where $deliveries.status_text not like 'Escalated Delivery' 
and $deliveries.status_text is not null
and $alerts.created_at > (now() - interval '14 days') 
group by $units.name,$deliveries.status_text

)
to '$filedir/delivery_errors_by_unit.csv' CSV header delimiter ','" extension_prod


#Gather cumulative data per day so we can average them out

echo "Getting data for averages..."

sudo -u extension psql -c "\copy (

select date_trunc('day', $alerts.created_at) as day,count(distinct $alerts.id) as Alerts,count(distinct $deliveries.id) as deliveries
from $alerts
left join $deliveries on $deliveries._alert=$alerts.id
left join $beds on $alerts._bed=$beds.id 
left join $rooms on $beds._room=$rooms.id
left join $units on $rooms._unit=$units.id
where $deliveries.recipient is not null
and $deliveries.status is not null
and $deliveries.status != 'Error'
and $alerts.created_at > (now() - interval '14 days')
group by day 

)
to '$filedir/alertsanddeliveriesdaily.csv' CSV header delimiter ','" extension_prod



echo "Done"

#gather delivery health data
sudo -u extension psql -c "\copy (

select $units.name,$deliveries.status,count(distinct $deliveries.id) as Total from $deliveries
left join $alerts on $deliveries._alert=$alerts.id
left join $beds on $alerts._bed=$beds.id
left join $rooms on $beds._room=$rooms.id
left join $units on $beds._unit=$units.id
where $deliveries.status is not null
and $deliveries.status != 'Processing'
and $deliveries.recipient is not null
and $alerts.created_at > (now() - interval '14 days')
group by $units.name,$deliveries.status

)
to '$filedir/deliveryhealth.csv' CSV header delimiter ','" extension_prod


##Server health


#Verify Database optimization is configured
#We could add logic here to just see if there is anything in the file.
	
	echo "Verifying database optimization is configured..."
	#this variable will be used for the failed deliveries check, as well as vacuum analyze
	failed_delivery_date=$(date +%Y-%m-%d)
	#finds the last 5 times that vacuum analyze has been done
	sudo -u extension psql -c "\copy (select relname, last_vacuum, last_analyze from pg_stat_all_tables where schemaname = 'public' limit 5) to '$filedir/database_optimization.txt'" extension_prod
	
	#If the document is empty for database optimization, then it is not running.
	#Run a check inside, so make sure it ran the day of.
	if [ -s $filedir/database_optimization.txt ] ;
		
			then {
				printf "Database optimization is currently running.\n" >> $worddata 
				
				
				#Check to see if optimization occured today.
				if grep -q $failed_delivery_date $filedir/database_optimization.txt ;
					then 
						printf "$green" "Database optimization ran today.\n" >> $worddata
						
					else 
						printf "$red" "Database optimization did not run today." >> $worddata
						
				fi
					
				
				}
		
			else {
			
				printf "$red" "Did not find any database optimization records, please investigate." >> $worddata
			
				}
	fi
	echo "Done"
	
	linebreak 

##Gather average cpu usage, and memory usage from SAR

#get yestderdays date from the time the script was run.
sardate=`date --date="yesterday" +"%m/%d/%Y"`

#create document
printf "Sar Averages" > $filedir/saraverages.txt
sardoc=$filedir/saraverages.txt
printf "\n\n" >> $sardoc

for file in $(ls -la /var/log/sa/* | grep sa[0-9] | awk '{print $9}')
do
        sar -f $file | head -n 1 >> $sardoc
        printf "\n" >> $sardoc
 
        # Get CPU idle average, it's pretty straight forward.
 
        printf "CPU average: " >> $sardoc
        sar -u -f $file | grep Average: | awk -F " " '{sum = (100 - $8) } END { print sum "%" }' >> $sardoc
 
        # Get Average Memory utilization
 
        printf "Memory Average: " >> $sardoc
        sar -r -f $file | grep Average | awk -F " " '{ sum = ($3-$5-$6)/($2+$3) * 100   } END { print sum "%" }' >> $sardoc
 
        printf "\n" >> $sardoc
done

#look for yesterdays date

sudo cat $sardoc | grep -A3 "$sardate" >> $worddata

#cleanup
sudo rm $sardoc


