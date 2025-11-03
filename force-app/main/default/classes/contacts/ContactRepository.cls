public inherited sharing class ContactRepository {

  public Contact getPositionStatusForContact(Id contactId) {
    return [
      SELECT
        atlas1__Positions__c,
        atlas1__BoardMemberStatus__c,
        atlas1__ClientCertificationValidUntil__c,
        atlas1__ClientStatus__c,
        atlas1__FacilitatorCertAgreementReceived__c,
        atlas1__FacilitatorStatus__c,
        atlas1__LeadFacilitatorStatus__c,
        atlas1__PuppyRaiserStatus__c,
        atlas1__PuppyCertAgreementReceived__c,
        atlas1__StaffStatus__c,
        atlas1__StandaloneStatus__c,
        atlas1__TrainerCertAgreementReceived__c,
        atlas1__TrainerStatus__c,
        GW_Volunteers__Volunteer_Status__c
      FROM Contact
      WHERE Id = :contactId
    ];
  }

  public Set<Id> getActiveFacilitators() {
    List<Contact> active = [
      SELECT Id
      FROM Contact
      WHERE
        atlas1__Positions__c INCLUDES ('Team Facilitator')
        AND atlas1__FacilitatorStatus__c = 'Certified-Active'
    ];

    Set<Id> facilitators = new Set<Id>();
    for (Contact facilitator : active) {
      facilitators.add(facilitator.Id);
    }
    return facilitators;
  }

  public Contact getClientStatus(Id contactId) {
    List<Contact> clients = [
      SELECT
        atlas1__ClientStatus__c,
        atlas1__ClientDog__c,
        atlas1__ClientCertificationValidUntil__c,
        atlas1__ClientFacilitatorAvailability__c,
        atlas1__ClientInitialCertificationDate__c
      FROM Contact
      WHERE Id = :contactId
    ];
    if (!clients.isEmpty()) {
      return clients[0];
    }
    return null;
  }

  public Contact modify(Contact cntct) {
    upsert cntct;
    return cntct;
  }

  public Contact[] getContactsNeedingBackgroundChecks() {
    String[] active = new String[]{'Onboarding', 'Active', 'Certified-Active'};
    // Check for any contacts that need background checks
    return [
      SELECT Id, Name, atlas1__VolunteerAccess__c
      FROM Contact
      WHERE
        atlas1__VolunteerAccess__c INCLUDES (
          'Credit Check Required',
          'Background Check Required'
        ) AND (
          atlas1__BoardMemberStatus__c IN :active OR atlas1__FacilitatorStatus__c IN :active OR atlas1__LeadFacilitatorStatus__c IN :active OR GW_Volunteers__Volunteer_Status__c IN :active OR
          atlas1__TrainerStatus__c IN :active OR atlas1__ClientStatus__c IN :active OR atlas1__StaffStatus__c IN :active
        )
    ];
  }
}
