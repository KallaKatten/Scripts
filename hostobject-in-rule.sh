#!/bin/bash


# Log in to cbsvprdpan02 and run the following commands
# set cli pager off
# set cli config-output-format set
# configure
# show

# Save the output to a file and point the variable CONFFILE towards the file.
# this script will then take a hostname as input and pars the config and output will give a searchstring that can be pasted in to panorama webGUI and filter out what access is granted towards the hostname.




function sortuniq {
	tempvar=$(echo "$1"|tr " " "\n"|sort|uniq|tr "\n" " ")
}


function ipc {
				
				PossibleNetworks=""
				for ml in 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31; 
					do
						temp=""
						NetPrefix=""
						temp=`ipcalc -nps $1/$ml | awk -F "=" '{ print $2 }'`
						NetPrefix=`echo $temp | awk '{ print $2 "/" $1 }'`
						#is there a network object?
						ObjNet=`cat $CONFFILE | grep "ip-netmask $NetPrefix" | awk '{sub(/.*address /,"");sub(/ ip-netmask.*/,"");print;}'`
						#echo $ObjNet
						#echo "cat $CONFFILE | grep ip-netmask $NetPrefix"
						PossibleNetworks+="$ObjNet "
					done
        #printf "\n \n PossibleNetworks: $PossibleNetworks \n"
}


function findRuleNameforObject {
#!!!
#        printf " \n\n\n"
#        printf " ObMemberOfAll: $ObMemberOfAll \n"
#        printf "OB: $OB \n"
#        printf "MemOfStatGrp: $MemOfStatGrp \n"
#        printf "MemOfDynGrp: $MemOfDynGrp \n"
#        printf "DynGrpMemOfStatGrp $DynGrpMemOfStatGrp \n"
#        printf "PossibleNetworks: $PossibleNetworks \n"
#        printf "\n\n"
#        printf "\n\n"

	ObjectInRuleName=""
        for a in $ObMemberOfAll;
                do
#                        printf "$a "
#                        printf "\n"
                        ObjectInRuleName+=`cat $CONFFILE | grep -e set.device-group.CBSINFFW.pre-rulebase.security.rules.*.destination.*.$a | awk '{ print $7 " " }'`
                        ObjectInRuleName+=`cat $CONFFILE | grep -e set.device-group.CBSINFFW.post-rulebase.security.rules.*.destination.*.$a | awk '{ print $7 " " }'`
#                       printf "\n"
#                       printf "\n"
                        #printf "\n"
                done
}


SRCOBJ=$1

# Verify if the object excists
ObjPressent=`cat $CONFFILE | grep ip-netmask | grep "address $SRCOBJ" | awk '{sub(/.*address /,"");sub(/ ip-netmask.*/,"");print;}'`

# printf "$ObjPressent \n"

declare -i n=0

if [[ $(echo $ObjPressent | grep '[a-Z]' | grep -vc grep) < 1 ]]
 then
	printf "\n $SRCOBJ does not excist, moving on...\n"
	#exit 1
 else 
##printf "$1 does excist,  \n"
#printf " Matced: $ObjPressent "
##	sleep 1

for OB in $ObjPressent;
 do 
	n=$n+1

ObjIP=`cat $CONFFILE | grep ip-netmask | grep "address $OB" | awk '{sub(/.*ip-netmask /,"");sub(/\/.*/,"");print;}'`
ipc $ObjIP

# verify if the object has tags, if so are they uesd for dynamic group matching?

	TAGLINE=`cat $CONFFILE | grep tag | grep "address $OB"`

	if [[ $(echo $TAGLINE | grep '[a-Z]' | grep -vc grep) > 0 ]]
	 then
		# verify if there are multiple tags or not	
		if [[ $(echo $TAGLINE | grep '\[' | grep -vc grep) > 0 ]]
		 then 
##			printf "\n## $SRCOBJ is tagged with the following tages ## \n"
##			echo $TAGLINE | sed -n 's/.*\[//;s/\].*//p' | xargs -n 1
			TAGS=`echo $TAGLINE | sed -n 's/.*\[//;s/\].*//p'`
