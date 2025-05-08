global class RenewalReminder implements Schedulable {
  EmailService service;

  global RenewalReminder() {
    service = new EmailService();
  }

  /* Send reminder emails and tasks related to Trainer renewal:
   - exactly 1 month before Trainer Certification Valid Until- "1 month email"
   - exactly 2 weeks before Trainer Certification Valid Until- "2 week email"
   - exactly 1 week before Trainer Certification Valid Until- "1 week email"
   - Day of Trainer Certification Valid Until = " last day email"
   - 1 week after = "you expired a week ago"
   - 30 days after Trainer Certification Valid Until-> "decertification email"
   */
  global void execute(SchedulableContext sc) {
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    // Create a list of Tasks
    Task[] tasks = new List<Task>();

    // Get the group to assign the task to
    Group adminGroup = [SELECT Id
                        FROM Group
                        WHERE Name = 'Background Check Administrator' AND Type = 'Queue'];
    Group progGroup = [SELECT Id
                       FROM Group
                       WHERE Name = 'Program Administrator' AND Type = 'Queue'];

    atlas1__Certification__c[] certs = [SELECT atlas1__End__c, 
                                               atlas1__Approved__c, 
                                               atlas1__Contact__c
                                        FROM atlas1__Certification__c
                                        WHERE atlas1__Status__c = 'Current' AND atlas1__Type__c = 'Trainer'];
    for (atlas1__Certification__c cert : certs) {
      // If the Date that calls the method occurs after the secondDate, the return value is negative.
      Integer numberDays = cert.atlas1__End__c.daysBetween(Date.today());
      Id contactId = cert.atlas1__Contact__c;
      switch  on numberDays {
        when  - 30 {
          emails.add(createEmail('TrainerMonthBefore', cert.atlas1__Contact__c, cert.Id));
          // Create task for invoice
          tasks.add(new Task(
            OwnerId = adminGroup.Id, 
            Subject = 'Trainer due for recertification in 1 month, invoice renewal', 
            Status = 'Open', 
            Priority = 'Normal', 
            WhoId = contactId, 
            ActivityDate = Date.today()
          ));
        }
        when  - 14 {
          emails.add(createEmail('Trainer2WeeksBefore', cert.atlas1__Contact__c, cert.Id));
        }
        when  - 7 {
          emails.add(createEmail('TrainerWeekBefore', cert.atlas1__Contact__c, cert.Id));
          // Create task for invoice
          tasks.add(new Task(
            OwnerId = adminGroup.Id, 
            Subject = 'Trainer is expiring in 1 week and they haven\'t replied', 
            Status = 'Open', 
            Priority = 'Normal', 
            WhoId = contactId, 
            ActivityDate = Date.today()
          ));
        }
        when 0 {
          emails.add(createEmail('TrainerToday', cert.atlas1__Contact__c, cert.Id));
        }
        when 7 {
          emails.add(createEmail('TrainerWeekAfter', cert.atlas1__Contact__c, cert.Id));
        }
        when 30 {
          emails.add(createEmail('TrainerMonthAfter', cert.atlas1__Contact__c, cert.Id));
          // Create task for decert
          tasks.add(new Task(
            OwnerId = adminGroup.Id, 
            Subject = 'Trainer Discontinued', 
            Description = '- Send decert letter to Trainer\n- Change status to Discontinued\n- Remove from Canvas and facebook', 
            Status = 'Open', 
            Priority = 'Normal', 
            WhoId = contactId, 
            ActivityDate = Date.today()
          ));
          tasks.add(new Task(
            OwnerId = progGroup.Id, 
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
    service.sendEmail(emails);
  }

  private Messaging.SingleEmailMessage createEmail(String name, Id contactId, Id certId) {

    // Remind the contact for these certs to get their CEUs
    EmailTemplate template = service.getTemplate(name);
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    if (service.orgAddressId != null) {
      mail.setOrgWideEmailAddressId(service.orgAddressId);
    }
    mail.setTargetObjectId(contactId);
    mail.setWhatId(certId);
    mail.setBccSender(false);
    mail.setUseSignature(false);
    if (service.orgAddressId == null) {
      mail.setSenderDisplayName('Atlas Assistance Dogs');
    }
    mail.setSaveAsActivity(false);
    return mail;
  }

}