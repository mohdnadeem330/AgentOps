/**
* @description       : StepStatusUpdateCtrl coverage class 
* @coverage          : StepStatusUpdateCtrlTest.cls | @CC100%
* @author            : rizwan
* @group             : 
* @last modified on  : 07-24-2023
* @last modified by  : rizwan
* Modifications Log
* Ver   Date         Author             Modification
* 1.0   07-24-2023   rizwan             Initial Version | @CC100%
**/
@istest
private class StepStatusUpdateCtrlTest {
    // Test Data Setup
    @testSetup static void dataSetup(){
        Profile profile2 = [Select Id from Profile where name = 'System Administrator'];
        Integer rand = Math.round(Math.random() * 1000);
        string randomFourDigit=String.valueOf(Math.mod(rand, 9999)).leftpad(4, '0');
        User portalAccountOwner2 = new User(ProfileId = profile2.Id,Username = System.now().millisecond() + randomFourDigit+'testx1@test.com',
                                            Alias = 'batman',Email='bruce.wayne@fsra.com',EmailEncodingKey='UTF-8',Firstname='Bruce',
                                            Lastname='Wayne',LanguageLocaleKey='en_US',LocaleSidKey='en_US',TimeZoneSidKey='America/Chicago');
        Database.insert(portalAccountOwner2);
        
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'PaymentExtension']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Payment Extension';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='PaymentExtension';
        insert SR_Template;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('PaymentExtension');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        insert SR;
        
        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Approval by Development Finance';
        ST.HexaBPM__Code__c = 'Approval by Development Finance';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Approval by Development Finance';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        HexaBPM__Status__c objStatus = new HexaBPM__Status__c();
        objStatus.Name = 'Awaiting Approval';
        objStatus.HexaBPM__Type__c = 'Intermediate';
        objStatus.HexaBPM__Code__c = 'AWAITING_APPROVAL';
        insert objStatus;
        
        HexaBPM__Status__c objStatus1 = new HexaBPM__Status__c();
        objStatus1.Name = 'Approved';
        objStatus1.HexaBPM__Type__c = 'Intermediate';
        objStatus1.HexaBPM__Code__c = 'APPROVED';
        insert objStatus1;
        
        map<string,string> mapStpStatus = new map<string,string>();
        for(HexaBPM__Status__c status:[select id,HexaBPM__Code__c,Name,HexaBPM__Type__c from HexaBPM__Status__c]){
            mapStpStatus.put(status.HexaBPM__Code__c,status.id);
        }
        
        HexaBPM__Transition__c Trans = new HexaBPM__Transition__c();
        Trans.HexaBPM__From__c = mapStpStatus.get('AWAITING_APPROVAL');
        Trans.HexaBPM__To__c = mapStpStatus.get('APPROVED');
        insert Trans;
        
