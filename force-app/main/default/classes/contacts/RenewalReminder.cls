global class RenewalReminder implements Schedulable {
  CertificationService service;

  global RenewalReminder() {
    service = new CertificationService();
  }

  global void execute(SchedulableContext sc) {
    service.remindToRenew();
  }

}