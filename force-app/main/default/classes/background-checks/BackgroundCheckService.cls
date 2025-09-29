public with sharing class BackgroundCheckService {
    private BackgroundCheckRepository repo;
    private ContactRepository contactRepo;
    private TaskRepository taskRepo;
    final String subjectFormat = 'Order {0} check';
    final String background = 'background';
    final String credit = 'credit';
    final String combined = 'background and credit';
    public BackgroundCheckService() {
        this.repo = new BackgroundCheckRepository();
        this.contactRepo = new ContactRepository();
        this.taskRepo = new TaskRepository();
    }

    private Id userId;
    // Make sure we only have one Background check per contact
    private Set<Id> contactIds = new Set<Id>();
    private Set<Id> creditIds = new Set<Id>();
    private Set<Id> criminalIds = new Set<Id>();
    private Set<Id> combinedIds = new Set<Id>();
    @TestVisible
    private BackgroundCheckService(BackgroundCheckRepository bgcrepo, ContactRepository contactRepo, TaskRepository taskRepo) {
        this.repo = bgcrepo;
        this.contactRepo = contactRepo;
        this.taskRepo = taskRepo;
    }

    private void clearReminders() {
        contactIds.clear();
        creditIds.clear();
        criminalIds.clear();
        combinedIds.clear();
    }

    public void createReminderTask() {
        User user = taskRepo.getBackgroundCheckUser();
        if (user == null) {
            return; // no user found, TaskRepository logs error
        }
        userId = user.Id;

        if (!findContacts()) {
            return;
        }

        removeMatchingChecks();

        removeExistingTasks();

        createTasks();
    }

    // find contacts that need to have background checks ordered
    private Boolean findContacts() {
        clearReminders();
        // Check for any contacts that need background checks
        Contact[] contacts = this.contactRepo.getContactsNeedingBackgroundChecks();

        for (Contact person : contacts) {
            if (contactIds.contains(person.Id)) {
                continue;
            }
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
        return contactIds.size() > 0;
    }

    private void removeMatchingChecks() {
        atlas1__AtlasSettings__c settings = atlas1__AtlasSettings__c.getOrgDefaults();
        // check to see if this setting is missing
        if (settings.atlas1__BackgroundCheckRenewalYears__c == null) {
            settings.atlas1__BackgroundCheckRenewalYears__c = 1;
            upsert settings;
        }

        // find the cutoff for which background checks to remind
        Date threshold = Date.today().addYears(-1 * (Integer) settings.atlas1__BackgroundCheckRenewalYears__c).addMonths(1);

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
    }

    private void removeExistingTasks() {
        // Find any existing tasks for these contacts
        Map<Id, Task[]> existingTasks = taskRepo.getTasksByWhoId(contactIds, 'order % check');

        if (existingTasks != null) {
            // Remove any contacts with open tasks from the list
            for (Id contactId : existingTasks.keySet()) {
                Task[] tasks = existingTasks.get(contactId);
                for (Task t : tasks) {
                    if (t.Subject.contains(combined)) {
                        combinedIds.remove(contactId);
                    } else if (t.Subject.contains(background)) {
                        criminalIds.remove(contactId);
                    } else if (t.Subject.contains(credit)) {
                        creditIds.remove(contactId);
                    }
                }
            }
        }
    }

    // Create a list of Tasks
    private void createTasks() {
        Task[] tasks = new List<Task>();
        // Create tasks to order combined checks
        for (Id contactId : combinedIds) {
            tasks.add(new Task(
                OwnerId = userId, 
                Subject = String.format(subjectFormat, new Object[]{ combined }), 
                Status = 'Open', 
                Priority = 'Normal', 
                WhoId = contactId, 
                ActivityDate = Date.today()
            ));
        }
        // Create tasks to order background checks
        for (Id contactId : criminalIds) {
            tasks.add(new Task(
                OwnerId = userId, 
                Subject = String.format(subjectFormat, new Object[]{ background }), 
                Status = 'Open', 
                Priority = 'Normal', 
                WhoId = contactId, 
                ActivityDate = Date.today()
            ));
        }
        // Create tasks to order credit checks
        for (Id contactId : creditIds) {
            tasks.add(new Task(
                OwnerId = userId, 
                Subject = String.format(subjectFormat, new Object[]{ credit }), 
                Status = 'Open', 
                Priority = 'Normal', 
                WhoId = contactId, 
                ActivityDate = Date.today()
            ));
        }

        taskRepo.create(tasks);
    }

}