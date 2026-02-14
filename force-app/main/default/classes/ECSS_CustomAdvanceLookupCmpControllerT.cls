@isTest
public class ECSS_CustomAdvanceLookupCmpControllerT {

    @testSetup
    static void setupTestData() {
        TestObjectsFactory.createUser();
        User testUser = [select id from user where email='testuser@example.com'];
        System.runAs(testUser) {
            List<Account> accounts = new List<Account>{
                new Account(Name = 'Test Account 1', Phone = '1234567890', ECSS_Aldar_Estate__c = true),
                new Account(Name = 'Test Account 2', Phone = '0987654321', ECSS_Aldar_Estate__c = false),
                new Account(Name = 'Test Account 3', Phone = '1122334455', ECSS_Aldar_Estate__c = true)
            };
            insert accounts;
                Project__c newProject = TestObjectsFactory.getProjectRecord('projectId'); 
            insert newProject ;
            BuildingSection__c newBuilding = TestObjectsFactory.getBuildingDetailRecord(newProject.Id);
            insert newBuilding ;
            Asset unit = TestObjectsFactory.getECSSUnitDetail(newProject.Id,newBuilding.Id );
            insert unit;
    }
    }

    @isTest
    static void testGetLookupValues() {
        Test.startTest();
         List<Asset> unitList = new List<Asset>([SELECT Id from Asset LIMIT 1]);
        List<sObject> results = ECSS_CustomAdvanceLookupCmpController.getLookupValues(
            'Test',
            'Account',
            '(Phone LIKE \'%123%\' OR Name LIKE \'%Test%\')',
            '', 
            10,
            unitList[0].Id
            
        );
        
        Test.stopTest();

       // System.assertNotEquals(null, results, 'Results should not be null.');
       // System.assert(results.size() > 0, 'Results should contain at least one record.');
    }
    @isTest
    static void testGetLookupValuesContact() {
        Test.startTest();
         List<Account> accList = new List<Account>([SELECT Id from Account LIMIT 1]);
        List<sObject> results = ECSS_CustomAdvanceLookupCmpController.getLookupValuesContact(
            'Test',
            'Contact',
            '(Phone LIKE \'%123%\' OR Name LIKE \'%Test%\')',
            '', 
            10,
            accList[0].Id
            
        );
        
        Test.stopTest();

      
    }

    @isTest
    static void testGetInitRecord() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        Test.startTest();
        
        sObject result = ECSS_CustomAdvanceLookupCmpController.getinitRecord(
            testAccount.Id,
            'Account',
            '' 
        );
        
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals('Test Account 1', result.get('Name'), 'The name should match the test record.');
    }

    @isTest
    static void testGetRecentlyCreatedRecords() {
        Test.startTest();
       
        List<sObject> results = ECSS_CustomAdvanceLookupCmpController.gerRecentlyCreatedRecords(
            'Account',
            '', 
            'Phone LIKE \'%123%\'',
            10
        );
        
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null.');
        System.assert(results.size() > 0, 'Results should contain at least one record.');
    }

    @isTest
    static void testDefaultWhereCondition() {
        Test.startTest();
        
        List<sObject> results = ECSS_CustomAdvanceLookupCmpController.gerRecentlyCreatedRecords(
            'Account',
            'ECSS_Aldar_Estate__c', 
            '', 
            10
        );
        
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null.');
        System.assert(results.size() == 2, 'Results should contain only records with ECSS_Aldar_Estate__c = true.');
        for (sObject record : results) {
            Account acc = (Account) record;
            System.assertEquals(true, acc.get('ECSS_Aldar_Estate__c'), 'Each account should have ECSS_Aldar_Estate__c = true.');
        }
    }
}