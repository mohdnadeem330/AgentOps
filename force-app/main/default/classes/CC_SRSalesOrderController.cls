/*
* Purpose: To change the Sales Order and Related records, check the LPC, Outstanding Balance, and so on.
* SR Type: Property Transfer And Property Transfer NOC
*/
global without sharing class CC_SRSalesOrderController implements HexaBPM.iCustomCodeExecutable {
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp) {
        HexaBPM__Service_Request__c serviceRequest = ServiceRequestService.queryAllFieldsWithExtraFields(new List<Id>{stp.HexaBPM__SR__c})[0];
        SalesOrder__c salesOrder = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{serviceRequest.SalesOrder__c})[0];
		 
		String staffValidationMsg = ServiceRequestTriggerHandlerNew.aldarstaffPTValidation(serviceRequest,salesOrder);
        if(staffValidationMsg!=null){
            return staffValidationMsg;
        }
        
        /*
        * Logic: Check fro delow validation before Updating Sales Order and Related Records
        *           LPC is out outstanding
        *           Mortgage is Applicable
        *           Outstanding balance is pending
        *           Check for Threshold Limit
        */
        if (!serviceRequest.ExemptValidations__c) {
            Decimal thresholdLimit = salesOrder.Unit__r.BuildingSectionName__r.TransferThresholdLimit__c == null ? 0 : (salesOrder.NetAmount__c * (salesOrder.Unit__r.BuildingSectionName__r.TransferThresholdLimit__c / 100)).setScale(2);
            Boolean isError = false;
            String errorMessage = salesOrder.Unit__r.Name + ' Property cannot be transfer because of ';
            if (salesOrder.MortgageApplicable__c == 'Yes') {
                SystemMessages__mdt message = Utilities.getSystemMessages('MORTGAGE_APPLICABLE');
                errorMessage += message.Message__c + ', ';
                isError = true;
            }

            List<InstallmentLines__c> installmentLinesList = new List<InstallmentLines__c>();
            for (InstallmentLines__c lines : salesOrder.InstallmentLines__r) {
                installmentLinesList.add(lines);
            }
            if(!installmentLinesList.isEmpty()){
                Boolean isUnclearedReceipts = SRUtility.checkForUnclearedReceipts(installmentLinesList);
                isError = isError == true ? true : isUnclearedReceipts;
                SystemMessages__mdt message = Utilities.getSystemMessages('UNCLEARED_RECEIPTS');
                errorMessage += isUnclearedReceipts == true ? message.Message__c + ', ' : '';
            }

            if (!serviceRequest.HexaBPM__Customer__r.TransferThresholdLimitExcluded__c && salesOrder.TotalBilled__c < thresholdLimit) {
                SystemMessages__mdt message = Utilities.getSystemMessages('THRESHOLD_LIMIT');
                errorMessage += message.Message__c + ', ';
                isError = true;
            }

            List<ReceiptAcknowledgement__c> receiptList = new List<ReceiptAcknowledgement__c>();
            for (ReceiptAcknowledgement__c receipts : salesOrder.Payments__r) {
                receiptList.add(receipts);
            }
            if(!receiptList.isEmpty()){
                
                Boolean isOutstandingAmount = SRUtility.checkForOutstandingAmountWithBypass(receiptList, serviceRequest); //SRUtility.checkForOutstandingAmount(receiptList); //SS_FOR_RECEIPT_BYPASS_LOGIC_ASF_514
                isError = isError == true ? true : isOutstandingAmount;
                SystemMessages__mdt message = Utilities.getSystemMessages('OUTSTANDING_PAYMENT');
                errorMessage += isOutstandingAmount == true ? message.Message__c + ', ' : '';
            }

            List<SalesOrderOtherCharges__c> otherChargesList = new List<SalesOrderOtherCharges__c>();
            for (SalesOrderOtherCharges__c otherChares : salesOrder.SalesOrdersOtherCharges__r) {
                otherChargesList.add(otherChares);
            }
            if(!otherChargesList.isEmpty()){
                Boolean isLPC = SRUtility.checkLatePaymentCharges(salesOrder.Id);
                isError = isError == true ? true : isLPC;
                SystemMessages__mdt message = Utilities.getSystemMessages('LATE_PAYMENT_CHARGES');
                errorMessage += isLPC == true ? message.Message__c + ', ' : '';
            }
            
            if (isError && String.isNotBlank(errorMessage)) {
                errorMessage = errorMessage.removeEnd(', ');
                System.debug('Error>>> ' + errorMessage);
                return errorMessage;
            }
        }

        /*
        * Logic: Delete old Joint Owner and Create Joint Owner History
        */
        List<JointOwner__c> jointOwnerList = new List<JointOwner__c>();
        List<JointOwnerHistory__c> jointOwnerHistoryList = new List<JointOwnerHistory__c>();
        for (JointOwner__c jointOwner: salesOrder.Joint_OwnersSalesOrder__r) {
            jointOwner.IsDeleted__c = true;
            jointOwnerList.add(jointOwner);

            JointOwnerHistory__c jointOwnerHistory = new JointOwnerHistory__c();
            jointOwnerHistory.PrimaryAccount__c = salesOrder.Account__c;
            jointOwnerHistory.Account__c = jointOwner.Account__c;
            jointOwnerHistory.SalesOrder__c = jointOwner.SalesOrder__c;
            jointOwnerHistory.RelationshipType__c = jointOwner.RelationshipType__c;
            jointOwnerHistory.SharePercentage__c = jointOwner.SharePercentage__c;
            jointOwnerHistoryList.add(jointOwnerHistory);
        }
        if(!jointOwnerList.isEmpty()) {
            update jointOwnerList;
            insert jointOwnerHistoryList;
        }

        /*
        * Logic: Create Transfer History for Sales Order
        */
        TransferHistory__c transferHistory = createTransferHistory(serviceRequest);
        insert transferHistory;

        //adding logic to update transfer date on the SR
        /*HexaBPM__Service_Request__c serviceReq = new HexaBPM__Service_Request__c();
        serviceReq.id = serviceRequest.id;
        serviceReq.TransferDate__c = Date.today();
        update serviceReq;*/

        salesOrder.Account__c = serviceRequest.BuyerName__c;
        salesOrder.Contact__c = serviceRequest.BuyerContact__c;
        update salesOrder;

        /*
        * Logic: Create ADM Charges(2%) for Buyer
        */
        /*As part of ASF 718, ADM FEE and ADM ADMIN FEE needs to be merged to ADM FEE, hence, type will be changed to ADMFEE below */
        if (serviceRequest.RecordType.Name == Constants.PROPERTY_TRANSFER_RT || serviceRequest.RecordType.Name == Constants.PLOT_PROPERTY_TRANSFER_RT){// || serviceRequest.RecordType.Name == Constants.PROPERTY_TRANSFER_NOC_RT) { *****STOPING ADM FEE FOR PRT TRANSFER NOC and DUBAI/RAK Prop ADM Fee **** RUN BASED on the Custom Meta DATA
          //   Decimal ADMAdminFeetoBeCharged =  decimal.valueOf(Label.ADMAdminFee);
          /* if (ADMAdminFeetoBeCharged > 0) {
            SalesOrderOtherCharges__c newADMCharge = SRUtility.createSalesOrderOtherCharge(serviceRequest, Constants.BUDGET_LINE_ADMFEE, ((salesOrder.AmountPayable__c * 0.02).setScale(2) + ADMAdminFeetoBeCharged.setScale(2)));
           }else {
               SalesOrderOtherCharges__c newADMCharge = SRUtility.createSalesOrderOtherCharge(serviceRequest, Constants.BUDGET_LINE_ADMFEE, (salesOrder.AmountPayable__c * 0.02).setScale(2) );
               //SalesOrderOtherCharges__c newADMAdminCharge = SRUtility.createSalesOrderOtherCharge(serviceRequest, Constants.BUDGET_LINE_ADMADMINFEE, ADMAdminFeetoBeCharged.setScale(2));
           }*/
		   
		    /*Decimal totalCharges;
                if(!(serviceRequest.ChargeType__c == 'Transfer Next of Kin (Death)' || serviceRequest.ChargeType__c == 'Court Order'|| serviceRequest.ChargeType__c == 'Transfer Next of Kin (Family)'))
                {
                     totalCharges = ((salesOrder.AmountPayable__c * 0.02).setScale(2) + ADMAdminFeetoBeCharged.setScale(2));
                    SalesOrderOtherCharges__c newADMCharge = SRUtility.createSalesOrderOtherCharge(serviceRequest,Constants.BUDGET_LINE_ADMFEE, totalCharges);
                }*/
             Municipality_Fee_Details__mdt municipalityFee = SRUtility.fetchMunicipalityFee(salesOrder.Unit__r.Project__r.City__c);
            if(municipalityFee <> null && municipalityFee.Municipality_Fee_perc__c <> null && municipalityFee.Municipality_Charge__c <> null){
                Decimal ADMAdminFeetoBeCharged = municipalityFee.Municipality_Charge__c;
                Decimal totalCharges;
                system.debug('totalcharges' + municipalityFee.Municipality_Charge__c.setScale(2) + (salesOrder.AmountPayable__c * (municipalityFee.Municipality_Fee_perc__c/100)).setScale(2));
                    if(!(serviceRequest.ChargeType__c == 'Transfer Next of Kin (Death)' || serviceRequest.ChargeType__c == 'Court Order'|| serviceRequest.ChargeType__c == 'Transfer Next of Kin (Family)'))
                    {
                         totalCharges = municipalityFee.Municipality_Charge__c.setScale(2) + (salesOrder.AmountPayable__c * (municipalityFee.Municipality_Fee_perc__c/100)).setScale(2);
                         //Added by Kuhinoor....
                         String excludedCity = System.label.Excluded_OC_City;
                         Set<String> excludedCitySet = String.isNotBlank(excludedCity) ? new Set<String>( excludedCity.split(',')) : null; 
                         
                         if(serviceRequest != null && String.isNotBlank( serviceRequest.Unit__r.Project__r.City__c) 
                            && !excludedCitySet.contains(serviceRequest.Unit__r.Project__r.City__c)){
                            SalesOrderOtherCharges__c newADMCharge = SRUtility.createSalesOrderOtherCharge(serviceRequest, municipalityFee.MasterLabel, totalCharges);
                         }
                    }
                }
        }
 
        /*
        * Logic: If Charge to be Collected in not zero then Create a Trasfer Fee in Other Charges and allocate those to Receipt
       
        if (serviceRequest.ChargeCollected__c != null && serviceRequest.ChargeCollected__c != 0 && serviceRequest.ChargeWaivedOff__c == false) {
            SalesOrderOtherCharges__c otherCharge = SRUtility.createSalesOrderOtherCharge(serviceRequest, Constants.OTHER_CHARGES_TYPE_TRANSFER_FEE_CHARGE);
            if (!serviceRequest.Receipt_Acknowledgements__r.isEmpty()) {
                ReceiptAllocation__c receiprAllocation = SRUtility.createReceiptAllocation(otherCharge, serviceRequest);
            }
        }
        */

        /*
        * Logic: Create new Joint Owner from SR Amendments
        */
        if (!serviceRequest.Partners__r.isEmpty()) {
            List<JointOwner__c> newJointOwnerList = SRUtility.createJointOwner(serviceRequest);
        }

        /*
        * Logic: Unapply all receipts where Invoice No is avialable
        */
        if (serviceRequest.RecordType.Name == Constants.PROPERTY_TRANSFER_RT ||serviceRequest.RecordType.Name == Constants.PROPERTY_TRANSFER_OffPlan) {
            List<ReceiptAllocation__c> receiptAllocationList = new List<ReceiptAllocation__c>();
            for (ReceiptAllocation__c receiptAllocation: salesOrder.ReceiptAllocations__r) {
                if (receiptAllocation.InstallmentLine__c != null && receiptAllocation.InstallmentLine__r.InvoiceNumber__c == null) {
                    receiptAllocation.AmountApplied__c = 0;
                    receiptAllocationList.add(receiptAllocation);
                }
            } 
            if (!receiptAllocationList.isEmpty()) {
                //update receiptAllocationList;
                //Added by kuhinoor...
                System.enqueueJob(new UpdateReceiptAllocationQueueable(receiptAllocationList));
            }
        }
        // if (serviceRequest.RecordType.Name == Constants.PROPERTY_TRANSFER_RT || serviceRequest.RecordType.Name == Constants.PLOT_PROPERTY_TRANSFER_RT) {
        List<HexaBPM__Service_Request__c> handoverSRList = [SELECT Id,HandoverDetail__c, 
                                                            (SELECT Id FROM HexaBPM__SR_Docs__r) FROM HexaBPM__Service_Request__c 
                                                            WHERE RecordType.Name =: Constants.HANDOVER_RT AND SalesOrder__c =: serviceRequest.SalesOrder__c 
                                                            AND HexaBPM__External_Status_Name__c !=: Constants.SR_STATUS_CLOSED
                                                            AND HexaBPM__External_Status_Name__c !=: Constants.SR_STATUS_CANCELLED];
            List<HexaBPM__SR_Doc__c> srDocList = new List<HexaBPM__SR_Doc__c>();
            List<HandoverDetails__c> handoverDetailList=new List<HandoverDetails__c>();
            if (!handoverSRList.isEmpty()) {
                for (HexaBPM__Service_Request__c updateSR: handoverSRList) {
                    if(updateSR.HandoverDetail__c!=null){
                        HandoverDetails__c handoverDetailObj=new HandoverDetails__c();
                        handoverDetailObj.Id=updateSR.HandoverDetail__c;
                        handoverDetailObj.IsPropertyTransferHandover__c=true;
                        handoverDetailList.add(handoverDetailObj);
                    }
                    updateSR.HexaBPM__Customer__c = serviceRequest.BuyerName__c;
                    updateSR.HexaBPM__Contact__c = serviceRequest.BuyerContact__c;
                    for (HexaBPM__SR_Doc__c doc: updateSR.HexaBPM__SR_Docs__r) {
                        HexaBPM__SR_Doc__c srDoc = new HexaBPM__SR_Doc__c();
                        srDoc.Id = doc.Id;
                        srDoc.HexaBPM__Customer__c = serviceRequest.BuyerName__c;
                        srDocList.add(srDoc);
                    }
                    
                }
                update handoverSRList;
                if(!handoverDetailList.isEmpty()){
                   update handoverDetailList;  
                }              
                if (!srDocList.isEmpty()) {
                    System.debug('@@@@srDocList'+srDocList);
                    update srDocList;
                }
            }
        // }

       
        
         /*
          * Logic: Send Survey to Seller and Buyer both for Property Transfer Process
          */ 
        if (serviceRequest.RecordType.Name == Constants.PROPERTY_TRANSFER_RT  
                || serviceRequest.RecordType.Name == Constants.PLOT_PROPERTY_TRANSFER_RT || serviceRequest.RecordType.Name == Constants.PROPERTY_TRANSFER_OffPlan) {
                serviceRequest.Survey_Point__c ='TRANSFER_SR_BUY';
                serviceRequest.Survey_Required__c=true;
                ServiceRequestTriggerHandlerNew.isSkipSrRequestTrigger = true; // added by kuhinoor
                update serviceRequest;
                //ConfigGroup = customerType == Constants.BUYER_ESIGN ? 'PRODALPropertyBuyerExp' : 'PRODALPropertySellerExp';
           } else if (serviceRequest.RecordType.Name == Constants.PROPERTY_TRANSFER_NOC_RT) {
               System.enqueueJob(new Qualtrics.QualtricsIntegration(new set<Id>{serviceRequest.Id}));
           } 
       
        PropertyTransferCalloutHelper.getDataForCallout(new List<Id>{stp.HexaBPM__SR__c});
        return Constants.SUCCESS_RETURN_MESSAGE;
    }

    public static TransferHistory__c createTransferHistory(HexaBPM__Service_Request__c serviceRequest) {
        TransferHistory__c transferHistory = new TransferHistory__c();
        transferHistory.BuyerNameSFId__c = serviceRequest.BuyerName__c;
        transferHistory.FreeOfCharge__c = serviceRequest.FreeofCharge__c;
        transferHistory.FromAccount__c = serviceRequest.HexaBPM__Customer__c;
        transferHistory.SalesOrder__c = serviceRequest.SalesOrder__c;
        transferHistory.SalesorderId__c = serviceRequest.SalesOrder__c;
        transferHistory.ToAccount__c = serviceRequest.BuyerName__c;
        transferHistory.TransferCharges__c = serviceRequest.ChargeCollected__c;
        transferHistory.TransferPrice__c = String.valueOf(serviceRequest.TransferSellingPrice__c);
        transferHistory.TransferType__c = serviceRequest.SRType__c;
        transferHistory.UnitNumber__c = serviceRequest.Unit__r.Name;
        transferHistory.SRNumber__c = serviceRequest.Name;
        transferHistory.SROwner__c = serviceRequest.Owner.Name;
        transferHistory.CreationDate__c = String.valueOf(Date.today());
        //New date introduced for transfer date
        //transferHistory.TransferDate__c = Date.today();
        return transferHistory;
    }
}