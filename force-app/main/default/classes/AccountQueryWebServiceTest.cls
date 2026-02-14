@isTest(SeeAllData=false)
public class AccountQueryWebServiceTest {
    
    static Account accountRecord;
    
    static void init(){
        
        accountRecord = TestObjectsFactory.getOrganisationAccountRecord('CompanyName', 'Ysjs657');
        insert accountRecord;
        Contact contactRecord = TestObjectsFactory.contactDataSetup(accountRecord.Id);  
        
        Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(accountRecord.Id);
        insert opportunityRecord;
        
        Lead leadRec = TestObjectsFactory.getLeadRecord(4, 'Person');
        leadRec.LeadSource = '800-Aldar' ;
        leadRec.EnquiryCategory__c = 'Kiosk' ;
        leadRec.EnquiryTrigger__c = 'Aljimi Mall Kiosk' ;
        insert leadRec ;
        
        leadRec.ExistingAccount__c = accountRecord.id;
        update leadRec;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opportunityRecord.Id, accountRecord.Id);
        salesOrderRecord.Unit__c = unit.id;
        insert salesOrderRecord;
        
        salesOrderRecord.Status__c = 'Pending';
        update salesOrderRecord;
        
        Task leadTask = TestObjectsFactory.getAccountActivity(accountRecord.Id);
        Task opportunityTask = TestObjectsFactory.getOpportunityActivity(opportunityRecord.Id);
    }
    static testmethod void testAccountById() {
        
        init();
        
        TestObjectsFactory.initializeRestContext(null, '/query/account');
        
        Map<String, String> searchMap = new Map<String, String>();
		searchMap.put('Id', accountRecord.Id);
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(searchMap));
        
        AccountQueryWebService.doPost();        
        TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
        RestContextHandler handler = new RestContextHandler(false);
        AccountQueryWebService.doPost();  
        
        Test.startTest();
        
        TestObjectsFactory.initializeRestContext(null, '/query/accountss');
        AccountQueryWebService.doPost();
        
        Test.stopTest();
        
        
    }
}