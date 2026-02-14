@isTest(SeeAllData=false)
public class RetriggerAPIControllerTest {
    @isTest
    public static void testPropetryTransfer() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        acc.ERPID__c = '87292';
        insert acc;

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

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesorder.RebateForfeitureLetterSent__c = TRUE;
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate('Rebate Reinstate');        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.PROPERTY_TRANSFER_RT, 'PropertyTransfer');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;

        HexaBPM__SR_Status__c verificationByFinance = TestObjectsFactory.getSRStatus('Verification by Finance');       
        insert verificationByFinance;
       
        Id rebateReinstateId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.PROPERTY_TRANSFER_RT, rebateReinstateId, SRTemplateDetailRecord.Id);
        newSR.BuyerName__c = acc.Id;
        insert newSR;

        ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
        insert srReceiptAcknowledgementRec;

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        newStep.HexaBPM__Summary__c = Constants.Verification_BY_FINANCE;
        newStep.HexaBPM__Step_Notes__c = 'Notes';
        newStep.HexaBPM__Closed_Date__c = Date.Today();
        insert newStep;
        
        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        otherCharges.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_TRANSFER_FEE_CHARGE;
        update otherCharges;
        
        AgencyTeam__c agencyTeam = new AgencyTeam__c();
        agencyTeam.Account__c = acc.Id;
        agencyTeam.ServiceRequest__c = newSR.Id;
        agencyTeam.ShareHoldingPercentage__c = 20;
        agencyTeam.RelationshipType__c = 'Spouse Of';
        insert agencyTeam;

        try{
            Test.startTest();
            String srId = newSR.Id;
            RetriggerAPIController.callRespectiveAPI(srId);
            Test.stopTest();
        } catch(Exception ex){
            System.debug('ex>>>' + ex);
        }
    }

    @isTest
    public static void testPropetryTransfer2() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

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

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesorder.RebateForfeitureLetterSent__c = TRUE;
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate('Rebate Reinstate');        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.PROPERTY_TRANSFER_RT, 'PropertyTransfer');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;

        HexaBPM__SR_Status__c verificationByFinance = TestObjectsFactory.getSRStatus('Verification by Finance');       
        insert verificationByFinance;
       
        Id rebateReinstateId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PROPERTY_TRANSFER_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.PROPERTY_TRANSFER_RT, rebateReinstateId, SRTemplateDetailRecord.Id);
        newSR.BuyerName__c = acc.Id;
        insert newSR;

        ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
        insert srReceiptAcknowledgementRec;

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        newStep.HexaBPM__Summary__c = Constants.Verification_BY_FINANCE;
        newStep.HexaBPM__Step_Notes__c = 'Notes';
        newStep.HexaBPM__Closed_Date__c = Date.Today();
        insert newStep;
        
        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        otherCharges.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_TRANSFER_FEE_CHARGE;
        update otherCharges;
        
        AgencyTeam__c agencyTeam = new AgencyTeam__c();
        agencyTeam.Account__c = acc.Id;
        agencyTeam.ServiceRequest__c = newSR.Id;
        agencyTeam.ShareHoldingPercentage__c = 20;
        agencyTeam.RelationshipType__c = 'Spouse Of';
        insert agencyTeam;

        try{
            Test.startTest();
            String srId = newSR.Id;
            RetriggerAPIController.callRespectiveAPI(srId);
            Test.stopTest();
        } catch(Exception ex){
            System.debug('ex>>>' + ex);
        }
    }

    @isTest
    public static void testJointOwner() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        acc.ERPID__c = '12346';
        insert acc;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'aldar.test.account@gmail.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesorder.RebateForfeitureLetterSent__c = TRUE;
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate('Joint Owner');        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.JOINT_OWNER_RT, 'JointOwner');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;

        HexaBPM__SR_Status__c verificationByFinance = TestObjectsFactory.getSRStatus('Verification by Finance');       
        insert verificationByFinance;
       
        Id jointOwnerId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.JOINT_OWNER_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.ADDITION_JOINT_OWNER_RT, jointOwnerId, SRTemplateDetailRecord.Id);
        newSR.SalesOrder__c = salesOrder.Id;
        insert newSR;

        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        otherCharges.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_OWNERSHIP_CHANGE;
        update otherCharges;

        ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
        insert srReceiptAcknowledgementRec;

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        newStep.HexaBPM__Summary__c = Constants.Verification_BY_FINANCE;
        newStep.HexaBPM__Step_Notes__c = 'Notes';
        newStep.HexaBPM__Closed_Date__c = Date.Today();
        insert newStep;

        Account acc1 = TestObjectsFactory.getPersonAccountRecord();
        acc1.ERPID__c = '12345';
        insert acc1;

        AgencyTeam__c agencyTeam = new AgencyTeam__c();
        agencyTeam.Account__c = acc.Id;
        agencyTeam.ServiceRequest__c = newSR.Id;
        agencyTeam.ShareHoldingPercentage__c = 20;
        agencyTeam.RelationshipType__c = 'Spouse Of';
        insert agencyTeam;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, acc.Id, 'Spouse Of');
        insert jointOwner;
        
        try{
            Test.startTest();
            String srId = newSR.Id;
            RetriggerAPIController.callRespectiveAPI(srId);
            Test.stopTest();
        } catch(Exception ex){
            System.debug('ex>>>' + ex);
        }
    }

    @isTest
    public static void testJointOwner2() {
        
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Contact con = TestObjectsFactory.contactDataSetup(acc.Id);
        con.Email = 'aldar.test.account@gmail.com';
        update con;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesorder.RebateForfeitureLetterSent__c = TRUE;
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

        ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        insert receiptAcknowledgementRec;
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate('Joint Owner');        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.JOINT_OWNER_RT, 'JointOwner');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');       
        insert draft;
        
        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;

        HexaBPM__SR_Status__c verificationByFinance = TestObjectsFactory.getSRStatus('Verification by Finance');       
        insert verificationByFinance;
       
        Id jointOwnerId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.JOINT_OWNER_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.ADDITION_JOINT_OWNER_RT, jointOwnerId, SRTemplateDetailRecord.Id);
        newSR.SalesOrder__c = salesOrder.Id;
        insert newSR;

        SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);
        otherCharges.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_OWNERSHIP_CHANGE;
        update otherCharges;

        ReceiptAcknowledgement__c srReceiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
        srReceiptAcknowledgementRec.ServiceRequest__c = newSR.Id;
        insert srReceiptAcknowledgementRec;

        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR.id, objSRSteps.Id, objStepTemplate.id);   
        newStep.HexaBPM__Summary__c = Constants.Verification_BY_FINANCE;
        newStep.HexaBPM__Step_Notes__c = 'Notes';
        newStep.HexaBPM__Closed_Date__c = Date.Today();
        insert newStep;

        Account acc1 = TestObjectsFactory.getPersonAccountRecord();
        acc1.ERPID__c = '12345';
        insert acc1;

        AgencyTeam__c agencyTeam = new AgencyTeam__c();
        agencyTeam.Account__c = acc.Id;
        agencyTeam.ServiceRequest__c = newSR.Id;
        agencyTeam.ShareHoldingPercentage__c = 20;
        agencyTeam.RelationshipType__c = 'Spouse Of';
        insert agencyTeam;

        JointOwner__c jointOwner = TestObjectsFactory.getJointOwnerRecord(salesOrder.Id, acc.Id, 'Spouse Of');
        insert jointOwner;
        
        try{
            Test.startTest();
            String srId = newSR.Id;
            RetriggerAPIController.callRespectiveAPI(srId);
            Test.stopTest();
        } catch(Exception ex){
            System.debug('ex>>>' + ex);
        }
    }

    @isTest
    public static void testLPC(){
        Account acc = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert acc;

        Account acc1 = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
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

        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.Contact__c = con.Id;
        salesOrder.MortgageApplicationNumber__c = '1234';
        salesOrder.MortgageApplicable__c = 'No';
        insert salesOrder;

        List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 4);
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

        HexaBPM__SR_Status__c Closed = TestObjectsFactory.getSRStatus('Closed');       
        insert Closed;
        
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
        insert Submitted;

        HexaBPM__SR_Status__c approvedByFinance = TestObjectsFactory.getSRStatus('Approved by Finance');       
        insert approvedByFinance;
       
        Id mortgageRegistrationId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.INTERNAL_MORTGAGE_REGISTRATION_RT);

        SalesOrderOtherCharges__c soOther = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id,acc.Id);
        soOther.TypeOfCharge__c = Constants.OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES;
        update soOther;
        
        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(Closed.Id, unit.Id, Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE, mortgageRegistrationId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrder.Id;
        insert newSR;
        
        try{
            Test.startTest();
            String whrClause = ' Id = \'' + newSR.Id + '\'';
            List<HexaBPM__Service_Request__c> serviceRequestList = ServiceRequestService.queryAllFieldsWithWhereClause(whrClause);
            RetriggerAPIController.callAPI(serviceRequestList, Constants.LPC_WAIVER_RT);
            Test.stopTest();
        } catch(Exception ex){
            System.debug('ex>>>' + ex);
        }
    }
    
    @isTest
    public static void testCreditNoteSR(){
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'Credit_Note_Creation']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }

        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;

        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Credit Note Creation';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='CreditNoteCreation';
        insert SR_Template;
        
        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c();
        SR.RecordTypeId = recordTypeSR.get('Credit_Note_Creation');
        SR.HexaBPM__Customer__c = acc.Id;
        SR.HexaBPM__Contact__c = acc.PersonContactId;
        SR.OwnerId = UserInfo.getUserId();
        SR.HexaBPM__SR_Template__c = SR_Template.Id;
        SR.Unit__c = unit.Id;
        SR.SalesOrder__c = salesOrder.Id;
        SR.Credit_Note_Sub_Type__c = 'Installment Reversal';
        SR.Amount__c = 123.00;
        SR.SRType__c = 'Credit Note';
        SR.ChargeType__c = 'Credit Note';
        insert SR;

        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Manage Receipt';
        ST.HexaBPM__Code__c = 'Manage Receipt';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Manage Receipt';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        User us = [SELECT Id FROM User WHERE IsActive=true and UserName!=:Userinfo.getUserName() and ProfileId=:UserInfo.getProfileId() Limit 1];

        HexaBPM__Step__c step = new HexaBPM__Step__c();
        step.HexaBPM__Summary__c = 'Manage Receipt';
        step.HexaBPM__SR__c = SR.Id;
        step.HexaBPM__SR_Step__c = SRStep.Id;
        step.HexaBPM__Start_Date__c = System.today();
        step.OwnerId = us.Id;
        insert step; 
        
        HexaBPM__Status__c objStatus = new HexaBPM__Status__c();
        objStatus.Name = 'Approved';
        objStatus.HexaBPM__Type__c = 'End';
        objStatus.HexaBPM__Code__c = 'Approved';
        insert objStatus;
        
        HexaBPM__Step__c step2 = new HexaBPM__Step__c();
        step2.HexaBPM__Summary__c = 'Verify the Request';
        step2.HexaBPM__SR__c = SR.Id;
        step2.HexaBPM__SR_Step__c = SRStep.Id;
        step2.HexaBPM__Start_Date__c = System.today();
        step2.HexaBPM__Status__c = objStatus.Id;
        insert step2; 
        
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);
        InstallmentLines__c il = new InstallmentLines__c();
        il.Id = installmentLineList[0].Id;
        il.InvoiceId__c = '1234';
        il.InvoiceNumber__c = '1234';
        update il;
        
        SR.InstallmentLine__c = il.Id;
        update SR;
        
        //HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c Limit 1];
        HexaBPM__Step__c stp = [Select Id, Name, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Summary__c,HexaBPM__Status__c,HexaBPM__Status__r.Name,SRTemplateName__c From HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Verify the Request' AND HexaBPM__SR__c=:SR.Id ORDER BY CreatedDate DESC limit 1];
        
        CC_ALDRA_CreditNoteCreationProcess cc = new CC_ALDRA_CreditNoteCreationProcess();
        
        String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "results": { "othChgRes": [ { "sfRequestId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "srSFId": "a0Q250000059slaEAA", "sfId": "a2425000002qNaJAAU", "erpId": "", "recAcct": "", "expAcct": "", "taxAcct": "", "status": "Failure", "errorMsg": "Err in API Call : Error : no CM trx type id defined.Msg1: Error : no CM trx type id defined.", "invoiceNo": "" } ] } }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        System.debug('stp HexaBPM__Status__c -> '+stp.HexaBPM__Status__r.Name);
        cc.EvaluateCustomCode(SR, stp);
        
        Test.startTest();
        RetriggerAPIController.callRespectiveAPI(SR.Id);
        Test.stopTest();
    }
    
    @isTest
    public static void testInvoiceReversal() {
        Map<String,Id> recordTypeSR = new Map<String,Id>();
        for(Recordtype rtype : [SELECT Id,DeveloperName FROM Recordtype WHERE SObjectType = 'HexaBPM__Service_Request__c' AND DeveloperName = 'Credit_Note_Creation']){
            recordTypeSR.put(rtype.DeveloperName,rtype.Id);
        }
        User us = [SELECT Id FROM User WHERE IsActive=true and UserName!=:Userinfo.getUserName() and ProfileId=:UserInfo.getProfileId() Limit 1];
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.Status__c = 'Sold';
        insert unit;
        
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        insert salesOrder;
        
        HexaBPM__SR_Template__c SR_Template = new HexaBPM__SR_Template__c();
        SR_Template.Name = 'Credit Note Creation';
        SR_Template.HexaBPM__SR_RecordType_API_Name__c='CreditNoteCreation';
        insert SR_Template;
        
        
        HexaBPM__Step_Template__c ST = new HexaBPM__Step_Template__c();
        ST.Name = 'Manage Receipt';
        ST.HexaBPM__Code__c = 'Manage Receipt';
        ST.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert ST;
        
        HexaBPM__Status__c objStatus = new HexaBPM__Status__c();
        objStatus.Name = 'Approved';
        objStatus.HexaBPM__Type__c = 'End';
        objStatus.HexaBPM__Code__c = 'Approved';
        insert objStatus;
        
        HexaBPM__Status__c objStatus2 = new HexaBPM__Status__c();
        objStatus2.Name = 'Completed';
        objStatus2.HexaBPM__Type__c = 'End';
        objStatus2.HexaBPM__Code__c = 'Completed';
        insert objStatus2;
        
        HexaBPM__SR_Steps__c SRStep = new HexaBPM__SR_Steps__c();
        SRStep.HexaBPM__SR_Template__c = SR_Template.id;
        SRStep.HexaBPM__Step_No__c = 1;
        SRStep.HexaBPM__Step_Template__c = ST.Id;
        SRStep.HexaBPM__Summary__c = 'Manage Receipt';
        SRStep.HexaBPM__Step_RecordType_API_Name__c = 'General';
        insert SRStep;
        
        //FOR REVERSAL
        HexaBPM__Service_Request__c SR2 = new HexaBPM__Service_Request__c();
        SR2.RecordTypeId = recordTypeSR.get('Credit_Note_Creation');
        SR2.HexaBPM__Customer__c = acc.Id;
        SR2.HexaBPM__Contact__c = acc.PersonContactId;
        SR2.OwnerId = UserInfo.getUserId();
        SR2.HexaBPM__SR_Template__c = SR_Template.Id;
        SR2.Unit__c = unit.Id;
        SR2.SalesOrder__c = salesOrder.Id;
        SR2.Credit_Note_Sub_Type__c = 'Installment Reversal';
        SR2.Amount__c = 123.00;
        SR2.SRType__c = 'Credit Note';
        SR2.ChargeType__c = 'Credit Note';
        SR2.InvoiceReversal__c=true;
        insert SR2;
        
        HexaBPM__Step__c step11 = new HexaBPM__Step__c();
        step11.HexaBPM__Summary__c = 'Manage Receipt';
        step11.HexaBPM__SR__c = SR2.Id;
        step11.HexaBPM__SR_Step__c = SRStep.Id;
        step11.HexaBPM__Start_Date__c = System.today();
        step11.OwnerId = us.Id;
        step11.HexaBPM__Status__c = objStatus2.Id;
        insert step11; 
                
        HexaBPM__Step__c step22 = new HexaBPM__Step__c();
        step22.HexaBPM__Summary__c = 'Verify the Request';
        step22.HexaBPM__SR__c = SR2.Id;
        step22.HexaBPM__SR_Step__c = SRStep.Id;
        step22.HexaBPM__Start_Date__c = System.today();
        insert step22;
        
        Test.startTest();
        
        HexaBPM__Service_Request__c SR = [Select Id, SalesOrder__c From HexaBPM__Service_Request__c WHERE InvoiceReversal__c=true Limit 1];
        List<HexaBPM__Step__c> stps = [Select Id, Name, HexaBPM__SR__c, Step_Template_Code__c,HexaBPM__Summary__c,HexaBPM__Status__c,HexaBPM__Status__r.Name,SRTemplateName__c From HexaBPM__Step__c WHERE (HexaBPM__Summary__c = 'Manage Receipt' OR HexaBPM__Summary__c = 'Verify the Request') AND HexaBPM__SR__c=:SR.Id ORDER BY CreatedDate DESC limit 2];
        List<InstallmentLines__c> installmentLineList = TestObjectsFactory.createInstallmentLines(SR.SalesOrder__c, 2);
        
        InstallmentLines__c il = new InstallmentLines__c();
        il.Id = installmentLineList[0].Id;
        il.InvoiceId__c = '1234';
        il.InvoiceNumber__c = '1234';
        il.InvoicedAmount__c = 0;
        update il;
        
        SR.InstallmentLine__c = il.Id;
        update SR;
        
        HexaBPM__Status__c status = [SELECT Id from HexaBPM__Status__c WHERE Name='Approved' Limit 1];
        List<HexaBPM__Step__c> stpList = new List<HexaBPM__Step__c>();
        for(HexaBPM__Step__c stp:stps) {
            if(stp.HexaBPM__Summary__c == 'Verify the Request') {
                stp.HexaBPM__Status__c = status.Id;
                stpList.add(stp);
            }
        }
        update stpList;
        //CC_ALDRA_CreditNoteCreationProcess cc = new CC_ALDRA_CreditNoteCreationProcess();
        String responseBody = '{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "results": { "othChgRes": [ { "sfRequestId": "396fbd20-fa08-11ed-acd1-06dbb03cb360", "srSFId": "a0Q250000059slaEAA", "sfId": "a2425000002qNaJAAU", "erpId": "123243", "recAcct": "123243", "expAcct": "123243", "taxAcct": "123243", "status": "Success", "errorMsg": "","IsInvoiceReversal": "Y", "invoiceNo": "12343" } ] } }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody));
        //cc.EvaluateCustomCode(SR, stpList[0]);
        RetriggerAPIController.callRespectiveAPI(SR.Id);

        Test.stopTest();
        
    }
}