@isTest
public class DocumentServiceTest {

    @IsTest public static void testDocumentService() {

        Set<String> categoryNames = new Set<String>();
        categoryNames.add('Activity');

        Id salesOrderDocument = Schema.getGlobalDescribe().get('Document__c').getDescribe().getRecordTypeInfosByDeveloperName().get('SalesOrderDocument').getRecordTypeId();

        Account account = TestObjectsFactory.getOrganisationAccountRecord('companyName', 'registrationNo');
        insert account;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(account.Id );
        insert opp;

        ProjectBudget__c projectBudget = TestObjectsFactory.getProjectBudget();
        insert projectBudget;
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        project.ProjectBudget__c = projectBudget.Id;
        insert project;

        Unit__c unit = TestObjectsFactory.unitDataSetup('Mayan');
        unit.Project__c = project.Id;
        unit.Name = 'MAYAN-B1-101095';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, account.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        insert salesOrder;

         BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(project.id);
         insert buildingRecord;
                  
         PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
         paymentPlanRecord.BrokerPortalFlag__c = false;
         insert paymentPlanRecord;

         list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
         insert installmentLines;

         paymentPlanRecord.IsActive__c =Constants.YES;
         update paymentPlanRecord;

         BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
         insert buldingPaymentMapping;    

         OffersPromotions__c getOfferPromotion = TestObjectsFactory.getOfferPromotion(buildingRecord.Id, project.Id);
         insert getOfferPromotion;         

        OpportunityEOI__c opportunityEOI = TestObjectsFactory.getOpportunityEOIRecord(opp.Id, 'POS');
        opportunityEOI.ProjectName__c = unit.Project__c;
        opportunityEOI.Account__c = account.Id;
        opportunityEOI.Opportunity__c = opp.Id;
        opportunityEOI.BuildingSectionName__c = unit.BuildingSectionName__c;
        opportunityEOI.UnitModel__c = '1BHK';
        opportunityEOI.PriceRangeFrom__c = 0;
        opportunityEOI.PriceRangeTo__c = 10000;
        opportunityEOI.UnitFeatures__c = 'Saadiyat';
		opportunityEOI.ComplianceStatus__c = 'Cleared'; 
        insert opportunityEOI;

        Test.startTest();
        
        Document__c gtc = TestObjectsFactory.getProjectDocument(project.Id);
       
        List<Document__c> documentInsert = new List<Document__c>();
        documentInsert.add(gtc); 
        
        Document__c gtc1 = TestObjectsFactory.getProjectDocument(project.Id);
        insert gtc1;
        
        Map<Id,Document__c> documentDetailMap = new Map<Id,Document__c>();
        documentDetailMap.put(gtc1.Id,gtc1);

        ContentVersion content = new ContentVersion(); 
        content.Title = 'Header_Picture1'; 
        content.PathOnClient = '/' + content.Title + '.jpg'; 
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData = bodyBlob; 
        content.origin = 'H';
        insert content;

        ContentDocumentLink contentlinkAccount = new ContentDocumentLink();
        contentlinkAccount.LinkedEntityId = account.id;
        contentlinkAccount.contentdocumentid = [select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlinkAccount.ShareType = 'I';
        contentlinkAccount.Visibility = 'AllUsers';               
        insert contentlinkAccount;
        
        ContentVersion content1 = new ContentVersion(); 
        content1.Title = 'Header_Picture1'; 
        content1.PathOnClient = '/' + content1.Title + '.jpg'; 
        Blob bodyBlob1 = Blob.valueOf('Unit Test ContentVersion Body'); 
        content1.VersionData = bodyBlob1; 
        content1.origin = 'H';
        insert content1;
        
        ContentDocumentLink contentlinkDocument = new ContentDocumentLink();
        contentlinkDocument.LinkedEntityId = gtc1.id;
        contentlinkDocument.contentdocumentid = [select contentdocumentid from contentversion where id =: content1.id].contentdocumentid;
        contentlinkDocument.ShareType = 'I';
        contentlinkDocument.Visibility = 'AllUsers';               
        insert contentlinkDocument;

        Set<Id> accountId = new Set<Id>();
        accountId.add(account.Id);

        Document__c docRecord = DocumentService.createDocumentRecord(opp.Id, opportunityEOI.Id, unit.Id, 'Trade License', salesOrder.Id, account.Id, salesOrderDocument);
        
        map<string,list<DocumentPlaceHolder__mdt>>  documentMetaDataByCategory = DocumentService.getDocumentMetaDataByCategory(categoryNames);
        
        DocumentService.insertDocumentRecords(documentInsert);

        Map<Id,List<Document__c>> documentbyAccountId = DocumentService.getDocumentbyAccountId(accountId);
        
        Map<Id,DocumentQueryModel> documentDetails = DocumentService.getDocumentDetails(documentDetailMap);
        
        DocumentQueryModel documentQueryModel = DocumentService.uploadFileToParentRecord(gtc1, 'Title', bodyBlob);

        String fileURL = DocumentService.getFileURL(content.Id);

        map<String,list<DocumentService.PublicLinkDetails>> projectPaymentPlanDetailsRecords = DocumentService.getProjectPaymentPlanDetailsRecords(project.Id, false);

        map<String,list<DocumentService.PublicLinkDetails>> getProjectOfferDetailsRecords = DocumentService.getProjectOfferDetailsRecords(project.Id, false);

        List<Document__c> soDocs = DocumentService.getSalesOrderDocuments(salesOrder.Id);

        Document__c Docs = DocumentService.getDocumentRecordById(gtc.Id);
		
        DocumentService.regenerateAllDocuments(salesOrder.Id);

        Test.stopTest();
    }
}