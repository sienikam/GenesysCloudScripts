# Genesys Cloud Scripts

This repository contains Bash-based automation for bulk administration of Genesys Cloud using the `gc` CLI (Genesys Cloud CLI).

It is intended for operational tasks such as creating, updating, assigning, listing, or deleting Genesys Cloud objects in bulk based on CSV input files. Typical use cases include managing queues, groups, skills, wrap-up codes, phone assignments, and user-related configuration.

Most operations follow a simple pattern:

1. Prepare a semicolon-delimited CSV file for the selected task
2. Run the matching Bash script locally or through CI/CD
3. The script resolves object IDs through the Genesys Cloud API and performs the requested create, update, delete, or reporting action

This repository currently supports both GitLab CI/CD and GitHub Actions for running the Genesys Cloud automation scripts.

## GitLab CI/CD

GitLab pipeline is available in `.gitlab-ci.yml`.

Pipeline behavior:

1. Validate the selected CSV with `csvlint`
2. Optionally run `Backup.sh`
3. Run the selected Genesys Cloud script

GitLab pipeline inputs:

- `script`
- `oauthclient_id`
- `oauthclient_secret`
- `environment`
- `backup`

The GitLab pipeline is triggered manually via the GitLab web UI.

## GitHub Actions

This repository includes a manual GitHub Actions workflow at `.github/workflows/genesys-cloud.yml` that mirrors the GitLab flow:

1. Validate the CSV for the selected script with `csvlint`
2. Optionally run `Backup.sh`
3. Run the selected Genesys Cloud script
4. Upload generated backup and report artifacts

### GitHub Environment setup

Create one GitHub Environment per Genesys Cloud org you want to target. The workflow input `target_org` selects that environment for the `backup` and `deploy` jobs.

For each GitHub Environment currently used by the workflow, configure:

- Secret `OAUTHCLIENT_ID`
- Secret `OAUTHCLIENT_SECRET`
- Variable `GENESYS_CLOUD_ENVIRONMENT` with the Genesys Cloud domain, for example `mypurecloud.de`

This lets you keep a different OAuth client ID and secret for each Genesys Cloud org.

From the GitHub Actions UI:

1. Open the `Genesys Cloud Scripts` workflow
2. Click `Run workflow`
3. Select the target GitHub Environment in `target_org`
4. Choose the script from the `script` dropdown
5. Set `backup` to `true` only when you want `Backup.sh` to run before deployment

Notes:

- The workflow uses environment-scoped GitHub secrets.
- The `validate` job only checks the CSV file and does not require the selected GitHub Environment
- The `backup` and `deploy` jobs both use the selected GitHub Environment
- Backup artifacts are uploaded as `*.txt` files when `backup=true`
- Report artifacts are uploaded for generated files such as `UsersPerDivision.csv`, `UsersPerGroup.csv`, and `UsersPerQueue.csv`

---

## Available Scripts

The table below lists the currently available scripts in this repository together with a short description and the related Genesys Cloud API area.

