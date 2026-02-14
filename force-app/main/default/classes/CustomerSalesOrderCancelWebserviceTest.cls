@isTest
public class CustomerSalesOrderCancelWebserviceTest {
    
    private static void setupRestRequest(String requestBody,String accountId,String unitId,String orderId,Boolean isPaymentPlanChanged){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer/salesOrderCancellation';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        CustomerSalesOrderCancellationWebService.doPatch(accountId,isPaymentPlanChanged,orderId,unitId);
        Test.stopTest();
    }
    
    @testSetup
    public static void testSetupData(){
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        unit.Status__c = 'In-Progress';
        unit.LockedBy__c = Userinfo.getUserId();
        update unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Sold';
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        Project__c proj = TestObjectsFactory.getProjectRecord('25083');
        insert proj;
    }
    
    @isTest
    public static void positiveTesting(){
        
        Account acc = [Select Id From Account Where Name = 'Test Account' Limit 1];
        Project__c proj = [Select Id,Name From Project__c Where Name = 'Mayan' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c From Unit__c Where Project__c =: proj.Id Limit 1];
        SalesOrder__c salesOrder = [Select Id, Account__c From SalesOrder__c Where Account__c =: acc.Id]; 
        
        String requestBody = JSON.serialize(new Map<String, Object>{ 
            'isPaymentPlanChanged' => true,
                'orderId' => salesOrder.id,
                'unitId' => unit.Id
                });
        
        setupRestRequest(requestBody,acc.Id,unit.Id,salesOrder.Id,true);
    }
    
    @isTest
    public static void positiveTesting_salesOrder_notFound(){
        
        Account acc = [Select Id From Account Where Name = 'Test Account' Limit 1];
        Project__c proj = [Select Id,Name From Project__c Where Name = 'Mayan' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c From Unit__c Where Project__c =: proj.Id Limit 1];
        SalesOrder__c salesOrder = [Select Id, Account__c From SalesOrder__c Where Account__c =: acc.Id And Unit__c =: unit.Id]; 
        
        String requestBody = JSON.serialize(new Map<String, Object>{ 
            'isPaymentPlanChanged' => true,
                'orderId' => salesOrder.Id,
                'unitId' => unit.Id
                });
        setupRestRequest(requestBody,acc.Id,unit.Id,'a2AFW0000008VABCDE',true);
    }
    
    @isTest
    public static void positiveTesting_Account_notFound(){
        
        Account acc = [Select Id From Account Where Name = 'Test Account' Limit 1];
        Project__c proj = [Select Id,Name From Project__c Where Name = 'Mayan' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c From Unit__c Where Project__c =: proj.Id Limit 1];
        
        String requestBody = JSON.serialize(new Map<String, Object>{ 
            'isPaymentPlanChanged' => true,
                'customerId' => acc.Id,
                'orderId' => 'a2AFW0000008VABCDE',
                'unitId' => unit.Id
                });
        setupRestRequest(requestBody,'001FW000008ozABCDE',unit.Id,'a2AFW0000008VABCDE',true);
    }
    
    @isTest
    public static void positiveTesting_unitStatus_unChanged(){
        
        Account acc = [Select Id From Account Where Name = 'Test Account' Limit 1];
        Project__c proj = [Select Id,Name From Project__c Where Name = 'Mayan' Limit 1];
        
        Unit__c unit = [Select Id,Name,Status__c,Project__c From Unit__c Where Project__c =: proj.Id Limit 1];
        unit.Status__c = 'Available';
        update unit;
        
        SalesOrder__c salesOrder = [Select Id, Account__c,Status__c From SalesOrder__c Where Account__c =: acc.Id];
        salesOrder.Status__c = 'Cancelled';
        salesOrder.Unit__c = unit.Id;
        update salesOrder;
        
        String requestBody = JSON.serialize(new Map<String, Object>{ 
            'isPaymentPlanChanged' => true,
                'orderId' => salesOrder.id,
                'unitId' => unit.Id
                });
        
        setupRestRequest(requestBody,acc.Id,unit.Id,salesOrder.Id,true);
    }
    
