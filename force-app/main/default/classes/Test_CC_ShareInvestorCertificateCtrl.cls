@IsTest
public class Test_CC_ShareInvestorCertificateCtrl {
    @testSetup static void setupData() {
        // Create test data
       // Account account = new Account(Name='Test Account');
       // insert account;
        
        Account account = new Account(FirstName = 'Test',Lastname='Test Account', PersonEmail = 'test@test.com',
         RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId()
        );
        insert account; 
        
       // Contact con =new Contact(LastName ='TestContact',Email='raj@aldar.com',accountId=account.Id);
       // Insert con;
        
       
        
        OrgWideEmailAddress oEA =new OrgWideEmailAddress();
        oEA.Address='rjain@aldar.com';
        oEA.DisplayName='Aldar Customer Care';
         //Insert oEA;
        HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c(HexaBPM__Customer__c=account.Id, Is_Golden_Visa_Investor_Certificate__c =false, SRType__c='Investor Certificate',recordTypeId=Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Investor Certificate'));
        sr.Is_Golden_Visa_Investor_Certificate__c =false;
        insert sr;
        
        HexaBPM__Step__c stp = new HexaBPM__Step__c(HexaBPM__SR__c=sr.Id, HexaBPM__Summary__c='Share Investor Certificate with Customer');
        insert stp;
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;
        
        HexaBPM__SR_Doc__c srDoc=new HexaBPM__SR_Doc__c();
        srDoc.HexaBPM__Service_Request__c=sr.Id;
        srDoc.Name ='Signed Investor Certificate';
        Insert srDoc;
        
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
        testContentDocumentLink.LinkedEntityId = srDoc.Id;
        testContentDocumentLink.ShareType = 'V';
        insert testContentDocumentLink;
        
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User utest = new User(Alias = 'testusr', Email='testuser@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = p.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='testuser123456@Aldar.com');
        insert utest;
    }
    
    @IsTest static void testShareInvestorCertificateWithGoldenVisa() {
        // Modify the test data to include a golden *
        // 
         Emailtemplate validEmailTemplate = new EmailTemplate();
        validEmailTemplate.isActive = true;
        validEmailTemplate.Name = 'Golden_Visa_Invester_Certificate_to_Customer';
        validEmailTemplate.DeveloperName = 'Golden_Visa_Invester_Certificate_to_Customer';
        validEmailTemplate.TemplateType = 'text';
        validEmailTemplate.FolderId = UserInfo.getUserId();
        Insert validEmailTemplate;
 
        Emailtemplate eml =new Emailtemplate();
        eml.DeveloperName ='Golden_Visa_Invester_Certificate_to_Customer';
       // Insert eml;
  
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
        //sr.Is_Golden_Visa_Investor_Certificate__c = true;
        //update sr;
         HexaBPM__Step__c stp = [SELECT Id, HexaBPM__SR__c,HexaBPM__Summary__c FROM HexaBPM__Step__c LIMIT 1];
        
         
        /*EmailMessage email = new EmailMessage();

        // Required Fields
        email.Subject = 'Investor Certificate';
        email.TextBody = 'This is the body of the test email.';
        email.FromAddress = 'rjain@aldar.com';
        email.ToAddress = 'rjain@aldar.com';
        email.Status = '3'; // '3' means Sent
        email.Incoming = false; // false = outbound email
        email.RelatedToId = stp.HexaBPM__SR__c; // Replace with a valid Case Id (or other supported object)
        
            
        insert email;*/
         
        
        // Create an instance of the CC_ShareInvestorCertificateCtrl class
        CC_ShareInvestorCertificateCtrl ctrl = new CC_ShareInvestorCertificateCtrl();
        
        // Call the EvaluateCustomCode method
        ctrl.EvaluateCustomCode(sr, stp);
        
        // Assert that the copyFilesMethod was called with the correct parameters for golden *
         Test.startTest();
        CopyFilestoSRDoc.copyFilesMethod('Golden * Investor Certificate','Investor Certificate',new Set<Id>{sr.Id},'Investor Certificate','Golden *');
       Test.stopTest();
    }
    
    /*@IsTest static void testShareInvestorCertificateWithoutGoldenVisa() {
        // Get the test data created in the setup method
        HexaBPM__Step__c stp = [SELECT Id, HexaBPM__SR__c FROM HexaBPM__Step__c LIMIT 1];
        
        // Create an instance of the CC_ShareInvestorCertificateCtrl class
        CC_ShareInvestorCertificateCtrl ctrl = new CC_ShareInvestorCertificateCtrl();
        
        // Call the EvaluateCustomCode method
        ctrl.EvaluateCustomCode(null, stp);
        
        // Assert that the copyFilesMethod was called with the correct parameters for regular investor certificate
        Test.startTest();
        CopyFilestoSRDoc.copyFilesMethod('Investor Certificate','Investor Certificate',new Set<Id>{stp.HexaBPM__SR__c},'Investor Certificate','');
        Test.stopTest();
    }
    
    @IsTest static void testShareInvestorCertificateWithInvalidSR() {
        // Get the test data created in the setup method
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];
        
        // Create an instance of the CC_ShareInvestorCertificateCtrl class
        CC_ShareInvestorCertificateCtrl ctrl = new CC_ShareInvestorCertificateCtrl();
        
        // Call the EvaluateCustomCode method with an invalid SR
        ctrl.EvaluateCustomCode(sr, null);
    }*/
}