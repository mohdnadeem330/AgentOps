@isTest(SeeAllData=false)
public class LPCServiceTest {
    @isTest static void setupMethod() {
         HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = Constants.STEP_STATUS_CUSTOMER_SETTELED;
        status.HexaBPM__Code__c = Constants.STEP_STATUS_CUSTOMER_SETTELED;
        insert status;
        
         HexaBPM__Status__c status1 = new HexaBPM__Status__c();
        status1.Name = Constants.STEP_STATUS_TRANSFER_LEGAL;
        status1.HexaBPM__Code__c = Constants.STEP_STATUS_TRANSFER_LEGAL;
        insert status1;
        
        HexaBPM__Status__c status2 = new HexaBPM__Status__c();
        status2.Name = Constants.SR_STATUS_CLOSED;
        status2.HexaBPM__Code__c = Constants.SR_STATUS_CLOSED;
        insert status2;
        
        HexaBPM__SR_Status__c Closed = TestObjectsFactory.getSRStatus('Closed');       
        insert Closed;
        
        HexaBPM__SR_Status__c Draft = TestObjectsFactory.getSRStatus('Draft');       
        insert Draft;
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;

        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc1;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.MortgageApplicationNumber__c = '1234';
        insert salesOrder;

        Unit__c unitdetails = [SELECT Id,BuildingSectionName__c FROM Unit__c WHERE Id =: unit.Id];

        BuildingSection__c newBuilding = new BuildingSection__c();
        newBuilding.Id = unitdetails.BuildingSectionName__c;
        newBuilding.LatePaymentCharges__c = 2;
        update newBuilding;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 4);
        
        installmentLines[0].AmountReceived__c = 100;
        installmentLines[0].InvoicedAmount__c = 90;
        installmentLines[0].InvoiceNumber__c = '638221';
        installmentLines[0].InstallmentDate__c = Date.Today().addDays(-10);
        installmentLines[0].ExtensionDate__c = Date.Today().addDays(-5);
        
        installmentLines[1].AmountReceived__c = 100;
        installmentLines[1].InvoicedAmount__c = 90;
        installmentLines[1].InvoiceNumber__c = '638221';
        installmentLines[1].InstallmentDate__c = Date.Today().addDays(-10);
        installmentLines[1].LPCFreezeDate__c = Date.Today().addDays(-5);
        installmentLines[1].LPCFreezeUntilDate__c = Date.Today().addDays(20);
        
        installmentLines[2].InvoiceNumber__c = '638221';
        installmentLines[2].InstallmentDate__c = Date.Today().addDays(-5);
        
