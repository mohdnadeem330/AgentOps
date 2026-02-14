@isTest
public class CC_ReturnToCustomerNegotiationTest {
    
    static testMethod void testEvaluateCustomCode() {
        
        // Create test data
        Account acc = new Account(Name = 'Test Account', BlacklistReason__c = 'Legal', Blacklisted__c = true);
        insert acc;
        
        Unit__c unitA = TestObjectsFactory.unitDataSetup('TU-A');
        insert unitA;
        
        SalesOrder__c so = new SalesOrder__c(Unit__c = unitA.Id, Account__c = acc.Id,HoldFlag__c = true);
        insert so;
  
        
        HexaBPM__SR_Status__c submittedStatus = new HexaBPM__SR_Status__c(Name = 'Submitted', HexaBPM__Code__c='Submitted');
        insert submittedStatus;
        
        HexaBPM__SR_Status__c srStatus = new HexaBPM__SR_Status__c(
            Name = 'Sent to external counsel',
            HexaBPM__Code__c='Sent to external counsel'
        );
        insert srStatus;
        
        Id RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Default And Termination');
        
        
        HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c(
            SRType__c = Constants.DEFAULT_AND_TERMINATION,
            RecordTypeId = RecordTypeId,
            SalesOrder__c = so.Id,
            HexaBPM__Customer__c = acc.Id,
            HexaBPM__Internal_SR_Status__c = srStatus.id
            
        );
        insert sr;
        
        
        sr.SalesOrder__r = so;  
        update sr; 
        
        // Create Step record
        HexaBPM__Step__c step = new HexaBPM__Step__c(HexaBPM__SR__c = sr.Id);
        insert step;
        
        
        // Initialize service class
        CC_ReturnToCustomerNegotiation service = new CC_ReturnToCustomerNegotiation();
        
        Test.startTest();
        String result = service.EvaluateCustomCode(sr, step);
        
        Test.stopTest();
        
        
        acc.BlacklistReason__c = 'Legal';
        update acc;
        
        result = service.EvaluateCustomCode(sr, step);
        System.assertEquals('Success', result);
        
        step.HexaBPM__SR__c = null;
        update step;
        
        result = service.EvaluateCustomCode(sr, step);
        
        Id terminationRtId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Default And Termination');
        
        
        HexaBPM__Service_Request__c srExternal = new HexaBPM__Service_Request__c(
            RecordTypeId = terminationRtId,
            HexaBPM__Customer__c = acc.Id,
            SalesOrder__c = so.Id,
            HexaBPM__Internal_SR_Status__c = srStatus.id
        );
        insert srExternal;
        result = service.EvaluateCustomCode(srExternal, step);
        
        try {
            result = service.EvaluateCustomCode(null, null);
            System.assertEquals('Success', result);  
        } catch (Exception ex) {
            System.assert(false, 'Exception should not be thrown');
        }
    }
    
    @isTest
    static void testHasExternalCounselBranch() {
        
        // Setup base test data
        Account acc = new Account(Name = 'Test Acc 2', BlacklistReason__c = 'Legal');
        insert acc;
        
        Unit__c unitA = TestObjectsFactory.unitDataSetup('TU-B');
        insert unitA;
        
        SalesOrder__c so = new SalesOrder__c(Unit__c = unitA.Id, Account__c = acc.Id, HoldReasonCode__c = 'Legal');
        insert so;
        
        HexaBPM__SR_Status__c submittedStatus = new HexaBPM__SR_Status__c(Name = 'Submitted', HexaBPM__Code__c='Submitted');
        insert submittedStatus;
        
        HexaBPM__SR_Status__c externalCounselStatus = new HexaBPM__SR_Status__c(Name='Sent to external counsel', HexaBPM__Code__c='Sent to external counsel');
        insert externalCounselStatus;
        
        Id terminationRtId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Default And Termination');
        
        // Main SR being evaluated
        HexaBPM__Service_Request__c srMain = new HexaBPM__Service_Request__c(
            RecordTypeId = terminationRtId,
            HexaBPM__Customer__c = acc.Id,
            SalesOrder__c = so.Id,
            HexaBPM__Internal_SR_Status__c = externalCounselStatus.Id
        );
        insert srMain;
        
        // Additional SR to trigger hasExternalCounsel = true
        HexaBPM__Service_Request__c srExternal = new HexaBPM__Service_Request__c(
            RecordTypeId = terminationRtId,
            HexaBPM__Customer__c = acc.Id,
            SalesOrder__c = so.Id,
            HexaBPM__Internal_SR_Status__c = externalCounselStatus.Id
        );
        insert srExternal;
        
        // Step pointing to main SR
        HexaBPM__Step__c step = new HexaBPM__Step__c(HexaBPM__SR__c = srMain.Id);
        insert step;
        
        // Execute
        CC_ReturnToCustomerNegotiation service = new CC_ReturnToCustomerNegotiation();
        
        Test.startTest();
        String result = service.EvaluateCustomCode(srMain, step);
        Test.stopTest();
        
        // Account updatedAcc = [SELECT BlacklistReason__c FROM Account WHERE Id = :acc.Id];
        // System.assertEquals('Legal', updatedAcc.BlacklistReason__c, 'Blacklist should NOT be updated when hasExternalCounsel = true');
        // System.assertEquals('Success', result);
    }
    
    
}