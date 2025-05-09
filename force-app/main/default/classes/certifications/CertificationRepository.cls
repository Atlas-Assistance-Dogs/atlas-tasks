public inherited sharing class CertificationRepository {
    public atlas1__Certification__c[] getActiveCerts() {
        return [
          SELECT Id, atlas1__Contact__c, atlas1__Approved__c, atlas1__Type__c, atlas1__Start__c, atlas1__End__c
          FROM atlas1__Certification__c
          WHERE atlas1__Status__c = 'Active'
        ];
      }
    }