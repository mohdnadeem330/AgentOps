/**
* File Name : BookingQueable_Test.cls
* Description : Test class for BookingQueable
* Author : Akash Kumar
* Created On : 16/01/2025
==============================================================================
 Version |    Date    |    Author    | Modification
==============================================================================
* 1.0    | 16/01/2025 | Akash Kumar  | Initial Version
**/
@isTest
public class BookingQueable_Test {

    @testSetup 
    static void setupData() {
 		 User usr = TestObjectsFactory.getUserRecord('Sales Admin','srana');
        usr.ManagerId = UserInfo.getUserId();
        insert usr; 
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.Company__pc = 'ALdar';
        acc.Position__pc = 'CEO';
        acc.AnnualIncome__pc = 123456;
        acc.Industry = 'Agriculture';
        acc.BankName__c = 'ADCB';
        acc.NoofYearswithCompany__pc = 20;
        acc.BankCountry__c = 'United Arab Emirates';
        acc.CompanyAddress__pc = 'Test address';
        acc.isValidationBypass__c  = true;
        acc.EmploymentStatus__pc = 'Unemployed';
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryTrigger__c=null;
        insert opp;
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        projectRecord.IBANNoCorporate__c = '1234567890';
        insert projectRecord;
          Project__c projectMarjanRecord= TestObjectsFactory.getProjectRecord('Al Marjan');
        projectMarjanRecord.IBANNoCorporate__c = '1234567892';
        insert projectMarjanRecord;
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        unitrecord.Status__c = 'Sold';
        insert unitrecord;
        Unit__c unitrecordq = TestObjectsFactory.getUnitDetail(projectMarjanRecord.id,buildingRecord.id);
        unitrecordq.Status__c = 'Available';
        insert unitrecordq;
        
         Unit_Assignment__c unitAssingment = new Unit_Assignment__c();
        unitAssingment.RequestedBy__c = usr.id;
        unitAssingment.Status__c = 'Pending approval';
        unitAssingment.Unit__c = unitrecord.Id;
        unitAssingment.Approver__c = usr.Id;
        unitAssingment.RequestedDate__c = System.now();
       unitAssingment.Opportunity__c= opp.id;
       	Insert unitAssingment;
        
         Unit_Assignment__c unAssingment = new Unit_Assignment__c();
        unAssingment.RequestedBy__c = usr.id;
        unAssingment.Status__c = 'Approved';
        unAssingment.Unit__c = unitrecordq.Id;
        unAssingment.Approver__c = usr.Id;
        unAssingment.RequestedDate__c = System.now();
       unAssingment.Opportunity__c= opp.id;
       	Insert unAssingment;
    }
    
    @isTest
    static void testMethod1() {
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);        
        insert SRTemplateDetailRecord;
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Submitted');       
        insert draft;
        Account accRecord = [select id from Account limit 1];
        Opportunity optyRecord = [select Id, ServiceRequest__c from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        unitrecord.LockedBy__c=userInfo.getUserId();
        update unitrecord;
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        insert salesOrderRecord;
        ReceiptAcknowledgement__c receiptAcknowledgementOne = TestObjectsFactory.getReceiptAcknowledgementRecord(null, accRecord.Id, optyRecord.Id, 'Online');
        receiptAcknowledgementOne.ChequeReceived__c = false;
        insert receiptAcknowledgementOne;
        Id mortgageRegistrationId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unitrecord.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrderRecord.Id;
        insert newSR;
        optyRecord.ServiceRequest__c = newSR.Id;
        update optyRecord;
        test.startTest();
        System.enqueueJob(new BookingQueable(optyRecord, new List<SalesOrder__c>{salesOrderRecord}, new List<ReceiptAcknowledgement__c>{receiptAcknowledgementOne}));
        test.stopTest();
    }
    
    @isTest
    static void testMethod2() {
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);        
        insert SRTemplateDetailRecord;
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Submitted');       
        insert draft;
        Account accRecord = [select id from Account limit 1];
        Opportunity optyRecord = [select Id, ServiceRequest__c from opportunity limit 1];
        Unit__c unitrecord = [select id from Unit__c limit 1];
        unitrecord.LockedBy__c=userInfo.getUserId();
        update unitrecord;
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(optyRecord.ID,accRecord.Id);
        salesOrderRecord.Unit__c=unitrecord.Id;
        insert salesOrderRecord;
        ReceiptAcknowledgement__c receiptAcknowledgementOne = TestObjectsFactory.getReceiptAcknowledgementRecord(null, accRecord.Id, optyRecord.Id, 'Online');
        receiptAcknowledgementOne.ChequeReceived__c = false;
        insert receiptAcknowledgementOne;
        Id mortgageRegistrationId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unitrecord.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrderRecord.Id;
        insert newSR;
        optyRecord.ServiceRequest__c = newSR.Id;
        update optyRecord;
        test.startTest();
        System.enqueueJob(new BookingQueable(optyRecord, new List<SalesOrder__c>(), new List<ReceiptAcknowledgement__c>{receiptAcknowledgementOne}));
        test.stopTest();
    }
}