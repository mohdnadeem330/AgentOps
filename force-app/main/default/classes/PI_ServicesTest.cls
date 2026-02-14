@isTest
public class PI_ServicesTest {

     @testSetup static void setup(){
    	Lead newLead = new Lead();
        newLead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('P_I_Lead').getRecordTypeId();
        newLead.FirstName = 'test';
        newLead.LastName = 'Last001';
        newLead.Email = 'test@test.com';
        newLead.Company = 'testcmp';
        newLead.Commentary__c = 'test';
        newLead.Deal_Type__c = 'Joint Venture';
        newLead.Estimated_Deal_size__c = 1000;
        newLead.Ownership__c = 12;
        newLead.Project_city__c = 'Ajman';
        newLead.Project_Country__c = 'United Arab Emirates';
        newLead.PuP_Budget__c = 123466;
        newLead.PuP_Project_Code__c = 'test code'; 
        newLead.Type__c = 'Regional';
        newLead.ownerId = UserInfo.getUserId();
        insert newLead;
    }
    
    @isTest
    public static void testcreateDocumentForPandILead (){
       list<Lead> leads = new list<Lead>([Select Id,FirstName,LastName,Email,Company,Commentary__c,Deal_Type__c,
                   Estimated_Deal_size__c,Ownership__c,Project_city__c,Project_Country__c,
                   PuP_Budget__c,PuP_Project_Code__c,Type__c,ownerId,Start_date__c,Expected_due_date__c from Lead limit 1]);
        Test.startTest();
        PI_Services.createDocumentForPandILead(leads);
        Test.stopTest();
    }
    
    @isTest
    public static void testconvertPandILeads (){
       list<Lead> leads = new list<Lead>([Select Id,FirstName,LastName,Email,Company,Commentary__c,Deal_Type__c,
                   Estimated_Deal_size__c,Ownership__c,Project_city__c,Project_Country__c,
                   PuP_Budget__c,PuP_Project_Code__c,Type__c,ownerId,Start_date__c,Expected_due_date__c from Lead limit 1]);
        Test.startTest();
        PI_Services.convertPandILeads(leads);
        Test.stopTest();
    }
    
}