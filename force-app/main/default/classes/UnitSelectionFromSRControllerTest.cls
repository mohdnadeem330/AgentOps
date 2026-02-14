/*
*Created By     : Hardik Vitthani
*Description    : Test class for UnitSelectionFromSRController
*/
@isTest
public class UnitSelectionFromSRControllerTest {
    @isTest
    public static void testUnitSelectionFromSRController() {
        Account acc = TestObjectsFactory.getPersonAccountRecord();
        acc.ERPID__c = '12346';
        insert acc;

        //Account bankAccount = TestObjectsFactory.getAccountRecord('Bank', false, '');
        //bankAccount.BankEmail__c = 'hardikkuamr.vitthani.tpr@pwc.com';
        //bankAccount.Name = 'Abu Dhabi Commercial Bank';
        //insert bankAccount;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        opp.EnquiryCategory__c = 'Aldar Employees';
        opp.EnquiryTrigger__c = 'Aldar Hospitality';
        insert opp;
        
        Project__c project = TestObjectsFactory.getProjectRecord('ABC');
        insert project;
        
        BuildingSection__c buildingRecord= TestObjectsFactory.getBuildingDetailRecord(project.id);
        insert buildingRecord;
        
        Unit__c unit = TestObjectsFactory.getUnitDetail(project.Id,buildingRecord.Id);
        unit.Status__c = 'Sold';
        unit.MeasuredArea__c = 100;
        unit.AnticipatedServiceCharges__c = 10;
        unit.EscalationServiceCharge__c = 100;
        insert unit;

        Unit__c unit2 = TestObjectsFactory.getUnitDetail(project.Id,buildingRecord.Id);
        unit2.Name = 'MAYAN-B1-1002';
        unit2.ShortNumber__c = '1002';
        unit2.Status__c = 'Sold';
        unit2.MeasuredArea__c = 100;
        unit2.AnticipatedServiceCharges__c = 10;
        unit2.EscalationServiceCharge__c = 100;
        insert unit2;
        
        OffersPromotions__c getOfferPromotion = TestObjectsFactory.getOfferPromotion(buildingRecord.Id, project.Id);
        getOfferPromotion.Unit__c = unit.Id;
        insert getOfferPromotion;
        system.debug('getOfferPromotion@@@'+getOfferPromotion.Id);
        
		Test.startTest();
        SalesOrder__c salesOrder = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder.Unit__c = unit.Id;
        salesOrder.NetAmount__c = 100000;
        salesOrder.SellingPrice__c = 100000;
        salesOrder.OtherRebateAmount__c = 100;
        salesOrder.ADMFeeWaivedAmount__c = 100;
        insert salesOrder;

        SalesOrder__c salesOrder2 = TestObjectsFactory.getSalesOrderRecord(opp.Id, acc.Id);
        salesOrder2.Unit__c = unit2.Id;
        salesOrder2.Status__c = 'Sold';
        salesOrder2.NetAmount__c = 100000;
        salesOrder2.SellingPrice__c = 100000;
        salesOrder2.OtherRebateAmount__c = 100;
        salesOrder2.ADMFeeWaivedAmount__c = 100;
        insert salesOrder2;

        InternalCommission__c internalCommission = TestObjectsFactory.getInternalCommission();
        internalCommission.Project__c = project.Id;
        insert internalCommission;

        BrokerCommission__c brokerCommission = TestObjectsFactory.getBrokerCommission(project.Id);
        insert brokerCommission;

       // List<InstallmentLines__c> installmentLines = TestObjectsFactory.createInstallmentLines(salesOrder.Id, 2);

       // ReceiptAcknowledgement__c receiptAcknowledgementRec = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder.Id, acc.Id, opp.Id, 'Cash');
       // insert receiptAcknowledgementRec;

       // SalesOrderOtherCharges__c otherCharges = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder.Id, acc.Id);

        
       // List<InstallmentLines__c> installmentLines2 = TestObjectsFactory.createInstallmentLines(salesOrder2.Id, 2);

       // ReceiptAcknowledgement__c receiptAcknowledgementRec2 = TestObjectsFactory.getReceiptAcknowledgementRecord(salesOrder2.Id, acc.Id, opp.Id, 'Cash');
       // insert receiptAcknowledgementRec2;

       // SalesOrderOtherCharges__c otherCharges2 = TestObjectsFactory.createSalesOrderOtherCharges(salesOrder2.Id, acc.Id);
        
        HexaBPM__SR_Template__c SRTemplateDetailRecord = TestObjectsFactory.getSRTemplate(Constants.CANCELLATION_RT);        
        insert SRTemplateDetailRecord;

        HexaBPM__Step_Template__c objStepTemplate = TestObjectsFactory.getStepTemplate('Cancellation', 'Cancellation');
        insert objStepTemplate;

        HexaBPM__SR_Steps__c objSRSteps = TestObjectsFactory.getSRStep(SRTemplateDetailRecord.Id, objStepTemplate.Id);
        insert objSRSteps;

        HexaBPM__SR_Status__c draft = TestObjectsFactory.getSRStatus('Draft');
        insert draft;

        HexaBPM__SR_Status__c submitted = TestObjectsFactory.getSRStatus(Constants.SUBMITTED);
        insert submitted;
       
        Id srRecordtypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.CANCELLATION_RT);

