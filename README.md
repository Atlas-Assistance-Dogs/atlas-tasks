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