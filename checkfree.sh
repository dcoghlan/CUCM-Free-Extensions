#!/bin/bash
clear

vStartDN=
vEndDN=
vRangeFile=DNRange.txt
vXMLTemplateFile=xml_template.xml
vXMLInputFile=xmlinput.xml
vXMLResponseFile=xmlresponse.xml

#
# Delete range file it already exists
#

if [ -f "$vRangeFile" ]; then
        rm $vRangeFile
fi

#
# Prompt for inputs
#

read -p "Please enter the Starting DN: " vStartDN
read -p "Please enter the End DN: " vEndDN
read -p "Please enter the UCM Partition name (case sensitive): " vPartition

#
# Create range file to compare against.
#

for (( c=$vStartDN; c<=$vEndDN; c++ ))
do
   echo $c >> $vRangeFile
done

#
# Replace variables in the XML Template File and save to XML Input file to be used in CURL command
#

cat $vXMLTemplateFile | sed 's/vpartition/'$vPartition'/;s/xxxxx/'$vStartDN'/;s/yyyyy/'$vEndDN'/' > $vXMLInputFile

#
# Run CURL to connect to CUCM and execute XML input file
#

#curl -k -u admin:IptF#1z -H "Content-type: text/xml;" -H "SOAPAction: CUCM:DB ver=8.5" -d @xmlinput.xml https://10.10.100.230:8443/axl/ > $vXMLResponseFile
curl -k -u administrator:9Cq3Qb28 -H "Content-type: text/xml;" -H "SOAPAction: CUCM:DB ver=8.5" -d @xmlinput.xml https://10.1.40.11:8443/axl/ > $vXMLResponseFile

#
# puts new results on each line
#

cat $vXMLResponseFile | sed 's/\<\/dnorpattern\>\<\/row\>//g;s/\<row\>\<dnorpattern\>/\
/g;s/\<\/return\>/\
/g' > cucm-results1.txt

#
# deletes the first and last rows of XML/SOAP crap
#

cat cucm-results1.txt | sed '/\<\/axl/d;/\<\?xml/d;/executeSQLQueryResponse/d' > cucm-results2.txt

echo 
echo List of numbers NOT used on the system in the $vPartition partition
echo  

#
# Displays only extension numbers which do not exist in both lists
#
comm -13 <(sort cucm-results2.txt) <(sort $vRangeFile)

#
# Displays a count of all free extensions in the range
#
vFREECount=$(comm -13 <(sort cucm-results2.txt) <(sort $vRangeFile) | cat -n | wc -l)

echo
echo Total Count: $vFREECount
echo
echo

#
# Cleans up files used for calculations and data manipulations
#

if [ -f "$vRangeFile" ]; then
        rm $vRangeFile
fi

if [ -f "cucm-results1.txt" ]; then
        rm cucm-results1.txt
fi

if [ -f "cucm-results2.txt" ]; then
        rm cucm-results2.txt
fi

