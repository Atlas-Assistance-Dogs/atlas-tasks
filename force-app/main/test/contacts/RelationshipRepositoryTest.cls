@isTest
public with sharing class RelationshipRepositoryTest {
  static RelationshipRepository repo = new RelationshipRepository();

  @isTest
  static void getCurrentRelated_returnsRelationship_whenRelationshipTypeMatches() {
    Contact ace = new Contact(FirstName = 'Ace', LastName = 'GSD');
    Contact cookie = new Contact(
      FirstName = 'Cookie',
      LastName = 'Monster',
      Email = 'cookie@test.com',
      Phone = '800-555-1234'
    );
    insert new List<Contact>{ ace, cookie };

    npe4__Relationship__c relate = new npe4__Relationship__c(
      npe4__Contact__c = ace.Id,
      npe4__Type__c = 'Spouse',
      npe4__Status__c = 'Current',
      npe4__RelatedContact__c = cookie.Id
    );
    insert relate;

    List<npe4__Relationship__c> result = repo.getCurrentRelated(
      new Set<Id>{ace.Id},
      'Spouse'
    );
    System.assertEquals(1, result.size(), 'should have one record');
    npe4__Relationship__c actual = result[0];
    System.assertEquals(
      relate.npe4__RelatedContact__c,
      actual.npe4__RelatedContact__c,
      'wrong related contact'
    );
  }

}
