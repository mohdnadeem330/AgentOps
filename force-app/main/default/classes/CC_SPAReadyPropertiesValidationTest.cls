@isTest
private class CC_SPAReadyPropertiesValidationTest {
  
    //Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'LPCWaiver']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }

        Account orgAcc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert orgAcc;
        
        Contact con = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        con.Email = 'Ali.athamneh@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(orgAcc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, orgAcc.Id);
        salesOrder.Unit__c = unit.Id;
		salesOrder.Opportunity__c = opp.Id;
        salesOrder.Account__c = orgAcc.Id;
        salesOrder.Contact__c = con.Id;
        insert salesOrder;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'LPC Waiver';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='LPCWaiver';
        insert SR_Template;
        
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('LPCWaiver');
        SR.HexaBPM__Customer__c = orgAcc.Id;
        SR.HexaBPM__Contact__c = con.Id;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        insert SR;

        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Verification & Submission of the Request For SPA';
        ST.HexaBPM__Code__c = 'Verification & Submission of the Request For SPA';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Verification & Submission of the Request For SPA';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
            
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Verification & Submission of the Request For SPA';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
        
        HexaBPM__Step_Template__c ST1 = new HexaBPM__Step_Template__c();
        ST1.Name = 'SOA Verification';
        ST1.HexaBPM__Code__c = 'SOA Verification';
        ST1.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST1;
        
        HexaBPM__SR_Steps__c SRStep1 = new HexaBPM__SR_Steps__c();
        SRStep1.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep1.HexaBPM__Step_No__c = 1;
        SRStep1.HexaBPM__Step_Template__c = ST1.Id;
        SRStep1.HexaBPM__Summary__c = 'SOA Verification';
        SRStep1.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep1;
        
            
        HexaBPM__Step__c step1 = new HexaBPM__Step__c();
        step1.HexaBPM__Summary__c = 'SOA Verification';
        step1.HexaBPM__SR__c = SR.Id;
        step1.HexaBPM__SR_Step__c = SRStep1.Id;
        step1.HexaBPM__Start_Date__c = System.today();
        insert step1;
                
        HexaBPM__Step_Template__c ST3 = new HexaBPM__Step_Template__c();
        ST3.Name = 'Evaluation Submission & Payment Completion';
        ST3.HexaBPM__Code__c = 'Evaluation Submission & Payment Completion';
        ST3.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST3;
        
        HexaBPM__SR_Steps__c SRStep3 = new HexaBPM__SR_Steps__c();
        SRStep3.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep3.HexaBPM__Step_No__c = 1;
        SRStep3.HexaBPM__Step_Template__c = ST3.Id;
        SRStep3.HexaBPM__Summary__c = 'Evaluation Submission & Payment Completion';
        SRStep3.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep3;
        
            
        HexaBPM__Step__c step3 = new HexaBPM__Step__c();
        step3.HexaBPM__Summary__c = 'Evaluation Submission & Payment Completion';
        step3.HexaBPM__SR__c = SR.Id;
        step3.HexaBPM__SR_Step__c = SRStep3.Id;
        step3.HexaBPM__Start_Date__c = System.today();
        insert step3;
        
        HexaBPM__Step_Template__c ST4 = new HexaBPM__Step_Template__c();
        ST4.Name = 'Initiate Registration For Title Deed';
        ST4.HexaBPM__Code__c = 'Initiate Registration For Title Deed';
        ST4.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST4;
        
        HexaBPM__SR_Steps__c SRStep4 = new HexaBPM__SR_Steps__c();
        SRStep4.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep4.HexaBPM__Step_No__c = 1;
        SRStep4.HexaBPM__Step_Template__c = ST4.Id;
        SRStep4.HexaBPM__Summary__c = 'Initiate Registration For Title Deed';
        SRStep4.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep4;
        
            
        HexaBPM__Step__c step4 = new HexaBPM__Step__c();
        step4.HexaBPM__Summary__c = 'Initiate Registration For Title Deed';
        step4.HexaBPM__SR__c = SR.Id;
        step4.HexaBPM__SR_Step__c = SRStep4.Id;
        step4.HexaBPM__Start_Date__c = System.today();
        insert step4;


        ///////

        HexaBPM__Step_Template__c ST5 = new HexaBPM__Step_Template__c();
        ST5.Name = 'Registration In Progress For Title Deed';
        ST5.HexaBPM__Code__c = 'Registration In Progress For Title Deed';
        ST5.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST5;
        
        HexaBPM__SR_Steps__c SRStep5 = new HexaBPM__SR_Steps__c();
        SRStep5.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep5.HexaBPM__Step_No__c = 1;
        SRStep5.HexaBPM__Step_Template__c = ST5.Id;
        SRStep5.HexaBPM__Summary__c = 'Registration In Progress For Title Deed';
        SRStep5.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep5;
        
            
        HexaBPM__Step__c step5 = new HexaBPM__Step__c();
        step5.HexaBPM__Summary__c = 'Registration In Progress For Title Deed';
        step5.HexaBPM__SR__c = SR.Id;
        step5.HexaBPM__SR_Step__c = SRStep5.Id;
        step5.HexaBPM__Start_Date__c = System.today();
        insert step5;

        ////////

        HexaBPM__Step_Template__c ST6 = new HexaBPM__Step_Template__c();
        ST6.Name = 'Registration Completion For Title Deed';
        ST6.HexaBPM__Code__c = 'Registration Completion For Title Deed';
        ST6.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST6;
        
