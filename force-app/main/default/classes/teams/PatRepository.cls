public inherited sharing class PatRepository {
    public  atlas1__PublicAccessTest__c getFirstPat(Id teamId) {
        atlas1__PublicAccessTest__c[] pats = [SELECT Id, atlas1__DateCompleted__c
                                              FROM atlas1__PublicAccessTest__c
                                              WHERE atlas1__Team__c = :teamId AND atlas1__Status__c = 'Passed' AND atlas1__Type__c = 'Initial'];
        if (pats.size() > 0) {
            return pats[0];
        } else {
            return null;
        }
    }
}