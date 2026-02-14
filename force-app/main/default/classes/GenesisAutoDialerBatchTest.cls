@isTest
public class GenesisAutoDialerBatchTest {

    @testSetup static void setupData() {
        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStatusCode(200);

        // Success Mock
        mock.setStaticResource('GetSMSNotificationSuccess');
        Test.setMock(HttpCalloutMock.class, mock);
        Lead leadRec = TestObjectsFactory.getLeadRecord(1,'Person');
        Lead leadRec1 = TestObjectsFactory.getLeadRecord(1,'Person');
        insert leadRec;   
    }
    
    @isTest static void testGenesisAutoDialerBatchWithLead() {
        List<Lead> leadRecordList =[select id from Lead limit 2];
        Set<ID> leadIds=new Set<ID>();
        for(Lead newLead:leadRecordList){
            leadIds.add(newLead.Id);
        }
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new GenesisAutoDialerMockResponse());
        GenesisAutoDialerBatch genesisBatchObj=new GenesisAutoDialerBatch(leadIds);
        Database.executeBatch(genesisBatchObj,1);
        Test.StopTest();
    }
    
    
    @isTest static void testGenesisAutoDialerBatchWithoutLead() {
        List<Lead> leadRecordList =[select id from Lead limit 2];
        Set<ID> leadIds=new Set<ID>();
        for(Lead newLead:leadRecordList){
            leadIds.add(newLead.Id);
        }
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new GenesisAutoDialerMockResponse());
        GenesisAutoDialerBatch genesisBatchObj=new GenesisAutoDialerBatch();
        Database.executeBatch(genesisBatchObj,1);
        Test.StopTest();
    }
    
    
    @isTest static void testGenesisAutoDialerBatchWithoutParams() {
        List<Lead> leadRecordList =[select id from Lead limit 2];
        Set<ID> leadIds=new Set<ID>();
        String queryStr='select Id,Title,Name,Email,Phone,Project__c,UnitType__c,NumberOfBedrooms__c,PurposeOfUse__c,Financing__c,LanguagePreference__c,Country from Lead where Genesis_Auto_Dialer_Status__c=\'Failed\'';
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new GenesisAutoDialerMockResponse());
        GenesisAutoDialerBatch genesisBatchObj=new GenesisAutoDialerBatch(queryStr);
        Database.executeBatch(genesisBatchObj,1);
        Test.StopTest();
    }
}