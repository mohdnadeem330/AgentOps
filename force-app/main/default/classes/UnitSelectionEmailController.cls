/*
* Purpose: Retrieve Selected Unit Details in order to create a table in the Email Template.
* SR Type: Mutual Cancellation and Consolidation
*/
global with sharing class UnitSelectionEmailController {

    global String srId{get;set;}
    
    global UnitSelectionEmailController() {}

    global List<SRUnitSelected__c> reqList{
        get{
            HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{srId})[0];
            
            List<SRUnitSelected__c> unitsToDisplay = new List<SRUnitSelected__c>();
            for (SRUnitSelected__c unit: serviceRequest.SRUnitSelected__r) {
                unitsToDisplay.add(unit);
            }
            return unitsToDisplay;
        }
        set;
    }

    global List<UnitSelectionEmailModel> reqCancelledList{
        get{
            HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{srId})[0];
            
            UnitSelectionEmailModel unitSelection = new UnitSelectionEmailModel();
            unitSelection.unitName = 'Total';
            unitSelection.unitArea = '';
            unitSelection.currencyIsoCode = '';
            unitSelection.netAmount = 0;
            unitSelection.totalInstallmentReceived = 0;
            unitSelection.totalOutstanding = 0;
            unitSelection.equity = '';
            unitSelection.paymentPlan = '';
            unitSelection.lossCalculation = 0;
            unitSelection.equityRefund = 0;

            List<UnitSelectionEmailModel> unitsToDisplay = new List<UnitSelectionEmailModel>();
            for (SRUnitSelected__c unit: serviceRequest.SRUnitSelected__r) {
                if (unit.RetainedCancelled__c == Constants.CANCELLED_UNIT) {
                    unitsToDisplay.add(new UnitSelectionEmailModel(unit));
                    unitSelection.netAmount += unit.SalesOrder__r.NetAmount__c;
                    unitSelection.totalInstallmentReceived += unit.SalesOrder__r.TotalBilled__c;
                    unitSelection.totalOutstanding += unit.SalesOrder__r.TotalOutstanding__c;
                    unitSelection.lossCalculation += unit.FinalLossCalculation__c;
                    unitSelection.equityRefund += unit.FinalEquityRefund__c;
                    unitSelection.currencyIsoCode = unit.CurrencyIsoCode;
                }
            }
            unitsToDisplay.add(unitSelection);
            return unitsToDisplay;
        }
        set;
    }

    global List<UnitSelectionEmailModel> reqRetainedList{
        get{
            HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{srId})[0];
            
            UnitSelectionEmailModel unitSelection = new UnitSelectionEmailModel();
            unitSelection.unitName = 'Total';
            unitSelection.unitArea = '';
            unitSelection.currencyIsoCode = '';
            unitSelection.netAmount = 0;
            unitSelection.totalInstallmentReceived = 0;
            unitSelection.totalOutstanding = 0;
            unitSelection.equity = '';
            unitSelection.paymentPlan = '';
            unitSelection.cancelledUnitEquity = 0;
            unitSelection.aldarLoss = 0;
            unitSelection.equityShifted = 0;
            unitSelection.equityRefund = 0;

            List<UnitSelectionEmailModel> unitsToDisplay = new List<UnitSelectionEmailModel>();
            for (SRUnitSelected__c unit: serviceRequest.SRUnitSelected__r) {
                if (unit.RetainedCancelled__c == Constants.RETAINED_UNIT) {
                    unitsToDisplay.add(new UnitSelectionEmailModel(unit));
                    unitSelection.netAmount += unit.SalesOrder__r.NetAmount__c;
                    unitSelection.totalInstallmentReceived += unit.SalesOrder__r.TotalBilled__c;
                    unitSelection.totalOutstanding += unit.SalesOrder__r.TotalOutstanding__c;
                    unitSelection.currencyIsoCode = unit.CurrencyIsoCode;
                }
                if (unit.RetainedCancelled__c == Constants.CANCELLED_UNIT) {
                    unitSelection.cancelledUnitEquity += unit.SalesOrder__r.TotalBilled__c;
                    unitSelection.aldarLoss += unit.FinalLossCalculation__c;
                    unitSelection.equityRefund += unit.FinalEquityRefund__c;
                }
            }
            unitSelection.equityShifted = unitSelection.equityRefund >= 0 ? unitSelection.equityRefund : 0;
            unitSelection.balanceAfterEquityShifted = unitSelection.totalOutstanding - unitSelection.equityShifted;
            unitsToDisplay.add(unitSelection);
            return unitsToDisplay;
        }
        set;
    }
}