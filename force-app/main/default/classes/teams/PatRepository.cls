/** Repository for managing PAT data. */
public inherited sharing class PatRepository {
    /**
     * Gets the first passed initial PAT for the specified team.
     * @param teamId The ID of the team.
     * @return The first passed initial PAT for the specified team.
     */
    public  atlas1__PublicAccessTest__c getFirstPat(Id teamId) {
        atlas1__PublicAccessTest__c[] pats = [SELECT Id, atlas1__DateCompleted__c
                                              FROM atlas1__PublicAccessTest__c
                                              WHERE atlas1__Team__c = :teamId AND atlas1__Status__c = 'Passed' AND atlas1__Type__c = 'Initial'
                                              WITH SECURITY_ENFORCED];
        if (pats.size() > 0) {
            return pats[0];
        } else {
            return null;
        }
    }
}