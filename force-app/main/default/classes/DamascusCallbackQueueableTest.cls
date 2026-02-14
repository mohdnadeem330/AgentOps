@isTest
public class DamascusCallbackQueueableTest {
    
    @testSetup
    public static void setupMethod(){
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Project__c proj = TestObjectsFactory.getProjectRecord('25083');
        proj.Name = 'Gate';
        insert proj;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Available';
        unit.Project__c = proj.Id;
        insert unit;
    }
    
    @isTest
    public static void DamascusCallbackQueueableTest(){
        
        Account acc = [Select Id From Account Where Name = 'Test Account' Limit 1];
        Project__c proj = [Select Id,Name From Project__c Where Name = 'Gate' Limit 1];
        Unit__c unit = [Select Id,Name,Status__c,Project__c From Unit__c Where Project__c =: proj.Id Limit 1];
        unit.Status__c = 'In-Progress';
        unit.LockedByCustomer__c = acc.Id;
        update unit;
        
        List<Object> unitsPayload = new List<Object>();
        unitsPayload.add(new Map<String,Object>{ 
            'Id' => unit.Id, 
                'Name' => unit.Name, 
                'Status__c' => unit.Status__c
                });
        
        String requestBody = JSON.serialize(new Map<String, Object>{ 'units' => unitsPayload });
        
        Test.startTest();
        System.enqueueJob(new DamascusCallbackQueueable(
            requestBody,
            true,
            Constants.Damascus_Callback_Property,
            new List<Id>{unit.Id}));
        Test.stopTest();
    }
}