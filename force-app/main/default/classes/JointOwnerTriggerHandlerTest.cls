/*
*Created By     : Hardik Vitthani
*Description    : Test class for JointOwnerTriggerHandler
*/
@isTest
public class JointOwnerTriggerHandlerTest {
   @isTest
    public static void testJointOwnerTriggerHandler() {
        Test.startTest();

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.VisaType__c = 'Visa not applicable';
        acc.VisaUIDNo__pc = '123456789012345';
        insert acc;

       //Account newAcc = TestObjectsFactory.getPersonAccountRecord();
        //insert newAcc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.OwnerSharePercentage__c = 10;
        insert salesOrder;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, acc.Id, 'Friend Of');
        jointOwner.SharePercentage__c = 10;
        insert jointOwner;

        TriggerHandler.processedIds = new Set<Id>();
        jointOwner.SharePercentage__c = 5;
        update jointOwner;
        
         delete jointOwner;

        Test.stopTest();
    }
    //added by Dharanesh on 5-5-2025 to cover method : JointOwnerTriggerHandler.deleteJointOwner
    @isTest
    public static void testJointOwnerTriggerHandler2() {
        Test.startTest();

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.VisaType__c = 'Visa not applicable';
        acc.VisaUIDNo__pc = '123456789012345';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.OwnerSharePercentage__c = 10;
        insert salesOrder;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, acc.Id, 'Friend Of');
        jointOwner.SharePercentage__c = 10;
        insert jointOwner;

        TriggerHandler.processedIds = new Set<Id>();
        jointOwner.SharePercentage__c = 5;
        jointOwner.DeleteJointOwner__c = true;
        update jointOwner;
        
         delete jointOwner;

        Test.stopTest();
    }
    
    //added by Dharanesh on 5-5-2025
    
    //added by Dharanesh on 5-5-2025 to cover method : JointOwnerTriggerHandler.updateSalesOrderRecord
    @isTest
    public static void testJointOwnerTriggerHandler3() {
        Test.startTest();

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.VisaType__c = 'Visa not applicable';
        acc.VisaUIDNo__pc = '123456789012345';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.OwnerSharePercentage__c = 10;
        insert salesOrder;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, acc.Id, 'Friend Of');
        jointOwner.SharePercentage__c = 10;
        insert jointOwner;

        TriggerHandler.processedIds = new Set<Id>();
        jointOwner.SharePercentage__c = 5;
        jointOwner.Compliance_status__c = 'Returned';
        jointOwner.Compliance_comments__c = 'From Test Class';
        
        update jointOwner;
        
         delete jointOwner;

        Test.stopTest();
    }
    
    //added by Dharanesh on 5-5-2025
    
    //added by Dharanesh on 5-5-2025 to cover method : JointOwnerTriggerHandler.updateSalesOrderRecord
    @isTest
    public static void testJointOwnerTriggerHandler4() {
        Test.startTest();

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.VisaType__c = 'Visa not applicable';
        acc.VisaUIDNo__pc = '123456789012345';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.OwnerSharePercentage__c = 10;
        insert salesOrder;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, acc.Id, 'Friend Of');
        jointOwner.SharePercentage__c = 10;
        insert jointOwner;

        TriggerHandler.processedIds = new Set<Id>();
        jointOwner.SharePercentage__c = 5;
        jointOwner.Compliance_status__c = 'Cleared';
        
        update jointOwner;
        
         delete jointOwner;

        Test.stopTest();
    }
    
    //added by Dharanesh on 5-5-2025
    
    //added by Dharanesh on 5-5-2025 to cover method : JointOwnerTriggerHandler.UpdateSOWithJointOwnerDetailsFuture
    @isTest
    public static void testJointOwnerTriggerHandler5() {
        Test.startTest();

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.VisaType__c = 'Visa not applicable';
        acc.VisaUIDNo__pc = '123456789012345';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.OwnerSharePercentage__c = 10;
        insert salesOrder;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, acc.Id, 'Friend Of');
        jointOwner.SharePercentage__c = 10;
        
        insert jointOwner;
        
        TriggerHandler.processedIds = new Set<Id>();
        jointOwner.SharePercentage__c = 5;
        jointOwner.Compliance_status__c = 'Cleared';
        jointOwner.SalesOrder__c = salesOrder.id;
        update jointOwner;

                

        Test.stopTest();
    } 
    
    //added by Dharanesh on 5-5-2025 
  
    //added by Dharanesh on 8-5-2025 to cover afterDeleteMethod
    
    @isTest
    public static void testJointOwnerTriggerHandler6() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.VisaType__c = 'Visa not applicable';
        acc.VisaUIDNo__pc = '123456789012345';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.OwnerSharePercentage__c = 10;
        salesOrder.Status__c = 'Cancelled';
        insert salesOrder;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, acc.Id, 'Friend Of');
        jointOwner.SyncStatus__c = 'Synced';
        insert jointOwner;
        
        TriggerHandler.processedIds.remove(jointOwner.id);
         delete jointOwner;
        
        
         Test.stopTest();
    }
   //added by Dharanesh on 8-5-2025 to cover afterDeleteMethod 

