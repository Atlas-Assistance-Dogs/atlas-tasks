public inherited sharing class BackgroundCheckRepository {
     public atlas1__BackgroundCheck__c[] getMatchingChecksForContacts(Set<Id> contactIds, Date threshold) {
        return [SELECT Id, 
                       atlas1__Date__c, 
                       atlas1__Contact__c, 
                       atlas1__Type__c, 
                       atlas1__Contact__r.Name
                FROM atlas1__BackgroundCheck__c
                WHERE atlas1__Contact__c IN :contactIds AND atlas1__Date__c > :threshold// AND  atlas1__Status__c = 'Pass' We are not checking status at this time
         AND ((atlas1__Contact__r.atlas1__VolunteerAccess__c INCLUDES('Combined Background Check Required') AND atlas1__Type__c = 'Criminal&Credit') OR
          (atlas1__Contact__r.atlas1__VolunteerAccess__c INCLUDES('Credit Check Required') AND atlas1__Type__c = 'Credit') OR
          (atlas1__Contact__r.atlas1__VolunteerAccess__c INCLUDES('Background Check Required') AND atlas1__Type__c = 'Criminal'))
                ORDER BY atlas1__Date__c DESC // get the most recent first
        ];
    }

}