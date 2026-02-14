/**********************************************************************************************************************
* Name               : CreateWriteOffReceipt                                                        
* Description        : This Apex class/ Rest Service is getting used for the receipt write off and adjustment.
* Created By         : bakhan@aldar.com - bashim                                                   
******************************************************************************************************************/
@RestResource (urlMapping = '/create/receiptWriteOff')
global class CreateWriteOffReceipt {
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestContextHandler handler = new RestContextHandler(false);
        Set<Id> raIds = new Set<Id>();//receip allocation ids
        Set<Id> installmentOrOtherChargeIds = new Set<Id>();
        WriteOffResponse res = new WriteOffResponse();
        Set<String> erpIds = new Set<String>();
        Map<String, ReceiptAllocation__c> mapERPIdReAlloc =  new Map<String, ReceiptAllocation__c>();
        List<ReceiptAllocation__c> reAllocUpdate = new List<ReceiptAllocation__c>();
        List<ReceiptAllocation__c> reAllocInsert = new List<ReceiptAllocation__c>();
        try{
            /* sample json request body for this rest service
            [
             {
              "RECEIPTACKNOWLEDGEMENT__C": "a248d000000F4ukAAC",
              "AMOUNTAPPLIED__C": ".25",
              "DATEOFAPPLICATION__C": "2023-08-25",
              "ERPID__C": "5450451",
              "TYPEOFINVOICE__C": "Writeoff",
              "UNAPPLY__C": "false"
              }
            ] */
            List<ReceiptAllocation__c> lstReceiptAllocation = (List<ReceiptAllocation__c>) JSON.deserialize(handler.getRequestBody(),List<ReceiptAllocation__c>.class);
            for(ReceiptAllocation__c ra : lstReceiptAllocation){
                erpIds.add(ra.ERPId__c);
                ra.ReceiptWriteOff__c = true;
                if(ra.DATEOFAPPLICATION__C != null)
                	ra.DATEOFAPPLICATION__C = Date.valueOf(String.valueof(ra.DATEOFAPPLICATION__C));
                raIds.add(ra.RECEIPTACKNOWLEDGEMENT__C);
                if(ra.TYPEOFINVOICE__C == ReceiptAllocationConstants.RECEIPT_ALLOCATION_TYPEOFINVOICE_ADJUSTMENT){
                    installmentOrOtherChargeIds.add(ra.InstallmentLine__c);
                }
            }
            for(ReceiptAllocation__c ralloc : [SELECT Id, ERPId__c, Unapply__c 
                                               FROM ReceiptAllocation__c 
                                               WHERE  ERPId__c IN : erpIds]){
                mapERPIdReAlloc.put(ralloc.ERPId__c,ralloc);
            }
            Map<Id,InstallmentLines__c> mapIdInstallment = new Map<Id,InstallmentLines__c>();
            Map<Id,SalesOrderOtherCharges__c> mapIdOtherCharges = new Map<Id,SalesOrderOtherCharges__c>();
            for(InstallmentLines__c inst : [SELECT Id FROM InstallmentLines__c WHERE Id IN : installmentOrOtherChargeIds]){
                mapIdInstallment.put(inst.Id,inst);
            }
            for(SalesOrderOtherCharges__c otherCharge : [SELECT Id FROM SalesOrderOtherCharges__c WHERE Id IN : installmentOrOtherChargeIds]){
                mapIdOtherCharges.put(otherCharge.Id,otherCharge);
            }
            Map<Id,ReceiptAcknowledgement__c> mapIdReceiptAck =  new Map<Id,ReceiptAcknowledgement__c>([SELECT Id, Account__c, SalesOrder__c FROM ReceiptAcknowledgement__c WHERE Id IN : raIds]);                
            for(ReceiptAllocation__c ra : lstReceiptAllocation){
                
                if(mapIdReceiptAck.containsKey(ra.ReceiptAcknowledgement__c)){
                    ra.Account__c = mapIdReceiptAck.get(ra.ReceiptAcknowledgement__c).Account__c;
                    ra.SalesOrder__c = mapIdReceiptAck.get(ra.ReceiptAcknowledgement__c).SalesOrder__c;
                }
               
                if(ra.TypeOfInvoice__c == ReceiptAllocationConstants.RECEIPT_ALLOCATION_TYPEOFINVOICE_ADJUSTMENT){
                    if(mapIdInstallment.containskey(ra.InstallmentLine__c)){
                        ra.InstallmentLine__c = mapIdInstallment.get(ra.InstallmentLine__c).Id;
                    } else if(mapIdOtherCharges.containskey(ra.InstallmentLine__c)){
                        ra.SalesOrderOtherCharges__c = mapIdOtherCharges.get(ra.InstallmentLine__c).Id;
                        ra.InstallmentLine__c = null;
                    }
                }
                if(!mapERPIdReAlloc.isEmpty() && mapERPIdReAlloc.containsKey(ra.ERPID__c)){
                    ra.Id = mapERPIdReAlloc.get(ra.ERPID__c).Id;
                    ra.AMOUNTAPPLIED__C = mapERPIdReAlloc.get(ra.ERPID__c).Unapply__c?0:ra.AMOUNTAPPLIED__C;
                    reAllocUpdate.add(ra);
                } else{
                    reAllocInsert.add(ra);
                }
            }
            
            if(!reAllocUpdate.isEmpty()){
				update reAllocUpdate;                
            }
            if(!reAllocInsert.isEmpty()){
				insert reAllocInsert;                
            }
            res.TYPEOFINVOICE = lstReceiptAllocation[0].TypeOfInvoice__c;
            res.ERPID = lstReceiptAllocation[0].ERPID__c;
            res.Status = 'success';
            res.ErrorMsg = '';
            handler.response.success = true;
            handler.response.statusCode = Constants.STATUS_CODE_SUCCESS;
            handler.response.data = res;
            handler.finalize();
        } catch(Exception e){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = 'An error occurred: ' + e.getMessage();
            res.Status = 'error';
            res.ErrorMsg = handler.response.message;
            handler.response.data = res;
            handler.finalize(e);
        }
    }
}