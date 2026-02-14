@isTest
public class LeadPhoneValidationBatchTest {
    @isTest
    public static void testLeadPhoneValidationBatch() {
        // Create test data
        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            MobileNumber1__c= '588080914',
            MobileCountryCode__c = '971',
            EnquiryTrigger__c = 'GoogleSDC',
            Project__c = 'Yas Park Gate',
            LeadSource = 'Online',
            EnquiryCategory__c =  'Google',
            SalesType__c = 'Residential Sale',
            PropertyUsage__c = 'Residential Sale',
            LeadOrigin__c = 'United Arab Emirates',
            SalesOrigin__c = 'Domestic'
           
        );
        insert testLead;

        // Set up the mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MobileMockHttpResponseGenerator());
        Set<Id> leadId = new Set<Id>();
        leadId.add(testLead.Id);

        // Start the batch execution
        Test.startTest();
        Database.executeBatch(new LeadPhoneValidationBatch(leadId));
        Test.stopTest();

        // Retrieve the updated Lead record after the batch execution
        Lead updatedLead = [SELECT Id, MobileCountryCode__c,MobilePhone,MobileNumberisValid__c, MobileNumber1__c, LeadScore__c FROM Lead WHERE Id IN :leadId];

        // Perform assertions based on the expected results
        System.assertEquals('971', updatedLead.MobileCountryCode__c);
        //Replace 'ExpectedNationalFormat' and 'ExpectedIsValid' with the actual expected values
        System.assertEquals('971588080914', updatedLead.MobilePhone);
        System.assertEquals('ExpectedIsValid', updatedLead.MobileNumberisValid__c);
         System.assertEquals('588080914', updatedLead.MobileNumber1__c);
        System.assertEquals('971', updatedLead.MobileCountryCode__c);
         System.assertEquals('588080914', updatedLead.MobileNumber1__c);
         //System.assertEquals('05 88080914', updatedLead.MobileNumber1__c);
        //System.assertEquals('588080914', updatedLead.MobileNumber1__c);

    }
}