        HexaBPM__SR_Steps__c SRStep6 = new HexaBPM__SR_Steps__c();
        SRStep6.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep6.HexaBPM__Step_No__c = 1;
        SRStep6.HexaBPM__Step_Template__c = ST6.Id;
        SRStep6.HexaBPM__Summary__c = 'Registration Completion For Title Deed';
        SRStep6.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep6;
        
            
        HexaBPM__Step__c step6 = new HexaBPM__Step__c();
        step6.HexaBPM__Summary__c = 'Registration Completion For Title Deed';
        step6.HexaBPM__SR__c = SR.Id;
        step6.HexaBPM__SR_Step__c = SRStep6.Id;
        step6.HexaBPM__Start_Date__c = System.today();
        insert step6;
        
        HexaBPM__Step_Template__c ST7 = new HexaBPM__Step_Template__c();
        ST7.Name = 'SPA Registration Completion For SPA';
        ST7.HexaBPM__Code__c = 'SPA Registration Completion For SPA';
        ST7.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST7;
        
        HexaBPM__SR_Steps__c SRStep7 = new HexaBPM__SR_Steps__c();
        SRStep7.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep7.HexaBPM__Step_No__c = 1;
        SRStep7.HexaBPM__Step_Template__c = ST7.Id;
        SRStep7.HexaBPM__Summary__c = 'SPA Registration Completion For SPA';
        SRStep7.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep7;
        
            
        HexaBPM__Step__c step7 = new HexaBPM__Step__c();
        step7.HexaBPM__Summary__c = 'SPA Registration Completion For SPA';
        step7.HexaBPM__SR__c = SR.Id;
        step7.HexaBPM__SR_Step__c = SRStep7.Id;
        step7.HexaBPM__Start_Date__c = System.today();
        insert step7;
       
    }
    
    @isTest
    public static void callVerificationSubmissionoftheRequestForSPA (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__Summary__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verification & Submission of the Request For SPA' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        CC_SPAReadyPropertiesValidation cc = new CC_SPAReadyPropertiesValidation();
        cc.EvaluateCustomCode(SR, stp);
		cc.EvaluateCustomCode(null, null);

        stp = [Select Id, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verification & Submission of the Request For SPA' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        cc.EvaluateCustomCode(SR, stp);
        
        Test.stopTest();
    }
    
    @isTest
    public static void callVerificationSubmissionoftheRequestForSPA2 (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, HexaBPM__Summary__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verification & Submission of the Request For SPA' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        CC_SPAReadyPropertiesValidation cc = new CC_SPAReadyPropertiesValidation();
        cc.EvaluateCustomCode(SR, stp);
        
        Test.stopTest();
    }
    
     @isTest
    public static void callSOAVerification (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'SOA Verification' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];

        CC_SPAReadyPropertiesValidation cc = new CC_SPAReadyPropertiesValidation();

        cc.EvaluateCustomCode(SR, stp); 
        HexaBPM__Service_Request__c sRRecord = [SELECT Id, Name, SalesOrder__c, SPAApplicationNumber__c, SPAApplicationDate__c, HexaBPM__Contact__c, Unit__r.Name, Unit__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
		CC_SPAReadyPropertiesValidation.soaVerification(sRRecord);
        Test.stopTest();
    }
    
     @isTest
    public static void callEvaluationSubmissionPaymentCompletion (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, ApplicationNumber__c, MortgageApplicable__c, MortgageApplicationNumber__c, MortgageBank__c, MortgageAmount__c, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, HexaBPM__Summary__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Evaluation Submission & Payment Completion' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        CC_SPAReadyPropertiesValidation cc = new CC_SPAReadyPropertiesValidation();

        cc.EvaluateCustomCode(SR, stp);
        
        Test.stopTest();
    }
    
     @isTest
    public static void callInitiateRegistrationForTitleDeed (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, HexaBPM__Summary__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Initiate Registration For Title Deed' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        CC_SPAReadyPropertiesValidation cc = new CC_SPAReadyPropertiesValidation();

        cc.EvaluateCustomCode(SR, stp);
        
        Test.stopTest();
    }
    
    @isTest
    public static void callRegistrationInProgressForTitleDeed (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, HexaBPM__Summary__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Registration In Progress For Title Deed' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        CC_SPAReadyPropertiesValidation cc = new CC_SPAReadyPropertiesValidation();

        cc.EvaluateCustomCode(SR, stp);
        
        SR.InProgressDate__c = Date.Today();
        SR.ElectronicServiceCharge__c = 100;
        SR.TitleDeedRegistrationFee__c = 200;
        SR.MortgageRegistrationFees__c = 300;
        SR.EvaluationFee__c = 400;
        update SR;
        
        cc.EvaluateCustomCode(SR, stp);

        Test.stopTest();
    }

    @isTest
    public static void callRegistrationCompletionForTitleDeed (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, HexaBPM__Summary__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Registration Completion For Title Deed' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        CC_SPAReadyPropertiesValidation cc = new CC_SPAReadyPropertiesValidation();

        cc.EvaluateCustomCode(SR, stp);
        
        SR.RegistrationDate__c = Date.today();
        update SR;
        cc.EvaluateCustomCode(SR, stp);
        
        
        Test.stopTest();
    }
    
    @isTest
    public static void callSPARegistrationCompletionForSPA (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c, HexaBPM__Summary__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'SPA Registration Completion For SPA' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
        CC_SPAReadyPropertiesValidation cc = new CC_SPAReadyPropertiesValidation();

        cc.EvaluateCustomCode(SR, stp);
        
        SR.PaymentDate__c = Date.today();
        SR.SPARegistrationDate__c = Date.today();
        update SR;
        
        cc.EvaluateCustomCode(SR, stp);
        
        
        Test.stopTest();
    }

}