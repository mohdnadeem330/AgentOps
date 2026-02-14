@isTest(SeeAllData=false)
public class SRUtilityTest {
    
    
    @isTest static void unitTest1() {
        List<Account> accList = new List<Account>();
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        accList.add(acc);
        
        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        accList.add(acc1);
        
        Account bankAccount = TestObjectsFactory.getAccountRecord('Bank', false, '');
        bankAccount.BankEmail__c = 'ali.athamneh@pwc.com';
        bankAccount.Name = 'Abu Dhabi Commercial Bank';
        accList.add(bankAccount);
        
        insert accList;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ali.athamneh@pwc.com';
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
        salesOrder.MortgageApplicable__c = 'No';
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        installmentLines[0].AmountReceived__c = 100;
        installmentLines[0].InvoicedAmount__c = 10;
        update installmentLines[0];
        
        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        receiptAcknowledgementRec.Amount__c = 10100;
        insert receiptAcknowledgementRec;
        
        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgementRec.Id, salesOrder.Id, acc.Id, installmentLines[0].Id);
        receiptAllocation.DateOfApplication__c = null;
        receiptAllocation.Unapply__c = false;
        insert receiptAllocation;
        
        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);        
        insert SRTemplateDetailRecord;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Internal Mortgage Registration', 'InternalMortgageRegistration');
        insert objStepTemplate;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        List<HexaBPM__SR_Status__c> HexaBPMSRStatusList = new List<HexaBPM__SR_Status__c>();
        
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        HexaBPMSRStatusList.add(draft);
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        HexaBPMSRStatusList.add(Submitted);
        
        HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
        HexaBPMSRStatusList.add(approvedByFinance);
        
        insert HexaBPMSRStatusList;
        
        Id mortgageRegistrationId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);
        Test.startTest();
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.CancellationReason__c = 'Consolidation';
        newSR.SocialReason__c = 'Joint Owners Conflicts';
        newSR.AgreementType__c = 'T1 - Cancellation without Refund';
        newSR.TransferSellingPrice__c = 120000;
        insert newSR;
        
        ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
        insert srReceiptAcknowledgementRec;
        
        
        
        CC_SRMortgageRegistrationController mortageRegistration = new CC_SRMortgageRegistrationController();
        
        newSR.MortgageBank__c = bankAccount.Id;
        newSR.MortgageAmount__c = 100000;
        newSR.StartDate__c = Date.Today().addDays(-100);
        newSR.MortgageApplicationNumber__c = '12345';
        newSR.HexaBPM__External_SR_Status__c =  approvedByFinance.Id;
        newSR.HexaBPM__Internal_SR_Status__c =  approvedByFinance.Id;
        newSR.BuyerName__c = acc.Id;
        newSR.HexaBPM__Customer__c = acc.Id;
        newSR.CancellationReason__c = 'Consolidation';
        newSR.SocialReason__c = 'Joint Owners Conflicts';
        newSR.AgreementType__c = 'T1 - Cancellation without Refund';
        update newSR;
        
        AgencyTeam__c agencyTeam = new AgencyTeam__c();
        agencyTeam.Account__c = acc1.Id;
        agencyTeam.ServiceRequest__c = newSR.Id;
        agencyTeam.ShareHoldingPercentage__c = 20;
        agencyTeam.RelationshipType__c = 'Third Party';
        insert agencyTeam;
        
        SRUnitSelected__c unitSelected = new SRUnitSelected__c();
        unitSelected.Unit__c = unit.Id;
        unitSelected.Name = unit.Name;
        unitSelected.ServiceRequest__c = newSR.Id;
        unitSelected.SalesOrder__c = salesOrder.Id;
        insert unitSelected;
        
        //salesOrder.MortgageApplicable__c = 'Yes';
        //update salesOrder;
        List<ChargeRule__c> chargeRules = new List<ChargeRule__c>();
        ChargeRule__c fullyPaid = TestObjectsFactory.getChargeRuleRecord('Internal Mortgage Registration', 'Fully Paid');     
        chargeRules.add(fullyPaid);
        
        ChargeRule__c notFullyPaid = TestObjectsFactory.getChargeRuleRecord('Internal Mortgage Registration', 'Not Fully Paid');     
        chargeRules.add(notFullyPaid);
        
        insert chargeRules;
        
        Id CancellationRT = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.MUTUAL_CANCELLATION_RT);
        Id MortgageDischargeRT = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_DISCHARGE_RT);
        
        HexaBPM__Service_Request__c serviceRequest = [Select Id, BuyerName__c, SalesOrder__c, (select id, Account__c, ServiceRequest__c, ShareHoldingPercentage__c, RelationshipType__c FROM Partners__r) FROM HexaBPM__Service_Request__c where Id =: newSR.Id];        
        HexaBPM__Service_Request__c receiptAcknowledgement = [Select Id,HexaBPM__Customer__c, SalesOrder__c, ChargeCollected__c, (select id,OutstandingAmount__c FROM Receipt_Acknowledgements__r) FROM HexaBPM__Service_Request__c where Id =: newSR.Id];        
        
        
        
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id); 
        newStep.HexaBPM__Summary__c = 'Test';
        insert newStep;
        
        
        HexaBPM__Service_Request__c consolidationSR = newSR.clone(false, false, false, false);
        consolidationSR.RecordTypeId = CancellationRT;
        consolidationSR.SRType__c = Constants.MUTUAL_CANCELLATION_SUB_TYPE;
        consolidationSR.ChargeType__c = null;
        consolidationSR.CancellationReason__c = 'Consolidation';
        consolidationSR.SocialReason__c = 'Joint Owners Conflicts';
        consolidationSR.AgreementType__c = 'T1 - Cancellation without Refund';
        insert consolidationSR;
        
        SRUnitSelected__c unitSelectedCR = new SRUnitSelected__c();
        unitSelectedCR.Unit__c = unit.Id;
        unitSelectedCR.Name = unit.Name;
        unitSelectedCR.ServiceRequest__c = consolidationSR.Id;
        unitSelectedCR.SalesOrder__c = salesOrder.Id;
        insert unitSelectedCR;
        
        HexaBPM__Document_Master__c objDocMaster = new HexaBPM__Document_Master__c();
        objDocMaster.HexaBPM__Code__c = 'General_Information_for_Regulated_Activities';
        objDocMaster.HexaBPM__Available_to_client__c = true;
        insert objDocMaster;
        
        HexaBPM__SR_Template_Docs__c docTemp = new HexaBPM__SR_Template_Docs__c();
        docTemp.HexaBPM__Document_Master__c = objDocMaster.id ;
        insert docTemp;
        
        HexaBPM__SR_Doc__c objSRDoc = new HexaBPM__SR_Doc__c();
        objSRDoc.HexaBPM__Document_Master__c = objDocMaster.id  ;
        objSRDoc.HexaBPM__SR_Template_Doc__c = docTemp.id;
        objSRDoc.HexaBPM__Service_Request__c = consolidationSR.id  ;
        insert objSRDoc;
        
        HexaBPM__Service_Request__c srUnitSelected = [Select Id, HexaBPM__Customer__c, SalesOrder__c, SRType__c, Case__c, RecordType.Name, (select id, FinalEquityRefund__c, SRType__c, FinalLossCalculation__c, ForfeitedAmount__c, Unit__c, SalesOrder__c, OptionSelected__c  FROM SRUnitSelected__r) FROM HexaBPM__Service_Request__c where Id =: consolidationSR.Id];        
        srUnitSelected.CancellationReason__c = 'Consolidation';
        srUnitSelected.SocialReason__c = 'Joint Owners Conflicts';
        srUnitSelected.AgreementType__c = 'T1 - Cancellation without Refund';
        update srUnitSelected;
        
        Emailtemplate emailTemplateId = [select id, DeveloperName from emailtemplate where DeveloperName = 'Mortgage_Discharge_Mortgage_Release_Approved' limit 1]; 
        String orgWideEmailAddress = Utilities.getOrgWideEmailAddressIdByName(Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE);
        String fileName = 'SOA - '+unit.Name+' - Generated On - '+Date.Today(); 
        
        
        
        /*SRUtility.checkForUnclearedReceipts(installmentLines);
        SRUtility.checkForOutstandingAmountWithBypass(new List<ReceiptAcknowledgement__c> {receiptAcknowledgementRec},newSR); //SS_FOR_RECEIPT_BYPASS_LOGIC_ASF_514
        SRUtility.checkForOutstandingAmount(new List<ReceiptAcknowledgement__c> {receiptAcknowledgementRec});
        
        SRUtility.checkForPropertyMortgage(salesOrder);
        SRUtility.checkLatePaymentCharges(salesOrder.Id);
        SRUtility.createSalesOrderOtherCharge(newSR, Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE);
        SRUtility.createJointOwner(serviceRequest);*/
        SRUtility.createReceiptAllocation(otherCharges, receiptAcknowledgement);
        
        //SRUtility.createReceiptAcknowledgementFromSR(newSR, 'Cash', 2000);
        SRUtility.createSalesOrderOtherCharge(newSR, Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE, 2000);        
        SRUtility.createNewCancellationSRsFromSR(srUnitSelected, Constants.CANCELLATION_RT);
        SRUtility.createReceiptAcknowledgementFromSO(newSR, salesOrder, Constants.PAYMENT_TYPE_CREDIT_NOTE,1000);
        SRUtility.createSalesOrderOtherChargeFromSO(salesOrder, Constants.OTHER_CHARGES_TYPE_DEBIT_MEMO, Constants.OTHER_CHARGES_Charge_TYPE_ADM_Fee_REFUND, 1000, newSR);
        //SRUtility.getSRTemplate(SRTemplateDetailRecord.Name);
        SRUtility.updateServiceRequestStep(newSR.Id, newStep.HexaBPM__Summary__c, '', 'Notes');
        SRUtility.updateMultipleServiceRequestStep(newSR.Id, newStep.HexaBPM__Summary__c, '', 'Notes','');
        SRUtility.getDocumentsToBeUploadedToDARI(newSR.Id);
        SRUtility.submitSRFuture(new List<Id>{newSR.Id});
        SRUtility.checkSumOfRebateAmount(salesOrder.Id,12345);
        
        Test.StopTest();
        
    }
    
    
    @isTest static void testSubSR() {
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org1', 'G1234561');
        insert acc1;
        
        Account bankAccount = TestObjectsFactory.getAccountRecord('Bank', false, '');
        bankAccount.BankEmail__c = 'ajay.thakur.tpr@pwc.com';
        bankAccount.Name = 'Abu Dhabi Commercial Bank';
        insert bankAccount;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25084');
        unit1.Name = 'MAYAN-B1-1004';
        unit1.Status__c = 'Sold';
        insert unit1;
       
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.AmountPayable__c = 10000;
        insert salesOrder;
         Test.startTest();
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit1.Id;
        salesOrder1.Contact__c = con.Id;
        salesOrder1.AmountPayable__c = 10000;
        insert salesOrder1;
        
        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder1.Id, acc1.Id,'Friend Of');
        insert jointOwner;
        
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        
        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;
        
        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
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
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.PROPERTY_TRANSFER_TYPE, propertyTransferId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.HexaBPM__Customer__c = acc.Id;
        newSR.BuyerName__c = acc.Id;
        newSR.SalesOrder__c = salesorder.Id;
        newSR.TransferSellingPrice__c = 120000;
        insert newSR;
        
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        insert newStep;
        
        
        newSR.Unit__c = unit1.Id;
        newSR.salesOrder__c = salesOrder1.Id;
        update newSR;
        
        SRUtility.createNewSRFromSR(newSR, Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);
        
        Test.StopTest();
        
    }
    
    
    @isTest static void setupMethod2() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc1;
        
        Account bankAccount = TestObjectsFactory.getAccountRecord('Bank', false, '');
        bankAccount.BankEmail__c = 'ali.athamneh@pwc.com';
        bankAccount.Name = 'Abu Dhabi Commercial Bank';
        insert bankAccount;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ali.athamneh@pwc.com';
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
        salesOrder.MortgageApplicable__c = 'No';
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        installmentLines[0].AmountReceived__c = 100;
        installmentLines[0].InvoicedAmount__c = 10;
        update installmentLines[0];
        
        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        receiptAcknowledgementRec.Amount__c = 10100;
        insert receiptAcknowledgementRec;
        
        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgementRec.Id, salesOrder.Id, acc.Id, installmentLines[0].Id);
        receiptAllocation.DateOfApplication__c = null;
        receiptAllocation.Unapply__c = false;
        insert receiptAllocation;
        
        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);        
        insert SRTemplateDetailRecord;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Internal Mortgage Registration', 'InternalMortgageRegistration');
        insert objStepTemplate;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;
        
        HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
        insert approvedByFinance;
        
        Id mortgageRegistrationId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrder.Id;
        insert newSR;
        Test.startTest();
        ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
        insert srReceiptAcknowledgementRec;
        
        
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id); 
        newStep.HexaBPM__Summary__c = 'Test';
        insert newStep;
        
        CC_SRMortgageRegistrationController mortageRegistration = new CC_SRMortgageRegistrationController();
        
        newSR.MortgageBank__c = bankAccount.Id;
        newSR.MortgageAmount__c = 100000;
        newSR.StartDate__c = Date.Today().addDays(-100);
        newSR.MortgageApplicationNumber__c = '12345';
        newSR.HexaBPM__External_SR_Status__c =  approvedByFinance.Id;
        newSR.HexaBPM__Internal_SR_Status__c =  approvedByFinance.Id;
        newSR.BuyerName__c = acc.Id;
        newSR.HexaBPM__Customer__c = acc.Id;
        update newSR;
        
        //salesOrder.MortgageApplicable__c = 'Yes';
        //update salesOrder;
        Id CancellationRT = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.MUTUAL_CANCELLATION_RT);
        Id MortgageDischargeRT = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_DISCHARGE_RT);
        
        HexaBPM__Service_Request__c serviceRequest = [Select Id, BuyerName__c, SalesOrder__c, (select id, Account__c, ServiceRequest__c, ShareHoldingPercentage__c, RelationshipType__c FROM Partners__r) FROM HexaBPM__Service_Request__c where Id =: newSR.Id];        
        HexaBPM__Service_Request__c receiptAcknowledgement = [Select Id, HexaBPM__Customer__c, SalesOrder__c, ChargeCollected__c, (select id  FROM Receipt_Acknowledgements__r) FROM HexaBPM__Service_Request__c where Id =: newSR.Id];        
        
        HexaBPM__Service_Request__c mutualCancellationSR = newSR.clone(false, false, false, false);
        mutualCancellationSR.RecordTypeId = CancellationRT;
        mutualCancellationSR.SRType__c = Constants.MUTUAL_CANCELLATION_SUB_TYPE;
        mutualCancellationSR.ChargeType__c = null;
        insert mutualCancellationSR;
        
        Emailtemplate emailTemplateId = [select id, DeveloperName from emailtemplate where DeveloperName = 'Mortgage_Discharge_Mortgage_Release_Approved' limit 1]; 
        String orgWideEmailAddress = Utilities.getOrgWideEmailAddressIdByName(Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE);
        String fileName = 'SOA - '+unit.Name+' - Generated On - '+Date.Today(); 
        
        
        
        SRUtility.generatePdfAndSendEmail(con.Id, emailTemplateId.Id, newSR.Id, orgWideEmailAddress, salesOrder.Id, fileName);
        SRUtility.checkDefaultInstallments(new List<Id>{installmentLines[0].Id});
        
        Test.StopTest();
        
    }
    
    @isTest static void unitTest2() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc1;
        
        Account bankAccount = TestObjectsFactory.getAccountRecord('Bank', false, '');
        bankAccount.BankEmail__c = 'ali.athamneh@pwc.com';
        bankAccount.Name = 'Abu Dhabi Commercial Bank';
        insert bankAccount;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ali.athamneh@pwc.com';
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
        salesOrder.MortgageApplicable__c = 'No';
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        installmentLines[0].AmountReceived__c = 100;
        installmentLines[0].InvoicedAmount__c = 10;
        update installmentLines[0];
        
        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        receiptAcknowledgementRec.Amount__c = 10100;
        insert receiptAcknowledgementRec;
        
        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgementRec.Id, salesOrder.Id, acc.Id, installmentLines[0].Id);
        receiptAllocation.DateOfApplication__c = null;
        receiptAllocation.Unapply__c = false;
        insert receiptAllocation;
        
        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);        
        insert SRTemplateDetailRecord;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Internal Mortgage Registration', 'InternalMortgageRegistration');
        insert objStepTemplate;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;
        
        HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
        insert approvedByFinance;
        
        Id mortgageRegistrationId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrder.Id;
        insert newSR;
        
        Test.startTest();
        ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
        insert srReceiptAcknowledgementRec;
        
        
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id); 
        newStep.HexaBPM__Summary__c = 'Test';
        insert newStep;
        
        CC_SRMortgageRegistrationController mortageRegistration = new CC_SRMortgageRegistrationController();
        
        newSR.MortgageBank__c = bankAccount.Id;
        newSR.MortgageAmount__c = 100000;
        newSR.StartDate__c = Date.Today().addDays(-100);
        newSR.MortgageApplicationNumber__c = '12345';
        newSR.HexaBPM__External_SR_Status__c =  approvedByFinance.Id;
        newSR.HexaBPM__Internal_SR_Status__c =  approvedByFinance.Id;
        newSR.BuyerName__c = acc.Id;
        newSR.HexaBPM__Customer__c = acc.Id;
        update newSR;
        
        //salesOrder.MortgageApplicable__c = 'Yes';
        //update salesOrder;
        Id CancellationRT = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.MUTUAL_CANCELLATION_RT);
        Id MortgageDischargeRT = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_DISCHARGE_RT);
        
        HexaBPM__Service_Request__c serviceRequest = [Select Id, BuyerName__c, SalesOrder__c, (select id, Account__c, ServiceRequest__c, ShareHoldingPercentage__c, RelationshipType__c FROM Partners__r) FROM HexaBPM__Service_Request__c where Id =: newSR.Id];        
        HexaBPM__Service_Request__c receiptAcknowledgement = [Select Id, HexaBPM__Customer__c, SalesOrder__c, ChargeCollected__c, (select id  FROM Receipt_Acknowledgements__r) FROM HexaBPM__Service_Request__c where Id =: newSR.Id];        
        
        HexaBPM__Service_Request__c mutualCancellationSR = newSR.clone(false, false, false, false);
        mutualCancellationSR.RecordTypeId = CancellationRT;
        mutualCancellationSR.SRType__c = Constants.MUTUAL_CANCELLATION_SUB_TYPE;
        mutualCancellationSR.ChargeType__c = null;
        insert mutualCancellationSR;
        
        Emailtemplate emailTemplateId = [select id, DeveloperName from emailtemplate where DeveloperName = 'Mortgage_Discharge_Mortgage_Release_Approved' limit 1]; 
        String orgWideEmailAddress = Utilities.getOrgWideEmailAddressIdByName(Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE);
        String fileName = 'SOA - '+unit.Name+' - Generated On - '+Date.Today(); 
        
        
        
        SRUtility.generatePdfAndSendEmail(con.Id, emailTemplateId.Id, newSR.Id, orgWideEmailAddress, salesOrder.Id, fileName);
        SRUtility.checkDefaultInstallments(new List<Id>{installmentLines[0].Id});
        SRUtility.checkForOutstandingAmount(new List<ReceiptAcknowledgement__c> {receiptAcknowledgementRec});
        
        SRUtility.checkForPropertyMortgage(salesOrder);
        SRUtility.checkLatePaymentCharges(salesOrder.Id);
        SRUtility.createSalesOrderOtherCharge(newSR, Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE);
        SRUtility.createJointOwner(serviceRequest);
        //SRUtility.createReceiptAcknowledgementFromSO(newSR, salesOrder, Constants.PAYMENT_TYPE_CREDIT_NOTE,1000);
        SRUtility.createReceiptAcknowledgementFromSR(newSR,Constants.PAYMENT_TYPE_CREDIT_NOTE,1000);
        SRUtility.checkForOutstandingAmountWithBypass(new List<ReceiptAcknowledgement__c> {receiptAcknowledgementRec},newSR);
        SRUtility.checkForUnclearedReceipts(installmentLines);
        //InternalMortgageRegistration
       // SRUtility.getSRTemplate('InternalMortgageRegistration');
        Test.StopTest();
        
    }
}