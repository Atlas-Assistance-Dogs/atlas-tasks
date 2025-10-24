public with sharing class TeamRepository {
    public List<atlas1__Team__c> getByStatus(String status) {
        return [SELECT Id, 
                       atlas1__Client__c, 
                       atlas1__TrainingStartDate__c
                FROM atlas1__Team__c
                WHERE atlas1__Status__c = :status];
    }

    public atlas1__Team__c modify(atlas1__Team__c team) {
        update team;
        return team;
    }

}