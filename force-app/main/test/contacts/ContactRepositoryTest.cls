@isTest
private class ContactRepositoryTest {
  @isTest
  static void getContactsNeedingBackgroundChecks_returnsEmpty_whenNoContacts() {
    ContactRepository repo = new ContactRepository();
    Contact[] result = repo.getContactsNeedingBackgroundChecks();
    System.assert(result.isEmpty());
  }

  @isTest
  static void getContactsNeedingBackgroundChecks_returnsEmpty_whenNoContactsWithVolunteerAccess() {
    Contact bluey = new Contact(
      FirstName = 'Bluey', 
      LastName = 'Heeler', 
      Email = 'bluey@test.com'
    );
    insert bluey;
    ContactRepository repo = new ContactRepository();
    Contact[] result = repo.getContactsNeedingBackgroundChecks();
    System.assert(result.isEmpty());
  }

  @isTest
  static void getContactsNeedingBackgroundChecks_returnsEmpty_whenNoContactsWithCheckRequired() {
    Contact bluey = new Contact(
      FirstName = 'Bluey', 
      LastName = 'Heeler', 
      Email = 'bluey@test.com', 
      BackgroundCheck__c = 'Not Required'
    );
    insert bluey;
    ContactRepository repo = new ContactRepository();
    Contact[] result = repo.getContactsNeedingBackgroundChecks();
    System.assert(result.isEmpty());
  }

  @isTest
  static void getContactsNeedingBackgroundChecks_returnsEmpty_whenContactsNotActive() {
    Contact[] contacts = new Contact[]{ new Contact(
      FirstName = 'Bluey', 
      LastName = 'Heeler', 
      Email = 'bluey@test.com', 
      BackgroundCheck__c = 'Background Check'
    ), new Contact(
      FirstName = 'Bingo', 
      LastName = 'Heeler', 
      Email = 'bingo@test.com', 
      BackgroundCheck__c = 'Credit Check'
    ), new Contact(
      FirstName = 'Bluey', 
      LastName = 'Heeler', 
      Email = 'bluey@test.com', 
      BackgroundCheck__c = 'Combined Background Check'
    ) };
    insert contacts;
    ContactRepository repo = new ContactRepository();
    Contact[] result = repo.getContactsNeedingBackgroundChecks();
    System.assert(result.isEmpty());
  }

  @isTest
  static void getContactsNeedingBackgroundChecks_returnsContact_whenContactNeedsCriminal() {
    Contact bluey = new Contact(
      FirstName = 'Bluey', 
      LastName = 'Heeler', 
      Email = 'bluey@test.com', 
      GW_Volunteers__Volunteer_Status__c = 'Active', 
      BackgroundCheck__c = 'Background Check'
    );
    insert bluey;
    ContactRepository repo = new ContactRepository();
    Contact[] result = repo.getContactsNeedingBackgroundChecks();
    Contact puppy = result[0];
    System.assertEquals(bluey.Id, puppy.Id);
    System.assertEquals(bluey.BackgroundCheck__c, puppy.BackgroundCheck__c);
  }

  @isTest
  static void getContactsNeedingBackgroundChecks_returnsContact_whenContactNeedsCredit() {
    Contact bluey = new Contact(
      FirstName = 'Bluey', 
      LastName = 'Heeler', 
      Email = 'bluey@test.com', 
      atlas1__BoardMemberStatus__c = 'Active', 
      BackgroundCheck__c = 'Credit Check'
    );
    insert bluey;
    ContactRepository repo = new ContactRepository();
    Contact[] result = repo.getContactsNeedingBackgroundChecks();
    Contact puppy = result[0];
    System.assertEquals(bluey.Id, puppy.Id);
    System.assertEquals(bluey.BackgroundCheck__c, puppy.BackgroundCheck__c);
  }

  @isTest
  static void getContactsNeedingBackgroundChecks_returnsContact_whenContactNeedsBoth() {
    Contact bluey = new Contact(
      FirstName = 'Bluey', 
      LastName = 'Heeler', 
      Email = 'bluey@test.com', 
      atlas1__FacilitatorStatus__c = 'Certified-Active', 
      BackgroundCheck__c = 'Combined Background Check'
    );
    insert bluey;
    ContactRepository repo = new ContactRepository();
    Contact[] result = repo.getContactsNeedingBackgroundChecks();
    Contact puppy = result[0];
    System.assertEquals(bluey.Id, puppy.Id);
    System.assert(bluey.BackgroundCheck__c.contains('Combined Background Check'));
  }

