@isTest
private class CC_SPAPaymentTest {
  
    //Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'PaymentExtension']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }

        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;

        HexaBPM__SR_Status__c objSRStatus1 = TestObjectsFactory.getSRStatus(Constants.PENDING_STATUS);
        insert objSRStatus1;

        HexaBPM__SR_Status__c objSRStatus2 = TestObjectsFactory.getSRStatus(Constants.COMPLETED_STATUS);
        insert objSRStatus2;
        
        HexaBPM__SR_Status__c objSRStatus3 = TestObjectsFactory.getSRStatus(Constants.STEP_APPROVED_STATUS);
        insert objSRStatus3;

        HexaBPM__SR_Status__c objSRStatus4 = TestObjectsFactory.getSRStatus(Constants.STEP_ACCEPTED_STATUS);
        insert objSRStatus4;
        
        HexaBPM__SR_Status__c objSRStatus5 = TestObjectsFactory.getSRStatus(Constants.STEP_REJECTED_STATUS);
        insert objSRStatus5;
        
        HexaBPM__SR_Template__c SR_Template2 = new HexaBPM__SR_Template__c();
        SR_Template2.Name = 'Payment Extension';
        SR_Template2.HexaBPM__SR_RecordType_API_Name__c='PaymentExtension';
        insert SR_Template2;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Cheque Replacement';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='Cheque Replacement';
        insert SR_Template;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('PaymentExtension');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        insert SR;

        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Prepare the Cheques';
        ST.HexaBPM__Code__c = 'Prepare the Cheques';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Prepare the Cheques';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Prepare the Cheques';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
        
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'General_Information_for_Regulated_Activities';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;

        HexaBPM__Document_Master__c objSignedDocMaster = new HexaBPM__Document_Master__c();
        objSignedDocMaster.HexaBPM__Code__c = 'Signed_General_Information_for_Regulated_Activities';
        objSignedDocMaster.HexaBPM__Available_to_client__c = true;
        insert objSignedDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        insert docTemp;

        HexaBPM__SR_Template_Docs__c docSignedTemp = new HexaBPM__SR_Template_Docs__c();
        docSignedTemp.HexaBPM__Document_Master__c = objSignedDocMaster.id ;
        insert docSignedTemp;

        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objSignedDocMaster.id;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = SR.id;
        insert objSRDoc;

        HexaBPM__SR_Doc__c objSignedSRDoc = new HexaBPM__SR_Doc__c();
        objSignedSRDoc.HexaBPM__Document_Master__c = objDocMaster.id;
        objSignedSRDoc.HexaBPM__SR_Template_Doc__c = docSignedTemp.id;
        objSignedSRDoc.HexaBPM__Service_Request__c = SR.id ;
        insert objSignedSRDoc;
        
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = Constants.PENDING_STATUS;
        status.HexaBPM__Code__c = Constants.PENDING_STATUS;
        insert status;

        HexaBPM__Status__c status1 = new HexaBPM__Status__c();
        status1.Name = Constants.COMPLETED_STATUS;
        status1.HexaBPM__Code__c = Constants.COMPLETED_STATUS;
        insert status1;
        
        HexaBPM__Status__c status2 = new HexaBPM__Status__c();
        status2.Name = Constants.STEP_APPROVED_STATUS;
        status2.HexaBPM__Code__c = Constants.STEP_APPROVED_STATUS;
        insert status2;
        
         HexaBPM__Step_Template__c ST3 = new HexaBPM__Step_Template__c();
        ST3.Name = 'Payment Step';
        ST3.HexaBPM__Code__c = 'Payment Step';
        ST3.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST3;

        HexaBPM__SR_Steps__c SRStep3 = new HexaBPM__SR_Steps__c();
        SRStep3.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep3.HexaBPM__Step_No__c = 1;
        SRStep3.HexaBPM__Step_Template__c = ST3.Id;
        SRStep3.HexaBPM__Summary__c = 'Payment Step';
        SRStep3.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep3;
        
        HexaBPM__Step__c step3 = new HexaBPM__Step__c();
        step3.HexaBPM__Summary__c = 'Payment Step';
        step3.HexaBPM__SR__c = SR.Id;
        step3.HexaBPM__SR_Step__c = SRStep3.Id;
        step3.HexaBPM__Start_Date__c = System.today();
        insert step3;
    }
    
    @isTest
    public static void callMethod (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Prepare the Cheques' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
		CC_SPAPayment cc = new CC_SPAPayment();
		cc.EvaluateCustomCode(SR, stp);
        
        stp = [Select Id, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Prepare the Cheques' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
		cc.EvaluateCustomCode(SR, stp); 
		cc.EvaluateCustomCode(null, null);
        
        User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        System.runAs(systemAdmin) {
           cc.EvaluateCustomCode(SR, stp);
        }
        
        User systemAdmin1 = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        systemAdmin1.EmirateId__c = '123455677';
        insert systemAdmin1;
        System.runAs(systemAdmin1) {
           cc.EvaluateCustomCode(SR, stp);
        }

        Test.stopTest();
    }
}