        HexaBPM__Service_Request__c newSR = TestObjectsFactory.getServiceRequest(draft.Id, unit.Id, Constants.CANCELLATION_TYPE, srRecordtypeId, SRTemplateDetailRecord.Id);
        newSR.ChargeCollected__c = 2000;
        newSR.SalesOrder__c = salesOrder.Id;
        newSR.HexaBPM__Customer__c = acc.Id;
        newSR.BankAccountNumber__c = '123456789';
		newSR.BranchName__c='Branch';
		newSR.BankName__c ='Bank Name';
		newSR.IBANNumber__c='IBAN123456734567892';
		newSR.SwiftCode__c='NOC Test';
        newSR.CancellationReason__c ='Mutual Cancellation - Refund';
        newSR.SocialReason__c ='Death & Incurable Disease';
        newSR.AgreementType__c ='T1 - Cancellation without Refund';
        insert newSR;
        
        SRUnitSelected__c srUnitSelected = TestObjectsFactory.getSRUnitSelected(unit.Name, newSR.Id, salesOrder.Id, unit.Id);
        srUnitSelected.RetainedCancelled__c = Constants.RETAINED_UNIT;
        insert srUnitSelected;
        
        UnitDetailModel model = new UnitDetailModel();
        model.totalNonNegotiableCost = 100;
        model.totalFutureResaleCost = 100;
        model.ADMWaiverAmount = 100;
        model.rebateAmount = 100;
        model.darnaAmount = 100;
        model.totalFutureCommission = 100;
        model.externalCommissionAmount = 100;
        model.internalCommissionAmount = 100;
        model.lossCalculation1 = 100;
        model.lossCalculation2 = 100;
        model.equityRefund1 = 100;
        model.equityRefund2 = 100;

