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

  @IsTest
  static void getActiveCerts_returnsOnlyCertsWithActiveContacts() {
    CertificationRepositoryData data = new CertificationRepositoryData();
    Date start = Date.today().addYears(-1).addMonths(3);
    Date ending = start.addYears(1);
    atlas1__Certification__c cert2 = new atlas1__Certification__c(
      atlas1__Status__c = 'Active', 
      atlas1__Contact__c = data.con1.Id, 
      atlas1__End__c = ending, 
      atlas1__Start__c = start, 
      atlas1__Type__c = 'Facilitator'
    );
    insert cert2;

    data.con1.atlas1__FacilitatorStatus__c = 'Discontinued';
    update data.con1;

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

  @IsTest
  static void getActiveCerts_returnsOnlyCertsWithActiveContacts2() {
    CertificationRepositoryData data = new CertificationRepositoryData();
    Date start = Date.today().addYears(-1).addMonths(3);
    Date ending = start.addYears(1);
    atlas1__Certification__c cert2 = new atlas1__Certification__c(
      atlas1__Status__c = 'Active', 
      atlas1__Contact__c = data.con1.Id, 
      atlas1__End__c = ending, 
      atlas1__Start__c = start, 
      atlas1__Type__c = 'Facilitator'
    );
    insert cert2;

    data.con1.atlas1__TrainerStatus__c = 'Discontinued';
    update data.con1;

    // the trigger adds a cc
    atlas1__Certification__c[] actual = repo.getActiveCerts();
    System.assertEquals(1, actual.size(), 'wrong number of certs');
    atlas1__Certification__c cert = actual[0];
    System.assertEquals(cert2.Id, cert.Id, 'wrong cert');
    System.assertEquals(cert2.atlas1__Type__c, cert.atlas1__Type__c, 'wrong type');
    System.assertEquals(cert2.atlas1__Start__c, cert.atlas1__Start__c, 'returned wrong start date');
    System.assertEquals(cert2.atlas1__End__c, cert.atlas1__End__c, 'wrong end date');
    System.assertEquals(cert2.atlas1__Contact__c, cert.atlas1__Contact__c, 'wrong contact');
  }

  @IsTest
  static void getActiveTrainerCerts_returnsEmptyWhenNoCerts() {
    // act
    atlas1__Certification__c[] actual = repo.getActiveTrainerCerts();
    // assert
    System.assertEquals(0, actual.size(), 'wrong number of certs');
  }

  @IsTest
  static void getActiveTrainerCerts_returnsEmptyWhenNoActiveCerts() {
    // arrange
    CertificationRepositoryData data = new CertificationRepositoryData();
    data.cert.atlas1__Status__c = 'Inactive';
    update data.cert;
    // act
    atlas1__Certification__c[] actual = repo.getActiveTrainerCerts();
    // assert
    System.assertEquals(0, actual.size(), 'wrong number of certs');
  }

  @IsTest
  static void getActiveTrainerCerts_returnsEmptyWhenNoActiveTrainerCerts() {
    // arrange
    CertificationRepositoryData data = new CertificationRepositoryData();
    data.cert.atlas1__Type__c = 'Facilitator';
    update data.cert;
    // act
    atlas1__Certification__c[] actual = repo.getActiveTrainerCerts();
    // assert
    System.assertEquals(0, actual.size(), 'wrong number of certs');
  }

  @IsTest
  static void getActiveTrainerCerts_returnsEmptyWhenCertActiveButNotTrainer() {
    // arrange
    CertificationRepositoryData data = new CertificationRepositoryData();
    data.con1.atlas1__TrainerStatus__c = 'Discontinued';
    update data.con1;
    // act
    atlas1__Certification__c[] actual = repo.getActiveTrainerCerts();
    // assert
    System.assertEquals(0, actual.size(), 'wrong number of certs');
  }

  @IsTest
  static void getActiveTrainerCerts_returnsCertWhenCertActiveForTrainer() {
    // arrange
    CertificationRepositoryData data = new CertificationRepositoryData();
    // act
    atlas1__Certification__c[] actual = repo.getActiveTrainerCerts();
    // assert
    atlas1__Certification__c expected = [SELECT atlas1__Contact__c, 
                                                atlas1__End__c, 
                                                atlas1__Approved__c
                                         FROM atlas1__Certification__c
                                         WHERE Id = :data.cert.Id];
    System.assertEquals(expected, actual[0], 'wrong cert');
  }

  @isTest
  static void getActiveTrainerCerts_returnsOnlyTrainerCert() {
    // arrange
    CertificationRepositoryData data = new CertificationRepositoryData();
    atlas1__Certification__c cert = new atlas1__Certification__c(
      atlas1__Status__c = 'Active', 
      atlas1__Contact__c = data.con1.Id, 
      atlas1__End__c = Date.today().addMonths(5), 
      atlas1__Start__c = Date.today().addMonths(-7), 
      atlas1__Type__c = 'Facilitator'
    );
    insert cert;
    // act
    atlas1__Certification__c[] actual = repo.getActiveTrainerCerts();
    // assert
    System.Assert.areEqual(1, actual.size(), 'wrong number of certs');
    atlas1__Certification__c expected = [SELECT atlas1__Contact__c, 
                                                atlas1__End__c, 
                                                atlas1__Approved__c
                                         FROM atlas1__Certification__c
                                         WHERE Id = :data.cert.Id];
    System.assertEquals(expected, actual[0], 'wrong cert');
  }

}