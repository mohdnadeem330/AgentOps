/**
* DashboardControllerTest
*
* Test class for DashboardController
*/
@isTest
private class DashboardWitoutShareControllerTest{
    //Creating test data
     @testSetup static void setupData() {
        BrokerActivities__c brokerActivityRecord = new BrokerActivities__c();
        brokerActivityRecord.StartDate__c = system.today();
        brokerActivityRecord.Name='Test';
        brokerActivityRecord.Description__c ='Test';
        brokerActivityRecord.Type__c = BrokerActivities__c.Type__c.getDescribe().getPicklistValues()[0].getValue();
        brokerActivityRecord.Status__c = BrokerActivities__c.Status__c.getDescribe().getPicklistValues()[0].getValue();
        insert brokerActivityRecord;
    }
    //Fetching account data and the Document public URLs
    @isTest static void testDashBoardData() {
        BrokerActivities__c brokerActivityRecord = [select id from BrokerActivities__c limit 1];
        list<Document__c> documentrecords = [select id,DocumentType__c,Activity__c from Document__c where Activity__c = :brokerActivityRecord.id ];
        System.assertEquals(documentrecords.isEmpty(),false);
        for(Document__c docRecord : documentrecords){
        	OpportunityUnitSearchController.uploadFile(Blob.valueOf('Test').toString(),docRecord.DocumentType__c,docRecord.id);
        }
        DashboardWitoutShareController.getAccountRanking();
        DashboardWitoutShareController.getActivityDocs(new set<ID>{brokerActivityRecord.Id});
        DashboardWitoutShareController.getPublicDocumentURL(new set<ID>{documentrecords[0].Id});
        
    }
}