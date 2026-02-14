/*
* SR Type : Payment Extension
* Purpose : To approve and update the installment date to the new extension date, post service charge payment
*/
global without sharing class CC_SCApproveExtensionRequest implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_SCApproveExtensionRequest : Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, InstallmentLine__c, PaymentExtensionDate__c, PaymentExtensionPeriod__c, ReceiptAcknowledgement__c, ReceiptAcknowledgement__r.Status__c, ReceiptAcknowledgement__r.StatusReason__c,HexaBPM__Customer__c,SalesOrder__c,ChargeCollected__c,Exceptional_Reason__c,Amount__c,ChargeType__c,Credit_Note_Sub_Type__c,SalesOrder__r.Opportunity__c,HexaBPM__Contact__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                //--- update instalment date

                if(stp.Step_Template_Code__c == 'Charge Fees'){
                    if(stp.HexaBPM__Step_Status__c == 'Customer Not Paid'){
                        string receiptStatus = [SELECT Status__c FROM ReceiptAcknowledgement__c WHERE ServiceRequest__c =:sRRecord.Id AND Receipt_Type__c = 'Charge Fee' order by createddate DESC LIMIT 1]?.Status__c;
                        if(string.IsBlank(receiptStatus)){
                            return 'No related charge fee type receipt found for this service request.';
                        } else {
                            if(receiptStatus == 'Received' || receiptStatus == 'Cleared') {
                                return 'Receipt status shows customer has already paid.';
                            }
                        }
                    } else {
                        InstallmentLines__c instLine = new InstallmentLines__c(Id=sRRecord.InstallmentLine__c, InstallmentDate__c=sRRecord.PaymentExtensionDate__c);
                        update instLine;
                        PaymentExtensionCalloutHelper.getDataForCallout(new List<Id>{stp.HexaBPM__SR__c});
                    }               
                }
            } 
        } catch(Exception e){
            result = e.getMessage()+' :CC_SCApproveExtensionRequest';
        }
        return result;
    }
}