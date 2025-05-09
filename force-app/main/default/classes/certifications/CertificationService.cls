public with sharing class CertificationService {
  CertificationRepository certRepo;
  EmailService emailServ;

  public CertificationService() {
    certRepo = new CertificationRepository();
    emailServ = new EmailService();
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

}