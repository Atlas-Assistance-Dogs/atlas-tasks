/** class for managing email operations. */
public inherited sharing class EmailService {
    /** Gets or sets the ID of the organization-wide email address. */
    public Id orgAddressId { get;private  set; }

    private Map<String, EmailTemplate> templateMap = new Map<String, EmailTemplate>();
    /**
     * Initializes a new instance of the EmailService class with the specified organization-wide email address ID.
     * @param orgAddressId The ID of the organization-wide email address.
     */
    public EmailService(Id orgAddressId) {
        this.orgAddressId = orgAddressId;
    }

    /**
     * Initializes a new instance of the EmailService class.
     */
    public EmailService() {

        atlas1__AtlasSettings__c settings = atlas1__AtlasSettings__c.getOrgDefaults();
        String emailName = settings.atlas1__OrgWideEmailName__c;
        if (emailName == null) {
            settings.atlas1__OrgWideEmailName__c = 'Atlas Assistance Dogs';
        }
        OrgWideEmailAddress[] addresses = [SELECT Id
                                           FROM OrgWideEmailAddress
                                           WHERE DisplayName = :emailName
                                           WITH SECURITY_ENFORCED];
        if (addresses.size() > 0) {
            orgAddressId = addresses[0].Id;
        }
    }

    /**
     * Return the template from the template map if it's been retrieved already,
     * otherwise, retrieve it from the database and add it to the map.
     * @param name The name of the template to retrieve.
     * @return The retrieved email template or null if not found.
     */
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
                                     WITH SECURITY_ENFORCED
                                     LIMIT 1];
        if (templates.size() == 0) {
            templateMap.put(name, null);
            return null;
        }
        EmailTemplate template = templates[0];
        templateMap.put(name, template);
        return template;
    }

    /**
     * Creates an email message.
     * @param whatId The ID of the record to which the email belongs.
     * @param contactId The ID of the contact to whom the email will be sent.
     * @param templateId The ID of the email template to use.
     * @return The created email message.
     */
    public Messaging.SingleEmailMessage createEmail(Id whatId, Id contactId, Id templateId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if (orgAddressId != null) {
            mail.setOrgWideEmailAddressId(orgAddressId);
        }
        mail.setTargetObjectId(contactId);
        // Change Template ID
        mail.setTemplateId(templateId);

        // Record ID for which contact or lead will be emailed
        mail.setWhatId(whatId);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        if (orgAddressId == null) {
            mail.setSenderDisplayName('Atlas Assistance Dogs');
        }
        // save email as an activity in the recipient's activity history.
        mail.setSaveAsActivity(true);
        return mail;
    }

    /**
     * Sends email to contact.  Create EmailError records for failed emails.
     * @param emails The list of email messages to send.
     */
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
        if (!errors.isEmpty() && Schema.sObjectType.EmailError__c.isCreateable()) {
            insert errors;
        }
    }

}
