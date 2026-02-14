@IsTest
private class Test_CopyFilestoSRDoc {
    
    @IsTest static void testCopyFilesMethodWithGoldenVisa() {
       
        // Get the test data created in the setup method
        //HexaBPM__Step__c stp = [SELECT Id, HexaBPM__SR__c FROM HexaBPM__Step__c LIMIT 1];
        //Set<Id> srIds = new Set<Id>{stp.HexaBPM__SR__c};

         // Create a test account
        Account testAccount = new Account(FirstName = 'Test',Lastname='Test Account', PersonEmail = 'test@test.com',
         RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId()
        );
        insert testAccount;
        
        // Create a test contact
       // Contact testContact = new Contact(FirstName='Test',LastName='Contact',Email='test@test.com',AccountId=testAccount.Id);
        //insert testContact;
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;
        
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User utest = new User(Alias = 'testusr', Email='testuser@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = p.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='testuser987@Aldar.com');
        //insert utest;
        
        // Create a test HexaBPM__Service_Request__c record
        HexaBPM__Service_Request__c testSR = new HexaBPM__Service_Request__c(HexaBPM__Customer__c=testAccount.Id, Is_Golden_Visa_Investor_Certificate__c=false, SRType__c='Investor Certificate',recordTypeId=Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Investor Certificate'));
        insert testSR;
        
        // Create a test HexaBPM__Step__c record
        HexaBPM__Step__c testStep = new HexaBPM__Step__c(HexaBPM__SR__c=testSR.Id, HexaBPM__Summary__c='Share Investor Certificate with Customer');
        insert testStep;
        
         Test.StartTest();
        HexaBPM__SR_Doc__c srDoc=new HexaBPM__SR_Doc__c();
        srDoc.HexaBPM__Service_Request__c=testSR.Id;
        srDoc.Name ='Investor Certificate';
        Insert srDoc;
        
         HexaBPM__SR_Doc__c srDoc1=new HexaBPM__SR_Doc__c();
        srDoc1.HexaBPM__Service_Request__c=testSR.Id;
        srDoc1.Name ='Golden Visa Investor Certificate';
        Insert srDoc1;
        // Create a test content version
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert testContentVersion;
        
        // Create a test content document link
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId;
        testContentDocumentLink.LinkedEntityId = srDoc1.Id;
        testContentDocumentLink.ShareType = 'V';
        insert testContentDocumentLink;
        
        ContentDocumentLink testContentDocumentLink1 = new ContentDocumentLink();
        testContentDocumentLink1.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId;
        testContentDocumentLink1.LinkedEntityId = srDoc.Id;
        testContentDocumentLink1.ShareType = 'V';
        insert testContentDocumentLink1;

        Set<Id> srIds = new Set<Id>{testSR.Id};
        // Update the service request with golden *
        //HexaBPM__Service_Request__c testSR = [SELECT Id FROM HexaBPM__Service_Request__c WHERE Id = :srIds];
        //testSR.Is_Golden_Visa_Investor_Certificate__c = true;
        //update testSR;
        
        // Call the copyFilesMethod method with golden *
        
        CopyFilestoSRDoc.copyFilesMethod('Golden Visa Investor Certificate', 'Investor Certificate', srIds, 'Investor Certificate', 'Investor Certificate');
       // CopyFilestoSRDoc.copyFilesMethod('Investor Certificate', 'Investor Certificate', srIds, 'Share Investor Certificate with Customer', '');

        Test.stopTest();
        
        // Verify that the test worked as expected
        //List<HexaBPM__SR_Doc__c> srDocList = [SELECT Id, HexaBPM__Service_Request__c,HexaBPM__Service_Request__r.HexaBPM__Parent_SR__c, HexaBPM__Service_Request__r.SalesOrder__c,
        //                                      (select Id,contentdocumentid from AttachedContentDocuments) 
          //                                    FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c IN: srIds AND HexaBPM__Document_Name__c ='Share Investor Certificate with Customer'
            //                                  and HexaBPM__Service_Request__r.SRType__c='Investor Certificate'];
       // System.assertEquals(1, srDocList.size(), 'One SR Doc should be created');
        //System.assertEquals(stp.HexaBPM__SR__c, srDocList[0].HexaBPM__Service_Request__c, 'SR should match');
        
     //   List<ContentDocumentLink> contentDocumentLinkList = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :srDocList[0].Id];
        //System.assertEquals(1, contentDocumentLinkList.size(), 'One content document link should be created');
        //System.assertEquals(srDocList[0].Id, contentDocumentLinkList[0].LinkedEntityId, 'SR Doc Id should match');
    }
    
   
}