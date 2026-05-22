/**
 * This class contains unit tests for validating the behavior of Apex class TeamTaskService.
 */
@isTest
private class TeamTaskServiceTest {
    private static MockProvider mocks;
    private static TeamTaskService service;
    private static TeamRepository teamRepo;
    private static RelationshipRepository relationshipRepo;
    private static DogRepository dogRepo;
    private static TaskRepository taskRepo;
    private static PatRepository patRepo;
    // Users
    private static User admin;
    private static User adminAssistant;
    private static User clientManager;
    private static User clientSupportCoordinator;
    private static User tfManager;
    private static User trainerManager;
    private static final String STATUS_IN_TRAINING = 'In Training';
    private static final String STATUS_CERTIFIED = 'Certified';
    private static final String DESC_TRAINING_START = 'Client entered training';
    // private static final String DESC_TRAINING_START = 'Confirm returns forms, assign courses, add to office hours';
    private static final String SUBJECT_1MO_CLIENT = '1 mo in-training checkin due';
    private static final String SUBJECT_1MO_TF = '1 mo in-training checkin due for TF';
    private static final String SUBJECT_4P5MO_CLIENT = 'Check on client\'s courses and give Molly status';
    private static final String SUBJECT_5MO_CLIENT = '5 mo client in-training checkin due';
    private static final String DESC_5MO_CLIENT = 'Check on practice PAT and class status';
    private static final String SUBJECT_5MO_TF = '5 mo in-training checkin due for TF';
    private static final String SUBJECT_6MO_CLIENT = 'Check on dog spay/neuter status';
    private static final String SUBJECT_8MO_CLIENT = '8 mo client in-training checkin due';
    private static final String DESC_8MO_CLIENT = 'Confirm spay, see if need extension';
    private static final String SUBJECT_8MO_TF = '8 mo in-training checkin due for TF';
    private static final String SUBJECT_CERT_START = 'begin client checkins';
    private static final String SUBJECT_CERT_FIRST_REMINDER = 'Client 1st recert due in 3 mo';
    private static final String SUBJECT_CERT_REMINDER = 'Client recert due in 3 mo';
    private static final String DESC_CERT_FIRST_REMINDER = 'Checkin and schedule PAT';
    private static final String DESC_CERT_REMINDER = 'Check vet paperwork, inform Molly';
    // references to mocks
    private static void makeData() {
        mocks = new MockProvider();
        teamRepo = (TeamRepository)mocks.createMock(TeamRepository.class);
        relationshipRepo = (RelationshipRepository)mocks.createMock(RelationshipRepository.class);
        dogRepo = (DogRepository)mocks.createMock(DogRepository.class);
        taskRepo = (TaskRepository)mocks.createMock(TaskRepository.class);
        patRepo = (PatRepository)mocks.createMock(PatRepository.class);

        // create the users
        admin = new User(
            Email = 'admin@test.com', 
            Id = MockProvider.createId(User.class)
        );
        adminAssistant = new User(
            Email = 'adminAssistant@test.com', 
            Id = MockProvider.createId(User.class)
        );
        clientSupportCoordinator = new User(
            Email = 'ClientSupportCoordinator@test.com', 
            Id = MockProvider.createId(User.class)
        );
        clientManager = new User(
            Email = 'ClientManager@test.com', 
            Id = MockProvider.createId(User.class)
        );
        tfManager = new User(
            Email = 'TFManager@test.com', 
            Id = MockProvider.createId(User.class)
        );
        trainerManager = new User(
            Email = 'TrainerManager@test.com', 
            Id = MockProvider.createId(User.class)
        );
    }

    private static void setupUserReturns() {
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getTaskUser', admin, new Object[]{ 'Administrator' }));
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getTaskUser', clientSupportCoordinator, new Object[]{ 'Client Support Coordinator' }));
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getTaskUser', clientManager, new Object[]{ 'Client Manager' }));
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getTaskUser', tfManager, new Object[]{ 'TF Manager' }));
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getTaskUser', trainerManager, new Object[]{ 'Trainer Manager' }));
        // creating the service so it gets the users
        service = new TeamTaskService(teamRepo, relationshipRepo, dogRepo, taskRepo, patRepo);
    }

    private static void assertTask(Task expected, Task t) {
        System.assertNotEquals(null, t, 'task should not be null');
        System.assertEquals(expected.WhoId, t.WhoId, 'who does not match');
        System.assertEquals(expected.WhatId, t.WhatId, 'what does not match');
        System.assertEquals(expected.OwnerId, t.OwnerId, 'owner does not match');
        System.assertEquals(expected.Subject, t.Subject, 'subject does not match');
        System.assertEquals(expected.Description, t.Description, 'description does not match');
        System.assertEquals(expected.ActivityDate, t.ActivityDate, 'date does not match');
    }

