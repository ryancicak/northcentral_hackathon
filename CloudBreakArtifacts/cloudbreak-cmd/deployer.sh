#!/bin/bash
set -e
#Get properties 

if [ -f ./.deploy.config ]; then
  source ./.deploy.config 
else
  read -p "Version to Deploy: " Version
  read -p "Cloudbreak Server: " CloudBreakServer
  read -p "Cloudbreak Identity Server: " CloudBreakIdentityServer
  read -p "Cloudbreak User: " CloudBreakUser
  read -p "Cloudbreak Password: " CloudBreakPassword
  read -p "Cloudbreak Credentials: " CloudBreakCredentials
  read -p "Cloudbreak Cluster Name: " CloudBreakClusterName
  read -p "Cloudbreak Template: " CloudBreakTemplate
  read -p "Cloudbreak Openstak Region: " CloudBreakRegion
  read -p "Cloudbreak Security Group: " CloudBreakSecurityGroup
  read -p "Cloudbreak Network: " CloudBreakNetwork  
  read -p "Cloudbreak Availability Zone: " CloudBreakAvailabilityZone
fi

#Clone Repo and get version
git clone https://github.com/ryancicak/northcentral_hackathon.git
cd northcentral_hackathon
git checkout tags/$Version

cloudbreak="java -jar CloudBreakArtifacts/cloudbreak-cmd/cloudbreak-shell.jar --cert.validation=false --cloudbreak.address=$CloudBreakServer --identity.address=$CloudBreakIdentityServer --sequenceiq.user=$CloudBreakUser --sequenceiq.password=$CloudBreakPassword"


#Check if Cluster exists
echo stack list > file 
$cloudbreak --cmdfile=file | grep $CloudBreakClusterName || { echo "Cluster Already Exists"; exit 1; }
#Check if Credentials exists
echo credential list > file
$cloudbreak --cmdfile=file | grep $CloudBreakCredentials || { echo "Credential does not exist"; exit 1; }
echo credential select $CloudBreakCredentials > deploy
#Check if Template is avaliable
echo template list > file
$cloudbreak --cmdfile=file | grep $CloudBreakTemplate || { echo "Template does not exist"; exit 1; }

#Check if Security Group exists
echo securitygroup list > file 
$cloudbreak --cmdfile=file | grep $CloudBreakSecurityGroup || { echo "SecurityGroup does not exist"; exit 1; }

#Check if network Exists:
echo network list > file
$cloudbreak --cmdfile=file | grep $CloudBreakNetwork || { echo "Network does not exist"; exit 1; }
echo network select $CloudBreakNetwork >> deploy


#Check if blueprint exists
echo blueprint list > file
if $cloudbreak --cmdfile=file | grep -q alarmfatigue-$Version; then 
    echo "Blueprint Version is already deployed. Going to use it"
    echo blueprint select --name alarmfatigue-$Version >> deploy
else
    echo "Deploying Blueprint"
    echo blueprint create --name alarmfatigue-$Version --description "alarmfatigue-$Version" --file CloudBreakArtifacts/blueprints/alarmfatigue.json > file
    $cloudbreak --cmdfile=file 
    echo blueprint select --name alarmfatigue-$Version >> deploy
fi 

#Check if Recipes are there
echo recipe list > file
if $cloudbreak --cmdfile=file | grep -q alaramfatigue-post-$Version; then
    echo "Post Install Recipe is Loaded. Going to add it"
else
    echo "Deploying Post Install Recipe"
    echo recipe create --name alaramfatigue-post-$Version --type POST --scriptFile CloudBreakArtifacts/recipes/alarmfatigue-demo-post-install.sh > file
    $cloudbreak --cmdfile=file
fi

if $cloudbreak --cmdfile=file | grep -q alaramfatigue-sam-$Version; then
    echo "SAM Install Recipe is Loaded. Going to add it"
else
    echo "Deploying SAM Install Recipe"
    echo recipe create --name alaramfatigue-sam-$Version --type POST --scriptFile CloudBreakArtifacts/recipes/alarmfatigue-demo-sam-install.sh > file
    $cloudbreak --cmdfile=file
fi


#Setup instance groups and cluster commands

echo instancegroup configure --OPENSTACK --instanceGroup host_group_1  --nodecount 1 --ambariServer true --templateName  $CloudBreakTemplate --securityGroupName $CloudBreakSecurityGroup >> deploy
echo instancegroup configure --OPENSTACK --instanceGroup host_group_2  --nodecount 1 --ambariServer false --templateName  $CloudBreakTemplate --securityGroupName $CloudBreakSecurityGroup >> deploy
echo instancegroup configure --OPENSTACK --instanceGroup host_group_3  --nodecount 1 --ambariServer false --templateName  $CloudBreakTemplate --securityGroupName $CloudBreakSecurityGroup >> deploy
echo hostgroup configure --hostgroup host_group_1 --recipeNames alaramfatigue-post-$Version,alaramfatigue-sam-$Version >> deploy
echo stack create --OPENSTACK --name $CloudBreakClusterName --region $CloudBreakRegion --availabilityZone $CloudBreakAvailabilityZone >> deploy
echo cluster create --description "Alarm Fatigue $Version" >> deploy 


# Create cluster

$cloudbreak --cmdfile=deploy


