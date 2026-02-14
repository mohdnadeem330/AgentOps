@isTest
public class CC_ProvisNOCValidationCtrlTest {

    @testSetup
    static void setupTestData() {
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert objSRStatus;
        // Create test Status records
        HexaBPM__Status__c pendingStatus = new HexaBPM__Status__c(Name = 'Pending',HexaBPM__Code__c='Pending');
        HexaBPM__Status__c completedStatus = new HexaBPM__Status__c(Name = 'Completed',HexaBPM__Code__c='Completed');
        insert new List<HexaBPM__Status__c>{ pendingStatus, completedStatus };

        // Create test Document Master records
        HexaBPM__Document_Master__c provisDoc1 = new HexaBPM__Document_Master__c(Name = 'Doc1', Is_Provis_Document__c = true);
        HexaBPM__Document_Master__c provisDoc2 = new HexaBPM__Document_Master__c(Name = 'Doc2', Is_Provis_Document__c = true);
        insert new List<HexaBPM__Document_Master__c>{ provisDoc1, provisDoc2 };

        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = Constants.UNIT_STATUS_SOLD;
        insert unit;
            
         RecordType recordType = [SELECT Id FROM RecordType WHERE SObjectType = 'HexaBPM__Service_Request__c' AND Name = 'Property Transfer NOC' LIMIT 1];   
        // Create test Service Request
        HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c(ProvisDocumentUploaded__c = true,TransferSellingPrice__c = 200000,Unit__c =unit.Id,SRType__c='Property Transfer NOC', RecordTypeId=recordType.Id);
        insert sr;
  HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.PROPERTY_TRANSFER_RT);        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Property Transfer', 'PropertyTransfer');
        objStepTemplate.HexaBPM__Code__c = 'Pending upload Provis Docs by Customer';
        insert objStepTemplate;
          HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        // Create test Step
        HexaBPM__Step__c step = new HexaBPM__Step__c(HexaBPM__SR__c = sr.Id);
        step.HexaBPM__SR_Step__c = objSRSteps.Id;
        step.HexaBPM__Status__c = pendingStatus.Id;
        step.HexaBPM__Summary__c = 'Pending upload Provis Docs by Customer';
        insert step;
		
        // Create test SR Docs
        HexaBPM__SR_Doc__c srDoc1 = new HexaBPM__SR_Doc__c(HexaBPM__Service_Request__c = sr.Id, Name = 'Doc1', HexaBPM__Status__c = 'Uploaded');
        HexaBPM__SR_Doc__c srDoc2 = new HexaBPM__SR_Doc__c(HexaBPM__Service_Request__c = sr.Id, Name = 'Doc2', HexaBPM__Status__c = 'Pending Upload');
        insert new List<HexaBPM__SR_Doc__c>{ srDoc1, srDoc2 };
    }

    @isTest
    static void testEvaluateCustomCode_success() {
        HexaBPM__Step__c step = [SELECT Id, HexaBPM__SR__c FROM HexaBPM__Step__c LIMIT 1];
        Test.startTest();
        CC_ProvisNOCValidationCtrl ccprovis =new CC_ProvisNOCValidationCtrl();
        string result = ccprovis.EvaluateCustomCode(
            [SELECT Id FROM HexaBPM__Service_Request__c WHERE Id = :step.HexaBPM__SR__c LIMIT 1],
            step
        );
        Test.stopTest();

        //System.assertEquals('Please ensure all the Provis Documents Approved.', result, 'Expected validation message mismatch.');
    }

    @isTest
    static void testEvaluateCustomCode_invalidSR() {
        Test.startTest();
        CC_ProvisNOCValidationCtrl ccprovis =new CC_ProvisNOCValidationCtrl();
        string result = ccprovis.EvaluateCustomCode(null, null);
        Test.stopTest();

        System.assertEquals('CC_ProvisNOCValidationCtrl: Invalid SR or SR Step', result, 'Expected invalid SR message mismatch.');
    }

    @isTest
    static void testReOpnRejectedDocs() {
        HexaBPM__SR_Doc__c srDoc = [SELECT Id FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Status__c = 'Pending Upload' LIMIT 1];

        Test.startTest();
        CC_ProvisNOCValidationCtrl.reOpnRejectedDocs(new Set<Id>{srDoc.Id});
        Test.stopTest();

        srDoc = [SELECT HexaBPM__Status__c FROM HexaBPM__SR_Doc__c WHERE Id = :srDoc.Id];
        System.assertEquals('Pending Upload', srDoc.HexaBPM__Status__c, 'Status should remain Pending Upload.');
    }

    @isTest
    static void testDocsApprovedValidation() {
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];

        Test.startTest();
        String result = CC_ProvisNOCValidationCtrl.docsApprovedValidation(new Set<Id>{sr.Id});
        CC_ProvisNOCValidationCtrl.dfltCloseStatus(new Set<Id>{sr.Id});
        Test.stopTest();

        System.assertEquals('true', result, 'Expected document approval validation result mismatch.');
    }

    @isTest
    static void testProvisDocCloseStp() {
        HexaBPM__Service_Request__c sr = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1];

        Test.startTest();
        CC_ProvisNOCValidationCtrl.provisDocCloseStp(new Set<Id>{sr.Id});
        Test.stopTest();

        List<HexaBPM__Step__c> steps = [SELECT HexaBPM__Status__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c = :sr.Id];
        for (HexaBPM__Step__c step : steps) {
           // System.assertEquals('Completed', step.HexaBPM__Status__c, 'Step status should be updated to Completed.');
        }
    }
}