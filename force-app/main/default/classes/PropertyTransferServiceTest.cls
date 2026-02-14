@isTest
public class PropertyTransferServiceTest {
    
    @testSetup static void testData(){
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus(Constants.Compliance_Rejected);       
        insert Submitted; 
        
        HexaBPM__SR_Status__c Submitted1 = TestObjectsFactory.getSRStatus(Constants.Compliance_Cleared);       
        insert Submitted1; 
        
        HexaBPM__SR_Status__c Submitted2 = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);       
        insert Submitted2; 

        HexaBPM__Status__c status1 = new HexaBPM__Status__c();
        status1.Name =Constants.Cleared;
        status1.HexaBPM__Code__c =Constants.Cleared;
        insert status1;
        
        HexaBPM__Status__c statusCom = new HexaBPM__Status__c();
        statusCom.Name = 'Completed';
        statusCom.HexaBPM__Code__c = 'Completed';
        insert statusCom;
        
        HexaBPM__Status__c statusPending = new HexaBPM__Status__c();
        statusPending.Name = 'Pending';
        statusPending.HexaBPM__Code__c = 'Pending';
        insert statusPending;
        
        HexaBPM__Status__c statusApp = new HexaBPM__Status__c();
        statusApp.Name = 'Approved';
        statusApp.HexaBPM__Code__c = 'Approved';
        insert statusApp;
        
        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate(Constants.PROPERTY_TRANSFER_DEV_RT, 'PropertyTransfer');
        insert objStepTemplate;
        
        Account newAccount = TestObjectsFactory.getOrganisationAccountRecord('Test Org', 'G123456');
        insert newAccount;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(newAccount.Id);
        opp.OwnerManger__c = UserInfo.getUserId();
        insert opp;
        Unit__c unit = TestObjectsFactory.unitDataSetup('25083');
        unit.SellingPrice__c = 1000000;
        unit.Status__c = 'Sold';
        insert unit;
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, newAccount.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.IsBookingCompleted__c = true;
        salesOrder.NetAmount__c = 100000;
        salesOrder.SellingPrice__c=1000000;
        insert salesOrder;
        
