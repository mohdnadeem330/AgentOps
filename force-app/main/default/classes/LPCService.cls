public class LPCService {
    public static Boolean EXCLUDE_LPC_CALCULATION = false ; 
    
    /*
* Method to get number of days between 2 dates
*/
    public static Integer getNumberOfDays(Date fromDate,Date toDate){
        Integer numberDaysBetween = 0 ;
        /*//LPC_CHANGES_WITH_NEW_LOGIC_SS START 05/05/23
        Date freezeUntilDate = freezeDate!=null ? freezeDate.addDays(30) : null;
        if(freezeDate!=null && freezeDate < System.today() && freezeUntilDate > System.today()) { //freezeDate is past and freezeUntilDate is future
        fromDate = freezeDate;
        } 
        //LPC_CHANGES_WITH_NEW_LOGIC_SS END */
        if(toDate != null && fromDate != null){   
            numberDaysBetween = toDate.daysBetween(fromDate);
        }
        // System.debug('freezeDate -> '+freezeDate+' freezeUntilDate -> '+freezeUntilDate+' numberDaysBetween -> '+numberDaysBetween);
        
        System.debug(fromDate+'**Delay Days**'+toDate+'**Delay Days**'+numberDaysBetween);
        return numberDaysBetween ;
    }
    
    /*
* Method to calculated LPC based on the formula
*/
    public static Decimal calculateLPCAmount(Decimal outstandingAmount, Integer days, Decimal lpcPercentage){
        System.debug(outstandingAmount+' outstandingAmount '+lpcPercentage+' '+days);
        Decimal lpcAmount = 0 ;
        lpcAmount = ((outstandingAmount*lpcPercentage)/365) * days ;
        System.debug(lpcAmount+'**LPC Amount for**'+outstandingAmount+'**with days**'+days);
        return lpcAmount ;
    }
    
    /*
* Method to get LPC Amount calculated for the installment based on the dates and the receipts created
*/
    public static Decimal getLPCAmount(InstallmentLines__c installmentLine, List<ReceiptAllocation__c> receiptAllocations,SalesOrder__c orderDetail,Boolean isLastInstallment){
        Decimal lpcAmount = 0 ;
        Decimal outstandingAmount = installmentLine.OutstandingAmount__c ;
        Date fromDate ;
        Date today = Date.today(); 
        Date toDate = installmentLine.InstallmentDate__c ;
        Date previousClearedDate = null ; 
        Decimal dueAmountCounted = 0 ;
        
        if(installmentLine.LPCFreezeDate__c !=null && installmentLine.LPCFreezeUntilDate__c !=null && installmentLine.LPCFreezeUntilDate__c >= Date.today()){
            today = installmentLine.LPCFreezeDate__c ;
            System.debug(installmentLine.LPCFreezeDate__c+'**LPC Freeze Date**'+installmentLine.LPCFreezeUntilDate__c+'**To Date**'+today);
        }
        
        Decimal lpcPercentage = installmentLine.LPCPercentage__c ;
        if(lpcPercentage!=null){
            lpcPercentage = (lpcPercentage/100) ;
        }
        Integer days = 0 ;
        //---- In ERP during LPC waiver this days was considered so all the due till date gets waived off.
        if(installmentLine.ExtensionDate__c!=null){
            toDate = installmentLine.ExtensionDate__c ;
            //installmentLine.InstallmentDate__c  = installmentLine.ExtensionDate__c ; 
        }
        installmentLine.InstallmentDate__c  = (installmentLine.ExtensionDate__c!=null ? installmentLine.ExtensionDate__c : (isLastInstallment? orderDetail.HandoverReadyforOccupancyDate__c : installmentLine.InstallmentDate__c));
        System.debug(installmentLine.InstallmentDate__c+'**toDate**'+toDate);
        //---- Check for last cleared date from the reciepts
        if(receiptAllocations!=null && receiptAllocations.size()>0){
            Decimal totalBalance = 0 ;
            
            for(ReceiptAllocation__c receiptAllocation : receiptAllocations){
                Date startDate = (installmentLine.ExtensionDate__c!=null ? installmentLine.ExtensionDate__c : (isLastInstallment? orderDetail.HandoverReadyforOccupancyDate__c : installmentLine.InstallmentDate__c));
                days = 0 ;
                if(receiptAllocation.ReceiptAcknowledgement__r.ClearedDate__c !=null){
                    Date clearedDate = receiptAllocation.ReceiptAcknowledgement__r.ClearedDate__c ; 
                    //---- If cleared date is before installment date or pay out date then the cleared date is due date
                    if(clearedDate <= startDate || clearedDate <= installmentLine.InstallmentPayoutDate__c){
                        clearedDate = startDate ; 
                    }
                    //---- Check if previous cleared date is null then to date is installment date
                    //TO CALCULATE FIRST RECEIPT LPC
                    if(previousClearedDate==null){
                        //--- LPC should not be calcualted in case the payment was cleared within the Payout Date
                        if(clearedDate <= installmentLine.InstallmentPayoutDate__c){
                            days = 0 ; 
                        }
                        else{
                            Date endDate = clearedDate ; 
                            if(installmentLine.LPCFreezeDate__c !=null && receiptAllocations.size() == 1 && installmentLine.LPCFreezeUntilDate__c !=null && endDate > installmentLine.LPCFreezeDate__c && endDate < installmentLine.LPCFreezeUntilDate__c){
                                endDate = installmentLine.LPCFreezeDate__c ;
                            }
                            
                            days = getNumberOfDays(endDate, startDate); 
                            outstandingAmount = installmentLine.InstallmentAmount__c ; 
                        }
                    }
                    else {
                        //TO CALCULATE ALL OTHERS RECEIPT LPC EXCEPT FIRST
                        if(clearedDate <= installmentLine.InstallmentPayoutDate__c){
                            days = 0 ; 
                        }else{
                            if(installmentLine.LPCFreezeDate__c !=null && installmentLine.LPCFreezeUntilDate__c !=null && clearedDate > installmentLine.LPCFreezeDate__c && clearedDate < installmentLine.LPCFreezeUntilDate__c) {
                                clearedDate = installmentLine.LPCFreezeDate__c ;
                            }
                            if(clearedDate <= installmentLine.InstallmentPayoutDate__c){
                               days = 0; 
                            }else{
                                //---- Check last cleared date and outstanding amount
                                days = getNumberOfDays(clearedDate, previousClearedDate); 
                            } 
                        }  
                        outstandingAmount = installmentLine.InstallmentAmount__c - dueAmountCounted;  
                    }
                    previousClearedDate = clearedDate ;
                    System.debug(receiptAllocation.Name+'**Receipt Allocation Number**'+outstandingAmount+'**previousClearedDate**'+previousClearedDate+'**days**'+days);
                }
                if(days >0){
                    lpcAmount = lpcAmount + calculateLPCAmount (outstandingAmount,days,lpcPercentage);
                    System.debug('**LPC Amount Due -- Receipts**'+lpcAmount);
                } 
                dueAmountCounted = dueAmountCounted + receiptAllocation.AmountApplied__c ;  
                totalBalance = installmentLine.InstallmentAmount__c - dueAmountCounted; 
            }
            if(totalBalance == installmentLine.OutstandingAmount__c && previousClearedDate !=null){
                days = getNumberOfDays(today, previousClearedDate);
                if(days >0){
                    lpcAmount = lpcAmount + calculateLPCAmount (totalBalance,days,lpcPercentage);
                }    
                System.debug('Installment # '+installmentLine.InstallmentNumber__c+'**Last Oustanding -- Receipts**'+lpcAmount);
            }
        }
        // ---- If no receipts exists then calculate the LPC as of today
        else{
            lpcAmount = 0 ; 
            // IF extension date is available then consider that else Installment Date or RFO Date if final installment
            toDate = (installmentLine.ExtensionDate__c!=null ? installmentLine.ExtensionDate__c : (isLastInstallment? orderDetail.HandoverReadyforOccupancyDate__c : installmentLine.InstallmentDate__c));
            outstandingAmount = installmentLine.OutstandingAmount__c ;
            days = getNumberOfDays(today, toDate);
            lpcAmount = calculateLPCAmount (outstandingAmount,days,lpcPercentage);  
            System.debug('**LPC Amount Due -- No Receipts**'+lpcAmount);
        }
        
        System.debug('Installment # '+installmentLine.InstallmentNumber__c+'**Total LPC Amount**'+lpcAmount);
        return lpcAmount ;
    }
    
    /*
* Method to get total LPC for a Sales order
*/
    public static Decimal getLPCForSalesOrder(SalesOrder__c orderDetail, List<InstallmentLines__c> installmentLines,Map<Id,List<ReceiptAllocation__c>> installmentAllocationMap){
        Decimal totalLPCAmount = 0 ;
        Integer installmentsCount = installmentLines.size();
        for(InstallmentLines__c installmentLine : installmentLines){
            
            Boolean isLastInstallment = (installmentsCount == installmentLine.InstallmentNumber__c ? true : false) ;
            
            if(installmentLine.InstallmentNumber__c > 1 && String.isNotBlank(installmentLine.InvoiceNumber__c) && (!isLastInstallment || (isLastInstallment && orderDetail.HandoverReadyforOccupancyDate__c !=null)) && !installmentLine.LPCWaived__c && installmentLine.InstallmentPayoutDate__c < Date.today() && !installmentLine.LPCExcluded__c){
                
                List<ReceiptAllocation__c> receiptAllocationList = (installmentAllocationMap.containsKey(installmentLine.Id) ? installmentAllocationMap.get(installmentLine.Id) :  new List<ReceiptAllocation__c>());
                
                Decimal installmentLPC = LPCService.getLPCAmount(installmentLine,receiptAllocationList,orderDetail,isLastInstallment);
                
                System.debug('**installmentLine**'+installmentLine.InstallmentNumber__c+':'+installmentLPC);
                
                totalLPCAmount = totalLPCAmount + installmentLPC ;
            }
        }
        return totalLPCAmount ; 
    }
    
    /*
* Method to get LPC Total, LPC Collected/Paid, LPC Waived and LPC Due
*/
    public static LPCModel getOutstandingLPCforSalesOrder(Id salesOrderId){
        
        LPCModel lpcDetail = new LPCModel();
        Map<Id,List<ReceiptAllocation__c>> installmentAllocationMap = new Map<Id,List<ReceiptAllocation__c>>();
        
        SalesOrder__c orderDetail = StatementOfAccountController.getSalesOrderDetail(salesOrderId);
        lpcDetail.orderDetail = orderDetail ;
        // Decimal bufferOutstandingAmount = Decimal.valueOf(System.Label.BufferOutstandingAmount) ;
        
        // if (lpcDetail.orderDetail.TotalOutstanding__c > bufferOutstandingAmount) {
        
        //---- Check the LPC Waived and LPC Waived for the Sales Order
        for(SalesOrderOtherCharges__c otherChargeRec : orderDetail.SalesOrdersOtherCharges__r){
            if(otherChargeRec.TypeOfCharge__c == Constants.OTHER_CHARGES_TYPE_LPC_WAIVED_AMOUNT){
                lpcDetail.lpcWaivedAmount = lpcDetail.lpcWaivedAmount + otherChargeRec.Amount__c ;
            }
            else if(otherChargeRec.TypeOfCharge__c == Constants.OTHER_CHARGES_TYPE_LATE_PAYMENT_CHARGES && otherChargeRec.InvoicedAmount__c !=null){
                lpcDetail.lpcPaid = lpcDetail.lpcPaid + otherChargeRec.InvoicedAmount__c ;
            }       
        }
        
        lpcDetail.totalLPCWaivedOrPaid = lpcDetail.lpcPaid + lpcDetail.lpcWaivedAmount ;
        
        if(!LPCService.EXCLUDE_LPC_CALCULATION){
            for(ReceiptAllocation__c receiptAllocationRec : orderDetail.ReceiptAllocations__r){
                List<ReceiptAllocation__c> allocationList = new List<ReceiptAllocation__c>();
                allocationList.add(receiptAllocationRec);
                if(receiptAllocationRec.InstallmentLine__c !=null && receiptAllocationRec.ReceiptAcknowledgement__r.Status__c==Constants.RECEIPT_STATUS_CLEARED){
                    System.debug(receiptAllocationRec.InstallmentLine__c+'**installmentAllocationMap in getOutstandingLPCforSalesOrder**'+installmentAllocationMap);
                    if(installmentAllocationMap.containsKey(receiptAllocationRec.InstallmentLine__c)){
                        allocationList.addAll(installmentAllocationMap.get(receiptAllocationRec.InstallmentLine__c));
                    }
                    installmentAllocationMap.put(receiptAllocationRec.InstallmentLine__c,allocationList);
                }
            }
            //---- Total LPC that the customer is suppose for the Sales Order
            lpcDetail.totalLPC = getLPCForSalesOrder(orderDetail, orderDetail.InstallmentLines__r,installmentAllocationMap);
        }
        
        
        if(lpcDetail.totalLPC > 0){
            lpcDetail.totalLPCDue = lpcDetail.totalLPC - lpcDetail.totalLPCWaivedOrPaid;
        }
        // }
        return lpcDetail ;
    }
    /*
    *********************************************************
    @Method Name    : lpcBeforeInsertLogic
    @author         : 
    @description    : Method to Populate LPC
    @param          : newRecord
    @return         : void
    ********************************************************
    */
    public static void lpcBeforeInsertLogic(HexaBPM__Service_Request__c newRecord){
        LPCModel lpcDetail = getOutstandingLPCforSalesOrder(newRecord.SalesOrder__c);
        System.debug('**lpcDetail**'+ lpcDetail);
        newRecord.TotalLPCAmount__c = lpcDetail.totalLPC.setScale(2);
        newRecord.TotalLPCDue__c = lpcDetail.totalLPCDue.setScale(2);
        newRecord.TotalLPCCollected__c = lpcDetail.lpcPaid.setScale(2);
        newRecord.ChargeCollected__c = newRecord.TotalLPCDue__c != null ? (newRecord.TotalLPCDue__c).setScale(2) : 0;
        newRecord.TotalLPCWaivedAmount__c = lpcDetail.lpcWaivedAmount;
        newRecord.LPCCalculatedDate__c = Date.today();
        if(newRecord.HexaBPM__Record_Type_Name__c == Constants.TITLE_DEED_REGISTRATION_DEV_RT){
            newRecord.OldNetAmount__c = lpcDetail.orderDetail.NetAmount__c;
            newRecord.TotalBilledAmount__c = lpcDetail.orderDetail.NetAmount__c - lpcDetail.orderDetail.TotalOutstanding__c;
            newRecord.TotalOutstandingAmount__c = lpcDetail.orderDetail.TotalOutstanding__c;
        }
    }
    /*
    *********************************************************
    @Method Name    : lpcBeforeUpdateLogic
    @author         : 
    @description    : Method to Populate LPC
    @param          : newRecord
    @return         : void
    ********************************************************
    */
	public static void lpcBeforeUpdateLogic(HexaBPM__Service_Request__c newRecord){
        LPCModel lpcDetail = LPCService.getOutstandingLPCforSalesOrder(newRecord.SalesOrder__c);
        newRecord.TotalLPCAmount__c = lpcDetail.totalLPC.setScale(2);
        newRecord.TotalLPCDue__c = lpcDetail.totalLPCDue.setScale(2);
        newRecord.TotalLPCCollected__c = lpcDetail.lpcPaid.setScale(2);
        newRecord.ChargeCollected__c = newRecord.TotalLPCDue__c - (newRecord.WaivedAmount__c != null ? newRecord.WaivedAmount__c  : 0);                    
        newRecord.ChargeCollected__c = (newRecord.ChargeCollected__c).setScale(2);                    
        newRecord.TotalLPCWaivedAmount__c = lpcDetail.lpcWaivedAmount.setScale(2);
        newRecord.LPCCalculatedDate__c = Date.today();                    
        if(newRecord.HexaBPM__Record_Type_Name__c == Constants.TITLE_DEED_REGISTRATION_DEV_RT){
            newRecord.OldNetAmount__c = lpcDetail.orderDetail.NetAmount__c;
            newRecord.TotalBilledAmount__c = lpcDetail.orderDetail.NetAmount__c - lpcDetail.orderDetail.TotalOutstanding__c;
            newRecord.TotalOutstandingAmount__c = lpcDetail.orderDetail.TotalOutstanding__c;
        }
    }
    /*
    *********************************************************
    @Method Name    : calculateWaiverPercentageAmount
    @author         : 
    @description    : Method to calculate Waived Percentage and Amount
    @param          : serviceRequests,oldMap
    @return         : void
    ********************************************************
    */ 
    public static void calculateWaiverPercentageAmount(List<HexaBPM__Service_Request__c> newSRList,Map<Id,SObject> oldSRMap) {
        for(HexaBPM__Service_Request__c newRecord : newSRList) {
            HexaBPM__Service_Request__c oldRecord = (HexaBPM__Service_Request__c)oldSRMap.get(newRecord.Id);
            Boolean waivedAmountChanged = false;
            if(newRecord.TotalLPCDue__c != 0 && newRecord.WaivedAmount__c != null && newRecord.WaivedAmount__c != oldRecord.WaivedAmount__c){                
                if(newRecord.WaivedBy__c != 'Amount'){
                    newRecord.WaivedAmount__c = oldRecord.WaivedAmount__c;
                    newRecord.PaymentExtensionPeriod__c = newRecord.WaivedAmount__c != null ? (newRecord.WaivedAmount__c).setScale(0) : 0;
                } else{
                    waivedAmountChanged = true;
                    newRecord.PaymentExtensionPeriod__c = newRecord.WaivedAmount__c != null ? (newRecord.WaivedAmount__c).setScale(0) : 0;                    
                    if(newRecord.WaivedAmount__c == 0){
                        newRecord.WaivedPercentage__c = 0;
                    } else{
                        newRecord.WaivedPercentage__c = ((newRecord.WaivedAmount__c / newRecord.TotalLPCDue__c) * 100).setScale(2);
                    }
                }
            }
            // calculate WaivedAmount__c when WaivedPercentage__c is populated or changed.
            if (!WaivedAmountChanged && newRecord.WaivedPercentage__c != null && (newRecord.TotalLPCDue__c != oldRecord.TotalLPCDue__c || newRecord.WaivedPercentage__c != oldRecord.WaivedPercentage__c)) {            
                if(newRecord.WaivedBy__c != 'Percentage'){
                    newRecord.WaivedPercentage__c = oldRecord.WaivedPercentage__c;
                    newRecord.PaymentExtensionPeriod__c = newRecord.WaivedAmount__c != null ? (newRecord.WaivedAmount__c).setScale(0) : 0;                    
                } else{
                    newRecord.WaivedAmount__c = (newRecord.TotalLPCDue__c * (newRecord.WaivedPercentage__c/100)).setScale(2);
                    newRecord.PaymentExtensionPeriod__c = newRecord.WaivedAmount__c != null ? (newRecord.WaivedAmount__c).setScale(0) : 0;
                }
            }
        }
    }
    /*
    *********************************************************
    @Method Name    : submittedLPC
    @author         : 
    @description    : Method to handle the LPC Submitted status
    @param          : serviceRequests,oldMap
    @return         : void
    ********************************************************
    */   
    public static void submittedLPC(Map<HexaBPM__Service_Request__c, Id> submittedLPCSRWithSOMap) {  
        List<InstallmentLines__c> installmentLinesList = new List<InstallmentLines__c>();
        for (InstallmentLines__c ilRecord: [SELECT Id, Name, LPCFreezeDate__c, LPCFreezeUntilDate__c FROM InstallmentLines__c WHERE SalesOrder__c IN: submittedLPCSRWithSOMap.values()]) {
            ilRecord.LPCFreezeDate__c = ilRecord.LPCFreezeDate__c <> null && ilRecord.LPCFreezeDate__c < Date.Today() ? ilRecord.LPCFreezeDate__c : Date.Today();
            ilRecord.LPCFreezeUntilDate__c = ilRecord.LPCFreezeUntilDate__c <> null && ilRecord.LPCFreezeUntilDate__c > Date.Today() + 30 ? ilRecord.LPCFreezeUntilDate__c : Date.Today() + 30;
            installmentLinesList.add(ilRecord);
        }
        if(!installmentLinesList.isEmpty()) {
            update installmentLinesList;
        }        
        List<Id> srIds = new List<Id>();
        for(HexaBPM__Service_Request__c srRec : submittedLPCSRWithSOMap.keySet()){
            srIds.add(srRec.Id);
        }
        LPCCalloutHelper.getDataForFreezeCallout(srIds, true);
    }   	
}