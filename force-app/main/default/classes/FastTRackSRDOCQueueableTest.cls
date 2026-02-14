@isTest
public class FastTRackSRDOCQueueableTest {
	@testSetup
    static void makeData(){
        Id personAccountRecordTypeId=utilities.getRecordTypeId('Account','Person Account');
        Account customerAcc = new Account();
        customerAcc.FirstName='Test';
        customerAcc.LastName= 'Agni';
        customerAcc.PersonEmail='agni@gmail.com';
        customerAcc.RecordTypeId = personAccountRecordTypeId;
        insert customerAcc;
        
        Account buyerAcc = new Account();
        buyerAcc.FirstName='Test';
        buyerAcc.LastName= 'Drogo';
        buyerAcc.PersonEmail='drogo@gmail.com';
        buyerAcc.RecordTypeId = personAccountRecordTypeId;
        buyerAcc.FastTrackedAccount__c = true;
        buyerAcc.FasttrackCompletionDate__c = System.now();
        insert buyerAcc;
        
        HexaBPM__SR_Status__c submittedStatus = new HexaBPM__SR_Status__c();
        submittedStatus=TestObjectsFactory.getSRStatus('Submitted');
        insert submittedStatus;
        
        HexaBPM__SR_Status__c cancelledStatus = new HexaBPM__SR_Status__c();
        cancelledStatus=TestObjectsFactory.getSRStatus('Cancelled');
        insert cancelledStatus;
        
        Project__c project=TestObjectsFactory.getProjectRecord('recordId');
        insert project;
        
        list<Unit__c> units = new list<unit__c>();
        unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.Name = 'MAYAN-B1-1004'; 
        unit.Project__c= project.Id;
        insert unit;
        
        Id PropertyTransferNOCRTId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer NOC');
        
        HexaBPM__SR_Template__c PTNSRTemplate = new HexaBPM__SR_Template__c();
        PTNSRTemplate.HexaBPM__Active__c = true;
        PTNSRTemplate.HexaBPM__SR_RecordType_API_Name__c = 'Property Transfer NOC';
        insert PTNSRTemplate;
        
        Document__c nationalIdDoc = new Document__c();
        nationalIdDoc.Account__c = buyerAcc.Id;  
        nationalIdDoc.DocumentType__c = 'National ID Front Copy';
        insert nationalIdDoc;
        
        
        system.debug('nationalIdDoc'+nationalIdDoc.Id);
        
        Document__c nationalIdDocSeller = new Document__c();
        nationalIdDocSeller.Account__c = customerAcc.Id;  
        nationalIdDocSeller.DocumentType__c = 'National ID Front Copy';
        insert nationalIdDocSeller;
        system.debug('nationalIdDocSeller'+nationalIdDocSeller.Id);
        //change 31-12-2024
        Document__c nationalIdBackDocBuyer = new Document__c();
        nationalIdBackDocBuyer.Account__c = buyerAcc.Id;  
        nationalIdBackDocBuyer.DocumentType__c = 'National ID Back Copy';
        insert nationalIdBackDocBuyer;
        
        system.debug('nationalIdDocSeller'+nationalIdDocSeller.Id);
        
        
        Document__c passportDoc = new Document__c();
        passportDoc.Account__c = buyerAcc.Id;  
        passportDoc.DocumentType__c = 'Passport Copy';
        insert passportDoc;
        
        Document__c passportDocSeller = new Document__c();
        passportDocSeller.Account__c = customerAcc.Id;  
        passportDocSeller.DocumentType__c = 'Passport Copy';
        insert passportDocSeller;
        
        
        Test.startTest();
        HexaBPM__Service_Request__c srExists=TestObjectsFactory.getServiceRequest(submittedStatus.Id,unit.Id,'Property Transfer NOC',PropertyTransferNOCRTId,PTNSRTemplate.Id);
        srExists.TransferSellingPrice__c=19500.01;
        srExists.HexaBPM__Customer__c=customerAcc.Id;
        srExists.BuyerName__c = buyerAcc.Id;
        srExists.Retrive_Buyer_Acc_Docs__c= true;
        srExists.RecordTypeId = PropertyTransferNOCRTId;
        insert srExists;
        
        system.debug('recordtypename'+srExists.HexaBPM__Record_Type_Name__c);
        ContentVersion content = new ContentVersion(); 
        content.Title = 'Test Content';
        content.PathOnClient = '/' + content.Title + '.jpg';
        content.VersionData = Blob.valueOf('Unit Test ContentVersion Body');
        content.Origin = 'H';
        insert content;
        
        ContentVersion insertedContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id LIMIT 1];
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = nationalIdDocSeller.Id;  
        contentlink.ContentDocumentId = insertedContentVersion.ContentDocumentId;  
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';
        insert contentlink;
        
