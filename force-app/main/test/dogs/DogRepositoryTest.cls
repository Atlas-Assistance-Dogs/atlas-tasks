/**
 * This class contains unit tests for validating the behavior of Apex class DogRepository
 */
@isTest
private class DogRepositoryTest {
    @isTest
    static void getById_returnsNull_whenNoMatch() {
        // Act
        DogRepository repo = new DogRepository();
        atlas1__Dog__c dog = repo.getById(MockProvider.createId(atlas1__Dog__c.class));
        // Assert
        System.Assert.areEqual(null, dog, 'dog should be null');
    }

    @isTest
    static void getById_returnsNull_whenIdForTeam() {
        // Act
        DogRepository repo = new DogRepository();
        atlas1__Dog__c dog = repo.getById(MockProvider.createId(atlas1__Team__c.class));
        // Assert
        System.Assert.areEqual(null, dog, 'dog should be null');
    }

    @isTest
    static void getById_returnsSpayStatus() {
        // Arrange
        atlas1__Dog__c dog = new atlas1__Dog__c(
            Name = 'Chili', 
            atlas1__SpayedNeutered__c = true
        );
        insert dog;
        // Act
        DogRepository repo = new DogRepository();
        atlas1__Dog__c actual = repo.getById(dog.Id);
        // Assert
        System.Assert.areEqual(dog, actual, 'dog does not match');
    }

}