| Script | Description | API
| ------ | ------ | ------ 
| ArchitectCallFlowAssignDID.sh | assign DID Number with Call Flow (~50 DID Numbers limit per each request, adjust sleep) | https://developer.genesys.cloud/api/rest/v2/architect/#put-api-v2-architect-ivrs--ivrId- |
| ACDAutoAnswer | assign 'ACDAutoAnswer' option for users | https://developer.genesys.cloud/api/rest/v2/users/#patch-api-v2-users--userId- |
| AssignUserPhoneNumbers | Assign phone numbers to users from the csv list. The numbers will be seen under Contact Information section. This pipeline can be used for example in case we want to assign new set of contact numbers for users from the csv list or reassign them after DID range changes. | https://developer.genesys.cloud/devapps/api-explorer#patch-api-v2-users--userId- |
| AssignUserPhoneNumbers_withDirectRouting | Assign phone numbers to users from the csv list. The numbers will be seen under Contact Information section. This pipeline can be used for example in case we want to assign new set of contact numbers for users from the csv list or reassign them after DID range changes. The additional DirectRouting Integration parameter will be set aditionally accordingly using the number provided in the CSV| https://developer.genesys.cloud/devapps/api-explorer#patch-api-v2-users--userId- |
| AssignUsersGroups | assign users into groups | https://developer.genesys.cloud/api/rest/v2/groups/#post-api-v2-groups--groupId--members |
| RemoveUsersGroups | remove users from groups | https://developer.genesys.cloud/api/rest/v2/groups/#delete-api-v2-groups--groupId--members |
| AssignUsersQueues | assign users into queues | https://developer.genesys.cloud/api/rest/v2/routing/#post-api-v2-routing-queues--queueId--members |
| RemoveUsersQueues | remove users from queues | https://developer.genesys.cloud/api/rest/v2/routing/#delete-api-v2-routing-queues--queueId--members--memberId- |
| GDPR_DeleteUser | permanently remove users from org via GDPR request | https://developer.genesys.cloud/api/rest/v2/generaldataprotectionregulation/#post-api-v2-gdpr-requests |
| AssignUsersStations | assign default phone to user | https://developer.genesys.cloud/api/rest/v2/users/#put-api-v2-users--userId--station-defaultstation--stationId- |
| CreateDivisions | Create Divisions with Description as per csv | https://developer.genesys.cloud/devapps/api-explorer#post-api-v2-authorization-divisions |
| CreateGroups | create groups | https://developer.genesys.cloud/api/rest/v2/groups/#post-api-v2-groups |
| CreateQueues | create queues | https://developer.genesys.cloud/routing/routing/#post-api-v2-routing-queues |
| CreateSingleDIDRangesForPersonalHotlines | Create a DID range that conists of a single number according to the csv list. The purpose is to have a separate DID range for each number that will be leveraged for personal hotline - direct Agent contact | https://developer.genesys.cloud/devapps/api-explorer#post-api-v2-telephony-providers-edges-didpools
| UpdateQueues | update queues (CreateQueues.csv) | https://developer.genesys.cloud/api/rest/v2/routing/#put-api-v2-routing-queues--queueId- |
| DeleteQueues | delete queues | https://developer.genesys.cloud/api/rest/v2/routing/#delete-api-v2-routing-queues--queueId- |
| DeleteUserPhoneNumbers | Remove all phone numbers from Contact Information assigned to users from csv file. This can be useful in case of DID numbers change or reassignment | https://developer.genesys.cloud/devapps/api-explorer#patch-api-v2-users--userId- |
| DeleteRecordings | Mark recordings using the Delete Date flag according to the time interval specified in the csv file. Script will force the deletion immediately regardless of the action date. Action date parameter is mandatory however, but it doesn't work well - this strongly depends on how the timezone is set and so on. For this reason if we start the pipeline, it will put the recording job into the PROCESSING state forcefully, so that we are independent of the timezone. Keep in mind that recordings will not vanish from UI immediately. The job will only set a flag that these recordings are to be deleted, so be patient and check them in UI in a couple of days again.| https://developer.genesys.cloud/analyticsdatamanagement/recording/#post-api-v2-recording-jobs- |
| CreateSkills | create skills | https://developer.genesys.cloud/api/rest/v2/routing/#post-api-v2-routing-skills |
| DeleteAllExternalContacts | Delete all external contacts from Directory --> External Contacts section | https://developer.genesys.cloud/devapps/api-explorer#delete-api-v2-externalcontacts-contacts |
| DeleteSkills | delete skills | https://developer.genesys.cloud/api/rest/v2/routing/#delete-api-v2-routing-skills--skillId- |
| AssignUsersSkills | add skills to users | https://developer.genesys.cloud/api/rest/v2/users/#post-api-v2-users--userId--routingskills |
| RemoveUserSkills | remove skills from users | https://developer.genesys.cloud/api/rest/v2/users/#delete-api-v2-users--userId--routingskills--skillId- |
| CreateWrapUpCodes | create wrap-up codes | https://developer.genesys.cloud/api/rest/v2/routing/#post-api-v2-routing-wrapupcodes |
| AssignWrapUpCodes | assign wrap-up codes into queues | https://developer.genesys.cloud/api/rest/v2/routing/#post-api-v2-routing-queues--queueId--wrapupcodes |
| AssignRolesGroups | assign roles into groups | https://developer.genesys.cloud/api/rest/v2/authorization/#post-api-v2-authorization-roles--roleId- |
| IntegrationAssignGroup | configure groups for "Client Application" integration | https://developer.genesys.cloud/api/rest/v2/integrations/#put-api-v2-integrations--integrationId--config-current |
| ActivateUsersQueues | Join a set of users for a queue | https://developer.genesys.cloud/api/rest/v2/routing/#post-api-v2-routing-queues--queueId--members |
| DeactivateUsersQueues | Unjoin a set of users for a queue | https://developer.genesys.cloud/api/rest/v2/routing/#patch-api-v2-routing-queues--queueId--members |
| ListUsersPerDivision | List users per Division and save output to csv | https://developer.genesys.cloud/api/rest/v2/users/#post-api-v2-users-search |
| ListUsersPerGroup | List users per Group and save output to csv | https://developer.genesys.cloud/api/rest/v2/users/#post-api-v2-users-search |
| ListUsersPerQueue | List users per Queue and save output to csv | https://developer.genesys.cloud/api/rest/v2/users/#post-api-v2-users-search |
| ChangeWebRTCNames | Alter the name of the WebRTC Phones according to the CSV. The pipeline will only update the names of the WebRTC Phone and keep the remaining phone settings as is. | https://developer.genesys.cloud/devapps/api-explorer#put-api-v2-telephony-providers-edges-phones--phoneId-
| CreateDictionaryFeedback | Create new terms in Dictionary Management | https://developer.genesys.cloud/devapps/api-explorer#post-api-v2-speechandtextanalytics-dictionaryfeedback
| ChangePhoneSite | Update Phone Site Assignment | https://developer.genesys.cloud/api/rest/v2/telephonyprovidersedge/#put-api-v2-telephony-providers-edges-phones--phoneId-
| ExportUsers | Export all active users to `UsersExport.csv` with profile details, manager email, work location, division, skills, hire date, assigned queues, and roles (with division scopes) | https://developer.genesys.cloud/api/rest/v2/users/#get-api-v2-users