        ContentDocumentLink conlinkPass = new ContentDocumentLink();
        conlinkPass.LinkedEntityId = passportDoc.Id;  
        conlinkPass.ContentDocumentId = insertedContentVersion.ContentDocumentId;  
        conlinkPass.ShareType = 'I';
        conlinkPass.Visibility = 'AllUsers';
        insert conlinkPass;
        
        ContentDocumentLink conlinkNaId = new ContentDocumentLink();
        conlinkNaId.LinkedEntityId = nationalIdBackDocBuyer.Id;  
        conlinkNaId.ContentDocumentId = insertedContentVersion.ContentDocumentId;  
        conlinkNaId.ShareType = 'I';
        conlinkNaId.Visibility = 'AllUsers';
        insert conlinkNaId;
        
        ContentDocumentLink conlinkPassSel = new ContentDocumentLink();
        conlinkPassSel.LinkedEntityId = passportDocSeller.Id;  
        conlinkPassSel.ContentDocumentId = insertedContentVersion.ContentDocumentId;  
        conlinkPassSel.ShareType = 'I';
        conlinkPassSel.Visibility = 'AllUsers';
        insert conlinkPassSel;
        
        ContentVersion contentseller = new ContentVersion(); 
        contentseller.Title = 'Test Content';
        contentseller.PathOnClient = '/' + content.Title + '.jpg';
        contentseller.VersionData = Blob.valueOf('Unit Test ContentVersion Body');
        contentseller.Origin = 'H';
        
        insert contentseller;
        
