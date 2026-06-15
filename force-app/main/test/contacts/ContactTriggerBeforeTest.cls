/**
 * This class contains unit tests for validating the behavior of the Contact trigger before events.
 It ensures that the trigger logic is functioning as expected and that any necessary validations or
 operations are performed correctly when Contact records are created, updated, or deleted.
 */
@IsTest
private class ContactTriggerBeforeTest {
    @IsTest
    static void triggerSetsAcceptingWhenFacilitatorIsActivated() {
        // arrange
        Contact contact = new Contact(
            LastName = 'Test', 
            atlas1__Positions__c = 'Team Facilitator', 
            atlas1__FacilitatorStatus__c = 'In Training'
        );
        insert contact;
        // act
        contact.atlas1__FacilitatorStatus__c = 'Certified-Active';
        Test.startTest();
        Database.SaveResult result = Database.update (contact, false);
        Test.stopTest();

        // Assert
        System.assert(result.isSuccess(), 'Expected update to succeed');
        System.Assert.AreEqual(0, result.getErrors().size(), 'Expected no errors on update');
        contact = [SELECT AcceptingNewClients__c FROM Contact WHERE Id = :contact.Id];
        System.Assert.IsTrue(contact.AcceptingNewClients__c, 'Expected AcceptingNewClients__c to be true');
    }

    @IsTest
    static void triggerSetsNotAcceptingWhenFacilitatorIsNotCertifiedActive() {
        // arrange
        Contact contact = new Contact(
            LastName = 'Test', 
            atlas1__Positions__c = 'Team Facilitator', 
            atlas1__FacilitatorStatus__c = 'Certified-Active'
        );
        insert contact;
        // act
        contact.atlas1__FacilitatorStatus__c = 'Certified-OnHold';
        Test.startTest();
        Database.SaveResult result = Database.update (contact, false);
        Test.stopTest();

        // Assert
        System.assert(result.isSuccess(), 'Expected update to succeed');
        System.Assert.AreEqual(0, result.getErrors().size(), 'Expected no errors on update');
        contact = [SELECT AcceptingNewClients__c FROM Contact WHERE Id = :contact.Id];
        System.Assert.IsFalse(contact.AcceptingNewClients__c, 'Expected AcceptingNewClients__c to be false');
    }

    @IsTest
    static void triggerDoesNotChangeAcceptingWhenFacilitatorIsCertifiedActive() {
        // arrange
        Contact contact = new Contact(
            LastName = 'Test', 
            atlas1__Positions__c = 'Team Facilitator', 
            atlas1__FacilitatorStatus__c = 'Certified-Active'
        );
        insert contact;
        // act
        contact.AcceptingNewClients__c = false;
        Test.startTest();
        Database.SaveResult result = Database.update (contact, false);
        Test.stopTest();

        // Assert
        System.assert(result.isSuccess(), 'Expected update to succeed');
        System.Assert.AreEqual(0, result.getErrors().size(), 'Expected no errors on update');
        contact = [SELECT AcceptingNewClients__c FROM Contact WHERE Id = :contact.Id];
        System.Assert.IsFalse(contact.AcceptingNewClients__c, 'Expected AcceptingNewClients__c to be false');
    }
}