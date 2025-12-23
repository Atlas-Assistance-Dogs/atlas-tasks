public inherited sharing class TeamRepository {
    public List<atlas1__Team__c> getByStatus(String status) {
        return [SELECT Id, 
                       atlas1__Client__c, 
                       atlas1__Dog__c, 
                       atlas1__InitialCertificationDate__c, 
                       atlas1__PatValidUntil__c, 
                       atlas1__TrainingStartDate__c
                FROM atlas1__Team__c
                WHERE atlas1__Status__c = :status];
    }

    public atlas1__Team__c modify(atlas1__Team__c team) {
        update team;
        return team;
    }

    public List<atlas1__Team__c> getActiveDogs() {
        String[] active = new String[]{ 'In Training', 'Certified' };
        return [SELECT Id, 
                       atlas1__Client__c, 
                       atlas1__Dog__c, 
                       atlas1__Dog__r.atlas1__VaccineDueRabies__c,
                       atlas1__Dog__r.atlas1__PhysicalExamDue__c
                FROM atlas1__Team__c
                WHERE atlas1__Status__c IN :active];
    }

}