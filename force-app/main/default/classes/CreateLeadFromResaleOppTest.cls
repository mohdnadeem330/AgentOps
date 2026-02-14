/**
* CreateLeadFromResaleOppTest
*
* Test class for CreateLeadFromResaleOppController
*/
@isTest
public class CreateLeadFromResaleOppTest {
    @TestSetup
    static void makeData(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        unitrecord.ResaleListed__c = true;
        unitRecord.Listing_Price__c = 10000000;
        // unitRecord.Offer_Accepted__c = false;
        unitRecord.ResaleStatus__c = '';
        insert unitrecord;

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryTrigger__c=null;
        insert opp;

        Lead leadRec = TestObjectsFactory.getLeadRecord(3,'Person');
        leadRec.LeadSource = '800-Aldar';
        leadRec.EnquiryCategory__c = 'Aldar Database';
        leadRec.EnquiryTrigger__c = 'Aldar SMS Campaign';
        leadRec.IsConverted = true;
        leadRec.ConvertedAccountId = acc.Id;
        leadRec.ConvertedOpportunityId = opp.Id;
        insert leadRec;
    }

    @IsTest
    static void createNewLeadTest(){
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1][0].Id;
        Test.startTest();
            String result = CreateLeadFromResaleOppController.createNewLead(oppId);
        Test.stopTest();
    }
}