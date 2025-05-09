/**
 * This class contains unit tests for validating the behavior of CertificationService
 */
@isTest
private class CertificationServiceTest {
  private static MockProvider mocks;
  private static CertificationService service;
  private static EmailService emailSrv;
  private static CertificationRepository certRepo;

  // references to mocks
  static void makeData() {
    mocks = new MockProvider();
    emailSrv = (EmailService)mocks.createMock(EmailService.class);
    certRepo = (CertificationRepository)mocks.createMock(CertificationRepository.class);
    service = new CertificationService(certRepo, emailSrv);
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
    System.assertEquals(5, mocks.actualCalls.size(), 'wrong number of calls');
    Messaging.SingleEmailMessage[] messages = (Messaging.SingleEmailMessage[])mocks.actualCalls[4].args[0];
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

}