        update installmentLines ;
        Test.StartTest();
        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);

        ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        receipt.Status__c = Constants.RECEIPT_STATUS_CLEARED;
        receipt.ClearedDate__c = Date.Today();
        insert receipt;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwner(acc1.Id,20,'Friend Of');
        jointOwner.SalesOrder__c = salesOrder.Id;
        insert jointOwner;

        ReceiptAllocation__c recAllocation = TestObjectsFactory.getReceiptAllocationRecord(receipt.Id, salesOrder.Id, acc.Id, installmentLines[0].Id);
        insert recAllocation;

        ReceiptAllocation__c recAllocation1 = TestObjectsFactory.getReceiptAllocationRecord(receipt.Id, salesOrder.Id, acc.Id, otherCharges.Id);
        insert recAllocation1;

        List<ReceiptAllocation__c> allocationList = new List<ReceiptAllocation__c>();
        allocationList.add(recAllocation);
        allocationList.add(recAllocation1);

        ReceiptAllocation__c recAllocation2 = [SELECT Id, ReceiptAcknowledgement__r.ClearedDate__c, AmountApplied__c FROM ReceiptAllocation__c WHERE Id =: recAllocation1.Id];
        InstallmentLines__c installmentRec = [SELECT Id, AmountReceived__c, InvoicedAmount__c, InvoiceNumber__c, InstallmentDate__c, LPCPercentage__c, OutstandingAmount__c, InstallmentAmount__c FROM InstallmentLines__c WHERE Id =: installmentLines[0].Id ];

        List<SalesOrderOtherCharges__c> otherChargeList = new List<SalesOrderOtherCharges__c>();
        
        SalesOrderOtherCharges__c otherCharges1 = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        otherCharges1.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_LPC_WAIVED_AMOUNT ;
        otherChargeList.add(otherCharges1);
        
        SalesOrderOtherCharges__c otherCharges2 = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        otherCharges2.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_LPC_WAIVED_AMOUNT ;
        otherCharges2.InvoicedAmount__c = 150 ;
        otherChargeList.add(otherCharges2);
        
        update otherChargeList ;
        
       
        
        PageReference pageRef = Page.StatementOfAccountDocument;
        Test.setCurrentPage(pageRef);  
		ApexPages.currentPage().getParameters().put('id',salesOrder.Id);

        StatementOfAccountController.getSalesOrderDetails();   
        StatementOfAccountController.getListSalesOrderDetail(new List<Id>{salesOrder.Id});   
        LPCService.getOutstandingLPCforSalesOrder(salesOrder.Id);   

        Map<Id,List<ReceiptAllocation__c>> installmentAllocationMap = new Map<Id,List<ReceiptAllocation__c>>();
        installmentAllocationMap.put(installmentLines[0].Id, allocationList) ;
        LPCService.getLPCForSalesOrder(salesOrder, installmentLines, installmentAllocationMap);

        Test.StopTest();

    }
    @isTest
    public static void lpcTest() {
        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc1;

        Contact con = TestObjectsFactory.contactDataSetup(acc1.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc1.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc1.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.MortgageApplicationNumber__c = '1234';
        insert salesOrder;
        Test.StartTest();
        LPCService.getOutstandingLPCforSalesOrder(salesOrder.id);
        LPCService.calculateLPCAmount(1000000,30,50);
        LPCService.getNumberOfDays(Date.today(),Date.today()+5);
        Test.StopTest();
    }
    
	@isTest
    public static void lpcBeforeInsert() {
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.Golden_Visa_DEV_RT, 'GoldenVisa');
        insert objStepTemplate;
        Account newAccount = TestObjectsFactory.getPersonAccountRecord();
        insert newAccount;        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.SellingPrice__c=1000000;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;        
        List<InstallmentLines__c> installmentLines1 = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 1);
        installmentLines1[0].InvoicedAmount__c = 30;        
        update installmentLines1;
        HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('Golden Visa');     
        SRTemplateDetailRecord3.Name = Constants.PROPERTY_TRANSFER_RT;
        insert SRTemplateDetailRecord3;
        
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord3.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        List < HexaBPM__Service_Request__c > SRList = new List < HexaBPM__Service_Request__c > ();
        
        HexaBPM__Service_Request__c newSR1 = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, 'Golden Visa', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Golden Visa'), SRTemplateDetailRecord3.Id);
        newSR1.SalesOrder__c = salesOrder.Id;        
        newSR1.Unit__c = unit.Id;  
        newSR1.IsComplianceReturned__c = false;
        newSR1.Compliance_Status__c = '';
        newSR1.TransferSellingPrice__c= 1000000; 
        newSR1.InstallmentLine__c =installmentLines1[0].Id;
        newSR1.PaymentExtensionDate__c = Date.today() +3;
        newSR1.HexaBPM__Customer__c = newAccount.Id;
        newSR1.TotalLPCDue__c = 100;
        newSR1.WaivedAmount__c = 2000;
        newSR1.WaivedBy__c = 'Percentage';
        SRList.add(newSR1);
        insert SRList;
        Map<HexaBPM__Service_Request__c,Id> srMapSO = new Map<HexaBPM__Service_Request__c,Id>();
        for(HexaBPM__Service_Request__c sr : SRList) {
            srMapSO.put(sr,sr.SalesOrder__c);
        }
        Map<id,HexaBPM__Service_Request__c> oldMap = new Map<id,HexaBPM__Service_Request__c>();
        Map<id,HexaBPM__Service_Request__c> newMap = new Map<id,HexaBPM__Service_Request__c>();
        List < HexaBPM__Service_Request__c > newList5 = new List < HexaBPM__Service_Request__c > ();
        List<HexaBPM__Service_Request__c> updRec = [Select id,Unit__c,SalesOrder__c,InstallmentLine__c,SRType__c,TotalCollectedAmount__c,HexaBPM__Record_Type_Name__c,HexaBPM__Contact__c,PaidEquity__c,
                                                     Proceed_with_Offline__c,HexaBPM__Submitted_DateTime__c,Bypass_Equity_Check__c,ExemptValidations__c,RecordTypeId,Case__c,HexaBPM__Customer__c,PaymentExtensionDate__c,
                                                     CancellationReason__c,WaivedPercentage__c,WaivedAmount__c,WaivedBy__c,InstallmentDate__c,PaymentExtensionPeriod__c,HexaBPM__SR_Template__c,TotalLPCAmount__c,
                                                     LegalStatus__c,TermCommencementDate__c,TotalLPCDue__c,TotalLPCCollected__c,ChargeCollected__c,TotalLPCWaivedAmount__c,LPCCalculatedDate__c,
                                                     SocialReason__c,HexaBPM__Parent_SR__c,HandoverDetail__c,OldNetAmount__c,TotalBilledAmount__c,TotalOutstandingAmount__c,RefundAmount__c,ReallocationAmount__c,IsRefundApplicable__c,
                                                     LPCFreezeStatus__c,DocumentPrintedDate__c,HexaBPM__Closed_Date_Time__c,HexaBPM__IsClosedStatus__c,TitleDeedRegistrationFee__c,HexaBPM__External_SR_Status__c,HexaBPM__External_Status_Name__c,BlacklistedCustomer__c,
                                                     PriceRevisionRequired__c,ForfeitAmount__c,CancellationOption__c,AgreementType__c,
                                                     BuyerOwnershipVerifiedDari__c,Retrive_Buyer_Acc_Docs__c,SubType__c,BrokerManager__c,HOKAR__c,UnitFromSameProject__c,SwappedUnit__c,SalesOrderHoldFlag__c,BuyerName__c,ReferredBy__c,OwnerId from HexaBPM__Service_Request__c where id =:SRList[0].id limit 1 ];
        updRec[0].TransferSellingPrice__c= 1000000;
        updRec[0].PaymentExtensionDate__c = Date.today() +5; 
        updRec[0].WaivedAmount__c = 3000;
        updRec[0].IsComplianceReturned__c = true;
        newList5.add(updRec[0]);
        update newList5;
        for(HexaBPM__Service_Request__c sr : newList5) {
            oldMap.put(sr.id,sr);
        }
        Test.StartTest();
        LPCService.submittedLPC(srMapSO);
		LPCService.lpcBeforeInsertLogic(newSR1);
        LPCService.lpcBeforeUpdateLogic(newSR1);
        LPCService.calculateWaiverPercentageAmount(SRList,oldMap);
		Test.StopTest();
                
    }
    
    @isTest
    public static void titleDeedTest() {        
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Registration Completion', 'TitleDeedRegistration');
        insert objStepTemplate;
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert newAccount;        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.SellingPrice__c=1000000;
        insert salesOrder;
		HexaBPM__SR_Status__c Draft = TestObjectsFactory.getSRStatus('Draft');       
        insert Draft;
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;
        List<InstallmentLines__c> installmentLines1 = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 1);
        installmentLines1[0].InvoicedAmount__c = 30;
        update installmentLines1;
         HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('Title Deed Registration');     
        SRTemplateDetailRecord3.Name = 'Title Deed Registration';
        insert SRTemplateDetailRecord3;
                 
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord3.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        List < HexaBPM__Service_Request__c > SRList = new List < HexaBPM__Service_Request__c > ();
        HexaBPM__Service_Request__c newSR1 = TestObjectsFactory.getServiceRequest(Draft.Id, unit.Id, 'Title Deed Registration', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Title Deed Registration'), SRTemplateDetailRecord3.Id);
        newSR1.SalesOrder__c = salesOrder.Id;        
        //newSR1.SwappedUnit__c = unit.Id;
        newSR1.IsComplianceReturned__c = false;
        newSR1.Compliance_Status__c = '';
        newSR1.TransferSellingPrice__c= 1000000; 
        newSR1.InstallmentLine__c =installmentLines1[0].Id; 
        newSR1.Proceed_with_Offline__c = true;
        SRList.add(newSR1);
        insert SRList;
        List < HexaBPM__Service_Request__c > newList5 = new List < HexaBPM__Service_Request__c > ();
        List<HexaBPM__Service_Request__c> updRec = [Select id,Unit__c,SalesOrder__c,InstallmentLine__c,SRType__c,TotalCollectedAmount__c,HexaBPM__Record_Type_Name__c,HexaBPM__Contact__c,PaidEquity__c,
                                                     Proceed_with_Offline__c,HexaBPM__Submitted_DateTime__c,Bypass_Equity_Check__c,ExemptValidations__c,RecordTypeId,Case__c,HexaBPM__Customer__c,PaymentExtensionDate__c,
                                                     CancellationReason__c,WaivedPercentage__c,WaivedAmount__c,WaivedBy__c,InstallmentDate__c,PaymentExtensionPeriod__c,HexaBPM__SR_Template__c,TotalLPCAmount__c,
                                                     LegalStatus__c,TermCommencementDate__c,TotalLPCDue__c,TotalLPCCollected__c,ChargeCollected__c,TotalLPCWaivedAmount__c,LPCCalculatedDate__c,
                                                     SocialReason__c,HexaBPM__Parent_SR__c,HandoverDetail__c,OldNetAmount__c,TotalBilledAmount__c,TotalOutstandingAmount__c,RefundAmount__c,ReallocationAmount__c,IsRefundApplicable__c,
                                                     LPCFreezeStatus__c,DocumentPrintedDate__c,HexaBPM__Closed_Date_Time__c,HexaBPM__IsClosedStatus__c,TitleDeedRegistrationFee__c,HexaBPM__External_SR_Status__c,HexaBPM__External_Status_Name__c,BlacklistedCustomer__c,
                                                     PriceRevisionRequired__c,ForfeitAmount__c,CancellationOption__c,AgreementType__c,
                                                     BuyerOwnershipVerifiedDari__c,Retrive_Buyer_Acc_Docs__c,SubType__c,BrokerManager__c,HOKAR__c,UnitFromSameProject__c,SwappedUnit__c,SalesOrderHoldFlag__c,BuyerName__c,ReferredBy__c,OwnerId from HexaBPM__Service_Request__c where id =:SRList[0].id limit 1 ];
        updRec[0].TransferSellingPrice__c= 1000000;
        updRec[0].PaymentExtensionDate__c = Date.today() +5; 
        updRec[0].WaivedAmount__c = 3000;
        updRec[0].IsComplianceReturned__c = true;
        newList5.add(updRec[0]);
        update newList5;
        Test.startTest();
		LPCService.lpcBeforeInsertLogic(newSR1);
        LPCService.lpcBeforeUpdateLogic(updRec[0]);
		Test.StopTest();
    }
}