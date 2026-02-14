/*
* SR Type : Cheque Replacement
* Purpose : To approve and replace the old RA with new RA
*/
global without sharing class CC_ChequeReplacementFinalApproval implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_ChequeReplacementFinalApproval: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, HexaBPM__Parent_SR__c, HexaBPM__Parent_SR__r.Recordtype.Name, ReceiptAcknowledgement__c, ReceiptAcknowledgement__r.Status__c, InstallmentLine__c, InstallmentLine__r.InstallmentAmount__c, InstallmentLine__r.InstallmentDate__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];

                if(sRRecord.ReceiptAcknowledgement__c == null){
                    return Utilities.getSystemMessages(Constants.RECEIPT_ACKNOWLEDGEMENT_SR_VALIDATION).Message__c;
                }

                if(sRRecord.ReceiptAcknowledgement__r.Status__c != Constants.RECEIVED_PAYMENT_STATUS && sRRecord.ReceiptAcknowledgement__r.Status__c != Constants.CONFIRMED_PAYMENT_STATUS && sRRecord.ReceiptAcknowledgement__r.Status__c != Constants.REMITTED_PAYMENT_STATUS && sRRecord.ReceiptAcknowledgement__r.Status__c != Constants.REVERSED_PAYMENT_STATUS){
                    return Utilities.getSystemMessages(Constants.RECEIVED_RECEIPT_ACKNOWLEDGEMENT_SR).Message__c;
                }

                //--- Get old RA details 
                ReceiptAcknowledgement__c ra = ReceiptAcknowledgementService.getReceiptAcknowledgementById(sRRecord.ReceiptAcknowledgement__c)[0];

                ReceiptAcknowledgement__c newRA = new ReceiptAcknowledgement__c();
                
                newRA.Opportunity__c = ra.Opportunity__c;
                newRA.Account__c = ra.Account__c;
                newRA.Contact__c = ra.Contact__c;
                newRA.SalesOrder__c = ra.SalesOrder__c;
                newRA.Amount__c = ra.Amount__c;
                newRA.PaymentType__c = Constants.CHEQUE;
                newRA.ServiceRequest__c = sRRecord.Id;
                newRA.MaturityDate__c = sRRecord.InstallmentLine__r.InstallmentDate__c;

                if(sRRecord.HexaBPM__Parent_SR__r.Recordtype.Name == Constants.RTO_EXTENSION_RT){
                    newRA.MaturityDate__c = ra.MaturityDate__c;
                    newRA.PaymentType__c = ra.PaymentType__c;
                }
                // to update exsisting record if the Cheque Replacement SR created from Paymnet Plan Change SR
                if(sRRecord.HexaBPM__Parent_SR__r.Recordtype.Name == Constants.PAYMENT_PLAN_CHANGE_RT){

                    if(sRRecord.InstallmentLine__c == null){
                        return Utilities.getSystemMessages(Constants.INSTALLMENT_LINE_VALIDATION).Message__c;
                    }
                    newRA.Amount__c = sRRecord.InstallmentLine__r.InstallmentAmount__c;
                }
                insert newRA;

                List<ReceiptAllocation__c> rAllocation = [SELECT Id, ReceiptAcknowledgement__c FROM ReceiptAllocation__c WHERE ReceiptAcknowledgement__c =: ra.Id];

                // update Receipt Allocation
                if(!rAllocation.isEmpty()){
                    rAllocation[0].ReceiptAcknowledgement__c = newRA.Id;
                    rAllocation[0].AmountApplied__c = newRA.Amount__c;
                    update rAllocation[0];
                }
                ra.ReceiptAcknowledgement__c = newRA.Id;
                if(ra.Status__c == Constants.RECEIVED_PAYMENT_STATUS){
                    ra.Status__c = Constants.REVERSED_PAYMENT_STATUS;
                    ra.StatusReason__c = Constants.CHEQUE_REPLACED_STATUS_REASON;
                }
                update ra;
            } 
        } catch(Exception e){
            result = e.getMessage()+' :CC_ChequeReplacementFinalApproval';
        }
        return result;
    }
}