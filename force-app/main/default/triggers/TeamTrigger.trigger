trigger TeamTrigger on atlas1__Team__c(before update, after update ) {
    if (Trigger.isBefore) {
        // set Training start date if training is starting
        for (atlas1__Team__c team : Trigger.new ) {
            atlas1__Team__c oldTeam = Trigger.oldMap.get(team.Id);

            String oldStatus = oldTeam.atlas1__Status__c;
            if (team.atlas1__Status__C == 'In-Training' && oldStatus == 'Onboarding') {
                team.atlas1__TrainingStartDate__c = Date.today();
                TeamTaskService service = new TeamTaskService();
                service.handleTrainingStart(Trigger.new );
            }
        }
    }
}