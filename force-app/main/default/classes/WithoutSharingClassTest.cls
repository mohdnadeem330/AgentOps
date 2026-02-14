@isTest
public class WithoutSharingClassTest {

    @TestSetup
    static void setupTestData() {
        // Setup the common test data used across multiple test methods
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.VisaType__pc = 'Visa not applicable';
        acc.VisaUIDNo__pc = '123456789012345';
        insert acc;
        
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;
        
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        //insert conRecord;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        Project__c projectRecord = TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        
        BuildingSection__c buildingRecord = TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        
        Unit__c unitRecord = TestObjectsFactory.getUnitDetail(projectRecord.id, buildingRecord.id);
        insert unitRecord;
        
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrderRecord.Unit__c = unitRecord.Id;
        insert salesOrderRecord;
    }

    @isTest
    static void createSalesOrderTest() {
        // Retrieve the sales order created during the setup
        SalesOrder__c salesOrderRecord = [SELECT Id FROM SalesOrder__c LIMIT 1];
        List<Account> lstAccount = [SELECT Id FROM Account];
        List<Opportunity> lstOpportunity = [SELECT Id FROM Opportunity];
        
        // Start test and call the method to update sales order statuses
        Test.startTest();
        WithoutSharingClass.updatesalesOrderSyncStatuses(new List<SalesOrder__c>{ salesOrderRecord });
        WithoutSharingClass.accountUpdateWithoutTrigger(lstAccount);
        WithoutSharingClass.opportunityUpdateWithoutTrigger(lstOpportunity);
        Test.stopTest();
        
        // You can add assertions here to verify the changes
    }
    
    @isTest
    static void testGetDocumentforReciepientStatus() {
        // Setup document records with necessary fields
        SalesOrder__c salesOrderRecord = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Set<Id> sourceIds = new Set<Id>{ salesOrderRecord.Id };
        
        // Simulate records in Document__c
        Document__c documentRecord = new Document__c(SalesOrder__c = salesOrderRecord.Id,DocumentType__c='KYC Form');
        insert documentRecord;
        
        Test.startTest();
        Map<Id, Document__c> docMap = WithoutSharingClass.getDocumentforReciepientStatus(sourceIds);
        Test.stopTest();
        
        // Assert that the result map contains the expected document record
     //   System.assertNotEquals(docMap, null);
//        System.assertEquals(docMap.size(), 1);
    }
    
    @isTest
    static void testGetReciepientStatusList() {
        // Setup envelope status values
        Set<Id> envelopeIds = new Set<Id>();
        
        // Simulate records in dfsle__RecipientStatus__c
        /*dfsle__RecipientStatus__c recipientStatus = new dfsle__RecipientStatus__c(
            dfsle__EnvelopeStatus__c = 'envelopeId1',
            dfsle__Completed__c = DateTime.newInstance(2025, 2, 2, 0, 0, 0),
            dfsle__Email__c = 'test@example.com',
            dfsle__RoutingOrder__c = 1,
            dfsle__Status__c = 'Approved',
            dfsle__SourceId__c = 'sourceId1'
        );
        insert recipientStatus;*/
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
         insert projectRecord;
         
         //Add GTC under project
         Document__c docRecord= new Document__c(Project__c=projectRecord.Id,DocumentType__c=Constants.DOCUMENT_TYPE_GTC);
         insert docRecord;
             List<dfsle__RecipientStatus__c> newList = new List<dfsle__RecipientStatus__c>();
        Map<Id,dfsle__RecipientStatus__c> oldMapList = new Map<Id,dfsle__RecipientStatus__c>();   
        
        dfsle__EnvelopeStatus__c es = new dfsle__EnvelopeStatus__c();
        es.dfsle__DocuSignId__c = '1234TEST-83ef-47b6-bc4e-123411111111';
        es.dfsle__EmailSubject__c= 'SARAN TEST SUB';
        es.dfsle__Sent__c = System.now();
        es.dfsle__Expires__c = System.now().addDays(1);
        es.dfsle__Reason__c = 'test';
        es.dfsle__SenderEmail__c = 'saran@aldar.com';
        es.dfsle__SenderName__c = 'Saran';
        es.dfsle__Status__c = 'Sent';
        es.dfsle__SourceId__c = docRecord.id;
        insert es;
        envelopeIds.add(es.Id);
        
        System.debug('es Id -> '+es.Id);
        dfsle__RecipientStatus__c rs = new dfsle__RecipientStatus__c();
        rs.dfsle__Status__c = 'Sent';
        rs.dfsle__Email__c = 'saran@aldar.com';
        rs.dfsle__RoutingOrder__c = 1;
        rs.dfsle__EnvelopeStatus__c = es.Id;
        //rs.EnvelopeId__c = '08993507-f57b-4e3c-9bfe-09e5b1144c35';
        newList.add(rs);
        
        dfsle__RecipientStatus__c rs2 = new dfsle__RecipientStatus__c();
        rs2.dfsle__Status__c = 'Created';
        rs2.dfsle__Email__c = 'saran2@aldar.com';
        rs2.dfsle__RoutingOrder__c = 1;
        rs2.dfsle__EnvelopeStatus__c = es.Id;
        newList.add(rs2);
        
        insert newList;
        
        Test.startTest();
        List<dfsle__RecipientStatus__c> recipientList = WithoutSharingClass.getReciepientStatusList(envelopeIds);
        Test.stopTest();
        
        // Assert that the recipient list is not empty
    //    System.assertNotEquals(recipientList, null);
        //System.assertTrue(recipientList.size() > 0);
    }

