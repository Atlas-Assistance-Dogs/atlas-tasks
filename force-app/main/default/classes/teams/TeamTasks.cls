/* this creates tasks and reminder emails for teams.  It is expected to be run daily */
global class TeamTasks implements Schedulable {
  private TeamTaskService service;
  // default constructor
  public TeamTasks() {
    service = new TeamTaskService();
  }

  // used for test
  @TestVisible
  private TeamTasks(TeamTaskService service) {
    this.service = service;
  }

  global void execute(SchedulableContext SC) {
    service.createTrainingTasks();
    service.createCertificationTasks();
    service.createDogTasks();
  }
}