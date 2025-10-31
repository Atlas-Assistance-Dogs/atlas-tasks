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
    // Users
    private static User admin;
    private static User clientManager;
    private static User clientSupportCoordinator;
    private static User tfManager;
    private static User trainerManager;
    private static final String STATUS_IN_TRAINING = 'In Training';
    private static final String STATUS_CERTIFIED = 'Certified';
    private static final String SUBJECT_TRAINING_START = 'Client entered training';
    private static final String DESC_TRAINING_START = 'Confirm returns forms, assign courses, add to office hours';
    private static final String SUBJECT_1MO_CLIENT = '1 mo in-training checkin due';
    private static final String SUBJECT_1MO_TF = '1 mo in-training checkin due for TF';
    private static final String SUBJECT_4P5MO_CLIENT = 'Check on client\'s courses and give Molly status';
    private static final String SUBJECT_5MO_CLIENT = '5 mo client in-training checkin due';
    private static final String SUBJECT_5MO_TF = '5 mo in-training checkin due for TF';
    private static final String SUBJECT_6MO_CLIENT = 'Check on dog spay/neuter status';
    private static final String SUBJECT_8MO_CLIENT = '8 mo client in-training checkin due';
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

        // create the users
        admin = new User(
            Email = 'admin@test.com', 
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
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getTaskUser', clientSupportCoordinator, new Object[]{ 'ClientSupportCoordinator' }));
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getTaskUser', clientManager, new Object[]{ 'ClientManager' }));
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getTaskUser', tfManager, new Object[]{ 'TFManager' }));
        mocks.expectedCalls.add(new MockCallData(taskRepo, 'getTaskUser', trainerManager, new Object[]{ 'TrainerManager' }));
        // creating the service so it gets the users
        service = new TeamTaskService(teamRepo, relationshipRepo, dogRepo, taskRepo);
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
            atlas1__Client__c = MockProvider.createId(Contact.class), 
            atlas1__Status__c = STATUS_CERTIFIED, 
            atlas1__InitialCertificationDate__c = initialCertYearsAgo != null ? Date.today().addYears(-initialCertYearsAgo).addMonths(3) : null, 
            atlas1__PatValidUntil__c = patValidDaysFromToday != null ? Date.today().addDays(patValidDaysFromToday) : null
        );
    }

    @isTest
    static void handleTrainingStart_returnsWhenNoAdmin() {
        makeData();
        service = new TeamTaskService(teamRepo, relationshipRepo, dogRepo, taskRepo);
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class)
        );
        service.handleTrainingStart(team);

        System.assertEquals(5, mocks.actualCalls.size());
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
        MockCallData createCall = mocks.findCallByMethod('create');
        Task[] tasks = (Task[])createCall.args[0];
        System.assertEquals(1, tasks.size(), 'expected one task');
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = admin.Id, 
            Subject = SUBJECT_TRAINING_START, 
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
        System.assertEquals(6, mocks.actualCalls.size(), 'size does not match');
        MockCallData data = mocks.actualCalls[5];
        System.assertEquals('getByStatus', data.methodName, 'method name does not match');
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
        MockCallData data = mocks.findCallByMethod('modify');
        atlas1__Team__c actual = (atlas1__Team__c)data.args[0];
        System.assertEquals(Date.today(), actual.atlas1__TrainingStartDate__c, 'date does not match');
        data = mocks.findCallByMethod('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(1, tasks.size(), 'size should be 1');
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = admin.Id, 
            Subject = SUBJECT_TRAINING_START, 
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
        System.assertEquals(8, mocks.actualCalls.size(), 'size does not match');
        MockCallData data = mocks.findCallByMethod('getCurrentRelated');
        Set<Id> ids = (Set<Id>)data.args[0];
        System.assertEquals(1, ids.size(), 'size should be 1');
        System.assertEquals(team.atlas1__Client__c, ids.iterator().next(), 'id does not match');
        data = mocks.findCallByMethod('create');
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
        System.assertEquals(8, mocks.actualCalls.size(), 'size does not match');
        MockCallData data = mocks.findCallByMethod('getCurrentRelated');
        Set<Id> ids = (Set<Id>)data.args[0];
        System.assertEquals(1, ids.size(), 'size should be 1');
        System.assertEquals(team.atlas1__Client__c, ids.iterator().next(), 'id does not match');
        data = mocks.findCallByMethod('create');
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
        System.assertEquals(7, mocks.actualCalls.size(), 'size does not match');
        MockCallData data = mocks.findCallByMethod('create');

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
        System.assertEquals(8, mocks.actualCalls.size(), 'size does not match');
        MockCallData data = mocks.findCallByMethod('getCurrentRelated');
        Set<Id> ids = (Set<Id>)data.args[0];
        System.assertEquals(1, ids.size(), 'size should be 1');
        System.assertEquals(team.atlas1__Client__c, ids.iterator().next(), 'id does not match');
        data = mocks.findCallByMethod('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(1, tasks.size(), 'size should be 1');
        Task task = tasks[0];
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = clientManager.Id, 
            Subject = SUBJECT_5MO_CLIENT, 
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
        System.assertEquals(8, mocks.actualCalls.size(), 'size does not match');
        MockCallData data = mocks.findCallByMethod('getCurrentRelated');
        Set<Id> ids = (Set<Id>)data.args[0];
        System.assertEquals(1, ids.size(), 'size should be 1');
        System.assertEquals(team.atlas1__Client__c, ids.iterator().next(), 'id does not match');
        data = mocks.findCallByMethod('create');
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
        System.assertEquals(8, mocks.actualCalls.size(), 'size does not match');
        MockCallData data = mocks.findCallByMethod('create');
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
        System.assertEquals(8, mocks.actualCalls.size(), 'size does not match');
        MockCallData data = mocks.findCallByMethod('create');
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
        System.assertEquals(8, mocks.actualCalls.size(), 'size does not match');
        MockCallData data = mocks.findCallByMethod('create');
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
        System.assertEquals(8, mocks.actualCalls.size(), 'size does not match');
        MockCallData data = mocks.findCallByMethod('getCurrentRelated');
        Set<Id> ids = (Set<Id>)data.args[0];
        System.assertEquals(1, ids.size(), 'size should be 1');
        System.assertEquals(team.atlas1__Client__c, ids.iterator().next(), 'id does not match');
        data = mocks.findCallByMethod('create');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(1, tasks.size(), 'size should be 1');
        Task task = tasks[0];
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = clientManager.Id, 
            Subject = SUBJECT_8MO_CLIENT, 
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
        System.assertEquals(8, mocks.actualCalls.size(), 'size does not match');
        MockCallData data = mocks.actualCalls[6];
        System.assertEquals('getCurrentRelated', data.methodName, 'method name does not match');
        Set<Id> ids = (Set<Id>)data.args[0];
        System.assertEquals(1, ids.size(), 'size should be 1');
        System.assertEquals(team.atlas1__Client__c, ids.iterator().next(), 'id does not match');
        data = mocks.actualCalls[7];
        System.assertEquals('create', data.methodName, 'method name does not match');
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
    static void handleCertificationStart_returnsWhenNoCoordinator() {
        makeData();
        service = new TeamTaskService(teamRepo, relationshipRepo, dogRepo, taskRepo);
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class)
        );
        service.handleCertificationStart(team);

        System.assertEquals(5, mocks.actualCalls.size());
    }

    @isTest
    static void handleCertificationStart_createsTaskForCoordinator() {
        makeData();
        setupUserReturns();
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class), 
            atlas1__Client__c = mockProvider.createId(Contact.class)
        );
        // Act
        service.handleCertificationStart(team);
        // Assert
        System.assertEquals(6, mocks.actualCalls.size(), 'size does not match');
        MockCallData data = mocks.actualCalls[5];
        System.assertEquals('create', data.methodName, 'method name does not match');
        Task[] tasks = (Task[])data.args[0];
        System.assertEquals(1, tasks.size(), 'size should be 1');
        Task task = tasks[0];
        assertTask(new Task(
            WhoId = team.atlas1__Client__c, 
            WhatId = team.Id, 
            OwnerId = clientSupportCoordinator.Id, 
            Subject = SUBJECT_CERT_START, 
            ActivityDate = Date.today().addMonths(1)
        ), task);
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
        System.assertEquals(8, mocks.actualCalls.size(), 'size does not match');
        MockCallData data = mocks.findCallByMethod('getMatchingTasks');
        System.assertEquals(team.atlas1__Client__c, data.args[0], 'wrong first arg');
        System.assertEquals('%recert due in 3 mo%', data.args[1], 'wrong second arg');
        data = mocks.findCallByMethod('create');
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
        MockCallData data = mocks.findCallByMethod('create');
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
        System.assertEquals(8, mocks.actualCalls.size(), 'size does not match');
        MockCallData data = mocks.findCallByMethod('getMatchingTasks');
        System.assertEquals(team.atlas1__Client__c, data.args[0], 'wrong first arg');
        System.assertEquals('%recert due in 3 mo%', data.args[1], 'wrong second arg');
        data = mocks.findCallByMethod('create');
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
        MockCallData data = mocks.findCallByMethod('create');
        Task[] tasks = (Task[])data.args[0];
        System.assert(tasks.isEmpty(), 'Should not create when matching task exists');
    }

}