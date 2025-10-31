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

    System.assertEquals(1, result.size());
    System.assertEquals(team1.Id, team.Id);
    System.assertEquals(team1.atlas1__Client__c, team.atlas1__Client__c);
    System.assertEquals(team1.atlas1__TrainingStartDate__c, team.atlas1__TrainingStartDate__c);
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

    System.assertEquals(new Set<Id>{ team1.Id, team3.Id }, teamIds);
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

}