public with sharing class AccountRepository {

    // returns the contacts associated with the account
    public Contact[] getContacts(Id accountId) {
        return [SELECT Id, 
                       FirstName, 
                       LastName
                FROM Contact
                WHERE AccountId = :accountId];
    }

}