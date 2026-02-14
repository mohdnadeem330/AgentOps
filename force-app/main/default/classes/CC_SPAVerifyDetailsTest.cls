@isTest
private class CC_SPAVerifyDetailsTest {
  
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
        ST1.Name = 'Verify and Close';
        ST1.HexaBPM__Code__c = 'Verify and Close';
        ST1.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST1;
        
        HexaBPM__SR_Steps__c SRStep1 = new HexaBPM__SR_Steps__c();
        SRStep1.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep1.HexaBPM__Step_No__c = 1;
        SRStep1.HexaBPM__Step_Template__c = ST.Id;
        SRStep1.HexaBPM__Summary__c = 'Verify and Close';
        SRStep1.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep1;
        
        HexaBPM__Step__c step1 = new HexaBPM__Step__c();
        step1.HexaBPM__Summary__c = 'Verify and Close';
        step1.HexaBPM__SR__c = SR.Id;
        step1.HexaBPM__SR_Step__c = SRStep.Id;
        step1.HexaBPM__Start_Date__c = System.today();
        insert step1; 
        
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
        
    }
    
    @isTest
    public static void callMethod (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify Details' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
        
		CC_SPAVerifyDetails cc = new CC_SPAVerifyDetails();
		cc.EvaluateCustomCode(SR, stp);
        
        stp = [Select Id, HexaBPM__SR__c, HexaBPM__Summary__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify Details' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
		cc.EvaluateCustomCode(SR, stp); 
		cc.EvaluateCustomCode(null, null);
        
        User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        System.runAs(systemAdmin) {
           cc.EvaluateCustomCode(SR, stp);
        }
        
        User systemAdmin1 = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        systemAdmin1.EmirateId__c = '123455677';
        System.runAs(systemAdmin1) {
			cc.EvaluateCustomCode(SR, stp);
            
			stp = [Select Id, HexaBPM__SR__c, HexaBPM__Summary__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify and Close' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
			cc.EvaluateCustomCode(SR, stp);

        }

        Test.stopTest();
    }
}