/**
 * This class contains methods to create test data for the certification repository
 */
@isTest
public class CertificationRepositoryData {
  public Contact con1;
  public atlas1__Certification__c cert;
  public atlas1__Ceu__c ceu;
  public atlas1__CeuCertification__c cc;

  public CertificationRepositoryData() {
    con1 = new Contact(FirstName = 'John', LastName = 'Smith', atlas1__Positions__c = 'Team Facilitator;Trainer', atlas1__FacilitatorStatus__c = 'Certified-Active', atlas1__TrainerStatus__c = 'Certified-Active');
    insert con1;
    Date start = Date.today().addYears(-1).addMonths(3);
    Date ending = start.addYears(1);
    cert = new atlas1__Certification__c(
      atlas1__Status__c = 'Active',
      atlas1__Contact__c = con1.Id,
      atlas1__End__c = ending,
      atlas1__Start__c = start,
      atlas1__Type__c = 'Trainer'
    );
    insert cert;
    ceu = new atlas1__Ceu__c(
      atlas1__Authority__c = 'Atlas',
      atlas1__Comments__c = 'Comments1',
      atlas1__DateCompleted__c = Date.today().addMonths(-1),
      atlas1__DateSubmitted__c = Date.today().addMonths(-1),
      atlas1__ProgramHours__c = 20,
      atlas1__ProgramTitle__c = 'A Day in the Life of a Dog',
      atlas1__Quantity__c = 20,
      atlas1__Role__c = 'Presenter',
      atlas1__Status__c = 'Approved',
      atlas1__Contact__c = con1.Id
    );
    insert ceu;
    cc = new atlas1__CeuCertification__c(
      atlas1__Ceu__c = ceu.Id,
      atlas1__Certification__c = cert.Id
    );
  }
}
