@isTest
private class BackgroundCheckRepositoryTest {
    @isTest
    static void getMatchingChecksForContacts_returnsEmpty_whenContactsIsNull() {
        BackgroundCheckRepository repo = new BackgroundCheckRepository();

        List<atlas1__BackgroundCheck__c> result = repo.getMatchingChecksForContacts(null, null);

        System.assert(result.isEmpty());
    }

    @isTest
    static void getMatchingChecksForContacts_returnsEmpty_whenContactsIsEmpty() {
        BackgroundCheckRepository repo = new BackgroundCheckRepository();

        List<atlas1__BackgroundCheck__c> result = repo.getMatchingChecksForContacts(new Set<Id>(), null);

        System.assert(result.isEmpty());
    }

    @isTest
    static void getMatchingChecksForContacts_returnsEmpty_whenContactsAndDateAreEmpty() {
        BackgroundCheckRepository repo = new BackgroundCheckRepository();

        List<atlas1__BackgroundCheck__c> result = repo.getMatchingChecksForContacts(new Set<Id>(), Date.today());

        System.assert(result.isEmpty());
    }

    @isTest
    static void getMatchingChecksForContacts_returnsEmpty_whenContactsButNoBgChecks() {
        BackgroundCheckRepository repo = new BackgroundCheckRepository();

        List<atlas1__BackgroundCheck__c> result = repo.getMatchingChecksForContacts(new Set<Id>{ MockProvider.createId(Contact.class), MockProvider.createId(Contact.class) }, Date.today());

        System.assert(result.isEmpty());
    }

    @isTest
    static void getMatchingChecksForContacts_returnsEmpty_whenCheckBeforeThreshold() {
        BackgroundCheckRepository repo = new BackgroundCheckRepository();
        Date threshold = Date.today().addMonths(-11);
        Contact bluey = new Contact(
            FirstName = 'Bluey', 
            LastName = 'Heeler', 
            Email = 'bluey@test.com', 
            BackgroundCheck__c = 'Credit'
        );
        insert bluey;
        atlas1__BackgroundCheck__c check = new atlas1__BackgroundCheck__c(
            atlas1__Contact__c = bluey.Id, 
            atlas1__Status__c = 'Pass', 
            atlas1__Type__c = 'Credit', 
            atlas1__Date__c = threshold.addDays(-1)
        );
        insert check;

        List<atlas1__BackgroundCheck__c> result = repo.getMatchingChecksForContacts(new Set<Id>{ bluey.Id }, threshold);

        System.assert(result.isEmpty());
    }

    @isTest
    static void getMatchingChecksForContacts_returnsEmpty_whenCheckAtThreshold() {
        BackgroundCheckRepository repo = new BackgroundCheckRepository();
        Date threshold = Date.today().addMonths(-11);
        Contact bluey = new Contact(
            FirstName = 'Bluey', 
            LastName = 'Heeler', 
            Email = 'bluey@test.com', 
            BackgroundCheck__c = 'Credit'
        );
        insert bluey;
        atlas1__BackgroundCheck__c check = new atlas1__BackgroundCheck__c(
            atlas1__Contact__c = bluey.Id, 
            atlas1__Status__c = 'Pass', 
            atlas1__Type__c = 'Credit', 
            atlas1__Date__c = threshold
        );
        insert check;

        List<atlas1__BackgroundCheck__c> result = repo.getMatchingChecksForContacts(new Set<Id>{ bluey.Id }, threshold);

        System.assert(result.isEmpty());
    }

    @isTest
    static void getMatchingChecksForContacts_returnsCheck_whenCheckAfterThreshold() {
        BackgroundCheckRepository repo = new BackgroundCheckRepository();
        Date threshold = Date.today().addMonths(-11);
        Contact bluey = new Contact(
            FirstName = 'Bluey', 
            LastName = 'Heeler', 
            Email = 'bluey@test.com', 
            BackgroundCheck__c = 'Credit'
        );
        insert bluey;
        atlas1__BackgroundCheck__c check = new atlas1__BackgroundCheck__c(
            atlas1__Contact__c = bluey.Id, 
            atlas1__Status__c = 'Pass', 
            atlas1__Type__c = 'Credit', 
            atlas1__Date__c = threshold.addDays(1)
        );
        insert check;

        List<atlas1__BackgroundCheck__c> result = repo.getMatchingChecksForContacts(new Set<Id>{ bluey.Id }, threshold);

        System.assertEquals(1, result.size());
    }

    @isTest
    static void getMatchingChecksForContacts_returnsEmpty_whenTypeMisMatch() {
        BackgroundCheckRepository repo = new BackgroundCheckRepository();
        Date threshold = Date.today().addMonths(-11);
        Contact bluey = new Contact(
            FirstName = 'Bluey', 
            LastName = 'Heeler', 
            Email = 'bluey@test.com', 
            BackgroundCheck__c = 'Credit'
        );
        Contact bingo = new Contact(
            FirstName = 'Bingo', 
            LastName = 'Heeler', 
            Email = 'bingo@test.com', 
            BackgroundCheck__c = 'Criminal'
        );

        insert new List<Contact>{ bluey, bingo };
        atlas1__BackgroundCheck__c check1 = new atlas1__BackgroundCheck__c(
            atlas1__Contact__c = bluey.Id, 
            atlas1__Type__c = 'Criminal', 
            atlas1__Date__c = threshold.addDays(1)
        );
        atlas1__BackgroundCheck__c check2 = new atlas1__BackgroundCheck__c(
            atlas1__Contact__c = bingo.Id, 
            atlas1__Type__c = 'Credit', 
            atlas1__Date__c = threshold.addDays(1)
        );
        insert new List<atlas1__BackgroundCheck__c>{ check1, check2 };

        List<atlas1__BackgroundCheck__c> result = repo.getMatchingChecksForContacts(new Set<Id>{ bingo.Id, bluey.Id }, threshold);

        System.assert(result.isEmpty());
    }

