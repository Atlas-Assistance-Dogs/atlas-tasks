global class RemindDogStatus implements Schedulable {
    private TeamService service;

    // default constructor
    public RemindDogStatus() {
        service = new TeamService();
    }

    // used for test
    @TestVisible
    private RemindDogStatus(TeamService service) {
        this.service = service;
    }

    global void execute(SchedulableContext SC) {
        service.checkDogStatus();
    }
}