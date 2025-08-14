public inherited sharing class TaskRepository {
    public Task[] create(Task[] tasks) {
        insert tasks;
        return tasks;
    }

    public Map<Id, Task[]> getTasksByWhoId(Set<Id> contactIds, Set<String> subjects) {
        Task[] tasks = [SELECT Id, 
                               CreatedDate, 
                               OwnerId, 
                               Status, 
                               Subject
                        FROM Task
                        WHERE WhoId IN :contactIds AND Status <> 'Completed' AND Subject IN :subjects];
        Map<Id, Task> contactTaskMap = new Map<Id, Task>();

        for (Task task : tasks) {
            if (contactTaskMap.containsKey(task.WhoId)) {
                Task[] tasks = contactTaskMap.get(task.WhoId);
                tasks.add(task);
            } else {
                contactTaskMap.put(task.WhoId, new Task[]{ task });
            }
        }
    }

}