    private static atlas1__Team__c newTeamWithTraining(Integer startOffsetDays) {
        return new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class), 
            atlas1__Client__c = MockProvider.createId(Contact.class), 
            atlas1__Status__c = STATUS_IN_TRAINING, 
            atlas1__TrainingStartDate__c = Date.today().addDays(-startOffsetDays)
        );
    }

    private static atlas1__Team__c newCertifiedTeam(Integer initialCertYearsAgo, Integer patValidDaysFromToday) {
        return new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class), 
            Name = 'Fido_Buddy', 
            atlas1__Client__c = MockProvider.createId(Contact.class), 
            atlas1__Status__c = STATUS_CERTIFIED, 
            atlas1__InitialCertificationDate__c = initialCertYearsAgo != null ? Date.today().addYears(-initialCertYearsAgo).addMonths(3) : null, 
            atlas1__PatValidUntil__c = patValidDaysFromToday != null ? Date.today().addDays(patValidDaysFromToday) : null
        );
    }

    @isTest
    static void handleTrainingStart_returnsWhenNoAdmin() {
        makeData();
        service = new TeamTaskService(teamRepo, relationshipRepo, dogRepo, taskRepo, patRepo);
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class)
        );
        service.handleTrainingStart(team);

        mocks.assertMethodNotCalled('create');
    }

    @isTest
    static void handleTrainingStart_createsTaskForAdmin() {
        // Arrang
        makeData();
        setupUserReturns();
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class), 
            atlas1__Client__c = mockProvider.createId(Contact.class)
        );
        // Act
        service.handleTrainingStart(team);
        // Assert
        MockCallData createCall = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])createCall.args[0];
        System.assertEquals(4, tasks.size(), 'expected four tasks');
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = admin.Id, 
            Status = 'Not Started', 
            Subject = 'Confirm returns forms', 
            Description = DESC_TRAINING_START, 
            ActivityDate = Date.today()
        ), tasks[0]);
    }

    @isTest
    static void createTrainingTasks_returnsWhenNoTeamsInTraining() {
        makeData();
        setupUserReturns();
        atlas1__Team__c[] teams = new atlas1__Team__c[0];
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams));
        // Act
        service.createTrainingTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('getByStatus');
        System.assertEquals('In Training', data.args[0], 'status input does not match');
    }

    @isTest
    static void createTrainingTasks_handlesTrainingStart() {

        makeData();
        setupUserReturns();
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class), 
            atlas1__Client__c = MockProvider.createId(Contact.class), 
            atlas1__Status__c = STATUS_IN_TRAINING
        );
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams));
        // Act
        service.createTrainingTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('modify');
        atlas1__Team__c actual = (atlas1__Team__c)data.args[0];
        System.assertEquals(Date.today(), actual.atlas1__TrainingStartDate__c, 'date does not match');
        data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(4, tasks.size(), 'size should be 4');
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = admin.Id, 
            Status = 'Not Started', 
            Subject = 'Confirm returns forms', 
            Description = DESC_TRAINING_START, 
            ActivityDate = Date.today()
        ), tasks[0]);
    }

    @isTest
    static void createTrainingTasks_creates1monthTasksForClient() {
        makeData();
        setupUserReturns();
        atlas1__Team__c team = newTeamWithTraining(30);
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };

        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams));
        mocks.expectedCalls.add(new MockCallData(relationshipRepo, 'getCurrentRelated', new List<npe4__Relationship__c>()));
        // Act
        service.createTrainingTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('getCurrentRelated');
        Set<Id> ids = (Set<Id>)data.args[0];
        System.assertEquals(1, ids.size(), 'size should be 1');
        System.assertEquals(team.atlas1__Client__c, ids.iterator().next(), 'id does not match');
        data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(1, tasks.size(), 'size should be 1');
        Task task = tasks[0];
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = clientManager.Id, 
            Subject = SUBJECT_1MO_CLIENT, 
            ActivityDate = Date.today()
        ), task);
    }

    @isTest
    static void createTrainingTasks_creates1monthTasks() {
        makeData();
        setupUserReturns();
        atlas1__Team__c team = newTeamWithTraining(30);
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        Contact tf = new Contact(
            Id = MockProvider.createId(Contact.class)
        );

        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams));
        mocks.expectedCalls.add(new MockCallData(relationshipRepo, 'getCurrentRelated', new List<npe4__Relationship__c>{ new npe4__Relationship__c(
            Id = MockProvider.createId(npe4__Relationship__c.class), 
            npe4__Contact__c = team.atlas1__Client__c, 
            npe4__RelatedContact__c = tf.Id
        ) }));
        // Act
        service.createTrainingTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('getCurrentRelated');
        Set<Id> ids = (Set<Id>)data.args[0];
        System.assertEquals(1, ids.size(), 'size should be 1');
        System.assertEquals(team.atlas1__Client__c, ids.iterator().next(), 'id does not match');
        data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(2, tasks.size(), 'size should be 2');
        // check Team Facilitator task here, Client is checked in previous test
        Task task = tasks[1];
        assertTask(new Task(
            WhoId = tf.Id, 
            WhatId = team.Id, 
            OwnerId = tfManager.Id, 
            Subject = SUBJECT_1MO_TF, 
            ActivityDate = Date.today()
        ), task);
    }

    @isTest
    static void createTrainingTasks_creates4p5monthTasksForClient() {
        makeData();
        setupUserReturns();
        atlas1__Team__c team = newTeamWithTraining(135);
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };

        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams));
        // Act
        service.createTrainingTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');

        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(1, tasks.size(), 'size should be 1');
        Task task = tasks[0];
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = admin.Id, 
            Subject = SUBJECT_4P5MO_CLIENT, 
            ActivityDate = Date.today()
        ), task);
    }

    @isTest
    static void createTrainingTasks_creates5monthTasksForClient() {
        makeData();
        setupUserReturns();
        atlas1__Team__c team = newTeamWithTraining(150);
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };


        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams));
        mocks.expectedCalls.add(new MockCallData(relationshipRepo, 'getCurrentRelated', new List<npe4__Relationship__c>()));
        // Act
        service.createTrainingTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('getCurrentRelated');
        Set<Id> ids = (Set<Id>)data.args[0];
        System.assertEquals(1, ids.size(), 'size should be 1');
        System.assertEquals(team.atlas1__Client__c, ids.iterator().next(), 'id does not match');
        data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(1, tasks.size(), 'size should be 1');
        Task task = tasks[0];
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = clientManager.Id, 
            Subject = SUBJECT_5MO_CLIENT, 
            Description = DESC_5MO_CLIENT, 
            ActivityDate = Date.today()
        ), task);
    }

    @isTest
    static void createTrainingTasks_creates5monthTasks() {
        makeData();
        setupUserReturns();
        atlas1__Team__c team = newTeamWithTraining(150);
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        Contact tf = new Contact(
            Id = MockProvider.createId(Contact.class)
        );


        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams));
        mocks.expectedCalls.add(new MockCallData(relationshipRepo, 'getCurrentRelated', new List<npe4__Relationship__c>{ new npe4__Relationship__c(
            Id = MockProvider.createId(npe4__Relationship__c.class), 
            npe4__Contact__c = team.atlas1__Client__c, 
            npe4__RelatedContact__c = tf.Id
        ) }));
        // Act
        service.createTrainingTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('getCurrentRelated');
        Set<Id> ids = (Set<Id>)data.args[0];
        System.assertEquals(1, ids.size(), 'size should be 1');
        System.assertEquals(team.atlas1__Client__c, ids.iterator().next(), 'id does not match');
        data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(2, tasks.size(), 'size should be 2');
        // check Team Facilitator task here, Client is checked in previous test
        Task task = tasks[1];
        assertTask(new Task(
            WhoId = tf.Id, 
            WhatId = team.Id, 
            OwnerId = tfManager.Id, 
            Subject = SUBJECT_5MO_TF, 
            ActivityDate = Date.today()
        ), task);
    }

    @isTest
    static void createTrainingTasks_creates6monthTaskForClient() {
        makeData();
        setupUserReturns();
        atlas1__Team__c team = newTeamWithTraining(180);
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };

        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams));
        mocks.expectedCalls.add(new mockCallData(dogRepo, 'getById', new atlas1__Dog__c(
            Id = team.atlas1__Dog__c
        ), new Object[]{ team.atlas1__Dog__c }));
        // Act
        service.createTrainingTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(1, tasks.size(), 'size should be 1');
        Task task = tasks[0];
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = admin.Id, 
            Subject = SUBJECT_6MO_CLIENT, 
            ActivityDate = Date.today()
        ), task);
    }

    @isTest
    static void createTrainingTasks_creates6monthTaskForClient_whenSpayStatusFalse() {
        makeData();
        setupUserReturns();
        atlas1__Team__c team = newTeamWithTraining(180);
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };

        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams));
        mocks.expectedCalls.add(new mockCallData(dogRepo, 'getById', new atlas1__Dog__c(
            Id = team.atlas1__Dog__c, 
            atlas1__SpayedNeutered__c = false
        ), new Object[]{ team.atlas1__Dog__c }));
        // Act
        service.createTrainingTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(1, tasks.size(), 'size should be 1');
        Task task = tasks[0];
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = admin.Id, 
            Subject = SUBJECT_6MO_CLIENT, 
            ActivityDate = Date.today()
        ), task);
    }

    @isTest
    static void createTrainingTasks_doesNotCreate6monthTaskForClient_whenSpayStatusTrue() {
        makeData();
        setupUserReturns();
        atlas1__Team__c team = newTeamWithTraining(180);
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };

        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams));
        mocks.expectedCalls.add(new mockCallData(dogRepo, 'getById', new atlas1__Dog__c(
            Id = team.atlas1__Dog__c, 
            atlas1__SpayedNeutered__c = true
        ), new Object[]{ team.atlas1__Dog__c }));
        // Act
        service.createTrainingTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(0, tasks.size(), 'size should be 0');
    }

    @isTest
    static void createTrainingTasks_creates8monthTasksForClient() {
        makeData();
        setupUserReturns();
        atlas1__Team__c team = newTeamWithTraining(240);
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };


        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams));
        mocks.expectedCalls.add(new MockCallData(relationshipRepo, 'getCurrentRelated', new List<npe4__Relationship__c>()));
        // Act
        service.createTrainingTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('getCurrentRelated');
        Set<Id> ids = (Set<Id>)data.args[0];
        System.assertEquals(1, ids.size(), 'size should be 1');
        System.assertEquals(team.atlas1__Client__c, ids.iterator().next(), 'id does not match');
        data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(1, tasks.size(), 'size should be 1');
        Task task = tasks[0];
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = clientManager.Id, 
            Subject = SUBJECT_8MO_CLIENT, 
            Description = DESC_8MO_CLIENT, 
            ActivityDate = Date.today()
        ), task);
    }

    @isTest
    static void createTrainingTasks_creates8monthTasks() {
        makeData();
        setupUserReturns();
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class), 
            atlas1__Client__c = MockProvider.createId(Contact.class), 
            atlas1__Status__c = 'In Training', 
            atlas1__TrainingStartDate__c = Date.today().addDays(-240)
        );
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        Contact tf = new Contact(
            Id = MockProvider.createId(Contact.class)
        );


        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams));
        mocks.expectedCalls.add(new MockCallData(relationshipRepo, 'getCurrentRelated', new List<npe4__Relationship__c>{ new npe4__Relationship__c(
            Id = MockProvider.createId(npe4__Relationship__c.class), 
            npe4__Contact__c = team.atlas1__Client__c, 
            npe4__RelatedContact__c = tf.Id
        ) }));
        // Act
        service.createTrainingTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('getCurrentRelated');
        Set<Id> ids = (Set<Id>)data.args[0];
        System.assertEquals(1, ids.size(), 'size should be 1');
        System.assertEquals(team.atlas1__Client__c, ids.iterator().next(), 'id does not match');
        data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(2, tasks.size(), 'size should be 2');
        // check Team Facilitator task here, Client is checked in previous test
        Task task = tasks[1];
        assertTask(new Task(
            WhoId = tf.Id, 
            WhatId = team.Id, 
            OwnerId = tfManager.Id, 
            Subject = SUBJECT_8MO_TF, 
            ActivityDate = Date.today()
        ), task);
    }

    @isTest
    static void handleCertificationStart_throwsExceptionWhenNoPassingPat() {
        makeData();
        service = new TeamTaskService(teamRepo, relationshipRepo, dogRepo, taskRepo, patRepo);
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class), 
            Name = 'Test Team'
        );
        Boolean exc = false;
        try {
            service.handleCertificationStart(team);
        } catch (Exception e) {
            System.Assert.isTrue(e.getMessage().contains('No initial passing PAT found for team ' + team.Name), 'Exception message does not match');
            exc = true;
        }
        System.assert(exc, 'Exception was not thrown');
    }

    @isTest
    static void handleCertificationStart_setsInitialCertificationDateWhenPassingPat() {
        makeData();
        setupUserReturns();
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class)
        );
        mocks.expectedCalls.add(new MockCallData(patRepo, 'getFirstPat', new atlas1__PublicAccessTest__c(
            atlas1__DateCompleted__c = Date.today()
        ), new Object[]{ team.Id }));

        service.handleCertificationStart(team);

        System.assertEquals(Date.today(), team.atlas1__InitialCertificationDate__c, 'Initial Certification Date does not match');
    }

    @isTest
    static void handleCertificationStart_doesNotSetsInitialCertificationDateWhenAlreadySet() {
        makeData();
        setupUserReturns();
        Date initDate = Date.today().addDays(-1);
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class), 
            atlas1__InitialCertificationDate__c = initDate
        );
        mocks.expectedCalls.add(new MockCallData(patRepo, 'getFirstPat', new atlas1__PublicAccessTest__c(
            atlas1__DateCompleted__c = Date.today()
        ), new Object[]{ team.Id }));

        service.handleCertificationStart(team);

        System.assertEquals(initDate, team.atlas1__InitialCertificationDate__c, 'Initial Certification Date does not match');
    }

    @isTest
    static void handleCertificationStart_returnsWhenNoUsers() {
        makeData();
        service = new TeamTaskService(teamRepo, relationshipRepo, dogRepo, taskRepo, patRepo);
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class)
        );
        mocks.expectedCalls.add(new MockCallData(patRepo, 'getFirstPat', new atlas1__PublicAccessTest__c(
            atlas1__DateCompleted__c = Date.today()
        ), new Object[]{ team.Id }));
        service.handleCertificationStart(team);

        mocks.assertMethodNotCalled('create');
    }

    @isTest
    static void handleCertificationStart_createsTasksForCoordinator() {
        makeData();
        setupUserReturns();
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class), 
            atlas1__Client__c = mockProvider.createId(Contact.class)
        );
        mocks.expectedCalls.add(new MockCallData(patRepo, 'getFirstPat', new atlas1__PublicAccessTest__c(
            atlas1__DateCompleted__c = Date.today()
        ), new Object[]{ team.Id }));
        // Act
        service.handleCertificationStart(team);
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(4, tasks.size(), 'size should be 4');
        Task task = tasks[0];
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = clientSupportCoordinator.Id, 
            Subject = 'Begin client checkins', 
            Description = 'Schedule checkins every 3 months, inform Molly', 
            ActivityDate = Date.today().addMonths(1)
        ), task);
    }

    private static final String STARTED_TRAINING = 'Client entered training';
    private static final String NEWLY_CERTIFIED = 'Team newly certified';
    @isTest
    static void handleCertificationStart_createsTasksForAdmin() {
        makeData();
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class), 
            atlas1__Client__c = mockProvider.createId(Contact.class)
        );
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getTaskUser', admin, new Object[]{ 'Administrator' }));
        mocks.expectedCalls.add(new MockCallData(patRepo, 'getFirstPat', new atlas1__PublicAccessTest__c(
            atlas1__DateCompleted__c = Date.today()
        ), new Object[]{ team.Id }));
        service = new TeamTaskService(teamRepo, relationshipRepo, dogRepo, taskRepo, patRepo);
        // Act
        service.handleCertificationStart(team);
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(3, tasks.size(), 'size should be 3');
        Task task = tasks[0];
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = admin.Id, 
            Subject = 'Assign fitness course', 
            Description = NEWLY_CERTIFIED, 
            ActivityDate = Date.today()
        ), tasks[0]);
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = admin.Id, 
            Subject = 'Mark assigned program complete', 
            Description = NEWLY_CERTIFIED, 
            ActivityDate = Date.today()
        ), tasks[1]);
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = admin.Id, 
            Subject = 'Save grade report', 
            Description = NEWLY_CERTIFIED, 
            ActivityDate = Date.today()
        ), tasks[2]);
    }

    @isTest
    static void handleCertificationStart_createsTasksForAdminAssistant() {
        makeData();
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class), 
            atlas1__Client__c = mockProvider.createId(Contact.class)
        );
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getTaskUser', adminAssistant, new Object[]{ 'Admin Assistant' }));
        mocks.expectedCalls.add(new MockCallData(patRepo, 'getFirstPat', new atlas1__PublicAccessTest__c(
            atlas1__DateCompleted__c = Date.today()
        ), new Object[]{ team.Id }));
        service = new TeamTaskService(teamRepo, relationshipRepo, dogRepo, taskRepo, patRepo);
        // Act
        service.handleCertificationStart(team);
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(1, tasks.size(), 'size should be 1');
        Task task = tasks[0];
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = adminAssistant.Id, 
            Subject = 'Cleanup google drive', 
            Description = NEWLY_CERTIFIED, 
            ActivityDate = Date.today()
        ), tasks[0]);
    }

    @isTest
    static void createCertificationTasks_createsFirstReminderTask_whenNoMatching() {
        makeData();
        setupUserReturns();
        atlas1__Team__c team = newCertifiedTeam(0, 90);
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        Contact tf = new Contact(
            Id = MockProvider.createId(Contact.class)
        );

        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams, new Object[]{ 'Certified' }));
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getMatchingTasks', new Task[0]));
        // Act
        service.createCertificationTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('getMatchingTasks');
        System.assertEquals(team.atlas1__Client__c, data.args[0], 'wrong first arg');
        System.assertEquals('%recert due in 3 mo%', data.args[1], 'wrong second arg');
        data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(1, tasks.size(), 'size should be 1');
        Task task = tasks[0];
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = clientManager.Id, 
            Subject = SUBJECT_CERT_FIRST_REMINDER, 
            Description = DESC_CERT_FIRST_REMINDER, 
            ActivityDate = Date.today()
        ), task);
    }

    @isTest
    static void createCertificationTasks_doesNotCreateFirstReminder_whenMatchingExists() {
        // Arrange
        makeData();
        setupUserReturns();
        Date today = Date.today();
        atlas1__Team__c team = newCertifiedTeam(1, 90);
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams, new Object[]{ STATUS_CERTIFIED }));
        Task existing = new Task(
            Id = MockProvider.createId(Task.class), 
            WhoId = team.atlas1__Client__c, 
            Subject = SUBJECT_CERT_FIRST_REMINDER
        );
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getMatchingTasks', new Task[]{ existing }));
        // Act
        service.createCertificationTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assert(tasks.isEmpty(), 'Should not create when matching task exists');
    }

    @isTest
    static void createCertificationTasks_createsReminderTask_whenNoMatching() {
        makeData();
        setupUserReturns();
        atlas1__Team__c team = newCertifiedTeam(4, 90);
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        Contact tf = new Contact(
            Id = MockProvider.createId(Contact.class)
        );

        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams, new Object[]{ 'Certified' }));
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getMatchingTasks', new Task[0]));
        // Act
        service.createCertificationTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('getMatchingTasks');
        System.assertEquals(team.atlas1__Client__c, data.args[0], 'wrong first arg');
        System.assertEquals('%recert due in 3 mo%', data.args[1], 'wrong second arg');
        data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(1, tasks.size(), 'size should be 1');
        Task task = tasks[0];
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = admin.Id, 
            Subject = SUBJECT_CERT_REMINDER, 
            Description = DESC_CERT_REMINDER, 
            ActivityDate = Date.today()
        ), task);
    }

    @isTest
    static void createCertificationTasks_doesNotCreateReminder_whenMatchingExists() {
        // Arrange
        makeData();
        setupUserReturns();
        Date today = Date.today();
        atlas1__Team__c team = newCertifiedTeam(4, 90);
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getByStatus', teams, new Object[]{ STATUS_CERTIFIED }));
        Task existing = new Task(
            Id = MockProvider.createId(Task.class), 
            WhoId = team.atlas1__Client__c, 
            Subject = SUBJECT_CERT_REMINDER
        );
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getMatchingTasks', new Task[]{ existing }));
        // Act
        service.createCertificationTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assert(tasks.isEmpty(), 'Should not create when matching task exists');
    }

    @isTest
    static void createDogTasks_doesNotCreateTasks_whenAdminNotDefined() {
        // Arrange
        makeData();
        atlas1__Team__c team = newCertifiedTeam(5, 0);
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', teams));
        // creating the service so it gets the users
        service = new TeamTaskService(teamRepo, relationshipRepo, dogRepo, taskRepo, patRepo);
        // Act
        service.createDogTasks();
        // Assert
        mocks.assertMethodNotCalled('create');
    }

    @isTest
    static void createDogTasks_doesNotCreateTasks_whenNoTeam() {
        // Arrange
        makeData();
        setupUserReturns();
        atlas1__Team__c[] teams = new atlas1__Team__c[]{  };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', teams));
        // Act
        service.createDogTasks();
        // Assert
        mocks.assertMethodNotCalled('create');
    }

    @isTest
    static void createDogTasks_doesNotCreateTasks_whenNoDogInTeam() {
        // Arrange
        makeData();
        setupUserReturns();

        atlas1__Team__c[] teams = new atlas1__Team__c[]{ newCertifiedTeam(1, 0) };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', teams));
        // Act
        service.createDogTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(0, tasks.size(), 'Should not create task when no dog in team');
    }

    @isTest
    static void createDogTasks_doesNotCreateTasks_whenDogNoVaxDates() {
        // Arrange
        makeData();
        setupUserReturns();

        atlas1__Team__c team = newCertifiedTeam(1, 0);
        team.atlas1__Dog__r = new atlas1__Dog__c(
            Id = MockProvider.createId(atlas1__Dog__c.class), 
            Name = 'Fido'
        );
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', teams));
        // Act
        service.createDogTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(0, tasks.size(), 'Should not create task when dog has no vaccine dates');
    }

    @isTest
    static void createDogTasks_doesNotCreateTasks_whenRabiesExpiresTomorrow() {
        // Arrange
        makeData();
        setupUserReturns();

        atlas1__Team__c team = newCertifiedTeam(1, 0);
        team.atlas1__Dog__r = new atlas1__Dog__c(
            Id = MockProvider.createId(atlas1__Dog__c.class), 
            Name = 'Fido', 
            atlas1__VaccineDueRabies__c = Date.today().addDays(1)
        );
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', teams));
        // Act
        service.createDogTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(0, tasks.size(), 'Should not create task when rabies due tomorrow');
    }

    @isTest
    static void createDogTasks_doesNotCreateTasks_whenExamExpiresTomorrow() {
        // Arrange
        makeData();
        setupUserReturns();

        atlas1__Team__c team = newCertifiedTeam(1, 0);
        team.atlas1__Dog__r = new atlas1__Dog__c(
            Id = MockProvider.createId(atlas1__Dog__c.class), 
            Name = 'Fido', 
            atlas1__PhysicalExamDue__c = Date.today().addDays(1)
        );
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', teams));
        // Act
        service.createDogTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(0, tasks.size(), 'Should not create task when dog exam due tomorrow');
    }

    @isTest
    static void createDogTasks_doesNotCreateTasks_whenDA2PPExpiresTomorrow() {
        // Arrange
        makeData();
        setupUserReturns();

        atlas1__Team__c team = newCertifiedTeam(1, 0);
        team.atlas1__Dog__r = new atlas1__Dog__c(
            Id = MockProvider.createId(atlas1__Dog__c.class), 
            Name = 'Fido', 
            atlas1__VaccineDueDA2PP__c = Date.today().addDays(1)
        );
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', teams));
        // Act
        service.createDogTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(0, tasks.size(), 'Should not create task when dog DA2PP due tomorrow');
    }

    @isTest
    static void createDogTasks_doesNotCreateTasks_whenRabiesExpiredYesterday() {
        // Arrange
        makeData();
        setupUserReturns();

        atlas1__Team__c team = newCertifiedTeam(1, 0);
        team.atlas1__Dog__r = new atlas1__Dog__c(
            Id = MockProvider.createId(atlas1__Dog__c.class), 
            Name = 'Fido', 
            atlas1__VaccineDueRabies__c = Date.today().addDays(-1)
        );
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', teams));
        // Act
        service.createDogTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(0, tasks.size(), 'Should not create task when rabies due yesterday');
    }

    @isTest
    static void createDogTasks_doesNotCreateTasks_whenExamExpiredYesterday() {
        // Arrange
        makeData();
        setupUserReturns();

        atlas1__Team__c team = newCertifiedTeam(1, 0);
        team.atlas1__Dog__r = new atlas1__Dog__c(
            Id = MockProvider.createId(atlas1__Dog__c.class), 
            Name = 'Fido', 
            atlas1__PhysicalExamDue__c = Date.today().addDays(-1)
        );
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', teams));
        // Act
        service.createDogTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(0, tasks.size(), 'Should not create task when dog exam due yesterday');
    }

    @isTest
    static void createDogTasks_doesNotCreateTasks_whenDA2PPExpiredYesterday() {
        // Arrange
        makeData();
        setupUserReturns();

        atlas1__Team__c team = newCertifiedTeam(1, 0);
        team.atlas1__Dog__r = new atlas1__Dog__c(
            Id = MockProvider.createId(atlas1__Dog__c.class), 
            Name = 'Fido', 
            atlas1__VaccineDueDA2PP__c = Date.today().addDays(-1)
        );
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', teams));
        // Act
        service.createDogTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(0, tasks.size(), 'Should not create task when dog DA2PP due yesterday');
    }

    @isTest
    static void createDogTasks_doesNotCreateTasks_whenRabiesExpiresToday_andTaskPresent() {
        // Arrange
        makeData();
        setupUserReturns();

        atlas1__Team__c team = newCertifiedTeam(1, 0);
        team.atlas1__Dog__r = new atlas1__Dog__c(
            Id = MockProvider.createId(atlas1__Dog__c.class), 
            Name = 'Fido', 
            atlas1__VaccineDueRabies__c = Date.today()
        );
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', teams));
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getMatchingTasks', new Task[]{ new Task() }, new List<Object>{ team.atlas1__Client__c, '%veterinary health records%' }));
        // Act
        service.createDogTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(0, tasks.size(), 'Should not create task when rabies due today and task exists');
    }

    @isTest
    static void createDogTasks_doesNotCreateTasks_whenExamExpiresToday_andTaskPresent() {
        // Arrange
        makeData();
        setupUserReturns();

        atlas1__Team__c team = newCertifiedTeam(1, 0);
        team.atlas1__Dog__r = new atlas1__Dog__c(
            Id = MockProvider.createId(atlas1__Dog__c.class), 
            Name = 'Fido', 
            atlas1__PhysicalExamDue__c = Date.today()
        );
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', teams));
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getMatchingTasks', new Task[]{ new Task() }, new List<Object>{ team.atlas1__Client__c, '%veterinary health records%' }));
        // Act
        service.createDogTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(0, tasks.size(), 'Should not create task when dog exam due today and task exists');
    }

    @isTest
    static void createDogTasks_doesNotCreateTasks_whenDA2PPExpiresToday_andTaskPresent() {
        // Arrange
        makeData();
        setupUserReturns();

        atlas1__Team__c team = newCertifiedTeam(1, 0);
        team.atlas1__Dog__r = new atlas1__Dog__c(
            Id = MockProvider.createId(atlas1__Dog__c.class), 
            Name = 'Fido', 
            atlas1__VaccineDueDA2PP__c = Date.today()
        );
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', teams));
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getMatchingTasks', new Task[]{ new Task() }, new List<Object>{ team.atlas1__Client__c, '%veterinary health records%' }));
        // Act
        service.createDogTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(0, tasks.size(), 'Should not create task when dog DA2PP due today and task exists');
    }

    @isTest
    static void createDogTasks_creatsTasks_whenRabiesExpiresToday_andNoTaskPresent() {
        // Arrange
        makeData();
        setupUserReturns();

        atlas1__Team__c team = newCertifiedTeam(1, 0);
        team.atlas1__Dog__r = new atlas1__Dog__c(
            Id = MockProvider.createId(atlas1__Dog__c.class), 
            Name = 'Fido', 
            atlas1__VaccineDueRabies__c = Date.today()
        );
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', teams));
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getMatchingTasks', new Task[]{  }, new List<Object>{ team.atlas1__Client__c, '%veterinary health records%' }));
        // Act
        service.createDogTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(1, tasks.size(), 'Should not create task when rabies due today and task exists');
    }

    @isTest
    static void createDogTasks_createTasks_whenExamExpiresToday_andNoTaskPresent() {
        // Arrange
        makeData();
        setupUserReturns();

        atlas1__Team__c team = newCertifiedTeam(1, 0);
        team.atlas1__Dog__r = new atlas1__Dog__c(
            Id = MockProvider.createId(atlas1__Dog__c.class), 
            Name = 'Fido', 
            atlas1__PhysicalExamDue__c = Date.today()
        );
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', teams));
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getMatchingTasks', new Task[]{  }, new List<Object>{ team.atlas1__Client__c, '%veterinary health records%' }));
        // Act
        service.createDogTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(1, tasks.size(), 'Should not create task when dog exam due today and task exists');
    }

    @isTest
    static void createDogTasks_createTasks_whenDA2PPExpiresToday_andNoTaskPresent() {
        // Arrange
        makeData();
        setupUserReturns();

        atlas1__Team__c team = newCertifiedTeam(1, 0);
        team.atlas1__Dog__r = new atlas1__Dog__c(
            Id = MockProvider.createId(atlas1__Dog__c.class), 
            Name = 'Fido', 
            atlas1__VaccineDueDA2PP__c = Date.today()
        );
        atlas1__Team__c[] teams = new atlas1__Team__c[]{ team };
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getActiveDogs', teams));
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getMatchingTasks', new Task[]{  }, new List<Object>{ team.atlas1__Client__c, '%veterinary health records%' }));
        // Act
        service.createDogTasks();
        // Assert
        MockCallData data = mocks.assertMethodCalled('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(1, tasks.size(), 'Should not create task when dog DA2PP due today and task exists');
    }

}