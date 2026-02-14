@isTest(SeeAllData=false)
public class EOIRangeWebserviceTest {
    @isTest static void setupMethod() {

        Account orgAccount = TestObjectsFactory.getOrganisationAccountRecord('PWC', '123456789');
        insert orgAccount;
        
        Contact contactRecord = TestObjectsFactory.contactDataSetup(orgAccount.id);
        //insert contactRecord;
        
        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(orgAccount.Id);
        opportunityRecord.EnquiryTrigger__c = 'Aldar Academies';
        insert opportunityRecord;   
        
        Project__c p= TestObjectsFactory.getProjectRecord('45223452');
        insert p;

        BuildingSection__c b= TestObjectsFactory.getBuildingDetailRecord(p.id);
        b.EOIFee__c = 100;
        insert b;

        EOIRange__c eoi= TestObjectsFactory.getEOIRangeRecord(p.id,b.id);
        eoi.UnitType__c = 'Pent House';
        insert eoi;

        TestObjectsFactory.initializeRestContext(null, '/get/eoiranges');
        
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');

        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();                
        EOIRangeWebservice.doPost(opportunityRecord.Id);
        Test.stopTest();
    }
}