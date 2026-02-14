/*
* SR Type : Payment Plan Change
* Purpose : to validate if there is an Installment without Receipt and create Sales Order Other Charges for ADM if needed
*/
global without sharing class CC_PPCReceiptAdjustment implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_PPCReceiptAdjustment: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, ProposalPaymentPlan__c, SalesOrder__c, Unit__c, Unit__r.BuildingSectionName__r.TaxPercentage__c, NewNetAmount__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c, HexaBPM__Contact__c, SummaryReport__c
                  , ADMToBeCharged__c, SalesOrder__r.ADMFeeAmount__c, SalesOrder__r.ADMFeeWaivedAmount__c, Unit__r.Project__r.ExcludeFromADM__c, SalesOrder__r.Account__c FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];

                 List<String> errorsMessages = new List<String>();

                if(sRRecord.ProposalPaymentPlan__c == null){
                    errorsMessages.add(Utilities.getSystemMessages(Constants.PROPOSAL_PAYMENT_PLAN_VALIDATION).Message__c);
                }

                if(!errorsMessages.isEmpty()){
                    return errorsMessages.toString().replace(',','\n');
                }

                // to get Installment Lines List related to SO
                list<InstallmentLines__c>  installmentLinesList = PaymentPlanFromSRController.getInstallmentLineswithoutHandover(sRRecord.SalesOrder__c);
                List<ReceiptAllocation__c> receiptAllocationList = [Select Id, ReceiptAcknowledgement__c, ReceiptAcknowledgement__r.Amount__c,ReceiptAcknowledgement__r.Account__c, ReceiptAcknowledgement__r.ServiceRequest__c, InstallmentLine__c From ReceiptAllocation__c Where InstallmentLine__c In : installmentLinesList];

                Map<Id, ReceiptAllocation__c> installmentWithReceiptAllocation = new Map<Id, ReceiptAllocation__c>();

                for (ReceiptAllocation__c ra : receiptAllocationList) {
                    installmentWithReceiptAllocation.put(ra.InstallmentLine__c, ra);
                }
                // to check if there is an Installment without Receipt
                for (InstallmentLines__c il : installmentLinesList) {
                    if(!installmentWithReceiptAllocation.containsKey(il.Id)){
                        throw new CustomException(Utilities.getSystemMessages(Constants.INSTALLMENT_WITHOUT_RECEIPT).Message__c);
                    }
                }

                // calculate ADM to be charged and create SalesOrderOtherCharges__c record
                Decimal ADMToBeCharged =  (sRRecord.NewNetAmount__c * 0.02).setScale(2);

                if( (ADMToBeCharged - sRRecord.SalesOrder__r.ADMFeeAmount__c  ) >0){
                    ADMToBeCharged = (ADMToBeCharged - sRRecord.SalesOrder__r.ADMFeeAmount__c).setScale(2);

                    if(ADMToBeCharged > 0 && sRRecord.Unit__r.Project__r.ExcludeFromADM__c ==false ){
                        List<id> soOtherChargesList = new List<id>();
                        SalesOrderOtherCharges__c soOtherCharges = new SalesOrderOtherCharges__c(Amount__c = ADMToBeCharged.setScale(2), SalesOrder__c = sRRecord.SalesOrder__c,TypeOfCharge__c = Constants.BUDGET_LINE_ADMFEE, Opportunity__c=sRRecord.SalesOrder__r.Opportunity__c , Account__c=sRRecord.SalesOrder__r.Account__c, SyncStatus__c='In Progress');
                        insert soOtherCharges;
                        
                        //adding for syncing the new ADM Charges created for the difference amount
                        soOtherChargesList.add(soOtherCharges.id);
                        ALDOC_OtherChargesHelper.executeUponApproval(soOtherChargesList);
                    }

                    
                    if(sRRecord.Unit__r.Project__r.ExcludeFromADM__c ==true){
                        SalesOrder__c so = new SalesOrder__c(Id= sRRecord.SalesOrder__c, ADMFeeAmount__c = null, ADMFeeWaivedAmount__c = null);
                        update so;
                    }
                }

            } 
        } catch(Exception e){
            result = e.getMessage()+', '+e.getLineNumber()+' :CC_PPCReceiptAdjustment';
        }
        return result;
    }
}