##			printf "   $TAGS\n\n"
		
			# Verify if the tags are used for match in dynamic groups
			MemOfDynGrp=""
			for a in $TAGS;
				do
##				printf "$a for this run, and the cat returns: `cat $CONFFILE | grep "address-group" | grep "dynamic filter" | grep $a | awk '{ print $4 }'` \n"
	        		#	cat $CONFFILE | grep "address-group" | grep "dynamic filter" | grep $a | awk '{ print $4 }'
				#	populate variable with the dynamic groups
					MemOfDynGrp+=`cat $CONFFILE | grep "address-group" | grep "dynamic filter" | grep $a | awk '{ print $4 }'`
					MemOfDynGrp+=" "
				#	echo $MemOfDynGrp
				done
	
	
#				printf "\n\n## $SRCOBJ is member of the following dynamic groups ##\n"
#				printf "$MemOfDynGrp"



	
		 else
##			printf "#Hence the object is not tagged with multiple tags we do not need to strip the [] away"
			#echo $TAGLINE  | awk '{ print $6 }'
       	 	        #       populate variable with the dynamic group
			OneTagOnly=`echo $TAGLINE  | awk '{ print $6 }'`
#			printf "TAGLINE $TAGLINE, OneTagOnly $OneTagOnly"
			MemOfDynGrp=`cat $CONFFILE | grep "address-group" | grep "dynamic filter" | grep "$OneTagOnly"`

#			printf "\n\n## $SRCOBJ is member of the following dynamic groups ##\n"
			##printf "$MemOfDynGrp"
		fi

#		printf "Object $OB does not have any tags.\n"

	fi



	##printf "\n\n## $SRCOBJ is member of the following static groups ## \n"
	MemOfStatGrp=""
	MemOfStatGrp=`cat $CONFFILE | grep "address-group" | grep $OB | awk '{ print $4 }'`
		

	DynGrpMemOfStatGrp=""
	DynGrpMemOfStatGrpTest=""
	for b in $MemOfDynGrp;
		do
			##printf " \n B is equal $b \n "
			DynGrpMemOfStatGrp+=`cat $CONFFILE | grep "address-group" | grep -v "dynamic filter" | grep -v \ tag\  | grep $b\\  | awk '{ print $4" " }'`
			DynGrpMemOfStatGrpTest+=`cat $CONFFILE | grep "address-group .* static .* $b" | awk '{ print $4" " }'`

			##printf "\n\n\n\nDynGrpMemOfStatGrp - $DynGrpMemOfStatGrp \n\n DynGrpMemOfStatGrpTest - $DynGrpMemOfStatGrpTest \n\n\n\n"
			
	done


	ObMemberOfAllTemp="$OB $MemOfStatGrp $MemOfDynGrp $DynGrpMemOfStatGrp $PossibleNetworks"
	ObMemberOfAll=`echo $ObMemberOfAllTemp |tr " " "\n"|sort|uniq|tr "\n" " "`

	
	findRuleNameforObject $OB
	
#	printf " OB: $OB \n"

	ObjectInRuleNameUniq=`echo $ObjectInRuleName |tr " " "\n"|sort|uniq|tr "\n" " "`
	for a in $ObjectInRuleNameUniq;
		do 	
			#printf "$a \n\n"
			cat $CONFFILE | grep -e "CBSINFFW.*-rulebase.security.rules.$a " >>./$PciReviewYearAndQ/$OB\.rules
#			cat $CONFFILE | grep -e "CBSINFFW.*-rulebase.security.rules.$a "
			#cat $CONFFILE | grep -e "CBSINFFW.*-rulebase.security.rules.$a " | grep action
			#cat $CONFFILE | grep -e "$a " 
			#printf "(name contains '$a') OR  "
		done
progressbar+=0
printf "$progressbar \n"	
#printf "\n\n\n"
done
fi
