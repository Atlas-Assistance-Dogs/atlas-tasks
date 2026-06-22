/** TeamTrigger */
trigger TeamTrigger on atlas1__Team__c(before update ) {
    TeamTaskService service = new TeamTaskService();
    service.handleTeamChanges(Trigger.new, Trigger.oldMap);
}