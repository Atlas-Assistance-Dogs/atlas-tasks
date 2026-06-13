trigger ContactTriggerBefore on Contact(before update) {
    for (Contact con : Trigger.new ) {
        Contact oldCon = Trigger.oldMap.get(con.Id);
        if (con.atlas1__FacilitatorStatus__c == 'Certified-Active' && oldCon.atlas1__FacilitatorStatus__c != 'Certified-Active') {
            con.AcceptingNewClients__c = true;
        }
        if (con.atlas1__FacilitatorStatus__c != 'Certified-Active') {
            con.AcceptingNewClients__c = false;
        }
    }
}