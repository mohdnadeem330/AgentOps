@isTest(SeeAllData=false)
public class EOICreateWebServiceTest {

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

        OpportunityEOI__c opportunityEOIRecord = new OpportunityEOI__c();
        opportunityEOIRecord.UnitModel__c = '1BHK';
        opportunityEOIRecord.UnitType__c = 'Pent House';
        opportunityEOIRecord.UnitFeatures__c = 'P.Sea';
        opportunityEOIRecord.Remarks__c = 'remark';
        opportunityEOIRecord.PriceRangeFrom__c = 2000;
        opportunityEOIRecord.PriceRangeTo__c = 20000;
        opportunityEOIRecord.Opportunity__c = opportunityRecord.Id;
        opportunityEOIRecord.Account__c = orgAccount.Id;
               
        TestObjectsFactory.initializeRestContext(null, '/upsert/opportunityEOI');
        
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');

        RestContextHandler handler = new RestContextHandler(false);
        EOICreateWebService.doPost(opportunityEOIRecord);        
        
        Test.startTest();        
        opportunityEOIRecord.PaymentMode__c = 'Gpay';
        EOICreateWebService.doPost(opportunityEOIRecord);
        Test.stopTest();
    }
    @isTest static void setupMethod1() {
        
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
        
        OpportunityEOI__c existingEOIRecord = TestObjectsFactory.getOpportunityEOIRecord(opportunityRecord.Id, 'POS');
        insert existingEOIRecord;

        OpportunityEOI__c opportunityEOIRecord = new OpportunityEOI__c();
        //opportunityEOIRecord.ProjectNameFormula__c = 'Mayan';
        //opportunityEOIRecord.BuildingSectionName__c = 'Building 1';
        opportunityEOIRecord.UnitModel__c = '1BHK';
        opportunityEOIRecord.UnitType__c = 'Pent House';
        opportunityEOIRecord.UnitFeatures__c = 'P.Sea';
        opportunityEOIRecord.Remarks__c = 'remark';
        opportunityEOIRecord.PriceRangeFrom__c = 2000;
        opportunityEOIRecord.PriceRangeTo__c = 20000;
        opportunityEOIRecord.Opportunity__c = opportunityRecord.Id;
        opportunityEOIRecord.Account__c = orgAccount.Id;

        String JSON = '{"opportunityEOIRecord" : {"Opportunity__c": "'+opportunityRecord.Id+'","Account__c": "'+orgAccount.Id+'","ProjectName__c" : "Mayan", "BuildingSectionName__c" : "Building 1", "UnitModel__c" :"1BHK", "UnitType__c" : "Pent House","UnitFeatures__c" : "P.Sea", "Remarks__c" : "remark","PriceRangeFrom__c":"2000", "PriceRangeTo__c" : "20000","InterestFee__c": "1000"}}';

        //insert eoiRecord;
               
        TestObjectsFactory.initializeRestContext(null, '/upsert/opportunityEOI');
        
        TestObjectsFactory.initializeRestContext(JSON, '/some/path', '1.0', 'ios', '13', 'iphone x');

        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();        
        EOICreateWebService.doPost(opportunityEOIRecord);
        Test.stopTest();
    }
    
}