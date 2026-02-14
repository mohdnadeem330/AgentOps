@isTest
private class SalesOrderRelationshipAPITest {

    @isTest
    static void testUpsertSalesOrderRelationship_Create() {
        Id thirdPartyRecordTypeId = Schema.SObjectType.Sales_Order_Relationship__c.getRecordTypeInfosByName().get('Third Party').getRecordTypeId();

        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Account acc2 = TestObjectsFactory.getAccountRecord('Organization Account', false, '123223376');
        insert acc2;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'anayak@aldar.com';
        update con;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        Unit__c unit = TestObjectsFactory.unitDataSetup(opp.Id);
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.status__c = 'Reservation In Progress';
        insert salesOrder;

        RestRequest req = new RestRequest();
        RestContext.request = req;

        Map<String, String> requestBody = new Map<String, String>{
            'salesOrderId' => salesOrder.Id,
            'accountId' => acc2.Id,
            'relationshipSubType' => 'Friend',
            'expectedAmount' => '1000'
        };

        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        SalesOrderRelationshipAPI.upsertSalesOrderRelationship();
        Test.stopTest();

        /*Sales_Order_Relationship__c createdSOR = [SELECT Id, SalesOrder__c, Account__c, Relationship_Sub_Type__c, Expected_amount__c 
                                                  FROM Sales_Order_Relationship__c 
                                                  WHERE SalesOrder__c = :salesOrder.Id AND Account__c = :acc2.Id LIMIT 1];*/
        
    }

    @isTest
    static void testUpsertSalesOrderRelationship_Update() {
        Id thirdPartyRecordTypeId = Schema.SObjectType.Sales_Order_Relationship__c.getRecordTypeInfosByName().get('Third Party').getRecordTypeId();

        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Account acc2 = TestObjectsFactory.getAccountRecord('Organization Account', false, '123223376');
        insert acc2;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'anayak@aldar.com';
        update con;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        Unit__c unit = TestObjectsFactory.unitDataSetup(opp.Id);
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.status__c = 'Reservation In Progress';
        insert salesOrder;

        Sales_Order_Relationship__c sor1 = new Sales_Order_Relationship__c(
            SalesOrder__c = salesOrder.Id,
            Account__c = acc2.Id,
            RecordTypeId = thirdPartyRecordTypeId,
            Expected_amount__c = 500
        );
        insert sor1;

        RestRequest req = new RestRequest();
        RestContext.request = req;

        Map<String, String> requestBody = new Map<String, String>{
            'id' => sor1.Id,
            'salesOrderId' => salesOrder.Id,
            'expectedAmount' => '1500'
        };

        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        SalesOrderRelationshipAPI.upsertSalesOrderRelationship();
        Test.stopTest();

        Sales_Order_Relationship__c updatedSOR = [SELECT Id, Expected_amount__c FROM Sales_Order_Relationship__c WHERE Id = :sor1.Id];
    }

    @isTest
    static void testUpsertSalesOrderRelationship_ErrorHandling() {
        RestRequest req = new RestRequest();
        RestContext.request = req;

        Map<String, String> requestBody = new Map<String, String>{
            'salesOrderId' => '',
            'accountId' => '',
            'relationshipSubType' => '',
            'expectedAmount' => ''
        };

        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        SalesOrderRelationshipAPI.upsertSalesOrderRelationship();
        Test.stopTest();
    }

    @isTest
    static void testUpsertSalesOrderRelationship_RecordNotFound() {
        RestRequest req = new RestRequest();
        RestContext.request = req;

        Map<String, String> requestBody = new Map<String, String>{
            'id' => 'nonexistentId',
            'salesOrderId' => 'someSalesOrderId',
            'expectedAmount' => '1500'
        };

        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        SalesOrderRelationshipAPI.upsertSalesOrderRelationship();
        Test.stopTest();
    }
}