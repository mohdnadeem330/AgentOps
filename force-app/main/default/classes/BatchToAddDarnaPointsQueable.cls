public class BatchToAddDarnaPointsQueable implements Queueable,Database.AllowsCallouts {
    Map<String,List<ReceiptAllocation__c>> receiptAllocMap = new Map<String,List<ReceiptAllocation__c>>();
    public BatchToAddDarnaPointsQueable(Map<String,List<ReceiptAllocation__c>> receiptAllocMap){
        this.receiptAllocMap = receiptAllocMap;
    }
    public void execute(QueueableContext context) {
        Decimal receiptAmt = 0;
        List<Object> capillaryAddPointsBulkRequestArray = new List<Object>();
        Map<Id,Decimal> reciptAllocTotalValueMap = new Map<Id,Decimal>();
        /** Identfy the customer eligible to apply with already allocated DARNA Amount ***/
        /********************************************************************************/
        for(String prjConceptId: receiptAllocMap.keySet()){
            for (ReceiptAllocation__c receipt : receiptAllocMap.get(prjConceptId)) {
                Decimal amountAppliedBal = 0;//integer i=69; *** TESTING PURPOSE ***
                Decimal darnaAmtProcessed = ((receipt.ReceiptAcknowledgement__r.DarnaAmountProcessed__c !=null 
                                              ?receipt.ReceiptAcknowledgement__r.DarnaAmountProcessed__c:0)
                                             + (!reciptAllocTotalValueMap.isEmpty() && reciptAllocTotalValueMap.containsKey(receipt.ReceiptAcknowledgement__c)? 
                                                reciptAllocTotalValueMap.get(receipt.ReceiptAcknowledgement__c):receipt.AmountApplied__c));
                
                //System.debug('darnaAmtProcessed:'+darnaAmtProcessed);
                if(receipt.InstallmentLine__c!=null && receipt.AmountApplied__c > 0 && receipt.ReceiptAcknowledgement__r.Installment_Amount__c > 0){ 
                   if(receipt.ReceiptAcknowledgement__r.Installment_Amount__c >= darnaAmtProcessed){ //*** Newly added check ******//
                       amountAppliedBal = receipt.AmountApplied__c;
                   }else{
                       amountAppliedBal = receipt.ReceiptAcknowledgement__r.Installment_Amount__c - receipt.ReceiptAcknowledgement__r.DarnaAmountProcessed__c;
                   }
                  //  System.debug('amountAppliedBal:'+amountAppliedBal);
            	}
                if(amountAppliedBal > 0){
                    system.debug('Receipt Id:'+receipt.Id);
                    if(!reciptAllocTotalValueMap.isEmpty() && reciptAllocTotalValueMap.containsKey(receipt.ReceiptAcknowledgement__c)){                  
                        reciptAllocTotalValueMap.put(receipt.ReceiptAcknowledgement__c,reciptAllocTotalValueMap.get(receipt.ReceiptAcknowledgement__c)
                                                     +receipt.AmountApplied__c);
                    }else{
                        reciptAllocTotalValueMap.put(receipt.ReceiptAcknowledgement__c,receipt.AmountApplied__c); 
                    }
                    Map<String, Object> capillaryRecord = new Map<String, Object>();
                    Map<String,Object> eachLineItemsMap = new Map<String,Object>();
                    List<Object> eachReceiptAckLineItemsList = new List<Object>();
                    
                    Map<String,Object> payItemsMap = new Map<String,Object>();
                    List<Object> paymentMethodList = new List<Object>();
                    Map<String,Object> customFieldMapping = new Map<String,Object>();
                    Map<String,Object> custombookingdateMapping = new Map<String,Object>();
                    
                    if(receipt.Account__r.PersonMobilePhone <> null) {
                        capillaryRecord.put('identifierType','mobile');
                        capillaryRecord.put('identifierValue',receipt.Account__r.PersonMobilePhone);
                    }
                    else {
                        capillaryRecord.put('identifierType','email');
                        capillaryRecord.put('identifierValue',receipt.Account__r.PersonEmail);
                    }
                    
                    /**** NEWLY ADDED REQUEST PARAMETER **********/
                    capillaryRecord.put('grossAmount',String.valueOf(receipt.InstallmentLine__r.InstallmentAmount__c));
                    payItemsMap.put('mode',receipt.ReceiptAcknowledgement__r.PaymentType__c);
                    payItemsMap.put('value',String.valueOf(receipt.AmountApplied__c));
                    payItemsMap.put('notes','');
                    paymentMethodList.add(payItemsMap);
                    capillaryRecord.put('paymentModes',paymentMethodList);
                    
                    customFieldMapping.put('unit_id',receipt.InstallmentLine__r.SalesOrder__r.Unit__r.Name);
                    customFieldMapping.put('property_type',receipt.InstallmentLine__r.SalesOrder__r.Unit__r.PropertyUsage__c);
                    customFieldMapping.put('gross_total_amount',String.valueOf(receipt.InstallmentLine__r.InstallmentAmount__c));
                    customFieldMapping.put('net_amount',String.valueOf(receipt.InstallmentLine__r.SalesOrder__r.NetAmount__c));
                    customFieldMapping.put('currency','AED');
                    //customFieldMapping.put('paid_amount','');
                    // customFieldMapping.put('charge_id','');
                    customFieldMapping.put('description',receipt.InstallmentLine__r.Description__c);
                    customFieldMapping.put('community_name',receipt.InstallmentLine__r.SalesOrder__r.Unit__r.CommunityName__c);
                    // customFieldMapping.put('community_id','');
                    customFieldMapping.put('number_of_instalments',String.valueOf(receipt.InstallmentLine__r.SalesOrder__r.TotalInstallmentNo__c));
                    customFieldMapping.put('instalment_number',String.valueOf(receipt.InstallmentLine__r.InstallmentNumber__c));
                    customFieldMapping.put('instalment_due_date',receipt.InstallmentLine__r.InstallmentDate__c);
                    customFieldMapping.put('is_handover_payment',receipt.InstallmentLine__r.HandoverPayment__c?'true':'false');
                    customFieldMapping.put('bookingdate',receipt.InstallmentLine__r.Description__c);
                    capillaryRecord.put('customFields',customFieldMapping);
                    /****** NEWLY ADDED REQUEST PARAMETER ********/
                    
                    capillaryRecord.put('source','INSTORE');
                    
                    capillaryRecord.put('billNumber',receipt.Id.to15()+'_'+receipt.ReceiptAcknowledgement__c.to15()+'_'+receipt.InstallmentLine__c.to15());//+':'+i);

                    capillaryRecord.put('discount',0);
                    capillaryRecord.put('billingDate',String.valueOf((DateTime)receipt.ReceiptAcknowledgement__r.ClearedDate__c));
                    eachLineItemsMap.put('itemCode',receipt.InstallmentLine__r.Name);
                    eachLineItemsMap.put('qty',1);
                    eachLineItemsMap.put('amount',amountAppliedBal);
                    capillaryRecord.put('billAmount',amountAppliedBal);
                    eachLineItemsMap.put('discount',0);
                    eachLineItemsMap.put('value',receipt.InstallmentLine__r.InstallmentAmount__c);
                    eachLineItemsMap.put('rate',receipt.InstallmentLine__r.InstallmentAmount__c);
                    eachLineItemsMap.put('description',receipt.InstallmentLine__r.Description__c);
                    eachReceiptAckLineItemsList.add(eachLineItemsMap);       
                    capillaryRecord.put('lineItemsV2',eachReceiptAckLineItemsList);
                    capillaryRecord.put('type','REGULAR');
                    capillaryRecord.put('returnType','FULL');
                    //**** NEW REQUEST FROM CAPILLARY *****//
                    custombookingdateMapping.put('booking_date',(Object)receipt.InstallmentLine__r.SalesOrder__r.BookingDate__c);
                    capillaryRecord.put('extendedFields',custombookingdateMapping);
                    /*** TESTING ****/
                    //capillaryRecord.put('billAmount',49000);
                    capillaryAddPointsBulkRequestArray.add(capillaryRecord);
                }
            }
            if(!capillaryAddPointsBulkRequestArray.isEmpty()){
                System.debug('requestBody>>>' + JSON.serializePretty(capillaryAddPointsBulkRequestArray));
                String requestBody = JSON.serialize(capillaryAddPointsBulkRequestArray);
                DarnaServices.addPointsAPI(requestBody,prjConceptId);
            }
        }
        
    }
}