    @isTest
    static void getMatchingChecksForContacts_returnsCheck_whenTypeMatch() {
        BackgroundCheckRepository repo = new BackgroundCheckRepository();
        Date threshold = Date.today().addMonths(-11);
        Contact bluey = new Contact(
            FirstName = 'Bluey', 
            LastName = 'Heeler', 
            Email = 'bluey@test.com', 
            BackgroundCheck__c = 'Credit'
        );
        Contact bingo = new Contact(
            FirstName = 'Bingo', 
            LastName = 'Heeler', 
            Email = 'bingo@test.com', 
            BackgroundCheck__c = 'Criminal'
        );

        insert new List<Contact>{ bluey, bingo };
        atlas1__BackgroundCheck__c check1 = new atlas1__BackgroundCheck__c(
            atlas1__Contact__c = bingo.Id, 
            atlas1__Type__c = 'Criminal', 
            atlas1__Date__c = threshold.addDays(1)
        );
        atlas1__BackgroundCheck__c check2 = new atlas1__BackgroundCheck__c(
            atlas1__Contact__c = bluey.Id, 
            atlas1__Type__c = 'Credit', 
            atlas1__Date__c = threshold.addDays(1)
        );
        insert new List<atlas1__BackgroundCheck__c>{ check1, check2 };

        List<atlas1__BackgroundCheck__c> result = repo.getMatchingChecksForContacts(new Set<Id>{ bingo.Id, bluey.Id }, threshold);

        System.assertEquals(2, result.size());
    }

    @isTest
    static void getMatchingChecksForContacts_returnsCheck_whenBothRequired() {
        BackgroundCheckRepository repo = new BackgroundCheckRepository();
        Date threshold = Date.today().addMonths(-11);
        Contact bluey = new Contact(
            FirstName = 'Bluey', 
            LastName = 'Heeler', 
            Email = 'bluey@test.com', 
            BackgroundCheck__c = 'Criminal and Credit'
        );
        insert bluey;
        atlas1__BackgroundCheck__c check = new atlas1__BackgroundCheck__c(
            atlas1__Contact__c = bluey.Id, 
            atlas1__Status__c = 'Pass', 
            atlas1__Type__c = 'Criminal and Credit', 
            atlas1__Date__c = threshold.addDays(1)
        );
        insert check;

        List<atlas1__BackgroundCheck__c> result = repo.getMatchingChecksForContacts(new Set<Id>{ bluey.Id }, threshold);

        System.assertEquals(1, result.size());
    }

    @isTest
    static void getMatchingChecksForContacts_returnsEmpty_whenBothRequiredAndSeparatePresent() {
        BackgroundCheckRepository repo = new BackgroundCheckRepository();
        Date threshold = Date.today().addMonths(-11);
        Contact bluey = new Contact(
            FirstName = 'Bluey', 
            LastName = 'Heeler', 
            Email = 'bluey@test.com', 
            BackgroundCheck__c = 'Criminal and Credit'
        );
        insert bluey;
        atlas1__BackgroundCheck__c[] checks = new atlas1__BackgroundCheck__c[]{ new atlas1__BackgroundCheck__c(
            atlas1__Contact__c = bluey.Id, 
            atlas1__Status__c = 'Pass', 
            atlas1__Type__c = 'Criminal', 
            atlas1__Date__c = threshold.addDays(1)
        ), new atlas1__BackgroundCheck__c(
            atlas1__Contact__c = bluey.Id, 
            atlas1__Status__c = 'Pass', 
            atlas1__Type__c = 'Credit', 
            atlas1__Date__c = threshold.addDays(1)
        ) };
        insert checks;

        List<atlas1__BackgroundCheck__c> result = repo.getMatchingChecksForContacts(new Set<Id>{ bluey.Id }, threshold);

        System.assertEquals(0, result.size());
    }

    @isTest
    static void getMatchingChecksForContacts_returnsChecks_whenBothRequired() {
        BackgroundCheckRepository repo = new BackgroundCheckRepository();
        Date threshold = Date.today().addMonths(-11);
        Contact bluey = new Contact(
            FirstName = 'Bluey', 
            LastName = 'Heeler', 
            Email = 'bluey@test.com', 
            BackgroundCheck__c = 'Criminal and Credit'
        );
        insert bluey;
        atlas1__BackgroundCheck__c[] checks = new List<atlas1__BackgroundCheck__c>{ new atlas1__BackgroundCheck__c(
            atlas1__Contact__c = bluey.Id, 
            atlas1__Status__c = 'Pass', 
            atlas1__Type__c = 'Criminal and Credit', 
            atlas1__Date__c = threshold.addDays(1)
        ) };
        insert checks;

        List<atlas1__BackgroundCheck__c> result = repo.getMatchingChecksForContacts(new Set<Id>{ bluey.Id }, threshold);

        System.assertEquals(1, result.size());
    }

}