  @isTest
  static void getActiveFacilitators_returnsEmptyList_whenNoContacts() {
    ContactRepository repo = new ContactRepository();
    Set<Id> facilitators = repo.getActiveFacilitators();

    System.assertEquals(new Set<Id>(), facilitators);
  }

  @isTest
  static void getActiveFacilitators_returnsEmptyList_whenNoFacilitators() {
    Contact client = new Contact(
      FirstName = 'Billy', 
      LastName = 'Kid', 
      atlas1__Positions__c = 'Client'
    );
    insert client;

    ContactRepository repo = new ContactRepository();
    Set<Id> facilitators = repo.getActiveFacilitators();

    System.assertEquals(new Set<Id>(), facilitators);
  }

  @isTest
  static void getActiveFacilitators_returnsEmptyList_whenFacilitatorNotActive() {
    Contact[] facs = new List<Contact>{ new Contact(
      FirstName = 'Jack', 
      LastName = 'ONeil', 
      atlas1__Positions__c = 'Team Facilitator', 
      atlas1__FacilitatorStatus__c = 'Inactive'
    ), new Contact(
      FirstName = 'Sam', 
      LastName = 'Carter', 
      atlas1__Positions__c = 'Team Facilitator', 
      atlas1__FacilitatorStatus__c = 'Initial Inquiry'
    ), new Contact(
      FirstName = 'Daniel', 
      LastName = 'Jackson', 
      atlas1__Positions__c = 'Team Facilitator', 
      atlas1__FacilitatorStatus__c = 'In Training'
    ), new Contact(
      FirstName = 'Tealc', 
      LastName = 'Na', 
      atlas1__Positions__c = 'Team Facilitator', 
      atlas1__FacilitatorStatus__c = 'None'
    ), new Contact(
      FirstName = 'Cameron', 
      LastName = 'Mitchell', 
      atlas1__Positions__c = 'Team Facilitator', 
      atlas1__FacilitatorStatus__c = 'Onboarding'
    ), new Contact(
      FirstName = 'Janet', 
      LastName = 'Carter', 
      atlas1__Positions__c = 'Team Facilitator', 
      atlas1__FacilitatorStatus__c = 'Suspended'
    ), new Contact(
      FirstName = 'Vala', 
      LastName = 'Maldoran', 
      atlas1__Positions__c = 'Team Facilitator', 
      atlas1__FacilitatorStatus__c = 'Discontinued'
    ) };
    insert facs;

    ContactRepository repo = new ContactRepository();
    Set<Id> facilitators = repo.getActiveFacilitators();

    System.assertEquals(new Set<Id>(), facilitators);
  }

  @isTest
  static void getActiveFacilitators_returnsOnlyActive_whenOtherNotActive() {
    Contact[] facs = new List<Contact>{ new Contact(
      FirstName = 'Jack', 
      LastName = 'ONeil', 
      atlas1__Positions__c = 'Team Facilitator', 
      atlas1__FacilitatorStatus__c = 'Inactive'
    ), new Contact(
      FirstName = 'Sam', 
      LastName = 'Carter', 
      atlas1__Positions__c = 'Team Facilitator', 
      atlas1__FacilitatorStatus__c = 'Initial Inquiry'
    ), new Contact(
      FirstName = 'Daniel', 
      LastName = 'Jackson', 
      atlas1__Positions__c = 'Team Facilitator', 
      atlas1__FacilitatorStatus__c = 'In Training'
    ), new Contact(
      FirstName = 'Tealc', 
      LastName = 'Na', 
      atlas1__Positions__c = 'Team Facilitator', 
      atlas1__FacilitatorStatus__c = 'Certified-Active'
    ), new Contact(
      FirstName = 'Cameron', 
      LastName = 'Mitchell', 
      atlas1__Positions__c = 'Team Facilitator', 
      atlas1__FacilitatorStatus__c = 'Onboarding'
    ), new Contact(
      FirstName = 'Janet', 
      LastName = 'Carter', 
      atlas1__Positions__c = 'Team Facilitator', 
      atlas1__FacilitatorStatus__c = 'Suspended'
    ), new Contact(
      FirstName = 'Vala', 
      LastName = 'Maldoran', 
      atlas1__Positions__c = 'Team Facilitator', 
      atlas1__FacilitatorStatus__c = 'Discontinued'
    ) };
    insert facs;

    ContactRepository repo = new ContactRepository();
    Set<Id> facilitators = repo.getActiveFacilitators();

    System.assertEquals(new Set<Id>{ facs[3].id }, facilitators);
  }

