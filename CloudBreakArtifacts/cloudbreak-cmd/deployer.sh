#!/bin/bash
#set -e
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
echo stack show --name $CloudBreakClusterName > file 
$cloudbreak --cmdfile=file | grep -q FAILED || { echo "Cluster Already Exists"; exit 1; }
#Check if Credentials exists
echo credential show --name $CloudBreakCredentials  > file
$cloudbreak --cmdfile=file  | grep -q FAILED &&  { echo "Credential does not exist"; exit 1; }
echo credential select --name $CloudBreakCredentials > deploy
#Check if Template is avaliable
echo template show --name $CloudBreakTemplate > file
$cloudbreak --cmdfile=file | grep -q FAILED &&  { echo "Template does not exist"; exit 1; }

#Check if Security Group exists
echo securitygroup show --name $CloudBreakSecurityGroup  > file 
$cloudbreak --cmdfile=file | grep -q FAILED &&  { echo "SecurityGroup does not exist"; exit 1; }

#Check if network Exists:
echo network show --name $CloudBreakNetwork > file
$cloudbreak --cmdfile=file | grep -q FAILED &&  { echo "Network does not exist"; exit 1; }
echo network select --name  $CloudBreakNetwork >> deploy


#Check if blueprint exists
echo blueprint show --name alarmfatigue-$Version > file
if $cloudbreak --cmdfile=file | grep -q SUCCESS; then 
    echo "Blueprint Version is already deployed. Going to use it"
    echo blueprint select --name alarmfatigue-$Version >> deploy
else
    echo "Deploying Blueprint"
    echo blueprint create --name alarmfatigue-$Version --description "alarmfatigue-$Version" --file CloudBreakArtifacts/blueprints/alarmfatigue.json > file
    $cloudbreak --cmdfile=file 
    echo blueprint select --name alarmfatigue-$Version >> deploy
fi 

#Check if Recipes are there
echo recipe show --name alaramfatigue-post-$(echo $Version | sed 's/\./-/g') > file
if $cloudbreak --cmdfile=file | grep -q SUCCESS; then
    echo "Post Install Recipe is Loaded. Going to add it"
else
    echo "Deploying Post Install Recipe"
    echo recipe create --name alaramfatigue-post-$(echo $Version | sed 's/\./-/g') --type POST --scriptFile CloudBreakArtifacts/recipes/alarmfatigue-demo-post-install.sh > file
    $cloudbreak --cmdfile=file
fi

echo recipe show --name alaramfatigue-sam-$(echo $Version | sed 's/\./-/g') > file
if $cloudbreak --cmdfile=file | grep -q SUCCESS; then
    echo "SAM Install Recipe is Loaded. Going to add it"
else
    echo "Deploying SAM Install Recipe"
    echo recipe create --name alaramfatigue-sam-$(echo $Version | sed 's/\./-/g') --type POST --scriptFile CloudBreakArtifacts/recipes/alarmfatigue-demo-sam-install.sh > file
    $cloudbreak --cmdfile=file
fi


#Setup instance groups and cluster commands

echo instancegroup configure --instanceGroup host_group_1  --nodecount 1 --ambariServer true --templateName  $CloudBreakTemplate --securityGroupName $CloudBreakSecurityGroup >> deploy
echo instancegroup configure --instanceGroup host_group_2  --nodecount 1 --ambariServer false --templateName  $CloudBreakTemplate --securityGroupName $CloudBreakSecurityGroup >> deploy
echo instancegroup configure --instanceGroup host_group_3  --nodecount 1 --ambariServer false --templateName  $CloudBreakTemplate --securityGroupName $CloudBreakSecurityGroup >> deploy
echo hostgroup configure --hostgroup host_group_1 --recipeNames alaramfatigue-post-$(echo $Version | sed 's/\./-/g'),alaramfatigue-sam-$(echo $Version | sed 's/\./-/g') >> deploy
echo stack create --OPENSTACK --name $CloudBreakClusterName --region $CloudBreakRegion --availabilityZone $CloudBreakAvailabilityZone >> deploy


# Create cluster

$cloudbreak --cmdfile=deploy


