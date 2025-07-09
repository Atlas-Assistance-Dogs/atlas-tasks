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

}