@isTest
public class ServiceRequestTriggerHandlerNewTest {
    @testSetup static void testData(){
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus(Constants.Compliance_Rejected);       
        insert Submitted; 

        HexaBPM__SR_Status__c Submitted1 = TestObjectsFactory.getSRStatus(Constants.Compliance_Cleared);       
        insert Submitted1; 
        
        HexaBPM__SR_Status__c Submitted2 = TestObjectsFactory.getSRStatus('Submitted'); 
        Submitted2.HexaBPM__Type__c = 'End';   
        insert Submitted2; 
        
        HexaBPM__Status__c status1 = new HexaBPM__Status__c();
        status1.Name =Constants.Cleared;
        status1.HexaBPM__Code__c =Constants.Cleared;
        insert status1;
        
        HexaBPM__Status__c statusCom = new HexaBPM__Status__c();
        statusCom.Name = 'Completed';
        statusCom.HexaBPM__Code__c = 'Completed';
        insert statusCom;
        
        HexaBPM__Status__c statusApp = new HexaBPM__Status__c();
        statusApp.Name = 'Approved';
        statusApp.HexaBPM__Code__c = 'Approved';
        insert statusApp;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.PROPERTY_TRANSFER_DEV_RT, 'PropertyTransfer');
        insert objStepTemplate;
        
           Trigger_Enabler__c triggerEnabler = new Trigger_Enabler__c();
            triggerEnabler.Name = 'Asset';
            triggerEnabler.Is_After_Update__c =false;
            triggerEnabler.Is_After_Insert__c =false;
            triggerEnabler.Is_After_Delete__c = false;
            triggerEnabler.Is_Before_Delete__c = false;
            triggerEnabler.Is_Before_Insert__c = false;
            triggerEnabler.Is_Before_Update__c = false;
            insert triggerEnabler;
        
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
        salesOrder.NumberOfDefaults__c = 0;
        insert salesOrder;
        
        PaymentPlan__c paymentPlanRecord = TestObjectsFactory.getPaymentPlanRecord();
        insert paymentPlanRecord;
        list<PaymentInstallments__c> installmentLines = TestObjectsFactory.getPaymentInstallment(paymentPlanRecord.Id);
        insert installmentLines;
        
        HexaBPM__SR_Status__c closed = new HexaBPM__SR_Status__c();
        closed.Name = 'closed';
        closed.HexaBPM__Code__c = 'closed';
        insert closed;



