@isTest
public class ReceiptAcknowledgementTriggerHandlerTest { 
    //Create test data
    @testSetup static void setupData() {
        Test.startTest();
        //dmummy commit for SSP-697
        // Insert custom setting records to enable integration field check
        // This is required for the callout logic to be triggered in the handler
        List<ReceiptAllocation_Integration_Fields__c> integrationFields = new List<ReceiptAllocation_Integration_Fields__c>();
        integrationFields.add(new ReceiptAllocation_Integration_Fields__c(
            Name = 'Amount__c',
            API__c = 'Amount__c',
            Is_Active__c = true
        ));
        integrationFields.add(new ReceiptAllocation_Integration_Fields__c(
            Name = 'ReferenceNumber__c',
            API__c = 'ReferenceNumber__c',
            Is_Active__c = true
        ));
        integrationFields.add(new ReceiptAllocation_Integration_Fields__c(
            Name = 'PaymentType__c',
            API__c = 'PaymentType__c',
            Is_Active__c = true
        ));
        integrationFields.add(new ReceiptAllocation_Integration_Fields__c(
            Name = 'Status__c',
            API__c = 'Status__c',
            Is_Active__c = true
        ));
        integrationFields.add(new ReceiptAllocation_Integration_Fields__c(
            Name = 'SyncStatus__c',
            API__c = 'SyncStatus__c',
            Is_Active__c = true
        ));
        insert integrationFields;
        Id thirdPartyRecordTypeId = Schema.SObjectType.Sales_Order_Relationship__c.getRecordTypeInfosByName().get('Third Party').getRecordTypeId();
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;
        
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);
        
        // User agencyAdminUser = TestObjectsFactory.getUserRecord(Constants.AGENCY_ADMIN, 'pdbaa');
        // agencyAdminUser.contactId=conRecord.Id;
        // insert agencyAdminUser;
        
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        //opp.BrokerAgentContact__c=conRecord.Id; 
        //opp.BrokerAgentContact__c=conRecord.Id;   
        opp.BrokerAgencyAccount__c =orgAcc.Id;
        opp.Contact__c=conRecord.Id;
        opp.EnquiryTrigger__c = 'Aldar Academies';
        insert opp;
        
        Project__c projectRecord= TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRecord;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('123456');
        unit.Name = 'AliTest';
        unit.Status__c = 'Sold';
        unit.Project__c = projectRecord.id;
        insert unit;
                
        Unit__c un = TestObjectsFactory.unitDataSetup('123789');
        un.Name = 'Test Unit';
        un.Status__c = 'Sold';
        un.Project__c = projectRecord.id;
        insert un;
                
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(projectRecord.id);
        insert buildingRecord;
        Unit__c unitrecord = TestObjectsFactory.getUnitDetail(projectRecord.id,buildingRecord.id);
        insert unitrecord;
        
        SalesOrder__c salesOrderRecord = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrderRecord.Unit__c = unit.id;
        salesOrderRecord.Contact__c = conRecord.Id;
        salesOrderRecord.Email__c = conRecord.Email;
        
        SalesOrder__c salesOrderRecord2 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrderRecord2.Unit__c = unit.id;
        salesOrderRecord2.Contact__c = conRecord.Id;
        salesOrderRecord2.Email__c = conRecord.Email;
        
        insert new List<SalesOrder__c> {salesOrderRecord, salesOrderRecord2};
        
        Sales_Order_Relationship__c sor1 = new Sales_Order_Relationship__c(
            SalesOrder__c = salesOrderRecord.Id, 
            Account__c = acc.Id, 
            RecordTypeId = thirdPartyRecordTypeId
        );
        Sales_Order_Relationship__c sor2 = new Sales_Order_Relationship__c(
            SalesOrder__c = salesOrderRecord2.Id, 
            Account__c = acc.Id, 
            RecordTypeId = thirdPartyRecordTypeId
        );
        
        List<Sales_Order_Relationship__c> sorList = new List<Sales_Order_Relationship__c>{sor1, sor2};
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        paymentPlanRecord.IsActive__c =Constants.YES;
        update paymentPlanRecord;
        BuildingSectionMapping__c buldingPaymentMapping = TestObjectsFactory.getBuildingSectionMapping(paymentPlanRecord.Id,buildingRecord.Id);
        insert buldingPaymentMapping;    
        
        OffersPromotions__c offerRecord= TestObjectsFactory.getOfferPromotion(buildingRecord.Id,projectRecord.Id);
        insert offerRecord;
        OfferLines__c offerLine = TestObjectsFactory.getOfferLine(offerRecord.Id);
        insert offerLine;
        
