/**
* DownloadSODocsControllerTest
*
* Test class for DownloadSODocsController
*/
@isTest
private class DownloadSODocsControllerTest{
    // create setup data
     @testSetup static void setupData() {
       
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;
       
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        //Test.startTest();
        //UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        //insert r;
        
        
        User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
        agencyAdminUser.contactId=conRecord.Id;
        //agencyAdminUser.UserRoleId = r.Id;
       // insert agencyAdminUser;
         
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        system.debug('acc insert :'+acc);
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
        OpportunityUnitSearchController.uploadFile(Blob.valueOf('Test').toString(),docRecord.DocumentType__c,docRecord.id);
        
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        insert unitrecord;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        paymentPlanRecord.IsActive__c =Constants.YES;
        update paymentPlanRecord;
        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
        insert buldingPaymentMapping;    
        
        OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(buildingRecord.Id,projectRecord.Id);
        insert offerRecord;
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        insert offerLine;
    }
    //Test SO Esign
    @isTest static void testEsign() {
         test.startTest();
        
        Account accRecord = [select id from Account limit 1];
        Opportunity optyRecord = [select id,AccountId from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        Project__c projectRecord= [select id from Project__c limit 1];
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        //salesOrderRecord.Project__c=projectRecord.Id;
        salesOrderRecord.SellingPrice__c=1000000;
        salesOrderRecord.ExternalCommissionAmount__c=10000;
        salesOrderRecord.Status__c = Constants.UNIT_STATUS_SOLD;
        salesOrderRecord.Account__c=optyRecord.AccountId;
        salesOrderRecord.ReceiptAcknowledgementPaymentMethod__c='Online';
        salesOrderRecord.RAcknowledgementReservationAmount__c=10000;
        salesOrderRecord.SubStatus__c = Constants.STATUS_APPROVED;
        insert salesOrderRecord;
        
        DownloadSODocsController.fetchAllDocumentIDs(salesOrderRecord.Id);
        
        list<Document__c> docsToCOmplete = [select id,SalesOrder__c,DocumentType__c,ExpressionofInterest__c,Status__c from Document__c where SalesOrder__c=:salesOrderRecord.Id and DocumentType__c!=:Constants.DOCUMENT_TYPE_RA];
        if(docsToCOmplete.size() > 0){
            DownloadSODocsController.sendForESign(docsToCOmplete[0].id); 
        }
        docsToCOmplete = [select id,SalesOrder__c,DocumentType__c,ExpressionofInterest__c,Status__c from Document__c where SalesOrder__c=:salesOrderRecord.Id and DocumentType__c=:Constants.DOCUMENT_TYPE_RA];
        if(docsToCOmplete.size() > 0){
            DownloadSODocsController.sendForESign(docsToCOmplete[0].id); 
        }
        
       
            try{
                dfsle.TestUtils.setMock(new dfsle.ESignatureAPIMock());        
                docsToCOmplete = [select id,SalesOrder__c,DocumentType__c,ExpressionofInterest__c,Status__c from Document__c where SalesOrder__c=:salesOrderRecord.Id and DocumentType__c=:Constants.DOCUMENT_TYPE_RA];
//                System.assertEquals(docsToCOmplete.isEmpty(),false);
                list<Id> raDocId=new list<Id>();    
                for(Document__c doc : docsToCOmplete){
                    OpportunityUnitSearchController.uploadFile(Blob.valueOf('Test').toString(),doc.DocumentType__c,doc.id);
                    raDocId.add(doc.id);
                }
                if(!raDocId.isEmpty()){
                    DownloadSODocsController.sendForESign(raDocId[0]); 
                }
            }catch(dfsle.ValidationException e){}
            
        test.stoptest();
    }
    
     //Test SO Esign
     
    @isTest static void testEsign2() {
        Account accRecord = [select id from Account limit 1];
        Opportunity optyRecord = [select id,AccountId from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        Project__c projectRecord= [select id from Project__c limit 1];
        test.startTest();
        
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        //salesOrderRecord.Project__c=projectRecord.Id;
        salesOrderRecord.SellingPrice__c=1000000;
        salesOrderRecord.ExternalCommissionAmount__c=10000;
        salesOrderRecord.Status__c = Constants.UNIT_STATUS_SOLD;
        salesOrderRecord.Account__c=optyRecord.AccountId;
        salesOrderRecord.ReceiptAcknowledgementPaymentMethod__c='Online';
        salesOrderRecord.RAcknowledgementReservationAmount__c=10000;
        salesOrderRecord.SubStatus__c = Constants.STATUS_APPROVED;
        insert salesOrderRecord;
        
        DownloadSODocsController.fetchAllDocumentIDs(salesOrderRecord.Id);
        list<Document__c> docsToUpdate = new List<Document__c>();
        for(Document__c doc : [select id,SalesOrder__c,DocumentType__c,ExpressionofInterest__c,Status__c,SPAValidation__c,Document_Verified__c from Document__c where SalesOrder__c=:salesOrderRecord.Id]){
            doc.Identityverification__c = true;       
            docsToUpdate.add(doc);
        }
        Update docsToUpdate;
        
 List<Document__c> docsToComplete = [SELECT Id, SalesOrder__c, DocumentType__c, ExpressionofInterest__c, Status__c FROM Document__c WHERE SalesOrder__c = :salesOrderRecord.Id AND DocumentType__c != :Constants.DOCUMENT_TYPE_RA];
        System.debug('+++ docsToComplete: ' + docsToComplete);



        
        //list<Document__c> docsToCOmplete = [select id,SalesOrder__c,DocumentType__c,ExpressionofInterest__c,Status__c from Document__c where SalesOrder__c=:salesOrderRecord.Id and DocumentType__c!=:Constants.DOCUMENT_TYPE_RA];
        system.debug('+++ docsToCOmplete '+docsToCOmplete);
        DownloadSODocsController.getDocumentDetails(docsToCOmplete[0].id);
        
        DownloadSODocsController.regenerateAllDocuments(docsToCOmplete[0].SalesOrder__c);

        if(docsToCOmplete.size() > 0){
            DownloadSODocsController.sendForESign(docsToCOmplete[0].id); 
        }
        docsToCOmplete = [select id,SalesOrder__c,DocumentType__c,ExpressionofInterest__c,Status__c from Document__c where SalesOrder__c=:salesOrderRecord.Id and DocumentType__c=:Constants.DOCUMENT_TYPE_RA];
        system.debug('+++ docsToCOmplete 2 '+docsToCOmplete);
//        if(docsToCOmplete.size() > 0){
            DownloadSODocsController.sendForESign(docsToCOmplete[0].id); 
//         }
        salesOrderRecord.NetAmount__c = 600000000;
        Update salesOrderRecord;
        //test.startTest();
            try{
                dfsle.TestUtils.setMock(new dfsle.ESignatureAPIMock());        
                docsToCOmplete = [select id,SalesOrder__c,DocumentType__c,ExpressionofInterest__c,Status__c from Document__c where SalesOrder__c=:salesOrderRecord.Id and DocumentType__c=:Constants.DOCUMENT_TYPE_RA];
//                System.assertEquals(docsToCOmplete.isEmpty(),false);
                list<Id> raDocId=new list<Id>();    
                for(Document__c doc : docsToCOmplete){
                    OpportunityUnitSearchController.uploadFile(Blob.valueOf('Test').toString(),doc.DocumentType__c,doc.id);
                    raDocId.add(doc.id);
                }
                if(!raDocId.isEmpty()){
                    DownloadSODocsController.sendForESign(raDocId[0]); 
                }
            }catch(dfsle.ValidationException e){}
            
        test.stoptest();
    }
   

    
    //Test EOI Esign
    @isTest static void testEsignEOI() {
        Account accRecord = [select id from Account limit 1];
        Opportunity optyRecord = [select id,AccountId from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        Project__c projectRecord= [select id from Project__c limit 1];
        BuildingSection__c buildingRecord= [select id from BuildingSection__c limit 1];
        OpportunityEOI__c eoiRecord= new OpportunityEOI__c ();
        eoiRecord.Account__c = optyRecord.AccountId;
        eoiRecord.BuildingSectionName__c =buildingRecord.Id;
        eoiRecord.Opportunity__c =optyRecord.Id;
        eoiRecord.PaymentMode__c ='Online';
        eoiRecord.InterestFee__c=100;
        eoiRecord.ProjectName__c = projectRecord.Id; 
        eoiRecord.UnitModel__c=OpportunityEOI__c.UnitModel__c.getDescribe().getPicklistValues()[0].getValue();
        eoiRecord.PriceRangeFrom__c=100000;
        eoiRecord.PriceRangeTo__c=10000000;
        eoiRecord.UnitFeatures__c=OpportunityEOI__c.UnitFeatures__c.getDescribe().getPicklistValues()[0].getValue();
        insert eoiRecord;
        
        test.startTest();
            try{
                dfsle.TestUtils.setMock(new dfsle.ESignatureAPIMock());
                list<Document__c> docsToCOmplete = [select id,SalesOrder__c,DocumentType__c,ExpressionofInterest__c,Status__c from Document__c where ExpressionofInterest__c=:eoiRecord.Id and DocumentType__c='EOI Agreement'];
//                System.assertEquals(docsToCOmplete.isEmpty(),false);
                list<Id> raDocId=new list<Id>();    
                for(Document__c doc : docsToCOmplete){
                    OpportunityUnitSearchController.uploadFile(Blob.valueOf('Test').toString(),doc.DocumentType__c,doc.id);
                    raDocId.add(doc.id);
                }
                if(!raDocId.isEmpty()){
                   DownloadSODocsController.sendForESign(raDocId[0]); 
                }
            }catch(dfsle.ValidationException e){} 
            
        test.stoptest(); 
    }


    @IsTest
    static void sendForEsignResaleTest(){
        
        
        
        Unit__c unitrecord = TestObjectsFactory.unitDataSetup('25083');
        unitrecord.Status__c = 'Sold';
        unitrecord.Name = 'Test';
        unitrecord.CompletionDate__c = System.today().addDays(7);
        insert unitrecord;
        Project__c pj = new Project__c();
        pj.EligibleforResale__c = true;
        pj.Id= unitrecord.Project__c;
        update pj;
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
		
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@gmail.com';
        con.PrimaryContact__c = true;
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        test.startTest();
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.ID,acc.Id);
        salesOrderRecord.Unit__c = unitrecord.Id;
        salesOrderRecord.Contact__c = con.Id;
        salesOrderRecord.NetAmount__c = 1000;
        salesOrderRecord.Status__c = 'Sold';
        insert salesOrderRecord;

        Case caseRecord = TestObjectsFactory.getCaseRecord(ResaleConstants.Resale_Case_RecordTypeId, Constants.PAYMENT_EXTENSION_TYPE, unitrecord.Id, 'Phone');
        caseRecord.Subject = 'Test Subject';
        caseRecord.Unit__c = unitrecord.Id;
        insert caseRecord;

        caseRecord.CustomerContacted__c = true;
        caseRecord.Status = 'Property Listed';
        update caseRecord;
        
        Opportunity resaleOpp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        resaleOpp.Unit__c = unitrecord.Id;
        resaleOpp.Lead_Type__c = 'Resale';
        resaleOpp.StageName = 'Meeting';
        resaleOpp.RecordTypeId = ResaleConstants.Resale_Opp_RecordTypeId;
        insert resaleOpp;

        Document__c docRecord1= new Document__c(Opportunity__c=resaleOpp.Id,DocumentType__c= 'Listing MOU' );
        insert docRecord1;
        
         Document__c docRecord2= new Document__c(Opportunity__c=resaleOpp.Id,
                                                 DocumentType__c = Constants.DOCUMENT_TYPE_PREFIX_SIGNED+' '+'Listing MOU');
        insert docRecord2;

        ContentVersion cv = TestObjectsFactory.getContentVersion();
        insert cv;
        ContentDocumentLink cdl = TestObjectsFactory.insertContentDocumentLink(docRecord1.Id, cv.Id);
        TriggerHandler.processedIds = new Set<Id>();

        DownloadSODocsController.sendForESign(docRecord1.Id);
        DownloadSODocsController.sendForESignResale(docRecord1.Id,resaleOpp.Id,docRecord2.Id);
        test.stoptest(); 
    }


    @IsTest
    static void sendForEsignResaleCaseTest(){
       
        Unit__c unitrecord = TestObjectsFactory.unitDataSetup('25083');
        unitrecord.Status__c = 'Sold';
        unitrecord.Name = 'Test';
        unitrecord.CompletionDate__c = System.today().addDays(7);
        insert unitrecord;
        Project__c pj = new Project__c();
        pj.EligibleforResale__c = true;
        pj.Id= unitrecord.Project__c;
        update pj;
        
       /* Account acc = TestObjectsFactory.getPersonAccountRecord();
        syste
        acc.NationalIdNumber__pc = '646464646464646446';
        system.debug('Existing accounts : '+[SELECT Id, NationalIdNumber__pc FROM Account]);
        system.debug('New account : '+acc.NationalIdNumber__pc);
        Insert acc;*/
        Account acc = [SELECT Id FROM Account WHERE PersonEmail = 'test@pwc.com' LIMIT 1];
        //Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        //insert acc; 

//        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
//        con.Email = 'ajay.thakur.tpr@gmail.com';
//        update con;
        test.startTest();
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.ID,acc.Id);
        salesOrderRecord.Unit__c = unitrecord.Id;
//        salesOrderRecord.Contact__c = con.Id;
        salesOrderRecord.NetAmount__c = 1000;
        salesOrderRecord.Status__c = 'Sold';
        insert salesOrderRecord;

        

        Case caseRecord = TestObjectsFactory.getCaseRecord(ResaleConstants.Resale_Case_RecordTypeId, Constants.PAYMENT_EXTENSION_TYPE, unitrecord.Id, 'Phone');
        caseRecord.Subject = 'Test Subject';
        caseRecord.Unit__c = unitrecord.Id;
        insert caseRecord;

        Document__c docRecord1= new Document__c(Case__c=caseRecord.Id,DocumentType__c='Listing Agreement' );
        insert docRecord1;
        Document__c docRecord2= new Document__c(Case__c=caseRecord.Id,DocumentType__c=ResaleConstants.CASE_SIGNED_LISTING_AGREEMENT_DOCUMENT_TYPE );
        insert docRecord2;

        ContentVersion cv = TestObjectsFactory.getContentVersion();
        insert cv;
        ContentDocumentLink cdl = TestObjectsFactory.insertContentDocumentLink(docRecord1.Id, cv.Id);
        TriggerHandler.processedIds = new Set<Id>();
		DownloadSODocsController.checkSignatureType(docRecord1.Id);
        DownloadSODocsController.sendFasttrackLink(docRecord1.Id);
        DownloadSODocsController.sendForESign(docRecord1.Id);
        DownloadSODocsController.sendForESignNew(docRecord1.Id,salesOrderRecord.Id,acc.Id,docRecord2.Id);
        DownloadSODocsController.sendForESignResale(docRecord1.Id,salesOrderRecord.Id,docRecord2.Id);
        test.stoptest(); 
    }
}