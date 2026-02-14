public with sharing class RefreshLPCFromSRController {
    
    //--- Used to refresh LPC for the SalesOrder
    @AuraEnabled(cacheable=false)
    public static String getOutstandingLPCforSalesOrder(String srId){

        HexaBPM__Service_Request__c srRecord = [SELECT Id, WaivedBy__c, SalesOrder__c, WaivedAmount__c, WaivedPercentage__c, IsChargeReceiptCreated__c FROM HexaBPM__Service_Request__c WHERE Id=: srId];

        // check if the WaivedBy__c field is populated
        if(String.isBlank(srRecord.WaivedBy__c)){
            return Utilities.getSystemMessages(Constants.LPC_WAIVED_BY_VALIDATION).Message__c;
        }

        List<ReceiptAcknowledgement__c> ra = new List<ReceiptAcknowledgement__c>();

        // check if the RA is already created then raise error.
        if(srRecord.IsChargeReceiptCreated__c){

            ra = [Select Id, Status__c From ReceiptAcknowledgement__c Where ServiceRequest__c =: srRecord.Id limit 1];

            if(ra.size() > 0 && ra[0].Status__c == Constants.RECEIPT_STATUS_CLEARED){
                return 'Receipt is already entered, Cannot Update LPC Information';
            }
        }

        // update LPC SR details
        LPCModel lpcDetail = LPCService.getOutstandingLPCforSalesOrder(sRRecord.SalesOrder__c);
        sRRecord.TotalLPCAmount__c = lpcDetail.totalLPC.setScale(2);
        sRRecord.TotalLPCDue__c = lpcDetail.totalLPCDue.setScale(2);
        sRRecord.TotalLPCCollected__c = lpcDetail.lpcPaid.setScale(2);

        Boolean freezeAmount = srRecord.WaivedBy__c == Constants.WAIVED_BY_AMOUNT ? true : false;

        if(freezeAmount){
            sRRecord.WaivedAmount__c = sRRecord.WaivedAmount__c != null ? sRRecord.WaivedAmount__c : 0;
            sRRecord.WaivedPercentage__c = sRRecord.WaivedAmount__c == 0 ? 0 : (sRRecord.WaivedAmount__c / sRRecord.TotalLPCDue__c * 100);
        } else {
            sRRecord.WaivedPercentage__c = sRRecord.WaivedPercentage__c != null ? sRRecord.WaivedPercentage__c : 0;
            sRRecord.WaivedAmount__c = (sRRecord.TotalLPCDue__c * (sRRecord.WaivedPercentage__c/100)).setScale(2);
        }
        
        sRRecord.ChargeCollected__c = (sRRecord.TotalLPCDue__c - (sRRecord.WaivedAmount__c != null ? sRRecord.WaivedAmount__c  : 0)).setScale(2);
        sRRecord.TotalLPCWaivedAmount__c = lpcDetail.lpcWaivedAmount.setScale(2);
        sRRecord.LPCCalculatedDate__c = Date.today();

        update sRRecord;

        // update Receipt Allocation record if exist and if not create a new record
        if(ra.size() > 0){
            ra[0].Amount__c = sRRecord.ChargeCollected__c;
            update ra[0];

            List<ReceiptAllocation__c> allocationRecord = [Select Id, AmountApplied__c, ReceiptAcknowledgement__c From ReceiptAllocation__c Where ReceiptAcknowledgement__c =: ra[0].Id Limit 1];
                
            if(allocationRecord.size() > 0){
                allocationRecord[0].AmountApplied__c = ra[0].Amount__c;
                update allocationRecord[0];
            }
            
        }

        return '';
    }

}