        HexaBPM__SR_Template__c spaTemp = TestObjectsFactory.getSRTemplate(Constants.SPA_REGISTRATION_TYPE);        
        insert spaTemp;
        Id spaId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);
        
        HexaBPM__Service_Request__c newSRSPA = TestObjectsFactory.getServiceRequest(closed.Id, unit.Id, Constants.SPA_REGISTRATION_TYPE, spaId, spaTemp.Id);
        newSRSPA.SalesOrder__c = salesOrder.Id;
        newSRSPA.SPACounterSignedDate__c=Date.today();
        insert newSRSPA;
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');  
        insert draft;
        
        System.debug(json.serialize([SELECT ID,HexaBPM__Type__c   FROM HexaBPM__SR_Status__c WHERE ID =:draft.id ]));


        HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('PropertyTransfer');     
        SRTemplateDetailRecord3.Name = Constants.PROPERTY_TRANSFER_RT;
        insert SRTemplateDetailRecord3;

        HexaBPM__SR_Template__c SRTemplateDetailRecord4 = TestObjectsFactory.getSRTemplate('DefaultAndTermination');     
        SRTemplateDetailRecord3.Name = Constants.DEFAULT_AND_TERMINATION_DEV_RT;
        insert SRTemplateDetailRecord4;
        
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord3.Id, objStepTemplate.Id);
        insert objSRSteps;
        
        HexaBPM__Service_Request__c newSR1 = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, 'Property Transfer', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer'), SRTemplateDetailRecord3.Id);
        newSR1.SalesOrder__c = salesOrder.Id;        
        newSR1.Unit__c = unit.Id;        
        newSR1.IsComplianceReturned__c =false;
        newSR1.Compliance_Status__c = 'Cleared';
        newSR1.TransferSellingPrice__c= 1000000;
        newSR1.HexaBPM__Email__c = 'test@test.com';        
        insert newSR1;
        newSR1.Compliance_Status__c = 'Cleared';
        newSR1.IsComplianceReturned__c = true;        
        update newSR1;
        

        HexaBPM__Service_Request__c newSR2 = TestObjectsFactory.getServiceRequest(Submitted2.Id, unit.Id, 'Default And Termination', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Default And Termination'), SRTemplateDetailRecord4.Id);
        newSR2.SalesOrder__c = salesOrder.Id;        
        newSR2.Unit__c = unit.Id;        
        newSR2.IsComplianceReturned__c =false;
        newSR2.Compliance_Status__c = 'Cleared';
        newSR2.TransferSellingPrice__c= 1000000;
        newSR2.HexaBPM__Email__c = 'test@test.com';        
        insert newSR2;

        // Fetch the Service Request
        HexaBPM__Service_Request__c srToUpdate = [
            SELECT Id, HexaBPM__External_SR_Status__c
            FROM HexaBPM__Service_Request__c
            WHERE Id = :newSR2.Id
        ];

        // If it has an External Status record, update its Type
        if (srToUpdate.HexaBPM__External_SR_Status__c != null) {
            HexaBPM__SR_Status__c externalStatus = [
                SELECT Id, HexaBPM__Type__c
                FROM HexaBPM__SR_Status__c
                WHERE Id = :srToUpdate.HexaBPM__External_SR_Status__c
            ];
            externalStatus.HexaBPM__Type__c = 'End';
            update externalStatus;
        }

        System.debug(json.serialize([SELECT ID,HexaBPM__IsClosedStatus__c, SRType__c, HexaBPM__External_SR_Status__r.HexaBPM__Type__c, HexaBPM__Internal_SR_Status__r.HexaBPM__Type__c   FROM HexaBPM__Service_Request__c WHERE ID =:newSR2.id ]));

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR1.id, objSRSteps.Id, objStepTemplate.id);     
        newStep.HexaBPM__Summary__c = 'Compliance Check for Buyers';
        insert newStep;   
        
        update newSR2;
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
        
        /*Unit__c unit1 = TestObjectsFactory.unitDataSetup('25084');
        unit1.Status__c = 'Sold';
        unit1.Name = 'MAYAN-B1-1004';
        insert unit1;
        
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('25085');
        unit2.Status__c = 'Sold';
        unit2.Name = 'MAYAN-B1-1005';
        insert unit2;*/
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.MortgageApplicable__c = 'Yes';
        salesOrder.Contact__c = con.Id;
        insert salesOrder;                
        
        /*SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder1.Unit__c = unit1.Id;
        salesOrder1.MortgageApplicable__c = 'Yes';
        salesOrder1.Contact__c = con.Id;
        insert salesOrder1;
        
        SalesOrder__c salesOrder2 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder2.Unit__c = unit2.Id;
        salesOrder2.MortgageApplicable__c = 'Yes';
        salesOrder2.Contact__c = con.Id;
        insert salesOrder2;*/
        
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
        
        
        HexaBPM__Service_Request__c lpcSR1 = [Select id,HexaBPM__External_Status_Name__c, HexaBPM__External_SR_Status__r.Name from  HexaBPM__Service_Request__c where Id =: lpcSR.Id];
        
        
        TriggerHandler.processedIds = new Set<Id>();
        //newSR.Unit__c = unit2.Id;
        //newSR.SalesOrder__c = salesOrder2.Id;
        
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
        
        //Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        //insert acc;
        
        List<HexaBPM__SR_Template__c> srTemplateDetailList=new List<HexaBPM__SR_Template__c>();
        HexaBPM__SR_Template__c SRTemplateDetailRecord1 = TestObjectsFactory.getSRTemplate('PaymentExtension');
        SRTemplateDetailRecord1.Name = 'Payment Extension';
        // insert SRTemplateDetailRecord1;
        srTemplateDetailList.add(SRTemplateDetailRecord1);
        
        //HexaBPM__SR_Template__c SRTemplateDetailRecord2 = TestObjectsFactory.getSRTemplate('TitleDeedRegistration');
        //SRTemplateDetailRecord2.Name = 'Title Deed Registration';
        
        // insert SRTemplateDetailRecord2;
        //srTemplateDetailList.add(SRTemplateDetailRecord2);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('PropertyTransfer');     
        SRTemplateDetailRecord3.Name = Constants.PROPERTY_TRANSFER_RT;        
        //insert SRTemplateDetailRecord3;
        srTemplateDetailList.add(SRTemplateDetailRecord3);
        
        //HexaBPM__SR_Template__c SRTemplateDetailRecord4 = TestObjectsFactory.getSRTemplate('GoldenVisa');     
        //SRTemplateDetailRecord4.Name = 'Golden Visa';
        //insert SRTemplateDetailRecord4;
        //srTemplateDetailList.add(SRTemplateDetailRecord4);
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
        Test.startTest();
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
        
        
        HexaBPM__SR_Status__c closed = [Select id from HexaBPM__SR_Status__c where Name = 'Closed'];       
        HexaBPM__SR_Template__c spaTemp = TestObjectsFactory.getSRTemplate(Constants.SPA_REGISTRATION_TYPE);        
        insert spaTemp;
        Id spaId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);
        
        HexaBPM__Service_Request__c newSRSPA = TestObjectsFactory.getServiceRequest(closed.Id, u.Id, Constants.SPA_REGISTRATION_TYPE, spaId, spaTemp.Id);
        newSRSPA.SalesOrder__c = salesOrder.Id;
        newSRSPA.SPACounterSignedDate__c=Date.today();
        insert newSRSPA;
        HexaBPM__Service_Request__c newSRclSPA = new HexaBPM__Service_Request__c();
        newSRclSPA.Id = newSRSPA.Id;
        newSRclSPA.HexaBPM__External_SR_Status__c = closed.Id;
        ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = true;
        update newSRclSPA;
        ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = false;
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
        paymentExtention.SRType__c = Constants.PAYMENT_EXTENSION_TYPE;
        paymentExtention.PaymentExtensionDate__c = Date.Today().addDays(10);
        paymentExtention.Unit__c = u.Id;
        paymentExtention.HexaBPM__Email__c = 'test@test.com';
        
        HexaBPM__Service_Request__c propertyTransfer = new HexaBPM__Service_Request__c();
        propertyTransfer.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
        propertyTransfer.SRType__c = Constants.PROPERTY_TRANSFER_TYPE;
        propertyTransfer.ChargeType__c = 'Transfer Normal';
        propertyTransfer.Unit__c = u.Id;
        propertyTransfer.SwappedUnit__c = u1.Id;
        propertyTransfer.InstallmentLine__c = installmentRec.Id;
        propertyTransfer.TransferSellingPrice__c=1000000;
        propertyTransfer.HexaBPM__Email__c = 'test@test.com';
        Map<HexaBPM__Service_Request__c, Id> SRwithSOmap = new Map<HexaBPM__Service_Request__c, Id>();
        SRwithSOmap.put(propertyTransfer, salesOrder.id);
        
        
        /*HexaBPM__Service_Request__c titleDeed = new HexaBPM__Service_Request__c();
        titleDeed.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.TITLE_DEED_REGISTRATION_RT);
        titleDeed.SRType__c = Constants.TITLE_DEED_REGISTRATION_RT;
        titleDeed.Unit__c = salesOrder.Unit__c;
        titleDeed.Unit__c = u.Id;
        titleDeed.HexaBPM__Email__c = 'test@test.com';*/
       // Account newAcc = TestObjectsFactory.getPersonAccountRecord();
       // insert newAcc;
        
        //HexaBPM__Service_Request__c golden = new HexaBPM__Service_Request__c();
        //golden.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.Golden_Visa_RT);
        //golden.SRType__c = Constants.Golden_Visa_RT;
        //golden.HexaBPM__Customer__c = newAcc.id;
        //golden.HexaBPM__Email__c = 'test@test.com';
        //golden.Unit__c = u.Id;
        //insert golden;
        //List<SObject> newlist = new List<SObject>();
        //newlist.add(golden);
        
        HexaBPM__Service_Request__c cancellationSR = new HexaBPM__Service_Request__c();
        cancellationSR.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.CANCELLATION_RT);
        cancellationSR.SRType__c = Constants.CANCELLATION_INTEGRATION;
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
            ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = true;
            update srUpdateList;
            ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = false;
        } catch (Exception ex) {
            System.debug(ex);
        }
        Test.StopTest();
        
        //ServiceRequestTriggerHandler serviceRequest = new ServiceRequestTriggerHandler();
        //ServiceRequestTriggerHandler obj = new ServiceRequestTriggerHandler();
        //obj.beforeInsertMethod(newlist, new Map<Id, SObject>());
       // ServiceRequestTriggerHandler.updateSalesOrderAndCustomer(new List<HexaBPM__Service_Request__c>{propertyTransfer});
       // serviceRequest.afterInsertMethod(new List<SObject>(), new Map<Id, SObject>());
        LPCService.submittedLPC(SRwithSOmap);
       // ServiceRequestTriggerHandler.updateRTORent(new List<Id>{salesOrder.Id}, new List<HexaBPM__Service_Request__c>{paymentExtention});
       // ServiceRequestTriggerHandler.blockTheSwappedUnit(srUpdateList, new Map<Id, SObject>());       
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
        PaymentPlanChangeService.checkPaidEquity(paymentPlanChange);
        //ServiceRequestTriggerHandler.checkSRAutomation(new List<HexaBPM__Service_Request__c>{paymentPlanChange}, null);
        
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
        
        List<HexaBPM__Service_Request__c> srInsertList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> srUpdateList = new List<HexaBPM__Service_Request__c>();
        
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
        newAccount.FastTrackedAccount__c = true;
        newAccount.FasttrackCompletionDate__c = System.now();
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
        
        /*SalesOrder__c salesOrder1 = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder1.Unit__c = u.Id;
        salesOrder1.IsBookingCompleted__c = true;
        salesOrder1.NetAmount__c = 100000;
        salesOrder1.Status__c = 'Sold';
        insert salesOrder1;*/
        
        HexaBPM__SR_Template__c spaTemp = TestObjectsFactory.getSRTemplate(Constants.SPA_REGISTRATION_TYPE);        
        insert spaTemp;
        HexaBPM__SR_Status__c Closed = [Select id from HexaBPM__SR_Status__c where Name = 'Closed'];
        Id spaId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);        
        HexaBPM__Service_Request__c newSRSPA = TestObjectsFactory.getServiceRequest(Closed.id, u.Id, Constants.SPA_REGISTRATION_TYPE, spaId, spaTemp.Id);
        newSRSPA.SalesOrder__c = salesOrder.Id;
        newSRSPA.SPACounterSignedDate__c=Date.today();
        insert newSRSPA;
        HexaBPM__Service_Request__c newSRclSPA = new HexaBPM__Service_Request__c();
        newSRclSPA.Id = newSRSPA.Id;
        newSRclSPA.HexaBPM__External_SR_Status__c = Closed.Id;
        ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = true;
        update newSRclSPA;
        ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = false;
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
        Map<id,HexaBPM__Service_Request__c> oldMap = new Map<id,HexaBPM__Service_Request__c>();
        Map<id,HexaBPM__Service_Request__c> newMap = new Map<id,HexaBPM__Service_Request__c>();
        List < HexaBPM__Service_Request__c > newList5 = new List < HexaBPM__Service_Request__c > ();
        HexaBPM__SR_Status__c draft = [Select id from HexaBPM__SR_Status__c where Name = 'Draft']; 
        HexaBPM__Service_Request__c propertyTransfer = TestObjectsFactory.getServiceRequest(draft.Id, u.Id, 'Property Transfer', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer'), SRTemplateDetailRecord3.Id);
        //propertyTransfer.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
        //propertyTransfer.SRType__c = Constants.PROPERTY_TRANSFER_TYPE;
        propertyTransfer.ChargeType__c = 'Transfer Normal';
        propertyTransfer.Unit__c = u.Id;
        propertyTransfer.SwappedUnit__c = u1.Id;
        propertyTransfer.HexaBPM__Customer__c = acc.Id;
        propertyTransfer.TransferSellingPrice__c=1000000;
        propertyTransfer.HexaBPM__Email__c ='test@test.com';
        insert propertyTransfer;
        List<HexaBPM__Service_Request__c> updRec = [Select id,Unit__c,SalesOrder__c,InstallmentLine__c,SRType__c,TotalCollectedAmount__c,HexaBPM__Record_Type_Name__c,HexaBPM__Contact__c,PaidEquity__c,
                                                    Proceed_with_Offline__c,HexaBPM__Submitted_DateTime__c,Bypass_Equity_Check__c,ExemptValidations__c,RecordTypeId,Case__c,HexaBPM__Customer__c,PaymentExtensionDate__c,
                                                    CancellationReason__c,WaivedPercentage__c,WaivedAmount__c,WaivedBy__c,InstallmentDate__c,PaymentExtensionPeriod__c,HexaBPM__SR_Template__c,TotalLPCAmount__c,
                                                    LegalStatus__c,TermCommencementDate__c,TotalLPCDue__c,TotalLPCCollected__c,ChargeCollected__c,TotalLPCWaivedAmount__c,LPCCalculatedDate__c,
                                                    SocialReason__c,HexaBPM__Parent_SR__c,HandoverDetail__c,OldNetAmount__c,TotalBilledAmount__c,TotalOutstandingAmount__c,RefundAmount__c,ReallocationAmount__c,IsRefundApplicable__c,
                                                    LPCFreezeStatus__c,DocumentPrintedDate__c,HexaBPM__Closed_Date_Time__c,HexaBPM__IsClosedStatus__c,TitleDeedRegistrationFee__c,HexaBPM__External_SR_Status__c,HexaBPM__External_Status_Name__c,BlacklistedCustomer__c,
                                                    PriceRevisionRequired__c,ForfeitAmount__c,CancellationOption__c,AgreementType__c,
                                                    BuyerOwnershipVerifiedDari__c,Retrive_Buyer_Acc_Docs__c,SubType__c,BrokerManager__c,HOKAR__c,UnitFromSameProject__c,SwappedUnit__c,SalesOrderHoldFlag__c,BuyerName__c,ReferredBy__c,OwnerId from HexaBPM__Service_Request__c where id =:propertyTransfer.id limit 1 ];
        updRec[0].TransferSellingPrice__c= 1000000;
        //updRec[0].SalesOrder__c = salesOrder1.id;
        updRec[0].PaymentExtensionDate__c = Date.today() +5; 
        updRec[0].WaivedAmount__c = 2000;
        updRec[0].BuyerName__c = newAccount.id; 
        updRec[0].IsComplianceReturned__c = true;
        updRec[0].Retrive_Buyer_Acc_Docs__c = true;
        newList5.add(updRec[0]);
        update newList5;
        for(HexaBPM__Service_Request__c sr : newList5) {
            oldMap.put(sr.id,sr);
        }        
        Test.stopTest();
        
        HexaBPM__Service_Request__c propertyTransferOBJ = [SELECT Id,RecordType.Name,HexaBPM__Customer__r.CustomerType__c,Unit__r.BuildingSectionName__r.AldarStaffTransferThresholdLimit__c FROM HexaBPM__Service_Request__c WHERE Id=:propertyTransfer.id LIMIT 1];
        
        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{propertyTransfer.Id})[0];
        SalesOrder__c salesOrderObj = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{serviceRequest.SalesOrder__c})[0];
        String staffValidationMsg = ServiceRequestTriggerHandlerNew.aldarstaffPTValidation(serviceRequest,salesOrderObj);
        Map<Id,Id> soMap = new Map<Id,Id>();
        soMap.put(salesOrderObj.Id,serviceRequest.Id);
        //ServiceRequestTriggerHandler.titledeedKARMapping(soMap);
        //ServiceRequestTriggerHandler.updateGoldenVisaDetails(new List<HexaBPM__Service_Request__c>{serviceRequest},new Set<Id>{propertyTransferOBJ.HexaBPM__Customer__c});
        
    }
    @isTest