        HexaBPM__SR_Status__c closed = TestObjectsFactory.getSRStatus('Closed');       
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
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord3 = TestObjectsFactory.getSRTemplate('PropertyTransfer');     
        SRTemplateDetailRecord3.Name = Constants.PROPERTY_TRANSFER_RT;
        insert SRTemplateDetailRecord3;
        
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
        HexaBPM__Step__c newStep = TestObjectsFactory.getServiceRequestStep(newSR1.id, objSRSteps.Id, objStepTemplate.id);     
        newStep.HexaBPM__Summary__c = 'Compliance Check for Buyers';
        insert newStep;   
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
        /*for (HexaBPM__Service_Request__c sr: oldList) {
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
submittedLPCSRWithSOMap.put(newSR3, salesOrder2.id);*/
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
        // Set < Id > caseIdSet = new Set < Id > ();
        // PropertyTransferService.validatePropertyTransferSR(NewList, propertyTransferRecIds, unitIdList, caseIdSet);
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
    public static void testCloseADMStepAndPtOffplanSRStepOpen() {
        Test.startTest();
        HexaBPM__Status__c statusPending;
        List<HexaBPM__Status__c> existingPending = [
            SELECT Id FROM HexaBPM__Status__c WHERE Name = :Constants.PENDING_STATUS LIMIT 1
        ];
        if (existingPending.isEmpty()) {
            statusPending = new HexaBPM__Status__c(
                Name = Constants.PENDING_STATUS,
                HexaBPM__Code__c = Constants.PENDING_STATUS
            );
            insert statusPending;
        } else {
            statusPending = existingPending[0];
        }
        
        HexaBPM__Status__c statusCompleted;
        List<HexaBPM__Status__c> existingCompleted = [
            SELECT Id FROM HexaBPM__Status__c WHERE Name = :Constants.COMPLETED LIMIT 1
        ];
        if (existingCompleted.isEmpty()) {
            statusCompleted = new HexaBPM__Status__c(
                Name = Constants.COMPLETED,
                HexaBPM__Code__c = Constants.COMPLETED
            );
            insert statusCompleted;
        } else {
            statusCompleted = existingCompleted[0];
        }
        
        HexaBPM__Status__c statusApproved;
        List<HexaBPM__Status__c> existingApproved = [
            SELECT Id FROM HexaBPM__Status__c WHERE Name = :Constants.STATUS_APPROVED LIMIT 1
        ];
        if (existingApproved.isEmpty()) {
            statusApproved = new HexaBPM__Status__c(
                Name = Constants.STATUS_APPROVED,
                HexaBPM__Code__c = Constants.STATUS_APPROVED
            );
            insert statusApproved;
        } else {
            statusApproved = existingApproved[0];
        }
        
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        insert acc;
        
        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;
        
        Unit__c unit = TestObjectsFactory.unitDataSetup('PTTEST');
        unit.Status__c = 'Sold';
        insert unit;
        
        HexaBPM__SR_Template__c srTemp = TestObjectsFactory.getSRTemplate('Property Transfer NOC');
        insert srTemp;
        
        HexaBPM__Service_Request__c sr = TestObjectsFactory.getServiceRequest(
            null,
            unit.Id,
            'Property Transfer NOC',
            Utilities.getRecordTypeId('HexaBPM__Service_Request__c', 'Property Transfer NOC'),
            srTemp.Id
        );
        sr.SRType__c = 'Property Transfer NOC';
        sr.TransferSellingPrice__c = 200000;
        insert sr;
        
        HexaBPM__Step__c step = new HexaBPM__Step__c(
            HexaBPM__SR__c = sr.Id,
            HexaBPM__Summary__c = Constants.TRANSFER_EXEC_STATUS_ADM,
            HexaBPM__Status__c = statusPending.Id
        );
        insert step;
        
        HexaBPM__Step_Template__c stepTemp =
            TestObjectsFactory.getStepTemplate(Constants.PROPERTY_TRANSFER_NOC_RT, Constants.TITLE_DEED_APPROVAL);
        insert stepTemp;
        
        HexaBPM__SR_Steps__c srStep = TestObjectsFactory.getSRStep(srTemp.Id, stepTemp.Id);
        insert srStep;
        
        PropertyTransferService.closeADMStep(new List<HexaBPM__Service_Request__c>{ sr });
        
        List<HexaBPM__Step__c> updatedSteps = [
            SELECT Id, HexaBPM__Status__c
            FROM HexaBPM__Step__c
            WHERE HexaBPM__SR__c = :sr.Id
        ];
        System.assert(updatedSteps.size() > 0, 'Expected updated ADM step(s)');
        
        HexaBPM__SR_Template__c offPlanTemplate = TestObjectsFactory.getSRTemplate(Constants.PROPERTY_TRANSFER_OffPlan);
        offPlanTemplate.Name = 'Property Transfer (Off Plan)';
        insert offPlanTemplate;
        
        
        
        HexaBPM__Step_Template__c digitalStepTemp = new HexaBPM__Step_Template__c(
            Name = 'Digital Step Pending',
            HexaBPM__Code__c = 'Digital_Step_Pending',
            HexaBPM__Step_RecordType_API_Name__c = Constants.PROPERTY_TRANSFER_OFFPLAN_RT
        );
        insert digitalStepTemp;
        
        HexaBPM__SR_Steps__c offPlanStep = new HexaBPM__SR_Steps__c(
            HexaBPM__SR_Template__c = offPlanTemplate.Id,
            HexaBPM__Step_Template__c = digitalStepTemp.Id,
            HexaBPM__Active__c = true
        );
        insert offPlanStep;
        
        HexaBPM__Step_Template__c buyerProfileTemp = new HexaBPM__Step_Template__c(
            Name = 'Verification of Buyer Profile',
            HexaBPM__Code__c = 'Verification_of_Buyer_Profile',
            HexaBPM__Step_RecordType_API_Name__c = Constants.PROPERTY_TRANSFER_OFFPLAN_RT
        );
        insert buyerProfileTemp;
        
        HexaBPM__SR_Steps__c buyerStep = new HexaBPM__SR_Steps__c(
            HexaBPM__SR_Template__c = offPlanTemplate.Id,
            HexaBPM__Step_Template__c = buyerProfileTemp.Id,
            HexaBPM__Active__c = true
        );
        insert buyerStep;
        
        HexaBPM__Step_Template__c sellerProfileTemp = new HexaBPM__Step_Template__c(
            Name = 'Verification of Seller Profile',
            HexaBPM__Code__c = 'Verification_of_Seller_Profile',
            HexaBPM__Step_RecordType_API_Name__c = Constants.PROPERTY_TRANSFER_OFFPLAN_RT
        );
        insert sellerProfileTemp;
        
        HexaBPM__SR_Steps__c sellerStep = new HexaBPM__SR_Steps__c(
            HexaBPM__SR_Template__c = offPlanTemplate.Id,
            HexaBPM__Step_Template__c = sellerProfileTemp.Id,
            HexaBPM__Active__c = true
        );
        insert sellerStep;
        
        
        
        HexaBPM__Service_Request__c srSpa = [SELECT Id, HexaBPM__External_SR_Status__c, HexaBPM__External_SR_Status__r.Name, Unit__c, SRType__c from HexaBPM__Service_Request__c where SRType__c =:Constants.SPA_REGISTRATION_TYPE];
        
        HexaBPM__Service_Request__c offplanSR = new HexaBPM__Service_Request__c();
        offplanSR.RecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Property Transfer (Off Plan)').getRecordTypeId();
        offplanSR.SRType__c = Constants.PROPERTY_TRANSFER_OffPlan;
        offplanSR.HexaBPM__Customer__c =acc.Id;
        offplanSR.BuyerName__c =acc.Id;
        offplanSR.Origin__c = 'Customer Portal';
        //offplanSR.TransferSellingPrice__c = 200000;
        offplanSR.Unit__c = srSpa.Unit__c;
        insert offplanSR;
        PropertyTransferService.checkBeforeUpdatePTOfflineValidation(new List<HexaBPM__Service_Request__c>{offplanSR});
        offplanSR.TransferSellingPrice__c = 200000;
        Update offplanSR;
        PropertyTransferService.PtOffplanSRStepOpen(new List<HexaBPM__Service_Request__c>{ offplanSR });
        
        List<HexaBPM__Step__c> createdSteps = [
            SELECT Id, HexaBPM__Summary__c
            FROM HexaBPM__Step__c
            WHERE HexaBPM__SR__c = :offplanSR.Id
        ];
        System.assertEquals(3, createdSteps.size(), 'Expected 3 steps (Digital, Buyer, Seller)');
        Test.stopTest();
    }
    
    
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
        /*List<HexaBPM__SR_Status__c> draftStatus = [Select id, name from HexaBPM__SR_Status__c where name = 'Draft'];
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
Map<id,HexaBPM__Service_Request__c> emptyMap = new Map<id,HexaBPM__Service_Request__c>();         
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
}*/
        
