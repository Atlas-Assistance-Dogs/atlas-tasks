public inherited sharing class TaskRepository {
    public Task[] create(Task[] tasks) {
        insert tasks;
        return tasks;
    }

    public Task[] getMatchingTasks(Id contactId, String subject) {
        return [SELECT Id, 
                       CreatedDate, 
                       OwnerId, 
                       Status, 
                       Subject
                FROM Task
                WHERE WhoId = :contactId AND Status <> 'Completed' AND Subject LIKE:subject];
    }

    // Find the user to assign a check tasks to
    public User getTaskUser(String task) {
        // Get the users to assign the task to
        TaskUser__mdt[] taskUsers = [SELECT User__c
                                     FROM TaskUser__mdt
                                     WHERE Task__c = :task];
        if (taskUsers.size() == 0) {
            System.debug('No ' + task + ' users defined in TaskUser__mdt');
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