/**
* @description       : VisualforceEmailTemplateController coverage class
* @coverage          : VisualforceEmailTemplateControllerTest.cls | @CC100%
* @author            : rizwan
* @group             : 
* @last modified on  : 07-24-2023
* @last modified by  : rizwan
* Modifications Log
* Ver   Date         Author             Modification
* 1.0   07-24-2023   rizwan             Initial Version |  | @CC100%
**/
@istest
private class VisualforceEmailTemplateControllerTest {
    // Test Data Setup
    @testSetup static void dataSetup(){
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

    // invoke the VisualforceEmailTemplateController Apex Class
    @istest static void unitTest1(){
        HexaBPM__Step__c step1 = [SELECT id, HexaBPM__Summary__c, HexaBPM__SR__c, HexaBPM__SR_Step__c FROM HexaBPM__Step__c where HexaBPM__Summary__c =: 'Approval by Development Finance' LIMIT 1];
        system.debug('sss'+step1);
        HexaBPM__Step_Transition__c hexa = [SELECT id, HexaBPM__Sys_Step_Transition_Name__c,HexaBPM__Transition__r.HexaBPM__To__r.Name, HexaBPM__SR_Step__c, HexaBPM__Transition__c FROM HexaBPM__Step_Transition__c];
        
        test.startTest();
        VisualforceEmailTemplateController emailTemp = new VisualforceEmailTemplateController();  
        emailTemp.emailStepId = step1.id;
        emailTemp.userRecordId = step1.HexaBPM__SR_Step__c;
        emailTemp.currentStatus = hexa.HexaBPM__Transition__r.HexaBPM__To__r.Name;
        emailTemp.getTransitions();
        test.stopTest();
    }
    
}