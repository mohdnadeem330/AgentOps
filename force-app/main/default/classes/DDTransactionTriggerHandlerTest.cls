@isTest
public class DDTransactionTriggerHandlerTest {

    @testSetup static void setupData() {
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
        insert ddr;
        
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('YASPARK');
        insert unit2;
        
        SalesOrder__c salesOrder2 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder2.Unit__c = unit2.Id;
        insert salesOrder2;
        
        DirectDebitRequest__c ddr2 = TestObjectsFactory.createDirectDebitRecords(salesOrder2.id);
        ddr2.PayerAccount__c=acc.Id;
        insert ddr2;
    }
    
    @isTest
    public static void parseResponse() {
        Test.startTest();
        DirectDebitRequest__c ddr = [SELECT Id From DirectDebitRequest__c Limit 1];
        
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
        insert ddt;
        
        DDTransaction__c ddt11 = TestObjectsFactory.createDDTransactions(ddr.id, 'Abu Dhabi Islamic Bank');
        insert ddt11;
        
        DirectDebitRequest__c ddr2 = [SELECT Id From DirectDebitRequest__c Limit 1];
        
        Document__c document2 = TestObjectsFactory.getDDRDocument(ddr2.id);
        insert document2;
        
        DDTransaction__c ddt2 = TestObjectsFactory.createDDTransactions(ddr2.id, 'First Abu Dhabi Bank');
        insert ddt2; 
           
        DDTransaction__c ddt3 = TestObjectsFactory.createDDTransactions(ddr.id, 'Abu Dhabi Commercial Bank');
        ddt3.DDResponsefiletype__c = 'Collection Response';
        insert ddt3;
        
        ddt3.DDResponse__c = 'DACDRIREDR,0035022304116MTQ,000001,0035002304106MTJ,000001,RESP,550000657,55000065702023000000001,55000065702023000000001006MTJ,AED,10.00,AE220030010503791920050,600310101,AE350030011454359920001,A,10.00,,,,muzammil bajaria,ACDESC10503791920007,,,,,000001,2023-04-11,17:00:00,5002304100000018,UAEDDS';
        ddt3.TransactionStatus__c = 'Approved';        
        update ddt3;  
        TriggerHandler.processedIds = new Set<Id>();
      
        ddt.DDResponse__c ='NAKHR,REJECTED,C300003000014230204194211.DDS,3002301270000557\n'+
            'NAKDR,000001,12111,DARDR-10-INVALID CUSTOMER ID FOR GIVEN CUSTOMER TYPE.\n'+
            'NAKTR,REJECTED,3,003DAR23012701UM';
        ddt.TransactionStatus__c = 'Sent to Bank';
        ddt.DDResponsefiletype__c = 'Registration AckNack';
        update ddt;
     
         
        
        ddt2.DDResponse__c = 'Date Processed|Request Type|OIC|Payer Identification|DDA Reference|Customer Type|Customer ID Type|Customer ID Number|Bank Name|Title of Account|Account Type|IBAN / Card Number|Mobile Number|Email|Issued For|Commences On|Expires On|Amount Type|Payment Frequency|Minimum Amount|Maximum Amount|Currency Code|First Initiation Date|Frequency Parameter|Image File Name| | | |RCMS|ACK / NAK|Action|Accept / Reject|Reason of Rejection + Additional Comments of rejection reason'+
            '17-DEC-2022|New Registration|81600XXXX|78419759135XXXX||Individual|NID|78419759135XXXX|Abu Dhabi Islamic Bank|SALMA XXXX|Current|AE10050000000002816XXXX|||Previous Service Installment|28/11/2022|13/11/2027|Fixed|M|7222.33|7222.33|AED|29/11/2022||772825-78419759135XXXX-16092022.pdf||||NA|ACK|INITIATED|Accept|';
        ddt2.TransactionStatus__c = 'Approved';
        ddt2.DDResponsefiletype__c = 'Registration AckNack';
        update ddt2; 
        Test.stopTest();
    }
    