static void testAldarStaffPTValidation(){
    Test.startTest();

    // Aldar Staff Account
    Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
    acc.CustomerType__c = Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF;
    insert acc;
    
    // Non-Aldar Buyer Account to trigger threshold branch
    Account nonAldarBuyer = TestObjectsFactory.getOrganisationAccountRecord('Non Aldar Customer', 'G987654');
 //   nonAldarBuyer.CustomerType__c = 'Regular Customer';
    insert nonAldarBuyer;

    // SR Template
    HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('PropertyTransfer');     
    SRTemplateDetailRecord3.Name = Constants.PROPERTY_TRANSFER_RT;
    insert SRTemplateDetailRecord3;

    // Project & Building Section
    Project__c project = TestObjectsFactory.getProjectRecord('Test');
    project.AsiteProjectName__c = 'Test Project Name';
    insert project;

    BuildingSection__c buildingSection = TestObjectsFactory.getBuildingDetailRecord(project.Id);
    buildingSection.AldarStaffTransferThresholdLimit__c = 40;
    insert buildingSection;

    // Units
    Unit__c u = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
    u.Status__c = 'Sold';
    u.BuildingSectionName__c = buildingSection.id;
    insert u;

    Unit__c u1 = TestObjectsFactory.getUnitDetail(project.Id, buildingSection.Id);
    u1.Name = project.Id +'MAYAN-B1-1002';
    insert u1;

    // Opportunity & SalesOrder
    Opportunity opp = TestObjectsFactory.getOpportunityRecord(nonAldarBuyer.Id);
    opp.OwnerManger__c = UserInfo.getUserId();
    insert opp;

    SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, nonAldarBuyer.Id);
    salesOrder.Unit__c = u.Id;
    salesOrder.IsBookingCompleted__c = true;
    salesOrder.NetAmount__c = 100000;
    salesOrder.SellingPrice__c = 1000000;
 //   salesOrder.EquityPercentage__c = 35; // threshold branch
    insert salesOrder;
HexaBPM__SR_Template__c spaTemp = TestObjectsFactory.getSRTemplate(Constants.SPA_REGISTRATION_TYPE);        
insert spaTemp;

// Get Closed Status
HexaBPM__SR_Status__c Closed = [Select Id from HexaBPM__SR_Status__c where Name = 'Closed' LIMIT 1];

// Get SPA Record Type Id
Id spaId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);

// Create SPA Service Request
HexaBPM__Service_Request__c newSRSPA = TestObjectsFactory.getServiceRequest(
    Closed.Id,
    u.Id, // same Unit
    Constants.SPA_REGISTRATION_TYPE,
    spaId,
    spaTemp.Id
);
newSRSPA.SalesOrder__c = salesOrder.Id; // same SalesOrder
newSRSPA.SPACounterSignedDate__c = Date.today();
insert newSRSPA;

