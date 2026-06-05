/** Repository for managing contact data. */
public inherited sharing class ContactRepository {

  /**
   * Gets the position status for the specified contact ID.
   * @param contactId The ID of the contact.
   * @return The contact with the position status.
   */
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
      WITH SECURITY_ENFORCED
    ];
  }

  /**
   * Gets the active facilitators.
   * @return The set of active facilitator IDs.
   */
  public Set<Id> getActiveFacilitators() {
    List<Contact> active = [
      SELECT Id
      FROM Contact
      WHERE
        atlas1__Positions__c INCLUDES ('Team Facilitator')
        AND atlas1__FacilitatorStatus__c = 'Certified-Active'
      WITH SECURITY_ENFORCED
    ];

    Set<Id> facilitators = new Set<Id>();
    for (Contact facilitator : active) {
      facilitators.add(facilitator.Id);
    }
    return facilitators;
  }

  /**
   * Gets the client status for the specified contact ID.
   * @param contactId The ID of the contact.
   * @return The contact with the client status.
   */
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
      WITH SECURITY_ENFORCED
    ];
    if (!clients.isEmpty()) {
      return clients[0];
    }
    return null;
  }

  /**
   * Modifies the specified contact.
   * @param cntct The contact to modify.
   * @return The modified contact.
   */
  public Contact modify(Contact cntct) {
    upsert cntct;
    return cntct;
  }

  /**
   * Gets the contacts that need background checks.
   * @return The list of contacts that need background checks.
   */
  public Contact[] getContactsNeedingBackgroundChecks() {
    String[] active = new String[]{'Onboarding', 'In Training', 'Active', 'Certified-Active', 'Certified'};
    String[] inactive = new String[]{'Inactive', 'None'};
    // Check for any contacts that need background checks
    return [
      SELECT Id, Name, BackgroundCheck__c
      FROM Contact
      WHERE
        BackgroundCheck__c != 'Not Required' AND BackgroundCheck__c != null
        AND (
          (atlas1__Positions__c INCLUDES ('Board Member') AND atlas1__BoardMemberStatus__c IN :active) OR
          (atlas1__Positions__c INCLUDES ('Team Facilitator') AND atlas1__FacilitatorStatus__c IN :active) OR
          (atlas1__Positions__c INCLUDES ('Lead Facilitator') AND atlas1__LeadFacilitatorStatus__c IN :active) OR
          (atlas1__Positions__c INCLUDES ('Volunteer') AND GW_Volunteers__Volunteer_Status__c IN :active) OR
          (atlas1__Positions__c INCLUDES ('Trainer') AND atlas1__TrainerStatus__c IN :active) OR
          (atlas1__Positions__c INCLUDES ('Client') AND atlas1__ClientStatus__c IN :active) OR
          (atlas1__Positions__c INCLUDES ('Staff') AND atlas1__StaffStatus__c NOT IN :inactive)
        )
        WITH SECURITY_ENFORCED
    ];
  }
}
