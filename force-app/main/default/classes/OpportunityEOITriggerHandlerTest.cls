/**
* OpportunityEOITriggerHandlerTest
*
* Test class for OpportunityEOITriggerHandler
*/
@isTest
private class OpportunityEOITriggerHandlerTest{
    //Create test data
     @testSetup static void setupData() {
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;
       
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
        agencyAdminUser.contactId=conRecord.Id;
        insert agencyAdminUser;
        
         
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
         
         boolean eoiFlag= OpportunityEOIService.createOpportunityEOI(opp.Id,acc.Id,projectRecord.Id,buildingRecord.Id,OpportunityEOI__c.UnitModel__c.getDescribe().getPicklistValues()[0].getValue(),
                                                    '',OpportunityEOI__c.UnitFeatures__c.getDescribe().getPicklistValues()[0].getValue(),
                                                  'Online','','','1000','100000','1','1');
         eoiFlag= OpportunityEOIService.createOpportunityEOI(opp.Id,acc.Id,projectRecord.Id,buildingRecord.Id,OpportunityEOI__c.UnitModel__c.getDescribe().getPicklistValues()[0].getValue(),
                                                    '',OpportunityEOI__c.UnitFeatures__c.getDescribe().getPicklistValues()[0].getValue(),
                                                  'Online','','','1000','100000','1','1');
    }
    //Test EOI record
    @isTest static void testEOI() {
        
        list<OpportunityEOI__c> eoiList =[select id,Opportunity__r.AccountId,Opportunity__r.Contact__c,Opportunity__c,InterestFee__c,PaymentMode__c,NumberOfUnits__c,CreatedById from OpportunityEOI__c];
        System.assertEquals(eoiList.isEmpty(), false);
        eoiList[0].InterestFee__c=5;
        update eoiList;
        OpportunityEOITriggerHandler.createPaymentLink(eoiList);
        //eoiList[1].InterestFee__c=null;
        //update eoiList;
    }
    @isTest static void testEOIAgreementUpdate() {
        
        OpportunityEOI__c oei = [select id,ComplianceStatus__c,Account__c,Opportunity__r.AccountId,Opportunity__r.Contact__c,Opportunity__c,InterestFee__c,PaymentMode__c,CreatedById
                                          from OpportunityEOI__c WHERE ComplianceStatus__c != 'Cleared' Limit 1];
        
        Document__c doc1 = [SELECT Id, DocumentType__c, Status__c, ExpressionofInterest__c FROM Document__c WHERE 
                            DocumentType__c ='Signed EOI Agreement' Limit 1 ];      
               
        String base64 = Blob.valueOf('version 1').toString();
        String filename = 'Test';
        
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = doc1.id;
        cdl.ShareType = 'I';
        insert cdl;
        
        Account acc = [SELECT Id FROM Account WHERE Id =: oei.Account__c Limit 1];
        Document__c doc2 = [SELECT Id, DocumentType__c, Status__c, Account__c FROM Document__c WHERE 
                            DocumentType__c =: Constants.DOCUMENT_TYPE_SIGNED_KYC Limit 1 ];      

        String base64acc = Blob.valueOf('acc version 1').toString();
        String filenameacc = 'acc Test';
        
        ContentVersion cvacc = new ContentVersion();
        cvacc.VersionData = EncodingUtil.base64Decode(base64acc);
        cvacc.Title = filenameacc;
        cvacc.PathOnClient = filenameacc;
        insert cvacc;
        
        ContentDocumentLink cdlacc = new ContentDocumentLink();
        cdlacc.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cvacc.Id].ContentDocumentId;
        cdlacc.LinkedEntityId = doc2.id;
        cdlacc.ShareType = 'I';
        insert cdlacc;
        
        Test.startTest();
        OpportunityEOI__c oi = [select id,ComplianceStatus__c FROM OpportunityEOI__c WHERE Id=:oei.Id Limit 1];
        oei.ComplianceStatus__c = 'Cleared';
        update oei;        
        Test.stopTest();      
               
    }
}