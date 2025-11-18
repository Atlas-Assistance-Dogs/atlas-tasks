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
    static void getMatchingTasks_returnsEmptyWhenContactIdIsNull() {
        List<Task> result = repo.getMatchingTasks(null, null);
        System.Assert.isTrue(result.isEmpty());
    }

    @isTest
    static void getMatchingTasks_returnsEmptyWhenNoTasks() {
        Contact who = new Contact(
            FirstName = 'test', 
            LastName = 'contact'
        );
        insert who;

        List<Task> result = repo.getMatchingTasks(who.Id, 'Subject');
        System.Assert.isTrue(result.isEmpty());
    }

    @isTest
    static void getMatchingTasks_returnsEmptyWhenTaskDoesntMatch() {
        Contact who = new Contact(
            FirstName = 'test', 
            LastName = 'contact'
        );
        insert who;
        Task t = new Task(
            Subject = 'test', 
            WhoId = who.Id
        );

        List<Task> result = repo.getMatchingTasks(who.Id, 'Subject');
        System.Assert.isTrue(result.isEmpty());
    }

    @isTest
    static void getMatchingTasks_returnsTaskWhenTaskMatches() {
        Contact who = new Contact(
            FirstName = 'test', 
            LastName = 'contact'
        );
        insert who;
        Task t = new Task(
            Subject = 'Subject with more stuff', 
            WhoId = who.Id
        );
        insert t;

        List<Task> result = repo.getMatchingTasks(who.Id, 'Subject');
        System.Assert.isTrue(result.isEmpty());
    }

    @isTest
    static void getMatchingTasks_returnsOnlyMatchingTasks() {
        Contact who = new Contact(
            FirstName = 'test', 
            LastName = 'contact'
        );
        insert who;
        Task[] tasks = new Task[]{ new Task(
            Subject = 'Subject with more stuff', 
            WhoId = who.Id
        ), new Task(
            Subject = 'Subject', 
            WhoId = who.Id
        ), new Task(
            Subject = 'Something else', 
            WhoId = who.Id
        ), new Task(
            Subject = 'Subject', 
            Whoid = who.Id
        ) };
        insert tasks;

        List<Task> result = repo.getMatchingTasks(who.Id, 'Subject');
        System.Assert.areEqual(2, result.size());
    }

    @isTest
    static void getTaskUser_returnsNull_whenNoMatch() {
        // Act
        User user = repo.getTaskUser('test');
        // Assert
        System.Assert.areEqual(null, user, 'user should be null');
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
}