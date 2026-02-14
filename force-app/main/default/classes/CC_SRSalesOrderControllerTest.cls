@isTest(SeeAllData=false)
public class CC_SRSalesOrderControllerTest {
    @isTest static void setupData() {
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        acc.CustomerType__c = 'New Customer';
        insert acc; 

        //Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org1', 'G1234561');
        //acc1.CustomerType__c = 'New Customer';
        //insert acc1;

        //Account bankAccount = TestObjectsFactory.getAccountRecord('Bank', false, '');
        //bankAccount.BankEmail__c = 'ajay.thakur.tpr@pwc.com';
        //bankAccount.Name = 'Abu Dhabi Commercial Bank';
        //insert bankAccount;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        UtilitiesWithoutSharing.bypassOpportunityTrigger = true;
        insert opp;
        UtilitiesWithoutSharing.bypassOpportunityTrigger = false;
        List<Unit__c> insertUnitList =new List<Unit__c>();
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insertUnitList.add(unit);
        //insert unit;

        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25084');
        unit1.Name = 'MAYAN-B1-1004';
        unit1.Status__c = 'Sold';
        insertUnitList.add(unit1);
        
        insert insertUnitList;
        //insert unit1;

        List<SalesOrder__c> salesOrderList =new List<SalesOrder__c>();
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = insertUnitList[0].Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.AmountPayable__c = 10000;
        //salesOrder.MortgageApplicable__c = 'Yes';
        salesOrderList.add(salesOrder);
        //insert salesOrder;
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = insertUnitList[1].Id;
        salesOrder1.Contact__c = con.Id;
        salesOrder1.AmountPayable__c = 10000;
		salesOrder1.MortgageApplicable__c = 'Yes';
        salesOrderList.add(salesOrder1);
        insert salesOrderList;
        
        HexaBPM__SR_Status__c stClosed = new HexaBPM__SR_Status__c(Name = 'Closed',HexaBPM__Code__c = 'Closed' );
        insert stClosed;

        HexaBPM__SR_Template__c spaTemp = TestObjectsFactory.getSRTemplate(Constants.SPA_REGISTRATION_TYPE);  
        insert spaTemp;

        Id spaRT = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);

        HexaBPM__Service_Request__c spaSR = TestObjectsFactory.getServiceRequest(stClosed.Id,insertUnitList[0].Id,Constants.SPA_REGISTRATION_TYPE,spaRT,spaTemp.Id);
        spaSR.SalesOrder__c = salesOrderList[0].Id;
        spaSR.SPACounterSignedDate__c = Date.today();
        insert spaSR;
        
