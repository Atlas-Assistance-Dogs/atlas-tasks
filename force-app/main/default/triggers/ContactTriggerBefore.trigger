trigger ContactTriggerBefore on Contact (before update) {
    for (Contact con : Trigger.new) {
        Contact oldCon = Trigger.oldMap.get(con.Id);
        if (con.atlat1__FacilitatorStatus__c == 'Certified-Active' && oldCon.atlat1__FacilitatorStatus__c != 'Certified-Active') {
           con.AcceptingNewClients__c = true;
        }
        if (con.atlat1__FacilitatorStatus__c != 'Certified-Active') {
           con.AcceptingNewClients__c = false;
        }
    }

}