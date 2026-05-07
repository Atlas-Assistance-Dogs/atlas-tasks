trigger DogTrigger on atlas1__Dog__c(after insert, after update ) {
    DogService repo = new DogService();

    repo.updateVetRelationships(Trigger.new, Trigger.oldMap);
}