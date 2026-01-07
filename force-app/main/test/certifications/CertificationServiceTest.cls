/**
 * This class contains unit tests for validating the behavior of CertificationService
 */
@isTest
private class CertificationServiceTest {
  private static MockProvider mocks;
  private static CertificationService service;
  private static EmailService emailSrv;
  private static CertificationRepository certRepo;
  private static TaskRepository taskRepo;

  // references to mocks
  static void makeData() {
    mocks = new MockProvider();
    emailSrv = (EmailService)mocks.createMock(EmailService.class);
    certRepo = (CertificationRepository)mocks.createMock(CertificationRepository.class);
    taskRepo = (TaskRepository)mocks.createMock(TaskRepository.class);
    service = new CertificationService(certRepo, emailSrv, taskRepo);
  }

  @isTest
  static void remindToGetCeus_doesNothing_whenNoCerts() {
    makeData();
    mocks.expectedCalls.add(new MockCallData(certRepo, 'getActiveCerts', new List<atlas1__Certification__c>()));
    // act
    service.remindToGetCeus();
    // assert
    System.assertEquals(1, mocks.actualCalls.size(), 'too many calls');
  }

  @isTest
  static void remindToGetCeus_email_whenCerts() {
    makeData();
    atlas1__Certification__c[] certs = new List<atlas1__Certification__c>{ new atlas1__Certification__c(
      atlas1__Contact__c = MockProvider.createId(Contact.class), 
      atlas1__Type__c = 'Facilitator', 
      atlas1__Status__c = 'Active', 
      atlas1__Start__c = Date.today(), 
      atlas1__End__c = Date.today().addYears(1)
    ), new atlas1__Certification__c(
      atlas1__Contact__c = MockProvider.createId(Contact.class), 
      atlas1__Type__c = 'Trainer', 
      atlas1__Status__c = 'Active', 
      atlas1__Start__c = Date.today().addMonths(1), 
      atlas1__End__c = Date.today().addYears(1).addMonths(1)
    ) };
    Id emailId = MockProvider.createId(OrgWideEmailAddress.class);
    Id facTemplateId = MockProvider.createId(EmailTemplate.class);
    Id trainTemplateId = MockProvider.createId(EmailTemplate.class);
    mocks.expectedCalls.add(new MockCallData(certRepo, 'getActiveCerts', certs));
    mocks.expectedCalls.add(new MockCallData(emailSrv, 'getOrgEmailAddressId', emailId));
    mocks.expectedCalls.add(new MockCallData(emailSrv, 'getTemplate', new EmailTemplate(
      Id = facTemplateId
    )));
    mocks.expectedCalls.add(new MockCallData(emailSrv, 'getTemplate', new EmailTemplate(
      Id = trainTemplateId
    )));
    // act
    service.remindToGetCeus();
    // assert
    System.assertEquals(6, mocks.actualCalls.size(), 'wrong number of calls');
    Messaging.SingleEmailMessage[] messages = (Messaging.SingleEmailMessage[])mocks.actualCalls[5].args[0];
    for (Integer i; i < certs.size(); i++) {
      Messaging.SingleEmailMessage message = messages[i];
      atlas1__Certification__c cert = certs[i];
      Id templateId = facTemplateId;
      if (i == 1) {
        templateId = trainTemplateId;
      }
      System.assertEquals(emailId, message.orgwideemailaddressid, 'wrong target object');
      System.assertEquals(cert.atlas1__Contact__c, message.TargetObjectId, 'wrong target object');
      System.assertEquals(cert.Id, message.WhatId, 'wrong target object');
      System.assertEquals(templateId, message.templateid, 'wrong template id');
    }
  }

