public inherited sharing class TaskRepository {
    public Task[] create(Task[] tasks) {
        insert tasks;
        return tasks;
    }

    public Map<Id, Task[]> getTasksByWhoId(Set<Id> contactIds, String subject) {
        Task[] tasks = [SELECT Id, 
                               CreatedDate, 
                               OwnerId, 
                               Status, 
                               Subject, 
                               WhoId
                        FROM Task
                        WHERE WhoId IN :contactIds AND Status <> 'Completed' AND Subject LIKE :subject];
        Map<Id, Task[]> contactTaskMap = new Map<Id, Task[]>();

        for (Task task : tasks) {
            if (contactTaskMap.containsKey(task.WhoId)) {
                Task[] ltasks = contactTaskMap.get(task.WhoId);
                ltasks.add(task);
            } else {
                contactTaskMap.put(task.WhoId, new Task[]{ task });
            }
        }
        return contactTaskMap;
    }

    // Find the user to assign background check tasks to
    public User getBackgroundCheckUser() {
        // Get the users to assign the task to
        TaskUser__mdt[] taskUsers = [SELECT User__c
                                     FROM TaskUser__mdt
                                     WHERE Task__c = 'Background check'];
        if (taskUsers.size() == 0) {
            System.debug('No Background check users defined in TaskUser__mdt');
            return null;
        }

        User[] users = [SELECT Id
                        FROM User
                        WHERE Username = :taskUsers[0].User__c AND IsActive = true];
        if (users.size() == 0) {
            System.debug('Cannot find user defined to assign background check reminder tasks');
            return null;
        }
        return users[0];
    }

}