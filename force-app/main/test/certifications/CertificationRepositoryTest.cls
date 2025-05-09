/**
 * This class contains unit tests for validating the behavior of CertificationRepository
 */
@isTest
private class CertificationRepositoryTest {
  private static CertificationRepository repo = new CertificationRepository();

  @IsTest
  static void getActiveCerts_returnsAllFields() {
    CertificationRepositoryData data = new CertificationRepositoryData();
    // the trigger adds a cc
    atlas1__Certification__c[] actual = repo.getActiveCerts();
    System.assertEquals(1, actual.size(), 'wrong number of certs');
    atlas1__Certification__c cert = actual[0];
    System.assertEquals(data.cert.Id, cert.Id, 'wrong cert');
    System.assertEquals(data.cert.atlas1__Type__c, cert.atlas1__Type__c, 'wrong type');
    System.assertEquals(data.cert.atlas1__Start__c, cert.atlas1__Start__c, 'returned wrong start date');
    System.assertEquals(data.cert.atlas1__End__c, cert.atlas1__End__c, 'wrong end date');
    System.assertEquals(data.cert.atlas1__Contact__c, cert.atlas1__Contact__c, 'wrong contact');
  }
}
