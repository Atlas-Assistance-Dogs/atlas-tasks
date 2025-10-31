/**
 * This class contains unit tests for validating the behavior of Apex class EmailService
 */
@isTest
private class EmailServiceTest {
    @isTest
    static void service_instantiatesWithoutEmail() {
        EmailService service = new EmailService();

        Id emailId = service.orgAddressId;

        System.assertEquals(null, emailId, 'service instantiation error');
    }

    @isTest
    static void getTemplate_returnsEmpty_whenBadName() {
        EmailService service = new EmailService();
        EmailTemplate template = service.getTemplate('nonexistent template');

        System.assertEquals(null, template, 'address id is null');
    }

    @isTest
    static void getTemplate_returnsEmptyWhenTemplateNotFound() {
        EmailTemplate et = new EmailTemplate(
            DeveloperName = 'mine', 
            FolderId = UserInfo.getUserId(), 
            TemplateType = 'Text', 
            Name = 'my template'
        );
        insert et;

        EmailService service = new EmailService();
        EmailTemplate template = service.getTemplate('mine');

        System.assertEquals(null, template, 'address id matches');
    }

    @isTest
    static void getTemplate_returnsTrainerTemplate() {
        EmailTemplate et = new EmailTemplate(
            DeveloperName = 'Trainer_Month_After', 
            IsActive = true, 
            FolderId = UserInfo.getUserId(), 
            TemplateType = 'Text', 
            Name = 'my template'
        );
        insert et;

        EmailService service = new EmailService();
        EmailTemplate template = service.getTemplate('TrainerMonthAfter');

        System.assertEquals(et.Id, template.Id, 'returned wrong template');
    }

    @isTest
    static void createEmail_returnsEmail() {
        EmailService service = new EmailService();
        Id whatId = MockProvider.createId(atlas1__Team__c.class);
        Id whoId = MockProvider.createId(Contact.class);
        Id templateId = MockProvider.createId(emailTemplate.class);
        Messaging.SingleEmailMessage email = service.createEmail(whatId, whoId, templateId);

        System.Assert.isTrue(email != null, 'email is null');
        System.assertEquals(whatId, email.whatId, 'whatId does not match');
        System.assertEquals(whoId, email.targetObjectId, 'whoId does not match');
        System.assertEquals(templateId, email.templateId, 'templateId does not match');
    }

    @isTest
    static void sendEmail_sendsEmail() {
        EmailService service = new EmailService();
        Id whatId = MockProvider.createId(atlas1__Team__c.class);
        Id whoId = MockProvider.createId(Contact.class);
        Id templateId = MockProvider.createId(emailTemplate.class);
        Messaging.SingleEmailMessage email = service.createEmail(whatId, whoId, templateId);

        Test.StartTest();
        service.sendEmail(new Messaging.SingleEmailMessage[]{ email });
        Integer invocations = Limits.getEmailInvocations();
        Test.StopTest();
        System.assertEquals(1, invocations, 'An email has not been sent');
    }

}