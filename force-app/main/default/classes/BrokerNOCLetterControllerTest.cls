@isTest
public class BrokerNOCLetterControllerTest {
    
    @testSetup static void setupData() {
        // Set up test data
        Account testAccount = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
      	testAccount.RecordTypeId = Constants.BROKER_AGENCY_RECORD_TYPE_ID;
        insert testAccount;
        
        Contact partnerContact = new Contact(
            FirstName = 'Test',
            LastName = 'User11',
            Email = 'testuser@example.com',
            AccountId = testAccount.Id
        );
        insert partnerContact;
    }

    @isTest
    static void testControllerWithValidUser() {
        
        Account testAccount = [SELECT Id from Account Limit 1];
        Contact partnerContact = [SELECT Id From Contact Limit 1];
        
        Profile partnerProfile = [SELECT Id FROM Profile WHERE Name = 'Agency Admin Login' LIMIT 1];
        
		Test.startTest();
        User communityUser = new User(
            Username = 'testuser.partner@example.com',
            LastName = 'user12',
            Email = 'testuser@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = partnerProfile.Id,
            ContactId = partnerContact.Id
        );

        communityUser.CommunityNickname = 'testusernickname';
        insert communityUser;
        
        
        System.runAs(communityUser) {
            // Set the parameters
            PageReference pageRef = Page.BrokerNOCLetterPDF; // Use your Visualforce page name
            pageRef.getParameters().put('loggedInUserId', UserInfo.getUserId());
            pageRef.getParameters().put('renderAs', 'pdf');
            Test.setCurrentPage(pageRef);
            
            // Instantiate the controller
            BrokerNOCLetterController controller = new BrokerNOCLetterController();
        }
        Test.stopTest();
    }

    @isTest
    static void testControllerWithNoUser() {
        Test.startTest();
        // Set the parameters
        PageReference pageRef = Page.BrokerNOCLetterPDF; // Use your Visualforce page name
        Test.setCurrentPage(pageRef);

        // Instantiate the controller
        BrokerNOCLetterController controller = new BrokerNOCLetterController();
        Test.stopTest();
    }
}