/*@isTest
public static void testSafeStringContainsCoverage() {

    Test.startTest();

    // Create Person Account with valid fields
    Account acc = TestObjectsFactory.getPersonAccountRecord();
    acc.FirstName = 'John';           // Valid for Person Account
    acc.LastName  = 'Doe';
    acc.NameInArabic__c = 'جون';
    acc.PassportNumber__pc = 'P12345';
    insert acc;

    // Create Opportunity
    Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
    insert opp;

    // Unit
    Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
    insert unit;

    // Create Sales Order with JointOwner fields populated (to trigger safeStringContains)
    SalesOrder__c so = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
    so.Unit__c = unit.Id;

    // Strings that DO NOT contain the account values → safeStringContains = false
    so.JointOwnerNames__c = 'Random Name';
    so.JointOwnerNamesinArabic__c = 'اسم آخر';
    so.JointOwnerNationalities__c = 'Something';
    so.JointOwnerNationalitiesinArabic__c = 'شيء';
    so.JointOwnerPassportNumbers__c = 'XYZ999';
    insert so;

    // Create Joint Owner
    JointOwner__c jo = TestObjectsFactory.getJointOwnerRecord(so.Id, acc.Id, 'Friend Of');
    jo.SharePercentage__c = 10;
    insert jo;

    // This update triggers beforeUpdate → safeStringContains block
    jo.SharePercentage__c = 20;
    update jo;

    Test.stopTest();
} */



@isTest
public static void testSafeStringContainsCoverage() {

    Test.startTest();

    // Account
    Account acc = TestObjectsFactory.getPersonAccountRecord();
    acc.FirstName = 'John';
    acc.LastName  = 'Doe';
    acc.NameInArabic__c = 'جون';
    acc.PassportNumber__pc = 'P12345';
    insert acc;

    // Opportunity
    Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
    insert opp;

    // Unit
    Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
    insert unit;

    // SalesOrder with mismatch values
    SalesOrder__c so = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
    so.Unit__c = unit.Id;
    so.JointOwnerNames__c = 'XXX';
    so.JointOwnerNamesinArabic__c = 'YYY';
    so.JointOwnerNationalities__c = 'ZZZ';
    so.JointOwnerNationalitiesinArabic__c = 'AAA';
    so.JointOwnerPassportNumbers__c = 'BBB';
    insert so;

    // Create JointOwner
    JointOwner__c jo = TestObjectsFactory.getJointOwnerRecord(so.Id, acc.Id, 'Friend Of');
    jo.SharePercentage__c = 10;
    insert jo;

    // *** MAIN FIX ***
    // DO NOT change SharePercentage__c
    // DO NOT change Account__c
    // Change ONLY a safe text field
    jo.Compliance_comments__c = 'Trigger safeStringContains block';
    update jo;

    Test.stopTest();
}





}