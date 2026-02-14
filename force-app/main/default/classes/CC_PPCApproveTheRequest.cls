/*
* SR Type : Payment Plan Change
* Purpose : To approve the new payment plan
*/
global without sharing class CC_PPCApproveTheRequest implements HexaBPM.iCustomCodeExecutable {
    
    public class CustomException extends Exception {}

    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_PPCApproveTheRequest: Invalid SR or SR Step';
            }else{               
                HexaBPM__Service_Request__c sRRecord = [SELECT Id, SRType__c,Exceptional_Reason__c,Credit_Note_Sub_Type__c,No_Charge_Fee_Required__c,ChequeReplacementStatus__c, ProposalPaymentPlan__c, SalesOrder__c, Unit__c, Unit__r.Name, Unit__r.BuildingSectionName__r.TaxPercentage__c, NewNetAmount__c, SalesOrder__r.Opportunity__c, HexaBPM__Customer__c, HexaBPM__Contact__c, SummaryReport__c
                 FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                if((sRRecord.No_Charge_Fee_Required__c && stp.HexaBPM__Summary__c == 'Approval by D-CM') || (stp.HexaBPM__Summary__c == 'Charge Fees')) {

                    List<String> errorsMessages = new List<String>();

                    if(stp.HexaBPM__Step_Status__c == 'Customer Not Paid') {
                        string receiptStatus = [SELECT Status__c FROM ReceiptAcknowledgement__c WHERE ServiceRequest__c =:sRRecord.Id AND Receipt_Type__c = 'Charge Fee' order by createddate DESC LIMIT 1]?.Status__c;
                        if(string.IsBlank(receiptStatus)){
                            errorsMessages.add('No related charge fee type receipt found for this service request.');
                        } else {
                            if(receiptStatus == 'Received' || receiptStatus == 'Cleared') {
                                errorsMessages.add('Receipt status shows customer has already paid.');
                            }
                        } 
                        if(!errorsMessages.isEmpty()){
                            return errorsMessages.toString().replace(',','\n');
                        }                      
                    } else {

                        if(sRRecord.ProposalPaymentPlan__c == null){
                            errorsMessages.add(Utilities.getSystemMessages(Constants.PROPOSAL_PAYMENT_PLAN_VALIDATION).Message__c);
                        }

                        if(!errorsMessages.isEmpty()){
                            return errorsMessages.toString().replace(',','\n');
                        }

                        // to get Installment Lines List related to SO
                        list<InstallmentLines__c>  installmentLinesList = PaymentPlanFromSRController.getInstallmentLines(sRRecord.SalesOrder__c);
                        List<ReceiptAllocation__c> receiptAllocationList = [Select Id, ReceiptAcknowledgement__c, ReceiptAcknowledgement__r.Amount__c,ReceiptAcknowledgement__r.Account__c, ReceiptAcknowledgement__r.ServiceRequest__c, InstallmentLine__c From ReceiptAllocation__c Where InstallmentLine__c In : installmentLinesList AND ReceiptStatus__c =: Constants.RECEIVED_PAYMENT_STATUS];

                        // Update the installments
                        list<InstallmentLines__c> newinstallmentLinesList = updateInstallmentLinesRecords(sRRecord, installmentLinesList);
                        Map<Id, InstallmentLines__c> newinstallmentLinesMap = new Map<Id, InstallmentLines__c>(newinstallmentLinesList);
                        Map<Id, ReceiptAcknowledgement__c> installmentWithRAMap = new Map<Id, ReceiptAcknowledgement__c>();

                        list<InstallmentLines__c> installmentLinesToDeleteList = new list<InstallmentLines__c>();
                        list<InstallmentLines__c> installmentLinesToCreateRAList = new list<InstallmentLines__c>();
                        list<InstallmentLines__c> installmentLinesToCreateChequeReplacementSRList = new list<InstallmentLines__c>();
                        list<Id> installmentLinesUpdated = new list<Id>();

                            
                        // to remove Installment Line if the number of new Installments less than old Installment, OR to create cheque replacement SR if existing installment modified.
                        for (InstallmentLines__c record : installmentLinesList) {

                            InstallmentLines__c newRecord = newinstallmentLinesMap.get(record.Id) != null ? newinstallmentLinesMap.get(record.Id) : null;

                            if(record.InstallmentNumber__c > newinstallmentLinesList.size()){
                                installmentLinesToDeleteList.add(record);
                                
                            } else if(newRecord != null && (record.InstallmentAmount__c != newRecord.InstallmentAmount__c || record.InstallmentDate__c != newRecord.InstallmentDate__c)){
                                System.debug('newRecord: '+newRecord);
                                System.debug('oldRecord: '+record);

                                installmentLinesToCreateChequeReplacementSRList.add(record);
                                installmentLinesUpdated.add(record.Id);
                            }
                        }

                        List<ReceiptAllocation__c> receiptAllocationToUpdate = new List<ReceiptAllocation__c>();

                        // relocate Amount Applied on Receipt Allocation related to updated installments
                        for (ReceiptAllocation__c receiptAllocationRecord : receiptAllocationList) {
                            if(installmentLinesUpdated.contains(receiptAllocationRecord.InstallmentLine__c)){
                                receiptAllocationRecord.AmountApplied__c = 0;
                                receiptAllocationToUpdate.add(receiptAllocationRecord);
                            }
                            installmentWithRAMap.put(receiptAllocationRecord.InstallmentLine__c, receiptAllocationRecord.ReceiptAcknowledgement__r);
                        }

                        if (receiptAllocationToUpdate.size() > 0) {
                            update receiptAllocationToUpdate;
                        }

                        if (installmentLinesToDeleteList.size() > 0) {
                            delete installmentLinesToDeleteList;
                        }

                        if (installmentLinesToCreateChequeReplacementSRList.size() > 0 && sRRecord.ChequeReplacementStatus__c == Constants.CHEQUE_REPLACEMENT_APPLICABLE) {
                            createChequeReplacmentSR(installmentLinesToCreateChequeReplacementSRList, sRRecord, installmentWithRAMap);
                        }

                        //Update Booking Memo status to approved
                        BookingMemo__c bookingMemoRecord = new BookingMemo__c(Id=sRRecord.ProposalPaymentPlan__c, ApprovalStatus__c= 'Approved');
                        update bookingMemoRecord;
                        
                        
                        //New Changes
                        Map<Double, InstallmentLines__c> installmentMap = new Map<Double, InstallmentLines__c>();                
                        List<InstallmentLines__c> installmentList = [select Id,InstallmentNumber__c from InstallmentLines__c where SalesOrder__c=:sRRecord.SalesOrder__c];
                        for(InstallmentLines__c installment:installmentList){
                                installmentMap.put(installment.InstallmentNumber__c, installment);
                        }
                                        
                        BookingMemo__c memoLine=[select Id, (select Id from Payment_PlansBookingMemo__r) from BookingMemo__c where ID=:bookingMemoRecord.Id];
                        if(!memoLine.Payment_PlansBookingMemo__r.isEmpty()){
                        Map<Id,	PaymentInstallments__c> paymentInstallmentMap=new Map<Id,	PaymentInstallments__c>();
                        PaymentPlan__c paymentPlan=memoLine.Payment_PlansBookingMemo__r.get(0);
                        PaymentPlan__c paymentPlanRetrived=[select Id, (select Id,Name,InstallmentNumber__c from PaymentInstallments__r) from PaymentPlan__c where Id=:paymentPlan.Id];  
                        System.debug('*** paymentPlanRetrived ***'+paymentPlanRetrived);
                            for(PaymentInstallments__c paymentInstallmentObj:paymentPlanRetrived.PaymentInstallments__r){
                            paymentInstallmentMap.put(paymentInstallmentObj.Id, paymentInstallmentObj);
                            InstallmentLines__c matchedInstallmet= installmentMap.get(paymentInstallmentObj.InstallmentNumber__c);
                                if(matchedInstallmet!=null){
                                matchedInstallmet.PaymentInstallments__c =paymentInstallmentObj.Id;
                                }
                            }
                            System.debug('*** paymentInstallmentMap ***'+paymentInstallmentMap);
                            if(!installmentMap.isEmpty()){
                            update installmentMap.values(); 
                            }                    
                        }
                        //New Changes
                        

                        // SO Update
                        MemoLines__c memoLineRecord = MemoLinesService.getMemoLinesByBookinMemoId(sRRecord.ProposalPaymentPlan__c)[0];
                        SalesOrder__c so = new SalesOrder__c(Id=sRRecord.SalesOrder__c);
                        so.OtherRebateAmount__c = memoLineRecord.RebateAmount__c;
                        so.BulkDiscount__c = 0;
                        so.CorporateDiscount__c = 0;
                        so.PaymentPlanDiscount__c = 0;
                        so.WealthDiscount__c = 0;
                        so.Discount__c = memoLineRecord.DiscountAmount__c;
                        so.AmountPayable__c = sRRecord.NewNetAmount__c;
                        so.TaxableAmount__c = sRRecord.Unit__r.BuildingSectionName__r.TaxPercentage__c != null ? sRRecord.Unit__r.BuildingSectionName__r.TaxPercentage__c * so.AmountPayable__c : 0;
                        so.NetAmount__c = so.AmountPayable__c + so.TaxableAmount__c;
                        so.NetAmountInWords__c = Utilities.amountInWords(so.NetAmount__c,'Dirham','Fils');

                        Update so;

                        //--- To send an email with the new SOA
                        String orgWideEmailAddress='';
                        for(OrgWideEmailAddress tempRec: [select id,Address from OrgWideEmailAddress where DisplayName= :Constants.ALDAR_PROPERTIES_ORGWIDEEMAIL_CUSTOMER_CARE limit 1 ]){
                            orgWideEmailAddress=tempRec.id;
                        }

                        string emailTemplateId ='';
                        for(Emailtemplate tempRec:  [select id, DeveloperName from emailtemplate where DeveloperName = 'SOUpdatedPPCSRCustomerEmail' limit 1]){
                            emailTemplateId=tempRec.Id;
                        }
                        String fileName = 'SOA - '+sRRecord.Unit__r.Name+' - Generated On - '+Date.Today();
                        //SRUtility.generatePdfAndSendEmail(sRRecord.HexaBPM__Contact__c, emailTemplateId, sRRecord.Id, orgWideEmailAddress, sRRecord.SalesOrder__c, fileName);

                        PaymentPlanChangeCalloutHelper.getDataForCallout(new List<Id>{stp.HexaBPM__SR__c});
                    }
            } else if(!sRRecord.No_Charge_Fee_Required__c && stp.HexaBPM__Summary__c == 'Approval by D-CM') {
                ReceiptAcknowledgement__c rack = prepareReceiptAck(sRRecord);
                Map<Id, HexaBPM__Service_Request__c> srIdWithSR = new Map<Id, HexaBPM__Service_Request__c>();
                srIdWithSR.put(sRRecord.Id,sRRecord);
                Map<Id, ReceiptAcknowledgement__c> srIdWithRcptAcknowledgmentMap = new Map<Id, ReceiptAcknowledgement__c>();
                srIdWithRcptAcknowledgmentMap.put(sRRecord.Id,rack);
                SRPostPaymentHandler.paymentExtensionTypePayment(srIdWithSR,srIdWithRcptAcknowledgmentMap);
            }
        }
        } catch(Exception e){
            result = e.getMessage()+', '+e.getLineNumber()+' :CC_PPCApproveTheRequest';
        }
      
        return result;
    }

    /*
    * insert or update installments
    */
    public static list<InstallmentLines__c> updateInstallmentLinesRecords(HexaBPM__Service_Request__c sRRecord, list<InstallmentLines__c>  installmentLinesList){

        // get Installment Line Changes for new payment plan
        List<InstallmentLineChanges__c> installmentLineChangesList = InstallmentLineChangesService.getInstallmentLineChangesQuery('Select Id, Name, InstallmentAmount__c, InstallmentNumber__c, ProposedInstallmentPercentage__c, InstallmentDate__c, ProposedInstallmentDate__c, BookingMemo__c, Unit__c, InstallmentPercentage__c FROM InstallmentLineChanges__c WHERE BookingMemo__c =\''+sRRecord.ProposalPaymentPlan__c+'\' Order By InstallmentNumber__c asc');

        Map<Integer, InstallmentLines__c> installmentNumberWithRecord = new Map<Integer, InstallmentLines__c>();

        Id paymentInstallment = null;

        for (InstallmentLines__c il : installmentLinesList) {
            installmentNumberWithRecord.put(Integer.valueOf(il.InstallmentNumber__c), il);
            if(il.PaymentInstallments__c != null && paymentInstallment == null){
                paymentInstallment = il.PaymentInstallments__c;
            }
        }

        list<InstallmentLines__c>  installmentLinesToBeInsertOrUpdate = new list<InstallmentLines__c>();

        // insert or update installments
        for (InstallmentLineChanges__c ilChange : installmentLineChangesList) {
            InstallmentLines__c il = new InstallmentLines__c();

            if(installmentNumberWithRecord.get(Integer.valueOf(ilChange.InstallmentNumber__c)) != null){
                il.Id = installmentNumberWithRecord.get(Integer.valueOf(ilChange.InstallmentNumber__c)).Id;
                il.InstallmentPercentage__c = ilChange.ProposedInstallmentPercentage__c;
                il.InstallmentDate__c = ilChange.ProposedInstallmentDate__c;
                il.InstallmentAmount__c = ilChange.InstallmentAmount__c;
                
                if(installmentNumberWithRecord.get(Integer.valueOf(ilChange.InstallmentNumber__c)).InstallmentAmount__c != ilChange.InstallmentAmount__c || installmentNumberWithRecord.get(Integer.valueOf(ilChange.InstallmentNumber__c)).InstallmentDate__c != ilChange.ProposedInstallmentDate__c){
                    il.AmountReceived__c = 0;
                }

            } else{
                il.InstallmentPercentage__c = ilChange.ProposedInstallmentPercentage__c;
                il.InstallmentDate__c = ilChange.ProposedInstallmentDate__c;
                il.InstallmentAmount__c = ilChange.InstallmentAmount__c;
                il.SalesOrder__c = sRRecord.SalesOrder__c;
                il.PaymentInstallments__c = paymentInstallment;
                il.Description__c = 'Updated By '+ilChange.Name;
                il.InstallmentNumber__c = Integer.valueOf(ilChange.InstallmentNumber__c);
            }
            il.InstallmentAmountintheWords__c = Utilities.amountInWords(il.InstallmentAmount__c,'Dirham','Fils');
            installmentLinesToBeInsertOrUpdate.add(il);
            System.debug('**il**'+ il);
        }
        upsert installmentLinesToBeInsertOrUpdate;
        return installmentLinesToBeInsertOrUpdate;
    }

    /*
    * to create cheque replacement SR for each updated installment
    */
    public static void createChequeReplacmentSR(list<InstallmentLines__c> newinstallmentLinesList, HexaBPM__Service_Request__c sRRecord, Map<Id, ReceiptAcknowledgement__c> installmentWithRAMap){
        
        List<HexaBPM__Service_Request__c> srToInsert = new List<HexaBPM__Service_Request__c>();
        List<ReceiptAcknowledgement__c> raToUpdate = new List<ReceiptAcknowledgement__c>();

        Id srTempId = SRUtility.getSRTemplate(Constants.CHEQUE_REPLACEMENT);
        Group financeQueue = Utilities.getQueueInformation(Constants.FINANCE_QUEUE);

        for (InstallmentLines__c il : newinstallmentLinesList) {

            if(il.InstallmentDate__c != null){
                
                ReceiptAcknowledgement__c ra = installmentWithRAMap.get(il.Id);

                HexaBPM__Service_Request__c newSR = new HexaBPM__Service_Request__c();
                newSR.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.PAYMENT_EXTENSION_RT);
                newSR.HexaBPM__SR_Template__c = srTempId;
                newSR.HexaBPM__Parent_SR__c = sRRecord.Id;
                newSR.HexaBPM__Customer__c = sRRecord.HexaBPM__Customer__c;
                newSR.HexaBPM__Contact__c = sRRecord.HexaBPM__Contact__c;
                newSR.InstallmentLine__c = il.Id;
                newSR.SalesOrder__c = sRRecord.SalesOrder__c;
                newSR.SummaryReport__c = sRRecord.SummaryReport__c;
                newSR.PaymentExtensionDate__c = il.InstallmentDate__c;
                newSR.ReceiptAcknowledgement__c = ra != null ? ra.Id : null;
                newSR.Unit__c = sRRecord.Unit__c;
                newSR.OwnerId = financeQueue.Id;
                newSR.SRType__c = Constants.CHEQUE_REPLACEMENT_SR_TYPE;
                srToInsert.add(newSR);
            }
        }
        insert srToInsert;
    }
    public static ReceiptAcknowledgement__c prepareReceiptAck(HexaBPM__Service_Request__c sRRecord) {
        ReceiptAcknowledgement__c rack = new ReceiptAcknowledgement__c();
        
        //Decimal chargeAmount = [SELECT ChargeAmount__c from ChargeRule__c WHERE SRType__c =:Constants.LPC_WAIVER_TYPE AND ChargeType__c =:Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE AND IsActive__c = True ORDER BY CreatedDate DESC LIMIT 1]?.ChargeAmount__c;
        Decimal chargeAmount = 0;
        for(ChargeRule__c chargeRule : [SELECT ChargeAmount__c,ChargePercentage__c,VATChanges__c from ChargeRule__c WHERE SRType__c =:Constants.PAYMENT_PLAN_CHANGE_RT AND ChargeType__c =:Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE AND IsActive__c = True ORDER BY CreatedDate DESC LIMIT 1]){
            Decimal amountWithoutVAT = chargeRule.ChargeAmount__c;
            Decimal vatAmount = (amountWithoutVAT * chargeRule.VATChanges__c)/100;
            chargeAmount = amountWithoutVAT + vatAmount;
        }
        if(chargeAmount <> Null && chargeAmount > 0) {
            Timer__mdt paymentGatewayLinkTimer = Utilities.getTimer(Constants.PAYMENT_GATEWAY_LINK);
            String timerUnit = PaymentGatewayLinkTimer.Time__c;
            Integer timerDetails = Integer.valueOf(PaymentGatewayLinkTimer.Timer__c);
            if (timerUnit == Constants.HOURS) {
                timerDetails = timerDetails * 60;
            }
            rack.Account__c = sRRecord.HexaBPM__Customer__c;
            rack.SalesOrder__c = sRRecord.SalesOrder__c;
            rack.Amount__c = chargeAmount;
            rack.Status__c = Constants.LINK_SENT;
            rack.PaymentType__c = Constants.ONLINE;
            rack.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
            rack.PaymentSubType__c = sRRecord.Credit_Note_Sub_Type__c;
            rack.ServiceRequest__c = sRRecord.Id;
            rack.RegeneratePaymentLink__c = true;
            rack.DoNotSendPaymentURL__c = false;
            rack.Contact__c = sRRecord.HexaBPM__Contact__c;
            rack.Opportunity__c = sRRecord.SalesOrder__r.Opportunity__c;
            rack.Receipt_Type__c = 'Charge Fee';
            //rack.IsStopSyncingWithERP__c = true;
            rack.EncryptedRecordId__c = EncodingUtil.urlEncode(EncryptionUtils.encryptString(sRRecord.Id+''), 'UTF-8');
            rack.PaymentLinkExpiry__c = system.now().addMinutes(timerDetails);    
            insert rack;
        }
        
        return rack;
    }
}