@isTest
public class DocuSignStatusControllerTest {

    @testSetup
    private static void setupData() {
        
         Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;
       
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
       /* User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
        agencyAdminUser.contactId=conRecord.Id;
        insert agencyAdminUser; */
        
         
         Account acc = TestObjectsFactory.getPersonAccountRecord();
         insert acc;
         
         Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
         opp.BrokerAgentContact__c=conRecord.Id;
         opp.BrokerAgencyAccount__c =orgAcc.Id;
         opp.Contact__c=conRecord.Id;
         insert opp;
         Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
         insert projectRecord;
         
         //Add GTC under project
         Document__c docRecord= new Document__c(Project__c=projectRecord.Id,DocumentType__c=Constants.DOCUMENT_TYPE_GTC);
         insert docRecord;
        List<dfsle__RecipientStatus__c> newList = new List<dfsle__RecipientStatus__c>();
        Map<Id,dfsle__RecipientStatus__c> oldMapList = new Map<Id,dfsle__RecipientStatus__c>();   
        
        dfsle__EnvelopeStatus__c es = new dfsle__EnvelopeStatus__c();
        es.dfsle__DocuSignId__c = '1234TEST-83ef-47b6-bc4e-123411111111';
        es.dfsle__EmailSubject__c= 'SARAN TEST SUB';
        es.dfsle__Sent__c = System.now();
        es.dfsle__Expires__c = System.now().addDays(1);
        es.dfsle__Reason__c = 'test';
        es.dfsle__SenderEmail__c = 'saran@aldar.com';
        es.dfsle__SenderName__c = 'Saran';
        es.dfsle__Status__c = 'Sent';
        es.dfsle__SourceId__c = docRecord.id;
        insert es;
        
        System.debug('es Id -> '+es.Id);
        dfsle__RecipientStatus__c rs = new dfsle__RecipientStatus__c();
        rs.dfsle__Status__c = 'Sent';
        rs.dfsle__Email__c = 'saran@aldar.com';
        rs.dfsle__RoutingOrder__c = 1;
        rs.dfsle__EnvelopeStatus__c = es.Id;
        //rs.EnvelopeId__c = '08993507-f57b-4e3c-9bfe-09e5b1144c35';
        newList.add(rs);
        
        dfsle__RecipientStatus__c rs2 = new dfsle__RecipientStatus__c();
        rs2.dfsle__Status__c = 'Created';
        rs2.dfsle__Email__c = 'saran2@aldar.com';
        rs2.dfsle__RoutingOrder__c = 1;
        rs2.dfsle__EnvelopeStatus__c = es.Id;
        newList.add(rs2);
        
        insert newList;
        
        dfsle__EnvelopeStatus__c es2 = new dfsle__EnvelopeStatus__c();
        es2.dfsle__DocuSignId__c = '1234TEST-83ef-47b6-bc4e-123411111114';
        es2.dfsle__EmailSubject__c= 'SARAN TEST SUB';
        es2.dfsle__Sent__c = System.now();
        es2.dfsle__Expires__c = System.now().addDays(1);
        es2.dfsle__Reason__c = 'test';
        es2.dfsle__SenderEmail__c = 'saran@aldar.com';
        es2.dfsle__SenderName__c = 'Saran';
        es2.dfsle__Status__c = 'Completed';
        es2.dfsle__SourceId__c = docRecord.id;
        insert es2;
        
        dfsle__RecipientStatus__c rs3 = new dfsle__RecipientStatus__c();
        rs3.dfsle__Status__c = 'Completed';
        rs3.dfsle__Email__c = 'saran2@aldar.com';
        rs3.dfsle__RoutingOrder__c = 1;
        rs3.dfsle__EnvelopeStatus__c = es2.Id;
        insert rs3;
        
         dfsle__RecipientStatus__c rs4 = new dfsle__RecipientStatus__c();
        rs4.dfsle__Status__c = 'Delivered';
        rs4.dfsle__Email__c = 'saran2@aldar.com';
        rs4.dfsle__RoutingOrder__c = 1;
        rs4.dfsle__EnvelopeStatus__c = es2.Id;
        insert rs4;
    }
    
    @isTest
    private static void getdocuSignStatusActivityLineTest(){
        List<dfsle__EnvelopeStatus__c> envelopeStatusList = [SELECT
                                                             dfsle__Completed__c,
                                                             dfsle__DocuSignId__c,
                                                             dfsle__EmailSubject__c,
                                                             dfsle__Expires__c,
                                                             dfsle__LastStatusUpdate__c,
                                                             dfsle__Reason__c,
                                                             dfsle__SenderEmail__c,
                                                             dfsle__SenderName__c,
                                                             dfsle__Sent__c,
                                                             dfsle__SourceId__c,
                                                             dfsle__Status__c,
                                                             dfsle__TimeToComplete__c,
                                                             Id,
                                                             Name,
                                                             (SELECT
                                                              dfsle__Completed__c,
                                                              dfsle__Email__c,
                                                              dfsle__EnvelopeStatus__c,
                                                              dfsle__LastStatusUpdate__c,
                                                              dfsle__Reason__c,
                                                              dfsle__RoutingOrder__c,
                                                              dfsle__Sent__c,
                                                              dfsle__Sequence__c,
                                                              dfsle__SourceId__c,
                                                              dfsle__Status__c,
                                                              dfsle__Type__c,
                                                              Id,Name FROM dfsle__Recipients__r ORDER BY LASTMODIFIEDDATE DESC)
                                                             FROM dfsle__EnvelopeStatus__c Limit 1];
       system.debug('envelopeStatusList::'+envelopeStatusList);
        test.startTest();
        docuSignStatusController.getdocuSignStatusActivityLine(envelopeStatusList[0].dfsle__SourceId__c);
        test.stopTest();
        
    }
}