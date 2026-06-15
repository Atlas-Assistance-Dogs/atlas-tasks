/**
 * Trigger to handle Contact updates related to trainer and facilitator status changes.
 */
trigger ContactTrigger on Contact (after update) {
    CertificationService service = new CertificationService();
    service.handleContactChange(Trigger.new, Trigger.oldMap);
}