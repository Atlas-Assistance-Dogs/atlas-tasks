trigger TeamTrigger on atlas1__Team__c(before update, after update ) {
    TeamTaskService service = new TeamTaskService();
    if (Trigger.isBefore) {
        // set Training start date if training is starting
        for (atlas1__Team__c team : Trigger.new ) {
            atlas1__Team__c oldTeam = Trigger.oldMap.get(team.Id);

            String oldStatus = oldTeam.atlas1__Status__c;
            if (team.atlas1__Status__C == 'In-Training' && oldStatus == 'Onboarding') {
                team.atlas1__TrainingStartDate__c = Date.today();
                TeamTaskService service = new TeamTaskService();
                service.handleTrainingStart(team);
            }
            if (team.atlas1__Status__c == 'Certified' && oldStatus == 'In-Training') {
                service.handleCertificationStart(team);
            }
        }
    }
}