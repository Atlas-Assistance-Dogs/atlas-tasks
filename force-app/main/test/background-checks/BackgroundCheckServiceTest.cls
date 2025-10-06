@isTest
public with sharing class BackgroundCheckServiceTest {
  private static MockProvider mocks;
  private static BackgroundCheckService service;
  private static ContactRepository contactRepo;
  private static BackgroundCheckRepository bgcRepo;
  private static TaskRepository taskRepo;

  // references to mocks
  private static void makeData() {
    mocks = new MockProvider();
    contactRepo = (ContactRepository)mocks.createMock(ContactRepository.class);
    bgcRepo = (BackgroundCheckRepository)mocks.createMock(BackgroundCheckRepository.class);
    taskRepo = (TaskRepository)mocks.createMock(TaskRepository.class);
    service = new BackgroundCheckService(bgcRepo, contactRepo, taskRepo);
  }

  @isTest
  static void createReminderTask_exitsWhenNoUserSetup() {
    makeData();
    mocks.expectedCalls.add(new MockCallData(taskRepo, 'getBackgroundCheckUser', null));

    service.createReminderTask();
    System.assertEquals(1, mocks.actualCalls.size(), 'should stop when no user');
    // the first call would be to get the user to assign the tasks to
    MockCallData getUser = mocks.actualCalls[0];
    System.assertEquals('getBackgroundCheckUser', getUser.methodName);
  }

  @isTest
  static void createReminderTask_createsNoTasksWhenNoContactsWithAccess() {
    makeData();
    mocks.expectedCalls.add(new MockCallData(taskRepo, 'getBackgroundCheckUser', new User(
      Id = MockProvider.createId(User.class)
    )));
    mocks.expectedCalls.add(new MockCallData(contactRepo, 'getContactsNeedingBackgroundChecks', new List<Contact>()));
    mocks.expectedCalls.add(new MockCallData(bgcRepo, 'getMatchingChecksForContacts', new List<atlas1__BackgroundCheck__c>()));
    mocks.expectedCalls.add(new MockCallData(taskRepo, 'getTasksByWhoId', new Map<Id, List<Task>>()));
    // Act
    service.createReminderTask();

    // Assert
    System.assert(!mocks.actualCalls.isEmpty());
    // the next call would be to get contacts
    MockCallData getContacts = mocks.actualCalls[1];
    System.assertEquals('getContactsNeedingBackgroundChecks', getContacts.methodName);

    // see if there is a call to create tasks, if there is, there should be no tasks
    for (MockCallData call : mocks.actualCalls) {
      if (call.obj == taskRepo && call.methodName == 'create') {
        System.assert(((List<Task>)call.args[0]).isEmpty());
      }
    }
  }

  private static Contact[] createContactsWithAccess() {
    Contact[] contacts = new List<Contact>{ new Contact(
      Id = MockProvider.createId(Contact.class), 
      FirstName = 'Bluey', 
      LastName = 'Heeler', 
      Email = 'bluey@test.com', 
      atlas1__VolunteerAccess__c = 'Credit Check Required'
    ), new Contact(
      Id = MockProvider.createId(Contact.class), 
      FirstName = 'Bingo', 
      LastName = 'Heeler', 
      Email = 'bingo@test.com', 
      atlas1__VolunteerAccess__c = 'Background Check Required'
    ), new Contact(
      Id = MockProvider.createId(Contact.class), 
      FirstName = 'Chilli', 
      LastName = 'Heeler', 
      Email = 'chilli@test.com', 
      atlas1__VolunteerAccess__c = 'Background Check Required'
    ), new Contact(
      Id = MockProvider.createId(Contact.class), 
      FirstName = 'Bandit', 
      LastName = 'Heeler', 
      Email = 'bandit@test.com', 
      atlas1__VolunteerAccess__c = 'Background Check Required;Credit Check Required'
    ) };

    return contacts;
  }

  @isTest
  public static void createReminderTask_createsTasksWhenContactsWithAccess() {
    makeData();
    mocks.expectedCalls.add(new MockCallData(taskRepo, 'getBackgroundCheckUser', new User(
      Id = MockProvider.createId(User.class)
    )));
    mocks.expectedCalls.add(new MockCallData(contactRepo, 'getContactsNeedingBackgroundChecks', createContactsWithAccess()));
    mocks.expectedCalls.add(new MockCallData(bgcRepo, 'getMatchingChecksForContacts', new List<atlas1__BackgroundCheck__c>()));
    // Act
    service.createReminderTask();

    // see if there is a call to create tasks, if there is, there should be 4 tasks
    for (MockCallData call : mocks.actualCalls) {
      if (call.obj == taskRepo && call.methodName == 'create') {
        System.assertEquals(6, ((List<Task>)call.args[0]).size());
      }
    }
  }

  @isTest
  public static void createReminderTask_createsNoTasksWhenContactsWithAccessUpToDate() {
    makeData();
    mocks.expectedCalls.add(new MockCallData(taskRepo, 'getBackgroundCheckUser', new User(
      Id = MockProvider.createId(User.class)
    )));
    Contact[] contacts = createContactsWithAccess();
    mocks.expectedCalls.add(new MockCallData(contactRepo, 'getContactsNeedingBackgroundChecks', contacts));
    mocks.expectedCalls.add(new MockCallData(bgcRepo, 'getMatchingChecksForContacts', new List<atlas1__BackgroundCheck__c>{ new atlas1__BackgroundCheck__c(
      atlas1__Contact__c = contacts[0].id, 
      atlas1__Date__c = Date.today().addMonths(-3), 
      atlas1__Type__c = 'Credit'
    ), new atlas1__BackgroundCheck__c(
      atlas1__Contact__c = contacts[1].id, 
      atlas1__Date__c = Date.today().addMonths(-4), 
      atlas1__Type__c = 'Criminal'
    ), new atlas1__BackgroundCheck__c(
      atlas1__Contact__c = contacts[2].id, 
      atlas1__Date__c = Date.today().addMonths(-5), 
      atlas1__Type__c = 'Criminal'
    ), new atlas1__BackgroundCheck__c(
      atlas1__Contact__c = contacts[3].id, 
      atlas1__Date__c = Date.today().addMonths(-6), 
      atlas1__Type__c = 'Criminal&Credit'
    ) }));
    // Act
    service.createReminderTask();

    // see if there is a call to create tasks, if there is, there should be no tasks
    for (MockCallData call : mocks.actualCalls) {
      if (call.obj == taskRepo && call.methodName == 'create') {
        System.assert(((List<Task>)call.args[0]).isEmpty());
      }
    }
  }

  @isTest
  public static void createReminderTask_createsTaskWhenContactWithAccessNeedsNew() {
    makeData();
    // Get the group to assign the task to
    Group adminGroup = [SELECT Id
                        FROM Group
                        WHERE Name = 'Background Check Administrator' AND Type = 'Queue'];
    Contact[] contacts = createContactsWithAccess();
    Contact bandit = contacts[3];
    mocks.expectedCalls.add(new MockCallData(contactRepo, 'getContactsNeedingBackgroundChecks', contacts));
    mocks.expectedCalls.add(new MockCallData(bgcRepo, 'getMatchingChecksForContacts', new List<atlas1__BackgroundCheck__c>{ new atlas1__BackgroundCheck__c(
      atlas1__Contact__c = contacts[0].id, 
      atlas1__Date__c = Date.today().addMonths(-3), 
      atlas1__Type__c = 'Credit'
    ), new atlas1__BackgroundCheck__c(
      atlas1__Contact__c = contacts[1].id, 
      atlas1__Date__c = Date.today().addMonths(-4), 
      atlas1__Type__c = 'Criminal'
    ), new atlas1__BackgroundCheck__c(
      atlas1__Contact__c = contacts[2].id, 
      atlas1__Date__c = Date.today().addMonths(-5), 
      atlas1__Type__c = 'Criminal'
    ), new atlas1__BackgroundCheck__c(
      atlas1__Contact__c = contacts[3].id, 
      atlas1__Date__c = Date.today().addMonths(-6), 
      atlas1__Type__c = 'Credit'
    ) }));
    // Act
    service.createReminderTask();

    // see if there is a call to create tasks, if there is, there should be no tasks
    for (MockCallData call : mocks.actualCalls) {
      if (call.obj == taskRepo && call.methodName == 'create') {
        System.assertEquals(1, ((List<Task>)call.args[0]).size());
        Task task = ((List<Task>)call.args[0])[0];
        System.assertEquals(bandit.Id, task.WhoId);
        System.assert(task.Subject.contains('Order background check'));
        System.assertEquals(adminGroup.Id, task.OwnerId);
        System.assertEquals(Date.today().addMonths(1), task.ActivityDate);
      }
    }
  }

  @isTest
  public static void createReminderTask_createsTaskWhenOtherContactWithAccessNeedsNew() {
    makeData();
    // Get the group to assign the task to
    Group adminGroup = [SELECT Id
                        FROM Group
                        WHERE Name = 'Background Check Administrator' AND Type = 'Queue'];
    Contact[] contacts = createContactsWithAccess();
    Contact bandit = contacts[3];
    mocks.expectedCalls.add(new MockCallData(contactRepo, 'getContactsNeedingBackgroundChecks', contacts));
    mocks.expectedCalls.add(new MockCallData(bgcRepo, 'getMatchingChecksForContacts', new List<atlas1__BackgroundCheck__c>{ new atlas1__BackgroundCheck__c(
      atlas1__Contact__c = contacts[0].id, 
      atlas1__Date__c = Date.today().addMonths(-3), 
      atlas1__Type__c = 'Credit'
    ), new atlas1__BackgroundCheck__c(
      atlas1__Contact__c = contacts[1].id, 
      atlas1__Date__c = Date.today().addMonths(-4), 
      atlas1__Type__c = 'Criminal'
    ), new atlas1__BackgroundCheck__c(
      atlas1__Contact__c = contacts[2].id, 
      atlas1__Date__c = Date.today().addMonths(-5), 
      atlas1__Type__c = 'Criminal'
    ), new atlas1__BackgroundCheck__c(
      atlas1__Contact__c = contacts[3].id, 
      atlas1__Date__c = Date.today().addMonths(-6), 
      atlas1__Type__c = 'Criminal'
    ) }));
    // Act
    service.createReminderTask();

    // see if there is a call to create tasks, if there is, there should be one task to order Bandit's check
    for (MockCallData call : mocks.actualCalls) {
      if (call.obj == taskRepo && call.methodName == 'create') {
        System.assertEquals(1, ((List<Task>)call.args[0]).size());
        Task task = ((List<Task>)call.args[0])[0];
        System.assertEquals(bandit.Id, task.WhoId);
        System.assert(task.Subject.contains('Order credit check'));
        System.assertEquals(adminGroup.Id, task.OwnerId);
        System.assertEquals(Date.today().addMonths(1), task.ActivityDate);
      }
    }
  }

  @isTest
  public static void createReminderTask_whenBothNeededTaskOpenAndOneIn() {
    makeData();
    Contact[] contacts = createContactsWithAccess();
    Contact bandit = contacts[3];
    Id userId = MockProvider.createId(User.class);
    // Get the group to assign the task to
    mocks.expectedCalls.add(new MockCallData(taskRepo, 'getBackgroundCheckUser', new User(Id = userId)));
    mocks.expectedCalls.add(new MockCallData(contactRepo, 'getContactsNeedingBackgroundChecks', contacts));
    mocks.expectedCalls.add(new MockCallData(bgcRepo, 'getMatchingChecksForContacts', new List<atlas1__BackgroundCheck__c>{ new atlas1__BackgroundCheck__c(
      atlas1__Contact__c = bandit.id, 
      atlas1__Date__c = Date.today().addDays(-2), 
      atlas1__Type__c = 'Credit'
    ), new atlas1__BackgroundCheck__c(
      atlas1__Contact__c = bandit.id, 
      atlas1__Date__c = Date.today().addMonths(-12), 
      atlas1__Type__c = 'Criminal'
    ) }));
    mocks.expectedCalls.add(new MockCallData(taskRepo, 'getTasksByWhoId', new Map<Id, List<Task>>{
      bandit.Id => new List<Task>{ new Task(Subject = 'Order background and credit check', ActivityDate = Date.today().addDays(-1)) }}));
    // Act
    service.createReminderTask();

    // see if there is a call to create tasks, if there is, there should be one task to order Bandit's check
    for (MockCallData call : mocks.actualCalls) {
      if (call.obj == taskRepo && call.methodName == 'create') {
        System.assertEquals(0, ((List<Task>)call.args[0]).size());
      }
    }
  }

}