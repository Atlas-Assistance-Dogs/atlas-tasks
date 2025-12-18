/**
 * This class contains unit tests for validating the behavior of Apex class TeamRepository.
 */
@isTest
private class TeamRepositoryTest {
  private static Contact joe;
  private static atlas1__Dog__c boomer;
  private static atlas1__Team__c team;
  private static TeamRepository repo = new TeamRepository();
  // setup objects and create a team
  private static void setup() {
    joe = new Contact(
      FirstName = 'Joe', 
      LastName = 'Blow', 
      atlas1__ClientStatus__c = 'Onboarding', 
      atlas1__ClientCertificationValidUntil__c = Date.today().addMonths(3)
    );
    insert joe;
    boomer = new atlas1__Dog__c(
      Name = 'Boomer', 
      atlas1__Status__c = 'Onboarding'
    );
    insert boomer;
    team = new atlas1__Team__c(
      Name = 'Joe_Boomer', 
      atlas1__Client__c = joe.Id, 
      atlas1__Dog__c = boomer.Id
    );
    insert team;
  }

  @isTest
  static void getByStatus_returnsEmptyList_whenNoTeams() {
    List<atlas1__Team__c> result = repo.getByStatus('Certified');

    System.assertEquals(new List<atlas1__Team__c>(), result);
  }

  @isTest
  static void getByStatus_returnsEmptyList_whenStatusDoesntMatch() {
    atlas1__Team__c team = TestTeam.create();

    List<atlas1__Team__c> result = repo.getByStatus('Onboarding');

    System.assertEquals(new List<atlas1__Team__c>(), result);
  }

  @isTest
  static void getByStatus_returnsEmptyList_whenNoStatusMatches() {
    atlas1__Team__c team1 = TestTeam.create();
    atlas1__Team__c team2 = TestTeam.create();
    team2.atlas1__Status__c = 'In ADSiM';
    update team2;

    List<atlas1__Team__c> result = repo.getByStatus('Onboarding');

    System.assertEquals(new List<atlas1__Team__c>(), result);
  }

  @isTest
  static void getByStatus_returnsOnlyMatch_whenOtherNotMatch() {
    atlas1__Team__c team1 = TestTeam.create();
    atlas1__Team__c team2 = TestTeam.create();
    team2.atlas1__Status__c = 'Onboarding';
    update team2;

    List<atlas1__Team__c> result = repo.getByStatus('Certified');
    atlas1__Team__c team = result[0];

    System.assertEquals(1, result.size(), 'size should be 1');
    System.assertEquals(team1.Id, team.Id, 'should match');
    System.assertEquals(team1.atlas1__Client__c, team.atlas1__Client__c, 'should match');
    System.assertEquals(team1.atlas1__TrainingStartDate__c, team.atlas1__TrainingStartDate__c, 'should match');
  }

  @isTest
  static void getByStatus_returnsAllMatches_whenOtherStatuses() {
    atlas1__Team__c team1 = TestTeam.create();
    atlas1__Team__c team2 = TestTeam.create();
    atlas1__Team__c team3 = TestTeam.create();
    team2.atlas1__Status__c = 'Onboarding';
    update team2;

    List<atlas1__Team__c> result = repo.getByStatus('Certified');
    Set<Id> teamIds = new Set<Id>();
    for (atlas1__Team__c team : result) {
      teamIds.add(team.Id);
    }

    System.assertEquals(new Set<Id>{ team1.Id, team3.Id }, teamIds, 'teamIds should match');
  }

  @isTest
  static void modify_throwsError_whenNull() {
    // Act
    try {
      repo.modify(null);
      System.Assert.isTrue(false, 'should have thrown an error');
    } catch (Exception e) {
      // Assert
      System.Assert.isTrue(e != null);
    }
  }

  @isTest
  static void modify_updatesTeam() {
    // Arrange
    setup();

    team.Name = 'New Name';

    // Act
    repo.modify(team);
    // Assert

    atlas1__Team__c actual = [SELECT Name
                              FROM atlas1__Team__c
                              WHERE Id = :team.Id];
    System.Assert.areEqual('New Name', actual.Name, 'name does not match');
  }

