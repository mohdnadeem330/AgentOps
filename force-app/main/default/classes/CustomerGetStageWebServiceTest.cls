@isTest
public class CustomerGetStageWebServiceTest {
    @testSetUp
	public static void testdata(){
        list<Account> Acclist = new list<Account>();
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        Acclist.add(acc);
        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org1', 'G123465');
        Acclist.add(acc1);
        insert Acclist;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@gmail.com';
        update con;
        Contact con1 = TestObjectsFactory.contactDataSetup(acc1.Id);
        con1.Email = 'ajay.thakur@gmail.com';
        update con1;
        
        list<Opportunity> opplist = new list<Opportunity>();
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opplist.add(opp);
        Opportunity opp1 = TestObjectsFactory.getOpportunityRecord(acc1.Id);
        opplist.add(opp1);
        insert opplist;
   
        
        list<Unit__c> units = new list<unit__c>();
        unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        units.add(unit);
        //insert unit; // unit,building and project creation
        
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25093');
        unit1.Status__c = 'Sold';
        units.add(unit1);
        insert units;
        
        Id mortgageDischargeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.LPC_WAIVER_RT);
        list<SalesOrder__c> salesOrders = new list<SalesOrder__c>();
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.MortgageApplicable__c = 'Yes';
        salesOrder.Contact__c = con.Id;
        salesOrders.add(salesOrder);
        //insert salesOrder;
        
        // SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp1.Id, acc1.Id);
        // salesOrder1.Unit__c = unit1.Id;
        // salesOrder1.MortgageApplicable__c = 'Yes';
        // salesOrder1.Contact__c = con1.Id;
        // //salesOrder1.IsBookingCompleted__c = true;
        // salesOrders.add(salesOrder1);
        insert salesOrders;
        
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.LPC_WAIVER_RT, 'LPCWaiver');
        insert objStepTemplate;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_RT);        
        insert SRTemplateDetailRecord;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        list<HexaBPM__Service_Request__c> SRs = new list<HexaBPM__Service_Request__c>();
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.LPC_WAIVER_TYPE, mortgageDischargeId, SRTemplateDetailRecord.Id);
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.Unit__c = unit.Id;  
        newSR.WaivedPercentage__c = 2;
        newSR.ReallocationAmount__c = 100;
        newSR.No_Charge_Fee_Required__c = false;
        SRs.add(newSR);
        //insert newSR;
        
        // HexaBPM__Service_Request__c newSR1 = TestObjectsFactory.getServiceRequest(draft.Id, unit1.Id, Constants.LPC_WAIVER_TYPE, mortgageDischargeId, SRTemplateDetailRecord.Id);
        // newSR1.SalesOrder__c = salesOrder1.Id;
        // newSR1.Unit__c = unit1.Id;  
        // newSR1.WaivedPercentage__c = 2;
        // newSR1.ReallocationAmount__c = 100;
        // newSR1.No_Charge_Fee_Required__c = true;
        // SRs.add(newSR1);
        insert SRs;
        
        HexaBPM__Step__c newStep = new HexaBPM__Step__c();
        newStep.HexaBPM__SR__c = newSR.id;
        newStep.HexaBPM__Due_Date__c = System.Now().addDays(2);
        newStep.HexaBPM__Step_No__c = 10;
        newStep.HexaBPM__SR_Step__c = objSRSteps.Id;
        newStep.HexaBPM__Step_Template__c = objStepTemplate.id;
        newStep.HexaBPM__Step_Notes__c = 'test';
        newStep.HexaBPM__Summary__c ='Charge Fees';
        insert newStep;
        
        SalesOrderOtherCharges__c salesOrderOtherCharges = new SalesOrderOtherCharges__c();
        salesOrderOtherCharges.ServiceRequest__c = newSR.Id;
        salesOrderOtherCharges.Account__c = acc.Id;
        salesOrderOtherCharges.Amount__c = 10000;
        salesOrderOtherCharges.SalesOrder__c = salesOrder.Id;
        salesOrderOtherCharges.TypeOfCharge__c = Constants.BUDGET_LINE_ADMFEE;
        //salesOrderOtherCharges.PendingAmount__c = 1000;
        insert salesOrderOtherCharges;
    }
    
    @isTest
    public static void CustomerGetStageTest(){
        HexaBPM__Service_Request__c unitName = [Select id from HexaBPM__Service_Request__c limit 1];
        account Acc = [Select id from Account limit 1];
        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/getServiceRequestStage';
        req.params.put('unitName',unitName.Id);
        req.params.put('customerId',Acc.Id);
        req.httpMethod = 'Get';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        
        //Test.startTest();
        //ServiceRequestTriggerHandlerTest.testLPCWaiver();
        CustomerGetServiceRequestStageWebService.getstage();
        Test.stopTest(); 
    }
    //@isTest
    /*public static void CustomerGetStageTest2(){
        HexaBPM__Service_Request__c unitName = [Select id from HexaBPM__Service_Request__c limit 1];
        account Acc = [Select id from Account limit 1];
        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/getServiceRequestStage';
        req.params.put('unitName',null);
        req.params.put('customerId',null);
        req.httpMethod = 'Get';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        CustomerGetServiceRequestStageWebService.getstage();
        RestContextHandler handler = new RestContextHandler(false);
        handler.getRequestBodyMapObject();
        handler.finalize();
        Test.stopTest();
                
         
    }*/
}