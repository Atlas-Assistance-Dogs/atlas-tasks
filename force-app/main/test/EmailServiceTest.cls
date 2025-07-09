/**
 * This class contains unit tests for validating the behavior of Apex class EmailService
 */
@isTest
private class EmailServiceTest {
    @isTest
    static void service_instantiatesWithoutEmail() {
        EmailService service = new EmailService();

        Id emailId = service.orgAddressId;

        System.assert(true, 'service instantiation error');
    }

    @isTest
    static void getTemplate_returnsEmpty_whenBadName() {
        EmailService service = new EmailService();
        EmailTemplate template = service.getTemplate('nonexistent template');

        System.assertEquals(null, template, 'address id is null');
    }

    @isTest
    static void getTemplate_returnsEmptyWhenTemplateNotFound() {
        EmailTemplate et = new EmailTemplate(DeveloperName = 'mine', FolderId = UserInfo.getUserId(), TemplateType = 'Text', Name = 'my template');
        insert et;

        EmailService service = new EmailService();
        EmailTemplate template = service.getTemplate('mine');

        System.assertEquals(null, template, 'address id matches');
    }
}