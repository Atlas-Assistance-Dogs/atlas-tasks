global class RenewalReminder implements Schedulable {

/* Send reminder emails and tasks related to Trainer renewal:
  - exactly 1 month before Trainer Certification Valid Until- "1 month email"
  - exactly 2 weeks before Trainer Certification Valid Until- "2 week email"
  - exactly 1 week before Trainer Certification Valid Until- "1 week email"
  - Day of Trainer Certification Valid Until = " last day email"
  - 1 week after = "you expired a week ago"
  - 30 days after Trainer Certification Valid Until-> "decertification email"
*/
  global void execute(SchedulableContext sc) {
    Contact[] trainers = [SELECT atlas1__TrainerCertValidUntil__c, atlas1__PreferredName__c FROM Contact WHERE atlas1__TrainerStatus__c = 'Active'];
    for (Contact trainer : trainers) {
      // If the Date that calls the method occurs after the secondDate, the return value is negative.
      Integer numberDays = trainer.atlas1__TrainerCertValidUntil__c.daysBetween(Date.today());
      switch on numberDays {
        when -30 {
          
        }
        when else {
          
        }
      }(trainer.atlas1__TrainerCertValidUntil__c < Date.today() + 14) {
        // Send reminder email to active trainers
        sendEmail(trainer);
      }
    }
  }
}
