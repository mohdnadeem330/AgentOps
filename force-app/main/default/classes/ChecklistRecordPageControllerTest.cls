@isTest
public class ChecklistRecordPageControllerTest {
    @testSetup
    static void setupTestData() {
        // Create Account record
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        insert orgAcc;
        
        Account orgAcc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert orgAcc1;
        
        orgAcc1.RecordTypeId = Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        orgAcc1.AgencyCategory__c = 'Broker';
        orgAcc1.AgencySubCategory__c = 'LSQ broker';
        orgAcc1.ParentId = orgAcc.Id;
        update orgAcc1;
        
        // Create Invoice Bundle record
        InvoiceBundle__c invoiceBundle = new InvoiceBundle__c(); 
        invoiceBundle.BrokerAgency__c = orgAcc1.Id;
        invoiceBundle.BundleName__c = 'BrokerAgencyId';
        invoiceBundle.Status__c = 'Not Ready';
        invoiceBundle.BrokerManager__c = UserInfo.getUserId();
        invoiceBundle.BundleNumber__c = 1;
        insert invoiceBundle;
        
        // Create Checklist record
        Checklist__c checklist = new Checklist__c(
            InvoiceBundle__c = invoiceBundle.Id,
            Is_Active__c = true
        );
        insert checklist;
        Document__c doc = new Document__c(Checklist__c = checklist.Id, 
                                          DocumentType__c = 'Checklist Document',GenerateDocument__c = false);
        insert doc;
        
        // Create Commission Line Item record
        CommissionLineItem__c cli = new CommissionLineItem__c(
            InvoiceBundle__c = checklist.InvoiceBundle__c,
            CommissionAmount__c = 2200,
            CommissionPercentage__c = 1, 
            CommissionType__c = 'Internal',
            CurrencyIsoCode = 'AED'
        );
        insert cli;
    }
    
    @isTest
    static void testGetChecklistDetails() {
        List<Checklist__c> listChecklist = [SELECT Id FROM Checklist__c LIMIT 1];
        Test.startTest();
        
        ChecklistRecordPageController.ChecklistDetail details = ChecklistRecordPageController.getChecklistDetails(listChecklist[0].Id);
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateChecklist() {
        List<Checklist__c> checklist = [SELECT Id FROM Checklist__c LIMIT 1];
        checklist[0].Is_Active__c = false;
        
        String jsonString = JSON.serialize(checklist[0]);
        
        Test.startTest();
        String response = ChecklistRecordPageController.updateChecklist(jsonString);
        Test.stopTest();
    }
    
    @isTest
    static void testGetChecklistDetails_NoRecords() {
        Test.startTest();
        ChecklistRecordPageController.ChecklistDetail details = ChecklistRecordPageController.getChecklistDetails('NON_EXISTENT');
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateChecklist_InvalidJson() {
        Test.startTest();
        try {
            ChecklistRecordPageController.updateChecklist('invalid json');
        } catch (Exception e) {
        }
        Test.stopTest();
    }
}