  private static User admin = new User(
    Id = MockProvider.createId(User.class)
  );
  private static User manager = new User(
    Id = MockProvider.createId(User.class)
  );
  private static EmailTemplate monthBefore = new EmailTemplate(
    Id = MockProvider.createId(EmailTemplate.class), 
    Name = 'TrainerMonthBefore'
  );
  private static EmailTemplate twoWeeksBefore = new EmailTemplate(
    Id = MockProvider.createId(EmailTemplate.class), 
    Name = 'Trainer2WeeksBefore'
  );
  private static EmailTemplate weekBefore = new EmailTemplate(
    Id = MockProvider.createId(EmailTemplate.class), 
    Name = 'TrainerWeekBefore'
  );
  private static EmailTemplate today = new EmailTemplate(
    Id = MockProvider.createId(EmailTemplate.class), 
    Name = 'TrainerToday'
  );
  private static EmailTemplate weekAfter = new EmailTemplate(
    Id = MockProvider.createId(EmailTemplate.class), 
    Name = 'TrainerWeekAfter'
  );
  private static EmailTemplate monthAfter = new EmailTemplate(
    Id = MockProvider.createId(EmailTemplate.class), 
    Name = 'TrainerMonthAfter'
  );
  static void setup() {
    mocks.expectedCalls.add(new MockCallData(taskRepo, 'getTaskUser', admin, new Object[]{ 'Administrator' }));
    mocks.expectedCalls.add(new MockCallData(taskRepo, 'getTaskUser', manager, new Object[]{ 'Trainer Manager' }));
    mocks.expectedCalls.add(new MockCallData(emailSrv, 'getTemplate', monthBefore, new Object[]{ 'TrainerMonthBefore' }));
    mocks.expectedCalls.add(new MockCallData(emailSrv, 'getTemplate', twoWeeksBefore, new Object[]{ 'Trainer2WeeksBefore' }));
    mocks.expectedCalls.add(new MockCallData(emailSrv, 'getTemplate', weekBefore, new Object[]{ 'TrainerWeekBefore' }));
    mocks.expectedCalls.add(new MockCallData(emailSrv, 'getTemplate', today, new Object[]{ 'TrainerToday' }));
    mocks.expectedCalls.add(new MockCallData(emailSrv, 'getTemplate', weekAfter, new Object[]{ 'TrainerWeekAfter' }));
    mocks.expectedCalls.add(new MockCallData(emailSrv, 'getTemplate', monthAfter, new Object[]{ 'TrainerMonthAfter' }));
  }

  @isTest
  static void remindToRenew_getsTemplates() {
    makeData();
    setup();
    // act
    service.remindToRenew();
    // assert
    System.assertEquals(9, mocks.actualCalls.size(), 'wrong number of calls');
  }

  @isTest
  static void remindToRenew_continuesWhenNoDate() {
    makeData();
    mocks.expectedCalls.add(new MockCallData(certRepo, 'getActiveTrainerCerts', new List<atlas1__Certification__c>{ new atlas1__Certification__c(
      Id = MockProvider.createId(atlas1__Certification__c.class), 
      atlas1__Contact__c = MockProvider.createId(Contact.class)
    ) }));
    // act
    service.remindToRenew();
    // assert
    System.assertEquals(11, mocks.actualCalls.size(), 'wrong number of calls');
  }

  @isTest
  static void remindToRenew_handlesMissingMonthBefore() {
    makeData();
    mocks.expectedCalls.add(new MockCallData(certRepo, 'getActiveTrainerCerts', new List<atlas1__Certification__c>{ new atlas1__Certification__c(
      Id = MockProvider.createId(atlas1__Certification__c.class), 
      atlas1__Contact__c = MockProvider.createId(Contact.class), 
      atlas1__End__c = Date.today().addDays(30)
    ) }));
    // act
    service.remindToRenew();
    // assert
    System.assertEquals(11, mocks.actualCalls.size(), 'wrong number of calls');
  }

