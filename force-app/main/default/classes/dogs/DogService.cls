public inherited sharing class DogService {
    private DogRepository repo = new DogRepository();
    private AccountRepository accountRepo = new AccountRepository();
    
    @testVisible
    private DogService(DogRepository repo, AccountRepository accountRepo) {
        this.repo = repo;
        this.accountRepo = accountRepo;
    }

    // update the vet relationships
    public updateVetRelationships(atlas1__Dog__c[] dogs, Map<Id, atlas1__Dog__c> oldMap) {
        List<atlas1__DogRelationship__c> change = new List<atlas1__DogRelationship__c>();

        for (atlas1__Dog__c dog : dogs) {
            atlas1__Dog__c old = oldMap[dog.Id];
            if (old == null || old.atlas1__VetClinic__c != dog.atlas1__VetClinic__c) {
                if (dog.atlas1__VetClinic__c != null) {
                // get the vet and add a relationship to the dog
                Contact[] vets = accountRepo.getContacts(dog.atlas1__VetClinic__c);
                for (Contact vet : vets) {
                    change.add(new atlas1__DogRelationship__c());
                }
            }
        }
    }
}