        HexaBPM__Service_Request__c spaSR1 = TestObjectsFactory.getServiceRequest(stClosed.Id,insertUnitList[1].Id,Constants.SPA_REGISTRATION_TYPE,spaRT,spaTemp.Id);
        spaSR1.SalesOrder__c = salesOrderList[1].Id;
        spaSR1.SPACounterSignedDate__c = Date.today();
        insert spaSR1;
        
		
		JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrderList[0].Id, acc.Id, 'Friend Of');		
        Insert jointOwner;

        

        //JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder1.Id, acc1.Id,'Third Party');
        //insert jointOwner;

       List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrderList[0].Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrderList[0].Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;
   
        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrderList[0].Id, acc.Id);
        
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
       
        List<HexaBPM__Service_Request__c> insertSRList =new List<HexaBPM__Service_Request__c>();
        Id propertyTransferId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
        Test.startTest();
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, insertUnitList[0].Id, Constants.PROPERTY_TRANSFER_TYPE, propertyTransferId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.HexaBPM__Customer__c = acc.Id;
        newSR.BuyerName__c = acc.Id;
        newSR.SalesOrder__c = salesOrderList[0].Id;
        newSR.HexaBPM__Email__c ='abc@aldar.com';
        newSR.BuyerEmail__c ='abc@aldar.com';
        newSR.TransferSellingPrice__c = 120000;
        insertSRList.add(newSR);
        
        HexaBPM__Service_Request__c newSR1 = TestObjectsFactory.getServiceRequest(draft.Id, insertUnitList[1].Id, Constants.PROPERTY_TRANSFER_TYPE, propertyTransferId, SRTemplateDetailRecord.Id);
        newSR1.ChargeCollected__c = 2000;
        newSR1.HexaBPM__Customer__c = acc.Id;
        newSR1.BuyerName__c = acc.Id;
        newSR1.TransferSellingPrice__c = 120000;
        newSR1.SalesOrder__c = salesOrderList[1].Id;
        newSR1.HexaBPM__Email__c ='abc@aldar.com';
        newSR1.BuyerEmail__c ='abc@aldar.com';
        newSR1.ChargeType__c = 'Court Order';
        insertSRList.add(newSR1);
        insert insertSRList;
        
         HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = 'Pending';
        status.HexaBPM__Code__c = 'Pending';
        insert status;

        List<HexaBPM__Step__c> insertStepList = new List<HexaBPM__Step__c>();
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(insertSRList[0].Id, objSRSteps.Id, objStepTemplate.id); 
        newStep.HexaBPM__Status__c = status.Id;
        newStep.HexaBPM__Summary__c = 'test';
        newStep.HexaBPM__SR__c = insertSRList[0].Id;
        insertStepList.add(newStep);
       // insert newStep;

		HexaBPM__Step__c newStep1 = TestObjectsFactory.getServiceRequestStep(insertSRList[1].Id, objSRSteps.Id, objStepTemplate.id); 
        newStep1.HexaBPM__Status__c = status.Id;
        newStep1.HexaBPM__Summary__c = 'test';
        newStep1.HexaBPM__SR__c = insertSRList[1].Id;
        insertStepList.add(newStep1);
        insert insertStepList;
        system.debug('@@@insertStepList'+insertStepList);
        system.debug('@@@insertSRList'+insertSRList);
        //insert newStep1; 

        CC_SRSalesOrderController salesOrderController =  new CC_SRSalesOrderController();
        salesOrderController.EvaluateCustomCode(insertSRList[0],insertStepList[0]);
        salesOrderController.EvaluateCustomCode(insertSRList[1],insertStepList[1]);
        CC_SRSalesOrderController.createTransferHistory(insertSRList[0]); 

       

        newSR.Unit__c = unit1.Id;
        newSR.salesOrder__c = salesOrder1.Id;
       // update newSR;

      
        
        //SR TEMPLATE
        HexaBPM__SR_Template__c SR_Template1 = new HexaBPM__SR_Template__c();
        SR_Template1.Name = Constants.RECORDTYPE_HANDOVER;
        SR_Template1.HexaBPM__SR_RecordType_API_Name__c=Constants.RECORDTYPE_HANDOVER;
        insert SR_Template1;
        
        
        // STEP AND STEP TEMPLATE
        list<HexaBPM__Step_Template__c> stepTemplateToInsert = new list<HexaBPM__Step_Template__c>();
        list<String> templatesCode = new list<String>{Constants.STEP_NAME_KAR_ASSIGNMENT,
                                                Constants.STEP_NAME_FINANCE_VERIFICATION,
                                                Constants.STEP_NAME_DESNAGGING_APPOINTMENT,
                                                Constants.STEP_NAME_UTILITY_TRANSFER,
                                                Constants.STEP_NAME_KEYHANDOVER_APPOINTMENT,
                                                Constants.STEP_NAME_SNAGGING_APPOINTMENT,
                                                Constants.STEP_NAME_HANDOVER_PHASING,
                                                Constants.STEP_NAME_TITLE_DEED};
        for(String tempS : templatesCode){
            HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
            ST.Name = tempS;
            ST.HexaBPM__Code__c = tempS;
            ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
            stepTemplateToInsert.add(ST);
        }
        insert stepTemplateToInsert;
        
        list<HexaBPM__SR_Steps__c> templateSteps = new list<HexaBPM__SR_Steps__c>();
        for(HexaBPM__Step_Template__c tempRec : stepTemplateToInsert){
            HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
            SRStep.HexaBPM__SR_Template__c = SR_Template1.id;
            SRStep.HexaBPM__Step_No__c = templateSteps.size()+1;
            SRStep.HexaBPM__Step_Template__c = tempRec.Id;
            SRStep.HexaBPM__Summary__c = tempRec.Name;
            SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
            templateSteps.add(SRStep);
        }   
        insert templateSteps;
        
        //SR Status 
        insert new list<HexaBPM__SR_Status__c>{ TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_APPOINTMENT_BOOKED),
                                                TestObjectsFactory.getSRStatus(Constants.STEP_STATUS_SENT)};
        
        //SR AND STEP
        Id handoverRecordType = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = handoverRecordType;
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.HexaBPM__External_SR_Status__c = draft.Id;
        //SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template1.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.TransferSellingPrice__c = 120000;
        insert SR;
        system.debug('@@@SR'+SR);
		system.debug('@@@SR'+SR.RecordType.Name +' -> '+SR.HexaBPM__External_Status_Name__c);

        list<HexaBPM__Step__c> srSteps = new list<HexaBPM__Step__c>();
        for(HexaBPM__SR_Steps__c tempRec : templateSteps){
            HexaBPM__Step__c step = new HexaBPM__Step__c();
            step.HexaBPM__Summary__c = tempRec.HexaBPM__Summary__c;
            step.HexaBPM__SR__c = SR.Id;
            step.HexaBPM__SR_Step__c = tempRec.Id;
            step.HexaBPM__Start_Date__c = System.today();
           step.HexaBPM__Status__c = status.Id;
        step.HexaBPM__Summary__c = 'test';
            srSteps.add(step);
        }
        insert srSteps;
        
        newStep.HexaBPM__SR__c = SR.Id;
        //Update newStep;
        HexaBPM__Service_Request__c hexaSr = [SELECT Id,HandoverDetail__c,RecordType.Name,HexaBPM__External_Status_Name__c FROM HexaBPM__Service_Request__c WHERE Id =: SR.Id];     
        system.debug('hexaSr '+hexaSr);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(''));
        
        System.debug('@@@newStep'+newStep);
        //salesOrderController.EvaluateCustomCode(SR,newStep);
        CC_AldarStaffValidationPTCtrl cAldar = new CC_AldarStaffValidationPTCtrl();
        cAldar.EvaluateCustomCode(newSR,newStep);
        Test.StopTest();
        
    }
    
    
}