        try {
            UnitSelectionFromSRController.getAllSalesOrders(newSR.Id, '', '', '');
            UnitSelectionFromSRController.getActiveOffers(new List<String>{unit.Id});
           // UnitSelectionFromSRController.getCommission(new List<String>{unit.Id});
 			String unitSelectionStr = '[{"voucher":6000,"unitNo":"Mayan-B1-01-04","unitId":"' + unit.Id + '","totalOutstanding":143000,"totalNonNegotiableCost":12551.495890410959,"totalInstallmentReceived":0,"totalFutureResaleCost":89775.86,"totalFutureCommission":89462.65,"soId":"' + salesOrder.Id + '","serviceCharge":9551.495890410959,"sellingPrice":1789253.07,"SCWaiver":1,"SCWaivedAmount":20152,"salesSupportCost":1000,"salesOrderNo":"OU#00036404","retainedUnit":false,"rebateAmount":17892.53,"rebate":1,"projectName":"MAYAN","otherRebateAmount":1789253.07,"option3":true,"option2":false,"option1":false,"netAmount":143000,"lossCalculation3":1838043.08,"lossCalculation2":1748580.43,"lossCalculation1":1658804.57,"legalfeesVAT":1000,"internalCommissionAmount":17892.53,"internalCommission":1,"Id":null,"externalCommissionAmount":71570.12,"externalCommission":4,"escalationServiceCharge":1,"equityRefund3":-1838043.08,"equityRefund2":-1748580.43,"equityRefund1":-1658804.57,"equityPercent":0,"districtCooling":1000,"discountValue":1646253.07,"darnaAmount":8946.27,"darna":0.5,"cancelledUnit":false,"anticipatedServiceCharges":20152,"ADMWaiverAmount":35785.06,"ADMWaiver":2,"ADMFeeWaivedAmount":null,"ADDCAssumption":1000,"accountName":"Ali Aa Saeed","accountId":"' + acc.Id + '","selectedOption":"Option 3","lossCalculation":1838043.08,"equityRefund":-1838043.08,"rowIndex":0,"selectedOffer":"' + getOfferPromotion.Id + '","OtherLossCalcutation":123456,"option4":false,"lossCalculation4":1658804.57,"equityRefund4":-1748580.43,"totalOtherLossCalculation":1658804.57}]';
            System.debug('@@@unitSelectionStr>>>'+unitSelectionStr);
            UnitSelectionFromSRController.saveUnitSelection(unitSelectionStr, newSR.Id, 'Mutual Cancellation');
            
			system.debug('@@@AfterUnitSelectionFromSRController>>>'+newSR.Id);
           
			system.debug('@@@AfterUnitSelectionFromSRController>>>'+newSR.Id);
            
            system.debug('@@@getOffer>>>'+getOfferPromotion.Id);
            UnitSelectionFromSRController.getOffer(getOfferPromotion.Id);
            
            //String unitSelectionStr = '[{"voucher":6000,"unitNo":"Mayan-B1-01-04","unitId":"' + unit.Id + '","totalOutstanding":143000,"totalNonNegotiableCost":12551.495890410959,"totalInstallmentReceived":0,"totalFutureResaleCost":89775.86,"totalFutureCommission":89462.65,"soId":"' + salesOrder.Id + '","serviceCharge":9551.495890410959,"sellingPrice":1789253.07,"SCWaiver":1,"SCWaivedAmount":20152,"salesSupportCost":1000,"salesOrderNo":"OU#00036404","retainedUnit":false,"rebateAmount":17892.53,"rebate":1,"projectName":"MAYAN","otherRebateAmount":1789253.07,"option3":true,"option2":false,"option1":false,"netAmount":143000,"lossCalculation3":1838043.08,"lossCalculation2":1748580.43,"lossCalculation1":1658804.57,"legalfeesVAT":1000,"internalCommissionAmount":17892.53,"internalCommission":1,"Id":null,"externalCommissionAmount":71570.12,"externalCommission":4,"escalationServiceCharge":1,"equityRefund3":-1838043.08,"equityRefund2":-1748580.43,"equityRefund1":-1658804.57,"equityPercent":0,"districtCooling":1000,"discountValue":1646253.07,"darnaAmount":8946.27,"darna":0.5,"cancelledUnit":false,"anticipatedServiceCharges":20152,"ADMWaiverAmount":35785.06,"ADMWaiver":2,"ADMFeeWaivedAmount":null,"ADDCAssumption":1000,"accountName":"Ali Aa Saeed","accountId":"' + acc.Id + '","selectedOption":"Option 3","lossCalculation":1838043.08,"equityRefund":-1838043.08,"rowIndex":0,"selectedOffer":"' + getOfferPromotion.Id + ',"OtherLossCalcutation":123456,"option4":false,"lossCalculation4":1658804.57,"equityRefund4":-1748580.43,"totalOtherLossCalculation":1658804.57"}]';
            //System.debug('@@@unitSelectionStr>>>'+unitSelectionStr);
            //UnitSelectionFromSRController.saveUnitSelection(unitSelectionStr, newSR.Id, 'Mutual Cancellation');
            
            Test.stopTest();
        } catch (Exception ex) {
            System.debug('ex>>>' + ex);
        }
    }
}