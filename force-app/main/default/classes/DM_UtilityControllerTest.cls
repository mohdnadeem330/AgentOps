@isTest
public class DM_UtilityControllerTest {
    
    @isTest
    static void testGetPicklistValues() {
        
        String objName = 'Case';
        String fldName = 'Type';
        
        Test.startTest();
        Map<String, String> result = DM_UtilityController.getPicklistValues(objName, fldName);
        DM_UtilityController.getBankTransferDetails();
        Test.stopTest();
        
    }
    @isTest
    static void testGetUserInfo() {
        Test.startTest();
        List<User> result = DM_UtilityController.getUserInfo();
        Test.stopTest();
        
    }
    @isTest
    static void testCreateContentVersion() {
        String base64 = 'U29tZSBkYXRh'; // Base64 encoded string for "Some data"
        String filename = 'TestFile.txt';
        
        Test.startTest();
        ContentVersion cv = DM_UtilityController.createContentVersion(base64, filename);
        Test.stopTest();
    }
    static void testCreateContentLink() {    
        Document__c doc= new Document__c(Status__c = 'Uploaded',DocumentType__c = 'NOC');
        insert doc;
        /*ContentVersion cv = new ContentVersion(Title = 'TestFile.txt', PathOnClient = 'TestFile.txt', VersionData = Blob.valueOf('Test data'));
        insert cv;*/
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Document',
            VersionData = Blob.valueOf('Test Content'),
            PathOnClient = 'test.txt'
        );
        insert testContentVersion;
        String contentVersionId  = testContentVersion.Id;
       id ContentDocumentId = [SELECT Id FROM ContentDocument WHERE Title = 'Test Document' LIMIT 1].Id;
        Test.startTest();
        ContentDocumentLink cdl = DM_UtilityController.createContentLink(contentVersionId, doc.Id);
        Test.stopTest();
    }
    @isTest
    static void testSendBellNotification() {
        // Create a CustomNotificationType for testing
        CustomNotificationType cnt = new CustomNotificationType(DeveloperName = 'DM_customNotification', MasterLabel = 'Test Notification');
        
        Set<String> recipientsIds = new Set<String>{UserInfo.getUserId()};
            String targetId = UserInfo.getUserId();
        String title = 'Test Notification';
        String body = 'This is a test notification.';
        
        Test.startTest();
        DM_UtilityController.sendBellNotification(recipientsIds, targetId, title, body);
        Test.stopTest();
    }
    @isTest
    static void testGetDataWithAllFields() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Id recordId = testAccount.Id;
        Set<String> fieldList = new Set<String>{'Name'};
            
            Test.startTest();
        Sobject result = DM_UtilityController.getDataWithAllFields(recordId, fieldList);
        Test.stopTest();
    }
    @isTest
    static void testGetEmailAddresses() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id,BrokerLoginOTPNumber__c='123456');
        insert con;
        // Create test Case record with various field values
        Case testCase = new Case(
            Type = 'NOC',
            Status = 'New',
            Subject = 'Test Permit To Work Application',
            Project_Name__c = 'Project Alpha',
            Request_Type__c = 'New',
            Development_Name__c = 'Saadiyat Island',
            ContactId =con.Id,
            AccountId =acc.Id,
            recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('District_Management').getRecordTypeId()
        );
        insert testCase;
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode('test');
        cv.Title = 'filename.pdf';
        cv.PathOnClient = 'filename.pdf';
        insert cv;
        system.debug('cv'+cv.contentDocumentId);
        DM_UtilityController.createContentLink(cv.id,testCase.Id);
        DM_UtilityController.getCaseRecTypeName(new list<string>{testCase.id});
        DM_UtilityController.CommaseparatedValues(2000);
        DM_Security_Emails_Config__mdt emailConfig = new DM_Security_Emails_Config__mdt(Type__c = 'NOC', Development_Name__c = 'Saadiyat Island', EmailIds__c = 'test1@example.com,test2@example.com');
        
        
        Test.startTest();
        List<String> result = DM_UtilityController.getEmailAddresses(testCase);
        DM_UtilityController.updateContact(con);       
        DM_UtilityController.verifyOTP('123456');
        try{
            DM_UtilityController.sendMobileOTP(con);
        }catch(exception e){
            system.debug('Error in message =' + e.getMessage());
        }
        Test.stopTest();
    }
    @isTest
    static void testGenericValidationMsgGenerator() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;        
        Id recordId = testAccount.Id;        
        Test.startTest();
        String result = DM_UtilityController.genericValidationMsgGenerator(recordId);
        Test.stopTest();
        
    }    
    
}