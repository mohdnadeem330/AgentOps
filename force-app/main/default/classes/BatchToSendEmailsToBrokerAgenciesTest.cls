/**********************************************************************************************************************
* Name              : BatchToSendEmailsToBrokerAgenciesTest                                                        
* Description       : This Apex class is the test class to BatchToSendEmailsToBrokerAgencies for Marketing Reimbursement
* Method            : BatchToSendEmailsToBrokerAgencies  
* Created By        : tdontha@aldar.com - Tharun   
* Last Modified By  : tdontha@aldar.com - Tharun
******************************************************************************************************************/
@isTest
public class BatchToSendEmailsToBrokerAgenciesTest 
{
    //Create setup data
    @testSetup
    public static void setupData()
    {
        BrokerClassification__c standardClassification = TestObjectsFactory.getBrokerClassificationRecord();
        standardClassification.Name = 'Standard';
        standardClassification.Quarter1MarketingBudget__c = 0;
        standardClassification.Quarter2MarketingBudget__c = 0;
        standardClassification.Quarter3MarketingBudget__c = 0;
        standardClassification.Quarter4MarketingBudget__c = 0;
        standardClassification.Year__c = String.valueOf(System.Today().year()); 
        insert standardClassification;
        
        BrokerClassification__c envoyClassification = TestObjectsFactory.getBrokerClassificationRecord();
        envoyClassification.Name = 'Envoy';
        envoyClassification.Quarter1MarketingBudget__c = 20000;
        envoyClassification.Quarter2MarketingBudget__c = 30000;
        envoyClassification.Quarter3MarketingBudget__c = 40000;
        envoyClassification.Quarter4MarketingBudget__c = 50000;
        envoyClassification.Year__c = String.valueOf(System.Today().year());
        insert envoyClassification;
        
        BrokerClassification__c AmbassadorClassification = TestObjectsFactory.getBrokerClassificationRecord();
        AmbassadorClassification.Name = 'Ambassador';
        AmbassadorClassification.Quarter1MarketingBudget__c = 50000;
        AmbassadorClassification.Quarter2MarketingBudget__c = 60000;
        AmbassadorClassification.Quarter3MarketingBudget__c = 70000;
        AmbassadorClassification.Quarter4MarketingBudget__c = 80000;
        AmbassadorClassification.Year__c = String.valueOf(System.Today().year());
        insert AmbassadorClassification;
        
        Account accountRecord = TestObjectsFactory.getAgencyAccountRecord('New Prop LLC', 'VAT69');
        accountRecord.BrokerClassification__c = envoyClassification.Id;
        accountRecord.AgencyStatus__c = 'Active';
        insert accountRecord;
        System.debug('AccId------>'+accountRecord.Id);
        
        Contact con = TestObjectsFactory.contactDataSetup(accountRecord.Id);
        con.FirstName = 'Test';
        con.AgentStatus__c = 'Active';
        con.LastName = 'UserForEmail';
        con.Email = 'test@aldar.com';
        con.BrokerType__c = 'Agency Admin';
        update con;

        System.debug('contactRecord------>'+con);
    }
    
    @isTest
    static void sendEmailForReminder1()
    {
        Test.startTest();
        
        Account updateAcc = [SELECT Id, BrokerClassification__c, Name FROM Account WHERE Name = 'New Prop LLC'];
        updateAcc.BrokerClassification__c = [SELECT Id FROM BrokerClassification__c WHERE Name = 'Standard'].Id;
        update updateAcc;
        
        AccountHistory accHistory = new AccountHistory();
        //accHistory.OldValue = 'Envoy';
        //accHistory.NewValue = 'Standard';
        accHistory.AccountId = updateAcc.Id;
        accHistory.Field = 'BrokerClassification__c';
        insert accHistory;
            
        System.debug('Acc------>'+updateAcc.Name);
        
        BatchToSendEmailsToBrokerAgencies batchEmail1 = new BatchToSendEmailsToBrokerAgencies(1);
        Database.executeBatch(batchEmail1,5);
        Test.stopTest();
    }
    
    @isTest
    static void sendEmailForReminder2()
    {
        Test.startTest();
        BatchToSendEmailsToBrokerAgencies batchEmail1 = new BatchToSendEmailsToBrokerAgencies(2);
        Database.executeBatch(batchEmail1,5);
        Test.stopTest();
    }
    
    @isTest
    static void sendEmailForReminder3()
    {
        Test.startTest();
        BatchToSendEmailsToBrokerAgencies batchEmail1 = new BatchToSendEmailsToBrokerAgencies(3);
        Database.executeBatch(batchEmail1,5);
        Test.stopTest();
    }
    
    @isTest
    static void sendEmailTestContact()
    {
        String conId = [SELECT Id FROM Contact WHERE LastName = 'UserForEmail'].Id;
        Test.startTest();
        BatchToSendEmailsToBrokerAgencies batchEmail1 = new BatchToSendEmailsToBrokerAgencies(true,new Set<Id>{conId},1);
        Database.executeBatch(batchEmail1,5);
        BatchToSendEmailsToBrokerAgencies batchEmail2 = new BatchToSendEmailsToBrokerAgencies(true,new Set<Id>{conId},2);
        Database.executeBatch(batchEmail2,5);
        BatchToSendEmailsToBrokerAgencies batchEmail3 = new BatchToSendEmailsToBrokerAgencies(true,new Set<Id>{conId},3);
        Database.executeBatch(batchEmail3,5);
        Test.stopTest();
    }
    
    @isTest
    static void sendEmailException()
    {
        Contact cont = [SELECT Id, Email FROM Contact WHERE LastName = 'UserForEmail' LIMIT 1];
        cont.Email = '';
        update cont;
        
        Test.startTest();
        BatchToSendEmailsToBrokerAgencies batchEmail1 = new BatchToSendEmailsToBrokerAgencies(5);
        Database.executeBatch(batchEmail1,5);
        
        System.schedule('BatchToSendEmailsToBrokerAgencies-Test', '0 0 * * * ?', new BatchToSendEmailsToBrokerAgencies(true,new Set<Id>{cont.Id},1));
        Test.stopTest();
    }
    
}