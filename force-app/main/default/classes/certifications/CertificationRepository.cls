public inherited sharing class CertificationRepository {
  public atlas1__Certification__c[] getActiveCerts() {
    return [SELECT Id, 
                   atlas1__Contact__c, 
                   atlas1__Approved__c, 
                   atlas1__Type__c, 
                   atlas1__Start__c, 
                   atlas1__End__c
            FROM atlas1__Certification__c
            WHERE atlas1__Status__c = 'Active' AND (
              (atlas1__Type__c = 'Facilitator' AND atlas1__Contact__r.atlas1__IsTeamFacilitator__c = true AND atlas1__Contact__r.atlas1__FacilitatorStatus__c = 'Certified-Active') OR 
              (atlas1__Type__c = 'Trainer' AND atlas1__Contact__r.atlas1__IsTrainer__c = true AND atlas1__Contact__r.atlas1__TrainerStatus__c = 'Certified-Active'))];
  }

}