  @isTest
  static void remindToRenew_handlesMissingTaskUsers() {
    makeData();
    mocks.expectedCalls.add(new MockCallData(certRepo, 'getActiveTrainerCerts', new List<atlas1__Certification__c>{ new atlas1__Certification__c(
      Id = MockProvider.createId(atlas1__Certification__c.class), 
      atlas1__Contact__c = MockProvider.createId(Contact.class), 
      atlas1__End__c = Date.today().addDays(30)
    ), new atlas1__Certification__c(
      Id = MockProvider.createId(atlas1__Certification__c.class), 
      atlas1__Contact__c = MockProvider.createId(Contact.class), 
      atlas1__End__c = Date.today().addDays(7)
    ), new atlas1__Certification__c(
      Id = MockProvider.createId(atlas1__Certification__c.class), 
      atlas1__Contact__c = MockProvider.createId(Contact.class), 
      atlas1__End__c = Date.today().addDays(-30)
    ) }));
    // act
    service.remindToRenew();
    // assert
    System.assertEquals(11, mocks.actualCalls.size(), 'wrong number of calls');
  }

  @isTest
  static void remindToRenew_handlesMissing2weeksBefore() {
    makeData();
    mocks.expectedCalls.add(new MockCallData(certRepo, 'getActiveTrainerCerts', new List<atlas1__Certification__c>{ new atlas1__Certification__c(
      Id = MockProvider.createId(atlas1__Certification__c.class), 
      atlas1__Contact__c = MockProvider.createId(Contact.class), 
      atlas1__End__c = Date.today().addDays(14)
    ) }));
    // act
    service.remindToRenew();
    // assert
    System.assertEquals(11, mocks.actualCalls.size(), 'wrong number of calls');
  }

  @isTest
  static void remindToRenew_handlesMissingWeekBefore() {
    makeData();
    mocks.expectedCalls.add(new MockCallData(certRepo, 'getActiveTrainerCerts', new List<atlas1__Certification__c>{ new atlas1__Certification__c(
      Id = MockProvider.createId(atlas1__Certification__c.class), 
      atlas1__Contact__c = MockProvider.createId(Contact.class), 
      atlas1__End__c = Date.today().addDays(7)
    ) }));
    // act
    service.remindToRenew();
    // assert
    System.assertEquals(11, mocks.actualCalls.size(), 'wrong number of calls');
  }

  @isTest
  static void remindToRenew_sendsEmailsTasksWhen30DaysBefore() {
    makeData();
    setup();
    atlas1__Certification__c cert = new atlas1__Certification__c(
      Id = MockProvider.createId(atlas1__Certification__c.class), 
      atlas1__Contact__c = MockProvider.createId(Contact.class), 
      atlas1__End__c = Date.today().addDays(30)
    );
    mocks.expectedCalls.add(new MockCallData(certRepo, 'getActiveTrainerCerts', new List<atlas1__Certification__c>{ cert }));
    mocks.expectedCalls.add(new MockCallData(emailSrv, 'createEmail', new Messaging.SingleEmailMessage()));
    // act
    service.remindToRenew();
    // assert
    System.assertEquals(12, mocks.actualCalls.size(), 'wrong number of calls');
    MockCallData call = mocks.findCallByMethod('createEmail');
    System.Assert.areEqual(new Object[]{ cert.Id, cert.atlas1__Contact__c, monthBefore.Id }, call.args, 'wrong args');
    call = mocks.findCallByMethod('sendEmail');
    System.Assert.isNotNull(call, 'sendEmail not called');
    call = mocks.findCallByMethod('create');
    System.Assert.isNotNull(call, 'create not called');
    Task[] tasks = (Task[])call.args[0];
    System.Assert.areEqual(new Task[]{ new Task(
      OwnerId = manager.Id, 
      Subject = 'Trainer due for recertification in 1 month, invoice renewal', 
      Status = 'Open', 
      Priority = 'Normal', 
      WhoId = cert.atlas1__Contact__c, 
      ActivityDate = Date.today()
    ) }, tasks, 'wrong tasks');
  }

