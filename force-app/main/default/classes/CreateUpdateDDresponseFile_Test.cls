@isTest
public class CreateUpdateDDresponseFile_Test {
    
    @isTest
    public static void testMethod1(){
         User salesAdminUser = TestObjectsFactory.getUserRecord('Sales Admin', 'salesadmin1');
    insert salesAdminUser;
    
    Account orgAccount = TestObjectsFactory.getOrganisationAccountRecord('PWC', '123456789');
    insert orgAccount;
    
    Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(orgAccount.Id);
    insert opportunityRecord;
    
    Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
    insert unit;
    
    SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opportunityRecord.Id, orgAccount.Id);
    salesOrder.Unit__c = unit.Id;
    insert salesOrder;
    
    SalesOrderCancellation__c orderCancellation = new SalesOrderCancellation__c();
    orderCancellation.SalesOrder__c = salesOrder.Id;
    orderCancellation.ReasonforCancellation__c = 'Mortage Rejected';
    orderCancellation.SalesManagerComments__c = 'Customer requested to cancell';
    orderCancellation.AllInstallmentProvided__c = true;
    orderCancellation.SalesOrderStatusWhenCancelled__c = 'Pending with CM';
    
    TestObjectsFactory.initializeRestContext(null, '/upsert/ddResponseFile ');
    
   // TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
    
    RestContextHandler handler = new RestContextHandler(false);
    
    Test.startTest();                
    createUpdateDDresponseFile.doPost('21', 'Abu Dhabi Commercial Bank','Registration AckNack','ASA.name','QUNLSFIsQUNDRVBURUQsQzMwMDAwMzAwMDE1MTIzMDIwMTIzNDU1Ni5ERFMsMzAwMjMwMTI3MDAwMDg0Ng0KQUNLVFIsQUNDRVBURUQsMiwwMDNEQVIyMzAxMjcwMjRC');
    Test.stopTest(); 
    }
    
    @isTest
    public static void testMethod2(){
         User salesAdminUser = TestObjectsFactory.getUserRecord('Sales Admin', 'salesadmin1');
    insert salesAdminUser;
    
    Account orgAccount = TestObjectsFactory.getOrganisationAccountRecord('PWC', '123456789');
    insert orgAccount;
    
    Opportunity opportunityRecord = TestObjectsFactory.getOpportunityRecord(orgAccount.Id);
    insert opportunityRecord;
    
    Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
    insert unit;
    
    SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opportunityRecord.Id, orgAccount.Id);
    salesOrder.Unit__c = unit.Id;
    insert salesOrder;
    
    SalesOrderCancellation__c orderCancellation = new SalesOrderCancellation__c();
    orderCancellation.SalesOrder__c = salesOrder.Id;
    orderCancellation.ReasonforCancellation__c = 'Mortage Rejected';
    orderCancellation.SalesManagerComments__c = 'Customer requested to cancell';
    orderCancellation.AllInstallmentProvided__c = true;
    orderCancellation.SalesOrderStatusWhenCancelled__c = 'Pending with CM';
    
    TestObjectsFactory.initializeRestContext(null, '/upsert/ddResponseFile ');
    
   // TestObjectsFactory.initializeRestContext('', '/some/path', '1.0', 'ios', '13', 'iphone x');
    
    RestContextHandler handler = new RestContextHandler(false);
    
    Test.startTest();                
    createUpdateDDresponseFile.doPost('21', 'Abu Dhabi Commercial Bank','Registration AckNack','ASA.name','');
    Test.stopTest(); 
    }
    
  
}