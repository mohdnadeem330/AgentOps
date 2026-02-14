/*
* SR Type : LPC Waiver
* Purpose : Used when step is not closed in 7 days to reinitiate SR by refreshing the LPC information
*/
global without sharing class CC_LPCWaverReinitiateSR implements HexaBPM.iCustomCodeExecutable {
    

    /*
    * Method used to refresh LPC information
    */
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_LPCWaverReinitiateSR: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, IsChargeReceiptCreated__c, TotalLPCAmount__c, TotalLPCDue__c, TotalLPCCollected__c, ChargeCollected__c, TotalLPCWaivedAmount__c, WaivedAmount__c, SalesOrder__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];

                if(sRRecord.SalesOrder__c == null){
                    return result;
                }

                List<ReceiptAcknowledgement__c> ra = new List<ReceiptAcknowledgement__c>();

                if(srRecord.IsChargeReceiptCreated__c){

                    ra = [Select Id, Status__c From ReceiptAcknowledgement__c Where ServiceRequest__c =: srRecord.Id limit 1];
        
                    if(ra.size() > 0 && ra[0].Status__c == Constants.RECEIPT_STATUS_CLEARED){
                        return result;
                    } else {
                        LPCModel lpcDetail = LPCService.getOutstandingLPCforSalesOrder(sRRecord.SalesOrder__c);
                        sRRecord.TotalLPCAmount__c = lpcDetail.totalLPC.setScale(2);
                        sRRecord.TotalLPCDue__c = lpcDetail.totalLPCDue.setScale(2);
                        sRRecord.TotalLPCCollected__c = lpcDetail.lpcPaid.setScale(2);
                        sRRecord.WaivedAmount__c = sRRecord.WaivedAmount__c != null ? sRRecord.WaivedAmount__c  : 0;
                        sRRecord.ChargeCollected__c = (sRRecord.TotalLPCDue__c - sRRecord.WaivedAmount__c).setScale(2);
                        sRRecord.TotalLPCWaivedAmount__c = lpcDetail.lpcWaivedAmount.setScale(2);
                        update sRRecord;

                        ra[0].Amount__c = sRRecord.ChargeCollected__c;
                        update ra[0];

                        List<ReceiptAllocation__c> allocationRecord = [Select Id, AmountApplied__c, ReceiptAcknowledgement__c From ReceiptAllocation__c Where ReceiptAcknowledgement__c =: ra[0].Id Limit 1];
                
                        if(allocationRecord.size() > 0){
                            allocationRecord[0].AmountApplied__c = ra[0].Amount__c;
                            update allocationRecord[0];
                        }
                    }
                } else {
                    LPCModel lpcDetail = LPCService.getOutstandingLPCforSalesOrder(sRRecord.SalesOrder__c);
                    sRRecord.TotalLPCAmount__c = lpcDetail.totalLPC.setScale(2);
                    sRRecord.TotalLPCDue__c = lpcDetail.totalLPCDue.setScale(2);
                    sRRecord.TotalLPCCollected__c = lpcDetail.lpcPaid.setScale(2);
                    sRRecord.WaivedAmount__c = sRRecord.WaivedAmount__c != null ? sRRecord.WaivedAmount__c  : 0;
                    sRRecord.ChargeCollected__c = (sRRecord.TotalLPCDue__c - sRRecord.WaivedAmount__c).setScale(2);
                    sRRecord.TotalLPCWaivedAmount__c = lpcDetail.lpcWaivedAmount.setScale(2);
                    update sRRecord;
                }
            } 
        } catch(Exception e){
            result = e.getMessage()+' :CC_LPCWaverReinitiateSR';
        }
        return result;
    }
}