@IsTest
public class North_baniyasRequestTest {
    @IsTest
    static void testGetAllDlpCases() {
        User u = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];
        System.runAs(u) {
            Test.startTest();
            String result = North_baniyasRequest.getAllDlpCases(10, 1, '','NewCase','0990988','Status/ASC');
            System.assertNotEquals(null, result, 'Result should not be null');
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testGetAllAcceptedCase() {
        User u = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];
        System.runAs(u) {
            Test.startTest();
            String result = North_baniyasRequest.getAllDlpCases(10, 1, '','AllAcceptedCase','0990988','Status/ASC');
            System.assertNotEquals(null, result, 'Result should not be null');
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testGetFilterCase() {
        User u = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];
        System.runAs(u) {
            Test.startTest();
            String result = North_baniyasRequest.getAllDlpCases(10, 1, '','FilterCase','0990988','Status/ASC');
            System.assertNotEquals(null, result, 'Result should not be null');
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testGetdlpEmergencyCase() {
        User u = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];
        System.runAs(u) {
            Test.startTest();
            String result = North_baniyasRequest.getAllDlpCases(10, 1, '','dlpEmergencyCase','0990988','Status/ASC');
            System.assertNotEquals(null, result, 'Result should not be null');
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testGetdlpAllCase() {
        User u = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];
        System.runAs(u) {
            Test.startTest();
            String result = North_baniyasRequest.getAllDlpCases(10, 1, '','dlpAllCase','0990988','Status/ASC');
            System.assertNotEquals(null, result, 'Result should not be null');
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testGetAllDlpCasesWithFilter() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u) {
            Test.startTest();
            String result = North_baniyasRequest.getAllDlpCases(10, 1, 'Status = \'New\'','Mycases','998098','');
            System.assertNotEquals(null, result, 'Result should not be null');
            Test.stopTest();
        }
    }
    
    /*@IsTest
static void testGetAllDlpCasesWithInvalidPageNumber() {
User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
System.runAs(u) {
Test.startTest();
String result = North_baniyasRequest.getAllDlpCases(10, 0, '',true);
System.assertNotEquals(null, result, 'Result should not be null');
Test.stopTest();
}
}*/
    
    @IsTest
    static void testGetAllDlpCasesWithInvalidPageSize() {
        User u = [SELECT Id FROM User WHERE Id =:UserInfo.getUserId()];
        System.runAs(u) {
            Test.startTest();
            String result = North_baniyasRequest.getAllDlpCases(0, 1, '','NewCase','987987','');
            System.assertNotEquals(null, result, 'Result should not be null');
            Test.stopTest();
        }
    }
    
   
    
    @IsTest
    static void testUpdateAssignTo() {
        User u = [SELECT Id FROM User WHERE Id=:UserInfo.getUserId()];
        //Queue queue1 = new Queue(Name = 'Test Queue');
        //insert queue1;
        QueueSobject queue = [SELECT Id,QueueId,Queue.Name  FROM QueueSobject WHERE SObjectType = 'Case' and Queue.Name ='Contact Center Queue' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            Account testAccount = new Account(
                Name = 'Test Account',
                BillingStreet = '123 Test Lane',
                BillingCity = 'Dubai',
                BillingState = 'Dubai',
                BillingPostalCode = '12345',
                BillingCountry = 'United Arab Emirates'
            );
            insert testAccount;
            Contact testContact = new Contact(
                LastName = 'Test contact',
                AccountId = testAccount.Id);
            insert testContact;
            //Test.startTest();
            Case testCase = new Case(
                AccountId = testAccount.Id,
                ContactId = testContact.Id,
                recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
                Type = 'NOC',
                Development_Name__c='Yas Island',
                Status = 'New',
                Subject = 'Test NOC Application',
                IPS_Received_from_ADM__c='Yes',
                Priority = 'P1',
                CaseCategory__c = 'North Baniyas-AC',
                SubCategory__c = 'Thermostat not working',
                CreatedDate = System.today().addDays(-5)
                //ProductId=testProduct.id
            );
            insert testCase;
            
            Case testCase1 = new Case(
                AccountId = testAccount.Id,
                ContactId = testContact.Id,
                recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Requests').getRecordTypeId(),
                Type = 'NOC',
                Development_Name__c='Yas Island',
                Status = 'New',
                Subject = 'Test NOC Application',
                IPS_Received_from_ADM__c='Yes',
                Priority = 'P1',
                CaseCategory__c = 'North Baniyas-AC',
                SubCategory__c = 'Thermostat not working',
                CreatedDate = System.today().addDays(-10)
                //ProductId=testProduct.id
            );
            insert testCase1;

			List<CaseComment> comments = new List<CaseComment>();
            comments.add(new CaseComment(
                ParentId = testCase.Id,
                CommentBody = 'Latest comment for Case 1',
                CreatedDate = System.now()
            ));
            comments.add(new CaseComment(
                ParentId = testCase.Id,
                CommentBody = 'Older comment for Case 1',
                CreatedDate = System.now().addDays(-1)
            ));
            comments.add(new CaseComment(
                ParentId = testCase1.Id,
                CommentBody = 'Comment for Case 2',
                CreatedDate = System.now()
        	));
            insert comments;
            //Case testCase1 = [SELECT Id FROM Case LIMIT 1];
            North_baniyasRequest.updateAssignTo(testCase.Id,UserInfo.getUserId()); 
            North_baniyasRequest.getDLpCaseInfo(testCase.Id);
            North_baniyasRequest.updatedlpCase(testCase.Id,'Work In Progress','ABC',system.today(),'Test','New','North Baniyas-Civil','Aluminium');
            North_baniyasRequest.getQueueMembersByOwner(testCase.Id);
            Date fromDate = System.today().addDays(-10); 
        	Date toDate = System.today(); 
            North_baniyasRequest.getFilteredCasesForExport('New','P1','North Baniyas-AC','Thermostat not working',fromDate,toDate);
            Case updatedCase = [SELECT Id, Assigned_To__c FROM Case WHERE Id = :testCase.Id];
            System.assertEquals(u.Id, updatedCase.Assigned_To__c, 'Assigned To should be updated');
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testGetUserName() {
        User u = [SELECT Id FROM User WHERE Id=:UserInfo.getUserId()];
        System.runAs(u) {
            Test.startTest();
            User result = North_baniyasRequest.getUserName(u.Id);
            System.assertNotEquals(null, result, 'Result should not be null');
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testGetCaseCommentsAndPosts() {
        // Setup: Create necessary data
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u) {
            Test.startTest();
            
            Account testAccount = new Account(
                Name = 'Test Account',
                BillingStreet = '123 Test Lane',
                BillingCity = 'Dubai',
                BillingState = 'Dubai',
                BillingPostalCode = '12345',
                BillingCountry = 'United Arab Emirates'
            );
            insert testAccount;
            
            Contact testContact = new Contact(
                LastName = 'Test contact',
                AccountId = testAccount.Id);
            insert testContact;
            Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
            unit.Status__c = 'Sold';
            insert unit;
            Case testCase = new Case(
                AccountId = testAccount.Id,
                ContactId = testContact.Id,
                recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
                Type = 'NOC',
                Development_Name__c='Yas Island',
                Status = 'New',
                Subject = 'Test NOC Application',
                IPS_Received_from_ADM__c='Yes',
                Unit__c = unit.Id
            );
            insert testCase;
            
            CaseComment cc = new CaseComment(
                ParentId = testCase.Id,
                CommentBody = 'This is a test comment'
            );
            insert cc;
            
            List<CaseComment> result = North_baniyasRequest.getCaseCommentsAndPosts(testCase.Id);
            List<Id> listCaseId = new List<Id>{ testCase.Id };
            North_baniyasRequest.notifyNorthBaniyasQueue(listCaseId);
            Test.stopTest();
        }
    }
}