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

    // references to mocks
    private static void makeData() {
        mocks = new MockProvider();
        teamRepo = (TeamRepository)mocks.createMock(TeamRepository.class);
        relationshipRepo = (RelationshipRepository)mocks.createMock(RelationshipRepository.class);
        dogRepo = (DogRepository)mocks.createMock(DogRepository.class);
        taskRepo = (TaskRepository)mocks.createMock(TaskRepository.class);
        service = new TeamTaskService(teamRepo, relationshipRepo, dogRepo, taskRepo);

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
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getTaskUser', admin));
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getTaskUser', clientSupportCoordinator));
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getTaskUser', clientManager));
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getTaskUser', tfManager));
        mocks.expectedCalls.add(new MockCallData(teamRepo, 'getTaskUser', trainerManager));
    }

    @isTest
    static void handleTrainingStart_returnsWhenNoAdmin() {
        makeData();
        atlas1__Team__c team = new atlas1__Team__c(
            Id = MockProvider.createId(atlas1__Team__c.class));
        service.handleCertificationStart(team);

        System.assertEquals(5, mocks.actualCalls.size());
     }

}