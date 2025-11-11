/**
 * This class contains unit tests for validating the behavior of Apex classe PatRepository.
 */
@isTest
private class PatRepositoryTest {
    private static PatRepository patRepo = new PatRepository();
    @isTest
    static void getFirstPat_returnsNullWhenIdIsNull() {
        atlas1__PublicAccessTest__c pat = patRepo.getFirstPat(null);
        System.assertEquals(null, pat, 'pat should be null');
    }

    @isTest
    static void getFirstPat_returnsNullWhenIdIsNotForExistingTeam() {
        atlas1__PublicAccessTest__c pat = patRepo.getFirstPat(MockProvider.createId(atlas1__Team__c.class));
        System.assertEquals(null, pat, 'pat should be null');
    }

    @isTest
    static void getFirstPat_returnsNullWhenNoPatForExistingTeam() {
        atlas1__Team__c team = TestTeam.create();
        atlas1__PublicAccessTest__c pat = patRepo.getFirstPat(team.Id);
        System.assertEquals(null, pat, 'pat should be null');
    }

    @isTest
    static void getFirstPat_returnsPatForExistingTeam() {
        atlas1__Team__c team = TestTeam.create();
        atlas1__PublicAccessTest__c p = new atlas1__PublicAccessTest__c(
            atlas1__Team__c = team.Id, 
            atlas1__DateCompleted__c = Date.today(), 
            atlas1__Location__c = 'In Person', 
            atlas1__Status__c = 'Passed', 
            atlas1__Type__c = 'Initial'
        );
        insert p;

        atlas1__PublicAccessTest__c pat = patRepo.getFirstPat(team.Id);
        System.assertEquals(p.atlas1__DateCompleted__c, pat.atlas1__DateCompleted__c, 'date should match');
        System.assertNotEquals(null, pat.Id, 'Id should be set');
    }

}