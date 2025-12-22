public inherited sharing class TeamService {
  TeamRepository teamRepo;
  EmailService emailServ;
  RelationshipRepository relRepo;

  public TeamService() {
    teamRepo = new TeamRepository();
    emailServ = new EmailService();
    relRepo = new RelationshipRepository();
   }

  @testVisible
  private TeamService(TeamRepository teamRepo, EmailService emailServ, RelationshipRepository relRepo) {
    this.teamRepo = teamRepo;
    this.emailServ = emailServ;
    this.relRepo = relRepo;
  }

  // Remind the client in a Team to submit training logs
  public void remindClients() {
    List<atlas1__Team__c> teams = teamRepo.getByStatus('In Training');
    if (teams.isEmpty()) {
      return;
    }
    // Loop through the teams and remind the clients that haven't logged this week
    EmailTemplate template = emailServ.getTemplate('ClientLogReminder');

    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    for (atlas1__Team__c team : teams) {
      emails.add(emailServ.createEmail(team.Id, team.atlas1__Client__c, template.Id));
    }
    emailServ.sendEmail(emails);
  }

  // Remind the client facilitators to submit training logs
  public void remindFacilitators() {
    List<atlas1__Team__c> teams = teamRepo.getByStatus('In Training');
    if (teams.isEmpty()) {
      return;
    }
    // Get the email template
    EmailTemplate template = emailServ.getTemplate('FacilitatorLogReminder');

    Date today = Date.today();
    Map<Id, Id> teamContactIds = new Map<Id, Id>();
    for (atlas1__Team__c team : teams) {
      Integer weeks = 1; // default #weeks to 1.  If no TrainingStartDate, remind team facilitator weekly
      if (team.atlas1__TrainingStartDate__c != null) {
        weeks = team.atlas1__TrainingStartDate__c.daysBetween(today) / 7;
      }
      if (Math.mod(weeks, 2) == 1) {
        // remind the facilitators
        teamContactIds.put(team.atlas1__Client__c, team.Id);
      }
    }
    if (teamContactIds.isEmpty()) {
      return;
    }
    List<npe4__Relationship__c> relationships = relRepo.getCurrentRelated(teamContactIds.keySet(), 'Team Facilitator');

    // Loop through the teams and remind the faciltators for them
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    for (npe4__Relationship__c relationship : relationships) {
      emails.add(emailServ.createEmail(teamContactIds.get(relationship.npe4__Contact__c), relationship.npe4__RelatedContact__c, template.Id));
    }
    emailServ.sendEmail(emails);
  }

  // check the dog status and send any emails needed to the client
  public void checkDogStatus() {
    Date today = Date.today();
    List<atlas1__Team__c> teams = teamRepo.getActiveDogs();
    if (teams.isEmpty()) {
      return;
    }
    List<messaging.SingleEmailMessage> emails = new List<messaging.SingleEmailMessage>();
    EmailTemplate template = emailServ.getTemplate('DogVacExamsReminder');
    if (template == null) {
      return;
    }
    for (atlas1__Team__c team : teams) {
      if (team.atlas1__Dog__r == null) {
        continue; // this shouldn't happen, but checking just to be safe
      }
      atlas1__Dog__c dog = team.atlas1__Dog__r;
      if ((dog.atlas1__VaccineDueRabies__c != null && today.daysBetween(dog.atlas1__VaccineDueRabies__c) <= 60) ||
        (dog.atlas1__PhysicalExamDue__c != null && today.daysBetween(dog.atlas1__PhysicalExamDue__c) <= 60) ||
        (dog.atlas1__VaccineDueDA2PP__c != null && today.daysBetween(dog.atlas1__VaccineDueDA2PP__c) <= 60 )) {
        emails.add(emailServ.createEmail(dog.Id, team.atlas1__Client__c, template.Id));
      }
    }
    emailServ.sendEmail(emails);
  }

}