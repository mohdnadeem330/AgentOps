@isTest
public class SetupObjectDataHelperTest {
    
    @isTest(SeeAllData=true)
    static void callMethods() {
        Test.startTest();

        Id brokerQueueId = Utilities.getQueueInformation(Constants.BROKER_QUEUE).Id;

        SetupObjectDataHelper.getGroupData(brokerQueueId);
        SetupObjectDataHelper.getsObjectQueues('Lead');
        SetupObjectDataHelper.getEmailTemplates();
        SetupObjectDataHelper.GetDelegatedUsers(UserInfo.getUserId());

        Test.stopTest();
    }
}