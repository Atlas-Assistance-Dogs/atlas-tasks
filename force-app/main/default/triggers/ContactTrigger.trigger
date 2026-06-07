/**
 * Trigger to handle Contact updates related to trainer status changes.
 * When a trainer's status changes from 'Certified-Active' to 'Inactive' OR
 * when the trainer's status changed from 'In Training' to 'Discontinued'
 * it initiates the decertification/discontinuation process by creating tasks
 */
trigger ContactTrigger on Contact (after update) {
    CertificationService service = new CertificationService();
    service.handleContactChange(Trigger.new, Trigger.oldMap);
}