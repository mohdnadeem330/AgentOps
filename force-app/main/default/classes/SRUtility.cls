/*
* Purpose: Utility class for HexaBPM__Service_Request__c
*/
public with sharing class SRUtility {
    
    public static Boolean checkSumOfRebateAmount(Id soId, Decimal amountOnSR) {
         List<SalesOrder__c> soList = [SELECT Id, LastInstallmentRebate__c, OtherRebateAmount__c,AdditionalRebate__c,AdditionalRebate2__c,(select Id, Amount__c, SalesOrder__c from Payments__r where PaymentSubType__c ='Rebate'and Status__c!='Reversed') FROM SalesOrder__c WHERE Id=:soId Limit 1];//new List<SalesOrder__c>();
        Boolean isvalidForRebateCN = FALSE;
        System.debug('soList.size() > '+soList.size());
        if(soList.size()>0) {
            Decimal totalRebateOnSO = (soList[0].LastInstallmentRebate__c>0 ? soList[0].LastInstallmentRebate__c : 0) + (soList[0].OtherRebateAmount__c>0 ? soList[0].OtherRebateAmount__c : 0)+ (soList[0].AdditionalRebate__c>0 ? soList[0].AdditionalRebate__c : 0)+ (soList[0].AdditionalRebate2__c>0 ? soList[0].AdditionalRebate2__c : 0);
            Decimal exCNAmounts = 0;
            Decimal RamainingRebate = totalRebateOnSO;
            System.debug('totalRebateOnSO > '+totalRebateOnSO);
            System.debug('soList[0].Payments__r.size() > '+soList[0].Payments__r.size());

            if(soList[0].Payments__r.size()>0) {
                for(ReceiptAcknowledgement__c ra : soList[0].Payments__r) {
                    exCNAmounts = exCNAmounts+ra.Amount__c;
                }
        RamainingRebate = totalRebateOnSO-exCNAmounts;
            }
            
            isvalidForRebateCN = (exCNAmounts<=totalRebateOnSO && amountOnSR<=RamainingRebate);//(exCNAmounts + amountOnSR) >= totalRebateOnSO;
            System.debug('##isvalidForRebateCN > '+isvalidForRebateCN+' >> totalRebateOnSO='+totalRebateOnSO+' >> amountOnSR= '+amountOnSR+' > exCNAmounts= '+exCNAmounts+' > RamainingRebate= '+RamainingRebate);

        }
        return isvalidForRebateCN;
    }
    
    /*
* Purpose: To check whether Amount is received by Customer but not Cleared on Installment lines
*/
    public static Boolean checkForUnclearedReceipts (List<InstallmentLines__c> installmentLineList){
        Boolean hasUnclearedReceipt = false;
        
        for(InstallmentLines__c installmentLine: installmentLineList) {
            if (installmentLine.AmountReceived__c != null && installmentLine.AmountReceived__c != 0 && installmentLine.InvoicedAmount__c != null && installmentLine.InvoicedAmount__c < installmentLine.AmountReceived__c) {
                hasUnclearedReceipt = true;
                break;
            }
        }
        
        return hasUnclearedReceipt;
    }
    
    /*
* Purpose: To check whether Amount is outstanding or not on Receipt  - ADDED BYPASS CONDITION ONLY FOR PT - TEMPORARY SOLUTION //SS_FOR_RECEIPT_BYPASS_LOGIC_ASF_514
*/
    public static Boolean checkForOutstandingAmountWithBypass (List<ReceiptAcknowledgement__c> receiptsList, HexaBPM__Service_Request__c serviceRequest){
        Boolean hasOutStandingPayment = false;
        System.debug('1 serviceRequet.ByPass_Receipt_Validation__c -> '+serviceRequest.ByPass_Receipt_Validation__c);

        for (ReceiptAcknowledgement__c receipt: receiptsList) {
            System.debug('serviceRequest.ByPass_Receipt_Validation__c -> '+serviceRequest.ByPass_Receipt_Validation__c);
            if (!serviceRequest.ByPass_Receipt_Validation__c && receipt.OutstandingAmount__c != null && receipt.OutstandingAmount__c > Integer.valueOf(System.Label.BufferOutstandingAmount) && receipt.ServiceRequest__c == null && receipt.Status__c == Constants.RECEIPT_STATUS_CLEARED) {
                hasOutStandingPayment = true;
                break;
            }
        }
        System.debug('hasOutStandingPayment -> '+hasOutStandingPayment);

        return hasOutStandingPayment;
    }
    
    /*
* Purpose: To check whether Amount is outstanding or not on Receipt 
*/
    public static Boolean checkForOutstandingAmount (List<ReceiptAcknowledgement__c> receiptsList){
        Boolean hasOutStandingPayment = false;

        for (ReceiptAcknowledgement__c receipt: receiptsList) {
            if (receipt.OutstandingAmount__c != null && receipt.OutstandingAmount__c > Integer.valueOf(System.Label.BufferOutstandingAmount) && receipt.ServiceRequest__c == null && receipt.Status__c == Constants.RECEIPT_STATUS_CLEARED) {
                hasOutStandingPayment = true;
                break;
            }
        }
        System.debug('hasOutStandingPayment -> '+hasOutStandingPayment);

        return hasOutStandingPayment;
    }
    
    /*
* Purpose: Check whether Property has any financer or not
*/
    public static Boolean checkForPropertyMortgage (SalesOrder__c soRecord){
        Boolean hasPropertyMortgage = false;
        
        if(String.isNotBlank(soRecord.MortgageApplicationNumber__c)) {
            hasPropertyMortgage = true;
        }
        
        return hasPropertyMortgage;
    }
    
    
    /*
* Purpose: Check whether Late Payment Charges will apply or not
*/
    public static Boolean checkLatePaymentCharges (Id salesOrderId){
        Boolean hasLatePaymentCharges = false;
        
        LPCModel lpcDetail = LPCService.getOutstandingLPCforSalesOrder(salesOrderId);
        Decimal lpcThreshold = Decimal.valueOf(System.Label.LPCThreshold) ;
        if (lpcDetail.totalLPCDue > lpcThreshold) {
            hasLatePaymentCharges = true;
        }
        return hasLatePaymentCharges;
    }
    
    /*
* Purpose: Create new other charge on Sales Order level 
*/
    public static SalesOrderOtherCharges__c createSalesOrderOtherCharge(HexaBPM__Service_Request__c serviceRequest, String chargeType) {
        SalesOrderOtherCharges__c otherCharge = new SalesOrderOtherCharges__c();
        otherCharge.TypeOfCharge__c = chargeType;
        
        if(serviceRequest.BuyerName__c != null) {
            otherCharge.Account__c = serviceRequest.BuyerName__c;
        } else if(serviceRequest.HexaBPM__Customer__c != null) {
            otherCharge.Account__c = serviceRequest.HexaBPM__Customer__c;
        }
        otherCharge.Amount__c = serviceRequest.ChargeCollected__c;
        otherCharge.SalesOrder__c = serviceRequest.SalesOrder__c;
        otherCharge.AmountWithoutVAT__c = serviceRequest.AmountWithoutVAT__c;
        otherCharge.ServiceRequest__c=serviceRequest.Id;
        otherCharge.VATAmount__c = serviceRequest.AmountWithoutVAT__c != null && serviceRequest.AmountWithoutVAT__c != 0 ? serviceRequest.ChargeCollected__c - serviceRequest.AmountWithoutVAT__c : 0;
        insert otherCharge;
        
        return otherCharge;
    }
    
    /*
* Purpose: Create new Joint Owner(s) on Sales Order level 
*/
    public static List<JointOwner__c> createJointOwner(HexaBPM__Service_Request__c serviceRequest) {
        List<AccountRelationship__c> newAccountRelationshipList = new List<AccountRelationship__c>();
        List<JointOwner__c> newJointOwnerList = new List<JointOwner__c>();
        for (AgencyTeam__c agencyTeam: serviceRequest.Partners__r) {
            AccountRelationship__c newAccountRelationship = new AccountRelationship__c();
            newAccountRelationship.Account__c = agencyTeam.Account__c;
            newAccountRelationship.RelatedAccount__c = serviceRequest.BuyerName__c;
            newAccountRelationship.RelationshipType__c = agencyTeam.RelationshipType__c;
            newAccountRelationshipList.add(newAccountRelationship);
            
            JointOwner__c newJointOwner = new JointOwner__c();
            newJointOwner.RelationshipType__c = agencyTeam.RelationshipType__c;
            newJointOwner.Account__c = agencyTeam.Account__c;
            newJointOwner.SharePercentage__c = agencyTeam.ShareHoldingPercentage__c;
            newJointOwner.SalesOrder__c = serviceRequest.SalesOrder__c;
            newJointOwnerList.add(newJointOwner);
        }
        if (!newAccountRelationshipList.isEmpty() && !newJointOwnerList.isEmpty()) {
            insert newAccountRelationshipList;
            insert newJointOwnerList;
        }
        
        return newJointOwnerList;
    }
    
    /*
* Purpose: Create receipt allocation record on sales order 
*/
    public static ReceiptAllocation__c createReceiptAllocation(SalesOrderOtherCharges__c soOtherCharges, HexaBPM__Service_Request__c serviceRequest){
        
        ReceiptAcknowledgement__c receiptRecord = serviceRequest.Receipt_Acknowledgements__r!=null ? serviceRequest.Receipt_Acknowledgements__r.size()>0 ? serviceRequest.Receipt_Acknowledgements__r[0]:serviceRequest.Receipt_Acknowledgements__r:null;
        if(receiptRecord <> null){
            ReceiptAllocation__c allocationRecord = new ReceiptAllocation__c();
            allocationRecord.Account__c = serviceRequest.HexaBPM__Customer__c;
            allocationRecord.SalesOrder__c = serviceRequest.SalesOrder__c;
            allocationRecord.AmountApplied__c = serviceRequest.Receipt_Acknowledgements__r != null && serviceRequest.Receipt_Acknowledgements__r.size() > 0 && serviceRequest.ChargeCollected__c >= serviceRequest.Receipt_Acknowledgements__r[0].OutstandingAmount__c ?serviceRequest.Receipt_Acknowledgements__r[0].OutstandingAmount__c:serviceRequest.ChargeCollected__c;
            allocationRecord.ReceiptAcknowledgement__c = receiptRecord.Id;
            allocationRecord.SalesOrderOtherCharges__c = soOtherCharges.Id;
            allocationRecord.TypeOfInvoice__c = soOtherCharges.TypeOfCharge__c;
            insert allocationRecord;
            return allocationRecord;
        }
        return null;
    }
    
    /*
* Purpose: Create Receipt Acknowledgement record from SR 
*/
    public static ReceiptAcknowledgement__c createReceiptAcknowledgementFromSR(HexaBPM__Service_Request__c serviceRequest, String paymentType, Decimal amount){
        
        ReceiptAcknowledgement__c newRA = new ReceiptAcknowledgement__c();
        newRA.Opportunity__c = serviceRequest.SalesOrder__r.Opportunity__c;
        newRA.Account__c = serviceRequest.HexaBPM__Customer__c;
        newRA.Contact__c = serviceRequest.HexaBPM__Contact__c;
        newRA.SalesOrder__c = serviceRequest.SalesOrder__c;
        newRA.Amount__c = amount;
        newRA.PaymentType__c = paymentType;
        newRA.ServiceRequest__c = serviceRequest.Id;
        insert newRA;
        
        return newRA;
    }
    
    /*
* Purpose: Create Receipt Acknowledgement record from Sales Order 
*/
    public static ReceiptAcknowledgement__c createReceiptAcknowledgementFromSO(HexaBPM__Service_Request__c serviceRequest, SalesOrder__c salesOrder, String paymentType, Decimal amount){
        
        ReceiptAcknowledgement__c newRA = new ReceiptAcknowledgement__c();
        newRA.Opportunity__c = salesOrder.Opportunity__c;
        newRA.Account__c = salesOrder.Account__c;
        newRA.Contact__c = salesOrder.Contact__c;
        newRA.SalesOrder__c = salesOrder.Id;
        newRA.Amount__c = amount;
        newRA.PaymentType__c = paymentType;
        newRA.ServiceRequest__c = serviceRequest.Id;
        
        return newRA;
    }
    
    /*
* Purpose: Create Sales Order Other Charges From SR
*/
    public static SalesOrderOtherCharges__c createSalesOrderOtherCharge(HexaBPM__Service_Request__c serviceRequest, String chargeType, Decimal amount) {
        
        SalesOrderOtherCharges__c otherCharge = new SalesOrderOtherCharges__c();
        otherCharge.Account__c = serviceRequest.HexaBPM__Customer__c;
        otherCharge.SalesOrder__c = serviceRequest.SalesOrder__c;
        otherCharge.Amount__c = amount;
        otherCharge.TypeOfCharge__c = chargeType;
        otherCharge.ServiceRequest__c=serviceRequest.Id;
        
        if (chargeType == Constants.BUDGET_LINE_ADMFEE || chargeType == Constants.BUDGET_LINE_ADMADMINFEE) {
            otherCharge.Account__c = serviceRequest.BuyerName__c;

        } else if (chargeType == Constants.OTHER_CHARGES_TYPE_LPC_WAIVED_AMOUNT) {
            otherCharge.InvoicedAmount__c = amount;
        }
        
        insert otherCharge;
        return otherCharge;
    }
    
    /*
* Purpose: Create Sales Order Other Charges From Sales Order
*/
    public static SalesOrderOtherCharges__c createSalesOrderOtherChargeFromSO(SalesOrder__c salesOrder, String chargeType, String chargeSubType, Decimal amount, HexaBPM__Service_Request__c serviceRequest) {
        SalesOrderOtherCharges__c otherCharge = new SalesOrderOtherCharges__c();
        otherCharge.SalesOrder__c = salesOrder.Id;
        otherCharge.Account__c = salesOrder.Account__c;
        otherCharge.TypeOfCharge__c = chargeType;
        otherCharge.ServiceRequest__c = serviceRequest.Id;
        otherCharge.Remarks__c = chargeType+' For '+chargeSubType+': '+serviceRequest.Name;
        if (String.isNotBlank(chargeSubType)) {
            otherCharge.SubType__c = chargeSubType;
        }
        otherCharge.Amount__c = amount;
        otherCharge.OutstandingAmountinwords__c = Utilities.amountInWords(amount,'Dirham','Fils');

        return otherCharge;
    }
    
    /*
* Purpose: Create New SR From SR
*/
    public static HexaBPM__Service_Request__c createNewSRFromSR(HexaBPM__Service_Request__c serviceRequest, String srType) {
        List<FieldMapping__mdt> fieldMappingList = [SELECT Id, SourceObjectName__c, DestinationObjectName__c, SourceFieldName__c, 
                                                    DestinationFieldName__c, Condition__c FROM FieldMapping__mdt 
                                                    WHERE SourceObjectName__c = 'HexaBPM__Service_Request__c' AND 
                                                    DestinationObjectName__c = 'HexaBPM__Service_Request__c'];
        
        HexaBPM__Service_Request__c newSR = new HexaBPM__Service_Request__c();
        newSR.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', srType);
        
        //To check if the related sales order have pending or not to set value for charge type
        if(srType == Constants.INTERNAL_MORTGAGE_REGISTRATION_RT){
            newSR.SRType__c = Constants.INTERNAL_MORTGAGE_REGISTRATION_TYPE;
            SalesOrder__c salesOrder = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{serviceRequest.SalesOrder__c})[0];
            List<ReceiptAcknowledgement__c> receiptList = new List<ReceiptAcknowledgement__c>();
            for (ReceiptAcknowledgement__c receipts : salesOrder.Payments__r) {
                receiptList.add(receipts);
            }
            
            if(!receiptList.isEmpty()){
                Boolean hasOutStandingPayment = SRUtility.checkForOutstandingAmount(receiptList);
                if(hasOutStandingPayment) {
                    newSR.ChargeType__c = Constants.NOT_FULLY_PAID;
                } else {
                    newSR.ChargeType__c = Constants.FULLY_PAID;
                }
                System.debug('newSR.ChargeType__c '+newSR.ChargeType__c);
            }
        }
        
        for(FieldMapping__mdt fieldMapping: fieldMappingList) {
            List<String> conditionList = fieldMapping.Condition__c != null ? fieldMapping.Condition__c.split(',') : new List<String>();
            if (conditionList.contains(srType)) {
                newSR.put(fieldMapping.DestinationFieldName__c, serviceRequest.get(fieldMapping.SourceFieldName__c));
            }
        }
        System.debug('newSR.ChargeType__c '+newSR.ChargeType__c);
        System.debug('newSR '+newSR);
        insert newSR;
        return newSR;
    }
    
    /*
* Purpose: Create New Cancellation SRs From SR
*/
    public static List<HexaBPM__Service_Request__c> createNewCancellationSRsFromSR(HexaBPM__Service_Request__c serviceRequest, String srType) {
        List<FieldMapping__mdt> fieldMappingList = [SELECT Id, SourceObjectName__c, DestinationObjectName__c, SourceFieldName__c, 
                                                    DestinationFieldName__c, Condition__c FROM FieldMapping__mdt 
                                                    WHERE (SourceObjectName__c = 'HexaBPM__Service_Request__c' OR 
                                                           SourceObjectName__c = 'SRUnitSelected__c') AND 
                                                    DestinationObjectName__c = 'HexaBPM__Service_Request__c'];
        
        List<HexaBPM__Service_Request__c> newSRList = new List<HexaBPM__Service_Request__c>();
        for (SRUnitSelected__c unit: serviceRequest.SRUnitSelected__r) {
            if (serviceRequest.RecordType.Name == Constants.CONSOLIDATION_RT && unit.RetainedCancelled__c == Constants.RETAINED_UNIT) {
                continue;
            }
            HexaBPM__Service_Request__c newSR = new HexaBPM__Service_Request__c();
            newSR.RecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', srType);
            newSR.SRType__c = Constants.CANCELLATION_SR_TYPE;
            
            if (serviceRequest.RecordType.Name == Constants.MUTUAL_CANCELLATION_RT) {
                if (unit.FinalEquityRefund__c > 0) {
                    newSR.CancellationReason__c = Constants.CANCELLATION_REASON_MUTUAL_CANCELLATION_REFUND;
                } else {
                    newSR.CancellationReason__c = Constants.CANCELLATION_REASON_MUTUAL_CANCELLATION_FORFEITURE;
                }
            } else if (serviceRequest.RecordType.Name == Constants.CONSOLIDATION_RT) {
                newSR.CancellationReason__c = Constants.CANCELLATION_REASON_CONSOLIDATION;
            } else if (serviceRequest.RecordType.Name == Constants.UNIT_SWAP_RT) {
                newSR.CancellationReason__c = Constants.CANCELLATION_REASON_UNIT_SWAP;
            }
            
            for(FieldMapping__mdt fieldMapping: fieldMappingList) {
                List<String> conditionList = fieldMapping.Condition__c != null ? fieldMapping.Condition__c.split(',') : new List<String>();
                if (conditionList.contains(srType)) {
                    if (fieldMapping.SourceObjectName__c == 'HexaBPM__Service_Request__c') {
                        newSR.put(fieldMapping.DestinationFieldName__c, serviceRequest.get(fieldMapping.SourceFieldName__c));
                    } else if (fieldMapping.SourceObjectName__c == 'SRUnitSelected__c') {
                        if ((serviceRequest.RecordType.Name == Constants.CONSOLIDATION_RT || serviceRequest.RecordType.Name == Constants.UNIT_SWAP_RT) && unit.FinalEquityRefund__c > 0 && fieldMapping.SourceFieldName__c == 'FinalEquityRefund__c') {
                            newSR.put('ReallocationAmount__c', unit.get(fieldMapping.SourceFieldName__c));
                            newSR.put('EquityAmount__c', unit.get(fieldMapping.SourceFieldName__c));
                        } else if (serviceRequest.RecordType.Name == Constants.MUTUAL_CANCELLATION_RT && unit.FinalEquityRefund__c < 0 && fieldMapping.SourceFieldName__c == 'FinalEquityRefund__c') {
                            newSR.put('EquityAmount__c', 0);
                        } else {
                            newSR.put(fieldMapping.DestinationFieldName__c, unit.get(fieldMapping.SourceFieldName__c));
                        }
                    }
                }
            }
            newSRList.add(newSR);
        }
        insert newSRList;
        return newSRList;
    }
    
    public static Id getSRTemplate(String name){
        HexaBPM__SR_Template__c srTemp = [Select Id from HexaBPM__SR_Template__c where Name=: name];
        return srTemp.Id;
    }
    
    public static void updateServiceRequestStep(String srId, String stepName, String stepStatus, String stepNotes){
        
        HexaBPM__Step__c stepRec = [SELECT Name, HexaBPM__Step_Status__c, HexaBPM__SR__c, HexaBPM__SR_Step__r.Name, HexaBPM__Step_Notes__c, HexaBPM__Summary__c 
                                    FROM HexaBPM__Step__c
                                    WHERE HexaBPM__SR__c =: srId AND HexaBPM__Summary__c =: stepName order by CreatedDate Desc limit 1];
        
        if(stepStatus != ''){
            HexaBPM__Status__c stepStatusRecord = [SELECT Id, Name FROM HexaBPM__Status__c WHERE Name=: stepStatus];
            stepRec.HexaBPM__Status__c = stepStatusRecord.Id;
        }
        
        if(stepNotes != ''){
            stepRec.HexaBPM__Step_Notes__c = stepNotes;
        }
        update stepRec;
    }
    
    public static HexaBPM__Step__c updateMultipleServiceRequestStep(String srId, String stepName, String stepStatus, String stepNotes, String openStatus){
        
        List<HexaBPM__Step__c> stepRecList = [SELECT Name, HexaBPM__Step_Status__c, HexaBPM__SR__c, HexaBPM__SR_Step__r.Name, HexaBPM__Step_Notes__c, HexaBPM__Summary__c 
                                    FROM HexaBPM__Step__c
                                    WHERE HexaBPM__SR__c =: srId AND HexaBPM__Summary__c =: stepName AND HexaBPM__Step_Status__c =: openStatus order by CreatedDate Desc limit 1];


        HexaBPM__Step__c stepRec = new HexaBPM__Step__c();
        if(!stepRecList.isEmpty()){
            stepRec = stepRecList[0];
        } else {
            return null;
        }
        
        if(stepStatus != ''){
            HexaBPM__Status__c stepStatusRecord = [SELECT Id, Name FROM HexaBPM__Status__c WHERE Name=: stepStatus];
            stepRec.HexaBPM__Status__c = stepStatusRecord.Id;
        }
        
        if(stepNotes != ''){
            stepRec.HexaBPM__Step_Notes__c = stepNotes;
        }
        return stepRec;
    }
    
    public static List<String> getDocumentsToBeUploadedToDARI(String srId){
        
        List<String> srDocumentsNames = new List<String>();
        srDocumentsNames.add('Aldar Signed SPA');
        
        List<HexaBPM__SR_Doc__c> srDocs = [select id, Name, SyncStatus__c from HexaBPM__SR_Doc__c WHERE Name IN : srDocumentsNames and HexaBPM__Service_Request__c =: srId AND SyncStatus__c != : Constants.STATUS_SYNCED];
        List<String> srDocumentstoReupload = new List<String>();
        
        for (HexaBPM__SR_Doc__c srDocRecord : srDocs) {
            srDocumentstoReupload.add(srDocRecord.Name);
        }
        return srDocumentstoReupload;
    }
    
    @future
    public static void submitSRFuture(List<Id> srRecords){
        submitSR(srRecords);
    }
    //--- Used to submit SR 
    public static void submitSR(List<Id> srRecords){
        
        List<HexaBPM__Service_Request__c> srRecordsToUpdate = new List<HexaBPM__Service_Request__c>();
        HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: Constants.SUBMITTED LIMIT 1];
        
        for (Id srRecordId : srRecords) {
            HexaBPM__Service_Request__c srRecord = new HexaBPM__Service_Request__c(Id=srRecordId);
            srRecord.HexaBPM__External_SR_Status__c = objSRStatus.Id;
            srRecord.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;
            srRecord.HexaBPM__Submitted_DateTime__c = system.now();
            srRecord.HexaBPM__Submitted_Date__c = system.today();
            
            srRecordsToUpdate.add(srRecord);
        }
        update srRecordsToUpdate;
        
    }
    
    /*
Purpose : To send Mortgaged Release Approved Mail to customer with Statement of Account PDF document
*/
    @future(callout =true)
    public static void generatePdfAndSendEmail(String contactId, String emailTemplateId, String serviceRequest, String orgWideEmailAddress, String salesOrder, String fileName){
        list<Messaging.EmailFileAttachment> attachmentList = new list<Messaging.EmailFileAttachment>();
        
        SalesOrder__c soRecord = [select id, Contact__r.Email,Contact__c,Account__r.PersonEmail from salesorder__c where id =: salesOrder];

        //get All join owners
        List<String> ccAddress = new List<String>();
        map<id,set<String>> soToJointOwnerMap = DefaultAndTerminationUtility.getOwnerEmailList(new set<ID>{soRecord.Id});
        if(soToJointOwnerMap.containsKey(soRecord.Id) && !soToJointOwnerMap.get(soRecord.Id).isEmpty()){
            ccAddress.addAll(soToJointOwnerMap.get(soRecord.Id));
        }
        System.debug('toAddress '+ccAddress);
        
        // for SPA Payment confirmation, get the related Handover SR and add KAR and HO Agent
        list<HexaBPM__Service_Request__c> srRecord = [select id,HexaBPM__Parent_SR__r.HOAgent__r.Email,HexaBPM__Parent_SR__r.HOKAR__r.Email,HexaBPM__Parent_SR__r.HOAgent__c,HexaBPM__Parent_SR__r.HOKAR__c from HexaBPM__Service_Request__c where id =  :serviceRequest limit 1];
        System.debug('toAddress '+srRecord);
        if(!srRecord.isEmpty()){
            if(srRecord[0].HexaBPM__Parent_SR__r.HOAgent__c!=null){
                ccAddress.add(srRecord[0].HexaBPM__Parent_SR__r.HOAgent__r.Email);
            }
            if(srRecord[0].HexaBPM__Parent_SR__r.HOKAR__c!=null){
                ccAddress.add(srRecord[0].HexaBPM__Parent_SR__r.HOKAR__r.Email);
            }
        }
        System.debug('toAddress '+ccAddress);
        List<String> toAddress = new List<String>();
        toAddress.add(soRecord.Contact__c != null ? soRecord.Contact__r.Email : soRecord.Account__r.PersonEmail );
        System.debug('toAddress '+toAddress);
        PageReference pdf = Page.StatementOfAccountDocument;
        pdf.getParameters().put('id',salesOrder);
        
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(fileName+'.pdf');
        efa.setBody(Test.isRunningTest()? blob.valueOf('Test') :pdf.getContent());
        attachmentList.add(efa);
        list<Messaging.SingleEmailMessage> emailsToSend = new list<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage tempEmailInstance = new Messaging.SingleEmailMessage();
        tempEmailInstance = Utilities.getEmailInstance(contactId,emailTemplateId,serviceRequest,toAddress,null,ccAddress,null,null,null,attachmentList,orgWideEmailAddress);
        tempEmailInstance.setSaveAsActivity(true);
        emailsToSend.add(tempEmailInstance);
        list<Messaging.SendEmailResult> emailResult  = Utilities.sendEmail(emailsToSend);
        
    }
    

    //--- Check Default Installments
    public static List<Id> checkDefaultInstallments(List<Id> installmentLinesList){
        
        List<Id> defaultInstallmentsList = new List<Id>();

        List<HexaBPM__Service_Request__c> DTSRRecords = [Select Id, InstallmentLine__c From HexaBPM__Service_Request__c Where InstallmentLine__c in : installmentLinesList AND HexaBPM__Record_Type_Name__c =: Constants.DEFAULT_AND_TERMINATION_DEV_RT];
        
        for (HexaBPM__Service_Request__c srRecord : DTSRRecords) {
            defaultInstallmentsList.add(srRecord.InstallmentLine__c);
        }
        return defaultInstallmentsList;
    }
    public static Municipality_Fee_Details__mdt fetchMunicipalityFee(string city){
        List<Municipality_Fee_Details__mdt> mFeedDetails = [SELECT Id,IsActive__c,City__c,Municipality_Charge__c,Municipality_Charge_Name__c,Municipality_Fee_perc__c,DeveloperName,MasterLabel FROM Municipality_Fee_Details__mdt WHERE City__c =:city AND IsActive__c =: true];
        if(!mFeedDetails.isEmpty()){
            return mFeedDetails[0];
        }
        return null;
    }
}