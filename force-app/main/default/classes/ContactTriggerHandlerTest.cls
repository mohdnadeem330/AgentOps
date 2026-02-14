@isTest
private class ContactTriggerHandlerTest {

    @TestSetup
    static void makeData(){
        Test.startTest();
        //FIN-56 Dummy Comment
        List<Contact> listContact = new List<Contact>();
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;

        Contact conta1 = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        Contact conta2 = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        Contact conta3 = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        Contact conta4 = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        Contact conta5 = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        conta1.RecordTypeId = ALD_Constants.BROKER_AGENT_RT;
        conta1.AgentStatus__c = 'Active';
        conta1.PrimaryOwner__c = true;

        conta3.RecordTypeId = ALD_Constants.BROKER_AGENT_RT;
        conta3.AgentStatus__c = 'Active';
        conta3.PrimaryAgencyAdmin__c = true;
        
        conta2.RecordTypeId = ALD_Constants.BROKER_AGENT_RT;
        conta2.AgentStatus__c = 'Pending Verification';
        
        conta4.RecordTypeId = ALD_Constants.BROKER_AGENT_RT;
        conta4.AgentStatus__c = 'Pending Verification';
        
        conta5.RecordTypeId = ALD_Constants.BROKER_AGENT_RT;
        conta5.AgentStatus__c = 'In Active';
        conta5.PrimaryOwner__c = false;
        
        listContact.add(conta1);
        listContact.add(conta2);
        listContact.add(conta3);
        listContact.add(conta4);
        listContact.add(conta5);
        update listContact;
        
        Test.stopTest();
    }
    
    @isTest
    static void testCheckEmail() {
        // Test when there are no duplicate emails
        List<Contact> contactsNoDuplicates = new List<Contact>();
        contactsNoDuplicates.add(new Contact(FirstName='John', LastName='Doe', Email='john.doe@test.com'));
        contactsNoDuplicates.add(new Contact(FirstName='Jane', LastName='Doe', Email='jane.doe@test.com'));
        //Test.startTest();
        ContactTriggerHandler.checkEmail(contactsNoDuplicates);
        //Test.stopTest();
        // Assert no errors added
        for(Contact con : contactsNoDuplicates) {
            //System.assertEquals(0, con.getErrors().size());
        }
        
        // Test when there are duplicate emails
        List<Contact> contactsWithDuplicates = new List<Contact>();
        contactsWithDuplicates.add(new Contact(FirstName='John', LastName='Doe', Email='john.doe@test.com'));
        contactsWithDuplicates.add(new Contact(FirstName='Jane', LastName='Doe', Email='john.doe@test.com'));
        //Test.startTest();
        ContactTriggerHandler.checkEmail(contactsWithDuplicates);
        //Test.stopTest();
        // Assert error added for duplicate email
        for(Contact con : contactsWithDuplicates) {
            if (con.Email == 'john.doe@test.com') {
                //System.assertNotEquals(0, con.getErrors().size());
            } else {
                //System.assertEquals(0, con.getErrors().size());
            }
        }
    }
    
    @isTest
    private static void updatePrimaryOwnerTest(){
        Test.startTest();
        List<Contact> listContact = new List<Contact>();
        listContact = [SELECT Id,AgentStatus__c,PrimaryOwner__c,PrimaryAgencyAdmin__c FROM Contact WHERE PrimaryAgencyAdmin__c = false OR PrimaryOwner__c = false];
             
        listContact[0].AgentStatus__c = 'Active';
        listContact[0].PrimaryOwner__c = true;
        update listContact[0];
        
        listContact[1].AgentStatus__c = 'Active';
        listContact[1].PrimaryAgencyAdmin__c = true;
        update listContact[1];
        
        List<Contact> conList = [SELECT Id,AgentStatus__c,PrimaryOwner__c,PrimaryAgencyAdmin__c FROM Contact WHERE AgentStatus__c = 'In Active'];
        conList[0].AgentStatus__c = 'Active';
        conList[0].PrimaryOwner__c = true;
        
        update conList;
        
        Test.stopTest();
    }

    @isTest
    private static void suspenedUsers(){
        Test.startTest();
        List<Contact> listContact = new List<Contact>();
        listContact = [SELECT Id,AgentStatus__c FROM Contact];
      
        listContact[0].AgentStatus__c = 'Suspended';
        update listContact[0];
        
        Test.stopTest();
    }
    
    @isTest
    private static void testDuplicateContacts(){
        Test.startTest();
        
        Account acc = [SELECT Id From Account WHERE RecordTypeID =:Constants.BROKER_AGENCY_RECORD_TYPE_ID Limit 1 ];
        Contact con1 = new Contact();
        con1.AccountId = acc.Id;
        con1.LastName = 'Con1';
        con1.RecordTypeId = ALD_Constants.BROKER_AGENT_RT;
        con1.AgentStatus__c = 'Active';
        con1.PrimaryOwner__c = true;
        con1.BrokerType__c = 'Agent';
        con1.Email = 'testdupe@email.com';
        con1.MobilePhone__c = '9849517614';
        
        insert con1;
        
        Contact con2 = new Contact();
        con2.AccountId = acc.Id;
        con2.LastName = 'Con2';
        con2.RecordTypeId = ALD_Constants.BROKER_AGENT_RT;
        con2.AgentStatus__c = 'Active';
        con2.PrimaryOwner__c = true;
        con2.BrokerType__c = 'Agent';
        con2.Email = 'testdupe2@email.com';
        con2.MobilePhone__c = '9849517614';
        try{
            insert con2;
            
            con2.Email = 'testdupe@email.com';
            update con2;
        }catch(Exception e){
            
        }
        Test.stopTest();
    }
    
    @isTest
    private static void updateEmailMobileOnRelatedUserTest(){
        Test.startTest();
        List<Contact> listContact = new List<Contact>();
        listContact = [SELECT Id,Email,MobilePhone__c FROM Contact];
      
        listContact[0].Email = 'xyx@fmail.com';
        update listContact[0];
        
        Test.stopTest();
    }
}