        boolean eoiFlag= OpportunityEOIService.createOpportunityEOI(opp.Id,acc.Id,projectRecord.Id,buildingRecord.Id,OpportunityEOI__c.UnitModel__c.getDescribe().getPicklistValues()[0].getValue(),
                                                                    '',OpportunityEOI__c.UnitFeatures__c.getDescribe().getPicklistValues()[0].getValue(),
                                                                    'Online','','','1000','100000','1','4');
        eoiFlag= OpportunityEOIService.createOpportunityEOI(opp.Id,acc.Id,projectRecord.Id,buildingRecord.Id,OpportunityEOI__c.UnitModel__c.getDescribe().getPicklistValues()[0].getValue(),
                                                            '',OpportunityEOI__c.UnitFeatures__c.getDescribe().getPicklistValues()[0].getValue(),
                                                            'Online','','','1000','100000','1','4');
    Test.stopTest();
    }
    @isTest
    public static void TestReceiptAcknowledgementTriggerHandler() {
        
        
       Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryTrigger__c = 'Aldar Academies';
        insert opp;
        
        Unit__c unit = [select id from Unit__c Where Name = 'Test Unit' limit 1];
        
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        
        SalesOrderOtherCharges__c salesOrderOtherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        /*ChargeRule__c chargeRule = new ChargeRule__c(SRType__c = 'Cheque Replacement', ChargeType__c = 'Bounced Cheques',IsActive__c = true,ChargeAmount__c = 100,VATChanges__c = 5);
        insert chargeRule;*/
        
        Test.startTest();
        ReceiptAcknowledgement__c receiptAcknowledgementOne = TestObjectsFactory.getReceiptAcknowledgementRecord(null, acc.Id, opp.Id, 'Online');
        receiptAcknowledgementOne.ChequeReceived__c = false;
        //receiptAcknowledgementOne.PaymentType__c = 'Online';
        insert receiptAcknowledgementOne;
        
       
        
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        receiptAcknowledgement.ChequeReceived__c = false;
        insert receiptAcknowledgement;
        
        receiptAcknowledgement.ChequeReceived__c = true;
        update receiptAcknowledgement;
        
        ReceiptAllocation__c receiptAllocation = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, installmentLineList[0].Id);
        insert receiptAllocation;
        
        ReceiptAllocation__c receiptAllocation1 = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, salesOrderOtherCharges.Id);
        receiptAllocation1.InstallmentLine__c = installmentLineList[1].Id;
        insert receiptAllocation1;
        ChargeRule__c CR =new ChargeRule__c();
        CR.ChargeAmount__c=2000;
        //CR.ChargePercentage__c =5;
        CR.VATChanges__c=5;
        CR.SRType__c = 'Cheque Replacement';
        CR.ChargeType__c ='Bounced Cheques';
        CR.IsActive__c =true;
        Insert CR;
        
        TriggerHandler.processedIds = new Set<Id>();
        receiptAcknowledgement.ReferenceNumber__c = '0987654321';
        update receiptAcknowledgement;
        list<OpportunityEOI__c> eoiList =[select id,Opportunity__r.AccountId,Opportunity__r.Contact__c,Opportunity__c,InterestFee__c,PaymentMode__c from OpportunityEOI__c];
        ReceiptAcknowledgementTriggerHandler.UpdateEOISTatus(new map<Id,OpportunityEOI__c> {eoiList[0].Id => null} );
