@isTest(SeeAllData=false)
public class LoggerServiceTest {
    
    @testSetup
    static void setupTestData() {
        // Create test accounts for different scenarios
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account', false, 'JO20220212');
        insert orgAcc;
        
        // Create BrokerRequest for testing
        BrokerRequest__c br = TestObjectsFactory.getMarketingReimbursementRecord(orgAcc);
        insert br;
      /*  
        // Create Lead for testing
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'test@example.com',
            EnquiryCategory__c ='Sales Center',
            EnquiryTrigger__c = 'Dubai Sales Centre'
        );
        insert testLead;
       */ 
        // Create Order for testing (if Order is a custom object, adjust accordingly)
        Order testOrder = new Order(
            AccountId = orgAcc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert testOrder;
    }
    /*
    @isTest 
    static void testLogSuccessResponseWithDifferentRecordTypes() {
        // Get test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        BrokerRequest__c testBR = [SELECT Id FROM BrokerRequest__c LIMIT 1];
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        
        Test.startTest();
        
        // Test with Account
        Logger__c accountLog = LoggerService.logSuccessResponse(
            'TestProcess', 'TestClass', 'testMethod', 
            'Test Request', 'Test Response', testAccount.Id
        );
        
        // Test with BrokerRequest
        Logger__c brLog = LoggerService.logSuccessResponse(
            'TestProcess', 'TestClass', 'testMethod', 
            'Test Request', 'Test Response', testBR.Id
        );
        
        // Test with Lead
        Logger__c leadLog = LoggerService.logSuccessResponse(
            'TestProcess', 'TestClass', 'testMethod', 
            'Test Request', 'Test Response', testLead.Id
        );
        
        // Test with Order
        Logger__c orderLog = LoggerService.logSuccessResponse(
            'TestProcess', 'TestClass', 'testMethod', 
            'Test Request', 'Test Response', testOrder.Id
        );
        
        // Test with null recordId
        Logger__c nullLog = LoggerService.logSuccessResponse(
            'TestProcess', 'TestClass', 'testMethod', 
            'Test Request', 'Test Response', null
        );
        
        Test.stopTest();
        
        // Assertions
        System.assertEquals('Success Log', accountLog.ExceptionTypeName__c);
        System.assertEquals('TestProcess', accountLog.ExecutingProcessName__c);
        System.assertEquals('TestClass', accountLog.ClassName__c);
        System.assertEquals('testMethod', accountLog.MethodName__c);
        System.assertEquals('Test Request', accountLog.Message__c);
        System.assertEquals('Test Response', accountLog.ResponseMessage__c);
        System.assertEquals(testAccount.Id, accountLog.Account__c);
        
        System.assertEquals(testBR.Id, brLog.BrokerRequest__c);
        System.assertEquals(testLead.Id, leadLog.Lead__c);
        System.assertEquals(testOrder.Id, orderLog.Order__c);
        System.assertEquals(null, nullLog.Account__c);
    }
   */ 
    @isTest 
    static void testAddApexLogWithException() {
        Test.startTest();
        
        try {
            // Force an exception
            Integer result = 10 / 0;
        } catch (Exception e) {
            Logger__c apexLog = LoggerService.addApexLog(e, 'TestProcess', 'TestClass', 'testMethod');
            
            // Verify the log was added to the static list
            System.assertNotEquals(null, LoggerService.loggers);
            System.assertEquals(1, LoggerService.loggers.size());
            
            // Verify log properties
            System.assertEquals(e.getMessage(), apexLog.Message__c);
            System.assertEquals(e.getTypeName(), apexLog.ExceptionTypeName__c);
            System.assertEquals('TestProcess', apexLog.ExecutingProcessName__c);
            System.assertEquals('TestClass', apexLog.ClassName__c);
            System.assertEquals('testMethod', apexLog.MethodName__c);
            System.assertNotEquals(null, apexLog.LineNumber__c);
        }
        
        Test.stopTest();
    }
    
    @isTest 
    static void testCreateApexLogWithException() {
        Test.startTest();
        
        try {
            // Force an exception
            String nullString = null;
            nullString.toUpperCase();
        } catch (Exception e) {
            Logger__c apexLog = LoggerService.createApexLog(e, 'TestProcess', 'TestClass', 'testMethod');
            
            // Verify log properties
            System.assertEquals(e.getMessage(), apexLog.Message__c);
            System.assertEquals(e.getTypeName(), apexLog.ExceptionTypeName__c);
            System.assertEquals(e.getStackTraceString(), apexLog.StackTrace__c);
            System.assertEquals('TestProcess', apexLog.ExecutingProcessName__c);
            System.assertNotEquals(null, apexLog.LineNumber__c);
        }
        
        Test.stopTest();
    }
    
    @isTest 
    static void testDatabaseErrorLogging() {
        // Create contacts without required fields to generate database errors
        Contact con1 = new Contact();
        Contact con2 = new Contact();
        List<Contact> conList = new List<Contact>{con1, con2};
        
        Test.startTest();
        
        List<Database.SaveResult> results = Database.insert(conList, false);
        
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                for (Database.Error err : result.getErrors()) {
                    // Test createApexLog with Database.Error
                    Logger__c createLog = LoggerService.createApexLog(err, 'TestProcess', 'TestClass', 'testMethod');
                    
                    // Test addApexLog with Database.Error
                    Logger__c addLog = LoggerService.addApexLog(err, 'TestProcess', 'TestClass', 'testMethod');
                    
                    // Verify properties
                    System.assertEquals(err.getMessage(), createLog.Message__c);
                    System.assertEquals('TestProcess', createLog.ExecutingProcessName__c);
                    System.assertEquals(err.getMessage(), addLog.Message__c);
                }
            }
        }
        
