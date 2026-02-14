/*
* Purpose: To compute losses and the remaining balance.
*/
public with sharing class UnitSelectionFromSRController {
    
    /*
    * Logic: Retrieve all units that have been selected and are accessible for loss calculation.
    */
    @AuraEnabled(cacheable=true)
    public static String getAllSalesOrders(String srId, String projectName, String unitNo, String salesOrderNo){
        List<UnitDetailModel> unitDetailList = new List<UnitDetailModel>();

        String whrClause = '';
        String accountId;
        
        if (((Id)srId).getSObjectType() == Account.getSObjectType()) {
            accountId = srId;
        } else {
            HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{srId})[0];
            accountId = serviceRequest.HexaBPM__Customer__c;

            for (SRUnitSelected__c unit: serviceRequest.SRUnitSelected__r) {
                if (String.isNotBlank(whrClause)) {
                    whrClause += ' AND ';
                }
                whrClause += ' Id != \'' + unit.SalesOrder__c + '\' ';

                UnitDetailModel unitDetail = new UnitDetailModel();
                unitDetail.Id = unit.Id;
                unitDetail.soId = unit.SalesOrder__c;
                unitDetail.salesOrderNo = unit.SalesOrder__r.Name;
                unitDetail.unitId = unit.Unit__c;
                unitDetail.unitNo = unit.SalesOrder__r.Unit__r.Name;
                unitDetail.accountId = unit.SalesOrder__r.Account__c;
                unitDetail.accountName = unit.SalesOrder__r.Account__r.Name;
                unitDetail.projectName = unit.SalesOrder__r.ProjectName__c; 
                unitDetail.sellingPrice = unit.SalesOrder__r.SellingPrice__c;
                unitDetail.netAmount = unit.SalesOrder__r.NetAmount__c;
                unitDetail.totalInstallmentReceived = unit.SalesOrder__r.TotalBilled__c;
                unitDetail.totalOutstanding = unit.SalesOrder__r.TotalOutstanding__c;
                unitDetail.otherRebateAmount = unit.SalesOrder__r.OtherRebateAmount__c;
                unitDetail.ADMFeeWaivedAmount = unit.SalesOrder__r.ADMFeeWaivedAmount__c;
                unitDetail.equityPercent = (unitDetail.netAmount != null && unitDetail.netAmount != 0 && unitDetail.totalInstallmentReceived != null && unitDetail.totalInstallmentReceived != 0 ? (unitDetail.totalInstallmentReceived / unitDetail.netAmount) * 100 : 0).setScale(2);
                unitDetail.discountValue = (unitDetail.sellingPrice != null && unitDetail.sellingPrice != 0 && unitDetail.netAmount != null && unitDetail.netAmount != 0 ? unitDetail.sellingPrice - unitDetail.netAmount : 0).setScale(2);
                unitDetail.escalationServiceCharge = unit.SalesOrder__r.Unit__r.EscalationServiceCharge__c;
                if (unit.SalesOrder__r.Unit__r.AnticipatedServiceCharges__c != null && unit.SalesOrder__r.Unit__r.AnticipatedServiceCharges__c != 0 && unit.SalesOrder__r.Unit__r.MeasuredArea__c != null && unit.SalesOrder__r.Unit__r.MeasuredArea__c != 0) {
                    unitDetail.anticipatedServiceCharges = unit.SalesOrder__r.Unit__r.AnticipatedServiceCharges__c * unit.SalesOrder__r.Unit__r.MeasuredArea__c;
                } else if (unit.SalesOrder__r.Unit__r.AnticipatedServiceCharges__c != null && unit.SalesOrder__r.Unit__r.AnticipatedServiceCharges__c != 0 && unit.SalesOrder__r.Unit__r.SaleableArea__c != null && unit.SalesOrder__r.Unit__r.SaleableArea__c != 0) {
                    unitDetail.anticipatedServiceCharges = unit.SalesOrder__r.Unit__r.AnticipatedServiceCharges__c * unit.SalesOrder__r.Unit__r.SaleableArea__c;
                } else if (unit.SalesOrder__r.Unit__r.AnticipatedServiceCharges__c != null && unit.SalesOrder__r.Unit__r.AnticipatedServiceCharges__c != 0 && unit.SalesOrder__r.Unit__r.TotalArea__c != null && unit.SalesOrder__r.Unit__r.TotalArea__c != 0) {
                    unitDetail.anticipatedServiceCharges = unit.SalesOrder__r.Unit__r.AnticipatedServiceCharges__c * unit.SalesOrder__r.Unit__r.TotalArea__c;
                }
                unitDetail.retainedUnit = unit.RetainedCancelled__c == Constants.RETAINED_UNIT ? true : false;
                unitDetail.cancelledUnit = unit.RetainedCancelled__c == Constants.CANCELLED_UNIT ? true : false;
                unitDetail.option1 = unit.OptionSelected__c == Constants.REFUND_OPTION_1 ? true : false;
                unitDetail.option2 = unit.OptionSelected__c == Constants.REFUND_OPTION_2 ? true : false;
                unitDetail.option3 = unit.OptionSelected__c == Constants.REFUND_OPTION_3 ? true : false;
                unitDetail.option4 = unit.OptionSelected__c == Constants.REFUND_OPTION_4 ? true : false;
                unitDetail.isFullRefund = unit.IsFullRefund__c;
                unitDetail.serviceCharge = unit.ServiceCharge__c;
                unitDetail.districtCooling = unit.DistrictCooling__c;
                unitDetail.ADDCAssumption = unit.ADDCAssumption__c;
                unitDetail.legalfeesVAT = unit.LegalfeesVAT__c;
                unitDetail.additionalForfeitedAmount = unit.AdditionalForfeitedAmount__c;
                unitDetail.ADMWaiver = unit.ADMWaiverPercentage__c;
                unitDetail.rebate = unit.RebatePercentage__c;
                unitDetail.darna = unit.DarnaPercentage__c;
                unitDetail.salesSupportCost = unit.SalesSupportCostAED__c;
                unitDetail.voucher = unit.VoucherAED__c;
                unitDetail.SCWaiver = unit.SCWaiverYears__c;
                unitDetail.SCWaivedAmount = unit.SCWaivedAmount__c;
                unitDetail.externalCommission = unit.ExternalCommission__c;
                unitDetail.internalCommission = unit.InternalCommission__c;
                unitDetail.OtherLossCalcutation = unit.Other_Loss_Calculation__c;
                

                unitDetailList.add(unitDetail);
            }

            Map<String, SRAutomation__mdt> srAutomationMap = Utilities.getSRAutomation(new Set<String>{serviceRequest.RecordType.Name});
            if(srAutomationMap.size() > 0){
                List<HexaBPM__Service_Request__c> openSRList = ServiceRequestService.getOpenServiceRequestListByType(new Set<String>{Constants.CONSOLIDATION_RT, Constants.MUTUAL_CANCELLATION_RT});
    
                SRAutomation__mdt srAuto = serviceRequest.SRType__c != null ? srAutomationMap.get(serviceRequest.SRType__c) : null;
                if (srAuto != null && srAuto.DuplicateCheckRequired__c == true) {
                    for (HexaBPM__Service_Request__c sr: openSRList) {
                        for (SRUnitSelected__c unit: sr.SRUnitSelected__r) {
                            if (String.isNotBlank(whrClause)) {
                                whrClause += ' AND ';
                            }
                            whrClause += ' Id != \'' + unit.SalesOrder__c + '\' ';
                        }
                    }
                }
            }
        }
        //Before ASF-1179 Fix : TotalOutstanding__c > 100
        //String whereCondition = 'Account__c = \'' + accountId + '\' AND (Status__c = \'' + Constants.SO_STATUS_SOLD + '\' OR Status__c = \'' + Constants.SO_STATUS_RTO_SOLD + '\') AND TitleDeedRegistrationNumber__c = null AND TotalOutstanding__c > 100 ';
        //After ASF-1179 Fix : We need to fetch the SalesOrder irrespective of the TotalOutstanding__c
        String whereCondition = 'Account__c = \'' + accountId + '\' AND (Status__c = \'' + Constants.SO_STATUS_SOLD + '\' OR Status__c = \'' + Constants.SO_STATUS_RTO_SOLD + '\') AND TitleDeedRegistrationNumber__c = null ';    
        whereCondition += String.isNotBlank(projectName) ? ' AND ProjectName__c = \'' + projectName + '\'' : '';
        whereCondition += String.isNotBlank(unitNo) ? ' AND Unit__c = \'' + unitNo + '\'' : '';
        whereCondition += String.isNotBlank(salesOrderNo) ? ' AND Id = \'' + salesOrderNo + '\'' : '';

        whereCondition += String.isNotBlank(whrClause) ? ' AND ' + whrClause : '';
        List<SalesOrder__c> salesOrders = SalesOrderService.fetchSalesOrders(whereCondition);
        for (SalesOrder__c salesOrder: salesorders) {
            UnitDetailModel unitDetail = new UnitDetailModel();
            unitDetail.soId = salesOrder.Id;
            unitDetail.salesOrderNo = salesOrder.Name;
            unitDetail.unitId = salesOrder.Unit__c;
            unitDetail.unitNo = salesOrder.Unit__r.Name;
            unitDetail.accountId = salesOrder.Account__c;
            unitDetail.accountName = salesOrder.Account__r.Name;
            unitDetail.projectName = salesOrder.ProjectName__c; 
            unitDetail.sellingPrice = salesOrder.SellingPrice__c;
            unitDetail.netAmount = salesOrder.NetAmount__c;
            unitDetail.totalInstallmentReceived = salesOrder.TotalBilled__c;
            unitDetail.totalOutstanding = salesOrder.TotalOutstanding__c;
            unitDetail.otherRebateAmount = salesOrder.OtherRebateAmount__c;
            unitDetail.ADMFeeWaivedAmount = salesOrder.ADMFeeWaivedAmount__c;
            unitDetail.equityPercent = (unitDetail.netAmount != null && unitDetail.netAmount != 0 && unitDetail.totalInstallmentReceived != null && unitDetail.totalInstallmentReceived != 0 ? (unitDetail.totalInstallmentReceived / unitDetail.netAmount) * 100 : 0).setScale(2);
            unitDetail.discountValue = (unitDetail.sellingPrice != null && unitDetail.sellingPrice != 0 && unitDetail.netAmount != null && unitDetail.netAmount != 0 ? unitDetail.sellingPrice - unitDetail.netAmount : 0).setScale(2);
            unitDetail.escalationServiceCharge = salesOrder.Unit__r.EscalationServiceCharge__c;
            if (salesOrder.Unit__r.AnticipatedServiceCharges__c != null && salesOrder.Unit__r.AnticipatedServiceCharges__c != 0 && salesOrder.Unit__r.MeasuredArea__c != null && salesOrder.Unit__r.MeasuredArea__c != 0) {
                unitDetail.anticipatedServiceCharges = salesOrder.Unit__r.AnticipatedServiceCharges__c * salesOrder.Unit__r.MeasuredArea__c;
            } else if (salesOrder.Unit__r.AnticipatedServiceCharges__c != null && salesOrder.Unit__r.AnticipatedServiceCharges__c != 0 && salesOrder.Unit__r.SaleableArea__c != null && salesOrder.Unit__r.SaleableArea__c != 0) {
                unitDetail.anticipatedServiceCharges = salesOrder.Unit__r.AnticipatedServiceCharges__c * salesOrder.Unit__r.SaleableArea__c;
            } else if (salesOrder.Unit__r.AnticipatedServiceCharges__c != null && salesOrder.Unit__r.AnticipatedServiceCharges__c != 0 && salesOrder.Unit__r.TotalArea__c != null && salesOrder.Unit__r.TotalArea__c != 0)  {
                unitDetail.anticipatedServiceCharges = salesOrder.Unit__r.AnticipatedServiceCharges__c * salesOrder.Unit__r.TotalArea__c;
            }
            unitDetail.serviceCharge = unitDetail.anticipatedServiceCharges != null && unitDetail.anticipatedServiceCharges != 0 && salesOrder.HandoverRFOPayDueDate__c != null && salesOrder.HandoverRFOPayDueDate__c < Date.today() ? ((unitDetail.anticipatedServiceCharges / 365) * salesOrder.HandoverRFOPayDueDate__c.daysBetween(Date.today())) : 0;
            unitDetail.retainedUnit = false;
            unitDetail.cancelledUnit = false;
            unitDetail.option1 = false;
            unitDetail.option2 = false;
            unitDetail.option3 = false;
            unitDetail.option4 = false;
            unitDetail.isFullRefund = false;

            unitDetailList.add(unitDetail);
        }
        
        System.debug('unitDetailList>>>' + unitDetailList);
        System.debug('json>>>unitDetailList>>>' + json.serialize(unitDetailList));
        return json.serialize(unitDetailList);
    }

    /*
    * Logic: Retrieve all active offers for chosen units.
    */
    @AuraEnabled
    public static Map<Id,List<OffersPromotions__c>> getActiveOffers(List<String> unitIds){
        Set<Id> unitIdSet = new Set<Id>();
        for (String unitId: unitIds) {
            unitIdSet.add(unitId);
        }
        List<Unit__c> unitDetails = UnitService.getAllUnitsById(unitIdSet);
        Map<Id,List<OffersPromotions__c>> returnMap = OffersPromotionsService.getActiveOffersPromotions(null, unitDetails,null);
        return returnMap;
    }

    /*
    * Logic: Get the Outstanding LPC for the chosen units.
    */
    @AuraEnabled
    public static Decimal getOutstandingLPC(String salesOrderId){
        LPCModel lpcDetail = LPCService.getOutstandingLPCforSalesOrder(salesOrderId);
        return lpcDetail.totalLPCDue;
    }

    /*
    * Logic: Get the available internal & external commission for the chosen units.
    */
    @AuraEnabled
    public static Map<String, Map<String, Decimal>> getCommission(List<String> unitNos){
        Map<String, Map<String, Decimal>> returnMap = new Map<String, Map<String, Decimal>>();
        Set<Id> unitIds = new set<Id>();
        for (String unitNo: unitNos) {
            unitIds.add((Id)unitNo);
        }
        List<Unit__c> unitList = UnitServiceWithoutSharing.getAllUnitsById(unitIds);
        
        Map<Id, InternalCommission__c> unitInternalCommissionMap =  CommissionService.getInternalCommissionsForUnit(unitList);
        Map<Id, BrokerCommission__c> unitExternalCommissionMap = CommissionService.getBrokerCommissions(new Opportunity(), unitList, new Map<Id,OffersPromotions__c>());
        
        for (Id internalCommission: unitInternalCommissionMap.keySet()) {
            InternalCommission__c commision = unitInternalCommissionMap.get(internalCommission);
            Map<String, Decimal> commisionMap = new Map<String, Decimal>();
            commisionMap.put(Constants.COMMISSION_LINE_INTERNAL_COMMISSION, commision.IndirectCommission__c);
            
            if (unitExternalCommissionMap.containsKey(internalCommission)) {
                BrokerCommission__c brokercommision = unitExternalCommissionMap.get(internalCommission);
                commisionMap.put(Constants.COMMISSION_LINE_EXTERNAL_COMMISSION, brokercommision.CommissionPercentage__c);    
            }
            returnMap.put(internalCommission, commisionMap);
        }
        System.debug('returnMap>>>' + returnMap);
        return returnMap;
    }

    /*
    * Logic: Get the Offer details based on Offer Id.
    */
    @AuraEnabled
    public static OffersPromotions__c getOffer(String offerId){
        OffersPromotions__c returnOffer = [SELECT Id, Name, BuildingSectionName__c, Project__c, BookingMemo__r.OwnerId, Unit__c, 
                                            AllocationGroup__c, BrokerPortalFlag__c, (SELECT Id, Name, OfferType__c, OfferOn__c, OfferValue__c, 
                                            CustomerType__c, Nationality__c, ResidentStatus__c, Unit__c, UnitType__c, UnitFeatures__c, 
                                            UnitModel__c, NumberOfBedrooms__c, LeadSource__c, LowerBound__c, UpperBound__c, RangeOnField__c, 
                                            Bulk__c, DiscountType__c, BudgetTaskName__c, OfferValueType__c FROM Offers_Lines__r WHERE 
                                            CustomerType__c = null AND NumberOfBedrooms__c = null AND ResidentStatus__c = null AND 
                                            Nationality__c = null AND UnitFeatures__c = null AND UnitModel__c = null AND UnitType__c = null 
                                            AND LowerBound__c = null AND UpperBound__c = null) FROM OffersPromotions__c WHERE Id =: offerId];
        return returnOffer;
    }

    /*
    * Logic: Save the information from the Loss Calculation screen.
    */
    @AuraEnabled
    public static string saveUnitSelection(string unitSelectionDetails, String srId, String recordTypeName){
        List<UnitDetailModel> unitDetails = (List<UnitDetailModel>)json.deserialize(unitSelectionDetails, List<UnitDetailModel>.Class);
        System.debug('unitDetails>>>' + unitDetails);

        HexaBPM__Service_Request__c serviceRequest = new HexaBPM__Service_Request__c();
        serviceRequest.Id = srId;
        Integer optionNo, previousOptionNo;
        String unitCodes = '';
        Decimal equityRefund = 0;
        Decimal lossAmount = 0;
        Decimal lossPercent=0;
        //Decimal totalEquityForPercentage =0;

        List<SRUnitSelected__c> srUnitSelectedList = new List<SRUnitSelected__c>();
        for (UnitDetailModel unit :unitDetails) {
            SRUnitSelected__c srUnitSelected = new SRUnitSelected__c();
            if (String.isNotBlank(unit.Id)) {
                srUnitSelected.Id = unit.Id;
            } else {
                srUnitSelected.ServiceRequest__c = srId;
            }
            if (String.isNotBlank(unitCodes)) {
                unitCodes += ', ' + unit.unitNo;
            } else {
                unitCodes += unit.unitNo;
            }
            
            srUnitSelected.Name = unit.unitNo;
            srUnitSelected.SalesOrder__c = unit.soId;
            srUnitSelected.Unit__c = unit.unitId;
            srUnitSelected.OptionSelected__c = unit.option1 == true ? Constants.REFUND_OPTION_1 : unit.option2 == true ? Constants.REFUND_OPTION_2 : unit.option3 == true ? Constants.REFUND_OPTION_3 : unit.option4 == true ? Constants.REFUND_OPTION_4 :null;
            srUnitSelected.IsFullRefund__c = unit.isFullRefund;
            srUnitSelected.ServiceCharge__c = unit.serviceCharge;
            srUnitSelected.DistrictCooling__c = unit.districtCooling;
            srUnitSelected.ADDCAssumption__c = unit.ADDCAssumption;
            srUnitSelected.LegalfeesVAT__c = unit.legalfeesVAT;
            srUnitSelected.AdditionalForfeitedAmount__c = unit.additionalForfeitedAmount;
            srUnitSelected.ADMWaiverPercentage__c = unit.ADMWaiver;
            srUnitSelected.RebatePercentage__c = unit.rebate;
            srUnitSelected.DarnaPercentage__c = unit.darna;
            srUnitSelected.SalesSupportCostAED__c = unit.salesSupportCost;
            srUnitSelected.VoucherAED__c = unit.voucher;
            srUnitSelected.SCWaiverYears__c = unit.SCWaiver;
            srUnitSelected.SCWaivedAmount__c = unit.SCWaivedAmount;
            srUnitSelected.ExternalCommission__c = unit.externalCommission;
            srUnitSelected.InternalCommission__c = unit.internalCommission;
            srUnitSelected.TotalBilledAmount__c = unit.totalInstallmentReceived;
            srUnitSelected.ForfeitAmount__c = unit.option1 == true ? unit.lossCalculation1 : unit.option2 == true ? unit.lossCalculation2 : unit.option3 == true ? unit.lossCalculation3 : unit.option4 == true ? unit.lossCalculation4:0;
            srUnitSelected.RetainedAmount__c = srUnitSelected.TotalBilledAmount__c - srUnitSelected.ForfeitAmount__c;
            srUnitSelected.OutstandingAmount__c = unit.totalOutstanding;
            srUnitSelected.Other_Loss_Calculation__c = unit.OtherLossCalcutation;

            if (recordTypeName == Constants.CONSOLIDATION_RT) {
                srUnitSelected.RetainedCancelled__c = unit.retainedUnit ? Constants.RETAINED_UNIT : Constants.CANCELLED_UNIT;
            }

            srUnitSelectedList.add(srUnitSelected);

            equityRefund += unit.option1 == true ? unit.equityRefund1 : unit.option2 == true ? unit.equityRefund2 : unit.option3 == true ? unit.equityRefund3 : unit.option4 == true ? unit.equityRefund4:0;
            lossAmount += unit.option1 == true ? unit.lossCalculation1 : unit.option2 == true ? unit.lossCalculation2 : unit.option3 == true ? unit.lossCalculation3 : unit.option4 == true ? unit.lossCalculation4:0;
            optionNo = unit.option1 == true ? 1 : unit.option2 == true ? 2 : unit.option3 == true ? 3 : 4;
            if (String.isBlank(serviceRequest.CancellationOption__c)) {
                previousOptionNo = optionNo;
                serviceRequest.CancellationOption__c = unit.option1 == true ? Constants.REFUND_OPTION_1 : unit.option2 == true ? Constants.REFUND_OPTION_2 : unit.option3 == true ? Constants.REFUND_OPTION_3 : Constants.REFUND_OPTION_4;
            } else if (optionNo < previousOptionNo) {
                serviceRequest.CancellationOption__c = unit.option1 == true ? Constants.REFUND_OPTION_1 : unit.option2 == true ? Constants.REFUND_OPTION_2 : unit.option3 == true ? Constants.REFUND_OPTION_3 : Constants.REFUND_OPTION_4;
                previousOptionNo = optionNo;
            }
        }
        serviceRequest.UnitCodes__c = unitCodes;
        serviceRequest.IsRefundApplicable__c = equityRefund > 0 ? true : false;
        serviceRequest.Refund_Amount__c = equityRefund > 0 ? equityRefund.intValue() : 0;
        if(equityRefund > 0)
        {
            //if(lossAmount ==0)
            //{
             //   lossAmount=1;
            //}
            lossPercent = equityRefund/(equityRefund + lossAmount) * 100 ;
            
        }
        serviceRequest.Refund_Amount_Percentage__c =lossPercent;
        if (!srUnitSelectedList.isEmpty()) {
            upsert srUnitSelectedList;
            update serviceRequest;
        }
        return 'Success';
    }
}