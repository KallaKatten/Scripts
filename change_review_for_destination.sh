#!/bin/bash



HostReviewList=hosts-review-2018q1.list
ConfFileOrg="cbsinffw-review-2018q1.txt"
PciReviewYearAndQ=2018q1
PciReviewYearAndQLast=2017q4




CONFFILE="configfile.tmp"



#Cleanup
rm diff/*
rm $CONFFILE
rm $PciReviewYearAndQ/* 

mkdir -p $PciReviewYearAndQ
# remove unwanted new lines and ^M and write to $CONFFILE
awk '{printf "%s%s", (NR>1 ? (/^set/?ORS:OFS) : ""), $0} END{print ""}' $ConfFileOrg  | sed 's/\r//g' > $CONFFILE

# call hostobject-in-rule.sh for each hostname in $HostReviewList Note the ". " in front this means that we run this inside this shell.
for a in `cat $HostReviewList`; do . hostobject-in-rule.sh $a; done


# Compare result for each file created in $PciReviewYearAndQ with the files located in $PciReviewYearAndQLast and write  the diff to file diff/$a.diff
for a in `ls -1 $PciReviewYearAndQ/`; do diff $PciReviewYearAndQLast/$a $PciReviewYearAndQ/$a >> diff/$a.diff; done

# Stack the diff files in diff/ together and remove some crap to make it readable

for a in `ls -1 diff/`; do printf "File $a \n"; cat diff/$a ; printf "\n\n"; done | grep  'File\|^>\|^<\|^$' >> diff.$PciReviewYearAndQ

printf "\n\n  ############################################################################################ "
printf "  \n ####                                                                                      ####"
printf "  \n ####  The file diff.$PciReviewYearAndQ should now be populated with the changed rules                 ####"
printf "  \n ####  where the host in $HostReviewList is destination or a member of a static   ####"
printf "  \n ####  or dynamic group or part of a network and thus a destination                        ####"
printf "  \n  ############################################################################################ \n\n"