        HexaBPM__Step_Transition__c hesstep = new HexaBPM__Step_Transition__c();
        hesstep.HexaBPM__Sys_Step_Transition_Name__c = 'test';
        hesstep.HexaBPM__SR_Step__c = SRStep.id;
        hesstep.HexaBPM__Transition__c = Trans.id;
        // hesstep.HexaBPM__To__c = hesstep.HexaBPM__Transition__r.HexaBPM__To__r.Name;
        insert hesstep;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Approval by Development Finance';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        insert step; 
        
    }

    // invoke the StepStatusUpdateCtrl Apex Class
    @istest static void unitTest1(){
        Test.enableChangeDataCapture();
        HexaBPM__Step__c step1 = [SELECT id, HexaBPM__Summary__c, HexaBPM__SR__c, HexaBPM__SR_Step__c FROM HexaBPM__Step__c where HexaBPM__Summary__c =: 'Approval by Development Finance' LIMIT 1];
        HexaBPM__Status__c objst = [SELECT ID, HexaBPM__Type__c, Name, HexaBPM__Code__c FROM HexaBPM__Status__c WHERE Name = 'Awaiting Approval' LIMIT 1];
        User u = [SELECT ID, Name, Alias FROM User WHERE Alias = 'batman' LIMIT 1];
        
        test.startTest();
        ApexPages.currentPage().getParameters().put('stepId', EncodingUtil.Base64Encode(Blob.valueOf(step1.Id)));
        ApexPages.currentPage().getParameters().put('statusId', EncodingUtil.Base64Encode(Blob.valueOf(objst.id)));
        ApexPages.currentPage().getParameters().put('statusName', EncodingUtil.Base64Encode(Blob.valueOf('Completed')));
        ApexPages.currentPage().getParameters().put('userId', EncodingUtil.Base64Encode(Blob.valueOf(u.id)));
        StepStatusUpdateCtrl stepco = new StepStatusUpdateCtrl();
        stepco.isUpdated = false;
        stepco.responseString = 'test';
        stepco.stepId = step1.id;
        stepco.statusId = objst.id; 
        stepco.statusName = 'Completed';
        stepco.userId = u.id;
        stepco.statusType = objst.HexaBPM__Type__c;
        stepco.statusUpdate();
        Test.getEventBus().deliver();
        u.Is_Approver__c = true;
        update u;
        stepco.statusUpdate();
        Test.getEventBus().deliver();
        test.stopTest();
    }
    
    // invoke the StepStatusUpdateCtrl Apex Class
    @istest static void unitTest2() {
        Test.enableChangeDataCapture();
        HexaBPM__Step__c step1 = [SELECT id, HexaBPM__Summary__c, HexaBPM__SR__c, HexaBPM__SR_Step__c FROM HexaBPM__Step__c where HexaBPM__Summary__c =: 'Approval by Development Finance' LIMIT 1];
        HexaBPM__Status__c objst = [SELECT ID, HexaBPM__Type__c, Name, HexaBPM__Code__c FROM HexaBPM__Status__c WHERE Name = 'Awaiting Approval' LIMIT 1];
        User u = [SELECT ID, Name, Alias FROM User WHERE Alias = 'batman' LIMIT 1];
        step1.HexaBPM__Closed_Date__c = system.today();
        update step1;
        u.Is_Approver__c = true;
        update u;
        test.startTest();
        ApexPages.currentPage().getParameters().put('stepId', EncodingUtil.Base64Encode(Blob.valueOf(step1.Id)));
        ApexPages.currentPage().getParameters().put('statusId', EncodingUtil.Base64Encode(Blob.valueOf(objst.id)));
        ApexPages.currentPage().getParameters().put('statusName', EncodingUtil.Base64Encode(Blob.valueOf('Completed')));
        ApexPages.currentPage().getParameters().put('userId', EncodingUtil.Base64Encode(Blob.valueOf(u.id)));
        StepStatusUpdateCtrl stepco = new StepStatusUpdateCtrl();
        stepco.isUpdated = false;
        stepco.responseString = 'test';
        stepco.stepId = step1.id;
        stepco.statusId = objst.id; 
        stepco.statusName = 'Completed';
        stepco.userId = u.id;
        stepco.statusType = objst.HexaBPM__Type__c;
        stepco.statusUpdate();
        Test.getEventBus().deliver();
        test.stopTest();
    }
    
    // invoke the UpdateStepStatusTrigger Apex Trigger
    @istest static void unitTest3() {
        HexaBPM__Step__c step1 = [SELECT id, HexaBPM__Summary__c, HexaBPM__SR__c, HexaBPM__SR_Step__c FROM HexaBPM__Step__c where HexaBPM__Summary__c =: 'Approval by Development Finance' LIMIT 1];
        HexaBPM__Status__c objst = [SELECT ID, HexaBPM__Type__c, Name, HexaBPM__Code__c FROM HexaBPM__Status__c WHERE Name = 'Awaiting Approval' LIMIT 1];
        Update_Step_Status_Event__e event = new Update_Step_Status_Event__e();
        event.Step_Id__c = step1.Id;
        event.Status_from_Email__c = objst.Id;
        EventBus.publish(event);
    }
}