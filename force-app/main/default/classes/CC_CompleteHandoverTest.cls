/**
* CC_CompleteHandoverTest
*
* Test class for CC_CompleteHandover
*/
@isTest
private class CC_CompleteHandoverTest {
    @testSetup 
    static void setupData() {
        Id handoverRecordType = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = Constants.UNIT_STATUS_SOLD;
        unit.UnitType__c = 'Villa';
        insert unit;
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.RTOConverted__c = False;
        insert salesOrder;
        Account newAcc = TestObjectsFactory.getPersonAccountRecord();
        insert newAcc;
        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, newAcc.Id, 'Friend Of');
        jointOwner.SharePercentage__c = 10;
        insert jointOwner;
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = Constants.RECORDTYPE_HANDOVER;
        SR_Template.HexaBPM__SR_RecordType_API_Name__c = Constants.RECORDTYPE_HANDOVER;
        insert SR_Template;
        // Ensure Onboarding_Handover Queue exists
        Group onboardingQueue;
        List<Group> existingQueues = [SELECT Id FROM Group WHERE DeveloperName = 'Onboarding_Handover' LIMIT 1];
        if (!existingQueues.isEmpty()) {
            onboardingQueue = existingQueues[0];
        } else {
            onboardingQueue = new Group(Name = 'Onboarding_Handover', DeveloperName = 'Onboarding_Handover', Type = 'Queue');
            insert onboardingQueue;
        }
        // Create HandoverDetail__c with OutstandingAmount__c <= 100
        HandoverDetails__c handoverDetail = new HandoverDetails__c();
//        handoverDetail.OutstandingAmount__c = 0;
        insert handoverDetail;
        // Insert step templates
        List<HexaBPM__Step_Template__c> stepTemplateToInsert = new List<HexaBPM__Step_Template__c>();
        List<String> templatesCode = new List<String>{
            Constants.STEP_NAME_KAR_ASSIGNMENT,
            Constants.STEP_NAME_FINANCE_VERIFICATION,
            Constants.STEP_NAME_DESNAGGING_APPOINTMENT,
            Constants.STEP_NAME_UTILITY_TRANSFER,
            Constants.STEP_NAME_KEYHANDOVER_APPOINTMENT,
            Constants.STEP_NAME_SNAGGING_APPOINTMENT,
            Constants.STEP_NAME_HANDOVER_PHASING,
            Constants.STEP_NAME_TITLE_DEED
        };
        for(String tempS : templatesCode){
            HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
            ST.Name = tempS;
            ST.HexaBPM__Code__c = tempS;
            ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
            stepTemplateToInsert.add(ST);
        }
        insert stepTemplateToInsert;
        List<HexaBPM__SR_Steps__c> templateSteps = new List<HexaBPM__SR_Steps__c>();
        for(HexaBPM__Step_Template__c tempRec : stepTemplateToInsert){
            HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
            SRStep.HexaBPM__SR_Template__c = SR_Template.id;
            SRStep.HexaBPM__Step_No__c = templateSteps.size() + 1;
            SRStep.HexaBPM__Step_Template__c = tempRec.Id;
            SRStep.HexaBPM__Summary__c = tempRec.Name;
            SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
            templateSteps.add(SRStep);
        }
        insert templateSteps;
        // Insert SR Status records (if needed)
        insert new List<HexaBPM__SR_Status__c>{
            TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_APPOINTMENT_BOOKED),
            TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_SENT),
            TestObjectsFactory.getSRStatus(Constants.SUBMITTED),
            TestObjectsFactory.getSRStatus(Constants.STATUS_DRAFT)
        };
        // Create the Service Request linked to handoverDetail and other setup
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = handoverRecordType;
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.HandoverDetail__c = handoverDetail.Id;
        insert SR;
        // Create Steps for the SR
        List<HexaBPM__Step__c> srSteps = new List<HexaBPM__Step__c>();
        for(HexaBPM__SR_Steps__c tempRec : templateSteps){
            HexaBPM__Step__c step = new HexaBPM__Step__c();
            step.HexaBPM__Summary__c = tempRec.HexaBPM__Summary__c;
            step.HexaBPM__SR__c = SR.Id;
            step.HexaBPM__SR_Step__c = tempRec.Id;
            step.HexaBPM__Start_Date__c = System.today();
            srSteps.add(step);
        }
        insert srSteps;
    }
 @isTest
    public static void callMethod () {
        HexaBPM__Service_Request__c SR = [SELECT Id, SalesOrder__c,SalesOrder__r.RTOConverted__c,Unit__c,Unit__r.UnitType__c, HAndoverDetail__c FROM HexaBPM__Service_Request__c LIMIT 1];
        HexaBPM__Step__c stp = [SELECT Id, HexaBPM__SR__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c = :SR.Id LIMIT 1];
        Test.startTest();
        CC_CompleteHandover completeHandover = new CC_CompleteHandover();
        String result = completeHandover.EvaluateCustomCode(SR, stp);
        Test.stopTest();
        // Verify Case creation
        List<Case> cases = [SELECT Id, OwnerId, Status FROM Case WHERE ServiceRequest__c = :SR.Id];
  //      System.assert(!cases.isEmpty(), 'Expected Case to be created');
    } 

    @isTest
    public static void callMethodWithOrganizationAcc () {
        Test.startTest();
        Account newAccOrg = TestObjectsFactory.getOrganisationAccountRecord('ACC','001');
        insert newAccOrg;
        newAccOrg.EmailAddress__c = 'speddireddi@aldar.com';
        update newAccOrg;
        HexaBPM__Service_Request__c SR = [SELECT Id, SalesOrder__c FROM HexaBPM__Service_Request__c LIMIT 1];
        SR.HexaBPM__Customer__c = newAccOrg.Id;
        update SR;
        HexaBPM__Step__c stp = [SELECT Id, HexaBPM__SR__c FROM HexaBPM__Step__c LIMIT 1];
        CC_CompleteHandover cc = new CC_CompleteHandover();
        cc.EvaluateCustomCode(SR, stp);
        cc.EvaluateCustomCode(null, null);
        Test.stopTest();
    }
    
}