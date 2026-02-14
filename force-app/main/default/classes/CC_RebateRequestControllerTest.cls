/**
 * Test class: CC_RebateRequestController
 */
@isTest
public with sharing class CC_RebateRequestControllerTest {

@testSetup
static void setupData() {
    // Create test data
    Account acc = TestObjectsFactory.getPersonAccountRecord();
    insert acc;

    Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
    insert opp;

    Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
    unit.Status__c = 'Sold';
    insert unit;

    SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
    salesOrder.Unit__c = unit.Id;
    salesOrder.HoldReasonCode__c = 'test123';
    insert salesOrder;

    HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c(
        Name = 'Additional Rebate Request',
        HexaBPM__SR_RecordType_API_Name__c = 'Rebate_Request'
    );
    insert SR_Template;

    HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c(
        RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Rebate Request'),
        SRType__c =  'Rebate Request',
        HexaBPM__Customer__c = acc.Id,
        HexaBPM__Contact__c = acc.PersonContactId,
        HexaBPM__SR_Template__c = SR_Template.Id,
        Unit__c = unit.Id,
        SalesOrder__c = salesOrder.Id,
        StepClosureDate__c = Date.today(),
        Rebate_to_be_Offered__c = 0.00,
        Additional_Rebate_Offered__c = 0.00
    );
    insert SR;

    SRUnitSelected__c srUnit = new SRUnitSelected__c(
        Name = salesOrder.UnitNumber__c,
        OutstandingAmount__c = 900000.00,
        Previous_Rebate_Offered__c = 70005.00,
        ServiceRequest__c = SR.Id,
        Unit__c = unit.Id,
        SalesOrder__c = salesOrder.Id,
        Rebate_Percentage__c = 20
    );
    insert srUnit;

    SRUnitSelected__c srUnit2 = new SRUnitSelected__c(
        Name = salesOrder.UnitNumber__c,
        OutstandingAmount__c = 900000.00,
        Previous_Rebate_Offered__c = 70005.00,
        ServiceRequest__c = SR.Id,
        Unit__c = unit.Id,
        SalesOrder__c = salesOrder.Id,
        Rebate_Percentage__c = 90
    );
    insert srUnit2;

    HexaBPM__Step_Template__c[] stepTemplates = new HexaBPM__Step_Template__c[]{
        new HexaBPM__Step_Template__c(Name = 'Approval of the Request By D&T', HexaBPM__Code__c = 'Approval of the Request By D&T', HexaBPM__Step_RecordType_API_Name__c = 'General'),
        new HexaBPM__Step_Template__c(Name = 'Verification by Finance', HexaBPM__Code__c = 'Verification by Finance', HexaBPM__Step_RecordType_API_Name__c = 'General'),
        new HexaBPM__Step_Template__c(Name = 'Payment Step', HexaBPM__Code__c = 'Payment Step', HexaBPM__Step_RecordType_API_Name__c = 'General')
    };
    insert stepTemplates;

    HexaBPM__Status__c[] statusList = new HexaBPM__Status__c[]{
        new HexaBPM__Status__c(Name = Constants.PENDING_STATUS, HexaBPM__Code__c = Constants.PENDING_STATUS),
        new HexaBPM__Status__c(Name = Constants.STATUS_APPROVED, HexaBPM__Code__c = Constants.STATUS_APPROVED),
        new HexaBPM__Status__c(Name = Constants.COMPLETED_STATUS, HexaBPM__Code__c = Constants.COMPLETED_STATUS)
    };
    insert statusList;

    HexaBPM__SR_Steps__c[] SRstepsList = new HexaBPM__SR_Steps__c[]{
        new HexaBPM__SR_Steps__c(
            HexaBPM__SR_Template__c = SR_Template.id,
            HexaBPM__Step_No__c = 2,
            HexaBPM__Step_Template__c = stepTemplates[1].Id,
            HexaBPM__Summary__c = 'Verification by Finance',
            HexaBPM__Step_RecordType_API_Name__c = 'General'
        ),
        new HexaBPM__SR_Steps__c(
            HexaBPM__SR_Template__c = SR_Template.id,
            HexaBPM__Step_No__c = 1,
            HexaBPM__Step_Template__c = stepTemplates[2].Id,
            HexaBPM__Summary__c = 'Payment Verification',
            HexaBPM__Step_RecordType_API_Name__c = 'General'
        ),
        new HexaBPM__SR_Steps__c(
            HexaBPM__SR_Template__c = SR_Template.id,
            HexaBPM__Step_No__c = 1,
            HexaBPM__Step_Template__c = stepTemplates[0].Id,
            HexaBPM__Summary__c = 'Approval of the Request By D&T',
            HexaBPM__Step_RecordType_API_Name__c = 'General'
        )
    };
    insert SRstepsList;

    HexaBPM__Step__c[] stepList = new HexaBPM__Step__c[]{
        new HexaBPM__Step__c(
            HexaBPM__Summary__c = 'Verification by Finance',
            HexaBPM__SR__c = SR.Id,
            HexaBPM__SR_Step__c = SRstepsList[0].Id,
            HexaBPM__Start_Date__c = Date.today(),
            HexaBPM__Status__c = statusList[0].id
        ),
        new HexaBPM__Step__c(
            HexaBPM__Summary__c = 'Payment Verification',
            HexaBPM__SR__c = SR.Id,
            HexaBPM__SR_Step__c = SRstepsList[1].Id,
            HexaBPM__Start_Date__c = Date.today(),
            HexaBPM__Status__c = statusList[2].id
        ),
        new HexaBPM__Step__c(
            HexaBPM__Summary__c = 'Approval of the Request By D&T',
            HexaBPM__SR__c = SR.Id,
            HexaBPM__SR_Step__c = SRstepsList[2].Id,
            HexaBPM__Start_Date__c = Date.today(),
            HexaBPM__Status__c = statusList[1].id
        )
    };
    insert stepList;

    ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Note');
    insert receiptAcknowledgement;
      
      ReceiptAcknowledgementService.queryAllFieldsWithExtraFields(new List<Id>{receiptAcknowledgement.Id});
      ReceiptAcknowledgementService.getReceiptAcknowledgementById(receiptAcknowledgement.Id); 
  }


@isTest
public static void callMethod (){

HexaBPM__Status__c approvedStatus = [Select id,Name from HexaBPM__Status__c where Name =:Constants.STATUS_APPROVED LIMIT 1];

HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, Additional_Rebate_Offered__c,ReceiptRebete__c,HexaBPM__External_SR_Status__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
HexaBPM__Step__c stp = [Select Id ,HexaBPM__Step_Status__c, Step_Template_Code__c, HexaBPM__Status__c,OwnerId, OwnerName__c, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Approval of the Request By D&T'];
List<SalesOrder__c> salesOrders =[Select id,Account__c,Status__c,OutstandingAmount__c,TotalOutstanding__c, UnitNumber__c,Unit__c FROM SalesOrder__c];
Test.startTest();
List<SRUnitSelected__c> Unitresult = [Select id, ServiceRequest__c, SalesOrder__c,Rebate_Percentage__c from SRUnitSelected__c where ServiceRequest__c =:SR.id];
CC_RebateRequestController cc = new CC_RebateRequestController();
cc.EvaluateCustomCode(SR, stp);     
Test.stopTest();
}

@isTest
public static void callMethod1 (){
  Test.startTest();
    HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, Additional_Rebate_Offered__c,ReceiptRebete__c,HexaBPM__External_SR_Status__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
    
    HexaBPM__Step__c stp1 = [Select Id ,HexaBPM__Step_Status__c, Step_Template_Code__c, HexaBPM__Status__c,OwnerId, OwnerName__c, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Approval of the Request By D&T'];
    HexaBPM__Step__c stp = [Select Id ,HexaBPM__Step_Status__c, Step_Template_Code__c, HexaBPM__Status__c,OwnerId, OwnerName__c, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Payment Verification'];
    CC_RebateRequestController cc = new CC_RebateRequestController();
    cc.EvaluateCustomCode(SR, stp);        
    // List<HexaBPM__Service_Request__c> srList=  [SELECT Id,ReceiptAcknowledgement__r.Name,ReceiptAcknowledgement__c,ReceiptAcknowledgement__r.PaymentSubType__c,ReceiptAcknowledgement__r.Status__c from HexaBPM__Service_Request__c where Id =:srId and ReceiptAcknowledgement__r.Status__c !='Cleared' and ReceiptAcknowledgement__r.PaymentSubType__c !='Rebate'];
    
    // cc.EvaluateCustomCode(SR, stp);
    
    SR.Additional_Rebate_Offered__c = null;
    update SR;
    cc.EvaluateCustomCode(SR, stp1);
    
  Test.stopTest();    // Assert the result
}

@isTest
public static void callMethod2 (){
  Test.startTest();
    HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c, ReceiptAcknowledgement__c,Additional_Rebate_Offered__c,ReceiptRebete__c,HexaBPM__External_SR_Status__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c From HexaBPM__Service_Request__c Limit 1];
    HexaBPM__Step__c stp = [Select Id ,HexaBPM__Step_Status__c, Step_Template_Code__c, HexaBPM__Status__c,OwnerId, OwnerName__c, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verification by Finance'];
    HexaBPM__Step__c stp1 = [Select Id ,HexaBPM__Step_Status__c, Step_Template_Code__c, HexaBPM__Status__c,OwnerId, OwnerName__c, HexaBPM__SR__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Payment Verification'];
    CC_RebateRequestController cc = new CC_RebateRequestController();
    cc.EvaluateCustomCode(SR, stp); 
    ReceiptAcknowledgement__c rcpt = [Select Name, PaymentSubType__c, Status__c from  ReceiptAcknowledgement__c LIMIT 1];
    SR.ReceiptAcknowledgement__c = rcpt.id; 
    update SR;      
    User systemAdmin = TestObjectsFactory.getUserRecord(Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR, 'systemAdmin');
    System.runAs(systemAdmin) {
        cc.EvaluateCustomCode(SR, stp1);
    }


  Test.stopTest();    // Assert the result
}

}