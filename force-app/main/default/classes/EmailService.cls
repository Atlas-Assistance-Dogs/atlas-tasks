public with sharing class EmailService {
    public Id orgAddressId { get; private  set; }
    private Map<String, EmailTemplate> templateMap = new Map<String, EmailTemplate>();

    public EmailService(Id orgAddressId) {
        this.orgAddressId = orgAddressId;
    }

    public EmailService() {

        atlas1__AtlasSettings__c settings = atlas1__AtlasSettings__c.getOrgDefaults();
        String emailName = settings.atlas1__OrgWideEmailName__c;
        if (emailName == null) {
            settings.atlas1__OrgWideEmailName__c = 'Atlas Assistance Dogs';
        }
        OrgWideEmailAddress[] addresses = [SELECT Id
                                           FROM OrgWideEmailAddress
                                           WHERE DisplayName = :emailName];
        if (addresses.size() > 0) {
            orgAddressId = addresses[0].Id;
        }
    }

    // Return the template from the template map if it's been retrieved already,
    // otherwise, retrieve it from the database and add it to the map.
    public EmailTemplate getTemplate(String name) {
        EmailTemplate__mdt et = EmailTemplate__mdt.getInstance(name);
        if (et == null) {
            return null;
        }
        if (templateMap.containsKey(name)) {
            return templateMap.get(name);
        }
        EmailTemplate[] templates = [SELECT Id, 
                                            CreatedDate, 
                                            DeveloperName
                                     FROM EmailTemplate
                                     WHERE DeveloperName = :et.Template__c AND IsActive = true
                                     LIMIT 1];
        if (templates.size() == 0) {
            templateMap.put(name, null);
            return null;
        }
        EmailTemplate template = templates[0];
        templateMap.put(name, template);
        return template;
    }

    public Messaging.SingleEmailMessage createEmail(Id whatId, Id contactId, Id templateId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if (orgAddressId != null) {
            mail.setOrgWideEmailAddressId(orgAddressId);
        }
        mail.setTargetObjectId(contactId);
        //Change with Template ID
        mail.setTemplateId(templateId);

        //Record ID for which letter will be generated
        mail.setWhatId(whatId);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        if (orgAddressId == null) {
            mail.setSenderDisplayName('Atlas Assistance Dogs');
        }
        mail.setSaveAsActivity(false);
        return mail;
    }

    // send email to contact.  Create EmailError records for failed emails.
    public void sendEmail(List<Messaging.SingleEmailMessage> emails) {
        // the second parameter is "allOrNothing" and defaults to true
        Messaging.SendEmailResult[] result = Messaging.sendEmail(emails, false);
        EmailError__c[] errors = new List<EmailError__c>();
        for (Messaging.SendEmailResult res : result) {
            if (!res.isSuccess()) {
                for (Messaging.SendEmailError err : res.errors) {
                    errors.add(new EmailError__c(
                        Fields__c = String.join(err.getFields(), ','), 
                        Message__c = err.message, 
                        StatusCode__c = err.getStatusCode().toString(), 
                        TargetObjectId__c = err.getTargetObjectId()
                    ));
                }
            }
        }
        insert errors;
    }

}