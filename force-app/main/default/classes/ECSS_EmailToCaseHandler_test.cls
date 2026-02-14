@isTest
public class ECSS_EmailToCaseHandler_test {
    @testSetup
    static void setupTestData() {
        TestObjectsFactory.createUser();
        
    }
    
    @isTest
    static void TestinBoundEmail()
        
    {
        // Create Test record.
        User testUser = [select id from user where email='testuser@example.com'];
        System.runAs(testUser) {
            Account newAccount = TestObjectsFactory.getPersonAccountRecord(181, 'United Arab Emirates', 'V1', 'P1');
            insert newAccount;
            
            Case Cas = TestObjectsFactory.getProvisComplaintCase(newAccount);
            insert Cas;
        }
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        // intialize the list string to store emails.
        List<string> emails = new List<string>{'testbandi@gmail.com','testbandi123@gmail.com'};
            
            email.subject = 'Create case';
        email.fromAddress = 'someaddress@email.com';
        //assigning the emails to toAddresses 
        email.toAddresses = emails;
        email.plainTextBody = 'email body';
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfileone.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
            
            ECSS_EmailToCaseHandler  testInbound=new ECSS_EmailToCaseHandler ();
        testInbound.handleInboundEmail(email, env);
    }
    
}