    @isTest
    public static void negativeTesting_MissingOrderId(){
        
        Project__c proj = [Select Id,Name From Project__c Where Name = 'Mayan' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c From Unit__c Where Project__c =: proj.Id Limit 1];
        String requestBody = JSON.serialize(new Map<String, Object>{
            'isPaymentPlanChanged' => true,
                'orderId' => '',
                'unitId' => unit.Id
                });
        
        setupRestRequest(requestBody,'',unit.Id,'',true);
    }
    
    @isTest
    public static void negativeTesting_MissingUnitId(){
        
        Account acc = [Select Id From Account Where Name = 'Test Account' Limit 1];
        SalesOrder__c salesOrder = [Select Id, Account__c From SalesOrder__c Where Account__c =: acc.Id];
        String requestBody = JSON.serialize(new Map<String, Object>{
            'isPaymentPlanChanged' => true,
                'orderId' => salesOrder.Id,
                'unitId' => ''
                });
        setupRestRequest(requestBody,acc.Id,'',salesOrder.Id,true);
    }
    
    @isTest
    public static void negativeTesting_isPaymentPlanChanged_False(){
        
        String requestBody = JSON.serialize(new Map<String, Object>{
            'isPaymentPlanChanged' => false,
                'orderId' => '',
                'unitId' => ''
                });
        
        setupRestRequest(requestBody,'','','',false);
    }
    
    @isTest
    public static void negativeTesting_UnitMismatch(){
        
        Project__c proj = [Select Id,Name From Project__c Where Name = 'Mayan' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c From Unit__c Where Project__c =: proj.Id Limit 1];
        Account acc = [Select Id From Account Where Name = 'Test Account' Limit 1];
        SalesOrder__c salesOrder = [Select Id, Account__c,Unit__c From SalesOrder__c Where Account__c =: acc.Id and Unit__c =: unit.Id];
        
        String requestBody = JSON.serialize(new Map<String, Object>{
            'isPaymentPlanChanged' => true,
                'orderId' => salesOrder.Id,
                'unitId' => 'a2DFW000007iABCDEF'
                });
        
        setupRestRequest(requestBody,acc.Id,'a2DFW000007iABCDEF',salesOrder.Id,true);
    }
    
     @isTest
    public static void negativeTesting_SalesOrder_Cancelled(){
        
        Project__c proj = [Select Id,Name From Project__c Where Name = 'Mayan' Limit 1];
        Account acc = [Select Id From Account Where Name = 'Test Account' Limit 1];
        
        Unit__c unit = [Select Id,Name,Status__c,Project__c,LockExpiryTime__c,LockedByCustomer__c From Unit__c Where Project__c =: proj.Id Limit 1];
        unit.LockExpiryTime__c = System.now();
        unit.LockedByCustomer__c = acc.Id;
        unit.Status__c = 'Sold';
        update unit;
        
        SalesOrder__c salesOrder = [Select Id, Account__c,Unit__c From SalesOrder__c Where Account__c =: acc.Id and Unit__c =: unit.Id];
        salesOrder.Status__c = 'Sold';
        salesOrder.unit__c = unit.Id;
        update salesOrder;
        
        String requestBody = JSON.serialize(new Map<String, Object>{
            'isPaymentPlanChanged' => true,
                'orderId' => salesOrder.Id,
                'unitId' => unit.Id
                });
        
        setupRestRequest(requestBody,acc.Id,unit.Id,salesOrder.Id,true);
    }
    
    @isTest
    public static void testExceptionHandling() {
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/customer/salesOrderCancellation';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf('{"isPaymentPlanChanged": true, bad_json}');
        
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        
        String validRequestBody = JSON.serialize(new Map<String, Object>{
            'isPaymentPlanChanged' => true,
                'orderId' => 'a2AFW0000008VABCDE',
                'unitId' => 'a2DFW000007iABCDEF'
                }); 
        
        Test.startTest();
        try {
            CustomerSalesOrderCancellationWebService.doPatch('',true,'a2AFW0000008VABCDE','a2DFW000007iABCDEF');
        } catch (Exception ex) {
            System.assert(false, 'Exception was not handled inside the web service: ' + ex.getMessage());
        }
        Test.stopTest();
    }
}