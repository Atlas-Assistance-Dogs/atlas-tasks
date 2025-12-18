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
        System.Assert.isFalse(mocks.actualCalls.isEmpty(), 'calls should not be empty');
        // the first call would be to get teams
        MockCallData getTeams = mocks.actualCalls[0];
        System.assertEquals('getByStatus', getTeams.methodName, 'first call should be getByStatus');
        System.assertEquals('In Training', getTeams.args[0], 'status should be In Training');
        // see if there is a call to sendEmail, if there is, there should be no
        // emails
        for (MockCallData call : mocks.actualCalls) {
            if (call.obj == emailSrv && call.methodName == 'sendEmail') {
                System.assert(((List<Messaging.SingleEmailMessage>)call.args[0]).isEmpty(), 'emails should be empty');
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
        System.Assert.isFalse(mocks.actualCalls.isEmpty(), 'should not be empty');
        // the first call would be to get teams
        MockCallData getTeams = mocks.actualCalls[0];
        System.assertEquals('getByStatus', getTeams.methodName, 'method name should be getByStatus');
        System.assertEquals('In Training', getTeams.args[0], 'first argument should be In Training');
        // the next-to-last call would be to create email
        MockCallData createEmail = mocks.actualCalls[mocks.actualCalls.size() - 2];
        Id teamId = (Id) createEmail.args[0];
        Id clientId = (Id) createEmail.args[1];
        Id templateId = (Id) createEmail.args[2];
        System.AssertEquals(team.Id, teamId, 'teamId should match');
        System.assertEquals(team.atlas1__Client__c, clientId, 'clientId should match');
        System.AssertEquals(template.Id, templateId, 'templateId should match');
        MockCallData data = mocks.actualCalls[mocks.actualCalls.size() - 1];
        List<Messaging.SingleEmailMessage> emails = (List<Messaging.SingleEmailMessage>)data.args[0];
        System.assertEquals(1, emails.size(), 'should have 1 email');
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
            System.AssertEquals(team.Id, teamId, 'teamId should match');
            System.assertEquals(team.atlas1__Client__c, clientId, 'clientId should match');
            System.AssertEquals(template.Id, templateId, 'templateId should match');
        }
        // the last call would be to send emails
        MockCallData data = mocks.actualCalls[mocks.actualCalls.size() - 1];
        List<Messaging.SingleEmailMessage> emails = (List<Messaging.SingleEmailMessage>)data.args[0];
        System.assertEquals(5, emails.size(), 'size should be 5');
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
        System.Assert.isFalse(mocks.actualCalls.isEmpty(), 'actual calls should not be empty');
        // the first call would be to get teams
        MockCallData getTeams = mocks.actualCalls[0];
        System.assertEquals('In Training', getTeams.args[0], 'first argument should be In Training');
        // find the call to get facilitators
        MockCallData getFac;
        for (MockCallData mockCall : mocks.actualCalls) {
            if (mockCall.obj == relationshipRepo) {
                getFac = mockCall;
                break;
            }
        }
        System.Assert.isNotNull(getFac, 'getFac should not be null');
        // first parameter is client contact ids
        System.assertEquals(clientIds, getFac.args[0], 'first arge should be clientIds');
        // second parameter is type
        System.assertEquals('Team Facilitator', getFac.args[1], 'second arge should be Team Facilitator');
        // the last call would be to send emails
        MockCallData data = mocks.actualCalls[mocks.actualCalls.size() - 1];
        List<Messaging.SingleEmailMessage> emails = (List<Messaging.SingleEmailMessage>)data.args[0];
        System.assertEquals(7, emails.size(), 'should have 7 emails');
        for (MockCallData cdata : mocks.actualCalls) {
            if (cdata.methodName == 'createEmail') {
                Id teamId = (Id) cdata.args[0];
                Id whoId = (Id) cdata.args[1];
                Id templateId = (Id) cdata.args[2];
                System.assert(facilitatorIds.contains(whoId), 'facilitator ids should include whoId');
                System.assertEquals(facilitatorToTeamIds.get(whoId), teamId, 'teamId should match whoId');
                System.assertEquals(template.Id, templateId, 'template should match');
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
        System.Assert.isFalse(mocks.actualCalls.isEmpty(), 'no calls should have been made');
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
        System.Assert.isNull(getFac, 'should not call getFacilitator');
        System.Assert.isNull(sendEmail, 'should not call sendEmail');
    }

    @isTest
    static void remindFacilitators_sendsNoEmailWhenTrainingJustStarted() {
        // Arrange
        setupCalls(new List<Integer>{ 1 });
        // Act
        service.remindFacilitators();
        // Assert
        System.Assert.isFalse(mocks.actualCalls.isEmpty(), 'should have at least one call');
        // the first call would be to get teams
        MockCallData getTeams = mocks.actualCalls[0];
        System.assertEquals('In Training', getTeams.args[0], 'first arg should be In Training');
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
        System.Assert.isNull(getFac, 'facilitator should be null');
        System.Assert.isNull(sendEmail, 'sendEmail should be null');
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
        System.Assert.isFalse(mocks.actualCalls.isEmpty(), 'calls should not be empty');
        // the last call would be to send emails
        MockCallData data = mocks.actualCalls[mocks.actualCalls.size() - 1];
        List<Messaging.SingleEmailMessage> emails = (List<Messaging.SingleEmailMessage>)data.args[0];
        System.assertEquals(0, emails.size(), 'no emails should be sent');
    }

    @isTest
    static void checkDogStatus_sendsNoEmails_whenNoTeams() {
        makeData();
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', new atlas1__Team__c[]{  }));
        // Act
        service.checkDogStatus();
        // Assert
        System.Assert.areEqual(1, mocks.actualCalls.size(), 'no emails should be sent');
    }

    @isTest
    static void checkDogStatus_sendsNoEmails_whenNoTemplate() {
        makeData();
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', new atlas1__Team__c[]{ new atlas1__Team__c() }));
        mocks.expectedCalls.add(new MockCallData(emailSrv, 'getTemplate', null));
        // Act
        service.checkDogStatus();
        // Assert
        System.Assert.areEqual(2, mocks.actualCalls.size(), 'no emails should be sent');
    }

    @isTest
    static void checkDogStatus_sendsEmails_whenTeamsWithDogVetDatesWithin60days() {
        makeData();
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ new atlas1__Team__c(
            atlas1__Client__c = MockProvider.createId(Contact.class), 
            atlas1__Dog__r = new atlas1__Dog__c(
                Id = MockProvider.createId(atlas1__Dog__c.class), 
                atlas1__VaccineDueRabies__c = Date.today().addDays(60), 
                atlas1__PhysicalExamDue__c = Date.today().addMonths(3)
            )
        ), new atlas1__Team__c(
            atlas1__Client__c = MockProvider.createId(Contact.class), 
            atlas1__Dog__r = new atlas1__Dog__c(
                Id = MockProvider.createId(atlas1__Dog__c.class), 
                atlas1__VaccineDueRabies__c = Date.today().addDays(365), 
                atlas1__PhysicalExamDue__c = Date.today().addDays(60)
            )
        ), new atlas1__Team__c(
            atlas1__Client__c = MockProvider.createId(Contact.class), 
            atlas1__Dog__r = new atlas1__Dog__c(
                Id = MockProvider.createId(atlas1__Dog__c.class), 
                atlas1__VaccineDueRabies__c = Date.today().addDays(35), 
                atlas1__PhysicalExamDue__c = Date.today().addDays(35)
            )
        ), new atlas1__Team__c(
            atlas1__Client__c = MockProvider.createId(Contact.class), 
            atlas1__Dog__r = new atlas1__Dog__c(
                Id = MockProvider.createId(atlas1__Dog__c.class), 
                atlas1__VaccineDueRabies__c = Date.today(), 
                atlas1__PhysicalExamDue__c = Date.today()
            )
        ) };
        atlas1__Team__c[] allTeams = new atlas1__Team__c[]{ new atlas1__Team__c(), new atlas1__Team__c(
            atlas1__Dog__r = new atlas1__Dog__c()
        ), new atlas1__Team__c(
            atlas1__Dog__r = new atlas1__Dog__c(
                atlas1__VaccineDueRabies__c = Date.today().addMonths(3), 
                atlas1__PhysicalExamDue__c = Date.today().addMonths(3)
            )
        ) };
        allTeams.addAll(teams);
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', allTeams));
        Id templateId = MockProvider.createId(EmailTemplate.class);
        mocks.expectedCalls.add(new MockCallData(emailSrv, 'getTemplate', new EmailTemplate(
            Id = templateId
        )));
        // Act
        service.checkDogStatus();
        // Assert
        MockCallData call = mocks.findCallByMethod('sendEmail');
        Messaging.SingleEmailMessage[] messages = (Messaging.SingleEmailMessage[])call.args[0];
        System.Assert.areEqual(4, messages.size(), '4 emails should be sent');

        Integer idx = 0;
        for (MockCallData c : mocks.actualCalls) {
            if (c.methodName == 'createEmail') {
                atlas1__Team__c team = teams[idx];
                System.Assert.areEqual(team.atlas1__Dog__r.Id, c.args[0]);
                System.Assert.areEqual(team.atlas1__Client__c, c.args[1]);
                System.Assert.areEqual(templateId, c.args[2]);
                idx++;
            }
        }
    }

}