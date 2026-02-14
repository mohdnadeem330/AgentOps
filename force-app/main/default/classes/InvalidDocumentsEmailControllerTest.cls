@isTest
public class InvalidDocumentsEmailControllerTest {
    @isTest
    public static void doTest(){
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        orgAcc.Email__c = 'Ali.athamneh@pwc.com';
        insert orgAcc;
       
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        conRecord.Email = 'Ali.athamneh@pwc.com';
        update conRecord;
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.CustomerBankName__c = 'Test';
        acc.CustomerBankCountry__c = 'United Arab Emirates';
        insert acc;
         
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.BrokerAgencyAccount__c =orgAcc.Id;
        opp.BrokerAgentContact__c=conRecord.Id;
        insert opp;
        Document__c docRecord= new Document__c(Opportunity__c=opp.Id,DocumentType__c=Constants.DOCUMENT_TYPE_GTC);
        insert docRecord;
        docRecord.Status__c = 'Invalid Document';
        update docRecord;
        Test.startTest();
        InvalidDocumentsEmailController obj = new InvalidDocumentsEmailController();
        obj.recordId = opp.Id;
        obj.getDocuments();
        Test.stopTest();
        
    }
}