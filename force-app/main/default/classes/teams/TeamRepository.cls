/** Repository for managing team data. */
public inherited sharing class TeamRepository {
    /**
     * Gets the teams with the specified status.
     * @param status The status to filter by.
     * @return The list of teams with the specified status.
     */
    public List<atlas1__Team__c> getByStatus(String status) {
        return [SELECT Id, 
                       atlas1__Client__c, 
                       atlas1__Dog__c, 
                       atlas1__InitialCertificationDate__c, 
                       atlas1__PatValidUntil__c, 
                       atlas1__TrainingStartDate__c
                FROM atlas1__Team__c
                WHERE atlas1__Status__c = :status
                WITH SECURITY_ENFORCED];
    }

    /**
     * Modifies the specified team.
     * @param team The team to modify.
     * @return The modified team.
     */
    public atlas1__Team__c modify(atlas1__Team__c team) {
        update as user team;
        return team;
    }

    /** Gets the active dogs in teams (dogs in teams with status 'In Training' or 'Certified').
     * @return The list of active dogs in teams.
     */
    public List<atlas1__Team__c> getActiveDogs() {
        String[] active = new String[]{ 'In Training', 'Certified' };
        return [SELECT Id, Name,
                       atlas1__Client__c, 
                       atlas1__Dog__c, 
                       atlas1__Dog__r.atlas1__VaccineDueRabies__c,
                       atlas1__Dog__r.atlas1__PhysicalExamDue__c,
                       atlas1__Dog__r.atlas1__VaccineDueDA2PP__c,
                       atlas1__Dog__r.Name
                FROM atlas1__Team__c
                WHERE atlas1__Status__c IN :active
                WITH SECURITY_ENFORCED];
    }

}