/**
 * Trigger to handle Contact updates related to trainer status changes.
 * When a trainer's status changes from 'Certified-Active' to 'Discontinued',
 * it initiates the decertification process by creating tasks for administrators
 */
trigger ContactTrigger on Contact (after update) {
    CertificationService service = new CertificationService();
    service.handleDecertification(Trigger.new, Trigger.oldMap);
}