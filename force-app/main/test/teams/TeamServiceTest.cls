/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest
private class TeamServiceTest {
    private static MockProvider mocks;
    private static TeamService service;
    private static TeamRepository teamRepo;
    private static RelationshipRepository relationshipRepo;
    private static EmailService emailSrv;

    // references to mocks
    private static void makeData() {
        mocks = new MockProvider();
        teamRepo = (TeamRepository)mocks.createMock(TeamRepository.class);
        relationshipRepo = (RelationshipRepository)mocks.createMock(RelationshipRepository.class);
        emailSrv = (EmailService)mocks.createMock(EmailService.class);
        service = new TeamService(teamRepo, emailSrv, relationshipRepo);
    }

    @isTest
    static void remindClients_sendsNoEmails_whenNoTeams() {
        makeData();
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', new List<atlas1__Team__c>()));
        service.remindClients();
        // Assert
        System.assert(!mocks.actualCalls.isEmpty());
        // the first call would be to get teams
        MockCallData getTeams = mocks.actualCalls[0];
        System.assertEquals('getByStatus', getTeams.methodName);
        System.assertEquals('In Training', getTeams.args[0]);
        // see if there is a call to sendEmail, if there is, there should be no
        // emails
        for (MockCallData call : mocks.actualCalls) {
            if (call.obj == emailSrv && call.methodName == 'sendEmail') {
                System.assert(((List<Messaging.SingleEmailMessage>)call.args[0]).isEmpty());
            }
        }
    }

