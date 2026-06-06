/** Repository for managing dog data. */
public inherited sharing class DogRepository {
    /**
     * Gets the dog with the specified ID.
     * @param dogId The ID of the dog.
     * @return The dog with the specified ID.
     */
    public atlas1__Dog__c getById(Id dogId) {
        atlas1__Dog__c[] dogs = [SELECT Id, 
                                        Name, 
                                        atlas1__SpayedNeutered__c
                                 FROM atlas1__Dog__c
                                 WHERE Id = :dogId
                                 WITH SECURITY_ENFORCED];

        if (dogs.size() == 0) {
            return null;
        }
        return dogs[0];
    }
}