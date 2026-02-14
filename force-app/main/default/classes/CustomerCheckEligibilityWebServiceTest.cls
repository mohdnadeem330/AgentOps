@isTest
public class CustomerCheckEligibilityWebServiceTest {

    @isTest
    public static void testCustomerCheckEligibilityWebService() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;

        TestObjectsFactory.initializeRestContext(null, '/query/checkeligibility');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            CustomerCheckEligibilityWebService.doPost(acc.Id, '', 'PropertyTransfer', '');
              CustomerCheckEligibilityWebService.verifySalesOrder(string.valueof(acc.id), salesOrder, false, 'PropertyTransfer');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerCheckEligibilityWebServiceError() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;

        TestObjectsFactory.initializeRestContext(null, '/query/checkeligibility');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
            CustomerCheckEligibilityWebService.doPost(acc.Id + '123', '', 'PropertyTransfer', '');
              CustomerCheckEligibilityWebService.verifySalesOrder(string.valueof(acc.id), salesOrder, false, 'PropertyTransfer');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerCheckEligibilityWebServiceForSalesOrder() {
		Test.startTest();
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        
    /*     SalesOrder__c salesOrder2 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder2.Unit__c = unit.Id;
        salesOrder2.Status__c = 'Sold';
        insert salesOrder2;*/
        
        
       HexaBPM__SR_Status__c closed = TestObjectsFactory.getSRStatus('Closed');
        insert closed;
        HexaBPM__SR_Template__c spaTemp = TestObjectsFactory.getSRTemplate(Constants.SPA_REGISTRATION_TYPE);
        insert spaTemp;
        Id spaId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);

        HexaBPM__Service_Request__c newSRSPA = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.SPA_REGISTRATION_TYPE, spaId, spaTemp.Id);
        newSRSPA.SalesOrder__c = salesOrder.Id;
        newSRSPA.BuyerEmail__c ='test@example.com';
        newSRSPA.HexaBPM__Email__c ='test@example.com';
            //  newSRSPA.SPACounterSignedDate__c = Date.today();
        insert newSRSPA;
        
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.PROPERTY_TRANSFER_RT);        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Property Transfer', 'PropertyTransfer');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;

        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;
       
        Id propertyTransferId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer NOC');

        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, 'Property Transfer NOC', propertyTransferId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.HexaBPM__Customer__c = acc.Id;
        newSR.BuyerName__c = acc.Id;
        newSR.TransferSellingPrice__c = 1000000;
        //newSR.SalesOrder__c = salesorder.Id;
        newSR.BuyerEmail__c ='test@example.com';
        newSR.HexaBPM__Email__c ='test@example.com';
       // newSR.SRType__c = 'SPA Registration';
       // newSR.HexaBPM__External_Status_Code__c ='Closed';
       ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = true;
        insert newSR;
		ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = false;
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        //insert newStep;

        TestObjectsFactory.initializeRestContext(null, '/query/checkeligibility');
        RestContextHandler handler = new RestContextHandler(true);
        
        
        try {
            CustomerCheckEligibilityWebService.doPost(acc.Id, salesOrder.Id, 'InvestorCertificates', '');

  CustomerCheckEligibilityWebService.verifySalesOrder(string.valueof(acc.id), salesOrder, false, 'PropertyTransfer');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

    @isTest
    public static void testCustomerCheckEligibilityWebServiceForSalesOrderFalse() {

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
/*
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = 'Draft';
       
        insert salesOrder;
        
       */   SalesOrder__c salesOrder2 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder2.Unit__c = unit.Id;
        salesOrder2.Status__c = 'Sold';
        insert salesOrder2; 
        
        
       HexaBPM__SR_Status__c closed = TestObjectsFactory.getSRStatus('Closed');
        insert closed;
        HexaBPM__SR_Template__c spaTemp = TestObjectsFactory.getSRTemplate(Constants.SPA_REGISTRATION_TYPE);
        insert spaTemp;
        Id spaId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);
ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = true;
        HexaBPM__Service_Request__c newSRSPA = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.SPA_REGISTRATION_TYPE, spaId, spaTemp.Id);
        newSRSPA.SalesOrder__c = salesOrder2.Id;
      //  newSRSPA.SPACounterSignedDate__c = Date.today();
       newSRSPA.BuyerEmail__c ='test@example.com';
        newSRSPA.HexaBPM__Email__c ='test@example.com';
        insert newSRSPA;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.PROPERTY_TRANSFER_RT);        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Property Transfer', 'PropertyTransfer');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;

        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;
       
        Id propertyTransferId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
      ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = true;
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.PROPERTY_TRANSFER_TYPE, propertyTransferId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.HexaBPM__Customer__c = acc.Id;
        newSR.BuyerName__c = acc.Id;
        newSR.SalesOrder__c = salesOrder2.Id;
      newSR.HexaBPM__Closed_Date_Time__c = null;
         newSR.TransferSellingPrice__c = 1000000;
         newSR.BuyerEmail__c ='test@example.com';
        newSR.HexaBPM__Email__c ='test@example.com';
     
        insert newSR;

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        insert newStep;

        TestObjectsFactory.initializeRestContext(null, '/query/checkeligibility');
        RestContextHandler handler = new RestContextHandler(true);
        
        Test.startTest();
        try {
           // CustomerCheckEligibilityWebService.doPost(acc.Id, salesOrder.Id, 'PropertyTransfer', '');
           CustomerCheckEligibilityWebService.doPost(acc.Id, salesOrder2.Id, 'InvestorCertificate', '');
             CustomerCheckEligibilityWebService.doPost(acc.Id, salesOrder2.Id, 'JointOwner', '');
            //CustomerCheckEligibilityWebService.verifySalesOrder(String.valueOf(fakeAcc.Id), salesOrder, false, 'PropertyTransfer');
CustomerCheckEligibilityWebService.verifySalesOrder(String.valueOf(acc.Id), salesOrder2, false, 'JointOwner');            
            CustomerCheckEligibilityWebService.verifySalesOrder(string.valueof(acc.id), salesOrder2, false, 'PropertyTransfer');
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
        Test.stopTest();
    }

 
        
        
    
}