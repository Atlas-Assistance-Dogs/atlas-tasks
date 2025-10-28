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
            Subject = 'Subject'
        ) };
        insert tasks;

        List<Task> result = repo.getMatchingTasks(who.Id, 'Subject');
        System.Assert.areEqual(2, result.size());
    }

}