  @isTest
  static void remindToRenew_sendsEmailWhen14DaysBefore() {
    makeData();
    setup();
    atlas1__Certification__c cert = new atlas1__Certification__c(
      Id = MockProvider.createId(atlas1__Certification__c.class), 
      atlas1__Contact__c = MockProvider.createId(Contact.class), 
      atlas1__End__c = Date.today().addDays(14)
    );
    mocks.expectedCalls.add(new MockCallData(certRepo, 'getActiveTrainerCerts', new List<atlas1__Certification__c>{ cert }));
    mocks.expectedCalls.add(new MockCallData(emailSrv, 'createEmail', new Messaging.SingleEmailMessage()));
    // act
    service.remindToRenew();
    // assert
    System.assertEquals(12, mocks.actualCalls.size(), 'wrong number of calls');
    MockCallData call = mocks.findCallByMethod('createEmail');
    System.Assert.areEqual(new Object[]{ cert.Id, cert.atlas1__Contact__c, twoWeeksBefore.Id }, call.args, 'wrong args');
    call = mocks.findCallByMethod('sendEmail');
    System.Assert.isNotNull(call, 'sendEmail not called');
    call = mocks.findCallByMethod('create');
    System.Assert.isNotNull(call, 'create not called');
    Task[] tasks = (Task[])call.args[0];
    System.Assert.areEqual(0, tasks.size(), 'tasks are not empty');
  }

  @isTest
  static void remindToRenew_sendsEmailsTasksWhenWeekBefore() {
    makeData();
    setup();
    atlas1__Certification__c cert = new atlas1__Certification__c(
      Id = MockProvider.createId(atlas1__Certification__c.class), 
      atlas1__Contact__c = MockProvider.createId(Contact.class), 
      atlas1__End__c = Date.today().addDays(7)
    );
    mocks.expectedCalls.add(new MockCallData(certRepo, 'getActiveTrainerCerts', new List<atlas1__Certification__c>{ cert }));
    mocks.expectedCalls.add(new MockCallData(emailSrv, 'createEmail', new Messaging.SingleEmailMessage()));
    // act
    service.remindToRenew();
    // assert
    System.assertEquals(12, mocks.actualCalls.size(), 'wrong number of calls');
    MockCallData call = mocks.findCallByMethod('createEmail');
    System.Assert.areEqual(new Object[]{ cert.Id, cert.atlas1__Contact__c, weekBefore.Id }, call.args, 'wrong args');
    call = mocks.findCallByMethod('sendEmail');
    System.Assert.isNotNull(call, 'sendEmail not called');
    call = mocks.findCallByMethod('create');
    System.Assert.isNotNull(call, 'create not called');
    Task[] tasks = (Task[])call.args[0];
    System.Assert.areEqual(new Task[]{ new Task(
      OwnerId = manager.Id, 
      Subject = 'Trainer is expiring in 1 week and they haven\'t replied', 
      Status = 'Open', 
      Priority = 'Normal', 
      WhoId = cert.atlas1__Contact__c, 
      ActivityDate = Date.today()
    ) }, tasks, 'wrong tasks');
  }

  @isTest
  static void remindToRenew_sendsEmailWhenDayOf() {
    makeData();
    setup();
    atlas1__Certification__c cert = new atlas1__Certification__c(
      Id = MockProvider.createId(atlas1__Certification__c.class), 
      atlas1__Contact__c = MockProvider.createId(Contact.class), 
      atlas1__End__c = Date.today()
    );
    mocks.expectedCalls.add(new MockCallData(certRepo, 'getActiveTrainerCerts', new List<atlas1__Certification__c>{ cert }));
    mocks.expectedCalls.add(new MockCallData(emailSrv, 'createEmail', new Messaging.SingleEmailMessage()));
    // act
    service.remindToRenew();
    // assert
    System.assertEquals(12, mocks.actualCalls.size(), 'wrong number of calls');
    MockCallData call = mocks.findCallByMethod('createEmail');
    System.Assert.areEqual(new Object[]{ cert.Id, cert.atlas1__Contact__c, today.Id }, call.args, 'wrong args');
    call = mocks.findCallByMethod('sendEmail');
    System.Assert.isNotNull(call, 'sendEmail not called');
    call = mocks.findCallByMethod('create');
    System.Assert.isNotNull(call, 'create not called');
    Task[] tasks = (Task[])call.args[0];
    System.Assert.areEqual(0, tasks.size(), 'wrong tasks');
  }

