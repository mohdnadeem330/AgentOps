@isTest
public class DynamicSObjectShareControllerTest {

    @testSetup
    static void setupTestData() {
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create custom object record (e.g., Project__c)
        Project__c proj = new Project__c(Name = 'Test Project',BusinessUnitId__c='213',ProjectCode__c='1234');
        insert proj;
        Asset asse = new Asset(Name = 'Aset Test');
        insert asse;
    }
	@isTest
    static void testAssetShareCreation() {
        Asset acc = [SELECT Id FROM Asset LIMIT 1];

        DynamicSObjectShareController.Request req = new DynamicSObjectShareController.Request();
        req.shareObjectName = 'AssetShare';
        req.recordId = acc.Id;
        req.userOrGroupId = UserInfo.getUserId();
        req.accessLevel = 'Read'; // or 'Edit'

        Test.startTest();
        DynamicSObjectShareController.shareRecords(new List<DynamicSObjectShareController.Request>{ req });
        Test.stopTest();
    }
    @isTest
    static void testAccountShareCreation() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        DynamicSObjectShareController.Request req = new DynamicSObjectShareController.Request();
        req.shareObjectName = 'AccountShare';
        req.recordId = acc.Id;
        req.userOrGroupId = UserInfo.getUserId();
        req.accessLevel = 'Read'; // or 'Edit'

        Test.startTest();
        DynamicSObjectShareController.shareRecords(new List<DynamicSObjectShareController.Request>{ req });
        Test.stopTest();
    }

    @isTest
    static void testCustomShareCreation() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        DynamicSObjectShareController.Request req = new DynamicSObjectShareController.Request();
        req.shareObjectName = 'Project__Share';
        req.recordId = proj.Id;
        req.userOrGroupId = UserInfo.getUserId();
        req.accessLevel = 'Read'; // or 'Edit'

        Test.startTest();
        DynamicSObjectShareController.shareRecords(new List<DynamicSObjectShareController.Request>{ req });
        Test.stopTest();
    }
}