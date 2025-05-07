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
    atlas1__Certification__c[] certs = [SELECT atlas1__End__c, 
                                 atlas1__Approved__c,
                                 atlas1__Contact__c
                          FROM atlas1__Certification__c
                          WHERE atlas1__Status__c = 'Current' AND atlas1__Type__c = 'Trainer'];
    for (atlas1__Certification__c cert : certs) {
      // If the Date that calls the method occurs after the secondDate, the return value is negative.
      Integer numberDays = cert.atlas1__End__c.daysBetween(Date.today());
      switch  on numberDays {
        when  - 30 {
          emails.add(createEmail('oneMonthBefore', cert.atlas1__Contact__c, cert.Id));
        }
        when  - 14 {
          emails.add(createEmail('twoWeeksBefore', cert.atlas1__Contact__c, cert.Id));
        }
        when  - 7 {
          emails.add(createEmail('oneWeekBefore', cert.atlas1__Contact__c, cert.Id));
        }
        when 0 {
          emails.add(createEmail('today', cert.atlas1__Contact__c, cert.Id));
        }
        when 7 {
          emails.add(createEmail('oneWeekAfter', cert.atlas1__Contact__c, cert.Id));
        }
        when 30 {
          emails.add(createEmail('oneMonthAfter', cert.atlas1__Contact__c, cert.Id));
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