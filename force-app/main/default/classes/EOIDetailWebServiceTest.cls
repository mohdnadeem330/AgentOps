@isTest(SeeAllData=false)
public class EOIDetailWebServiceTest {
    @isTest static void setupMethod() {
        
        Account orgAccount = TestObjectsFactory.getOrganisationAccountRecord('PWC', '123456789');
        insert orgAccount;
        
        Contact contactRecord = TestObjectsFactory.contactDataSetup(orgAccount.id);
        //insert contactRecord;
        
        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(orgAccount.Id);
        opportunityRecord.EnquiryTrigger__c = 'Aldar Academies';
        insert opportunityRecord;

        Unit__c unit = TestObjectsFactory.unitDataSetup('Mayan');
        insert unit;
                     
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opportunityRecord.Id, orgAccount.Id);
        salesOrderRecord.unit__c = unit.Id;
        insert salesOrderRecord;

        OpportunityEOI__c eoiRecord = TestObjectsFactory.getOpportunityEOIRecord(opportunityRecord.Id, 'POS');
        eoiRecord.ComplianceStatus__c = Constants.RECEIPT_STATUS_CLEARED;
        eoiRecord.AllottedUnit__c = 'Mayan';
        insert eoiRecord;
       
        ReceiptAcknowledgement__c receiptRecord = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrderRecord.Id, orgAccount.Id, opportunityRecord.Id, 'POS');
        receiptRecord.OpportunityEOI__c = eoiRecord.Id;
        insert receiptRecord;
        
        TestObjectsFactory.initializeRestContext(null, '/get/opportunityEOI');
        
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');

        RestContextHandler handler = new RestContextHandler(false);
        
        Test.startTest();
        
        EOIDetailWebService.doPost(opportunityRecord.Id);

        Test.stopTest();
    }
   
}