      @isTest
    public static void parseResponse2() {
        Test.startTest();
        
          DirectDebitRequest__c ddr = [SELECT Id From DirectDebitRequest__c Limit 1];
        
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
        insert ddt;
        
         DDTransaction__c ddt11 = TestObjectsFactory.createDDTransactions(ddr.id, 'Abu Dhabi Islamic Bank');
        insert ddt11;
        
         DirectDebitRequest__c ddr2 = [SELECT Id From DirectDebitRequest__c Limit 1];
       
        Document__c document2 = TestObjectsFactory.getDDRDocument(ddr2.id);
        insert document2;
        
        DDTransaction__c ddt2 = TestObjectsFactory.createDDTransactions(ddr2.id, 'First Abu Dhabi Bank');
        insert ddt2; 
        
        
        TriggerHandler.processedIds = new Set<Id>();
      
        ddt.DDResponse__c ='DACDR,0033102202146GDQ,000001,3002202140001885,000001,ACCP,940000256,510051,IN,PASSP-567485965120051,401,003,Sushank Malik,+971526027725,s.malik@provis.ae,C,AE850030000961092920001,2022-01-01,0,2022-12-30,F,M,0,100.00,100.00,P,,94000025682022000001089,0033000211330941.pdf,UAEDDS';
        ddt.TransactionStatus__c = 'Sent to Bank';
        ddt.DDResponsefiletype__c = 'Registration Response';
        update ddt;
      
        
        ddt2.DDResponse__c = 'Date Processed|Request Type|OIC|Payer Identification|DDA Reference|Customer Type|Customer ID Type|Customer ID Number|Bank Name|Title of Account|Account Type|IBAN / Card Number|Mobile Number|Email|Issued For|Commences On|Expires On|Amount Type|Payment Frequency|Minimum Amount|Maximum Amount|Currency Code|First Initiation Date|Frequency Parameter|Image File Name| | | |RCMS|ACK / NAK|Action|Accept / Reject|Reason of Rejection + Additional Comments of rejection reason'+
            '17-DEC-2022|New Registration|81600XXXX|78419759135XXXX||Individual|NID|78419759135XXXX|Abu Dhabi Islamic Bank|SALMA XXXX|Current|AE10050000000002816XXXX|||Previous Service Installment|28/11/2022|13/11/2027|Fixed|M|7222.33|7222.33|AED|29/11/2022||772825-78419759135XXXX-16092022.pdf||||NA|ACK|INITIATED|Accept|';
        ddt2.TransactionStatus__c = 'Approved';
        ddt2.DDResponsefiletype__c = 'Registration Response';
        update ddt2; 
        Test.stopTest();
    }
    
    @isTest
    public static void parseResponse3(){
        test.startTest();
       
        DirectDebitRequest__c ddr = [SELECT Id From DirectDebitRequest__c Limit 1];
        SalesOrder__c salesOrder1 = [SELECT Id From SalesOrder__c Limit 1];
        Account acc = [SELECT Id From Account Limit 1];
        Opportunity opp = [SELECT Id From Opportunity Limit 1];
        
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
        
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder1.Id, acc.Id, opp.Id, 'Credit Card');
        receiptAcknowledgement.ChequeReceived__c = false;
        insert receiptAcknowledgement;
        
        DDTransaction__c ddt = TestObjectsFactory.createDDTransactions(ddr.id, 'Abu Dhabi Commercial Bank');
        ddt.TransactionStatus__c = 'Approved';
       // ddt.DDResponsefiletype__c = 'Collection Response';
        ddt.Requesttype__c = 'Collection';
        ddt.Receipt_Acknowledgement__c = receiptAcknowledgement.Id;
        insert ddt;
        
        DDTransaction__c ddt2 = TestObjectsFactory.createDDTransactions(ddr.id, 'Abu Dhabi Commercial Bank');
        ddt2.TransactionStatus__c = 'ACK';
       // ddt.DDResponsefiletype__c = 'Collection Response';
        ddt2.Requesttype__c = 'New Registration';
        
        insert ddt2;
        
        DDTransactionResponseHandler.updateDDRStatus(new List<DDTransaction__c>{ddt, ddt2});
        test.stopTest();
    }
    @isTest
    public static void parseResponse4(){
       
        test.startTest();
       
       DirectDebitRequest__c ddr = [SELECT Id From DirectDebitRequest__c Limit 1];
        
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
        
        DDTransaction__c ddt2 = TestObjectsFactory.createDDTransactions(ddr.id, 'Abu Dhabi Commercial Bank');
        ddt2.TransactionStatus__c = 'ACK';
        ddt2.Requesttype__c = 'New Registration';
        
        insert ddt2;
        
        DDTransaction__c ddt3 = TestObjectsFactory.createDDTransactions(ddr.id, 'Abu Dhabi Commercial Bank');
        ddt3.TransactionStatus__c = 'ACK';
        ddt3.Requesttype__c = 'Cancellation';
        insert ddt3;
        
        DDTransaction__c ddt4 = TestObjectsFactory.createDDTransactions(ddr.id, 'Abu Dhabi Commercial Bank');
        ddt4.TransactionStatus__c = 'Rejected';
        ddt4.Requesttype__c = 'Cancellation';
        insert ddt4;
        
        DDTransaction__c ddt5 = TestObjectsFactory.createDDTransactions(ddr.id, 'Abu Dhabi Commercial Bank');
        ddt5.TransactionStatus__c = System.Label.SenttoBank;
        ddt5.Requesttype__c = 'Cancellation';
        insert ddt5;
        
        DDTransactionResponseHandler.updateDDRStatus(new List<DDTransaction__c>{ddt2, ddt3});
        test.stopTest();
    }
    
    @isTest
    public static void testDDTADIB() {
        Test.startTest();
        DirectDebitRequest__c ddr = [SELECT Id From DirectDebitRequest__c Limit 1];
        
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
        
        
        DDTransaction__c ddt = TestObjectsFactory.createDDTransactions(ddr.id, 'Abu Dhabi Islamic Bank');
        insert ddt;        
        TriggerHandler.processedIds = new Set<Id>();
        
        Test.stopTest();
    }
}