//        ReceiptAcknowledgementTriggerHandler.updateInstallmentOtherChargesOnDelete(new set<Id>{receiptAllocation1.id});
        ReceiptAcknowledgementTriggerHandler.updateInstallmentOtherChargesOnDelete(new set<Id>{receiptAllocation1.id});
        ReceiptAcknowledgementTriggerHandler.createOtherCharge(new List<ReceiptAcknowledgement__c>{receiptAcknowledgement});
       // ReceiptAcknowledgementTriggerHandler.createOtherCharge(new List<ReceiptAcknowledgement__c>{receiptAcknowledgement});
        Test.stopTest();
    }
    @isTest
    public static void TestDeleteReceiptAcknowledgement() {
        // Minimal data setup
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryTrigger__c = 'Aldar Academies';
        insert opp;
        Project__c projectRec = TestObjectsFactory.getProjectRecord('Mayan');
        insert projectRec;
        BuildingSection__c buildingRec = TestObjectsFactory.getBuildingDetailRecord(projectRec.id);
        insert buildingRec;
        Unit__c unitrec = TestObjectsFactory.getUnitDetail(projectRec.id, buildingRec.id);
        insert unitrec;
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unitrec.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.Email__c = con.Email;
        insert salesOrder;
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        SalesOrderOtherCharges__c salesOrderOtherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        insert receiptAcknowledgement;
        List<ReceiptAllocation__c> allocations = new List<ReceiptAllocation__c>{
            TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, installmentLineList[0].Id),
            TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, salesOrderOtherCharges.Id)
        };
        insert allocations;
        // Only update what is necessary
        Test.startTest();
        receiptAcknowledgement.ReferenceNumber__c = '0987654321';
        receiptAcknowledgement.Remarks__c = 'parking';
        receiptAcknowledgement.PaymentType__c = 'Online';
        // Simulate deletion scenario
        allocations[0].Unapply__c = true;
        allocations[1].Unapply__c = true;
        update allocations;
        receiptAcknowledgement.Markfordeletion__c = true;
        update receiptAcknowledgement;
        Test.stopTest();
    }
    
    @isTest
    public static void TestExceptionReceiptAcknowledgement() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryTrigger__c = 'Aldar Academies';
        insert opp;
        
        Unit__c unit = [select id from Unit__c where Name = 'Test Unit' limit 1];
        
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        
        
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Credit Card');
        receiptAcknowledgement.ReferenceNumber__c = 'Test112233445511';
       
        try{
            ReceiptAcknowledgementTriggerHandler.throwExceptionForTest = true;
            insert receiptAcknowledgement;
            
        }catch(Exception e){
            
        }
        
        Test.stopTest();
    }
    @isTest
    public static void TestReceiptAcknowledgementSR1() {
        Test.startTest();  
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = [select id from Unit__c where Name = 'Test Unit' limit 1];
        unit.Status__c = 'Sold';
        update unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.Account__c = acc.Id;
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        
        SalesOrderOtherCharges__c salesOrderOtherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);        
        insert SRTemplateDetailRecord;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Internal Mortgage Registration', 'InternalMortgageRegistration');
        insert objStepTemplate;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__SR_Status__c closed = TestObjectsFactory.getSRStatus('Closed');       
        insert closed;
        
        HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
        insert approvedByFinance;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert submitted;
        
        Id mortgageRegistrationId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.No_Charge_Fee_Required__c = true;
        insert newSR;
        
        ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
        srReceiptAcknowledgementRec.Status__c = 'Received';
        
        insert srReceiptAcknowledgementRec;
        Map<Id,Id> rcOldMap = new Map<Id,Id>();
        for(ReceiptAcknowledgement__c rMap:[select id,SalesOrder__c from ReceiptAcknowledgement__c]){
            rcOldMap.put(rMap.Id,rMap.Id);
        }
        //ReceiptAcknowledgementTriggerHandler.onSalesOrderChange([select id,SalesOrder__c,SalesOrder__r.Account__c,Account__c from ReceiptAcknowledgement__c], rcOldMap);
        ReceiptAcknowledgementTriggerHandler.onSalesOrderChange([select id,SalesOrder__c,SalesOrder__r.Account__c,Account__c from ReceiptAcknowledgement__c LIMIT 2]);
        srReceiptAcknowledgementRec.SyncStatus__c = Constants.STATUS_SYNCED;
        update srReceiptAcknowledgementRec;
        
        Map<Id, ReceiptAcknowledgement__c> srRAMap = new Map<Id, ReceiptAcknowledgement__c>();
        srRAMap.put(newSR.Id, srReceiptAcknowledgementRec);
        ReceiptAcknowledgementTriggerHandler.updateServiceForReceipts(srRAMap);
        Test.stopTest();
    }
   /* Test comments
    * @isTest
    public static void TestReceiptAcknowledgementSR() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@pwc.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = [select id from Unit__c limit 1];
        unit.Status__c = 'Sold';
        update unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
        
        SalesOrderOtherCharges__c salesOrderOtherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);        
        insert SRTemplateDetailRecord;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Internal Mortgage Registration', 'InternalMortgageRegistration');
        insert objStepTemplate;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__SR_Status__c closed = TestObjectsFactory.getSRStatus('Closed');       
        insert closed;
        
        HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
        insert approvedByFinance;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert submitted;
        
        Id mortgageRegistrationId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        insert newSR;
        
        ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
        srReceiptAcknowledgementRec.Status__c = 'Received';
        insert srReceiptAcknowledgementRec;
        
        TriggerHandler.processedIds = new Set<Id>();
        srReceiptAcknowledgementRec.Status__c = 'Cleared';
        update srReceiptAcknowledgementRec;
        Test.startTest();
   
       
        try{
            Case caseRec = TestObjectsFactory.getStandardCase(acc.Id, con.Id, 'Customer Management');
            caseRec.Unit__c = unit.Id;
            caseRec.CustomerType__c = 'Owner';
            insert caseRec;
        
            ReceiptAcknowledgementTriggerHandler.updateCase(new Set<Id>{caseRec.Id});
            
            ReceiptAllocation__c receiptAllocation1 = TestObjectsFactory.getReceiptAllocationRecord(srReceiptAcknowledgementRec.Id, salesOrder.Id, acc.Id, salesOrderOtherCharges.Id);
            receiptAllocation1.AmountApplied__c = 1000;
            insert receiptAllocation1;
            
            ReceiptAcknowledgementTriggerHandler receiptAcknowledgementTriggerHandler1 = new ReceiptAcknowledgementTriggerHandler();
            
            
            Map<Id, ReceiptAllocation__c> recMap = new Map<Id, ReceiptAllocation__c>();
            recMap.put(srReceiptAcknowledgementRec.Id, receiptAllocation1);
            System.debug('receiptAllocation1' + receiptAllocation1);
            
            receiptAcknowledgementTriggerHandler1.beforeDeleteMethod(new List<ReceiptAllocation__c>{receiptAllocation1}, recMap );
            ReceiptAcknowledgementTriggerHandler.unApplyReceiptsBeforeDelete(recMap);
            try{
                ReceiptAcknowledgementTriggerHandler.unApplyReceiptsBeforeDelete(null);
            }catch(Exception ex){
                System.debug('Exception');
            }
            //ReceiptAcknowledgementTriggerHandler.updateInstallmentOtherChargesOnDelete(new set<Id>{receiptAllocation1.id});
            Test.stopTest();
        }catch(Exception e){}
    }*/
    @isTest
    public static void TestfreezeLPCForMortgagePaymentTypes() {

        Test.startTest();

        Unit__c unit = [select id from Unit__c Where Name = 'Test Unit' limit 1];
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        Id handoverRecordType = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        //Handover 
        HandoverDetails__c hodetail = new HandoverDetails__c(UnitOfferedDate__c = system.today(),
                                                                        Unit__c = unit.Id,
                                                                        HandoverPhaseDate__c = system.today(),
                                                                        Status__c=Constants.HO_STATUS_READY,
                                                                        Stage__c=Constants.HO_STAGE_OFFERED_BY_PROJECTS,
                                                                        SalesOrder__c = salesOrder.Id,
                                                                        isRTOHandover__c =  false,
                                                                        UtilityTransferStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY,
                                                                        TitleDeedStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY,
                                                                        HandoverCompletionDate__c = null);                                        
        insert hodetail; 

        //SR TEMPLATE
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = Constants.RECORDTYPE_HANDOVER;
        SR_Template.HexaBPM__SR_RecordType_API_Name__c=Constants.RECORDTYPE_HANDOVER;
        insert SR_Template;  

        //SR AND STEP
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = handoverRecordType;
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.HandoverDetail__c = hodetail.Id;
        insert SR;

        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, Constants.MORTGAGE_CHEQUE);
        receiptAcknowledgement.ChequeReceivedDate__c = null;
        insert receiptAcknowledgement;

        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        installmentLineList[0].AmountReceived__c = installmentLineList[0].InstallmentAmount__c;
        installmentLineList[1].AmountReceived__c = installmentLineList[1].InstallmentAmount__c;
        update installmentLineList;

        ReceiptAllocation__c receiptAllocation_1 = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, installmentLineList[0].Id);
        ReceiptAllocation__c receiptAllocation_2 = TestObjectsFactory.getReceiptAllocationRecord(receiptAcknowledgement.Id, salesOrder.Id, acc.Id, installmentLineList[1].Id);
        insert new List<ReceiptAllocation__c>{receiptAllocation_1,receiptAllocation_2};

        TriggerHandler.processedIds = new Set<Id>();
        receiptAcknowledgement.ChequeReceivedDate__c = system.today();
        update receiptAcknowledgement;

        Test.stopTest();

        Set<Id> installmentIdSet = new Set<Id>{installmentLineList[0].Id,installmentLineList[1].Id};
        //Assertions
        for(InstallmentLines__c installmentLine : [SELECT LPCFreezeDate__c,LPCFreezeUntilDate__c from InstallmentLines__c WHERE Id IN :installmentIdSet]){
//            Assert.areEqual(system.today(), installmentLine.LPCFreezeDate__c);
//            Assert.areEqual(system.today().addMonths(6), installmentLine.LPCFreezeUntilDate__c);
        } 
    }
        @isTest
        public static void TestReceiptAcknowledgementSRForChargeFee() {
            
            Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
            insert acc;
            
            Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
            con.Email = 'anayak@aldar.com';
            update con;
            
            Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
            insert opp;
            
            Unit__c unit = [select id from Unit__c Where Name = 'Test Unit' limit 1];
            unit.Status__c = 'Sold';
            update unit;
            
            SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
            salesOrder.Unit__c = unit.Id;
            salesOrder.Contact__c = con.Id;
            insert salesOrder;
            
            List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);
            
            SalesOrderOtherCharges__c salesOrderOtherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
            Test.startTest();
            
            HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);        
            insert SRTemplateDetailRecord;
            
            HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Internal Mortgage Registration', 'InternalMortgageRegistration');
            insert objStepTemplate;
            
            HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
            insert objSRSteps;
            
            HexaBPM__SR_Status__c closed = TestObjectsFactory.getSRStatus('Closed');       
            insert closed;
            
            HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
            insert approvedByFinance;
            
            HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus('Submitted');       
            insert submitted;
            
            Id mortgageRegistrationId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);
            
            HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
            newSR.ChargeCollected__c = 2000;
            insert newSR;
            
            ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
            srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
            srReceiptAcknowledgementRec.Receipt_Type__c = 'Charge Fee';
            srReceiptAcknowledgementRec.Status__c = 'Received';
            insert srReceiptAcknowledgementRec;
            
            TriggerHandler.processedIds = new Set<Id>();
            srReceiptAcknowledgementRec.Status__c = 'Cleared';
            update srReceiptAcknowledgementRec;
            
        }
    
       @IsTest
        static void testPopulateThirdPartyFlag() {
            Id thirdPartyRecordTypeId = Schema.SObjectType.Sales_Order_Relationship__c.getRecordTypeInfosByName().get('Third Party').getRecordTypeId();
            set<Id> soIds = new set<Id>();
            
            Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
            insert acc;
            
            Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
            insert acc1;
            
            Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
            con.Email = 'anayak@aldar.com';
            update con;
            
            Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
            insert opp;
            
            Unit__c unit = [select id from Unit__c Where Name = 'Test Unit' limit 1];
            
            Unit__c unit1 = TestObjectsFactory.unitDataSetup(opp.Id);        
            insert unit1;
            
            Unit__c unit2 = TestObjectsFactory.unitDataSetup(opp.Id);        
            insert unit2;
            
            SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
            salesOrder.Unit__c = unit.Id;
            salesOrder.Contact__c = con.Id;
            insert salesOrder;
        
            
            SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
            salesOrder1.Unit__c = unit1.Id;
            salesOrder1.Contact__c = con.Id;
            insert salesOrder1;
         
            
           /*SalesOrder__c salesOrder2 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
            salesOrder2.Unit__c = unit2.Id;
            salesOrder2.Contact__c = con.Id;
            insert salesOrder2;*/
            
            Sales_Order_Relationship__c sor1 = new Sales_Order_Relationship__c(
                SalesOrder__c = salesOrder.Id, 
                Account__c = acc.Id, 
                RecordTypeId = thirdPartyRecordTypeId
            );
            Sales_Order_Relationship__c sor2 = new Sales_Order_Relationship__c(
                SalesOrder__c = salesOrder1.Id, 
                Account__c = acc.Id, 
                RecordTypeId = thirdPartyRecordTypeId
            );
            /*Sales_Order_Relationship__c sor3 = new Sales_Order_Relationship__c(
                SalesOrder__c = salesOrder2.Id, 
                Account__c = acc.Id, 
                RecordTypeId = thirdPartyRecordTypeId
            );*/
            
            List<Sales_Order_Relationship__c> sorList = new List<Sales_Order_Relationship__c>{sor1, sor2};//, sor3}; 
                
             Test.startTest();
            List<ReceiptAcknowledgement__c> newList = new List<ReceiptAcknowledgement__c>();

            ReceiptAcknowledgement__c receipt = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Online');
            receipt.RecievedFromAccount__c = acc1.Id;
            newList.add(receipt);
            
            ReceiptAcknowledgement__c receipt_2 = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder1.Id, acc.Id, opp.Id, 'Online');
            receipt_2.RecievedFromAccount__c = acc1.Id;
            newList.add(receipt_2);
            
           /*ReceiptAcknowledgement__c receipt_3 = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder2.Id, acc.Id, opp.Id, 'Online');
            receipt_3.RecievedFromAccount__c = acc1.Id;
            newList.add(receipt_3);
            insert newList;*/
            
       //     ReceiptAcknowledgementTriggerHelper.populTateThirdPartyFlag(newList);
            Test.stopTest();
        }
    
   /* @isTest
    public static void testValidateInstrumentRecieved() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = [SELECT id FROM Unit__c LIMIT 1];
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        // Create Receipt Acknowledgement with ChequeReceived = false
        ReceiptAcknowledgement__c receiptAcknowledgement = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cheque');
        receiptAcknowledgement.Status__c = 'Received'; 
        receiptAcknowledgement.ChequeReceived__c = false;
        insert receiptAcknowledgement;
        
        // Create Old Map
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ receiptAcknowledgement.Id => receiptAcknowledgement };
        List<ReceiptAcknowledgement__c> newList = new List<ReceiptAcknowledgement__c>{receiptAcknowledgement};     
            for(ReceiptAcknowledgement__c ra : newList){
                oldMap.put(ra.Id, ra.clone(false,true));
            }
            
            try {
                receiptAcknowledgement.ChequeReceived__c = true;
                update receiptAcknowledgement;
                ReceiptAcknowledgementTriggerHelper.validateInstrumentRecieved(newList,oldMap);
            } catch (DmlException e) {
                System.assert(e.getMessage().contains('Cannot mark cheque as received'), 'Unexpected error message: ' + e.getMessage());
            }
        
        Test.stopTest();
    }*/
    
    @isTest
    public static void testVerifyAndReserveSO() {
        Test.startTest();
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        acc.Email__c = 'tdevar@aldar.com';
        update acc;
        
        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org1', 'G123457');
        insert acc1;
        acc1.Email__c = 'tdevar@aldar.com';
        update acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = [SELECT id,DigitalSales__c FROM Unit__c Where Name = 'Test Unit' LIMIT 1];
        unit.DigitalSales__c = true;
        update unit;
       
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        SalesOrder__c salesOrder3 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder3.Unit__c = unit.Id;
        salesOrder3.Status__c = Constants.STATUS_RESERVATION_IN_PROGRESS;
        salesOrder3.Is_Digital_Sales__c = true;
        salesOrder3.Contact__c = con.Id;
        salesOrder3.Email__c = con.Email;
        salesOrder3.ComplianceStatus__c = 'Under Review';
        insert salesOrder3;
        
        Communication_Preference__c cp = new Communication_Preference__c(Account__c = acc.Id,Active__c = true, Sales_Order__c = salesOrder3.Id, Unit__c =unit.Id );
        insert cp;
        cp.Category__c = 'Booking';
        update cp;
        
        Project__c proj = [Select Id,ReservationAmount__c From Project__c Limit 1];
        proj.ReservationAmount__c = 3600;
        update proj;
        
        Id rtId = Schema.SObjectType.Sales_Order_Relationship__c.getRecordTypeInfosByDeveloperName().get('Third_Party').getRecordTypeId();
                
        ReceiptAcknowledgement__c receipt01 = new ReceiptAcknowledgement__c(SalesOrder__c = salesOrder3.Id, PaymentType__c = Constants.ONLINE,Status__c = Constants.RECEIVED_PAYMENT_STATUS,ChequeReceived__c = false,OnlinePaymentCleared__c = false, Amount__c = 1500,RecievedFromAccount__c = acc.Id);
        ReceiptAcknowledgement__c receipt02 = new ReceiptAcknowledgement__c(SalesOrder__c = salesOrder3.Id, PaymentType__c = Constants.ONLINE,Status__c = Constants.RECEIVED_PAYMENT_STATUS,ChequeReceived__c = false,OnlinePaymentCleared__c = false, Amount__c = 1200,RecievedFromAccount__c = acc.Id);
        ReceiptAcknowledgement__c receipt03 = new ReceiptAcknowledgement__c(SalesOrder__c = salesOrder3.Id, PaymentType__c = Constants.ONLINE,Status__c = Constants.RECEIVED_PAYMENT_STATUS,ChequeReceived__c = false,OnlinePaymentCleared__c = false, Amount__c = 1200,RecievedFromAccount__c = acc.Id);
        ReceiptAcknowledgement__c receipt04 = new ReceiptAcknowledgement__c(SalesOrder__c = salesOrder3.Id, PaymentType__c = Constants.ONLINE,ChequeReceived__c = false,OnlinePaymentCleared__c = false,Amount__c = 5000,RecievedFromAccount__c = acc.Id,Is_Third_party_payment__c = true);
        ReceiptAcknowledgement__c receipt05 = new ReceiptAcknowledgement__c(SalesOrder__c = salesOrder3.Id, PaymentType__c = Constants.ONLINE,ChequeReceived__c = false,OnlinePaymentCleared__c = false,Status__c = 'Link Sent',Amount__c = 6000,RecievedFromAccount__c = acc1.Id);
        
        insert new List<ReceiptAcknowledgement__c>{ receipt01, receipt02, receipt03,receipt04,receipt05};
            
        List<ReceiptAcknowledgement__c> newList = new List<ReceiptAcknowledgement__c>{receipt01, receipt02, receipt03,receipt04};
        Map<Id,SObject> oldMap = new Map<Id,SObject>();
            
            for(ReceiptAcknowledgement__c ra : newList){
                oldMap.put(ra.Id, ra.clone(false, true, false, false));
        }        
        
        receipt01.OnlinePaymentCleared__c = true;
        receipt02.OnlinePaymentCleared__c = true;
        receipt03.OnlinePaymentCleared__c = true;
        receipt04.OnlinePaymentCleared__c = true;
        receipt04.ChequeReceived__c = true;
        receipt04.RecievedFromAccount__c = acc1.Id;
        receipt04.Amount__c = 1000;
        receipt04.Status__c = 'Received';
       
      
        update  new List<ReceiptAcknowledgement__c>{receipt01,receipt02,receipt03,receipt04};
            
        /*Sales_Order_Relationship__c so = new Sales_Order_Relationship__c(SalesOrder__c =salesOrder3.Id , Account__c = acc1.Id,RecordTypeId = rtId);
        insert so;*/
        
        /*receipt4.Sales_Order_Relationship__c = so.Id;
        update receipt4;*/
        
       /* JointOwner__c jo = new JointOwner__c(SalesOrder__c = salesOrder3.Id , Account__c = acc.Id);
        insert jo;*/
        
        /*JointOwner__c jo1 = new JointOwner__c(SalesOrder__c = salesOrder3.Id , Account__c = acc1.Id);
        insert jo1;*/
            
        ReceiptAcknowledgementTriggerHelper.validateInstrumentRecieved(newList,oldMap);
      
        Set<Id> soIDs = new Set<Id>{salesOrder3.Id};
        ReceiptAcknowledgementTriggerHelper.verifyAndReserveSO(soIDs);
        
        /*List<SalesOrder__c> updatedSalesOrders = [SELECT Id, Status__c FROM SalesOrder__c WHERE Id IN :soIDs];
        
        /*Map<Id, SObject> dummyMap = new Map<Id, SObject>();
        for (ReceiptAcknowledgement__c ra : [SELECT Id FROM ReceiptAcknowledgement__c WHERE SalesOrder__c = : salesOrder3.Id]) {
            dummyMap.put(ra.Id, ra.clone(false, true, false, false));
        }
        ReceiptAcknowledgementTriggerHelper.updateJointOwnerTotals([SELECT Id, SalesOrder__c, RecievedFromAccount__c, Amount__c, Status__c FROM ReceiptAcknowledgement__c WHERE SalesOrder__c = :salesOrder3.Id],dummyMap);
        */ 
        
        Test.stopTest();
    }
    
    @isTest
    public static void updateSalesOrderRelationshipTotalsTest(){
        Test.StartTest();
    
        Id rtId = Schema.SObjectType.Sales_Order_Relationship__c.getRecordTypeInfosByDeveloperName().get('Third_Party').getRecordTypeId();
        
        /*Account acc = TestObjectsFactory.getPersonAccountRecord(123456798,'Indian','Visa Not Applicable','ABCDRE5354');
        insert acc;
        acc.Email__c = 'tdevar@aldar.com';
        acc.Trigger_screening_Case__c = true;
        update acc;
        
        Account acc1 = TestObjectsFactory.getPersonAccountRecord(123456798,'Indian','Visa Not Applicable','ABCDRE5354');
        insert acc1;
        acc.Email__c = 'tdevar@aldar.com';
        acc.Trigger_screening_Case__c = true;
        update acc;*/
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        acc.Email__c = 'tdevar@aldar.com';
        update acc;
        
        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org1', 'G123457');
        insert acc1;
        acc1.Email__c = 'tdevar@aldar.com';
        update acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = [SELECT id,DigitalSales__c FROM Unit__c Where Name = 'Test Unit' LIMIT 1];
        unit.DigitalSales__c = true;
        update unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Status__c = Constants.STATUS_RESERVATION_IN_PROGRESS;
        salesOrder.Is_Digital_Sales__c = true;
        salesOrder.Email__c = 'tdevar@aldar.com';
        salesOrder.ComplianceStatus__c = 'Under Review';
        insert salesOrder;
        
        Communication_Preference__c cp = new Communication_Preference__c(Account__c = acc.Id,Active__c = true, Sales_Order__c = salesOrder.Id, Unit__c =unit.Id );
        insert cp;
        cp.Category__c = 'Booking';
        update cp;
          
        ReceiptAcknowledgement__c rec1 = new ReceiptAcknowledgement__c(SalesOrder__c = salesOrder.Id, PaymentType__c = Constants.ONLINE,Status__c = Constants.RECEIVED_PAYMENT_STATUS,ChequeReceived__c = false,OnlinePaymentCleared__c = false, Amount__c = 1500,RecievedFromAccount__c = acc.Id);
        ReceiptAcknowledgement__c rec2 = new ReceiptAcknowledgement__c(SalesOrder__c = salesOrder.Id, PaymentType__c = Constants.ONLINE,Status__c = Constants.RECEIVED_PAYMENT_STATUS,ChequeReceived__c = false,OnlinePaymentCleared__c = false, Amount__c = 1200,RecievedFromAccount__c = acc.Id);
        ReceiptAcknowledgement__c rec3 = new ReceiptAcknowledgement__c(SalesOrder__c = salesOrder.Id, PaymentType__c = Constants.ONLINE,Status__c = Constants.RECEIVED_PAYMENT_STATUS,ChequeReceived__c = false,OnlinePaymentCleared__c = false, Amount__c = 1200,RecievedFromAccount__c = acc.Id);
        ReceiptAcknowledgement__c rec4 = new ReceiptAcknowledgement__c(SalesOrder__c = salesOrder.Id, PaymentType__c = Constants.ONLINE,ChequeReceived__c = false,OnlinePaymentCleared__c = false,Amount__c = 5000,RecievedFromAccount__c = acc.Id,Is_Third_party_payment__c = true);
        ReceiptAcknowledgement__c rec5 = new ReceiptAcknowledgement__c(SalesOrder__c = salesOrder.Id, PaymentType__c = Constants.ONLINE,ChequeReceived__c = false,OnlinePaymentCleared__c = false,Status__c = 'Link Sent',Amount__c = 6000,RecievedFromAccount__c = acc1.Id);
        
        insert new List<ReceiptAcknowledgement__c>{rec1, rec2, rec3,rec4,rec5}; 
            
        rec1.OnlinePaymentCleared__c = true;
        rec2.OnlinePaymentCleared__c = true;
        rec3.OnlinePaymentCleared__c = true;
        rec4.OnlinePaymentCleared__c = true;
        rec4.ChequeReceived__c = true;
        rec4.RecievedFromAccount__c = acc1.Id;
        rec4.Amount__c = 1000;
        rec4.Status__c = 'Received';
        
        update new List<ReceiptAcknowledgement__c>{rec1,rec2,rec3,rec4};
            
        Sales_Order_Relationship__c so = new Sales_Order_Relationship__c(SalesOrder__c =salesOrder.Id , Account__c = acc1.Id,RecordTypeId = rtId);
        insert so;
        
        rec4.Sales_Order_Relationship__c = so.Id;
        update rec4;
        
        /*JointOwner__c jo = new JointOwner__c(SalesOrder__c = salesOrder.Id , Account__c = acc.Id);
        insert jo;
        
        JointOwner__c jo1 = new JointOwner__c(SalesOrder__c = salesOrder.Id , Account__c = acc1.Id);
        insert jo1;*/

            
        List<ReceiptAcknowledgement__c> newList = new List<ReceiptAcknowledgement__c>{rec1, rec2, rec3,rec4};
        Map<Id,SObject> oldMap = new Map<Id,SObject>();
        
        for(ReceiptAcknowledgement__c ra : newList){
            ra.Amount__c = 10000;
            oldMap.put(ra.Id, ra.clone(false, true, false, false));
        }
        ReceiptAcknowledgementTriggerHelper.updateSalesOrderRelationshipTotals(newList,oldMap);
        ReceiptAcknowledgementTriggerHelper.updateJointOwnerTotals(newList, oldMap);
        Test.StopTest();
    }
    
    @isTest
    public static void testUpdateCaseMethod() {
        Account orgAcc = TestObjectsFactory.getAccountRecord('Organization Account',false,'JO20220211');
        orgAcc.recordTypeID=Constants.BROKER_AGENCY_RECORD_TYPE_ID ;
        insert orgAcc;
        
        Contact conRecord = TestObjectsFactory.contactDataSetup(orgAcc.Id);

        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];

        Case caseRec = new Case();
        caseRec.AccountId = orgAcc.Id;
        caseRec.ContactId = conRecord.Id;
        caseRec.Unit__c = unit.Id;
        caseRec.CustomerType__c = 'Owner';
        caseRec.Origin = 'Web';
        caseRec.Status = 'New';
        caseRec.Priority = 'Medium';
        insert caseRec;

        Test.startTest();
        ReceiptAcknowledgementTriggerHandler.updateCase(new Set<Id>{caseRec.Id});
        Test.stopTest();
    }
}