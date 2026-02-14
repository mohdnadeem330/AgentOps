@isTest
public class DigitalExpTriggerHandlerTest {
    @isTest
    public static void beforeUpdateMethod(){
        //SSP-553 - Dummy Commit
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.FastTrackedAccount__c = true;
        acc.FasttrackCompletionDate__c = system.Today();
        insert acc;
        
        Lead leadRec = TestObjectsFactory.getLeadRecord(3,'Person');
        leadRec.LeadSource = 'Direct Call';
        leadRec.EnquiryCategory__c = 'Aldar Employees';
        leadRec.EnquiryTrigger__c = 'Provis';
        insert leadRec;
        
        
        Communication_Preference__c cp = new Communication_Preference__c();
        cp.Account__c = acc.Id;
        cp.Status__c = 'Link Sent';
        cp.Category__c = 'FastTrack';
        cp.Active__c = true;
        cp.Resend__c = false;
        insert cp;
        Communication_Preference__c cp1 = new Communication_Preference__c();
        cp1.Account__c = acc.Id;
        cp1.Status__c = 'Link Sent';
        cp1.Category__c = 'Digital SPA';
        cp1.Active__c = true;
        cp1.Resend__c = false;
        insert cp1;
        
        Communication_Preference__c cp2 = new Communication_Preference__c();
        cp2.Account__c = acc.Id;
        cp2.Status__c = 'Link Sent';
        cp2.Category__c = 'Booking';
        cp2.Active__c = true;
        cp2.Resend__c = false;
        cp2.Lead__c =leadRec.Id;
        insert cp2;
        
        Communication_Preference__c cpnew = new Communication_Preference__c();
        cpnew.Id = cp.Id;
        cpnew.Resend__c = true;
        cpnew.Status__c ='Fasttrack Completed';
        
        Test.startTest();
        update cpnew; 
        cp2.Status__c ='Fasttrack Completed';
        update cp2;
        Test.StopTest();
        
        //Account UpdateAcc = [select Id, FastTrackedAccount__c, FasttrackCompletionDate__c From Account Where Id =: acc.Id];
        //system.assertEquals(true, updateAcc.FastTrackedAccount__c);
        //system.assertNotEquals(Null, updateAcc.FasttrackCompletionDate__c);
    }
    
    @isTest
    static void testAfterInsertMethodWithBatchExecution() {
        Account testAccount = new Account(Name = 'Test Account', NumberOfUnits__c = 5, EstimatedPurchaseValue__c = 10000);
        insert testAccount;
        
        Communication_Preference__c testPreference = new Communication_Preference__c(Account__c = testAccount.Id, Category__c = 'FastTrack', Active__c = true);
        insert testPreference;
        
        Test.startTest();
        new DigitalExpTriggerHandler().afterInsertMethod(new List<SObject>{testPreference}, new Map<Id, SObject>{testPreference.Id => testPreference});
        Test.stopTest();
    }
    
    @isTest
    static void testAfterInsertMethodExceptionHandling() {
        Test.startTest();
        new DigitalExpTriggerHandler().afterInsertMethod(null, null);
        Test.stopTest();
    }
    
    @isTest
    static void testAfterUpdateMethodWithBatchExecution() {
        Account testAccount =  TestObjectsFactory.getPersonAccountRecord();
        insert testAccount;
        
        
        Lead leadRec = TestObjectsFactory.getLeadRecord(3,'Person');
        leadRec.LeadSource = 'Direct Call';
        leadRec.EnquiryCategory__c = 'Aldar Employees';
        leadRec.EnquiryTrigger__c = 'Provis';
        leadRec.OwnerId =UserInfo.getUserId();
        insert leadRec;
        Communication_Preference__c testPreference = new Communication_Preference__c(Account__c = testAccount.Id,Lead__c =leadRec.Id, Category__c = 'Booking', Active__c = true, Status__c = 'Link Sent');
        insert testPreference;
        
        
        Communication_Preference__c cp2 = new Communication_Preference__c();
        cp2.Account__c = testAccount.Id;
        cp2.Id = testPreference.Id;
        cp2.Status__c = 'Fasttrack Completed';
        cp2.Category__c = 'Booking';
        cp2.Active__c = true;
        cp2.Resend__c = false;
        cp2.Lead__c = leadRec.Id;
        Update cp2;
        
        
        Test.startTest();
        new DigitalExpTriggerHandler().afterUpdateMethod(new List<SObject>{testPreference}, new Map<Id, SObject>{testPreference.Id => testPreference}, new List<SObject>(), new Map<Id, SObject>{cp2.Id=>cp2});
        Test.stopTest();
        
    }
    
    @isTest
    static void testAfterUpdateMethodExceptionHandling() {
        
        
        Test.startTest();
        new DigitalExpTriggerHandler().afterUpdateMethod(null, null, null, null); // Pass null values to cause an exception
        Test.stopTest();
        
    }
}