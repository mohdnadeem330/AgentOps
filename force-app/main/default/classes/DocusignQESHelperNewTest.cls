@isTest
public class DocusignQESHelperNewTest 
{
    @testSetup 
    static void setupData()
    {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ResidentStatus__pc = 'Resident';
        insert acc;

        Account acc2 = TestObjectsFactory.getPersonAccountRecord();
        insert acc2;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.OwnerSharePercentage__c = 10;
        insert salesOrder;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, acc2.Id, 'Friend Of');
        insert jointOwner;
    }
    
    @isTest 
    static void testDocusignQESNew() 
    {
        Account accRecord = [select id,ResidentStatus__pc,AccountNumber__c,IsPersonAccount,FirstName,LastName,PersonEmail, (SELECT Id,FirstName, LastName FROM Contacts) from Account limit 1];
        Opportunity optyRecord = [select id,AccountId from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        Project__c projectRecord= [select id from Project__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        salesOrderRecord.SellingPrice__c=1000000;
        salesOrderRecord.ExternalCommissionAmount__c=10000;
        salesOrderRecord.Status__c = Constants.UNIT_STATUS_SOLD;
        salesOrderRecord.Account__c=optyRecord.AccountId;
        salesOrderRecord.ReceiptAcknowledgementPaymentMethod__c='Online';
        salesOrderRecord.RAcknowledgementReservationAmount__c=10000;
        salesOrderRecord.SubStatus__c = Constants.STATUS_APPROVED;
        insert salesOrderRecord;
        
        DownloadSODocsController.fetchAllDocumentIDs(salesOrderRecord.Id);
        SalesOrderTriggerHandler.createSalesOrderDocuments(new Map<Id,SalesOrder__c>([SELECT Id,Account__c,Status__c,RecordTypeId,Opportunity__c FROM SalesOrder__c WHERE Id=:salesOrderRecord.Id]));
            
        Document__c docRec = [select id,SalesOrder__c,DocumentType__c,ExpressionofInterest__c,Status__c,Identityverification__c,SalesOrder__r.UnitNumber__c from Document__c where SalesOrder__c=:salesOrderRecord.Id and DocumentType__c!=:Constants.DOCUMENT_TYPE_RA LIMIT 1];
        docRec.Identityverification__c = true;
        update docRec;
        ContentVersion cv=new Contentversion();
        cv.title='ABC';
        cv.PathOnClient ='test';
        Blob b=Blob.valueOf('Unit Test Attachment Body');
        cv.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body');
        insert cv;
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=docRec.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: cv.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        
        insert contentlink;
        map<id,id> documentToContentVersionID = new map<id,id>();
        for(ContentDocumentLink conDocLink : [select id,ContentDocumentId,ContentDocument.LatestPublishedVersionId,LinkedEntityId from ContentDocumentLink where LinkedEntityId = :docRec.Id]){
            documentToContentVersionID.put(conDocLink.LinkedEntityId,conDocLink.ContentDocument.LatestPublishedVersionId);
        }
        Map<Id,ContentVersion> contentVersionMap = new Map<Id,ContentVersion>([SELECT Id,FileType, Title, ContentDocumentId From ContentVersion where Id IN :documentToContentVersionID.values() ]);
        
        List<JointOwner__c> jointOwnerList = new List<JointOwner__c>();
        jointOwnerList = [SELECT Id,Account__c,Account__r.AccountNumber__c,Account__r.Name,Account__r.isPersonAccount,Account__r.ResidentStatus__pc,FirstName__c,MiddleName__c,LastName__c,JointOwnerFullName__c,City__c,Salutation__c,Nationality__c,Passport__c,Email__c,MobileNumber__c,Phone__c,Country__c,Suffix__c,UAEID__c,SharePercentage__c  
                          FROM JointOwner__c WHERE  SalesOrder__c =:salesOrderRecord.Id ];
        
        String relatedsObjectId  = docRec.SalesOrder__c;

        
        Test.startTest();
        DocusignQESHelperNew.sendForQESSignatureFuture(docRec.Id,relatedsObjectId,accRecord.Id,docRec.Id,'');
        //	DocusignQESHelperNew.prepareQESEnvelope(docRec, false,relatedsObjectId, accRecord,cv,jointOwnerList,false);
        Test.stopTest();
        
    }
    
    
     @isTest 
    static void testDocusignQESNew2() 
    {
        Account accRecord = [select id,ResidentStatus__pc,AccountNumber__c,IsPersonAccount,FirstName,LastName,PersonEmail, (SELECT Id,FirstName, LastName FROM Contacts) from Account limit 1];
        Opportunity optyRecord = [select id,AccountId from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        Project__c projectRecord= [select id from Project__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        salesOrderRecord.SellingPrice__c=1000000;
        salesOrderRecord.ExternalCommissionAmount__c=10000;
        salesOrderRecord.Status__c = Constants.UNIT_STATUS_SOLD;
        salesOrderRecord.Account__c=optyRecord.AccountId;
        salesOrderRecord.ReceiptAcknowledgementPaymentMethod__c='Online';
        salesOrderRecord.RAcknowledgementReservationAmount__c=10000;
        salesOrderRecord.SubStatus__c = Constants.STATUS_APPROVED;
        insert salesOrderRecord;
        
        DownloadSODocsController.fetchAllDocumentIDs(salesOrderRecord.Id);
        SalesOrderTriggerHandler.createSalesOrderDocuments(new Map<Id,SalesOrder__c>([SELECT Id,Account__c,Status__c,RecordTypeId,Opportunity__c FROM SalesOrder__c WHERE Id=:salesOrderRecord.Id]));

        Document__c docRec = [select id,SalesOrder__c,DocumentType__c,ExpressionofInterest__c,Status__c,Identityverification__c,SalesOrder__r.UnitNumber__c from Document__c where SalesOrder__c=:salesOrderRecord.Id and DocumentType__c!=:Constants.DOCUMENT_TYPE_RA LIMIT 1];
//        docRec.Identityverification__c = true;
//        update docRec;
        ContentVersion cv=new Contentversion();
        cv.title='ABC';
        cv.PathOnClient ='test';
        Blob b=Blob.valueOf('Unit Test Attachment Body');
        cv.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body');
        insert cv;
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=docRec.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: cv.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        
        insert contentlink;
        map<id,id> documentToContentVersionID = new map<id,id>();
        for(ContentDocumentLink conDocLink : [select id,ContentDocumentId,ContentDocument.LatestPublishedVersionId,LinkedEntityId from ContentDocumentLink where LinkedEntityId = :docRec.Id]){
            documentToContentVersionID.put(conDocLink.LinkedEntityId,conDocLink.ContentDocument.LatestPublishedVersionId);
        }
        Map<Id,ContentVersion> contentVersionMap = new Map<Id,ContentVersion>([SELECT Id,FileType, Title, ContentDocumentId From ContentVersion where Id IN :documentToContentVersionID.values() ]);
        
        List<JointOwner__c> jointOwnerList = new List<JointOwner__c>();
        jointOwnerList = [SELECT Id,Account__c,Account__r.AccountNumber__c,Account__r.Name,Account__r.isPersonAccount,Account__r.ResidentStatus__pc,FirstName__c,MiddleName__c,LastName__c,JointOwnerFullName__c,City__c,Salutation__c,Nationality__c,Passport__c,Email__c,MobileNumber__c,Phone__c,Country__c,Suffix__c,UAEID__c,SharePercentage__c  
                          FROM JointOwner__c WHERE  SalesOrder__c =:salesOrderRecord.Id ];
        
        String relatedsObjectId  = docRec.SalesOrder__c;

        
        Test.startTest();
        DocusignQESHelperNew.sendForQESSignatureFuture(docRec.Id,relatedsObjectId,accRecord.Id,docRec.Id,'');
        //	DocusignQESHelperNew.prepareQESEnvelope(docRec, false,relatedsObjectId, accRecord,cv,jointOwnerList,false);
        Test.stopTest();
        
    }
    

}