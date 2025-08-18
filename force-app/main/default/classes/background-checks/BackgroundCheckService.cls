public with sharing class BackgroundCheckService {
    private BackgroundCheckRepository repo;
    private ContactRepository contactRepo;
    private TaskRepository taskRepo;

    public BackgroundCheckService() {
        this.repo = new BackgroundCheckRepository();
        this.contactRepo = new ContactRepository();
        this.taskRepo = new TaskRepository();
    }

    @TestVisible
    private BackgroundCheckService(BackgroundCheckRepository bgcrepo, ContactRepository contactRepo, TaskRepository taskRepo) {
        this.repo = bgcrepo;
        this.contactRepo = contactRepo;
        this.taskRepo = taskRepo;
    }

    public void createReminderTask() {
        atlas1__AtlasSettings__c settings = atlas1__AtlasSettings__c.getOrgDefaults();
        // check to see if this setting is missing
        if (settings.atlas1__BackgroundCheckRenewalYears__c == null) {
            settings.atlas1__BackgroundCheckRenewalYears__c = 1;
            upsert settings;
        }

        // find the cutoff for which background checks to remind
        Date threshold = Date.today().addYears(-1 * (Integer) settings.atlas1__BackgroundCheckRenewalYears__c).addMonths(1);

        // Get the users to assign the task to
        TaskUser__mdt taskUser = [SELECT User__c
                              FROM TaskUser__mdt
                              WHERE Task__c = 'Background check' LIMIT 1];
        User user = [SELECT Id
                        FROM User
                        WHERE Username = :taskUser.User__c AND IsActive = true Limit 1];

        // Make sure we only have one Background check per contact
        Set<Id> contactIds = new Set<Id>();
        Set<Id> creditIds = new Set<Id>();
        Set<Id> criminalIds = new Set<Id>();
        Set<Id> combinedIds = new Set<Id>();
        // Check for any contacts that need background checks
        Contact[] contacts = this.contactRepo.getContactsNeedingBackgroundChecks();

        for (Contact person : contacts) {
            contactIds.add(person.Id);
            if (person.atlas1__VolunteerAccess__c.contains('Credit Check Required') && person.atlas1__VolunteerAccess__c.contains('Background Check Required')) {
                combinedIds.add(person.Id);
                continue;
            }
            if (person.atlas1__VolunteerAccess__c.contains('Credit Check Required')) {
                creditIds.add(person.Id);
                continue;
            }
            if (person.atlas1__VolunteerAccess__c.contains('Background Check Required')) {
                criminalIds.add(person.Id);
            }
        }

        atlas1__BackgroundCheck__c[] checks = repo.getMatchingChecksForContacts(contactIds, threshold);

        // Remove the contacts with recent-enough background checks from the list
        for (atlas1__BackgroundCheck__c check : checks) {
            switch  on check.atlas1__Type__c {
                when 'Criminal&Credit' {
                    combinedIds.remove(check.atlas1__Contact__c);
                }
                when 'Criminal' {
                    criminalIds.remove(check.atlas1__Contact__c);
                }
                when 'Credit' {
                    creditIds.remove(check.atlas1__Contact__c);
                }
            }
        }

        // Find any existing tasks for these contacts
        Map<Id, Task[]> existingCreditTasks = taskRepo.getTasksByWhoId(creditIds, 'Order % check');

        // Create a list of Tasks
        Task[] tasks = new List<Task>();
        // Create tasks to order background checks
        for (Id contactId : criminalIds) {
            tasks.add(new Task(
                OwnerId = user.Id, 
                Subject = 'Order background check', 
                Status = 'Open', 
                Priority = 'Normal', 
                WhoId = contactId, 
                ActivityDate = Date.today()
            ));
        }
        // Create tasks to order credit checks
        for (Id contactId : creditIds) {
            tasks.add(new Task(
                OwnerId = user.Id, 
                Subject = 'Order credit check', 
                Status = 'Open', 
                Priority = 'Normal', 
                WhoId = contactId, 
                ActivityDate = Date.today()
            ));
        }

        taskRepo.create(tasks);
    }

}