# atlas-tasks

This project is for an unlocked extension of the atlas-dogs package to add Apex Schedulable classes that mainly
create various reminder emails for contacts and tasks for users related to tracking Team Facilitators,
Teams, Clients, and Trainers within Atlas Assistance dogs.

## Development

To work on this project in a scratch org:

1. [Set up CumulusCI](https://cumulusci.readthedocs.io/en/latest/tutorial.html)
2. Run `cci flow run dev_org --org dev` to deploy this project.
    a. Note that there is currently a problem with the Admin profile: when this errors out,
       `cci org browser dev`, edit the System Admin profile, and add all the Account record types
    b. Then restart the flow
3. Run `cci org browser dev` to open the org in your browser.

## Create a new version

`sf package version create -x -p atlas-tasks`

Package atlas-tasks is

 Successfully created the package version [08cRg0000000oZVIAY]. Subscriber Package Version Id: 04tRg000000bNP3IAM
Package Installation URL: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tRg000000bNP3IAM
As an alternative, you can use the "sf package:install" command.

Name                          Value                                                                             
 ───────────────────────────── ───────────────────────────────────────────────────────────────────────────────── 
 ID                            08cRg0000000q1pIAA                                                                
 Status                        Success                                                                           
 Package Id                    0HoRg000000077xKAA                                                                
 Package Version Id            05iRg000000LDqHIAW                                                                
 Subscriber Package Version Id 04tRg000000bz7lIAA                                                                
 Tag                                                                                                             
 Branch                                                                                                          
 Created Date                  2025-07-31 21:57                                                                  
 Installation URL              https://login.salesforce.com/packaging/installPackage.apexp?p0=04tRg000000bz7lIAA 
 Created By                    0054x000003UWrpAAG                                                                
 
 ## List package versions
 `sf package version list`

 ## Promote package version

 `sf package version promote -p <value>`

 Where -p is the package version ID (starts with 04t)
