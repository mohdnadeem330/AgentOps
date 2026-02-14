@isTest
public class ServiceRequestTriggerHandlerTest {
    @testSetup static void testData(){
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus(Constants.Compliance_Rejected);       
        insert Submitted; 
        
        HexaBPM__SR_Status__c Submitted1 = TestObjectsFactory.getSRStatus(Constants.Compliance_Cleared);       
        insert Submitted1; 
        
        HexaBPM__SR_Status__c Submitted2 = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted2; 
        
        HexaBPM__Status__c status1 = new HexaBPM__Status__c();
        status1.Name =Constants.Cleared;
        status1.HexaBPM__Code__c =Constants.Cleared;
        // status1.HexaBPM__DEV_Id__c ='567890';
        insert status1;
        
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.PROPERTY_TRANSFER_DEV_RT, 'PropertyTransfer');
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
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('PropertyTransfer');     
        SRTemplateDetailRecord3.Name = Constants.PROPERTY_TRANSFER_RT;
        insert SRTemplateDetailRecord3;
        
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord3.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__SR_Status__c Closed = TestObjectsFactory.getSRStatus('Closed');       
        insert Closed;
        
        HexaBPM__Service_Request__c newSR2 = TestObjectsFactory.getServiceRequest(Closed.Id, unit.Id, 'SPA Registration', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'SPA Registration For Off Plan'), SRTemplateDetailRecord3.Id);
        newSR2.SalesOrder__c = salesOrder.Id;        
        newSR2.Unit__c = unit.Id;  
        newSR2.IsComplianceReturned__c =false;
        newSR2.Compliance_Status__c = 'Cleared';
        newSR2.TransferSellingPrice__c= 1000000;
        newSR2.HexaBPM__Email__c = 'test@test.com';
        newSR2.SRType__c ='';
        //newSR.WaivedAmount__c = 2;
        //newSR.ReallocationAmount__c = 100;        
        insert newSR2;
        
        HexaBPM__Service_Request__c newSR1 = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, 'Property Transfer', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer'), SRTemplateDetailRecord3.Id);
        newSR1.SalesOrder__c = salesOrder.Id;        
        newSR1.Unit__c = unit.Id;  
        newSR1.IsComplianceReturned__c =false;
        newSR1.Compliance_Status__c = 'Cleared';
        newSR1.TransferSellingPrice__c= 1000000;
        newSR1.HexaBPM__Email__c = 'test@test.com';
        //newSR.WaivedAmount__c = 2;
        //newSR.ReallocationAmount__c = 100;
        newSR1.SRType__c = '';        
        insert newSR1;
        system.debug('@@@newSR1-Insert'+newSR1);
        newSR1.Compliance_Status__c = 'Cleared';
        newSR1.IsComplianceReturned__c = true;        
        update newSR1;
        system.debug('@@@newSR1-Update'+newSR1);
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR1.id, objSRSteps.Id, objStepTemplate.id);     
        newStep.HexaBPM__Summary__c = 'Compliance Check for Buyers';
        insert newStep;
        System.debug('@@@newStep'+newStep);
        
        
        /* List<InstallmentLines__c> installmentLines1 = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 1);
installmentLines1[0].InvoicedAmount__c = 30;
update installmentLines1;

HexaBPM__SR_Template__c SRTemplateDetailRecord4 = TestObjectsFactory.getSRTemplate('LPCWaiver');     
SRTemplateDetailRecord4.Name = 'LPC Waiver';
insert SRTemplateDetailRecord4;

HexaBPM__Service_Request__c newSR2 = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, 'LPC Waiver', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'LPC Waiver'), SRTemplateDetailRecord4.Id);
newSR2.SalesOrder__c = salesOrder.Id;        
newSR2.Unit__c = unit.Id;  
newSR2.IsComplianceReturned__c = false;
newSR2.Compliance_Status__c = '';
newSR2.TransferSellingPrice__c= 1000000;

insert newSR2;*/
        
        /* HexaBPM__SR_Template__c SRTemplateDetailRecord5 = TestObjectsFactory.getSRTemplate('PaymentExtension');     
SRTemplateDetailRecord5.Name = 'Payment Extension and Cheque Replacement';
insert SRTemplateDetailRecord5;
HexaBPM__Service_Request__c newSR3 = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id,  'Payment Extension', Utilities.getRecordTypeId('HexaBPM__Service_Request__c','Payment Extension and Cheque Replacement'), SRTemplateDetailRecord5.Id);
newSR3.SalesOrder__c = salesOrder.Id;        
newSR3.Unit__c = unit.Id;  
newSR3.IsComplianceReturned__c = false;
newSR3.Compliance_Status__c = '';
newSR3.TransferSellingPrice__c= 1000000;
newSR3.InstallmentLine__c =installmentLines1[0].Id;
newSR3.PaymentExtensionDate__c =system.Today();
insert newSR3;*/              
        
        
        
    }
    @isTest
    public static void testShareServiceRequestBrokerManager() {
        Test.startTest();
        
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'AgencyRegistration']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Broker Manager']; 
        UserRole r = [Select Id, name From UserRole Where Name LIKE '%Broker Relations Manager%' limit 1];
        
        User userRecord1 = TestObjectsFactory.getUserRecord('System Administrator', 'userName');
        
        User u;
        System.runAs(userRecord1) {
            
            u = new User(Alias = 'standt', Email='sampleemail@aldar.com', 
                         EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                         LocaleSidKey='en_US', ProfileId = p.Id, 
                         TimeZoneSidKey='Asia/Dubai', UserName='testbrokercreation@aldar.com', UserRoleId=r.Id);
            
            insert u;
        }
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        // insert Submitted;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('AgencyRegistration');
        insert SR;
        
        TriggerHandler.processedIds = new Set<Id>();
        
        SR.BrokerManager__c = u.Id;
        try{
            update SR;
        } catch (Exception ex) {
            System.debug(ex);
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void testLPCWaiver() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@gmail.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25084');
        unit1.Status__c = 'Sold';
        unit1.Name = 'MAYAN-B1-1004';
        insert unit1;
        
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('25085');
        unit2.Status__c = 'Sold';
        unit2.Name = 'MAYAN-B1-1005';
        insert unit2;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.MortgageApplicable__c = 'Yes';
        salesOrder.Contact__c = con.Id;
        //insert salesOrder;
        
        Test.startTest();
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit1.Id;
        salesOrder1.MortgageApplicable__c = 'Yes';
        salesOrder1.Contact__c = con.Id;
        insert salesOrder1;
        
        SalesOrder__c salesOrder2 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder2.Unit__c = unit2.Id;
        salesOrder2.MortgageApplicable__c = 'Yes';
        salesOrder2.Contact__c = con.Id;
        insert salesOrder2;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.INTERNAL_MORTGAGE_DISCHARGE_RT);        
        insert SRTemplateDetailRecord;
        HexaBPM__SR_Template__c SRTemplateDetailRecord1 = TestObjectsFactory.getSRTemplate(Constants.PROPERTY_TRANSFER_DEV_RT);        
        insert SRTemplateDetailRecord1;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.LPC_WAIVER_RT, 'LPCWaiver');
        insert objStepTemplate;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        //insert draft;
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        // insert Submitted;
        
        Id mortgageDischargeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.LPC_WAIVER_RT);
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.LPC_WAIVER_TYPE, mortgageDischargeId, SRTemplateDetailRecord.Id);
        newSR.SalesOrder__c = salesOrder.Id;        
        newSR.Unit__c = unit.Id;  
        newSR.WaivedAmount__c = 2;
        newSR.ReallocationAmount__c = 100;        
        insert newSR;
        
        
        
        TriggerHandler.processedIds = new Set<Id>();      
        
        
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);     
        insert newStep;
        
        HexaBPM__Service_Request__c lpcSR = [Select id,HexaBPM__External_Status_Name__c, HexaBPM__External_SR_Status__r.Name from  HexaBPM__Service_Request__c where Id =: newSR.Id];
        System.debug('service request '+lpcSR);
        System.debug('service request '+newSR.HexaBPM__External_SR_Status__r.Name);
        System.debug('service request '+Submitted);
        
        //Test.startTest();
        /*lpcSR.Id = lpcSR.Id;
lpcSR.HexaBPM__External_SR_Status__c =  Submitted.Id;
lpcSR.HexaBPM__Internal_SR_Status__c =  Submitted.Id;
newSR.WaivedPercentage__c = 4;
TriggerHandler.processedIds = new Set<Id>();
update lpcSR;*/
        
        HexaBPM__Service_Request__c lpcSR1 = [Select id,HexaBPM__External_Status_Name__c, HexaBPM__External_SR_Status__r.Name from  HexaBPM__Service_Request__c where Id =: lpcSR.Id];
        System.debug('service request '+lpcSR1.HexaBPM__External_Status_Name__c);
        System.debug('service request '+lpcSR1.HexaBPM__External_SR_Status__r.Name);
        System.debug('service request '+lpcSR1);
        
        TriggerHandler.processedIds = new Set<Id>();
        newSR.Unit__c = unit2.Id;
        newSR.SalesOrder__c = salesOrder2.Id;
        newSR.TermCommencementDate__c = Date.today();
        newSR.BuyerName__c = acc.Id;
        newSR.WaivedAmount__c = 4;
        newSR.WaivedBy__c = 'Amount';
        newSR.HexaBPM__External_SR_Status__c =  Submitted.Id;
        newSR.HexaBPM__Internal_SR_Status__c =  Submitted.Id;
        newSR.TotalLPCDue__c = 24;
        try{
            update newSR;
        } catch (Exception ex) {
            System.debug('Ex::'+ex);
        }
        
        Test.StopTest();
    }
    
    @isTest
    public static void testPaymentExtentionPT() {
        Test.startTest(); 
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        List<HexaBPM__SR_Template__c> srTemplateDetailList=new List<HexaBPM__SR_Template__c>();
        HexaBPM__SR_Template__c SRTemplateDetailRecord1 = TestObjectsFactory.getSRTemplate('PaymentExtension');
        SRTemplateDetailRecord1.Name = 'Payment Extension';
        // insert SRTemplateDetailRecord1;
        srTemplateDetailList.add(SRTemplateDetailRecord1);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord2 = TestObjectsFactory.getSRTemplate('TitleDeedRegistration');
        SRTemplateDetailRecord2.Name = 'Title Deed Registration';
        
        // insert SRTemplateDetailRecord2;
        srTemplateDetailList.add(SRTemplateDetailRecord2);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('PropertyTransfer');     
        SRTemplateDetailRecord3.Name = Constants.PROPERTY_TRANSFER_RT;        
        //insert SRTemplateDetailRecord3;
        srTemplateDetailList.add(SRTemplateDetailRecord3);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord4 = TestObjectsFactory.getSRTemplate('GoldenVisa');     
        SRTemplateDetailRecord4.Name = 'Golden Visa';
        //insert SRTemplateDetailRecord4;
        srTemplateDetailList.add(SRTemplateDetailRecord4);
        insert srTemplateDetailList;
        
        List<ChargeRule__c> chargeList=new List<ChargeRule__c>();
        ChargeRule__c chargeAmount = TestObjectsFactory.getChargeRuleRecord('Property Transfer', 'Transfer Normal');       
        chargeAmount.ChargeAmount__c = null;
        chargeAmount.ChargePercentage__c = 5;
        //chargeList.add(cr);
        chargeList.add(chargeAmount);
        
        ChargeRule__c chargePercentage = TestObjectsFactory.getChargeRuleRecord('Property Transfer', 'Transfer Normal');       
        chargePercentage.ChargeAmount__c = null;
        chargePercentage.ChargePercentage__c = 5;
        //insert chargePercentage;
        chargeList.add(chargePercentage);
        
        ChargeRule__c cr = TestObjectsFactory.getChargeRuleRecord('Property Transfer', 'Transfer Normal');       
        cr.ChargeAmount__c = null;
        cr.ChargePercentage__c = 5;
        chargeList.add(cr);
        
        ChargeRule__c cr1 = TestObjectsFactory.getChargeRuleRecord('Payment Extension', Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE);       
        cr1.ChargePercentage__c = 5;
        cr1.VATChanges__c = 5;
        cr1.ChargeAmount__c = null;
        //insert cr1;
        chargeList.add(cr1);
        insert chargeList; 
        
        List<HexaBPM__Service_Request__c> srInsertList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> srUpdateList = new List<HexaBPM__Service_Request__c>();
        
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;
        
        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        insert buildingSection;
        
        List<Unit__c> unitList=new List<Unit__c>();
        Unit__c u = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        u.Status__c = 'Sold';
        // insert u;
        unitList.add(u);
        
        Unit__c u1 = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        u1.Name = project.Id +'MAYAN-B1-1002';
        // insert u1;
        unitList.add(u1);
        insert unitList; 
        
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert newAccount;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        
        List<SalesOrder__c> salesOrderList=new List<SalesOrder__c>();
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = u.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        //  insert salesOrder;
        salesOrderList.add(salesOrder);
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder1.Unit__c = u.Id;
        salesOrder1.IsBookingCompleted__c = true;
        salesOrder1.NetAmount__c = 100000;
        salesOrder1.Status__c = 'Sold';
        salesOrder1.SellingPrice__c=1000000;
        //insert salesOrder1;
        salesOrderList.add(salesOrder1);
        insert salesOrderList;
        
        List<InstallmentLines__c> installmentLines1 = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 1);
        installmentLines1[0].InvoicedAmount__c = 30;
        update installmentLines1;
        
        List<InstallmentLines__c> installmentLines = [select id,SalesOrder__c from InstallmentLines__c where SalesOrder__c =: salesOrder.Id];
        
        InstallmentLines__c installmentRec = new InstallmentLines__c();
        if(installmentLines.size() > 0){
            installmentRec = installmentLines[0];
            installmentRec.InstallmentDate__c = Date.Today().addDays(50);
            update installmentRec;
        }
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        //insert objSRStatus;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.PAYMENT_EXTENSION_RT, Constants.PAYMENT_EXTENSION_RT);
        insert objStepTemplate;
        
        HexaBPM__Step_Template__c objStepTemplate1 = TestObjectsFactory.getStepTemplate(Constants.PROPERTY_TRANSFER_RT, Constants.PROPERTY_TRANSFER_RT);
        insert objStepTemplate1;
        
        HexaBPM__Service_Request__c paymentExtention = new HexaBPM__Service_Request__c();
        paymentExtention.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PAYMENT_EXTENSION_RT);
        paymentExtention.InstallmentLine__c = installmentRec.Id;
        //paymentExtention.SRType__c = Constants.PAYMENT_EXTENSION_TYPE;
        paymentExtention.SRType__c = '';
        paymentExtention.PaymentExtensionDate__c = Date.Today().addDays(10);
        paymentExtention.Unit__c = u.Id;
        paymentExtention.HexaBPM__Email__c = 'test@test.com';
        
        HexaBPM__Service_Request__c propertyTransfer = new HexaBPM__Service_Request__c();
        propertyTransfer.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
        //propertyTransfer.SRType__c = Constants.PROPERTY_TRANSFER_TYPE;
        propertyTransfer.SRType__c ='';
        propertyTransfer.ChargeType__c = '';
        propertyTransfer.Unit__c = u.Id;
        propertyTransfer.SwappedUnit__c = u1.Id;
        propertyTransfer.InstallmentLine__c = installmentRec.Id;
        propertyTransfer.TransferSellingPrice__c=1000000;
        propertyTransfer.HexaBPM__Email__c = 'test@test.com';
        Map<HexaBPM__Service_Request__c, Id> SRwithSOmap = new Map<HexaBPM__Service_Request__c, Id>();
        SRwithSOmap.put(propertyTransfer, salesOrder.id);
        
        
        HexaBPM__Service_Request__c titleDeed = new HexaBPM__Service_Request__c();
        titleDeed.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.TITLE_DEED_REGISTRATION_RT);
        titleDeed.SRType__c ='';
        //titleDeed.SRType__c = Constants.TITLE_DEED_REGISTRATION_RT;
        titleDeed.Unit__c = salesOrder.Unit__c;
        titleDeed.Unit__c = u.Id;
        titleDeed.HexaBPM__Email__c = 'test@test.com';
        Account newAcc = TestObjectsFactory.getPersonAccountRecord();
        insert newAcc;
        
        HexaBPM__Service_Request__c golden = new HexaBPM__Service_Request__c();
        golden.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.Golden_Visa_RT);
        //golden.SRType__c = Constants.Golden_Visa_RT;
        golden.SRType__c ='';
        golden.HexaBPM__Customer__c = newAcc.id;
        golden.HexaBPM__Email__c = 'test@test.com';
        //golden.Unit__c = u.Id;
        //insert golden;
        List<SObject> newlist = new List<SObject>();
        newlist.add(golden);
        
        HexaBPM__Service_Request__c cancellationSR = new HexaBPM__Service_Request__c();
        cancellationSR.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.CANCELLATION_RT);
        cancellationSR.SRType__c ='';
        //cancellationSR.SRType__c = 'Constants.CANCELLATION_INTEGRATION';
        cancellationSR.SalesOrder__c = salesOrder.Id;
        cancellationSR.Unit__c = salesOrder.Unit__c;
        cancellationSR.CancellationReason__c = 'Mutual Cancellation - Refund';
        cancellationSR.SocialReason__c = 'Delay in Handover';
        cancellationSR.TotalCollectedAmount__c = 186258.00;
        cancellationSR.AgreementType__c = 'T3 - Conditional Cancellation Agreement (Mortgage or Extension of Time)';
        cancellationSR.ReallocationAmount__c = 0.00;
        cancellationSR.PriceRevisionRequired__c = false;
        cancellationSR.ForfeitAmount__c = 0.00;
        cancellationSR.CancellationOption__c = 'Option 1';
        cancellationSR.HexaBPM__Email__c = 'test@test.com';
        srInsertList.add(paymentExtention);
        srInsertList.add(propertyTransfer);
        //srInsertList.add(titleDeed);
        //srInsertList.add(golden);
        srInsertList.add(cancellationSR);
        
        TriggerHandler.processedIds = new Set<Id>();
        
        
        insert srInsertList;
        
        
        propertyTransfer.BankAccountNumber__c = '21321';
        paymentExtention.PaymentExtensionDate__c = Date.Today().addDays(100);
        srUpdateList.add(propertyTransfer);
        srUpdateList.add(paymentExtention);
        
        TriggerHandler.processedIds = new Set<Id>();
        try{
            update srUpdateList;
        } catch (Exception ex) {
            System.debug(ex);
        }
        Test.StopTest();
        
        ServiceRequestTriggerHandler serviceRequest = new ServiceRequestTriggerHandler();
        //ServiceRequestTriggerHandler obj = new ServiceRequestTriggerHandler();
        //obj.beforeInsertMethod(newlist, new Map<Id, SObject>());
        ServiceRequestTriggerHandler.updateSalesOrderAndCustomer(new List<HexaBPM__Service_Request__c>{propertyTransfer});
        serviceRequest.afterInsertMethod(new List<SObject>(), new Map<Id, SObject>());
        ServiceRequestTriggerHandler.submittedLPC(SRwithSOmap);
        ServiceRequestTriggerHandler.updateRTORent(new List<Id>{salesOrder.Id}, new List<HexaBPM__Service_Request__c>{paymentExtention});
        ServiceRequestTriggerHandler.blockTheSwappedUnit(srUpdateList, new Map<Id, SObject>());
        
    }
    
    @isTest
    public static void testPaymentPlanChange() {
        Test.startTest();
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;
        
        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'ajay.thakur.tpr@gmail.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.MortgageApplicable__c = 'Yes';
        salesOrder.Contact__c = con.Id;
        salesOrder.NetAmount__c = 100;
        salesOrder.NumberOfDefaults__c = 1;
        insert salesOrder;
        
        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 1);
        installmentLines[0].InvoicedAmount__c = 30;
        update installmentLines;
        
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        //insert objSRStatus;
        Test.stopTest();
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.PAYMENT_PLAN_CHANGE_RT, 'PaymentPlanChange');
        
        insert objStepTemplate;
        
        HexaBPM__Service_Request__c paymentPlanChange = new HexaBPM__Service_Request__c();
        paymentPlanChange.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PAYMENT_PLAN_CHANGE_RT);
        paymentPlanChange.SRType__c = Constants.PAYMENT_PLAN_CHANGE_TYPE;
        paymentPlanChange.PaidEquity__c=100;
        paymentPlanChange.SalesOrder__c = salesOrder.Id;
        paymentPlanChange.Unit__c = unit.Id;
        insert paymentPlanChange;
        
        ServiceRequestTriggerHandler.checkSRAutomation(new List<HexaBPM__Service_Request__c>{paymentPlanChange}, null);
        
    }
    
    
    @isTest
    public static void testAgencyRegistrationSR()
    {
        Test.startTest();
        HexaBPM__Service_Request__c serviceRequestRecord = new HexaBPM__Service_Request__c();
        
        serviceRequestRecord.AccountName__c = 'agencyName';
        serviceRequestRecord.TradeCommercialLicenseNumber__c = 'licenseNumber';
        serviceRequestRecord.Address1__c = 'addressLine1';
        serviceRequestRecord.Address2__c = 'addressLine2';
        serviceRequestRecord.City__c = 'this.city';
        serviceRequestRecord.State__c = 'this.state';
        serviceRequestRecord.POBox__c = 'this.poBox';
        serviceRequestRecord.Country__c = 'Jordan';
        serviceRequestRecord.EstablishmentDate__c =  date.today();
        serviceRequestRecord.ExpiryDate__c = date.today().addYears(5);
        serviceRequestRecord.PhoneNumber__c = 'phoneNumber';
        serviceRequestRecord.CompanyEmail__c = 'this.companyEmail@test.com';
        serviceRequestRecord.Website__c = 'this.website';
        serviceRequestRecord.TaxRegistrationNumber__c = 'this.taxRegistrationCertificate';
        
        serviceRequestRecord.POATitle__c = 'Mr';
        serviceRequestRecord.NameOfPOA__c = 'Nikil';
        
        serviceRequestRecord.ReferredBy__c = 'Faiza Kanwal' ;
        serviceRequestRecord.ReferredByTitle__c = 'Mr';
        serviceRequestRecord.Title__c = 'Mr';
        serviceRequestRecord.Designation__c = 'CCO';
        serviceRequestRecord.SignatoryName__c = 'Mahmood';
        serviceRequestRecord.SignatoryEmail__c = 'test@gmail.com';
        
        HexaBPM__Service_Request__c sr = BrokerAgencyRegistrationController.createServiceRequestRecord(serviceRequestRecord);
        Test.stopTest();
    }
    @isTest static void aldarStaffalidationTest(){
        Test.startTest();
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        acc.CustomerType__c =Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF;
        insert acc;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord1 = TestObjectsFactory.getSRTemplate('PaymentExtension');
        SRTemplateDetailRecord1.Name = 'Payment Extension';
        insert SRTemplateDetailRecord1;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord2 = TestObjectsFactory.getSRTemplate('TitleDeedRegistration');
        SRTemplateDetailRecord2.Name = 'Title Deed Registration';
        insert SRTemplateDetailRecord2;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('PropertyTransfer');     
        SRTemplateDetailRecord3.Name = Constants.PROPERTY_TRANSFER_RT;
        insert SRTemplateDetailRecord3;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord4 = TestObjectsFactory.getSRTemplate('GoldenVisa');     
        SRTemplateDetailRecord4.Name = 'Golden Visa';
        insert SRTemplateDetailRecord4;
        
        ChargeRule__c chargeAmount = TestObjectsFactory.getChargeRuleRecord('Property Transfer', 'Transfer Normal');       
        chargeAmount.ChargeAmount__c = null;
        chargeAmount.ChargePercentage__c = 5;
        insert chargeAmount;
        
        ChargeRule__c chargePercentage = TestObjectsFactory.getChargeRuleRecord('Property Transfer', 'Transfer Normal');       
        chargePercentage.ChargeAmount__c = null;
        chargePercentage.ChargePercentage__c = 5;
        insert chargePercentage;
        
        ChargeRule__c cr = TestObjectsFactory.getChargeRuleRecord('Property Transfer', 'Transfer Normal');       
        cr.ChargeAmount__c = null;
        cr.ChargePercentage__c = 5;
        insert cr;
        
       /* List<HexaBPM__Service_Request__c> srInsertList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> srUpdateList = new List<HexaBPM__Service_Request__c>();*/
        
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;
        
        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        buildingSection.AldarStaffTransferThresholdLimit__c = 40;
        insert buildingSection;
        
        Unit__c u = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        u.Status__c = 'Sold';
        u.BuildingSectionName__c = buildingSection.id;
        insert u;
        
        Unit__c u1 = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        u1.Name = project.Id +'MAYAN-B1-1002';
        insert u1;
        
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert newAccount;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = u.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.SellingPrice__c=1000000;
        insert salesOrder;
        
        SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder1.Unit__c = u.Id;
        salesOrder1.IsBookingCompleted__c = true;
        salesOrder1.NetAmount__c = 100000;
        salesOrder1.Status__c = 'Sold';
        insert salesOrder1;
        
        List<InstallmentLines__c> installmentLines1 = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 1);
        installmentLines1[0].InvoicedAmount__c = 30;
        update installmentLines1;
        
        List<InstallmentLines__c> installmentLines = [select id,SalesOrder__c from InstallmentLines__c where SalesOrder__c =: salesOrder.Id];
        
        InstallmentLines__c installmentRec = new InstallmentLines__c();
        if(installmentLines.size() > 0){
            installmentRec = installmentLines[0];
            installmentRec.InstallmentDate__c = Date.Today().addDays(50); 
            update installmentRec;
        }
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        //insert objSRStatus;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.PAYMENT_EXTENSION_RT, Constants.PAYMENT_EXTENSION_RT);
        insert objStepTemplate;
        
        HexaBPM__Step_Template__c objStepTemplate1 = TestObjectsFactory.getStepTemplate(Constants.PROPERTY_TRANSFER_RT, Constants.PROPERTY_TRANSFER_RT);
        insert objStepTemplate1;
        
        List < HexaBPM__Service_Request__c > propertyTransferList = new List < HexaBPM__Service_Request__c > ();        
        HexaBPM__Service_Request__c propertyTransfer = new HexaBPM__Service_Request__c();
        propertyTransfer.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
        propertyTransfer.SRType__c = '';
        propertyTransfer.ChargeType__c = '';
        propertyTransfer.Unit__c = u.Id;
        propertyTransfer.SwappedUnit__c = u1.Id;
        propertyTransfer.HexaBPM__Customer__c = acc.Id;
        propertyTransfer.BuyerName__c = newAccount.Id;   
        propertyTransfer.TransferSellingPrice__c=1000000;
        propertyTransfer.HexaBPM__Email__c ='test@test.com';
        insert propertyTransfer;
        
        propertyTransfer.SRType__c = 'Property Transfer';
   		update propertyTransfer;
        Test.stopTest();
        
        List<HexaBPM__Service_Request__c> propertyTransferOBJ = [SELECT Id,RecordType.Name,HexaBPM__Customer__r.CustomerType__c,Unit__r.BuildingSectionName__r.AldarStaffTransferThresholdLimit__c FROM HexaBPM__Service_Request__c WHERE Id=:propertyTransfer.id LIMIT 1];
        
        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{propertyTransfer.Id})[0];
        SalesOrder__c salesOrderObj = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{serviceRequest.SalesOrder__c})[0];
        String staffValidationMsg = ServiceRequestTriggerHandler.aldarstaffPTValidation(serviceRequest,salesOrderObj);
        Map<Id,Id> soMap = new Map<Id,Id>();
        soMap.put(salesOrderObj.Id,serviceRequest.Id);
        ServiceRequestTriggerHandler.titledeedKARMapping(soMap);
        if(propertyTransferOBJ.size() >0){
            ServiceRequestTriggerHandler.updateGoldenVisaDetails(new List<HexaBPM__Service_Request__c>{serviceRequest},new Set<Id>{propertyTransferOBJ[0].HexaBPM__Customer__c});
             ServiceRequestTriggerHandler.updateChargeCollected(propertyTransferList, propertyTransferList);
       		 ServiceRequestTriggerHandler.isCancellationSRNonClosed(propertyTransfer);
    
        }
        
    }
    
    
    /*@isTest
public static void createTaskDTProcess() {
Map<String,Id> recordTypeSR = new Map<String,Id>();
for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'DefaultAndTermination']){
recordTypeSR.put(rtype.DeveloperName,rtype.Id);
}

HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
SR.RecordTypeId = recordTypeSR.get('DefaultAndTermination');
SR.SRType__c = ALD_Constants.DEFAULT_AND_TERMINATION;
insert SR;

ServiceRequestTriggerHandler.createTaskDTProcess(new List<HexaBPM__Service_Request__c>{SR});
}*/
    @isTest static void srTest(){
        Test.startTest();
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        acc.CustomerType__c =Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF;
        insert acc;
        
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert newAccount;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name';
        insert project;
        
        BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
        buildingSection.AldarStaffTransferThresholdLimit__c = 40;
        insert buildingSection;
        
        Unit__c u = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
        u.Status__c = 'Sold';
        u.BuildingSectionName__c = buildingSection.id;
        insert u;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = u.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.SellingPrice__c=1000000;
        insert salesOrder;
        
        
        
        
        
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        //insert objSRStatus;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.PAYMENT_EXTENSION_RT, Constants.PAYMENT_EXTENSION_RT);
        insert objStepTemplate;
        
        HexaBPM__Step_Template__c objStepTemplate1 = TestObjectsFactory.getStepTemplate(Constants.PROPERTY_TRANSFER_RT, Constants.PROPERTY_TRANSFER_RT);
        insert objStepTemplate1;
        
        
        HexaBPM__Service_Request__c propertyTransfer = new HexaBPM__Service_Request__c();
        propertyTransfer.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
        propertyTransfer.SRType__c = '';
        propertyTransfer.ChargeType__c = '';
        propertyTransfer.IsComplianceReturned__c =false;
        propertyTransfer.Compliance_Status__c = 'Cleared';
        propertyTransfer.Unit__c = u.Id;
        //  propertyTransfer.SwappedUnit__c = u1.Id;
        propertyTransfer.HexaBPM__Customer__c = acc.Id;
        propertyTransfer.BuyerName__c = newAccount.id;   
        propertyTransfer.TransferSellingPrice__c=1000000;
        propertyTransfer.HexaBPM__Email__c ='test@test.com';
        insert propertyTransfer;
        system.debug('@@@propertyTransfer'+propertyTransfer);
        
          propertyTransfer.SRType__c = 'Property Transfer';
   		  update propertyTransfer;
        
        
        
        //system.debug('@@@propertyTransfer-Updaye'+propertyTransfer);
        
        HexaBPM__Status__c status = new HexaBPM__Status__c();
        status.Name = Constants.Cleared;
        status.HexaBPM__Code__c = Constants.Cleared;
        //insert status;
        
        List<HexaBPM__Status__c> statusList =[Select Id From HexaBPM__Status__c where Name = :Constants.Cleared limit 1];
        
        HexaBPM__Step__c step = new HexaBPM__Step__c(
            HexaBPM__Summary__c = 'Compliance Check for Buyers',
            HexaBPM__SR__c = propertyTransfer.Id,
            HexaBPM__Status__c = statusList[0].Id,
            HexaBPM__Start_Date__c = System.today(),
            HexaBPM__Due_Date__c = System.today().addDays(10)
        );
        insert step;
        List < HexaBPM__Service_Request__c > updRec = [Select id, Unit__c, SalesOrder__c, InstallmentLine__c, SRType__c, TotalCollectedAmount__c, HexaBPM__Record_Type_Name__c, HexaBPM__Contact__c, PaidEquity__c,
            Proceed_with_Offline__c, HexaBPM__Submitted_DateTime__c, Bypass_Equity_Check__c, ExemptValidations__c, RecordTypeId, Case__c, HexaBPM__Customer__c, PaymentExtensionDate__c,
            CancellationReason__c, WaivedPercentage__c, WaivedAmount__c, WaivedBy__c, InstallmentDate__c, PaymentExtensionPeriod__c, HexaBPM__SR_Template__c, TotalLPCAmount__c,
            LegalStatus__c, TermCommencementDate__c, TotalLPCDue__c, TotalLPCCollected__c, ChargeCollected__c, TotalLPCWaivedAmount__c, LPCCalculatedDate__c,
            SocialReason__c, HexaBPM__Parent_SR__c, HandoverDetail__c, OldNetAmount__c, TotalBilledAmount__c, TotalOutstandingAmount__c, RefundAmount__c, ReallocationAmount__c, IsRefundApplicable__c,
            LPCFreezeStatus__c, DocumentPrintedDate__c, HexaBPM__Closed_Date_Time__c, HexaBPM__IsClosedStatus__c, TitleDeedRegistrationFee__c, HexaBPM__External_SR_Status__c, HexaBPM__External_Status_Name__c, BlacklistedCustomer__c,
            PriceRevisionRequired__c, ForfeitAmount__c, CancellationOption__c, AgreementType__c,
            BuyerOwnershipVerifiedDari__c,Retrive_Buyer_Acc_Docs__c, BrokerManager__c, HOKAR__c, UnitFromSameProject__c, SwappedUnit__c, SalesOrderHoldFlag__c, BuyerName__c, ReferredBy__c, OwnerId from HexaBPM__Service_Request__c where id =: propertyTransfer.id limit 1
        ];
        propertyTransfer.Compliance_Status__c = 'Cleared';
        propertyTransfer.IsComplianceReturned__c = true;        
        update propertyTransfer;
        
        List<HexaBPM__Step__c> stepToUpdateList = [SELECT Id, HexaBPM__SR_Step__c, HexaBPM__Status__c,HexaBPM__Summary__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c = :propertyTransfer.Id AND HexaBPM__Summary__c = 'Compliance Check for Buyers' ORDER BY CreatedDate DESC LIMIT 1];
        system.debug('@@@stepToUpdateList-1'+stepToUpdateList);
        
        Test.stopTest();
        //  HexaBPM__Service_Request__c propertyTransferOBJ = [SELECT Id,RecordType.Name,HexaBPM__Customer__r.CustomerType__c,IsComplianceReturned__c,Compliance_Status__c FROM HexaBPM__Service_Request__c WHERE Id=:propertyTransfer.id LIMIT 1];
        //  propertyTransferOBJ.Compliance_Status__c = 'Cleared';
        //  propertyTransferOBJ.IsComplianceReturned__c = true;
        
        //   update propertyTransferOBJ;
        
        
    }
    @isTest static void srTest2(){
        Test.startTest();
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        newAccount.FastTrackedAccount__c = true;
        newAccount.FasttrackCompletionDate__c =System.today();
        insert newAccount;
        Document__c testNationalDocument = new Document__c(Account__c = newAccount.Id, DocumentType__c = 'National ID Front Copy');
        insert testNationalDocument;
        
        Document__c testPassportDocument = new Document__c(Account__c = newAccount.Id, DocumentType__c = 'Passport Copy');
        insert testPassportDocument;
        
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test Version';
        contentVersion.PathOnClient = 'testDocument.txt'; 
        contentVersion.VersionData = Blob.valueOf('Test Content'); 
        contentVersion.ContentLocation = 'S'; // 
        //contentVersion.FirstPublishLocationId = contentDoc.Id; 
        insert contentVersion;        
        
        ContentDocumentLink contentDocLink = new ContentDocumentLink();
        contentDocLink.ContentDocumentId = [select contentdocumentid from contentversion where id =: contentVersion.id].contentdocumentid;
        contentDocLink.LinkedEntityId = testNationalDocument.Id; 
        contentDocLink.ShareType = 'V'; 
        contentDocLink.Visibility = 'AllUsers';
        insert contentDocLink;       
        
        
        HexaBPM__Service_Request__c newSR2 = new HexaBPM__Service_Request__c();
        newSR2.Id =[SELECT id from HexaBPM__Service_Request__c LIMIT 1].id;       
        newSR2.Retrive_Buyer_Acc_Docs__c = true;
        newSR2.BuyerName__c = newAccount.id;
        update newSR2;
        
        HexaBPM__SR_Doc__c SR = new HexaBPM__SR_Doc__c();
        SR.HexaBPM__Service_Request__c = newSR2.id;
        SR.Name ='Buyer Emirates ID Copy';
        Sr.HexaBPM__Doc_ID__c = null;
        insert SR;
        
        
        Test.stopTest();
    }
    @isTest
    public static void validatePropertyTransferSR(){
        
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org acc', 'G123456');
        insert newAccount;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        Set<Id> unitIdList = new Set<Id>();
        unitIdList.add(unit.Id);
        
        Test.startTest();
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        insert salesOrder;
        
        Case newCase = new Case();
        newCase.RecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('StandardCase').getRecordTypeId();
        newCase.Subject = 'Test Subject';
        newCase.Description = 'Test Description';
        newCase.Status = 'New';
        newCase.Origin = 'Direct Call';
        newCase.CaseCategory__c = 'Property Transfer';
        newCase.Opportunity__c = opp.id;
        newCase.Unit__c = unit.id;
        newCase.Current_Residential_Status__c = 'Resident';
        newCase.Current_Residential_Country__c = 'United Arab Emirates';
        //insert newcase;
        
        HexaBPM__Service_Request__c propertyTransfer = new HexaBPM__Service_Request__c();
        propertyTransfer.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
        propertyTransfer.SRType__c = Constants.PROPERTY_TRANSFER_TYPE;
        propertyTransfer.Unit__c = unit.id;
        List<HexaBPM__Service_Request__c> serviceRequestList = new List<HexaBPM__Service_Request__c>();
        serviceRequestList.add(propertyTransfer);
        
        Id propertyTransferRecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Property Transfer').getRecordTypeId();
        Id propertyTransferNocRecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Property Transfer NOC').getRecordTypeId();
        set<Id> propertyTransferRecIds = new set<Id>();
        propertyTransferRecIds.add(propertyTransferRecordTypeId);
        propertyTransferRecIds.add(propertyTransferNocRecordTypeId);
        
        Set<Id> emptycaseIdSet = new Set<Id>();      
        ServiceRequestTriggerHandler.validatePropertyTransferSR(serviceRequestList, propertyTransferRecIds, unitIdList, emptycaseIdSet);
        Test.stopTest();
    }
    @isTest static void spaOffline(){
        Test.startTest();
        HexaBPM__Service_Request__c spaReg = new HexaBPM__Service_Request__c();
        //spaReg.SRType__c = 'SPA Registration';
        spaReg.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'SPA Registration For Off Plan');
        spaReg.Id = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1].Id;
        spaReg.Proceed_with_Offline__c = true;
        spaReg.SPACounterSignedDate__c = system.today();
        update spaReg;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.LPC_WAIVER_RT, 'LPCWaiver');
        insert objStepTemplate;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate('PropertyTransfer');     
        SRTemplateDetailRecord.Name = Constants.PROPERTY_TRANSFER_RT;
        insert SRTemplateDetailRecord;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(spaReg.id, objSRSteps.Id, objStepTemplate.id);     
        newStep.HexaBPM__Summary__c = 'Submit Registration';
        insert newStep;
        
        System.debug('debug:'+[SELECT Id,HexaBPM__Summary__c,HexaBPM__Step_Status__c FROM HexaBPM__Step__c ]);
        ServiceRequestTriggerHandler.handleOfflineProceess(new List<HexaBPM__Service_Request__c>{spaReg}, new Map<Id,HexaBPM__Service_Request__c>([SELECT Id,SRType__c,Proceed_with_Offline__c FROM HexaBPM__Service_Request__c]));
        Test.stopTest();
    }
    
    @isTest static void spaOffline2(){
        Test.startTest();
        HexaBPM__Service_Request__c spaReg = new HexaBPM__Service_Request__c();
        //spaReg.SRType__c = 'SPA Registration';
        spaReg.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Title Deed Registration');
        spaReg.Id = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1].Id;
        spaReg.Proceed_with_Offline__c = true;
        spaReg.SPACounterSignedDate__c = system.today();
        update spaReg;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.LPC_WAIVER_RT, 'LPCWaiver');
        objStepTemplate.Name='Registration In Progress';
        insert objStepTemplate;
        
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate('TitleDeedRegistration');     
        SRTemplateDetailRecord.Name = 'Title Deed Registration';
        insert SRTemplateDetailRecord;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        objSRSteps.HexaBPM__Step_Template__c=objStepTemplate.Id;
        insert objSRSteps;
        
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(spaReg.id, objSRSteps.Id, objStepTemplate.id);     
        newStep.HexaBPM__Summary__c = 'Registration In Progress';
        insert newStep;
        
        System.debug('debug:'+[SELECT Id,HexaBPM__Summary__c,HexaBPM__Step_Status__c FROM HexaBPM__Step__c ]);
        ServiceRequestTriggerHandler.handleOfflineProceess(new List<HexaBPM__Service_Request__c>{spaReg}, new Map<Id,HexaBPM__Service_Request__c>([SELECT Id,SRType__c,Proceed_with_Offline__c FROM HexaBPM__Service_Request__c]));
        Test.stopTest();
    }
    @isTest 
    static void closeADMStep(){
        
        
        Id personAccountRecordTypeId=utilities.getRecordTypeId('Account','Person Account');
        Account acc = new Account();
        acc.FirstName='Test';
        acc.LastName= 'Agni';
        acc.PersonEmail='agni@gmail.com';
        acc.RecordTypeId = personAccountRecordTypeId;
        acc.CustomerAppWebUser__c=false;
        insert acc;
        
        //HexaBPM__SR_Status__c submittedStatus = new HexaBPM__SR_Status__c();
        //submittedStatus =TestObjectsFactory.getSRStatus('Submitted');
        Test.startTest();
        HexaBPM__SR_Status__c submittedStatus = [SELECT Id FROM HexaBPM__SR_Status__c where Name='Submitted'];
        system.debug('INSERTED_SR_STATUS_::'+submittedStatus);
        //insert submittedStatus;
        
        Project__c project=TestObjectsFactory.getProjectRecord('recordId');
        insert project;
        
        list<Unit__c> units = new list<unit__c>();
        unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.Name = 'MAYAN-B1-1004'; 
        unit.Project__c= project.Id;
        insert unit;
        
        list<Unit__c> unitList = new list<unit__c>();
        unit__c unit2 = TestObjectsFactory.unitDataSetup('25083');
        unit2.Status__c = 'Sold';
        unit2.Name = 'Test MAYAN-B1-1004'; 
        unit2.Project__c= project.Id;
        insert unit2;
        
        Id PropertyTransferNOCRTId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer NOC');
        
        HexaBPM__SR_Template__c PTNSRTemplate = new HexaBPM__SR_Template__c();
        PTNSRTemplate.HexaBPM__Active__c = true;
        PTNSRTemplate.HexaBPM__SR_RecordType_API_Name__c = 'Property Transfer NOC';
        insert PTNSRTemplate;
        
        HexaBPM__Service_Request__c srExists=TestObjectsFactory.getServiceRequest(submittedStatus.Id,unit.Id,'Property Transfer NOC',PropertyTransferNOCRTId,PTNSRTemplate.Id);
        srExists.TransferSellingPrice__c=19500.01;
        srExists.HexaBPM__Customer__c=acc.Id;
        srExists.BuyerOwnershipVerifiedDari__c = false ;
        
        insert srExists;
        
        HexaBPM__Status__c CompletedStatus = new HexaBPM__Status__c();
        CompletedStatus.Name = 'Completed';
        CompletedStatus.HexaBPM__Code__c = 'Completed';
        Insert CompletedStatus;
        
        HexaBPM__Status__c ApprovedStatus = new HexaBPM__Status__c();
        ApprovedStatus.Name = 'Approved';
        ApprovedStatus.HexaBPM__Code__c = 'Approved';
        Insert ApprovedStatus;
        
        HexaBPM__Status__c PendingStatus = new HexaBPM__Status__c();
        PendingStatus.Name = 'Pending';
        PendingStatus.HexaBPM__Code__c = 'Pending';
        Insert PendingStatus;
        
        list<HexaBPM__Step_Template__c> stepTemplateToInsert = new list<HexaBPM__Step_Template__c>();
        list<String> templatesCode = new list<String>{'Transfer Execution status in ADM','Title Deed Approval'};
            for(String tempS : templatesCode){
                HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
                ST.Name = tempS;
                ST.HexaBPM__Code__c = tempS;
                ST.HexaBPM__Summary__c =tempS;
                ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
                stepTemplateToInsert.add(ST);
            }
        insert stepTemplateToInsert;
        
        //Step Status 
        list<HexaBPM__Status__c> stepStatus = new list<HexaBPM__Status__c>{ new HexaBPM__Status__c(Name=Constants.STEP_STATUS_PENDING, HexaBPM__Code__c=Constants.STEP_STATUS_PENDING , HexaBPM__Type__c = 'Start'),
            new HexaBPM__Status__c(Name=Constants.STEP_STATUS_COMPLETED, HexaBPM__Code__c=Constants.STEP_STATUS_COMPLETED , HexaBPM__Type__c = 'End')};
                //insert stepStatus;
                list<HexaBPM__SR_Steps__c> templateSteps = new list<HexaBPM__SR_Steps__c>();
        for(HexaBPM__Step_Template__c tempRec : stepTemplateToInsert){
            HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
            SRStep.HexaBPM__SR_Template__c = PTNSRTemplate.id;
            SRStep.HexaBPM__Step_No__c = templateSteps.size()+1;
            SRStep.HexaBPM__Step_Template__c = tempRec.Id;
            SRStep.HexaBPM__Summary__c = tempRec.Name;
            SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
            SRStep.HexaBPM__Start_Status__c = stepStatus[0].Id;
            
            templateSteps.add(SRStep);
        }   
        insert templateSteps;  
        List<HexaBPM__Step__c>stepList = new List<HexaBPM__Step__c>();
        for(HexaBPM__SR_Steps__c tempStep : templateSteps){
            HexaBPM__Step__c tempRec = new 
                HexaBPM__Step__c( ExecuteCustomCode__c =
                                 tempStep.HexaBPM__Sys_Custom_Conditions_Actions__c,
                                 HexaBPM__SR_Step__c = tempStep.Id,
                                 OwnerId = UserInfo.getUserId(),
                                 HexaBPM__SR__c = srExists.Id,
                                 HexaBPM__Start_Date__c = System.today(),
                                 HexaBPM__Step_No__c = tempStep.HexaBPM__Step_No__c,
                                 HexaBPM__Status__c =  PendingStatus.Id,
                                 HexaBPM__Step_Template__c =  tempStep.HexaBPM__Step_Template__c,
                                 HexaBPM__Summary__c = tempStep.HexaBPM__Summary__c,
                                 HexaBPM__Sys_Step_Loop_No__c = tempStep.HexaBPM__Step_No__c +'_1' );
            stepList.add(tempRec);   
            
        }
        if(!stepList.isEmpty()){
            insert stepList;
        }
        
        srExists.BuyerOwnershipVerifiedDari__c=true;
        update srExists;
        
        system.debug('Updated NOCSR_BuyerOwnershipVerifiedDari__c::'+ srExists.BuyerOwnershipVerifiedDari__c);        
        
        //ServiceRequestTriggerHandler.closeADMStepList(new List<HexaBPM__Service_Request__c>{srExists});
        
        Test.stopTest();
    }
    
    @isTest
    public static void handleOfflineTest() {
        Test.startTest();
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
        salesOrder.SellingPrice__c = 1000000;
        insert salesOrder;
        List < HexaBPM__SR_Status__c > draftStatus = [Select id, name from HexaBPM__SR_Status__c where name = 'Draft'];
        List < InstallmentLines__c > installmentLines1 = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 1);
        installmentLines1[0].InvoicedAmount__c = 30;
        update installmentLines1;
        HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('Title Deed Registration');
        SRTemplateDetailRecord3.Name = 'Title Deed Registration';
        insert SRTemplateDetailRecord3;


        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord3.Id, objStepTemplate.Id);
        insert objSRSteps;

        List < HexaBPM__Service_Request__c > SRList = new List < HexaBPM__Service_Request__c > ();
        HexaBPM__Service_Request__c newSR1 = TestObjectsFactory.getServiceRequest(draftStatus[0].Id, unit.Id, 'Title Deed Registration', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Title Deed Registration'), SRTemplateDetailRecord3.Id);
        newSR1.SalesOrder__c = salesOrder.Id;
        //newSR1.SwappedUnit__c = unit.Id;
        newSR1.IsComplianceReturned__c = false;
        newSR1.Compliance_Status__c = '';
        newSR1.TransferSellingPrice__c = 1000000;
        newSR1.InstallmentLine__c = installmentLines1[0].Id;
        newSR1.Proceed_with_Offline__c = true;
        SRList.add(newSR1);
        insert SRList;

        List < HexaBPM__Service_Request__c > newList = [Select id, Unit__c, SalesOrder__c, InstallmentLine__c, SRType__c, TotalCollectedAmount__c, HexaBPM__Record_Type_Name__c, HexaBPM__Contact__c, PaidEquity__c,
            Proceed_with_Offline__c, HexaBPM__Submitted_DateTime__c, Bypass_Equity_Check__c, ExemptValidations__c, RecordTypeId, Case__c, HexaBPM__Customer__c, PaymentExtensionDate__c,
            CancellationReason__c, WaivedPercentage__c, WaivedAmount__c, WaivedBy__c, InstallmentDate__c, PaymentExtensionPeriod__c, HexaBPM__SR_Template__c, TotalLPCAmount__c,
            LegalStatus__c, TermCommencementDate__c, TotalLPCDue__c, TotalLPCCollected__c, ChargeCollected__c, TotalLPCWaivedAmount__c, LPCCalculatedDate__c,
            SocialReason__c, HexaBPM__Parent_SR__c, HandoverDetail__c, OldNetAmount__c, TotalBilledAmount__c, TotalOutstandingAmount__c, RefundAmount__c, ReallocationAmount__c, IsRefundApplicable__c,
            LPCFreezeStatus__c, DocumentPrintedDate__c, HexaBPM__Closed_Date_Time__c, HexaBPM__IsClosedStatus__c, TitleDeedRegistrationFee__c, HexaBPM__External_SR_Status__c, HexaBPM__External_Status_Name__c, BlacklistedCustomer__c,
            PriceRevisionRequired__c, ForfeitAmount__c, CancellationOption__c, AgreementType__c,
            BuyerOwnershipVerifiedDari__c,BrokerManager__c, HOKAR__c, UnitFromSameProject__c, SwappedUnit__c, SalesOrderHoldFlag__c, BuyerName__c, ReferredBy__c, OwnerId from HexaBPM__Service_Request__c where id =: SRList[0].id limit 1
        ];
        Map < id, HexaBPM__Service_Request__c > emptyMap = new Map < id, HexaBPM__Service_Request__c > ();

        ServiceRequestTriggerHandler srHandler = new ServiceRequestTriggerHandler();
        Map < id, HexaBPM__Service_Request__c > oldMap = new Map < id, HexaBPM__Service_Request__c > ();
        Map < HexaBPM__Service_Request__c, id > newMap = new Map < HexaBPM__Service_Request__c, id > ();
        List < HexaBPM__Service_Request__c > newList5 = new List < HexaBPM__Service_Request__c > ();
        List < SalesOrder__c > salOrd = [Select id, Unit__c, EquityPercentage__c from SalesOrder__c limit 1];
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25084');
        unit1.Status__c = 'Sold';
        insert unit1;
        List < HexaBPM__Service_Request__c > updRec = [Select id, Unit__c, SalesOrder__c, InstallmentLine__c, SRType__c, TotalCollectedAmount__c, HexaBPM__Record_Type_Name__c, HexaBPM__Contact__c, PaidEquity__c,
            Proceed_with_Offline__c, HexaBPM__Submitted_DateTime__c, Bypass_Equity_Check__c, ExemptValidations__c, RecordTypeId, Case__c, HexaBPM__Customer__c, PaymentExtensionDate__c,
            CancellationReason__c, WaivedPercentage__c, WaivedAmount__c, WaivedBy__c, InstallmentDate__c, PaymentExtensionPeriod__c, HexaBPM__SR_Template__c, TotalLPCAmount__c,
            LegalStatus__c, TermCommencementDate__c, TotalLPCDue__c, TotalLPCCollected__c, ChargeCollected__c, TotalLPCWaivedAmount__c, LPCCalculatedDate__c,
            SocialReason__c, HexaBPM__Parent_SR__c, HandoverDetail__c, OldNetAmount__c, TotalBilledAmount__c, TotalOutstandingAmount__c, RefundAmount__c, ReallocationAmount__c, IsRefundApplicable__c,
            LPCFreezeStatus__c, DocumentPrintedDate__c, HexaBPM__Closed_Date_Time__c, HexaBPM__IsClosedStatus__c, TitleDeedRegistrationFee__c, HexaBPM__External_SR_Status__c, HexaBPM__External_Status_Name__c, BlacklistedCustomer__c,
            PriceRevisionRequired__c, ForfeitAmount__c, CancellationOption__c, AgreementType__c,
            BuyerOwnershipVerifiedDari__c,BrokerManager__c, HOKAR__c, UnitFromSameProject__c, SwappedUnit__c, SalesOrderHoldFlag__c, BuyerName__c, ReferredBy__c, OwnerId from HexaBPM__Service_Request__c where id =: SRList[0].id limit 1
        ];
        updRec[0].TransferSellingPrice__c = 1000000;
        updRec[0].SalesOrder__c = salOrd[0].id;
        updRec[0].PaymentExtensionDate__c = Date.today() + 5;
        updRec[0].WaivedAmount__c = 2000;
        updRec[0].Unit__c = unit1.Id;
        updRec[0].SwappedUnit__c = null;
        updRec[0].HexaBPM__Customer__c = newAccount.id;
        updRec[0].Proceed_with_Offline__c = false;
        newList5.add(updRec[0]);
        update newList5;
        set < id > cusIds = new set < id > ();
        list < id > salesId = new list < id > ();
        Map < id, id > salsOrdMap = new Map < id, id > ();
        for (HexaBPM__Service_Request__c sr: newList5) {
            oldMap.put(sr.id, sr);
            newMap.put(sr, sr.id);
            cusIds.add(sr.HexaBPM__Customer__c);
            salsOrdMap.put(sr.SalesOrder__c, sr.HOKAR__c);
            salesId.add(sr.SalesOrder__c);
        }
        ServiceRequestTriggerHandler.handleOfflineProcessTDSR(newList, oldMap);
        Test.stopTest();
    }
    
     @isTest
    public static void beforeUpdateTitleTest() {
        Test.startTest();
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.TITLE_DEED_REGISTRATION_DEV_RT, 'TitleDeedRegistration');
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
        salesOrder.SellingPrice__c = 1000000;
        insert salesOrder;
        List < HexaBPM__SR_Status__c > draftStatus = [Select id, name from HexaBPM__SR_Status__c where name = 'Draft'];
        List < InstallmentLines__c > installmentLines1 = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 1);
        installmentLines1[0].InvoicedAmount__c = 30;
        update installmentLines1;
        HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('Title Deed Registration');
        SRTemplateDetailRecord3.Name = Constants.PROPERTY_TRANSFER_RT;
        insert SRTemplateDetailRecord3;


        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord3.Id, objStepTemplate.Id);
        insert objSRSteps;

        List < HexaBPM__Service_Request__c > SRList = new List < HexaBPM__Service_Request__c > ();
        HexaBPM__Service_Request__c newSR1 = TestObjectsFactory.getServiceRequest(draftStatus[0].Id, unit.Id, 'Title Deed Registration', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Title Deed Registration'), SRTemplateDetailRecord3.Id);
        newSR1.SalesOrder__c = salesOrder.Id;
        newSR1.Unit__c = unit.Id;
        newSR1.IsComplianceReturned__c = false;
        newSR1.Compliance_Status__c = '';
        newSR1.TransferSellingPrice__c = 1000000;
        newSR1.InstallmentLine__c = installmentLines1[0].Id;
        SRList.add(newSR1);
        insert SRList;

        List < HexaBPM__Service_Request__c > newList = [Select id, Unit__c, SalesOrder__c, InstallmentLine__c, SRType__c, TotalCollectedAmount__c, HexaBPM__Record_Type_Name__c, HexaBPM__Contact__c, PaidEquity__c,
            Proceed_with_Offline__c, HexaBPM__Submitted_DateTime__c, Bypass_Equity_Check__c, ExemptValidations__c, RecordTypeId, Case__c, HexaBPM__Customer__c, PaymentExtensionDate__c,
            CancellationReason__c, WaivedPercentage__c, WaivedAmount__c, WaivedBy__c, InstallmentDate__c, PaymentExtensionPeriod__c, HexaBPM__SR_Template__c, TotalLPCAmount__c,
            LegalStatus__c, TermCommencementDate__c, TotalLPCDue__c, TotalLPCCollected__c, ChargeCollected__c, TotalLPCWaivedAmount__c, LPCCalculatedDate__c,
            SocialReason__c, HexaBPM__Parent_SR__c, HandoverDetail__c, OldNetAmount__c, TotalBilledAmount__c, TotalOutstandingAmount__c, RefundAmount__c, ReallocationAmount__c, IsRefundApplicable__c,
            LPCFreezeStatus__c, DocumentPrintedDate__c, HexaBPM__Closed_Date_Time__c, HexaBPM__IsClosedStatus__c, TitleDeedRegistrationFee__c, HexaBPM__External_SR_Status__c, HexaBPM__External_Status_Name__c, BlacklistedCustomer__c,
            PriceRevisionRequired__c, ForfeitAmount__c, CancellationOption__c, AgreementType__c,
            BuyerOwnershipVerifiedDari__c,SubType__c, BrokerManager__c, HOKAR__c, UnitFromSameProject__c, SwappedUnit__c, SalesOrderHoldFlag__c, BuyerName__c, ReferredBy__c, OwnerId from HexaBPM__Service_Request__c where id =: SRList[0].id limit 1
        ];
        Map < id, HexaBPM__Service_Request__c > emptyMap = new Map < id, HexaBPM__Service_Request__c > ();

        ServiceRequestTriggerHandler srHandler = new ServiceRequestTriggerHandler();
        Map < id, HexaBPM__Service_Request__c > oldMap = new Map < id, HexaBPM__Service_Request__c > ();
        Map < id, HexaBPM__Service_Request__c > newMap = new Map < id, HexaBPM__Service_Request__c > ();
        List < HexaBPM__Service_Request__c > newList5 = new List < HexaBPM__Service_Request__c > ();
        List < SalesOrder__c > salOrd = [Select id, Unit__c, EquityPercentage__c from SalesOrder__c limit 1];
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25084');
        unit1.Status__c = 'Sold';
        insert unit1;
        List < HexaBPM__Service_Request__c > updRec = [Select id, Unit__c, SalesOrder__c, InstallmentLine__c, SRType__c, TotalCollectedAmount__c, HexaBPM__Record_Type_Name__c, HexaBPM__Contact__c, PaidEquity__c,
            Proceed_with_Offline__c, HexaBPM__Submitted_DateTime__c, Bypass_Equity_Check__c, ExemptValidations__c, RecordTypeId, Case__c, HexaBPM__Customer__c, PaymentExtensionDate__c,
            CancellationReason__c, WaivedPercentage__c, WaivedAmount__c, WaivedBy__c, InstallmentDate__c, PaymentExtensionPeriod__c, HexaBPM__SR_Template__c, TotalLPCAmount__c,
            LegalStatus__c, TermCommencementDate__c, TotalLPCDue__c, TotalLPCCollected__c, ChargeCollected__c, TotalLPCWaivedAmount__c, LPCCalculatedDate__c,
            SocialReason__c, HexaBPM__Parent_SR__c, HandoverDetail__c, OldNetAmount__c, TotalBilledAmount__c, TotalOutstandingAmount__c, RefundAmount__c, ReallocationAmount__c, IsRefundApplicable__c,
            LPCFreezeStatus__c, DocumentPrintedDate__c, HexaBPM__Closed_Date_Time__c, HexaBPM__IsClosedStatus__c, TitleDeedRegistrationFee__c, HexaBPM__External_SR_Status__c, HexaBPM__External_Status_Name__c, BlacklistedCustomer__c,
            PriceRevisionRequired__c, ForfeitAmount__c, CancellationOption__c, AgreementType__c,
            BuyerOwnershipVerifiedDari__c,SubType__c, BrokerManager__c, HOKAR__c, UnitFromSameProject__c, SwappedUnit__c, SalesOrderHoldFlag__c, BuyerName__c, ReferredBy__c, OwnerId from HexaBPM__Service_Request__c where id =: SRList[0].id limit 1
        ];
        updRec[0].TransferSellingPrice__c = 1000000;
        updRec[0].SalesOrder__c = salOrd[0].id;
        updRec[0].PaymentExtensionDate__c = Date.today() + 5;
        updRec[0].WaivedAmount__c = 2000;
        updRec[0].Unit__c = unit1.Id;
        newList5.add(updRec[0]);
        update newList5;
        for (HexaBPM__Service_Request__c sr: newList5) {
            oldMap.put(sr.id, sr);
        }
        ServiceRequestTriggerHandler.closeADMStepList(newList5);
        srHandler.beforeUpdateMethod(newList, newMap, newList5, oldMap);
        Test.stopTest();
    } 
    
    @isTest
    public static void GoldenVisaTest() {
        Test.startTest();
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

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.SellingPrice__c = 1000000;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        List < HexaBPM__SR_Status__c > draftStatus = [Select id, name from HexaBPM__SR_Status__c where name = 'Draft'];

        HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('Golden Visa');
        SRTemplateDetailRecord3.Name = Constants.PROPERTY_TRANSFER_RT;
        insert SRTemplateDetailRecord3;


        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord3.Id, objStepTemplate.Id);
        insert objSRSteps;

        List < HexaBPM__Service_Request__c > SRList = new List < HexaBPM__Service_Request__c > ();
        HexaBPM__Service_Request__c newSR1 = TestObjectsFactory.getServiceRequest(draftStatus[0].Id, unit.Id, 'Golden Visa', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Golden Visa'), SRTemplateDetailRecord3.Id);
        newSR1.SalesOrder__c = salesOrder.Id;
        newSR1.Unit__c = unit.Id;
        newSR1.IsComplianceReturned__c = false;
        newSR1.Compliance_Status__c = '';
        newSR1.TransferSellingPrice__c = 1000000;
        newSR1.PaymentExtensionDate__c = Date.today() + 3;
        newSR1.HexaBPM__Customer__c = newAccount.Id;
        SRList.add(newSR1);
        insert SRList;
        ServiceRequestTriggerHandler serviceRequest = new ServiceRequestTriggerHandler();
        serviceRequest.beforeInsertMethod(SRList, new Map < Id, SObject > ());
        ServiceRequestTriggerHandler.aldarstaffPTValidation(newSR1, salesOrder);
        Test.stopTest();

    }
    
}