        ContentVersion insertedContentVersionseller = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id LIMIT 1];
        ContentDocumentLink contentlinkSeller = new ContentDocumentLink();
        contentlinkSeller.LinkedEntityId = nationalIdDoc.Id;  
        contentlinkSeller.ContentDocumentId = insertedContentVersion.ContentDocumentId;  
        contentlinkSeller.ShareType = 'I';
        contentlinkSeller.Visibility = 'AllUsers';
        insert contentlinkSeller;
        
        HexaBPM__Document_Master__c buyerEmiratesIdDOA = new HexaBPM__Document_Master__c();
        buyerEmiratesIdDOA.HexaBPM__Code__c = 'Buyer Emirates ID Copy';
        buyerEmiratesIdDOA.HexaBPM__Available_to_client__c = true;
        buyerEmiratesIdDOA.AvailableForCustomer__c=true;
        insert buyerEmiratesIdDOA;
        
        HexaBPM__SR_Template_Docs__c buyerEmiratesIdSRTemplate = new HexaBPM__SR_Template_Docs__c();
        buyerEmiratesIdSRTemplate.HexaBPM__Document_Master__c = buyerEmiratesIdDOA.id ;
        insert buyerEmiratesIdSRTemplate;
        
        HexaBPM__SR_Doc__c buyerEmiratesIdSRDoc = new HexaBPM__SR_Doc__c();
        buyerEmiratesIdSRDoc.HexaBPM__Document_Master__c = buyerEmiratesIdDOA.id  ;
        buyerEmiratesIdSRDoc.HexaBPM__SR_Template_Doc__c = buyerEmiratesIdSRTemplate.id;
        buyerEmiratesIdSRDoc.HexaBPM__Service_Request__c =srExists.Id;
        buyerEmiratesIdSRDoc.Name='Buyer Emirates ID Copy';
        insert buyerEmiratesIdSRDoc;
        system.debug('srdocdetails'+buyerEmiratesIdSRDoc); 
        
        HexaBPM__Document_Master__c buyerPassportIdDOA = new HexaBPM__Document_Master__c();
        buyerPassportIdDOA.HexaBPM__Code__c = 'Buyer Passport Copy';
        buyerPassportIdDOA.HexaBPM__Available_to_client__c = true;
        buyerPassportIdDOA.AvailableForCustomer__c=true;
        insert buyerPassportIdDOA;
        
        HexaBPM__SR_Template_Docs__c buyerPassportIdSRTemplate = new HexaBPM__SR_Template_Docs__c();
        buyerPassportIdSRTemplate.HexaBPM__Document_Master__c = buyerPassportIdDOA.id ;
        insert buyerPassportIdSRTemplate;
        
        HexaBPM__SR_Doc__c buyerPassportIdSRDoc = new HexaBPM__SR_Doc__c();
        buyerPassportIdSRDoc.HexaBPM__Document_Master__c = buyerPassportIdDOA.id  ;
        buyerPassportIdSRDoc.HexaBPM__SR_Template_Doc__c = buyerPassportIdSRTemplate.id;
        buyerPassportIdSRDoc.HexaBPM__Service_Request__c =srExists.Id;
        buyerPassportIdSRDoc.Name='Buyer Passport Copy';
        insert buyerPassportIdSRDoc;
        system.debug('buyerEmiratesIdSRDoc'+buyerPassportIdSRDoc); 
        
        HexaBPM__Document_Master__c sellerEmiratesIdDOA = new HexaBPM__Document_Master__c();
        sellerEmiratesIdDOA.HexaBPM__Code__c = 'Seller Emirates ID Copy';
        sellerEmiratesIdDOA.HexaBPM__Available_to_client__c = true;
        sellerEmiratesIdDOA.AvailableForCustomer__c=true;
        insert sellerEmiratesIdDOA;
        
        HexaBPM__SR_Template_Docs__c sellerEmiratesSRTemplate = new HexaBPM__SR_Template_Docs__c();
        sellerEmiratesSRTemplate.HexaBPM__Document_Master__c = sellerEmiratesIdDOA.id ;
        insert sellerEmiratesSRTemplate;
        
        HexaBPM__SR_Doc__c sellerEmiratesSRDoc = new HexaBPM__SR_Doc__c();
        sellerEmiratesSRDoc.HexaBPM__Document_Master__c = sellerEmiratesIdDOA.id  ;
        sellerEmiratesSRDoc.HexaBPM__SR_Template_Doc__c = sellerEmiratesSRTemplate.id;
        sellerEmiratesSRDoc.HexaBPM__Service_Request__c =srExists.Id;
        sellerEmiratesSRDoc.Name='Seller Emirates ID Copy';
        
        insert sellerEmiratesSRDoc;
        HexaBPM__SR_Doc__c sellerEmiratesbackSRDoc = new HexaBPM__SR_Doc__c();
        sellerEmiratesbackSRDoc.HexaBPM__Document_Master__c = sellerEmiratesIdDOA.id  ;
        sellerEmiratesbackSRDoc.HexaBPM__SR_Template_Doc__c = sellerEmiratesSRTemplate.id;
        sellerEmiratesbackSRDoc.HexaBPM__Service_Request__c =srExists.Id;
        sellerEmiratesbackSRDoc.Name='Seller Emirates ID BackSideCopy';
        
        insert sellerEmiratesbackSRDoc;
        
        
        HexaBPM__Document_Master__c sellerPassportIdDOA = new HexaBPM__Document_Master__c();
        sellerPassportIdDOA.HexaBPM__Code__c = 'Seller Passport Copy';
        sellerPassportIdDOA.HexaBPM__Available_to_client__c = true;
        sellerPassportIdDOA.AvailableForCustomer__c=true;
        insert sellerPassportIdDOA;
        
        HexaBPM__SR_Template_Docs__c sellerPassportSRTemplate = new HexaBPM__SR_Template_Docs__c();
        sellerPassportSRTemplate.HexaBPM__Document_Master__c = sellerPassportIdDOA.id ;
        insert sellerPassportSRTemplate;
        
        HexaBPM__SR_Doc__c sellerPassportSRDoc = new HexaBPM__SR_Doc__c();
        sellerPassportSRDoc.HexaBPM__Document_Master__c = sellerPassportIdDOA.id  ;
        sellerPassportSRDoc.HexaBPM__SR_Template_Doc__c = sellerPassportSRTemplate.id;
        sellerPassportSRDoc.HexaBPM__Service_Request__c =srExists.Id;
        sellerPassportSRDoc.Name='Seller Passport Copy';
        
        insert sellerPassportSRDoc;
        HexaBPM__SR_Doc__c buyerEmiratesIdBackCopySRDoc = new HexaBPM__SR_Doc__c();
        buyerEmiratesIdBackCopySRDoc.HexaBPM__Service_Request__c =srExists.Id;
        buyerEmiratesIdBackCopySRDoc.Name='Buyer Emirates ID BackSideCopy';
        insert buyerEmiratesIdBackCopySRDoc;
        Test.stopTest();	        
    }
    @isTest
    static void FastTRackSRDOCmethod(){
        
        List<HexaBPM__Service_Request__c> ServiceRequests =[SELECT Id,BuyerName__c,Retrive_Buyer_Acc_Docs__c,HexaBPM__Record_Type_Name__c,HexaBPM__Customer__c,RecordTypeId FROM HexaBPM__Service_Request__c WHERE TransferSellingPrice__c=:19500.01];
        // Enqueue the queueable job
        Test.startTest();
        FastTRackSRDOCQueueable job = new FastTRackSRDOCQueueable(ServiceRequests);
        System.enqueueJob(job);
        Test.stopTest();
    }
}