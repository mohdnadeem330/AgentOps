@isTest
public class DDRNotificationToBankPDFHandlerTest {

    @isTest
    public static void parseResponse() {
       Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit.Id;
        insert salesOrder1;
        
        DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder1.id);
        ddr.PayerAccount__c=acc.Id;
        ddr.SentTobankDate__c = System.now();
        insert ddr;
        
        Document__c document = TestObjectsFactory.getDDRDocument(ddr.id);
        insert document;
        
        ContentVersion content=new ContentVersion(); 
        content.Title='SampleTestFile'; 
        content.PathOnClient='/' + content.Title + '.txt'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        content.ContentLocation = 'S';
        insert content;
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId = document.id;
        contentlink.contentdocumentid = [select Id, contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'V';
        contentlink.Visibility = 'AllUsers';
        insert contentlink;
        
        DDTransaction__c ddt = TestObjectsFactory.createDDTransactions(ddr.id, 'Abu Dhabi Commercial Bank');
        
        ddt.Requesttype__c = 'New Registration';
        insert ddt;
        ddt.TransactionStatus__c = 'Sent to Bank';
        update ddt;
        DDTransaction__c  ddr1 = [Select
                                  DirectDebitRequest__r.SentToBankDays__c,
                                  DirectDebitRequest__r.SentTobankDate__c ,
                                 
                                  TransactionStatus__c  from DDTransaction__c where Id=:ddt.id ];
        system.debug('ddr1:::'+ddr1);
        system.debug('ddr1:::'+ddr1.DirectDebitRequest__r.SentTobankDate__c);
        system.debug('ddr1:::'+ddr1.DirectDebitRequest__r.SentToBankDays__c);
        test.startTest();
        ScheduledClassToDDRNotificationToBank s = new ScheduledClassToDDRNotificationToBank();
        s.execute(null);
        test.stopTest();
    }
}