  @isTest
  static void getActiveDogs_returnsEmpty_whenNoTeams() {
    // Act
    atlas1__Team__c[] teams = repo.getActiveDogs();
    // Assert
    System.Assert.isTrue(teams.isEmpty(), 'teams should be empty');
  }

  @isTest
  static void getActiveDogs_returnsEmpty_whenNoActiveTeams() {
    // Arrange
    atlas1__Team__c team1 = TestTeam.create();
    atlas1__Team__c team2 = TestTeam.create();
    team1.atlas1__Status__c = 'Onboarding';
    team2.atlas1__Status__c = 'Initial Inquiry';
    update new atlas1__Team__c[]{ team1, team2 };
    // Act
    atlas1__Team__c[] teams = repo.getActiveDogs();
    // Assert
    System.Assert.isTrue(teams.isEmpty(), 'teams should be empty');
  }

  @isTest
  static void getActiveDogs_returnsTeamAndDogInfo_whenCertified() {
    atlas1__Team__c expected = TestTeam.create();
    // Act
    atlas1__Team__c[] teams = repo.getActiveDogs();
    // Assert
    System.Assert.areEqual(1, teams.size(), 'teams should have one element');
    atlas1__Team__c team = teams[0];
    atlas1__Dog__c dog = team.atlas1__Dog__r;
    System.Assert.areEqual(expected.Id, team.Id, 'teams should match');
    System.Assert.areEqual(expected.atlas1__Dog__c, dog.Id, 'dogs should match');
    System.Assert.areEqual(expected.atlas1__Client__c, team.atlas1__Client__c, 'client should match');
    System.Assert.areEqual(null, dog.atlas1__VaccineDueRabies__c, 'should be null');
    System.Assert.areEqual(null, dog.atlas1__PhysicalExamDue__c, 'should be null');
  }

  @isTest
  static void getActiveDogs_returnsTeamAndDogInfo_whenInTraining() {
    atlas1__Team__c expected = TestTeam.create();
    expected.atlas1__Status__c = 'In Training';
    update expected;
    // Act
    atlas1__Team__c[] teams = repo.getActiveDogs();
    // Assert
    System.Assert.areEqual(1, teams.size(), 'teams should have one element');
    atlas1__Team__c team = teams[0];
    atlas1__Dog__c dog = team.atlas1__Dog__r;
    System.Assert.areEqual(expected.Id, team.Id, 'teams should match');
    System.Assert.areEqual(expected.atlas1__Dog__c, dog.Id, 'dogs should match');
    System.Assert.areEqual(expected.atlas1__Client__c, team.atlas1__Client__c, 'client should match');
    System.Assert.areEqual(null, dog.atlas1__VaccineDueRabies__c, 'should be null');
    System.Assert.areEqual(null, dog.atlas1__PhysicalExamDue__c, 'should be null');
  }

  @isTest
  static void getActiveDogs_returnsTeamAndDogInfo_withDates() {
    atlas1__Team__c expected = TestTeam.create();
    atlas1__Dog__c ace = [SELECT Id, atlas1__VaccineDueRabies__c, atlas1__PhysicalExamDue__c FROM atlas1__Dog__c WHERE Id = :expected.atlas1__Dog__c];
    ace.atlas1__PhysicalExamDue__c = Date.today().addMonths(-1);
    ace.atlas1__VaccineDueRabies__c = Date.today().addMonths(-2);
    update ace;
    // Act
    atlas1__Team__c[] teams = repo.getActiveDogs();
    // Assert
    System.Assert.areEqual(1, teams.size(), 'teams should have one element');
    atlas1__Team__c team = teams[0];
    atlas1__Dog__c dog = team.atlas1__Dog__r;
    System.Assert.areEqual(expected.Id, team.Id, 'teams should match');
    System.Assert.areEqual(expected.atlas1__Dog__c, dog.Id, 'dogs should match');
    System.Assert.areEqual(expected.atlas1__Client__c, team.atlas1__Client__c, 'client should match');
    System.Assert.areEqual(ace.atlas1__VaccineDueRabies__c, dog.atlas1__VaccineDueRabies__c, 'vaccine due should match');
    System.Assert.areEqual(ace.atlas1__PhysicalExamDue__c, dog.atlas1__PhysicalExamDue__c, 'physical exam due should match');
  }

}