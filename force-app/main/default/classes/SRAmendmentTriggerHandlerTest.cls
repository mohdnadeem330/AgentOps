@isTest(SeeAllData=false)
public class SRAmendmentTriggerHandlerTest {
    @isTest static void setupData() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        acc.Email__c = 'test@test.com';
        acc.OwnerManagerEmail__c = 'test1@test.com';
          acc.BankEmail__c = 'test2@test.com';
        acc.CustomerVertical__c= 'LSQ';
        insert acc;
        
        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        acc1.Email__c = 'test@test.com';
        acc1.OwnerManagerEmail__c = 'test1@test.com';
          acc1.BankEmail__c = 'test2@test.com';
        insert acc1;        
       
       Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
       Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.AmountPayable__c = 10000;
        salesOrder.NetAmount__c = 100000;
        salesOrder.SellingPrice__c=1000000;
        insert salesOrder;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.PROPERTY_TRANSFER_RT);        
        insert SRTemplateDetailRecord;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord1 = TestObjectsFactory.getSRTemplate(Constants.SPA_REGISTRATION_TYPE);        
        insert SRTemplateDetailRecord1;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Property Transfer', 'PropertyTransfer');
        insert objStepTemplate;
        
        HexaBPM__Step_Template__c objStepTemplate1 = TestObjectsFactory.getStepTemplate('SPA Registration For Off Plan', 'SPARegistrationForOffPlan');
        insert objStepTemplate1;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__SR_Steps__c objSRSteps1 = TestObjectsFactory.getSRStep(SRTemplateDetailRecord1.Id, objStepTemplate1.Id);
        insert objSRSteps1;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;

        HexaBPM__SR_Status__c closed = TestObjectsFactory.getSRStatus(Constants.CLOSED_SR);
        insert closed;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;
        
        Id spaRegistrationID = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'SPA Registration For Off Plan');
        HexaBPM__Service_Request__c newSR1 = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.SPA_REGISTRATION_TYPE, spaRegistrationID, SRTemplateDetailRecord1.Id);
        insert newSR1;
        
        HexaBPM__Service_Request__c newSR2 = new HexaBPM__Service_Request__c();
        
       newSR2.id = newSR1.id;
         newSR2.HexaBPM__External_SR_Status__c = closed.id;
        Update newSR2;
        
        
        Id propertyTransferId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
        Test.startTest();
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.PROPERTY_TRANSFER_TYPE, propertyTransferId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.HexaBPM__Customer__c = acc.Id;
        newSR.BuyerName__c = acc.Id;
        newSR.SalesOrder__c = salesorder.Id;
        newSR.TransferSellingPrice__c =1000000;
        newSR.HexaBPM__Email__c = 'test1@test.com';
        newSR.BuyerEmail__c = 'test2@test.com';
      
        insert newSR;       
        
        AgencyTeam__c agencyTeam = new AgencyTeam__c();
        agencyTeam.Account__c = acc.Id;
        agencyTeam.ServiceRequest__c = newSR.Id;
        agencyTeam.ShareHoldingPercentage__c = 20;
        agencyTeam.RelationshipType__c = 'Spouse Of';
        agencyTeam.recordTypeId = Utilities.getRecordTypeId('AgencyTeam__c', Constants.JOINT_OWNER_RT);
        insert agencyTeam;
        
        //Test.startTest();
            
        AgencyTeam__c agencyTeam1 = new AgencyTeam__c();
        agencyTeam1.id = agencyTeam.id;
        agencyTeam1.Account__c = acc1.Id;
        agencyTeam1.ShareHoldingPercentage__c = 40;
        
        update agencyTeam1;
        
        
        
       // Test.StopTest();
        
        
    }
    
    
}