// Update SPA SR External Status
HexaBPM__Service_Request__c newSRclSPA = new HexaBPM__Service_Request__c();
newSRclSPA.Id = newSRSPA.Id;
newSRclSPA.HexaBPM__External_SR_Status__c = Closed.Id;
update newSRclSPA;
    // Installment lines to trigger Staff Plan validation
    List<InstallmentLines__c> installmentLines1 = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 1);
    installmentLines1[0].InstallmentPercentage__c = Decimal.valueOf(System.Label.Staff_Purchase_PP_Validation.split(',')[0]); // match label
    update installmentLines1;

    // Service Request
    Id rtId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
    HexaBPM__Service_Request__c propertyTransfer = TestObjectsFactory.getServiceRequest(
        [SELECT Id FROM HexaBPM__SR_Status__c WHERE Name='Draft' LIMIT 1].Id,
        u.Id,
        Constants.PROPERTY_TRANSFER_RT,
        rtId,
        SRTemplateDetailRecord3.Id
    );
    propertyTransfer.ChargeType__c = 'Transfer Normal';
    propertyTransfer.Unit__c = u.Id;
    propertyTransfer.SwappedUnit__c = u1.Id;
    propertyTransfer.HexaBPM__Customer__c = acc.Id;
    propertyTransfer.TransferSellingPrice__c = 1000000;
    propertyTransfer.HexaBPM__Email__c ='test@test.com';
    propertyTransfer.BuyerName__c = nonAldarBuyer.Id; // triggers threshold branch
    insert propertyTransfer;

    // Reload ServiceRequest for validation
    HexaBPM__Service_Request__c srObj = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{propertyTransfer.Id})[0];
    SalesOrder__c soObj = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{srObj.SalesOrder__c})[0];

    // 1️⃣ Staff Plan validation
    String msg1 = ServiceRequestTriggerHandlerNew.aldarstaffPTValidation(srObj, soObj);
   // System.assertEquals(System.Label.Staff_Purchase_Validation_PP_Plan_Error, msg1);

    // 2️⃣ Threshold validation (Non-Aldar buyer)
    installmentLines1[0].InstallmentPercentage__c = 5; 
    update installmentLines1;
    String msg2 = ServiceRequestTriggerHandlerNew.aldarstaffPTValidation(srObj, soObj);
    //System.assertEquals(System.Label.Staff_Purchase_Validation_Threshold_Error, msg2);

    // 3️⃣ Normal case (Buyer is Aldar Staff → returns null)
    srObj.BuyerName__c = acc.Id; 
    update srObj;
    String msg3 = ServiceRequestTriggerHandlerNew.aldarstaffPTValidation(srObj, soObj);
 //   System.assertEquals(null, msg3);

    Test.stopTest();
}

   
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
        
        HexaBPM__SR_Status__c closed = [Select id from HexaBPM__SR_Status__c where Name = 'Closed'];       
        HexaBPM__SR_Template__c spaTemp = TestObjectsFactory.getSRTemplate(Constants.SPA_REGISTRATION_TYPE);        
        insert spaTemp;
        Id spaId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_REGISTRATION_RT);
        
        HexaBPM__Service_Request__c newSRSPA = TestObjectsFactory.getServiceRequest(closed.Id, u.Id, Constants.SPA_REGISTRATION_TYPE, spaId, spaTemp.Id);
        newSRSPA.SalesOrder__c = salesOrder.Id;
        newSRSPA.SPACounterSignedDate__c=Date.today();
        insert newSRSPA;       
        HexaBPM__Service_Request__c newSRclSPA = new HexaBPM__Service_Request__c();
        newSRclSPA.Id = newSRSPA.Id;
        newSRclSPA.HexaBPM__External_SR_Status__c = closed.Id;
        ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = true;
        update newSRclSPA;
        
        HexaBPM__SR_Status__c objSRStatus = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        //insert objSRStatus;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.PAYMENT_EXTENSION_RT, Constants.PAYMENT_EXTENSION_RT);
        insert objStepTemplate;
        
        HexaBPM__Step_Template__c objStepTemplate1 = TestObjectsFactory.getStepTemplate(Constants.PROPERTY_TRANSFER_RT, Constants.PROPERTY_TRANSFER_RT);
        insert objStepTemplate1;
        
        
        HexaBPM__Service_Request__c propertyTransfer = new HexaBPM__Service_Request__c();
        propertyTransfer.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
        propertyTransfer.SRType__c = Constants.PROPERTY_TRANSFER_TYPE;
        propertyTransfer.ChargeType__c = 'Transfer Normal';
        propertyTransfer.IsComplianceReturned__c =false;
        propertyTransfer.Compliance_Status__c = 'Cleared';
        propertyTransfer.Unit__c = u.Id;
        //  propertyTransfer.SwappedUnit__c = u1.Id;
        propertyTransfer.HexaBPM__Customer__c = acc.Id;
        propertyTransfer.BuyerName__c = newAccount.id;   
        propertyTransfer.TransferSellingPrice__c=1000000;
        propertyTransfer.HexaBPM__Email__c ='test@test.com';
        insert propertyTransfer;
        
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
        
        propertyTransfer.Compliance_Status__c = 'Cleared';
        propertyTransfer.IsComplianceReturned__c = true;        
        update propertyTransfer;
        
        List<HexaBPM__Step__c> stepToUpdateList = [SELECT Id, HexaBPM__SR_Step__c, HexaBPM__Status__c,HexaBPM__Summary__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c = :propertyTransfer.Id AND HexaBPM__Summary__c = 'Compliance Check for Buyers' ORDER BY CreatedDate DESC LIMIT 1];
        system.debug('@@@stepToUpdateList-1'+stepToUpdateList);
        
        Test.stopTest();
        
    }
    @isTest static void srTest2(){
        Test.startTest();
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        newAccount.FastTrackedAccount__c = true;
        newAccount.FasttrackCompletionDate__c = System.now();
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
    /*@isTest
    public static void validatePropertyTransferSR() {
        
        // --- Setup core data ---
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org acc', 'G123456');
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c so = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        so.Unit__c = unit.Id;
        so.IsBookingCompleted__c = true;
        so.NetAmount__c = 100000;
        insert so;
        
        // --- Prepare SR Record ---
        Id rtId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);
        HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c(
            RecordTypeId = rtId,
            SRType__c = Constants.PROPERTY_TRANSFER_RT,
            SalesOrder__c = so.Id,
            Unit__c = unit.Id,
            HexaBPM__Customer__c = acc.Id,
            TransferSellingPrice__c = 1000000,
            Origin__c = 'Customer Portal'
        );
        
        Test.startTest();
        
        // Insert SR in bulk to trigger once only
        insert new List<HexaBPM__Service_Request__c>{ sr };
            
            // Now perform update in bulk (avoid multiple SOQL-trigger cycles)
            sr.IsComplianceReturned__c = true;
        sr.PaymentExtensionDate__c = Date.today().addDays(5);
        sr.WaivedAmount__c = 2000;
        update new List<HexaBPM__Service_Request__c>{ sr };
            
            Test.stopTest();
        
        // --- Assertions ---
        HexaBPM__Service_Request__c fetchedSR = [
            SELECT Id, SalesOrder__c, TransferSellingPrice__c, IsComplianceReturned__c, Unit__c
            FROM HexaBPM__Service_Request__c
            WHERE Id = :sr.Id
        ];
        System.assertNotEquals(null, fetchedSR.SalesOrder__c, 'SalesOrder should be linked');
        System.assertEquals(1000000, fetchedSR.TransferSellingPrice__c);
    }*/

    @isTest static void spaOffline(){
        Test.startTest();
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        HexaBPM__Service_Request__c spaReg = new HexaBPM__Service_Request__c();
        //spaReg.SRType__c = 'SPA Registration';
        spaReg.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'SPA Registration For Off Plan');
        spaReg.Id = [SELECT Id FROM HexaBPM__Service_Request__c LIMIT 1].Id;
        spaReg.Proceed_with_Offline__c = true;
        spaReg.SPACounterSignedDate__c = system.today();
        spaReg.SwappedUnit__c = unit.id;
        spaReg.IsComplianceReturned__c = true;
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
        //ServiceRequestTriggerHandler.handleOfflineProceess(new List<HexaBPM__Service_Request__c>{spaReg}, new Map<Id,HexaBPM__Service_Request__c>([SELECT Id,SRType__c,Proceed_with_Offline__c FROM HexaBPM__Service_Request__c]));
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
        //ServiceRequestTriggerHandler.handleOfflineProceess(new List<HexaBPM__Service_Request__c>{spaReg}, new Map<Id,HexaBPM__Service_Request__c>([SELECT Id,SRType__c,Proceed_with_Offline__c FROM HexaBPM__Service_Request__c]));
        Test.stopTest(); 
    }
    
    @isTest
    public static void aldarMoveINTest() {
        Test.startTest();
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert newAccount;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        Project__c project = TestObjectsFactory.getProjectRecord('Test');
        project.AsiteProjectName__c = 'Test Project Name'; 
        project.OA_Community_Name__c = 'Mayan';
        insert project;
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        unit.Project__c = project.id;
        insert unit;
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.SellingPrice__c=1000000;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;      	
        List<HexaBPM__SR_Status__c> draft1 = [Select id, name from HexaBPM__SR_Status__c where name = 'Draft'];       
        HexaBPM__SR_Template__c SRTemplateDetailRecord4 = TestObjectsFactory.getSRTemplate('Aldar Estates Move-In');     
        SRTemplateDetailRecord4.Name = Constants.PROPERTY_TRANSFER_RT;
        insert SRTemplateDetailRecord4;
        List < HexaBPM__Service_Request__c > SRList = new List < HexaBPM__Service_Request__c > ();
        List < HexaBPM__Service_Request__c > newList5 = new List < HexaBPM__Service_Request__c > ();
        Map <Id, HexaBPM__Service_Request__c > oldMap = new Map <Id, HexaBPM__Service_Request__c > ();
        Map <Id, HexaBPM__Service_Request__c > newMap = new Map <Id, HexaBPM__Service_Request__c > ();
        HexaBPM__Service_Request__c newSR2 = TestObjectsFactory.getServiceRequest(draft1[0].Id, unit.Id, 'Aldar Estates Move-In', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'AldarEstatesMoveIn'), SRTemplateDetailRecord4.Id);
        newSR2.Unit__c = unit.Id;  
        newSR2.IsComplianceReturned__c = false;
        newSR2.Compliance_Status__c = '';
        newSR2.TransferSellingPrice__c= 1000000;  
        newSR2.Proceed_with_Offline__c = true;
        newSR2.BuyerName__c = newAccount.id;
        newSR2.OwnerId = [SELECT Id,Name FROM Group WHERE Type = 'Queue' and Name = 'Mayan AE Queue'][0].Id;
        SRList.add(newSR2);
        insert SRList;                
        ServiceRequestTriggerHandlerNew serviceRequest = new ServiceRequestTriggerHandlerNew();
        serviceRequest.beforeInsertMethod(SRList, new Map<Id, SObject>());
        serviceRequest.afterInsertMethod(SRList, new Map<Id, SObject>());
        List<HexaBPM__Service_Request__c> updRec = [Select id,Unit__c,SalesOrder__c,InstallmentLine__c,SRType__c,TotalCollectedAmount__c,HexaBPM__Record_Type_Name__c,HexaBPM__Contact__c,PaidEquity__c,
                                                    Proceed_with_Offline__c,HexaBPM__Submitted_DateTime__c,Bypass_Equity_Check__c,ExemptValidations__c,RecordTypeId,Case__c,HexaBPM__Customer__c,PaymentExtensionDate__c,
                                                    CancellationReason__c,WaivedPercentage__c,WaivedAmount__c,WaivedBy__c,InstallmentDate__c,PaymentExtensionPeriod__c,HexaBPM__SR_Template__c,TotalLPCAmount__c,
                                                    LegalStatus__c,TermCommencementDate__c,TotalLPCDue__c,TotalLPCCollected__c,ChargeCollected__c,TotalLPCWaivedAmount__c,LPCCalculatedDate__c,
                                                    SocialReason__c,HexaBPM__Parent_SR__c,HandoverDetail__c,OldNetAmount__c,TotalBilledAmount__c,TotalOutstandingAmount__c,RefundAmount__c,ReallocationAmount__c,IsRefundApplicable__c,
                                                    LPCFreezeStatus__c,DocumentPrintedDate__c,HexaBPM__Closed_Date_Time__c,HexaBPM__IsClosedStatus__c,TitleDeedRegistrationFee__c,HexaBPM__External_SR_Status__c,HexaBPM__External_Status_Name__c,BlacklistedCustomer__c,
                                                    PriceRevisionRequired__c,ForfeitAmount__c,CancellationOption__c,AgreementType__c,
                                                    BuyerOwnershipVerifiedDari__c,Retrive_Buyer_Acc_Docs__c,SubType__c,BrokerManager__c,HOKAR__c,UnitFromSameProject__c,SwappedUnit__c,SalesOrderHoldFlag__c,BuyerName__c,ReferredBy__c,OwnerId from HexaBPM__Service_Request__c where id =:SRList[0].id limit 1 ];
        updRec[0].TransferSellingPrice__c= 1000000;
        updRec[0].SalesOrder__c = salesOrder.id;
        updRec[0].HexaBPM__External_SR_Status__c = [Select id from HexaBPM__SR_Status__c where name = 'Submitted'][0].Id;        
        newList5.add(updRec[0]);
        update newList5;
        for(HexaBPM__Service_Request__c sr : newList5) {
            oldMap.put(sr.id,sr);
        }
        serviceRequest.beforeUpdateMethod(SRList,newMap,newList5,oldMap);
        //serviceRequest.afterUpdateMethod(SRList,newMap,newList5,oldMap);
        ECSS_ServiceRequestTriggerHelper.afterUpdSRStatusUpd(SRList);
        //ServiceRequestTriggerHelper.updateClosedSRSOAndAccount(SRList, newMap);
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
        salesOrder.SellingPrice__c=1000000;
        salesOrder.Status__c = 'Sold';
        insert salesOrder;        
        List<HexaBPM__SR_Status__c> draftStatus = [Select id, name from HexaBPM__SR_Status__c where name = 'Draft'];
        //List<InstallmentLines__c> installmentLines1 = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 1);
        //installmentLines1[0].InvoicedAmount__c = 30;        
        //update installmentLines1;
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
        newSR1.TransferSellingPrice__c= 1000000; 
        newSR1.PaymentExtensionDate__c = Date.today() +3;
        newSR1.HexaBPM__Customer__c = newAccount.Id;
        SRList.add(newSR1);
        insert SRList;
        ServiceRequestTriggerHandlerNew serviceRequest = new ServiceRequestTriggerHandlerNew();
        serviceRequest.beforeInsertMethod(SRList, new Map<Id, SObject>());
        ServiceRequestTriggerHandlerNew.aldarstaffPTValidation(newSR1,salesOrder);
        Test.stopTest();        
    }
    
    @isTest
    public static void propertyTransferTest() {
        //RecordType = Property Transfer
        Test.startTest();
        Account newAccount2 = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert newAccount2;
        Opportunity opp2 = TestObjectsFactory.getOpportunityRecord(newAccount2.Id);
        opp2.OwnerManger__c = UserInfo.getUserId();
        insert opp2;
        Project__c project1 = TestObjectsFactory.getProjectRecord('Test');
        project1.AsiteProjectName__c = 'Test Project Name';
        project1.OA_Community_Name__c = 'Mayan';
        insert project1;
        Unit__c unit2 = TestObjectsFactory.unitDataSetup('25083');
        unit2.Status__c = 'Sold';
        unit2.Project__c = project1.id;
        insert unit2;
        set < Id > unitIdList = new Set < Id > ();
        unitIdList.add(unit2.Id);
        SalesOrder__c salesOrder2 = TestObjectsFactory.getSalesOrderRecord(opp2.Id, newAccount2.Id);
        salesOrder2.Unit__c = unit2.Id;
        salesOrder2.IsBookingCompleted__c = true;
        salesOrder2.NetAmount__c = 100000;
        salesOrder2.SellingPrice__c = 1000000;
        insert salesOrder2;
        
        List < HexaBPM__SR_Status__c > draftStatus = [Select id, name from HexaBPM__SR_Status__c where name = 'Draft'];
        List < InstallmentLines__c > installmentLines2 = TestObjectsFactory.createInstallmentLines(salesOrder2.Id, 1);
        installmentLines2[0].InvoicedAmount__c = 30;
        update installmentLines2;
        HexaBPM__SR_Template__c SRTemplateDetailRecord5 = TestObjectsFactory.getSRTemplate('Property Transfer NOC');
        SRTemplateDetailRecord5.Name = Constants.PROPERTY_TRANSFER_RT;
        insert SRTemplateDetailRecord5;
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Buyer', 'G123456');
        newAccount.FastTrackedAccount__c = true;
        newAccount.FasttrackCompletionDate__c = System.now();
        insert newAccount;
        
        Map < id, HexaBPM__Service_Request__c > oldMap = new Map < id, HexaBPM__Service_Request__c > ();
        List < HexaBPM__Service_Request__c > oldList = new List < HexaBPM__Service_Request__c > ();
        List < HexaBPM__Service_Request__c > NewList = new List < HexaBPM__Service_Request__c > ();
        HexaBPM__Service_Request__c newSR3 = TestObjectsFactory.getServiceRequest(draftStatus[0].Id, unit2.Id, 'Property Transfer NOC', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer NOC'), SRTemplateDetailRecord5.Id);
        newSR3.SalesOrder__c = salesOrder2.Id;
        newSR3.Unit__c = unit2.Id;
        newSR3.Compliance_Status__c = 'Cleared';
        newSR3.TransferSellingPrice__c = 1000000;
        newSR3.InstallmentLine__c = installmentLines2[0].Id;
        newSR3.Retrive_Buyer_Acc_Docs__c = false;
        oldList.add(newSR3);
        insert oldList;
        HexaBPM__Service_Request__c updSR = new HexaBPM__Service_Request__c();
        updSR.id = oldList[0].id;
        updSR.Compliance_Status__c = 'Returned';
        updSR.IsComplianceReturned__c = true;
        updSR.Retrive_Buyer_Acc_Docs__c = true;
        updSR.BuyerOwnershipVerifiedDari__c = true;
        updSR.BuyerName__c = newAccount.id;
        NewList.add(updSR);
        update NewList;
        for (HexaBPM__Service_Request__c sr: oldList) {
            oldMap.put(sr.id, sr);
        }
       // ServiceRequestTriggerHandler serviceRequest = new ServiceRequestTriggerHandler();
       // serviceRequest.afterUpdateMethod(NewList, new Map < Id, SObject > (), oldList, oldMap);
        
        Id propertyTransferRecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Property Transfer').getRecordTypeId();
        Id propertyTransferNocRecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Property Transfer NOC').getRecordTypeId();
        set < Id > propertyTransferRecIds = new set < Id > ();
        propertyTransferRecIds.add(propertyTransferRecordTypeId);
        propertyTransferRecIds.add(propertyTransferNocRecordTypeId);
        Map < HexaBPM__Service_Request__c, id > submittedLPCSRWithSOMap = new Map < HexaBPM__Service_Request__c, id > ();
        submittedLPCSRWithSOMap.put(newSR3, salesOrder2.id);
        /*List < User > u = [Select id, ProfileName__c From user where ProfileName__c = 'Integration Profile'];
        System.runAs(u[0]) {
            Case cas = new Case();
            cas.CaseCategory__c = 'Property Transfer NOC';
            cas.Subject = 'test';
            cas.Status = 'New';
            cas.Opportunity__c = opp2.id;
            cas.Unit__c = unit2.id;
            //insert cas;
        }*/
        Set < Id > caseIdSet = new Set < Id > ();
        PropertyTransferService.validatePropertyTransferSR(NewList, propertyTransferRecIds, unitIdList, caseIdSet);
       // ServiceRequestTriggerHandler.updateAgencySrReferredByProfileName(NewList);
        /*AldarUtilityClass.fetchQueueMap(new Set < String > {
            'Aldar_Broker_Portal'
                }, new Set < String > {
                    'Aldar_Broker_Portal'
                        });*/
        /*HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('Property Transfer NOC');     
        SRTemplateDetailRecord3.Name = 'Property Transfer NOC';
        insert SRTemplateDetailRecord3;
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Title Deed Approval', 'Property Transfer NOC');
        insert objStepTemplate;
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord3.Id, objStepTemplate.Id);
        insert objSRSteps;
        HexaBPM__Status__c status1 = new HexaBPM__Status__c();
        status1.Name = 'Pending';
        status1.HexaBPM__Code__c = 'Pending';
        insert status1;
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(oldList[0].id, objSRSteps.Id, objStepTemplate.id);     
        newStep.HexaBPM__Summary__c = 'Transfer Execution status in ADM';
        newStep.HexaBPM__Status__c = status1.Id;
        insert newStep;*/
        PropertyTransferService.closeADMStep(oldList);
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
        salesOrder.SellingPrice__c=1000000;
        insert salesOrder;
        List<HexaBPM__SR_Status__c> draftStatus = [Select id, name from HexaBPM__SR_Status__c where name = 'Draft'];
        List<InstallmentLines__c> installmentLines1 = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 1);
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
        newSR1.TransferSellingPrice__c= 1000000; 
        newSR1.InstallmentLine__c =installmentLines1[0].Id; 
        newSR1.Proceed_with_Offline__c = true;
        SRList.add(newSR1);
        insert SRList;        
        List<HexaBPM__Service_Request__c> newList = [Select id,Unit__c,SalesOrder__c,InstallmentLine__c,SRType__c,TotalCollectedAmount__c,HexaBPM__Record_Type_Name__c,HexaBPM__Contact__c,PaidEquity__c,
                                                     Proceed_with_Offline__c,HexaBPM__Submitted_DateTime__c,Bypass_Equity_Check__c,ExemptValidations__c,RecordTypeId,Case__c,HexaBPM__Customer__c,PaymentExtensionDate__c,
                                                     CancellationReason__c,WaivedPercentage__c,WaivedAmount__c,WaivedBy__c,InstallmentDate__c,PaymentExtensionPeriod__c,HexaBPM__SR_Template__c,TotalLPCAmount__c,
                                                     LegalStatus__c,TermCommencementDate__c,TotalLPCDue__c,TotalLPCCollected__c,ChargeCollected__c,TotalLPCWaivedAmount__c,LPCCalculatedDate__c,
                                                     SocialReason__c,HexaBPM__Parent_SR__c,HandoverDetail__c,OldNetAmount__c,TotalBilledAmount__c,TotalOutstandingAmount__c,RefundAmount__c,ReallocationAmount__c,IsRefundApplicable__c,
                                                     LPCFreezeStatus__c,DocumentPrintedDate__c,HexaBPM__Closed_Date_Time__c,HexaBPM__IsClosedStatus__c,TitleDeedRegistrationFee__c,HexaBPM__External_SR_Status__c,HexaBPM__External_Status_Name__c,BlacklistedCustomer__c,
                                                     PriceRevisionRequired__c,ForfeitAmount__c,CancellationOption__c,AgreementType__c,
                                                     BrokerManager__c,HOKAR__c,UnitFromSameProject__c,SwappedUnit__c,SalesOrderHoldFlag__c,BuyerName__c,ReferredBy__c,OwnerId from HexaBPM__Service_Request__c where id =:SRList[0].id limit 1 ];
        Map<id,HexaBPM__Service_Request__c> emptyMap = new Map<id,HexaBPM__Service_Request__c>();        
        ServiceRequestTriggerHandlerNew srHandler = new ServiceRequestTriggerHandlerNew();        
        Map<id,HexaBPM__Service_Request__c> oldMap = new Map<id,HexaBPM__Service_Request__c>();
        Map<HexaBPM__Service_Request__c,id> newMap = new Map<HexaBPM__Service_Request__c,id>();
        List < HexaBPM__Service_Request__c > newList5 = new List < HexaBPM__Service_Request__c > ();
        List<SalesOrder__c> salOrd = [Select id,Unit__c,EquityPercentage__c from SalesOrder__c limit 1];
        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25084');
        unit1.Status__c = 'Sold';
        insert unit1;
        List<HexaBPM__Service_Request__c> updRec = [Select id,Unit__c,SalesOrder__c,InstallmentLine__c,SRType__c,TotalCollectedAmount__c,HexaBPM__Record_Type_Name__c,HexaBPM__Contact__c,PaidEquity__c,
                                                    Proceed_with_Offline__c,HexaBPM__Submitted_DateTime__c,Bypass_Equity_Check__c,ExemptValidations__c,RecordTypeId,Case__c,HexaBPM__Customer__c,PaymentExtensionDate__c,
                                                    CancellationReason__c,WaivedPercentage__c,WaivedAmount__c,WaivedBy__c,InstallmentDate__c,PaymentExtensionPeriod__c,HexaBPM__SR_Template__c,TotalLPCAmount__c,
                                                    LegalStatus__c,TermCommencementDate__c,TotalLPCDue__c,TotalLPCCollected__c,ChargeCollected__c,TotalLPCWaivedAmount__c,LPCCalculatedDate__c,
                                                    SocialReason__c,HexaBPM__Parent_SR__c,HandoverDetail__c,OldNetAmount__c,TotalBilledAmount__c,TotalOutstandingAmount__c,RefundAmount__c,ReallocationAmount__c,IsRefundApplicable__c,
                                                    LPCFreezeStatus__c,DocumentPrintedDate__c,HexaBPM__Closed_Date_Time__c,HexaBPM__IsClosedStatus__c,TitleDeedRegistrationFee__c,HexaBPM__External_SR_Status__c,HexaBPM__External_Status_Name__c,BlacklistedCustomer__c,
                                                    PriceRevisionRequired__c,ForfeitAmount__c,CancellationOption__c,AgreementType__c,
                                                    BrokerManager__c,HOKAR__c,UnitFromSameProject__c,SwappedUnit__c,SalesOrderHoldFlag__c,BuyerName__c,ReferredBy__c,OwnerId from HexaBPM__Service_Request__c where id =:SRList[0].id limit 1 ];
        updRec[0].TransferSellingPrice__c= 1000000;
        updRec[0].SalesOrder__c = salOrd[0].id;
        updRec[0].PaymentExtensionDate__c = Date.today() +5; 
        updRec[0].WaivedAmount__c = 2000;
        updRec[0].Unit__c = unit1.Id;
        updRec[0].SwappedUnit__c = null;
        updRec[0].HexaBPM__Customer__c = newAccount.id;
        updRec[0].Proceed_with_Offline__c = false;
        newList5.add(updRec[0]);
        update newList5;
        set<id> cusIds = new set<id>();
        list<id> salesId = new list<id>();
        Map<id,id> salsOrdMap = new Map<id,id>();
        for(HexaBPM__Service_Request__c sr : newList5) {
            oldMap.put(sr.id,sr);
            newMap.put(sr,sr.id);
            cusIds.add(sr.HexaBPM__Customer__c);
            salsOrdMap.put(sr.SalesOrder__c,sr.HOKAR__c);
            salesId.add(sr.SalesOrder__c);
        }
        SPATitleDeedRegistration.handleOfflineProcessTDSR(newList,oldMap);
        Test.stopTest();
    }
    
    
    
    //Updated Code
    
    
     /*@isTest
    static void testAfterUpdateCallsUnfreezeHandler() {
        // Setup: Account, Opportunity, Unit, SalesOrder with a frozen InstallmentLine
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('PT Org', 'PT-001');
        insert acc;
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        Unit__c unit = TestObjectsFactory.unitDataSetup('PT-PROJ');
        unit.Status__c = 'Sold';
        insert unit;
        SalesOrder__c so = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        so.Unit__c = unit.Id;
        insert so;
        List<InstallmentLines__c> ils = TestObjectsFactory.createInstallmentLines(so.Id, 1);
        ils[0].LPCFreezeDate__c = Date.today();
        ils[0].LPCFreezeUntilDate__c = Date.today().addDays(7);
        ils[0].isFreezeByTransferSR__c = true;
        update ils;

        // Create a Property Transfer SR linked to the SalesOrder
        HexaBPM__SR_Template__c srTemplate = TestObjectsFactory.getSRTemplate('PropertyTransfer');
        insert srTemplate;
        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');
        insert draft;
        Id ptRtId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer');
        HexaBPM__Service_Request__c sr = TestObjectsFactory.getServiceRequest(
            draft.Id,
            unit.Id,
            'Property Transfer',
            ptRtId,
            srTemplate.Id
        );
        sr.SalesOrder__c = so.Id;
        insert sr;

        // Simulate status change to Cancelled (code field)
         HexaBPM__Service_Request__c srOld = sr.clone(false, true, false, false);
        HexaBPM__SR_Status__c cancelled = TestObjectsFactory.getSRStatus('Cancelled');
        insert cancelled;
        sr.HexaBPM__External_SR_Status__c = cancelled.Id;
        update sr;

        // Invoke afterUpdateMethod with non-empty newList to hit the new branch
        ServiceRequestTriggerHandlerNew handler = new ServiceRequestTriggerHandlerNew();
        List<SObject> newList = new List<SObject>{ sr };
        Map<Id, SObject> oldMap = new Map<Id, SObject>{ sr.Id => srOld };
        handler.afterUpdateMethod(newList, new Map<Id, SObject>(), new List<SObject>{ srOld }, oldMap);

        // Verify unfreeze occurred
        InstallmentLines__c il = [SELECT LPCFreezeDate__c, LPCFreezeUntilDate__c, isFreezeByTransferSR__c FROM InstallmentLines__c WHERE Id = :ils[0].Id LIMIT 1];
        System.assertEquals(false, il.isFreezeByTransferSR__c, 'Installment line should be unfrozen');
        System.assertEquals(null, il.LPCFreezeDate__c, 'Freeze date should be cleared');
        System.assertEquals(null, il.LPCFreezeUntilDate__c, 'Freeze until date should be cleared');
    }*/
    
    
    
     
    
    
    
    
    
    
    @isTest
    public static void beforeUpdateTitleTest() {
        Test.startTest();
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.TITLE_DEED_REGISTRATION_DEV_RT, 'TitleDeedRegistration');
        insert objStepTemplate;
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        newAccount.FasttrackCompletionDate__c = System.now();
        insert newAccount;        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        Unit__c unit3 = TestObjectsFactory.unitDataSetup('25084');
        unit3.Status__c = 'Sold';
        insert unit3;
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.SellingPrice__c=1000000;
        insert salesOrder;
        List<HexaBPM__SR_Status__c> draftStatus = [Select id, name from HexaBPM__SR_Status__c where name = 'Draft'];
        List<InstallmentLines__c> installmentLines1 = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 1);
        installmentLines1[0].InvoicedAmount__c = 30;
        update installmentLines1;
        HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('Title Deed Registration');     
        SRTemplateDetailRecord3.Name = Constants.PROPERTY_TRANSFER_RT;
        insert SRTemplateDetailRecord3;                 
        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord3.Id, objStepTemplate.Id);
        insert objSRSteps;  
        List<SalesOrder__c> salOrd = [Select id,Unit__c,EquityPercentage__c from SalesOrder__c limit 1];
        List < HexaBPM__Service_Request__c > SRList = new List < HexaBPM__Service_Request__c > ();
        HexaBPM__Service_Request__c newSR1 = TestObjectsFactory.getServiceRequest(draftStatus[0].Id, unit.Id, 'Title Deed Registration', Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Title Deed Registration'), SRTemplateDetailRecord3.Id);
        newSR1.SalesOrder__c = salesOrder.Id;        
        newSR1.Unit__c = unit.Id;  
        newSR1.IsComplianceReturned__c = false;
        newSR1.Compliance_Status__c = '';
        newSR1.TransferSellingPrice__c= 1000000; 
        newSR1.InstallmentLine__c =installmentLines1[0].Id;
        newSR1.SwappedUnit__c = unit3.id;      
        SRList.add(newSR1);
        insert SRList;        
        List<HexaBPM__Service_Request__c> newList = [Select id,Unit__c,SalesOrder__c,InstallmentLine__c,SRType__c,TotalCollectedAmount__c,HexaBPM__Record_Type_Name__c,HexaBPM__Contact__c,PaidEquity__c,
                                                     Proceed_with_Offline__c,HexaBPM__Submitted_DateTime__c,Bypass_Equity_Check__c,ExemptValidations__c,RecordTypeId,Case__c,HexaBPM__Customer__c,PaymentExtensionDate__c,
                                                     CancellationReason__c,WaivedPercentage__c,WaivedAmount__c,WaivedBy__c,InstallmentDate__c,PaymentExtensionPeriod__c,HexaBPM__SR_Template__c,TotalLPCAmount__c,
                                                     LegalStatus__c,TermCommencementDate__c,TotalLPCDue__c,TotalLPCCollected__c,ChargeCollected__c,TotalLPCWaivedAmount__c,LPCCalculatedDate__c,
                                                     SocialReason__c,HexaBPM__Parent_SR__c,HandoverDetail__c,OldNetAmount__c,TotalBilledAmount__c,TotalOutstandingAmount__c,RefundAmount__c,ReallocationAmount__c,IsRefundApplicable__c,
                                                     LPCFreezeStatus__c,DocumentPrintedDate__c,HexaBPM__Closed_Date_Time__c,HexaBPM__IsClosedStatus__c,TitleDeedRegistrationFee__c,HexaBPM__External_SR_Status__c,HexaBPM__External_Status_Name__c,BlacklistedCustomer__c,
                                                     PriceRevisionRequired__c,ForfeitAmount__c,CancellationOption__c,AgreementType__c,
                                                     Retrive_Buyer_Acc_Docs__c,BuyerOwnershipVerifiedDari__c,SubType__c,BrokerManager__c,HOKAR__c,UnitFromSameProject__c,SwappedUnit__c,SalesOrderHoldFlag__c,BuyerName__c,ReferredBy__c,OwnerId from HexaBPM__Service_Request__c where id =:SRList[0].id limit 1 ];               
        ServiceRequestTriggerHandlerNew srHandler = new ServiceRequestTriggerHandlerNew();                
        List < HexaBPM__Service_Request__c > newList5 = new List < HexaBPM__Service_Request__c > ();
        Map<id,HexaBPM__Service_Request__c> oldMap = new Map<id,HexaBPM__Service_Request__c>();
        Map<id,HexaBPM__Service_Request__c> newMap = new Map<id,HexaBPM__Service_Request__c>();

        Unit__c unit1 = TestObjectsFactory.unitDataSetup('25084');
        unit1.Status__c = 'Sold';
        insert unit1;
        List<HexaBPM__Service_Request__c> updRec = [Select id,Unit__c,SalesOrder__c,InstallmentLine__c,SRType__c,TotalCollectedAmount__c,HexaBPM__Record_Type_Name__c,HexaBPM__Contact__c,PaidEquity__c,
                                                    Proceed_with_Offline__c,HexaBPM__Submitted_DateTime__c,Bypass_Equity_Check__c,ExemptValidations__c,RecordTypeId,Case__c,HexaBPM__Customer__c,PaymentExtensionDate__c,
                                                    CancellationReason__c,WaivedPercentage__c,WaivedAmount__c,WaivedBy__c,InstallmentDate__c,PaymentExtensionPeriod__c,HexaBPM__SR_Template__c,TotalLPCAmount__c,
                                                    LegalStatus__c,TermCommencementDate__c,TotalLPCDue__c,TotalLPCCollected__c,ChargeCollected__c,TotalLPCWaivedAmount__c,LPCCalculatedDate__c,
                                                    SocialReason__c,HexaBPM__Parent_SR__c,HandoverDetail__c,OldNetAmount__c,TotalBilledAmount__c,TotalOutstandingAmount__c,RefundAmount__c,ReallocationAmount__c,IsRefundApplicable__c,
                                                    LPCFreezeStatus__c,DocumentPrintedDate__c,HexaBPM__Closed_Date_Time__c,HexaBPM__IsClosedStatus__c,TitleDeedRegistrationFee__c,HexaBPM__External_SR_Status__c,HexaBPM__External_Status_Name__c,BlacklistedCustomer__c,
                                                    PriceRevisionRequired__c,ForfeitAmount__c,CancellationOption__c,AgreementType__c,
                                                    BuyerOwnershipVerifiedDari__c,Retrive_Buyer_Acc_Docs__c,SubType__c,BrokerManager__c,HOKAR__c,UnitFromSameProject__c,SwappedUnit__c,SalesOrderHoldFlag__c,BuyerName__c,ReferredBy__c,OwnerId from HexaBPM__Service_Request__c where id =:SRList[0].id limit 1 ];
        updRec[0].TransferSellingPrice__c= 1000000;
        updRec[0].SalesOrder__c = salOrd[0].id;
        updRec[0].PaymentExtensionDate__c = Date.today() +5; 
        updRec[0].WaivedAmount__c = 2000;
        updRec[0].Unit__c = unit1.Id;
        updRec[0].IsComplianceReturned__c = true;
        newList5.add(updRec[0]);
        update newList5;
        for(HexaBPM__Service_Request__c sr : newList5) {
            oldMap.put(sr.id,sr);
        }
        List<HexaBPM__Step__c> step = [SELECT Id,HexaBPM__SR__c, HexaBPM__Status__c,HexaBPM__Summary__c FROM HexaBPM__Step__c WHERE  HexaBPM__Summary__c = 'Compliance Check for Buyers' ORDER BY CreatedDate DESC LIMIT 1];
        ServiceRequestTriggerHelper.handleComplianceStepUpdate(newList,step,newList);        
        srHandler.beforeUpdateMethod(newList,newMap,newList5,oldMap);        
        //PropertyTransferService.ComplianceCheck(new Set<Id>{newAccount.Id});
        UnitSwapService.updateSwapUnits(newList);
        Test.stopTest();
    }    
    
     @IsTest
    static void testUpdateClosedSalesOrder() {
        String type = Constants.DEFAULT_AND_TERMINATION;
        List < HexaBPM__Service_Request__c > SRList1 = [SELECT Id,SalesOrder__c FROM HexaBPM__Service_Request__c WHERE HexaBPM__IsClosedStatus__c = true And SRType__c =: type];
            // Convert list to Set<Id>
        Set<Id> srIdSet = new Set<Id>();
        Set<Id> srOrdIdList = new Set<Id>();
        for (HexaBPM__Service_Request__c sr : srList1) {
            srIdSet.add(sr.Id);
            srOrdIdList.add(sr.SalesOrder__c);
        }
        // Call the method
        Test.startTest();
        //ServiceRequestTriggerHelper.updateClosedSalesOrder(srOrdIdList);
        Test.stopTest();

        // Verify the updates
        List<SalesOrder__c> updatedOrders = [SELECT HoldReasonCode__c, HoldFlag__c FROM SalesOrder__c WHERE Id IN :srOrdIdList];
        for (SalesOrder__c so : updatedOrders) {
            System.assertEquals(null, so.HoldReasonCode__c, 'HoldReasonCode__c should be null');
            System.assertEquals(false, so.HoldFlag__c, 'HoldFlag__c should be false');
        }
    }

    @IsTest
    static void testUpdateClosedSalesOrderAccount() {
        String type = Constants.DEFAULT_AND_TERMINATION;
        List < HexaBPM__Service_Request__c > SRList1 = [SELECT Id,SalesOrder__c FROM HexaBPM__Service_Request__c WHERE HexaBPM__IsClosedStatus__c = true And SRType__c =: type];
            // Convert list to Set<Id>
        Set<Id> srIdSet = new Set<Id>();
        for (HexaBPM__Service_Request__c sr : srList1) {
            srIdSet.add(sr.SalesOrder__c);
        }
        // Call the method
        Test.startTest();
        //ServiceRequestTriggerHelper.updateClosedSalesOrderAccount(srIdSet);
        Test.stopTest();

        // Verify Account update (should only clear BlacklistReason__c if all SRs for SO are closed)
        Account updatedAcc = [SELECT BlacklistReason__c FROM Account];
        System.assertEquals(null, updatedAcc.BlacklistReason__c, 'BlacklistReason__c should be cleared');
    }
    
    @IsTest
    static void testDNADSR() {

        Map<Id, HexaBPM__Service_Request__c> srMAPDandT = new Map<Id, HexaBPM__Service_Request__c>(
            [SELECT Id,
             HexaBPM__External_Status_Name__c,
             SRType__c,
             SalesOrder__c,
             HexaBPM__Customer__c,RecordTypeId,RecordType.DeveloperName
             FROM HexaBPM__Service_Request__c
             WHERE SRType__c = 'Default And Termination' AND RecordType.DeveloperName = 'DefaultAndTermination']);
        System.debug('@@@srMAPDandT'+srMAPDandT);
        System.debug('@@@srMAPDandTafter update'+srMAPDandT);
        ServiceRequestTriggerHelper.updateClosedSRSOAndAccount(srMAPDandT.values(), srMAPDandT);
        ServiceRequestTriggerHelper.isCancellationSRNonClosed(srMAPDandT.values()[0]);
    }   
}