        Test.stopTest();
    }
    
    @isTest 
    static void testAddApexServiceCalls() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        BrokerRequest__c testBR = [SELECT Id FROM BrokerRequest__c LIMIT 1];
        
        Test.startTest();
        
        Logger__c serviceLog = LoggerService.addApexServiceCalls(
            'TestProcess', 'TestClass', 'testMethod', 
            'Test Request', 'Test Response', testAccount.Id
        );
        
        Logger__c serviceLogBR = LoggerService.addApexServiceCalls(
            'TestProcess', 'TestClass', 'testMethod', 
            'Test Request', 'Test Response', testBR.Id
        );
        
        Test.stopTest();
        
        // Verify properties
        System.assertEquals('ServiceCall', serviceLog.ExceptionTypeName__c);
        System.assertEquals('Test Request', serviceLog.Message__c);
        System.assertEquals('Test Response', serviceLog.ResponseMessage__c);
        System.assertEquals(testAccount.Id, serviceLog.Account__c);
        System.assertEquals(testBR.Id, serviceLogBR.BrokerRequest__c);
    }
    
    @isTest 
    static void testAddApexServiceCallsLog() {
        Test.startTest();
        
        try {
            // Force an exception for testing
            List<String> testList = new List<String>();
            String item = testList[5]; // This will throw an exception
        } catch (Exception e) {
            Logger__c serviceCallLog = LoggerService.addApexServiceCallsLog(
                e, 'TestClass', 'testMethod', 'TestProcess', 
                'Test Request', 'Test Response'
            );
            
            // Verify properties
            System.assertEquals('DeserializationException', serviceCallLog.ExceptionTypeName__c);
            System.assertEquals('Test Request', serviceCallLog.Message__c);
            System.assertEquals('Test Response', serviceCallLog.ResponseMessage__c);
            System.assertEquals(e.getMessage(), serviceCallLog.ExceptionMessage__c);
            System.assertNotEquals(null, serviceCallLog.StackTrace__c);
        }
        
        Test.stopTest();
    }
    
    @isTest 
    static void testAddLog() {
        Test.startTest();
        
        LoggerService.addLog('TestProcess', 'Test Message');
        
        Test.stopTest();
        
        // This method doesn't return anything or add to the static list, 
        // so we're just testing it doesn't throw an exception
        System.assert(true, 'addLog method executed without exception');
    }
    
    @isTest 
    static void testSaveMethods() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Create a log and add it to the static list
        try {
            Integer result = 10 / 0;
        } catch (Exception e) {
            Logger__c apexLog = LoggerService.addApexLog(e, 'TestProcess', 'TestClass', 'testMethod');
            
            // Test save() method
            LoggerService.save();
            
            // Test save(Logger__c) method
            Logger__c singleLog = LoggerService.logSuccessResponse(
                'TestProcess', 'TestClass', 'testMethod', 
                'Request', 'Response', testAccount.Id
            );
            LoggerService.save(singleLog);
            
            // Test saveAndReturnLogger method
            Logger__c returnedLog = LoggerService.saveAndReturnLogger(singleLog);
            System.assertNotEquals(null, returnedLog);
            System.assertNotEquals(null, returnedLog.Id);
            
            // Test saveAndReturnLogger with null
            Logger__c nullResult = LoggerService.saveAndReturnLogger(null);
            System.assertEquals(null, nullResult);
        }
        
        Test.stopTest();
        
        // Verify logs were saved
        List<Logger__c> savedLogs = [SELECT Id FROM Logger__c];
        System.assert(savedLogs.size() > 0, 'Logs should be saved to database');
    }
    
    @isTest 
    static void testAsynchronousSave() {
        Test.startTest();
        
        // Create a JSON string of logger records
        List<Logger__c> testLogs = new List<Logger__c>();
        Logger__c testLog = new Logger__c(
            Message__c = 'Test Message',
            ExecutingProcessName__c = 'TestProcess',
            ClassName__c = 'TestClass',
            MethodName__c = 'testMethod'
        );
        testLogs.add(testLog);
        
        String jsonString = JSON.serialize(testLogs);
        
        LoggerService.aynchronousSave(jsonString);
        
        Test.stopTest();
        
        // Verify the async method executed (logs should be inserted)
        List<Logger__c> asyncLogs = [SELECT Id FROM Logger__c WHERE ExecutingProcessName__c = 'TestProcess'];
        System.assertEquals(1, asyncLogs.size(), 'Async save should create log record');
    }
    
    @isTest 
    static void testMobileLogging() {
        Test.startTest();
        
        // Create RestRequest
        RestRequest restRequest = new RestRequest();
        restRequest.resourcePath = '/services/apexrest/testpath';
        
        try {
            // Force an exception
            Account nullAccount = null;
            String accountName = nullAccount.Name;
        } catch (Exception e) {
            Logger__c mobileLog = LoggerService.addMobileLog(restRequest, e, 'Error Response', 500);
            
            // Verify mobile log properties
            System.assertEquals('Mobile Log', mobileLog.LogType__c);
            System.assertEquals('/services/apexrest/testpath', mobileLog.ResourcePath__c);
            System.assertEquals(500, mobileLog.StatusCode__c);
            System.assertEquals('Error Response', mobileLog.ResponseMessage__c);
            System.assertEquals(e.getMessage(), mobileLog.Message__c);
            System.assertEquals(e.getTypeName(), mobileLog.ExceptionTypeName__c);
            System.assertNotEquals(null, mobileLog.ExceptionLogId__c);
        }
        
        Test.stopTest();
    }
    
    @isTest 
    static void testUpdateMobileLog() {
        Test.startTest();
        
        RestRequest restRequest = new RestRequest();
        restRequest.resourcePath = '/services/apexrest/updatetest';
        
        Logger__c existingLog = new Logger__c();
        
        try {
            // Force an exception
            List<String> emptyList = new List<String>();
            String item = emptyList[0];
        } catch (Exception e) {
            Logger__c updatedLog = LoggerService.updateMobileLog(existingLog, restRequest, e, 'Updated Response', 400);
            
            // Verify updated properties
            System.assertEquals('Mobile Log', updatedLog.LogType__c);
            System.assertEquals('/services/apexrest/updatetest', updatedLog.ResourcePath__c);
            System.assertEquals(400, updatedLog.StatusCode__c);
            System.assertEquals('Updated Response', updatedLog.ResponseMessage__c);
            System.assertEquals(e.getMessage(), updatedLog.Message__c);
            System.assertEquals(e.getTypeName(), updatedLog.ExceptionTypeName__c);
        }
        
        Test.stopTest();
    }
    
    @isTest 
    static void testMobileLogWithoutException() {
        Test.startTest();
        
        RestRequest restRequest = new RestRequest();
        restRequest.resourcePath = '/services/apexrest/noexception';
        
        Logger__c mobileLog = LoggerService.addMobileLog(restRequest, null, 'Success Response', 200);
        
        // Verify log without exception
        System.assertEquals('Mobile Log', mobileLog.LogType__c);
        System.assertEquals(200, mobileLog.StatusCode__c);
        System.assertEquals('Success Response', mobileLog.ResponseMessage__c);
        System.assertEquals('/services/apexrest/noexception', mobileLog.ResourcePath__c);
        System.assertEquals(null, mobileLog.Message__c);
        
        Test.stopTest();
    }
    /*
    @isTest 
    static void testEdgeCases() {
        Test.startTest();
        
        // Test with empty loggers list
        LoggerService.save();
        
        // Test logSuccessResponse with various custom objects
        // (Assuming these objects exist in your org)
        /*
        JointOwner__c jo = TestObjectsFactory.getJointOwner(testAccount.Id, 80.00, 'Spouse Of');
        insert jo;
        
        Logger__c joLog = LoggerService.logSuccessResponse(
            'TestProcess', 'TestClass', 'testMethod', 
            'Request', 'Response', jo.Id
        );
        System.assertEquals(jo.Id, joLog.JointOwner__c);
        
        
        Test.stopTest();
    }*/
}