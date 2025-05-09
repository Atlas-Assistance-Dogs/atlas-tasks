/**
 * This class contains utilities for testing objects that include Teams.
 */
@isTest
public class TestTeam {
  public static atlas1__Team__c create() {
    Contact debbie = new Contact(FirstName = 'Debbie', LastName = 'Queen');
    Contact ken = new Contact(FirstName = 'Ken', LastName = 'King');
    Contact wanda = new Contact(FirstName = 'Wanda', LastName = 'Around');
    List<Contact> contacts = new List<Contact>{ debbie, ken, wanda };
    insert contacts;

    atlas1__Dog__c ace = new atlas1__Dog__c(Name = 'Ace');
    insert ace;

    atlas1__Team__c team = new atlas1__Team__c(
      atlas1__Client__c = ken.Id,
      atlas1__Dog__c = ace.Id,
      atlas1__Handler__c = debbie.Id,
      atlas1__Facilitator__c = wanda.Id,
      Name = 'Camelot',
      atlas1__PatValidUntil__c = Date.today().addMonths(12),
      atlas1__PatCount__c = 21,
      atlas1__PrimaryCertification__c = 'Allergen Alert',
      atlas1__SecondaryCertification__c = 'Autism',
      atlas1__Status__c = 'Certified',
      atlas1__TrainingStartDate__c = Date.today()
    );
    insert team;
    return [
      SELECT
        id,
        atlas1__Client__c,
        atlas1__Dog__c,
        atlas1__Dog__r.Name,
        atlas1__Handler__c,
        atlas1__Handler__r.FirstName,
        atlas1__Handler__r.LastName,
        atlas1__Facilitator__c,
        atlas1__Facilitator__r.FirstName,
        atlas1__Facilitator__r.LastName,
        Name,
        atlas1__PatCount__c,
        atlas1__PatValidUntil__c,
        atlas1__PrimaryCertification__c,
        atlas1__SecondaryCertification__c,
        atlas1__Status__c,
        atlas1__TrainingStartDate__c
      FROM atlas1__Team__c
      WHERE id = :team.Id
    ];
  }
}