        PropertyTransferService.ComplianceCheck(new Set<Id>{newAccount.Id});
        
        Test.stopTest();
    }    
    
    @isTest
    static void testUpdateVerificationStepsForPropertyTransfer() {
        
        Test.startTest();
        
        HexaBPM__Status__c pendingStatus = [SELECT Id FROM HexaBPM__Status__c WHERE Name = :Constants.PENDING_STATUS LIMIT 1];
        
        HexaBPM__Status__c completedStatus = [SELECT Id FROM HexaBPM__Status__c WHERE Name = :Constants.COMPLETED_STATUS LIMIT 1];
        
        List<Account> accountsToInsert = new List<Account>{TestObjectsFactory.getPersonAccountRecord(), TestObjectsFactory.getPersonAccountRecord()};
		insert accountsToInsert;
        
        Account sellerAcc = accountsToInsert[0];
        Account buyerAcc  = accountsToInsert[1];      
        
        HexaBPM__SR_Template__c offPlanTemplate = TestObjectsFactory.getSRTemplate(Constants.PROPERTY_TRANSFER_OffPlan);
        offPlanTemplate.Name = 'Property Transfer (Off Plan)';
        insert offPlanTemplate;
        
        HexaBPM__Step_Template__c buyerTemp = new HexaBPM__Step_Template__c(
            Name = 'Verification of Buyer Profile',
            HexaBPM__Code__c = 'Verification_of_Buyer_Profile',
            HexaBPM__Step_RecordType_API_Name__c = Constants.PROPERTY_TRANSFER_OFFPLAN_RT
        );
        insert buyerTemp;
        
        HexaBPM__Step_Template__c sellerTemp = new HexaBPM__Step_Template__c(
            Name = 'Verification of Seller Profile',
            HexaBPM__Code__c = 'Verification_of_Seller_Profile',
            HexaBPM__Step_RecordType_API_Name__c = Constants.PROPERTY_TRANSFER_OFFPLAN_RT
        );
        insert sellerTemp;
        
        HexaBPM__SR_Steps__c buyerStep = TestObjectsFactory.getSRStep(offPlanTemplate.Id, buyerTemp.Id);
        insert buyerStep;
        
        HexaBPM__SR_Steps__c sellerStep = TestObjectsFactory.getSRStep(offPlanTemplate.Id, sellerTemp.Id);
        insert sellerStep;
        
        Id offPlanRT = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Property Transfer (Off Plan)').getRecordTypeId();
        Id unitId = [Select Id from Unit__c where Status__c = 'Sold' Limit 1].Id;
        HexaBPM__SR_Status__c Submitted = TestObjectsFactory.getSRStatus('Submitted');       
       // insert Submitted;
        
        HexaBPM__Service_Request__c offSR = TestObjectsFactory.getServiceRequest(Submitted.Id, unitId, Constants.PROPERTY_TRANSFER_OffPlan, offPlanRT, offPlanTemplate.Id); 
        offSR.Origin__c = 'Customer Portal'; 
        offSR.HexaBPM__Customer__c = sellerAcc.Id; 
        offSR.BuyerName__c = buyerAcc.Id; 
        offSR.TransferSellingPrice__c = 1000000;
        insert offSR;
        offSR.HexaBPM__External_SR_Status__c = Submitted.Id;
        update offSR;
        
        HexaBPM__Service_Request__c offPlanSR = [SELECT Id, HexaBPM__External_Status_Name__c, HexaBPM__External_SR_Status__r.Name, Origin__c, HexaBPM__Customer__c, BuyerName__c from HexaBPM__Service_Request__c where SRType__c =: Constants.PROPERTY_TRANSFER_OffPlan];
        
        HexaBPM__Step__c stepBuyer = new HexaBPM__Step__c(
            HexaBPM__SR__c = offSR.Id,
            HexaBPM__Status__c = pendingStatus.Id,
            HexaBPM__SR_Step__c = buyerStep.Id
        );
        HexaBPM__Step__c stepSeller = new HexaBPM__Step__c(
            HexaBPM__SR__c = offSR.Id,
            HexaBPM__Status__c = pendingStatus.Id,
            HexaBPM__SR_Step__c = sellerStep.Id
        );
        insert new List<HexaBPM__Step__c>{ stepBuyer, stepSeller };
            
            PropertyTransferService.updatePTOffPlanVerificationSteps(
                new Set<Id>{ offSR.HexaBPM__Customer__c, offSR.BuyerName__c }
            );
        Test.stopTest();
    }
    
    
}