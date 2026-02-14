@isTest
private class CC_SRJointOwnerControllerTest {
  
    //Create setupData
    @testSetup static void setupData() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'JointOwner']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        
        HexaBPM__SR_Template__c SR_Template2 = new HexaBPM__SR_Template__c();
        SR_Template2.Name = 'Addition Joint Owner';
        SR_Template2.HexaBPM__SR_RecordType_API_Name__c='AdditionJointOwner';
        insert SR_Template2;
        
        HexaBPM__SR_Template__c SR_Template3 = new HexaBPM__SR_Template__c();
        SR_Template3.Name = 'Deletion Joint Owner';
        SR_Template3.HexaBPM__SR_RecordType_API_Name__c='DeletionJointOwner';
        insert SR_Template3;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.AmountPayable__c = 1000;
        insert salesOrder;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Cheque Replacement';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='Cheque Replacement';
        insert SR_Template;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('JointOwner');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template2.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.ApplicationNumber__c = '1';
        insert SR;
        
        HexaBPM__Service_Request__c SR1 = new HexaBPM__Service_Request__c();
        SR1.RecordTypeId = recordTypeSR.get('JointOwner');
        SR1.HexaBPM__Customer__c = acc.Id;
        SR1.HexaBPM__Contact__c = acc.PersonContactId;
        SR1.OwnerId = UserInfo.getUserId();
        SR1.HexaBPM__SR_Template__c = SR_Template3.Id;
        SR1.Unit__c = unit.Id;
        SR1.ApplicationNumber__c = '2';
        SR1.SalesOrder__c = salesOrder.Id;
        insert SR1;

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
        
    }
    
    @isTest
    public static void callMethod (){
        Test.startTest();

        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c where ApplicationNumber__c = '1' Limit 1];
        HexaBPM__Service_Request__c SR1 = [Select Id, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c where ApplicationNumber__c = '2' Limit 1];

        HexaBPM__Step__c stp = [Select Id, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Prepare the Cheques' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];

        CC_SRJointOwnerController cc = new CC_SRJointOwnerController();
        
        cc.EvaluateCustomCode(SR, stp);
        
        SR.SRType__c = Constants.ADDITION_JOINT_OWNER_RT;
        update SR;
        cc.EvaluateCustomCode(SR, stp);

        SR1.SRType__c = Constants.DELETION_JOINT_OWNER_RT;
        update SR1;
        stp.HexaBPM__SR__c = SR1.Id;
        update stp;
        cc.EvaluateCustomCode(SR1, stp);
        
        AgencyTeam__c agencyTeam = new AgencyTeam__c();
        agencyTeam.Account__c = SR1.HexaBPM__Customer__c; 
        agencyTeam.ServiceRequest__c = SR1.Id;
        agencyTeam.ShareHoldingPercentage__c = 0;
        agencyTeam.RelationshipType__c = Constants.PRIMARY_OWNER;
        insert agencyTeam;
        
        cc.EvaluateCustomCode(SR1, stp);
        
        agencyTeam.RelationshipType__c = 'Spouse Of';
        agencyTeam.Description__c = Constants.PRIMARY_OWNER;
		update agencyTeam;
        
        cc.EvaluateCustomCode(SR1, stp);

        Test.stopTest();
    }
}