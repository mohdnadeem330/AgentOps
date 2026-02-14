@isTest
public class BatchToDirectDebitCalloutTest {

    @isTest
    public static void BatchToDirectDebitCalloutExecute() {
       Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;
        
        SalesOrder__c salesOrder= TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        DirectDebitRequest__c ddr = TestObjectsFactory.createDirectDebitRecords(salesOrder.id);
        ddr.PayerAccount__c = acc.id;
        insert ddr;
        
        Document__c document = TestObjectsFactory.getDDRDocument(ddr.id);
        insert document;
        
        DDTransaction__c ddt = TestObjectsFactory.createDDTransactions(ddr.id, 'Abu Dhabi Commercial Bank');
        insert ddt;
        
        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        insert content;
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId = ddt.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        BatchToDirectDebitCallout batch = new BatchToDirectDebitCallout();
        database.executeBatch(batch);
        String requestBody = '{"ddsRequest": [{"soReferenceNumber": "OU#00000173", "fileName_req": "C300003-360000067-270423-000101.txt","fileName_pdf": "C300003-360000067-270423-000101.pdf", "fileExtention_req": "TEXT", "fileExtention_pdf": "PDF", "ddTransactionStatus": "Unprocessed","ddTransactionNumber": "DDT-000101", "ddTransactionId": "'+ddt.id+'","ddResponseFileName": "050003C3100033002305010101.DDR","ddRequestType": "New Registration","ddrequestNumber": "DDT-000101","ddBankingReferenceNumber": "00331023510101","ddBank": "First Abu Dhabi Bank","base64_req": "UmVxdWVzdCBUeX", "base64_pdf":  "UmVxdWVzdCBUeX" }]}';
        String jsonInput = '{ "applicationName": "x-ald-sferp-api",  "success": true,  "statusCode": "201",  "correlationId": "55881770-e7e6-11ed-8eb8-067717201602",  "results": { "ddsRes": [{ "sfRequestId": "55881770-e7e6-11ed-8eb8-067717201602", "ddTransactionId": "'+ddt.id+'", "status": "Failure","errorMsg": "Error while creating DD ,Error:Exception :ORA-00001: unique constraint (XXCONV.SFDDSINT_PK) violated"} ]}}';
        BatchToDirectDebitCalloutHelper.updateDDTransaction(jsonInput, new List<Id>{ddt.id}, requestBody);
        Test.stopTest();
    }
    
    public class MockHttpResponseGenerator implements HttpCalloutMock{
        DDTransaction__c ddt = [Select Id from DDTransaction__c limit 1];
       
        public HTTPResponse respond(HTTPRequest req){   
            HttpResponse res = new HttpResponse();
            String jsonInput = '{ "applicationName": "x-ald-sferp-api",  "success": true,  "statusCode": "201",  "correlationId": "55881770-e7e6-11ed-8eb8-067717201602",  "results": { "ddsRes": [{ "sfRequestId": "55881770-e7e6-11ed-8eb8-067717201602", "ddTransactionId": "'+ddt.id+'", "status": "Success","errorMsg": ""} ]}}';
            res.setHeader('Content-Type', 'application/json');
            res.setBody(jsonInput);            
            res.setStatusCode(200);
            return res;
        }
    }
}