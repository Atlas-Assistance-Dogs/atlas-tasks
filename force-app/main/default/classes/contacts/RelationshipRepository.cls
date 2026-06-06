/**
 * Repository for managing relationship data.
 */
public inherited sharing class RelationshipRepository {
    /**
     * Gets the current related relationships for the specified contact IDs and type.
     * @param contactIds The IDs of the contacts.
     * @param type The type of relationship.
     * @return The list of current related relationships.
     */
    public List<npe4__Relationship__c> getCurrentRelated(Set<Id> contactIds, String type) {
        return [SELECT Id, 
                       npe4__Contact__c, 
                       npe4__RelatedContact__c
                FROM npe4__Relationship__c
                WHERE npe4__Contact__c IN:contactIds AND npe4__Status__c = 'Current' AND npe4__Type__c = :type
                WITH SECURITY_ENFORCED];
    }

    /**
     * Gets the current related relationships for the specified contact ID and type.
     * @param contactId The ID of the contact.
     * @param type The type of relationship.
     * @return The list of current related relationships.
     */
    public List<npe4__Relationship__c> getCurrentRelated(Id contactId, String type) {
        return [SELECT Id, 
                       npe4__Contact__c, 
                       npe4__RelatedContact__c
                FROM npe4__Relationship__c
                WHERE npe4__Contact__c = :contactId AND npe4__Status__c = 'Current' AND npe4__Type__c = :type
                WITH SECURITY_ENFORCED];
    }

}