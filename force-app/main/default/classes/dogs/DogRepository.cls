public inherited sharing class DogRepository {
    public atlas1__Dog__c getById(Id dogId) {
        atlas1__Dog__c[] dogs = [SELECT Id, 
                                        Name, 
                                        atlas1__SpayedNeutered__c
                                 FROM atlas1__Dog__c
                                 WHERE Id = :dogId];

        if (dogs.size() == 0) {
            return null;
        }
        return dogs[0];
    }

}