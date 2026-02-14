@isTest 
public class BuildingSectionMappingTriggerHandlerTest {
    
    @testSetup static void setupData() {
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.IBANNoCorporate__c = '1234567890';
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        
        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
        
        Test.startTest();
        insert buldingPaymentMapping;  
        Test.stopTest();
    }
    
    @isTest public static void deleteMethodTest() {
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.IBANNoCorporate__c = '1234567890';
        insert projectRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        
        BuildingSectionMapping__c buldingPaymentMapping1 = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
        insert buldingPaymentMapping1;
        BuildingSectionMappingTriggerHandler invokeClass = new BuildingSectionMappingTriggerHandler();
        invokeClass.afterInsertMethod(new List<SObject>{buldingPaymentMapping1}, new Map<Id, SObject>{buldingPaymentMapping1.Id => buldingPaymentMapping1});
        invokeClass.afterDeleteMethod(new List<SObject>{buldingPaymentMapping1}, new Map<Id, SObject>{buldingPaymentMapping1.Id => buldingPaymentMapping1});
        
        BuildingSectionMapping__c buildingPaymentMapping = [SELECT Id FROM BuildingSectionMapping__c LIMIT 1];
        Test.startTest();
        delete buildingPaymentMapping;
        Test.stopTest();
    }
}