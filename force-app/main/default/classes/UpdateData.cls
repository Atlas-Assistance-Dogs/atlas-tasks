public with sharing class UpdateData {
    public UpdateData() {

    }

    final String background = 'Background Check Required';
    final String credit = 'Credit Check Required';
    public void moveBackgroundChecks() {
        Contact[] contacts = [SELECT atlas1__VolunteerAccess__c, BackgroundCheck__c FROM Contact WHERE atlas1__VolunteerAccess__c INCLUDES (:background, :credit)];

        for (Contact c : contacts) {
            Set<String> access = new Set<String>(c.atlas1__VolunteerAccess__c.split(';'));
            if (access.contains(background) && access.contains(credit)) {
                c.BackgroundCheck__c = 'Criminal and Credit';
            } else if (access.contains(background)) {
                c.BackgroundCheck__c = 'Criminal';
            } else {
                c.BackgroundCheck__c = 'Credit';
            }
            access.remove(background);
            access.remove(credit);
            c.atlas1__VolunteerAccess__c = String.join(new List<String>(access), ';');
        }
        update contacts;
    }
  // Find Contacts with current Standalone position that is assigned Teams Set in Motion Client program only and
  // give them the TSiM position
  void setTSiMPosition() {
    atlas1__ProgramAssignment__c[] tsimAssignments = [SELECT Id, 
                                                     atlas1__Contact__r.atlas1__Positions__c, 
                                                     atlas1__Contact__r.atlas1__StandaloneApplicationReceived__c, 
                                                     atlas1__Contact__r.atlas1__StandaloneProgAgreementReceived__c, 
                                                     atlas1__Contact__r.atlas1__StandaloneStatus__c, 
                                                     atlas1__Contact__r.atlas1__TSiMStatus__c, 
                                                     atlas1__Contact__r.atlas1__TSMApplicationReceived__c, 
                                                     atlas1__Contact__r.atlas1__TSMProgAgreementReceived__c
                                              FROM atlas1__ProgramAssignment__c
                                              WHERE atlas1__Program__r.Name = 'Teams Set in Motion Client' AND atlas1__Contact__r.atlas1__Positions__c INCLUDES('Standalone')];

    atlas1__ProgramAssignment__c[] standalones = [SELECT atlas1__Contact__c
                                          FROM atlas1__ProgramAssignment__c
                                          WHERE atlas1__Program__r.atlas1__Standalone__c = true AND atlas1__Program__r.Name != 'Teams Set in Motion Client'];
    Set<Id> standaloneContacts = new Set<Id>();
    for (atlas1__ProgramAssignment__c pa : standalones) {
      standaloneContacts.add(pa.atlas1__Contact__c);
    }

    List<Contact> tsimContacts = new List<Contact>();
    for (atlas1__ProgramAssignment__c pa : tsimAssignments) {
      if (standaloneContacts.contains(pa.atlas1__Contact__r.Id)) {
        continue;
      }
      Contact c = pa.atlas1__Contact__r;
      Set<String> positions = new Set<String>(c.atlas1__Positions__c.split(';'));
      positions.remove('Standalone');
      positions.add('TSiM');
      String[] pos = new List<String>(positions);
      c.atlas1__Positions__c = String.join(pos, ';');
      c.atlas1__TSimStatus__c = c.atlas1__StandaloneStatus__c;
      c.atlas1__TSMApplicationReceived__c = c.atlas1__StandaloneApplicationReceived__c;
      c.atlas1__TSMProgAgreementReceived__c = c.atlas1__StandaloneProgAgreementReceived__c;
      c.atlas1__StandaloneStatus__c = null;
      c.atlas1__StandaloneApplicationReceived__c = null;
      c.atlas1__StandaloneProgAgreementReceived__c = null;
      tsimContacts.add(c);
    }
    update tsimContacts;
    transferDocumentsToTSiM(tsimContacts);
  }

  // Find related
  void transferDocumentsToTSiM(Contact[] contacts) {
    if (contacts.isEmpty()) {
      return;
    }
    Set<Id> contactIds = new Set<Id>();
    for (Contact c : contacts) {
      contactIds.add(c.Id);
    }
    List<Id> lstConDocs = new List<Id>();

    for (ContentDocumentLink cntLink : [SELECT Id, 
                                               ContentDocumentId
                                        FROM ContentDocumentLink
                                        WHERE LinkedEntityId IN :contactIds]) {
      lstConDocs.add(cntLink.ContentDocumentId);
    }
    List<ContentVersion> files = [SELECT atlas1__Category__c
                                  FROM ContentVersion
                                  WHERE atlas1__Category__C = 'Standalone' AND ContentDocumentId IN :lstConDocs AND FileType != 'SNOTE'];
    for (ContentVersion cv : files) {
      cv.atlas1__Category__c = 'TSM';
    }
    update files;
  }
}