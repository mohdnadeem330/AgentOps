@isTest
public class BlockedDuplicateBrokerBatchTest{
    @testSetup 
    static void createData() {
        Test.startTest();
        List<Contact> listContact = new List<Contact>();
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;

        Contact conta1 = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        Contact conta2 = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        conta1.RecordTypeId = ALD_Constants.BROKER_AGENT_RT;
        conta1.AgentStatus__c = 'Active';
        conta1.Email = 'test@aldar.com';
        conta1.MobilePhone__c = '552191627';
        conta1.phone = null;
        conta1.Mobilephone = null;
        conta1.PrimaryOwner__c = true;

        conta2.RecordTypeId = ALD_Constants.BROKER_AGENT_RT;
        conta2.AgentStatus__c = 'Pending Verification';
        conta2.LastName = 'Alice 111';
        conta2.Email = 'test@aldar.com';
        conta2.phone = null;
        conta2.Mobilephone = null;
        conta2.MobilePhone__c = '552191627';
        
        listContact.add(conta1);
        listContact.add(conta2);
        update listContact;
        
        Test.stopTest();
    }

    @isTest
    static void unitTest(){
        Test.startTest();
        BlockedDuplicateBrokerBatch blockBatch = new BlockedDuplicateBrokerBatch(new Set<String>());
        Database.executeBatch(blockBatch);
        blockBatch.execute(null);
        Test.stopTest();
    }
}