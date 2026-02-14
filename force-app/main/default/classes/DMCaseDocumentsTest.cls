@isTest
public class DMCaseDocumentsTest {
    @isTest
    static void testGeneratePDF1() {
        String uniqueUsername = 'testuser' + DateTime.now().getTime() + '@example.com';
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'test@gmail.com', 
            Username = uniqueUsername,
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        Case testCase = new Case(
            Subject = 'Test Case',
            Type = 'NOC', // Or 'Permit to Work'
            Payment_Required__c = 'Yes',
            Development_Name__c='Yas Island',
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Generate_Doc_w_o_Payment__c = false,
            Status = 'Completed',
            CreatedById = testUser.Id
        );
        insert testCase;
        
        List<Case> caseList = new List<Case>{ testCase };
        try{
            Test.startTest();
            DMCaseDocuments.generatePDF(caseList); 
            Test.stopTest();
        }catch(exception e){}
        
    }
}