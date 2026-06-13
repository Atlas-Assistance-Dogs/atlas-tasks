trigger ContactTriggerBefore on Contact(before update) {
    System.debug('ContactTriggerBefore: Updating Contact');
    for (Contact con : Trigger.new ) {
        System.debug('Processing Contact: ' + con.LastName);
        System.debug('Current FacilitatorStatus: ' + con.atlas1__FacilitatorStatus__c);
        System.debug('Current AcceptingNewClients: ' + con.AcceptingNewClients__c);
        System.debug('Old FacilitatorStatus: ' + Trigger.oldMap.get(con.Id).atlas1__FacilitatorStatus__c);
        Contact oldCon = Trigger.oldMap.get(con.Id);
        if (con.atlas1__FacilitatorStatus__c == 'Certified-Active' && oldCon.atlas1__FacilitatorStatus__c != 'Certified-Active') {
            System.debug('FacilitatorStatus changed to Certified-Active, setting AcceptingNewClients to true');
            con.AcceptingNewClients__c = true;
        }
        if (con.atlas1__FacilitatorStatus__c != 'Certified-Active') {
            System.debug('FacilitatorStatus is not Certified-Active, setting AcceptingNewClients to false');
            con.AcceptingNewClients__c = false;
        }
    }
}