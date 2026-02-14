@isTest
private class DMcaseMilestonehandlerTest {
  @isTest
    public static void milestoneTest() {
      test.startTest();
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
        Product2 testProduct = new Product2(Name = 'Road Closure Diversion', IsActive = true,Family = 'NOC');
        insert testProduct;
        // Create a test case with initial values Dummy Commit - SSP-348
        Case newcase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Type = 'NOC',
            Development_Name__c='Yas Island',
            Status = 'Pending with Customer',
            Sub_Status__c= Label.DM_AdditionalInfoFromCustomer,
            Subject = 'Test NOC Application',
            IPS_Received_from_ADM__c='Yes',
            ProductId=testProduct.id,
            IsStopped = false
        );
        
        insert newcase;   
        TriggerHandler.processedIds = new Set<Id>();
        newcase.Status='Pending with Customer';
        newcase.Sub_Status__c='Waiting for Payment';       
        update newcase;
     test.stopTest();
    }
  @isTest
    public static void milestoneTest2() {
      test.startTest();
        try{
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
        Product2 testProduct = new Product2(Name = 'Road Closure Diversion', IsActive = true,Family = 'NOC');
        insert testProduct;
        // Create a test case with initial values
        
        Case newcase = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId(),
            Type = 'NOC',
            Development_Name__c='Yas Island',
            Status = 'Pending with Customer',
            Sub_Status__c= 'Waiting for Payment',
            Subject = 'Test NOC Application',
            IPS_Received_from_ADM__c='Yes',
            ProductId=testProduct.id,
            IsStopped = false
        );
        
        insert newcase;   
        TriggerHandler.processedIds = new Set<Id>();
        newcase.status='Work In Progress';
        newcase.Sub_Status__c=Label.DM_AdditionalInfoFromPMC;       
        update newcase; 
        }
        catch(exception e){
            system.debug('Error in message =' + e.getMessage());
        }
       
     test.stopTest();
    }

}