/**
 *
 * Test class for CC_ManageAutoApproval
 */
@isTest
private class CC_ManageAutoApprovalTest {

        //Create setupData
        @testSetup static void setupData() {
            Map<String,Id> recordTypeSR = new Map<String,Id>();
            for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'LPCWaiver']){
                recordTypeSR.put(rtype.DeveloperName,rtype.Id);
            }
    
            Account acc = TestObjectsFactory.getPersonAccountRecord();
            insert acc;
            
            Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
            insert opp;
            
            Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
            unit.Status__c = 'Sold';
            insert unit;
            
            SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
            salesOrder.Unit__c = unit.Id;
            insert salesOrder;
    
            HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
            insert objSRStatus;

            HexaBPM__SR_Status__c objSRStatus1 = TestObjectsFactory.getSRStatus('Approved by Director of CM');
            insert objSRStatus1;
            
            
            HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
            SR_Template.Name = 'LPC Waiver';
            SR_Template.HexaBPM__SR_RecordType_API_Name__c='LPCWaiver';
            insert SR_Template;
            
            HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
            SR.RecordTypeId = recordTypeSR.get('LPCWaiver');
            SR.HexaBPM__Customer__c = acc.Id;
            SR.HexaBPM__Contact__c = acc.PersonContactId;
            SR.OwnerId = UserInfo.getUserId();
            SR.HexaBPM__SR_Template__c = SR_Template.Id;
            SR.Unit__c = unit.Id;
            SR.SalesOrder__c = salesOrder.Id;
            insert SR;
    
            HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
            ST.Name = 'Verify the Request';
            ST.HexaBPM__Code__c = 'Verify the Request';
            ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
            insert ST;
            
            HexaBPM__Step_Template__c ST1 = new HexaBPM__Step_Template__c();
            ST1.Name = 'Verification by Finance';
            ST1.HexaBPM__Code__c = 'Verification by Finance';
            ST1.HexaBPM__Step_RecordType_API_Name__c = 'General';
            insert ST1;

            HexaBPM__Status__c status1 = new HexaBPM__Status__c();
            status1.Name = Constants.PENDING_STATUS;
            status1.HexaBPM__Code__c = Constants.PENDING_STATUS;
            insert status1;

            HexaBPM__Status__c status2 = new HexaBPM__Status__c();
            status2.Name = Constants.STATUS_APPROVED;
            status2.HexaBPM__Code__c = Constants.STATUS_APPROVED;
            insert status2;

            HexaBPM__Status__c status3 = new HexaBPM__Status__c();
            status3.Name = Constants.COMPLETED_STATUS;
            status3.HexaBPM__Code__c = Constants.COMPLETED_STATUS;
            insert status3;
            
            HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
            SRStep.HexaBPM__SR_Template__c = SR_Template.id;
            SRStep.HexaBPM__Step_No__c = 2;
            SRStep.HexaBPM__Step_Template__c = ST1.Id;
            SRStep.HexaBPM__Summary__c = 'Verification by Finance';
            SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
          //  SRStep.HexaBPM__Step_Status__c = status2.HexaBPM__Code__c;
            insert SRStep;
            
                
            HexaBPM__Step__c step = new HexaBPM__Step__c();
            step.HexaBPM__Summary__c = 'Verification by Finance';
            step.HexaBPM__SR__c = SR.Id;
            step.HexaBPM__SR_Step__c = SRStep.Id;
            step.HexaBPM__Start_Date__c = System.today();
            step.HexaBPM__Status__c =status1.id;
            insert step; 

            HexaBPM__SR_Steps__c SRStep2 = new HexaBPM__SR_Steps__c();
            SRStep2.HexaBPM__SR_Template__c = SR_Template.id;
            SRStep2.HexaBPM__Step_No__c = 1;
            SRStep2.HexaBPM__Step_Template__c = ST.Id;
            SRStep2.HexaBPM__Summary__c = 'Verify the Request';
            SRStep2.HexaBPM__Step_RecordType_API_Name__c = 'General';
          //  SRStep.HexaBPM__Step_Status__c = status2.HexaBPM__Code__c;
            insert SRStep2;

            HexaBPM__Step__c step1 = new HexaBPM__Step__c();
            step1.HexaBPM__Summary__c = 'Verify the Request';
            step1.HexaBPM__SR__c = SR.Id;
            step1.HexaBPM__SR_Step__c = SRStep2.Id;
            step1.HexaBPM__Start_Date__c = System.today();
            step1.HexaBPM__Status__c =status2.id;
            insert step1; 

            HexaBPM__Transition__c txnstatus = new HexaBPM__Transition__c();
            txnstatus.HexaBPM__From__c = status1.id;
            txnstatus.HexaBPM__To__c = status3.id;
            insert txnstatus;

            HexaBPM__Step_Transition__c txn = new HexaBPM__Step_Transition__c();
           
            txn.HexaBPM__SR_Step__c = step.HexaBPM__SR_Step__c;
            txn.HexaBPM__Evaluate_Refund__c = false;
            txn.HexaBPM__Display_on_Portal__c = true;
            txn.HexaBPM__SR_Status_Internal__c = objSRStatus1.id;
            txn.HexaBPM__SR_Status_External__c = objSRStatus1.id;
           // txn.HexaBPM__Start_Date__c = System.today();
            txn.HexaBPM__Transition__c = txnstatus.id;
            insert txn; 
            }


    @isTest
    public static void callMethod (){

        HexaBPM__Status__c approvedStatus = [Select id,Name from HexaBPM__Status__c where Name =:Constants.STATUS_APPROVED LIMIT 1];
        
        HexaBPM__Service_Request__c SR = [Select Id, HexaBPM__External_SR_Status__c, HexaBPM__Internal_SR_Status__c, SalesOrder__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id ,HexaBPM__Step_Status__c, HexaBPM__Step_Notes__c,HexaBPM__Status__c,OwnerId, OwnerName__c, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verification by Finance' AND HexaBPM__SR__c != null ORDER BY CreatedDate DESC limit 1];
		    HexaBPM__Step_Transition__c stpTxn = [select id, HexaBPM__To__c, HexaBPM__SR_Step__c, HexaBPM__SR_Status_Internal__c,HexaBPM__SR_Status_External__c from HexaBPM__Step_Transition__c];

        Test.startTest();
        CC_ManageAutoApproval cc = new CC_ManageAutoApproval();
        
        User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
        System.runAs(systemAdmin) {
           cc.EvaluateCustomCode(SR, stp);
        }

        HexaBPM__Transition__c txnstatus = [Select HexaBPM__To__c from HexaBPM__Transition__c];
        txnstatus.HexaBPM__To__c = approvedStatus.id;
        update txnstatus;

        cc.EvaluateCustomCode(SR, stp);
         
       // System.assert(stp.HexaBPM__Step_Status__c == approvedStatus.Name, 'Expected result is Approved');

        Test.stopTest();
    }


}