  @isTest
  static void remindToRenew_sendsEmailWhenWeekAfter() {
    makeData();
    setup();
    atlas1__Certification__c cert = new atlas1__Certification__c(
      Id = MockProvider.createId(atlas1__Certification__c.class), 
      atlas1__Contact__c = MockProvider.createId(Contact.class), 
      atlas1__End__c = Date.today().addDays(-7)
    );
    mocks.expectedCalls.add(new MockCallData(certRepo, 'getActiveTrainerCerts', new List<atlas1__Certification__c>{ cert }));
    mocks.expectedCalls.add(new MockCallData(emailSrv, 'createEmail', new Messaging.SingleEmailMessage()));
    // act
    service.remindToRenew();
    // assert
    System.assertEquals(12, mocks.actualCalls.size(), 'wrong number of calls');
    MockCallData call = mocks.findCallByMethod('createEmail');
    System.Assert.areEqual(new Object[]{ cert.Id, cert.atlas1__Contact__c, weekAfter.Id }, call.args, 'wrong args');
    call = mocks.findCallByMethod('sendEmail');
    System.Assert.isNotNull(call, 'sendEmail not called');
    call = mocks.findCallByMethod('create');
    System.Assert.isNotNull(call, 'create not called');
    Task[] tasks = (Task[])call.args[0];
    System.Assert.areEqual(0, tasks.size(), 'wrong tasks');
  }

  @isTest
  static void remindToRenew_sendsEmailsTasksWhen30DaysLate() {
    makeData();
    setup();
    atlas1__Certification__c cert = new atlas1__Certification__c(
      Id = MockProvider.createId(atlas1__Certification__c.class), 
      atlas1__Contact__c = MockProvider.createId(Contact.class), 
      atlas1__End__c = Date.today().addDays(-30)
    );
    mocks.expectedCalls.add(new MockCallData(certRepo, 'getActiveTrainerCerts', new List<atlas1__Certification__c>{ cert }));
    mocks.expectedCalls.add(new MockCallData(emailSrv, 'createEmail', new Messaging.SingleEmailMessage()));
    // act
    service.remindToRenew();
    // assert
    System.assertEquals(12, mocks.actualCalls.size(), 'wrong number of calls');
    MockCallData call = mocks.findCallByMethod('createEmail');
    System.Assert.areEqual(new Object[]{ cert.Id, cert.atlas1__Contact__c, monthAfter.Id }, call.args, 'wrong args');
    call = mocks.findCallByMethod('sendEmail');
    System.Assert.isNotNull(call, 'sendEmail not called');
    call = mocks.findCallByMethod('create');
    System.Assert.isNotNull(call, 'create not called');
    Task[] tasks = (Task[])call.args[0];
    System.Assert.areEqual(new Task[]{ new Task(
      OwnerId = manager.Id, 
      Subject = 'Trainer Discontinued', 
      Description = '- Send decert letter to Trainer\n- Change status to Discontinued\n- Remove from Canvas and facebook', 
      Status = 'Open', 
      Priority = 'Normal', 
      WhoId = cert.atlas1__Contact__c, 
      ActivityDate = Date.today()
    ), new Task(
      OwnerId = admin.Id, 
      Subject = 'Trainer Discontinued', 
      Description = 'Remove from website', 
      Status = 'Open', 
      Priority = 'Normal', 
      WhoId = cert.atlas1__Contact__c, 
      ActivityDate = Date.today()
    ) }, tasks, 'wrong tasks');
  }

}