    @isTest
    static void remindClients_sendsEmailToClient_InTraining() {
        makeData();
        EmailTemplate template = new EmailTemplate(
            Id = MockProvider.createId(EmailTemplate.class)
        );
        mocks.expectedCalls.add(new MockCallData(emailSrv, 'getTemplate', template));
        mocks.expectedCalls.add(new MockCallData(emailSrv, 'sendEmail'));
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class), 
            atlas1__Client__c = MockProvider.createId(Contact.class), 
            atlas1__Status__c = 'In Training', 
            atlas1__TrainingStartDate__c = Date.today().addDays(-6)
        );
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', new List<atlas1__Team__c>{ team }));
        service.remindClients();
        // Assert
        System.assert(!mocks.actualCalls.isEmpty());
        // the first call would be to get teams
        MockCallData getTeams = mocks.actualCalls[0];
        System.assertEquals('getByStatus', getTeams.methodName);
        System.assertEquals('In Training', getTeams.args[0]);
        // the next-to-last call would be to create email
        MockCallData createEmail = mocks.actualCalls[mocks.actualCalls.size() - 2];
        Id teamId = (Id) createEmail.args[0];
        Id clientId = (Id) createEmail.args[1];
        Id templateId = (Id) createEmail.args[2];
        System.AssertEquals(team.Id, teamId);
        System.assertEquals(team.atlas1__Client__c, clientId);
        System.AssertEquals(template.Id, templateId);
        MockCallData data = mocks.actualCalls[mocks.actualCalls.size() - 1];
        List<Messaging.SingleEmailMessage> emails = (List<Messaging.SingleEmailMessage>)data.args[0];
        System.assertEquals(1, emails.size());
    }

    @isTest
    static void remindClients_sendsEmailsToClients_InTraining() {
        makeData();
        atlas1__Team__c[] teams = new atlas1__Team__c[5];
        for (Integer i = 0; i < 5; i++) {
            teams[i] = new atlas1__Team__c(
                Id = MockProvider.createId(atlas1__Team__c.class), 
                atlas1__Client__c = MockProvider.createId(Contact.class), 
                atlas1__Status__c = 'In Training', 
                atlas1__TrainingStartDate__c = Date.today().addDays(0 - i)
            );
        }
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams));
        EmailTemplate template = new EmailTemplate(
            Id = MockProvider.createId(EmailTemplate.class)
        );
        mocks.expectedCalls.add(new MockCallData(emailSrv, 'getTemplate', template));
        mocks.expectedCalls.add(new MockCallData(emailSrv, 'sendEmail'));
        mocks.expectedCalls.add(new MockCallData(emailSrv, 'createEmail'));
        service.remindClients();
        // Assert
        // the 3rd to 8th calls would be to send emails
        for (Integer i = 0; i < 5; i++) {
            atlas1__Team__c team = teams[i];
            MockCallData data = mocks.actualCalls[i + 2];
            Id teamId = (Id) data.args[0];
            Id clientId = (Id) data.args[1];
            Id templateId = (Id) data.args[2];
            System.AssertEquals(team.Id, teamId);
            System.assertEquals(team.atlas1__Client__c, clientId);
            System.AssertEquals(template.Id, templateId);
        }
        // the last call would be to send emails
        MockCallData data = mocks.actualCalls[mocks.actualCalls.size() - 1];
        List<Messaging.SingleEmailMessage> emails = (List<Messaging.SingleEmailMessage>)data.args[0];
        System.assertEquals(5, emails.size());
    }

    private static Map<Id, Id> facilitatorToTeamIds = new Map<Id, Id>();
    private static Set<Id> facilitatorIds = new Set<Id>();
    private static Set<Id> clientIds = new Set<Id>();
    private static EmailTemplate template;
    private static void setupCalls(Integer[] daysTraining) {
        makeData();
        template = new EmailTemplate(
            Id = MockProvider.createId(EmailTemplate.class)
        );
        mocks.expectedCalls.add(new MockCallData(emailSrv, 'getTemplate', template));
        mocks.expectedCalls.add(new MockCallData(emailSrv, 'sendEmail'));
        List<atlas1__Team__c> teams = new List<atlas1__Team__c>();
        for (Integer i = 0; i < daysTraining.size(); i++) {
            Integer days = daysTraining[i];
            teams.add(new atlas1__Team__c(
                Id = MockProvider.createId(atlas1__Team__c.class), 
                atlas1__Client__c = MockProvider.createId(Contact.class), 
                atlas1__Status__c = 'In Training', 
                atlas1__TrainingStartDate__c = Date.today().addDays(0 - days)
            ));
        }
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams));
        facilitatorToTeamIds = new Map<Id, Id>();
        facilitatorIds = new Set<Id>();
        clientIds = new Set<Id>();
        List<npe4__Relationship__c> relationships = new List<npe4__Relationship__c>();
        for (Integer i = 0; i < daysTraining.size(); i++) {
            Id currentId = MockProvider.createId(Contact.class);
            relationships.add(new npe4__Relationship__c(
                Id = MockProvider.createId(npe4__Relationship__c.class), 
                npe4__Contact__c = teams[i].atlas1__Client__c, 
                npe4__RelatedContact__c = currentId
            ));
            facilitatorIds.add(currentId);
            clientIds.add(teams[i].atlas1__Client__c);
            facilitatorToTeamIds.put(currentId, teams[i].Id);
        }
        mocks.expectedCalls.add(new MockCallData(relationshipRepo, 'getCurrentRelated', relationships));
    }

    @isTest
    static void remindFacilitators_sendsEmailsToFacilitators() {
        // Arrange
        setupCalls(new List<Integer>{ 7, 14 + 8, 28 + 9, 14 * 3 + 10, 11, 12, 13 });
        // Act
        service.remindFacilitators();
        // Assert
        System.assert(!mocks.actualCalls.isEmpty());
        // the first call would be to get teams
        MockCallData getTeams = mocks.actualCalls[0];
        System.assertEquals('In Training', getTeams.args[0]);
        // find the call to get facilitators
        MockCallData getFac;
        for (MockCallData mockCall : mocks.actualCalls) {
            if (mockCall.obj == relationshipRepo) {
                getFac = mockCall;
                break;
            }
        }
        System.assertNotEquals(null, getFac);
        // first parameter is client contact ids
        System.assertEquals(clientIds, getFac.args[0]);
        // second parameter is type
        System.assertEquals('Team Faciliator', getFac.args[1]);
        // the last call would be to send emails
        MockCallData data = mocks.actualCalls[mocks.actualCalls.size() - 1];
        List<Messaging.SingleEmailMessage> emails = (List<Messaging.SingleEmailMessage>)data.args[0];
        System.assertEquals(7, emails.size());
        for (MockCallData cdata : mocks.actualCalls) {
            if (cdata.methodName == 'createEmail') {
                Id teamId = (Id) cdata.args[0];
                Id whoId = (Id) cdata.args[1];
                Id templateId = (Id) cdata.args[2];
                System.assert(facilitatorIds.contains(whoId));
                System.assertEquals(facilitatorToTeamIds.get(whoId), teamId);
                System.assertEquals(template.Id, templateId);
                facilitatorIds.remove(whoId);
            }
        }
        System.assertEquals(0, facilitatorIds.size(), 'should have messaged all facilitators');
    }

    @isTest
    static void remindFacilitators_doesNotSendEmailsOnEvenWeeks() {
        // Arrange
        setupCalls(new List<Integer>{ 1, 14 + 2, 28 + 3, 14 * 3 + 4 });
        // Act
        service.remindFacilitators();
        // Assert
        System.assert(!mocks.actualCalls.isEmpty());
        // the fourth call would be to get facilitators
        MockCallData getFac;
        MockCallData sendEmail;
        for (MockCallData mockCall : mocks.actualCalls) {
            if (mockCall.obj == relationshipRepo) {
                getFac = mockCall;
            }
            if (mockCall.obj == emailSrv && mockCall.methodName == 'sendEmail') {
                sendEmail = mockCall;
            }
        }
        System.assertEquals(null, getFac);
        System.assertEquals(null, sendEmail);
    }

    @isTest
    static void remindFacilitators_sendsNoEmailWhenTrainingJustStarted() {
        // Arrange
        setupCalls(new List<Integer>{ 1 });
        // Act
        service.remindFacilitators();
        // Assert
        System.assert(!mocks.actualCalls.isEmpty());
        // the first call would be to get teams
        MockCallData getTeams = mocks.actualCalls[0];
        System.assertEquals('In Training', getTeams.args[0]);
        // the fourth call would be to get facilitators
        MockCallData getFac;
        MockCallData sendEmail;
        for (MockCallData mockCall : mocks.actualCalls) {
            if (mockCall.obj == relationshipRepo) {
                getFac = mockCall;
            }
            if (mockCall.obj == emailSrv && mockCall.methodName == 'sendEmail') {
                sendEmail = mockCall;
            }
        }
        System.assertEquals(null, getFac);
        System.assertEquals(null, sendEmail);
    }

    @isTest
    static void remindFacilitators_sendsNoEmails_whenNoFacilitators() {
        makeData();
        mocks.expectedCalls.add(new MockCallData(emailSrv, 'getTemplate', new EmailTemplate(
            Id = MockProvider.createId(EmailTemplate.class)
        )));
        mocks.expectedCalls.add(new MockCallData(emailSrv, 'sendEmail'));
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class), 
            atlas1__Client__c = MockProvider.createId(EmailTemplate.class), 
            atlas1__Status__c = 'In Training', 
            atlas1__TrainingStartDate__c = Date.today().addDays(-8)
        );
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', new List<atlas1__Team__c>{ team }));
        List<npe4__Relationship__c> relationships = new List<npe4__Relationship__c>{  };
        mocks.expectedCalls.add(new MockCallData(relationshipRepo, 'getCurrentRelated', relationships));
        service.remindFacilitators();
        // Assert
        System.assert(!mocks.actualCalls.isEmpty());
        // the last call would be to send emails
        MockCallData data = mocks.actualCalls[mocks.actualCalls.size() - 1];
        List<Messaging.SingleEmailMessage> emails = (List<Messaging.SingleEmailMessage>)data.args[0];
        System.assertEquals(0, emails.size());
    }

}