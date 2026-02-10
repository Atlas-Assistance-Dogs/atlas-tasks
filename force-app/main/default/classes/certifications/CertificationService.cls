public with sharing class CertificationService {
  CertificationRepository certRepo;
  EmailService emailServ;
  TaskRepository taskRepo;

  public CertificationService() {
    certRepo = new CertificationRepository();
    emailServ = new EmailService();
    taskRepo = new TaskRepository();
  }

  @testVisible
  private CertificationService(CertificationRepository certRepo, EmailService emailServ, TaskRepository taskRepo) {
    this.certRepo = certRepo;
    this.emailServ = emailServ;
    this.taskRepo = taskRepo;
  }

  public void remindToGetCeus() {
    atlas1__Certification__c[] certs = certRepo.getActiveCerts();

    if (certs.isEmpty()) {
      return;
    }
    // Remind the contact for these certs to get their CEUs
    EmailTemplate facTemplate = emailServ.getTemplate('CeuFacilitatorReminder');
    EmailTemplate trainTemplate = emailServ.getTemplate('CeuTrainerReminder');

    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    for (atlas1__Certification__c cert : certs) {
      Id templateId;
      if (cert.atlas1__Type__c == 'Facilitator') {
        templateId = facTemplate.Id;
      } else {
        templateId = trainTemplate.Id;
      }

      Messaging.SingleEmailMessage mail = emailServ.createEmail(cert.Id, cert.atlas1__Contact__c, templateId);

      emails.add(mail);
    }

    emailServ.sendEmail(emails);
  }

  final Integer requiredCEUs = 10;  
  final String decertTaskSubject = 'Trainer Deactivated';
  final String decertTaskDescription = '- Email decert letter\n- Change status to discontinued\n- Remove from Canvas and facebook';
  /* Send reminder emails and tasks related to Trainer renewal:
   - exactly 1 month before Trainer Certification Valid Until- "1 month email"
   - exactly 2 weeks before Trainer Certification Valid Until- "2 week email"
   - exactly 1 week before Trainer Certification Valid Until- "1 week email"
   - Day of Trainer Certification Valid Until = " last day email"
    */
  public void remindToRenew() {
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    // Create a list of Tasks
    Task[] tasks = new List<Task>();

    // Get the user to assign the task to
    User trainerManager = taskRepo.getTaskUser('Trainer Manager');
    User admin = taskRepo.getTaskUser('Administrator');

    atlas1__Certification__c[] certs = certRepo.getActiveTrainerCerts();
    if (certs == null || certs.isEmpty()) {
      return;
    }
    for (atlas1__Certification__c cert : certs) {
      if (cert.atlas1__End__c == null) {
        continue;
      }
      // If the Date that calls the method occurs after the secondDate, the return value is negative.
      Integer numberDays = cert.atlas1__End__c.daysBetween(Date.today());
      Id contactId = cert.atlas1__Contact__c;
      EmailTemplate template;
      switch  on numberDays {
        when  - 30 {
          emails.addAll(monthBeforeEmails(cert, requiredCEUs));
          // Create task for invoice
          tasks.addAll(monthBeforeTasks(admin, cert));
        }
        when  - 14 {
          emails.addAll(twoWeeksBeforeEmails(cert, requiredCEUs));
        }
        when  - 7 {
          emails.addAll(weekBeforeEmails(cert, requiredCEUS));
          tasks.addAll(weekBeforeTasks(admin, cert));
        }
        when 1 {
          emails.addAll(dayAfterEmails(cert, requiredCEUs));
          tasks.addAll(dayAfterTasks(admin, trainerManager, cert));
        }
      }
    }
    emailServ.sendEmail(emails);
    taskRepo.create(tasks);
  }

  private Messaging.SingleEmailMessage[] monthBeforeEmails(atlas1__Certification__c cert, Integer requiredCEUs) {
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    EmailTemplate template;
    if (cert.atlas1__Approved__c == null || cert.atlas1__Approved__c < requiredCEUs) {
      template = emailServ.getTemplate('TrainerMonthBeforeCEUs');
    } else {
      template = emailServ.getTemplate('TrainerMonthBefore');
    }
    if (template != null) {
      emails.add(emailServ.createEmail(cert.Id, cert.atlas1__Contact__c, template.Id));
    }
    return emails;
  }

  private Task[] monthBeforeTasks(User admin, atlas1__Certification__c cert) {
    Task[] tasks = new List<Task>();
    if (admin != null) {
      tasks.add(new Task(
        OwnerId = admin.Id, 
        Subject = 'Trainer due for recertification in 1 month, invoice renewal', 
        Status = 'Open', 
        Priority = 'Normal', 
        WhoId = cert.atlas1__Contact__c, 
        ActivityDate = Date.today()
      ));
    }
    return tasks;
  }

  private Messaging.SingleEmailMessage[] twoWeeksBeforeEmails(atlas1__Certification__c cert, Integer requiredCEUs) {
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    EmailTemplate template;
    if (cert.atlas1__Approved__c == null || cert.atlas1__Approved__c < requiredCEUs) {
      template = emailServ.getTemplate('Trainer2WeeksBeforeCEUs');
    } else {
      template = emailServ.getTemplate('Trainer2WeeksBefore');
    }

    if (template != null) {
      emails.add(emailServ.createEmail(cert.Id, cert.atlas1__Contact__c, template.Id));
    }
    return emails;
  }

  private Messaging.SingleEmailMessage[] weekBeforeEmails(atlas1__Certification__c cert, Integer requiredCEUs) {
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    EmailTemplate template;
    if (cert.atlas1__Approved__c == null || cert.atlas1__Approved__c < requiredCEUs) {
      template = emailServ.getTemplate('TrainerWeekBeforeCEUs');
    } else {
      template = emailServ.getTemplate('TrainerWeekBefore');
    }
    if (template != null) {
      emails.add(emailServ.createEmail(cert.Id, cert.atlas1__Contact__c, template.Id));
    }
    return emails;
  }

  private Task[] weekBeforeTasks(User admin, atlas1__Certification__c cert) {
    Task[] tasks = new List<Task>();
    // Create task for invoice
    if (admin != null) {
      tasks.add(new Task(
        OwnerId = admin.Id, 
        Subject = 'Trainer is expiring in 1 week and they haven\'t replied', 
        Description = 'Check on invoice, CEU and renewal status',
        Status = 'Open', 
        Priority = 'Normal', 
        WhoId = cert.atlas1__Contact__c, 
        ActivityDate = Date.today()
      ));
    }
    return tasks;
  }

  private Messaging.SingleEmailMessage[] dayAfterEmails(atlas1__Certification__c cert, Integer requiredCEUs) {
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    EmailTemplate template;
    if (cert.atlas1__Approved__c == null || cert.atlas1__Approved__c < requiredCEUs) {
      template = emailServ.getTemplate('TrainerTodayCEUs');
    } else {
      template = emailServ.getTemplate('TrainerToday');
    }
    if (template != null) {
      emails.add(emailServ.createEmail(cert.Id, cert.atlas1__Contact__c, template.Id));
    }
    return emails;
  }

  private Task[] dayAfterTasks(User admin, User trainerManager, atlas1__Certification__c cert) {
    Task[] tasks = new List<Task>();
    // Create task for decert
    if (admin != null) {
      tasks.add(new Task(
        OwnerId = admin.Id, 
        Subject = decertTaskSubject, 
        Description = decertTaskDescription, 
        Status = 'Open', 
        Priority = 'Normal', 
        WhoId = cert.atlas1__Contact__c, 
        ActivityDate = Date.today()
      ));
    }
    if (trainerManager != null) {
      tasks.add(new Task(
        OwnerId = trainerManager.Id, 
        Subject = decertTaskSubject, 
        Description = 'Remove from website', 
        Status = 'Open', 
        Priority = 'Normal', 
        WhoId = cert.atlas1__Contact__c, 
        ActivityDate = Date.today()
      ));
    }
    return tasks;
  }

}