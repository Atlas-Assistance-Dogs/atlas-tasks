/**
 * This class contains unit tests for validating the behavior of Apex classe TaskRepository
 */
@isTest
private class TaskRepositoryTest {
    static TaskRepository repo = new TaskRepository();
    @isTest
    static void createTasks_handlesEmptyList() {
        repo.create(new List<Task>());
        System.Assert.isTrue(true, 'we reached this line without an exception being thrown');
    }

    @isTest
    static void createTask_insertsNew() {
        Task t = new Task(
            Subject = 'test'
        );
        repo.create(new List<Task>{ t });

        System.Assert.isTrue(t.Id != null);
        Task actual = [Select Id, 
                              Subject
                       FROM Task
                       WHERE Subject = 'test'];
        System.Assert.isTrue(actual != null);
    }

    @isTest
    static void getTasksByWhoId_returnsEmptyList_whenBadId() {
        Map<Id, Task[]> resp = repo.getTasksByWhoId(new Set<Id>{MockProvider.createId(atlas1__Dog__c.class)}, 'string');

        System.Assert.isTrue(resp.isEmpty());
    }

    @isTest
    static void getTasksByWhoId_returnsEmptyList_whenNoTasks() {
        Map<Id, Task[]> resp = repo.getTasksByWhoId(new Set<Id>{MockProvider.createId(Contact.class)}, 'string');

        System.Assert.isTrue(resp.isEmpty());
    }
    @isTest
    static void getTasksByWhoId_returnsEmptyList_whenNoMatchingTasks() {
        Contact c = new Contact(
            LastName = 'test'
        );
        insert c;
        Task t = new Task(
            Subject = 'test',
            WhoId = c.Id
        );
        insert t;
        Map<Id, Task[]> resp = repo.getTasksByWhoId(new Set<Id>{c.Id}, 'string');

        System.Assert.isTrue(resp.isEmpty());
    }
    @isTest
    static void getTasksByWhoId_returnsTaskList_whenMatchingTask() {
        Contact c = new Contact(
            LastName = 'Fresh'
        );
        insert c;
        Task t = new Task(
            Subject = 'Order background and credit check',
            WhoId = c.Id
        );
        insert t;
        Map<Id, Task[]> resp = repo.getTasksByWhoId(new Set<Id>{c.Id}, 'order % check');

        Task[] tasks = resp.get(c.Id);

        System.Assert.areEqual(1, tasks.size(), 'should have one element');
        System.Assert.areEqual(t.Subject, tasks[0].Subject, 'should have the right subject');
    }
    @IsTest
    static void getTasksByWhoId_groupsTasksByWhoId() {
        Contact c1 = new Contact(LastName = 'Smith');
        Contact c2 = new Contact(LastName = 'Baker');
        Contact c3 = new Contact(LastName = 'Jones');
        insert new Contact[]{c1, c2, c3};
        Task t1 = new Task(Subject = 'Order credit check', WhoId = c1.Id);
        Task t2 = new Task(Subject = 'Order background check', WhoId = c2.Id);
        Task t3 = new Task(Subject = 'Order background and credit check', WhoId = c3.Id);
        Task t4 = new Task(Subject = 'Order stuff', WhoId = c3.Id);
        insert new Task[]{t1, t2, t3, t4};
        Map<Id, Task[]> resp = repo.getTasksByWhoId(new Set<Id>{c1.Id, c2.Id, c3.Id}, 'order % check');
        
        System.Assert.areEqual(3, resp.size(), 'should have 3 elements');
        System.Assert.areEqual(1, resp.get(c1.Id).size(), 'should have 1 element');
        System.Assert.areEqual(1, resp.get(c2.Id).size(), 'should have 1 element');
        System.Assert.areEqual(1, resp.get(c3.Id).size(), 'should have 1 element');
    }

    @isTest
    static void getBackgroundcheckUser_returnsNull_whenNoUser() {
        User u = repo.getBackgroundcheckUser();
        System.Assert.isNull(u, 'user should be null');
    }
    @IsTest
    static void getBackgroundCheckUser_returnsUser_whenUserIsFound() {
        User u = [SELECT Id, Name, Profile.Name, UserRole.Name FROM User WHERE UserRole.Name = 'Backgroundcheck'];
        insert new User[]{u};
        User u2 = repo.getBackgroundCheckUser();
    }
}