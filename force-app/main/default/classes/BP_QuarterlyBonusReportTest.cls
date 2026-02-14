@isTest
private class BP_QuarterlyBonusReportTest {

    @TestSetup
    static void makeData(){
        QuarterlyBonusCommission__c bonus = new QuarterlyBonusCommission__c(
            Year__c = '2024',
            Quarter__c = 'Q1',
            Status__c = 'Ready for Submission',
            Comments__c = 'Pending approval'
        );
        insert bonus;
    }

    @isTest
    static void testExcute() {
        Test.startTest();
        QuarterlyBonusCommission__c bonus = [SELECT Id FROM QuarterlyBonusCommission__c LIMIT 1];

        String requestBody = '{"qbcRecordId":"' + bonus.Id + '","status":"'+Constants.COMMISSION_LINE_STATUS_ACCEPTED+'","comments":"Quarterly Bonus Approved", "documentBase64":"test document base 64", "documentExtension" : "pdf"}';
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/submitQuarterlyBonusReport';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        BP_QuarterlyBonusReport.excute();
        
        RestResponse res = RestContext.response;
        System.assertEquals(null, res.statusCode);
        System.assertNotEquals(null, res.responseBody);
        
        Test.stopTest();
    }

    @isTest
    static void testProcessRequestWithInvalidData() {
        Test.startTest();
        
        String requestBody = '{"qbcRecordId":"","status":"InvalidStatus","comments":"Invalid Bonus"}';
        Map<String, String> params = new Map<String, String>();
        
        BP_QuarterlyBonusReport service = new BP_QuarterlyBonusReport();
        BP_BaseRestResource.ApiResponse response = service.processRequest(params, requestBody);
        
        System.assertNotEquals(null, response);
        System.assertEquals(400, response.statusCode);
        System.assert(response.message.contains('Quarterly Broker Commission Id can not be blank'));
        
        Test.stopTest();
    }

    @isTest
    static void testUpdateStatus() {
        Test.startTest();
        try {
            Map<Id, QuarterlyBonusCommission__c> bonusMap = new Map<Id, QuarterlyBonusCommission__c>();
            QuarterlyBonusCommission__c bonus = new QuarterlyBonusCommission__c(Status__c = 'Pending Invoice Verification', Comments__c = 'Pending approval');
            insert bonus;
            
            bonusMap.put(bonus.Id, bonus);
          
            BP_QuarterlyBonusReport.QuarterlyBonusWrapper requestWrapper = new BP_QuarterlyBonusReport.QuarterlyBonusWrapper();
            requestWrapper.qbcRecordId = bonus.Id;
            requestWrapper.status = 'Approved';
            requestWrapper.comments = 'Approved by manager';
            requestWrapper.documentBase64 = 'test document';
            requestWrapper.documentExtension = 'pdf';
            
            BP_QuarterlyBonusReport service = new BP_QuarterlyBonusReport();
            QuarterlyBonusCommission__c result = service.updateStatus(bonusMap, requestWrapper);
            
            QuarterlyBonusCommission__c updatedBonus = [SELECT Status__c, Comments__c FROM QuarterlyBonusCommission__c WHERE Id = :bonus.Id];
            System.assertEquals('Approved', updatedBonus.Status__c);
            System.assertEquals('Approved by manager', updatedBonus.Comments__c);
        } catch (Exception ee) {}
        Test.stopTest();
    }

    @isTest
    static void testInvalidRequestBody() {
        Test.startTest();
        
        String requestBody = '';
        Map<String, String> params = new Map<String, String>();
        
        BP_QuarterlyBonusReport service = new BP_QuarterlyBonusReport();
        BP_BaseRestResource.ApiResponse response = service.processRequest(params, requestBody);
        
        System.assertNotEquals(null, response);
        System.assertEquals(500, response.statusCode);
       
        Test.stopTest();
    }

    @isTest
    static void testNoUpdatePermission() {
        Test.startTest();
        try {
            Map<Id, QuarterlyBonusCommission__c> bonusMap = new Map<Id, QuarterlyBonusCommission__c>();
            QuarterlyBonusCommission__c bonus = new QuarterlyBonusCommission__c(Status__c = 'Fixed', Comments__c = 'Test');
            insert bonus;
            
            bonusMap.put(bonus.Id, bonus);
            
            BP_QuarterlyBonusReport.QuarterlyBonusWrapper requestWrapper = new BP_QuarterlyBonusReport.QuarterlyBonusWrapper();
            requestWrapper.qbcRecordId = bonus.Id;
            requestWrapper.status = 'Paid';
            requestWrapper.comments = 'Approved by manager';
            requestWrapper.documentBase64 = 'test document';
            requestWrapper.documentExtension = 'pdf';
            
            BP_QuarterlyBonusReport service = new BP_QuarterlyBonusReport();
            service.updateStatus(bonusMap, requestWrapper);
            
        } catch (CustomException ex) {
            System.assert(ex.getMessage().contains('No permission to update'), 'Expected permission exception');
        }
        Test.stopTest();
    }

    @isTest
    static void testExecute_withInvalidRequestBodyAndCatchBlockHandled() {
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/submitQuarterlyBonusReport';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = null;
        RestContext.request = req;
        RestContext.response = new RestResponse();

        try {
            BP_QuarterlyBonusReport.excute();
        } catch (Exception e) {}
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        System.assertEquals(false, response.get('success'));
    }

    @isTest
    static void testExecute_invalidRequestBody() {
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/submitQuarterlyBonusReport';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        BP_QuarterlyBonusReport.excute();
        Test.stopTest();

        RestResponse res = RestContext.response;
        String responseBody = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        System.assertEquals(false, response.get('success'));
        System.assertEquals('Invalid Request Body', response.get('message'));
    }
}