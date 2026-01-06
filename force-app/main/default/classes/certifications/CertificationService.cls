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

  /* Send reminder emails and tasks related to Trainer renewal:
   - exactly 1 month before Trainer Certification Valid Until- "1 month email"
   - exactly 2 weeks before Trainer Certification Valid Until- "2 week email"
   - exactly 1 week before Trainer Certification Valid Until- "1 week email"
   - Day of Trainer Certification Valid Until = " last day email"
   - 1 week after = "you expired a week ago"
   - 30 days after Trainer Certification Valid Until-> "decertification email"
   */
  public void remindToRenew() {
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    // Create a list of Tasks
    Task[] tasks = new List<Task>();

    // Get the user to assign the task to
    User trainerManager = taskRepo.getTaskUser('Trainer Manager');
    User admin = taskRepo.getTaskUser('Administrator');

    // get the email templates
    EmailTemplate monthBefore = emailServ.getTemplate('TrainerMonthBefore');
    EmailTemplate twoWeeksBefore = emailServ.getTemplate('Trainer2WeeksBefore');
    EmailTemplate weekBefore = emailServ.getTemplate('TrainerWeekBefore');
    EmailTemplate today = emailServ.getTemplate('TrainerToday');
    EmailTemplate weekAfter = emailServ.getTemplate('TrainerWeekAfter');
    EmailTemplate monthAfter = emailServ.getTemplate('TrainerMonthAfter');

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
      switch  on numberDays {
        when  - 30 {
          if (monthBefore != null) {
            emails.add(emailServ.createEmail(cert.Id, cert.atlas1__Contact__c, monthBefore.Id));
          }
          // Create task for invoice
          if (trainerManager != null) {
            tasks.add(new Task(
              OwnerId = trainerManager.Id, 
              Subject = 'Trainer due for recertification in 1 month, invoice renewal', 
              Status = 'Open', 
              Priority = 'Normal', 
              WhoId = contactId, 
              ActivityDate = Date.today()
            ));
          }
        }
        when  - 14 {
          if (twoWeeksBefore != null) {
            emails.add(emailServ.createEmail(cert.Id, cert.atlas1__Contact__c, twoWeeksBefore.Id));
          }
        }
        when  - 7 {
          if (weekBefore != null) {
            emails.add(emailServ.createEmail(cert.Id, cert.atlas1__Contact__c, weekBefore.Id));
          }
          // Create task for invoice
          if (trainerManager != null) {
            tasks.add(new Task(
              OwnerId = trainerManager.Id, 
              Subject = 'Trainer is expiring in 1 week and they haven\'t replied', 
              Status = 'Open', 
              Priority = 'Normal', 
              WhoId = contactId, 
              ActivityDate = Date.today()
            ));
          }
        }
        when 0 {
          emails.add(emailServ.createEmail(cert.Id, cert.atlas1__Contact__c, today.Id));
        }
        when 7 {
          emails.add(emailServ.createEmail(cert.Id, cert.atlas1__Contact__c, weekAfter.Id));
        }
        when 30 {
          if (monthAfter != null) {
            emails.add(emailServ.createEmail(cert.Id, cert.atlas1__Contact__c, monthAfter.Id));
          }
          // Create task for decert
          if (trainerManager != null) {
            tasks.add(new Task(
              OwnerId = trainerManager.Id, 
              Subject = 'Trainer Discontinued', 
              Description = '- Send decert letter to Trainer\n- Change status to Discontinued\n- Remove from Canvas and facebook', 
              Status = 'Open', 
              Priority = 'Normal', 
              WhoId = contactId, 
              ActivityDate = Date.today()
            ));
          }
          if (admin != null) {
            tasks.add(new Task(
              OwnerId = admin.Id, 
              Subject = 'Trainer Discontinued', 
              Description = 'Remove from website', 
              Status = 'Open', 
              Priority = 'Normal', 
              WhoId = contactId, 
              ActivityDate = Date.today()
            ));
          }
        }
      }
    }
    emailServ.sendEmail(emails);
    taskRepo.create(tasks);
  }

}