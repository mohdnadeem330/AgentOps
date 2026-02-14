@isTest
public with sharing class DocuSignUtilityTest {
    @TestSetup
    static void makeData(){
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        insert acc;

        List<Opportunity> oppToInsert = new List<Opportunity>();

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        oppToInsert.add(opp);
        Opportunity opp1 = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp1.LeadSource = Constants.WALK_IN;
        opp1.EnquiryCategory__c = 'Kiosk';
        opp1.EnquiryTrigger__c = 'Yas Mall Kiosk';
        oppToInsert.add(opp1);

        Opportunity opp2 = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp2.CustomerContactedBySM__c = true;
        oppToInsert.add(opp2);

        insert oppToInsert;

        TriggerHandler.processedIds = new Set<Id>();
        Opportunity oppDup = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert oppDup;

        TriggerHandler.processedIds = new Set<Id>();
        Project__c p= TestObjectsFactory.getProjectRecord('25083');
        insert p;
        Unit__c u = TestObjectsFactory.unitDataSetup(p.Id);        
        insert u;

        SalesOrder__c sa = TestObjectsFactory.getSalesOrderRecord(opp.Id,acc.Id);
        sa.Unit__c = u.Id;
        sa.Status__c = Constants.STATUS_RESERVATION_IN_PROGRESS;
        insert sa;

        TriggerHandler.processedIds = new Set<Id>();
        opp.ReservationApprovalStatus__c = Constants.STATUS_APPROVED;
		opp.StageName = Constants.STAGE_CLOSED_LOST;
        opp.LossReason__c = constants.OPPORTUNITY_LOST_PRICE;
        opp.LossComments__c = constants.OPPORTUNITY_LOST_PRICE;
		update opp;

        TriggerHandler.processedIds = new Set<Id>();
        opp.ReservationApprovalStatus__c = Constants.STATUS_REJECTED;
		update opp;
        
        Test.startTest();
        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(sa.Id, acc.Id, 'Spouse Of');
        insert jointOwner;
                
        Document__c document = TestObjectsFactory.getSalesOrderDocument(opp.Id,sa.Id);
        insert document;
        //ContentVersion conVer = TestObjectsFactory.getContentVersion();
        //insert conVer;
        //TestObjectsFactory.insertContentDocumentLink(document.Id, conVer.Id);
        ContentDocumentLink conLink = TestObjectsFactory.createContentDocumentLink(document.Id);
        Test.stopTest();
    }

    @IsTest
    static void sendQESSignature(){ 
        DocuSignWrapper.EnvelopeWrapper envWrapper = new DocuSignWrapper.EnvelopeWrapper();
        Document__c document = [SELECT Id FROM Document__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];       
        DocuSignWrapper.Signer signer1 = new DocuSignWrapper.Signer(acc.Id,acc.Id,'BUYER');
        DocuSignWrapper.Signer signer2 = new DocuSignWrapper.Signer(acc.Id,acc.Id,'SELLER');
        List<DocuSignWrapper.Signer> lstSigner = new List<DocuSignWrapper.Signer>(); 
        Test.startTest();
        envWrapper = DocuSignMapper.createEnvelopeWrapper(document.Id, lstSigner);
        envWrapper.isNormalSign = false;
            DocuSignUtility.sendQESSignature(envWrapper);
        Test.stopTest();
    }
   
    @IsTest
    static void sendQESSignatur2(){ 
        DocuSignWrapper.EnvelopeWrapper envWrapper = new DocuSignWrapper.EnvelopeWrapper();
        Document__c document = [SELECT Id FROM Document__c LIMIT 1];
        ContentVersion cv=new Contentversion();
        cv.title='ABC';
        cv.PathOnClient ='test';
        Blob b=Blob.valueOf('Unit Test Attachment Body');
        cv.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body');
        insert cv;
        Account acc = [SELECT Id FROM Account LIMIT 1];       
        Test.startTest();

        //envWrapper.templateId = 'test';
        envWrapper.documentRecordId = document.Id;
        envWrapper.contentVersion = cv;
		envWrapper.isNormalSign = true;
        envWrapper.relatedObjectId = acc.Id;
        DocuSignWrapper.RecipientTabs rt = new DocuSignWrapper.RecipientTabs();
        rt.recipientSignHolder = 'SignatureHolder'; 
        rt.recipientDateHolder = 'DateHolder';
        rt.recipientInitialHolder = 'InitialsHolder';
        rt.recipientNameHolder = 'NameHolder';

        DocuSignWrapper.RecipientWrapper rw = new DocuSignWrapper.RecipientWrapper();
        rw.name = 'Test';
        rw.email = 'av@g.com';
        rw.routingOrder = 1;
        rw.typeOfRecipient = 'PrimaryRecipient';
        rw.signatureType = 'Digital Signature';
        rw.role = 'ABC';
        rw.signerType = 'Signer';
        rw.recipientPlaceHolders = rt;
        envWrapper.recipients = new List<DocuSignWrapper.RecipientWrapper>{rw};

        DocuSignWrapper.Signer signer1 = new DocuSignWrapper.Signer(acc.Id,acc.Id,'BUYER');
        DocuSignWrapper.Signer signer2 = new DocuSignWrapper.Signer(acc.Id,acc.Id,'SELLER');
        List<DocuSignWrapper.Signer> lstSigner = new List<DocuSignWrapper.Signer>(); 
//        envWrapper = DocuSignMapper.createEnvelopeWrapper(document.Id, lstSigner);
//        envWrapper.isNormalSign = false;
            DocuSignUtility.sendQESSignature(envWrapper);
        Test.stopTest();
    }
    
       @IsTest
    static void sendQESSignatur4(){ 
        DocuSignWrapper.EnvelopeWrapper envWrapper = new DocuSignWrapper.EnvelopeWrapper();
        Document__c document = [SELECT Id FROM Document__c LIMIT 1];
        ContentVersion cv=new Contentversion();
        cv.title='ABC';
        cv.PathOnClient ='test';
        Blob b=Blob.valueOf('Unit Test Attachment Body');
        cv.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body');
        insert cv;
        Account acc = [SELECT Id FROM Account LIMIT 1];       
        Test.startTest();

        //envWrapper.templateId = 'test';
        envWrapper.documentRecordId = document.Id;
        envWrapper.contentVersion = cv;
		envWrapper.isNormalSign = true;
        envWrapper.relatedObjectId = acc.Id;
        DocuSignWrapper.RecipientTabs rt = new DocuSignWrapper.RecipientTabs();
        rt.recipientSignHolder = 'SignatureHolder'; 
        rt.recipientDateHolder = 'DateHolder';
        rt.recipientInitialHolder = 'InitialsHolder';
        rt.recipientNameHolder = 'NameHolder';

        DocuSignWrapper.RecipientWrapper rw = new DocuSignWrapper.RecipientWrapper();
        rw.name = 'Test';
        rw.email = 'av@g.com';
        rw.routingOrder = 1;
        rw.typeOfRecipient = 'PrimaryRecipient';
        rw.signatureType = 'Digital Signature';
        rw.role = 'ABC';
        rw.signerType = 'Signer';
        rw.recipientPlaceHolders = rt;
        envWrapper.recipients = new List<DocuSignWrapper.RecipientWrapper>{rw};

        DocuSignWrapper.Signer signer1 = new DocuSignWrapper.Signer(acc.Id,acc.Id,'BUYER');
        DocuSignWrapper.Signer signer2 = new DocuSignWrapper.Signer(acc.Id,acc.Id,'SELLER');
        List<DocuSignWrapper.Signer> lstSigner = new List<DocuSignWrapper.Signer>(); 
//        envWrapper = DocuSignMapper.createEnvelopeWrapper(document.Id, lstSigner);
//        envWrapper.isNormalSign = false;
            DocuSignUtility.sendQESSignature(envWrapper);
        Test.stopTest();
    }
     
      @IsTest
    static void sendQESSignatur3(){ 
        DocuSignWrapper.EnvelopeWrapper envWrapper = new DocuSignWrapper.EnvelopeWrapper();
        Document__c document = [SELECT Id FROM Document__c LIMIT 1];
        ContentVersion cv=new Contentversion();
        cv.title='ABC';
        cv.PathOnClient ='test';
        Blob b=Blob.valueOf('Unit Test Attachment Body');
        cv.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body');
        insert cv;
        Account acc = [SELECT Id FROM Account LIMIT 1];       
        Test.startTest();

        //envWrapper.templateId = 'test';
        envWrapper.documentRecordId = document.Id;
        envWrapper.contentVersion = cv;
		envWrapper.isNormalSign = false;
        envWrapper.relatedObjectId = acc.Id;
        DocuSignWrapper.RecipientTabs rt = new DocuSignWrapper.RecipientTabs();
        rt.recipientSignHolder = 'SignatureHolder'; 
        rt.recipientDateHolder = 'DateHolder';
        rt.recipientInitialHolder = 'InitialsHolder';
        rt.recipientNameHolder = 'NameHolder';
        List<DocuSignWrapper.RecipientWrapper> recList =  new List<DocuSignWrapper.RecipientWrapper>();
        DocuSignWrapper.RecipientWrapper rw = new DocuSignWrapper.RecipientWrapper();
        rw.name = 'Test';
        rw.email = 'av@g.com';
        rw.routingOrder = 1;
        rw.typeOfRecipient = 'PrimaryRecipient';
        rw.signatureType = 'Digital Signature';
        rw.role = 'ABC';
        rw.signerType = 'Signer';
        rw.recipientPlaceHolders = rt;
        recList.add(rw);
        
        DocuSignWrapper.RecipientWrapper rw2 = new DocuSignWrapper.RecipientWrapper();
        rw2.name = 'Test';
        rw2.email = 'av@g.com';
        rw2.routingOrder = 1;
        rw2.typeOfRecipient = 'PrimaryRecipient';
        rw2.signatureType = 'Digital Signature';
        rw2.role = 'ABC';
        rw2.signerType = 'Approver';
        rw2.recipientPlaceHolders = rt;
        recList.add(rw2);
        
         DocuSignWrapper.RecipientWrapper rw3 = new DocuSignWrapper.RecipientWrapper();
        rw3.name = 'Test';
        rw3.email = 'av@g.com';
        rw3.routingOrder = 1;
        rw3.typeOfRecipient = 'PrimaryRecipient';
        rw3.signatureType = 'Normal Signature';
        rw3.role = 'ABC';
        rw3.signerType = 'Approver';
        rw3.recipientPlaceHolders = rt;
        recList.add(rw3);
        envWrapper.recipients = recList;
        
        DocuSignWrapper.AldarSignatories ald = new DocuSignWrapper.AldarSignatories();
         ald.name = 'Test';
        ald.email = 'av@g.com';
        ald.routingOrder = 1;
        ald.typeOfRecipient = 'PrimaryRecipient';
        ald.signatureType = 'Normal Signature';
        ald.role = 'ABC';
        ald.signerType = 'Approver';
        ald.recipientPlaceHolders = rt;
        envWrapper.aldarSignatoryList = new List<DocuSignWrapper.AldarSignatories>{ald};

        DocuSignWrapper.Signer signer1 = new DocuSignWrapper.Signer(acc.Id,acc.Id,'BUYER');
        DocuSignWrapper.Signer signer2 = new DocuSignWrapper.Signer(acc.Id,acc.Id,'SELLER');
        List<DocuSignWrapper.Signer> lstSigner = new List<DocuSignWrapper.Signer>(); 
//        envWrapper = DocuSignMapper.createEnvelopeWrapper(document.Id, lstSigner);
//        envWrapper.isNormalSign = false;
            DocuSignUtility.sendQESSignature(envWrapper);
        Test.stopTest();
    }
}