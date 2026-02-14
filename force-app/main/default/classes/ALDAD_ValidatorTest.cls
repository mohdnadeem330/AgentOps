@isTest
public class ALDAD_ValidatorTest {

    @testSetup static void setupData() {
        
     // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
        leadRec.Project__c='AlReeman2';
        Lead leadRec1 = TestObjectsFactory.getLeadRecord(1,'Person');
        insert leadRec;      
    }
    
     @isTest static void testIsAutoDialerAssigneeLead() {
          List<Lead> leadRecordList =[select Id,Title,Name,Email,Phone,Project__c,UnitType__c,NumberOfBedrooms__c,PurposeOfUse__c,Financing__c,LanguagePreference__c,Country,LeadSource from Lead limit 2];
          System.assertEquals(ALDAD_Validator.isAutoDialerAssigneeLead(leadRecordList.get(0)), true);
    }
    
     @isTest static void testIsAutoDialerAssigneeLeadByID() {
          List<Lead> leadRecordList =[select Id,Title,Name,Email,Phone,Project__c,UnitType__c,NumberOfBedrooms__c,PurposeOfUse__c,Financing__c,LanguagePreference__c,Country,LeadSource from Lead limit 2];
           List<Id> leadIds=new List<Id>();
           leadIds.add(leadRecordList.get(0).Id);
           ALDAD_Validator.autoDialerAssigneeLeadCheck(leadIds);
        // System.assertEquals(, true);
    }
}