    @isTest
    static void testUpdateUnitAssignments() {
        // Setup Unit_Assignment__c records for updating
       User smManager = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaytSM1');
        smManager.IsActive = TRUE;
        insert smManager;
        
        User sm = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaSM1');
        sm.IsActive = TRUE;
        sm.ManagerId = smManager.Id;
        insert sm;
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId != null LIMIT 1];
        
         Unit__c unit3 = TestObjectsFactory.unitDataSetup('25085');
        unit3.Status__c = 'Available';
        unit3.AssignedToUser__c=null;
        insert unit3;
        

        Unit_Assignment__c unitAssignment = new Unit_Assignment__c(
            Unit__c = unit3.Id,
            Status__c = 'Approved', 
            RequestedBy__c = sm.Id,
            Opportunity__c = opp.Id,
            approver__c = smManager.Id
        );
        insert unitAssignment;
        
        Test.startTest();
        // Call update method for unit assignments
        WithoutSharingClass.updateUnitAssignments(new List<Unit_Assignment__c>{ unitAssignment });
         List<Unit_Assignment__c> unitAssignments = WithoutSharingClass.getUnitAssignments(new List<String>{ unit3.Id });
        Test.stopTest();
        
        // Assert that unit assignments have been updated, if applicable
    }

    @isTest
    static void testInsertUnitAssignments() {
        // Setup Unit_Assignment__c records for insertion
         User smManager = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaytSM1');
        smManager.IsActive = TRUE;
        insert smManager;
        
        User sm = TestObjectsFactory.getUserRecord('Sales Manager', 'ajaSM1');
        sm.IsActive = TRUE;
        sm.ManagerId = smManager.Id;
        insert sm;
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId != null LIMIT 1];
        
         Unit__c unit3 = TestObjectsFactory.unitDataSetup('25085');
        unit3.Status__c = 'Available';
        unit3.AssignedToUser__c=null;
        insert unit3;
        

        Unit_Assignment__c unitAssignment = new Unit_Assignment__c(
            Unit__c = unit3.Id,
            Status__c = 'Approved', 
            RequestedBy__c = sm.Id,
            Opportunity__c = opp.Id,
            approver__c = smManager.Id
        );
        insert unitAssignment;
        
        
        Test.startTest();
        // Call insert method for unit assignments
        try{
        	WithoutSharingClass.insertUnitAssignments(new List<Unit_Assignment__c>{ unitAssignment });
        }catch(Exception exp){
            
        }
        Test.stopTest();
        
        // Assert that unit assignments have been inserted
//        System.assertEquals([SELECT COUNT() FROM Unit_Assignment__c], 1);
    }

    @isTest
    static void testGetUnits() {
        // Setup unit records
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.IBANNoCorporate__c = '1234567890';
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        insert unitrecord;
        
        
        Test.startTest();
        List<Unit__c> units = WithoutSharingClass.getUnits(new List<String>{unitrecord.Id});
        Test.stopTest();
        
        // Assert that the unit list is returned correctly
   //     System.assertNotEquals(units, null);
        //System.assertTrue(units.size() > 0);
    }
    
    @isTest
    public static void getOnlineUnitsTest(){
        Unit__c unit = [Select Id,Name,Status__c,Project__c,LockedBy__c,LockedByCustomer__c,LockTime__c,LockExpiryTime__c,RelatedOpportunity__c,RelatedSalesOrder__c,LockType__c From Unit__c Where Status__c = 'Available' Limit 1];
        unit.DigitalSales__c = true;
        update unit;
        
        Test.startTest();
        WithoutSharingClass.getAllOnlineUnitsById(new Set<Id>{unit.Id});
        WithoutSharingClass.getAllUnitsById(new Set<Id>{unit.Id});
        Test.stopTest();
    }
    
    @isTest
    public static void getTimerTest(){
        Test.startTest();
        WithoutSharingClass.getTimer('Reservation');
        Test.stopTest();
    }
    
    @isTest
    public static void lockUnitTest(){
        Account acc = [Select Id From Account Where Name = 'Test Account' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c,LockedBy__c,LockedByCustomer__c,LockTime__c,LockExpiryTime__c,RelatedOpportunity__c,RelatedSalesOrder__c,LockType__c From Unit__c Where Status__c = 'Available' Limit 1];
        unit.DigitalSales__c = true;
        update unit;
        
        Test.startTest();
        WithoutSharingClass.lockUnit(new List<Unit__c>{unit},acc.Id,Constants.RESERVATION_TIMERNAME,Constants.UNIT_LOCKING);
        Test.stopTest();
    }
}