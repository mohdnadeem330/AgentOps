@isTest
public class FinanceCommentTest {

    @isTest
    static void testSaveFinanceComment() {
        // Setup test data
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        Project__c projectRecord = TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;

        BuildingSection__c buildingRecord = TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;

        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id, buildingRecord.id);
        insert unitrecord;

        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;

        List<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;

        paymentPlanRecord.IsActive__c = Constants.YES;
        update paymentPlanRecord;

        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id, buildingRecord.Id);
        insert buldingPaymentMapping;    

        OffersPromotions__c offerRecord = TestObjectsFactory.getOfferPromotion(buildingRecord.Id, projectRecord.Id);
        insert offerRecord;

        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        insert offerLine;

        // Retrieve necessary records
        Account accRecord = [SELECT Id FROM Account LIMIT 1];
        Opportunity optyRecord = [SELECT Id FROM Opportunity LIMIT 1];
        Unit__c unitrecord1 = [SELECT Id FROM Unit__c LIMIT 1];

        SalesOrder__c testSalesOrder = TestObjectsFactory.getSalesOrderRecord(optyRecord.Id, accRecord.Id);
        testSalesOrder.Unit__c = unitrecord1.Id;
        testSalesOrder.SubStatus__c = Constants.SALES_SUB_STATUS_SPA_SIGNEDOFF_PENDING;
        insert testSalesOrder;

  /*      // Simulate a user context
        User testUser = new User(
            Alias = 'testu',
            LastName = 'TestUser123',
            FirstName ='TestUser123',
            Email = 'testuser111@example.com',
            EmailEncodingKey = 'ISO-8859-1',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser111@example.com',
            LanguageLocaleKey = 'en_US',
            CommunityNickname = 'testuser111'
        );
        insert testUser;*/

        // Set the running user to the test user
//        System.runAs(testUser) {
            // Define the remark to be added
            String testRemark = 'This is a test remark.';

            // Call the method to test
            Test.startTest();
            FinanceComment.saveFinanceComment(testSalesOrder.Id, testRemark);
            Test.stopTest();

            // Fetch the updated SalesOrder__c record
    /*        SalesOrder__c updatedSalesOrder = [SELECT FinanceComments__c FROM SalesOrder__c WHERE Id = :testSalesOrder.Id LIMIT 1];

          // Capture the formatted date
    String formattedDate = System.now().format();
// Fetch the profile name using the User record
    User insertedUser = [SELECT Profile.Name FROM User WHERE Id = :testUser.Id LIMIT 1];
    // Create the expected comment string
    String expectedComment = testUser.FirstName + ' ' + testUser.LastName + ' (' + 
                             testUser.Profile.Name + ') ' + 
                             formattedDate + '\n ----- \n' + 
                             testRemark + '\n\n';
            // Assert that the FinanceComments__c field was updated correctly
           // System.assertEquals(expectedComment, updatedSalesOrder.FinanceComments__c);
//        }
        */
    }
}