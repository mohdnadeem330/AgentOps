@isTest
private class JointOwnerControllerTest {
  
    //Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'SPARegistrationForOffPlan']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.NationalIdNumber__pc = '';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Account__c = acc.Id;
        salesOrder.Opportunity__c = opp.Id;
        insert salesOrder;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 4);

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

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'SPA Registration For Off Plan';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='SPARegistrationForOffPlan';
        insert SR_Template;
        
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('SPARegistrationForOffPlan');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        insert SR;

        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Verify Details';
        ST.HexaBPM__Code__c = 'Verify Details';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Verify Details';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Verify Details';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 

        HexaBPM__Step_Template__c ST1 = new HexaBPM__Step_Template__c();
        ST1.Name = 'Submit Registration';
        ST1.HexaBPM__Code__c = 'Submit Registration';
        ST1.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST1;

        HexaBPM__SR_Steps__c SRStep1 = new HexaBPM__SR_Steps__c();
        SRStep1.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep1.HexaBPM__Step_No__c = 1;
        SRStep1.HexaBPM__Step_Template__c = ST1.Id;
        SRStep1.HexaBPM__Summary__c = 'Submit Registration';
        SRStep1.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep1;
        
        HexaBPM__Step__c step1 = new HexaBPM__Step__c();
        step1.HexaBPM__Summary__c = 'Submit Registration';
        step1.HexaBPM__SR__c = SR.Id;
        step1.HexaBPM__SR_Step__c = SRStep1.Id;
        step1.HexaBPM__Start_Date__c = System.today();
        insert step1; 

        HexaBPM__Step_Template__c ST2 = new HexaBPM__Step_Template__c();
        ST2.Name = 'Salesforce - Approval';
        ST2.HexaBPM__Code__c = 'Salesforce - Approval';
        ST2.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST2;

        HexaBPM__SR_Steps__c SRStep2 = new HexaBPM__SR_Steps__c();
        SRStep2.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep2.HexaBPM__Step_No__c = 1;
        SRStep2.HexaBPM__Step_Template__c = ST2.Id;
        SRStep2.HexaBPM__Summary__c = 'Salesforce - Approval';
        SRStep2.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep2;
        
        HexaBPM__Step__c step2 = new HexaBPM__Step__c();
        step2.HexaBPM__Summary__c = 'Salesforce - Approval';
        step2.HexaBPM__SR__c = SR.Id;
        step2.HexaBPM__SR_Step__c = SRStep2.Id;
        step2.HexaBPM__Start_Date__c = System.today();
        insert step2;

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

        HexaBPM__Step_Template__c ST4 = new HexaBPM__Step_Template__c();
        ST4.Name = 'ADM Team Approval';
        ST4.HexaBPM__Code__c = 'ADM Team Approval';
        ST4.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST4;

        HexaBPM__SR_Steps__c SRStep4 = new HexaBPM__SR_Steps__c();
        SRStep4.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep4.HexaBPM__Step_No__c = 1;
        SRStep4.HexaBPM__Step_Template__c = ST4.Id;
        SRStep4.HexaBPM__Summary__c = 'ADM Team Approval';
        SRStep4.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep4;
        
        HexaBPM__Step__c step4 = new HexaBPM__Step__c();
        step4.HexaBPM__Summary__c = 'ADM Team Approval';
        step4.HexaBPM__SR__c = SR.Id;
        step4.HexaBPM__SR_Step__c = SRStep4.Id;
        step4.HexaBPM__Start_Date__c = System.today();
        insert step4; 

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
        

        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'Aldar Signed SPA';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        insert docTemp;
        
        
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = SR.id  ;
        objSRDoc.Name = 'Aldar Signed SPA';
        insert objSRDoc;

        TestObjectsFactory.createContentDocumentLink(objSRDoc.Id);
    }
    
    @isTest
    public static void callMethod (){
        Test.startTest();
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Account__c From HexaBPM__Service_Request__c Limit 1];

        JointOwnerController.getServiceRequestDetail(SR.Id);

        List<String> jj = new List<String>(); //JointOwnerController.JointOwnerDetailModel
        jj.add(JointOwnerController.getServiceRequestDetail(SR.Id));
        
        JointOwner__c jointOwner1 = TestObjectsFactory.getJointOwnerRecord(SR.SalesOrder__c, SR.SalesOrder__r.Account__c, 'Friend Of');
        insert jointOwner1;
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        JointOwner__c jointOwner2 = TestObjectsFactory.getJointOwnerRecord(SR.SalesOrder__c, acc.Id, 'Friend Of');
        insert jointOwner2;
        
        AgencyTeam__c agencyTeam = new AgencyTeam__c();
        agencyTeam.Account__c = SR.SalesOrder__r.Account__c;
        agencyTeam.ServiceRequest__c = SR.Id;
        agencyTeam.ShareHoldingPercentage__c = 20;
        agencyTeam.RelationshipType__c = 'Spouse Of';
        insert agencyTeam;
        
        String s = '[{"accountId":"' + acc.Id + '","relationType":"Friend Of","sharePercentage":"10","description":"Joint Owner"}]';

        JointOwnerController.getServiceRequestDetail(SR.Id);

        JointOwnerController.saveJointOwner(s, SR.Id, '');
        
        Test.stopTest();
    }
}