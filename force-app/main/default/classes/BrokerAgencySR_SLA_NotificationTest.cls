@isTest
public class BrokerAgencySR_SLA_NotificationTest {
    
    // Helper method to create test data
    @testSetup
    private static void setupTestData() {

        Account acc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        acc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert acc;

        Contact newcon = new Contact();
        newcon.Lastname ='Alice';
        newcon.AccountId = acc.Id;
        newcon.Email = 'test13@aldar.com';  
        newcon.phone = '527583669'; 
        newcon.MobilePhone = '527583669';
        newcon.AgentStatus__c = 'Active';
        newcon.BrokerType__c = 'Agency Admin';
        newcon.PrimaryAgencyAdmin__c = true;
        newcon.RecordTypeId = ALD_Constants.BROKER_AGENT_RT;
        insert newcon;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Agency Registration';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='AgencyRegistration';
        insert SR_Template;

        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = Constants.PENDING_STATUS;
        status.HexaBPM__Code__c = Constants.PENDING_STATUS;
        insert status;
        
        HexaBPM__Status__c status1 = new HexaBPM__Status__c();
        status1 .Name = Constants.CLOSED_SR;
        status1 .HexaBPM__Code__c = Constants.CLOSED_SR ;
        insert status1 ;

        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.HexaBPM__Code__c = 'Pending Review';
        srStatus.Name = 'Pending Review';
        insert srStatus;

        HexaBPM__SR_Status__c srStatus1 = new HexaBPM__SR_Status__c();
        srStatus1.HexaBPM__Code__c = Constants.CLOSED_SR;
        srStatus1.Name = Constants.CLOSED_SR;
        insert srStatus1;
        
        HexaBPM__Service_Request__c serviceRequest = new HexaBPM__Service_Request__c(
            HexaBPM__Customer__c = acc.Id,
            HexaBPM__SR_Template__c = SR_Template.Id,
            CompanyEmail__c = 'test@test.com',
            SRType__c = 'Agency Registration'
        );
        insert serviceRequest;
        
        HexaBPM__Service_Request__c serviceRequest1 = new HexaBPM__Service_Request__c(
            HexaBPM__Customer__c = acc.Id,
            HexaBPM__SR_Template__c = SR_Template.Id,
            CompanyEmail__c = 'test@test.com',
            SRType__c = 'Agency Registration'
        );
        insert serviceRequest1 ;

        List<HexaBPM__SR_Status__c> HexaBPMSRStatusList = new List<HexaBPM__SR_Status__c>();
        
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        HexaBPMSRStatusList.add(draft);
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        HexaBPMSRStatusList.add(Submitted);
        
        HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
        HexaBPMSRStatusList.add(approvedByFinance);
        
        insert HexaBPMSRStatusList;

        HexaBPM__Step__c step = new HexaBPM__Step__c(
            HexaBPM__Summary__c = 'digital signature by authorized signatory',
            HexaBPM__SR__c = serviceRequest.Id,
            HexaBPM__Status__c = status.Id,
            HexaBPM__Start_Date__c = System.today(),
            HexaBPM__Due_Date__c = System.today().addDays(10)
        );
        insert step;

        HexaBPM__Step__c step1 = new HexaBPM__Step__c(
            HexaBPM__Summary__c = 'assignment of broker manager',
            HexaBPM__SR__c = serviceRequest.Id,
            HexaBPM__Status__c = status.Id,
            HexaBPM__Start_Date__c = System.today(),
            HexaBPM__Due_Date__c = System.today().addDays(-10)
        );
        insert step1;

        HexaBPM__Step__c step2 = new HexaBPM__Step__c(
            HexaBPM__Summary__c = 'validation by sales admin',
            HexaBPM__SR__c = serviceRequest.Id,
            HexaBPM__Status__c = status.Id,
            HexaBPM__Start_Date__c = System.today(),
            HexaBPM__Due_Date__c = System.today().addDays(-10)
        );
        insert step2;

        HexaBPM__Step__c step3 = new HexaBPM__Step__c(
            HexaBPM__Summary__c = 'digital signature by authorized signatory',
            HexaBPM__SR__c = serviceRequest.Id,
            HexaBPM__Status__c = status.Id,
            HexaBPM__Start_Date__c = System.today(),
            HexaBPM__Due_Date__c = System.today().addDays(-10)
        );
        insert step3;

        HexaBPM__Step__c step4 = new HexaBPM__Step__c(
            HexaBPM__Summary__c = 'require more information',
            HexaBPM__SR__c = serviceRequest1.Id,
            HexaBPM__Status__c = status.Id,
            HexaBPM__Start_Date__c = System.today().addDays(-50), 
            HexaBPM__Due_Date__c = System.today().addDays(-3) 
        );
        insert step4;
    }
    
    @isTest
    static void testBatchableMethods() {
       
        Test.startTest();
        
        Set<Id> srIds = new Set<Id>(new Map<Id,HexaBPM__Service_Request__c>([SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1]).keySet());
        BrokerAgencySR_SLA_Notification batchable = new BrokerAgencySR_SLA_Notification(srIds);
        
        // Mock the Schedulable interface execution
        // String sch = '0 0 0 15 3 ? 2022'; // A specific CRON expression
        // System.schedule('Test Schedule', sch, batchable);

        // Run the batch job
        Database.executeBatch(batchable);

        BreachedStepsController breachController = new BreachedStepsController();
        breachController.getbreachedSteps();
        
        Test.stopTest();
    }
}