  @isTest
  static void getActiveFacilitators_returnsAllActive_whenOtherPositions() {
    Contact[] facs = new List<Contact>{ new Contact(
      FirstName = 'Jack', 
      LastName = 'ONeil', 
      atlas1__Positions__c = 'Team Facilitator;Volunteer', 
      atlas1__FacilitatorStatus__c = 'Inactive'
    ), new Contact(
      FirstName = 'Sam', 
      LastName = 'Carter', 
      atlas1__Positions__c = 'Team Facilitator;Client', 
      atlas1__FacilitatorStatus__c = 'Initial Inquiry'
    ), new Contact(
      FirstName = 'Daniel', 
      LastName = 'Jackson', 
      atlas1__Positions__c = 'Team Facilitator;Board Member', 
      atlas1__FacilitatorStatus__c = 'In Training'
    ), new Contact(
      FirstName = 'Tealc', 
      LastName = 'Na', 
      atlas1__Positions__c = 'Team Facilitator;Trainer', 
      atlas1__FacilitatorStatus__c = 'Certified-Active'
    ), new Contact(
      FirstName = 'Cameron', 
      LastName = 'Mitchell', 
      atlas1__Positions__c = 'Team Facilitator;Team Facilitator Lead', 
      atlas1__FacilitatorStatus__c = 'Onboarding'
    ), new Contact(
      FirstName = 'Janet', 
      LastName = 'Carter', 
      atlas1__Positions__c = 'Team Facilitator;Client;Board Member;Volunteer', 
      atlas1__FacilitatorStatus__c = 'Certified-Active'
    ), new Contact(
      FirstName = 'Vala', 
      LastName = 'Maldoran', 
      atlas1__Positions__c = 'Client', 
      atlas1__FacilitatorStatus__c = 'Discontinued'
    ) };
    insert facs;

    ContactRepository repo = new ContactRepository();
    Set<Id> facilitators = repo.getActiveFacilitators();

    System.assertEquals(new Set<Id>{ facs[3].id, facs[5].id }, facilitators);
  }

  @isTest
  public static void getPositionStatusForContact_returnsAllStatuses() {
    Contact vala = new Contact(
      FirstName = 'Vala', 
      LastName = 'Maldoran', 
      atlas1__Positions__c = 'Team Facilitator;Client;Board Member;Volunteer;Trainer;Staff', 
      atlas1__BoardMemberStatus__c = 'Initial Inquiry', 
      atlas1__ClientCertificationValidUntil__c = Date.today().addMonths(3), 
      atlas1__ClientStatus__c = 'In ADSiM', 
      atlas1__FacilitatorCertAgreementReceived__c = Date.today().addMonths(-3), 
      atlas1__FacilitatorStatus__c = 'Discontinued', 
      GW_Volunteers__Volunteer_Status__c = 'Active', 
      atlas1__LeadFacilitatorStatus__c = 'Active', 
      atlas1__PuppyCertAgreementReceived__c = Date.today().addYears(-1), 
      atlas1__PuppyRaiserStatus__c = 'Onboarding', 
      atlas1__StaffStatus__c = 'Employee', 
      atlas1__StandaloneStatus__c = 'In Training', 
      atlas1__TrainerCertAgreementReceived__c = Date.today().addMonths(-1), 
      atlas1__TrainerStatus__c = 'Certified-Active'
    );
    insert vala;

    ContactRepository repo = new ContactRepository();
    Contact actual = repo.getPositionStatusForContact(vala.Id);

    // Assert
    System.assertEquals(vala.Id, actual.Id);
    System.assertEquals(new Set<String>(vala.atlas1__Positions__c.split(';')), new Set<String>(actual.atlas1__Positions__c.split(';')));
    System.assertEquals(vala.atlas1__BoardMemberStatus__c, actual.atlas1__BoardMemberStatus__c);
    System.assertEquals(vala.atlas1__ClientCertificationValidUntil__c, actual.atlas1__ClientCertificationValidUntil__c);
    System.assertEquals(vala.atlas1__ClientStatus__c, actual.atlas1__ClientStatus__c);
    System.assertEquals(vala.atlas1__FacilitatorCertAgreementReceived__c, actual.atlas1__FacilitatorCertAgreementReceived__c);
    System.assertEquals(vala.atlas1__FacilitatorStatus__c, actual.atlas1__FacilitatorStatus__c);
    System.assertEquals(vala.GW_Volunteers__Volunteer_Status__c, actual.GW_Volunteers__Volunteer_Status__c);
    System.assertEquals(vala.atlas1__LeadFacilitatorStatus__c, actual.atlas1__LeadFacilitatorStatus__c);
    System.assertEquals(vala.atlas1__PuppyCertAgreementReceived__c, actual.atlas1__PuppyCertAgreementReceived__c);
    System.assertEquals(vala.atlas1__PuppyRaiserStatus__c, actual.atlas1__PuppyRaiserStatus__c);
    System.assertEquals(vala.atlas1__StaffStatus__c, actual.atlas1__StaffStatus__c);
    System.assertEquals(vala.atlas1__StaffStatus__c, actual.atlas1__StaffStatus__c);
    System.assertEquals(vala.atlas1__TrainerCertAgreementReceived__c, actual.atlas1__TrainerCertAgreementReceived__c);
    System.assertEquals(vala.atlas1__TrainerStatus__c, actual.atlas1__TrainerStatus__c);
  }

