/*
*Created By     : Hardik Vitthani
*Description    : Test class for CC_SRCreateCancellation
*/
@isTest
public class StepTriggerHandlerTest {
    @testSetup static void methodName() {
        HexaBPM__SR_Status__c srStatus1 = new HexaBPM__SR_Status__c();
        srStatus1.HexaBPM__Code__c = 'Approved';
        srStatus1.Name = 'Approved';
        insert srStatus1;
        
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
        status1.Name = Constants.CLOSED_SR;
        status1.HexaBPM__Code__c = Constants.CLOSED_SR ;
        insert status1 ;
        
        HexaBPM__Status__c status2 = new HexaBPM__Status__c();
        status2.Name = 'Completed';
        status2.HexaBPM__Code__c = 'Completed';
        insert status2 ;

        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c();
        srStatus.HexaBPM__Code__c = 'Pending';
        srStatus.Name = 'Pending';
        insert srStatus;
        
        HexaBPM__Service_Request__c serviceRequest = new HexaBPM__Service_Request__c(
            HexaBPM__Customer__c = acc.Id,
            HexaBPM__SR_Template__c = SR_Template.Id,
            CompanyEmail__c = 'test@test.com',
            SRType__c = 'Agency Registration'
        );
        insert serviceRequest;
        
        

        List<HexaBPM__SR_Status__c> HexaBPMSRStatusList = new List<HexaBPM__SR_Status__c>();
        
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        HexaBPMSRStatusList.add(draft);
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        HexaBPMSRStatusList.add(Submitted);
        
        HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
        HexaBPMSRStatusList.add(approvedByFinance);
        
        insert HexaBPMSRStatusList;

        HexaBPM__Step__c step = new HexaBPM__Step__c(
            HexaBPM__Summary__c = 'require more information',
            HexaBPM__SR__c = serviceRequest.Id,
            HexaBPM__Status__c = status.Id,
            HexaBPM__Start_Date__c = System.today(),
            HexaBPM__Due_Date__c = System.today().addDays(10)
        );
        insert step;
        step.OwnerId = UserInfo.getUserId();
        Update step;
        
        
        HexaBPM__Step__c nocSr = new HexaBPM__Step__c(
            HexaBPM__Summary__c = 'Pending upload Provis Docs by Customer',
            HexaBPM__SR__c = serviceRequest.Id,
            HexaBPM__Status__c = status.Id,
            HexaBPM__Start_Date__c = System.today(),
            HexaBPM__Due_Date__c = System.today().addDays(10)
            
        );
        insert nocSr;
        
    
        
    }

  

    @isTest
    private static void coveredSLA(){        

        List<HexaBPM__Step__c> step = [SELECT Id,HexaBPM__Step_Status__c,HexaBPM__Summary__c FROM HexaBPM__Step__c WHERE HexaBPM__Step_Status__c != 'Completed'];
        Test.startTest();
        try{
            Decimal a;
            Decimal b = a/0;
        }catch(Exception e){
            StepTriggerHandler.createLogs(e,'', '',new List<String>{'test'},new List<HexaBPM__Step__c>{step[0]});
        }
        
        
        List<HexaBPM__Service_Request__c> serviceRequest = [SELECT Id FROM HexaBPM__Service_Request__c];
         
        StepTriggerHandler.updateStepAndSRAutoComplete(new Set<Id>{step[0].Id});
        StepTriggerHandler.callingBatchAsUtilityToSendEmailFuture(new Set<Id>{serviceRequest[0].Id});
        
        
        step[0].HexaBPM__Summary__c = 'Pending upload Provis Docs by Customer';
        step[0].HexaBPM__Status__c = [SELECT Id FROM HexaBPM__Status__c WHERE HexaBPM__Code__c = 'Completed'].Id;
        update step[0];
        
        
        
        Test.stopTest();

    }
    
   
    
     
}