  @isTest
  public static void getClientStatus_returnsStatus() {
    Contact vala = new Contact(
      FirstName = 'Vala', 
      LastName = 'Maldoran', 
      atlas1__Positions__c = 'Team Facilitator;Client;Board Member;Volunteer;Trainer;Staff', 
      atlas1__ClientStatus__c = 'Initial Inquiry', 
      atlas1__ClientCertificationValidUntil__c = Date.today().addMonths(3), 
      atlas1__ClientDog__c = 'Cookie', 
      atlas1__FacilitatorCertAgreementReceived__c = Date.today().addMonths(-3), 
      atlas1__FacilitatorStatus__c = 'Discontinued', 
      GW_Volunteers__Volunteer_Status__c = 'Active', 
      atlas1__ClientFacilitatorAvailability__c = 'Available', 
      atlas1__ClientInitialCertificationDate__c = Date.today().addYears(-1)
    );
    insert vala;

    ContactRepository repo = new ContactRepository();
    Contact actual = repo.getClientStatus(vala.Id);

    System.assertEquals(vala.atlas1__ClientStatus__c, actual.atlas1__ClientStatus__c, 'wrong client status');
    System.assertEquals(vala.atlas1__ClientDog__c, actual.atlas1__ClientDog__c, 'wrong client status');
    System.assertEquals(vala.atlas1__ClientCertificationValidUntil__c, actual.atlas1__ClientCertificationValidUntil__c, 'wrong cert valid until');
    System.assertEquals(vala.atlas1__ClientFacilitatorAvailability__c, actual.atlas1__ClientFacilitatorAvailability__c, 'wrong facilitator availability');
    System.assertEquals(vala.atlas1__ClientInitialCertificationDate__c, actual.atlas1__ClientInitialCertificationDate__c, 'wrong cert date');
  }

  @isTest
  public static void getClientStatus_returnsNull_whenNotFound() {
    ContactRepository repo = new ContactRepository();
    Contact actual = repo.getClientStatus(MockProvider.createId(Contact.class));
    System.assertEquals(null, actual, 'should be nul');
  }

  @isTest
  static void modify_throwsError_whenNull() {
    ContactRepository repo = new ContactRepository();
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
  static void modify_updates() {
    ContactRepository repo = new ContactRepository();
    // Arrange
    Contact missy = new Contact(
      FirstName = 'Missy', 
      LastName = 'Maldoran'
    );
    insert missy;

    missy.FirstName = 'Val';

    // Act
    repo.modify(missy);
    // Assert

    Contact actual = [SELECT FirstName
                      FROM Contact
                      WHERE Id = :missy.Id];
    System.Assert.areEqual('Val', actual.FirstName, 'name does not match');
  }

}