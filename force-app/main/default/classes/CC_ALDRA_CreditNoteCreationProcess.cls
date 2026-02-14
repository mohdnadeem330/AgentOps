global without sharing class CC_ALDRA_CreditNoteCreationProcess implements HexaBPM.iCustomCodeExecutable {
    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException { }
    public static List<ReceiptAllocation__c> AllocationReceiptWithAckOCList = new List<ReceiptAllocation__c>();
    public static String INVOICE_REVERSAL = 'INVOICE_REVERSAL';
    public static String REBATE = 'Rebate';
    public static String ERROR_DO_NOT_SELECT_IL_OR_OC_FOR_REBATE = 'Don\'t select IL or OC for Rebate';
    public static String ERROR_IR_CANNOT_BE_REBATE = 'Please uncheck Invoice Reversal to proceed the Rebate SR';
    public static String ERROR_INVALID_REBATE_AMOUNT = 'Invalid Rebate Amount. Either it was already billed / Enter the Amount lesser than or equal to Total Rebate value';
    public static String ERROR_SR_AMOUNT_SHOULD_BE_POPULATED = 'Please enter the Credit Note Amount';
    public static String WARNING_INITIATOR_CANNOT_BE_THE_VERIFIER = 'Initiator Cannot Verify the Request.';
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        System.debug('EvaluateCustomCode Invoked SARAN');
        String returnString = 'WENT WRONG';
        String MANAGE_RECEIPT = 'Manage Receipt';
        String VERIFY_REQUEST = 'Verify the Request';
        String INVALID_REVERSAL_MESSAGE = 'You cannot proceed with Installment Reversal for the ';
        try {
            if(stp == null || stp.HexaBPM__SR__c == null){
                System.debug('stp == null');
                
                returnString='CC_ALDRA_CreditNoteCreationProcess: Invalid SR or SR Step';
            } else {
                HexaBPM__Service_Request__c sRRecord = [SELECT Id,Amount__c, AmountWithoutVAT__c, ChargeType__c, VATAmount__c,
                                                        InstallmentLine__c, InstallmentLine__r.InstallmentAmount__c,InstallmentLine__r.InvoicedAmount__c,
                                                        InstallmentLine__r.Name,InstallmentLine__r.InvoiceId__c,
                                                        PaymentType__c, Credit_Note_Sub_Type__c, Unit__c, SalesOrder__c, HexaBPM__Customer__c,
                                                        Sales_Order_Other_Charges__c, ServiceRequestComments__c, Sales_Order_Other_Charges__r.ERPID__c,
                                                        HexaBPM__External_SR_Status__r.Name,
                                                        InvoiceReversal__c,Sales_Order_Other_Charges__r.amount__C,
                                                        SalesOrder__r.Opportunity__c,
                                                        (SELECT Id, HexaBPM__Step_Status__c, OwnerId, HexaBPM__Summary__c FROM HexaBPM__Steps_SR__r),
                                                        (SELECT Id FROM HexaBPM__SR_Docs__r)
                                                        FROM HexaBPM__Service_Request__c
                                                        WHERE Id =: stp.HexaBPM__SR__c  Limit 1];
                String stepStatus = '';
                Id manageReceiptOwner = null;
                Id verifyRequestOwner = null;
                for(HexaBPM__Step__c step: sRRecord.HexaBPM__Steps_SR__r) {
                    if(step.HexaBPM__Summary__c == MANAGE_RECEIPT) {
                        manageReceiptOwner = step.OwnerId;
                    } else if(step.HexaBPM__Summary__c == VERIFY_REQUEST) {
                        verifyRequestOwner = step.OwnerId;
                    }
                    if(step.Id == stp.Id) {
                        stepStatus = step.HexaBPM__Step_Status__c;
                    }
                }
                Map<String, String> cdLinkEntityId = new Map<String, String>();
                for(HexaBPM__SR_Doc__c doc: sRRecord.HexaBPM__SR_Docs__r) {
                    cdLinkEntityId.put(doc.Id, ALDOC_OtherChargesHelper.generatePublicURL(doc.Id));
                }
                System.debug('SRTemplateName__c -> '+stp.SRTemplateName__c);
                String subType = sRRecord.Credit_Note_Sub_Type__c;
                
                Boolean isPaymentStartedIL = false;
                if(sRRecord.InvoiceReversal__c) {
                    isPaymentStartedIL = (sRRecord.InstallmentLine__r.InvoicedAmount__c!=0 && sRRecord.InstallmentLine__r.InvoicedAmount__c!=null) || sRRecord.InstallmentLine__r.InstallmentAmount__c == sRRecord.InstallmentLine__r.InvoicedAmount__c;
                }
                
                returnString = 'Something Went Wrong > Name: '+stp.HexaBPM__Summary__c+' > '+stp.Name+' > '+stp.HexaBPM__Status__c +' > '+ isPaymentStartedIL;
                System.debug('isPaymentStartedIL -> '+isPaymentStartedIL+ ' > stp.HexaBPM__Summary__c -> '+stp.HexaBPM__Summary__c);
                
                if(stp.HexaBPM__Summary__c == MANAGE_RECEIPT && stepStatus == Constants.COMPLETED) {
                    //SS_REBATE_IMPLEMENTATION_09Aug23-START
                    System.debug('#### REBATE ->< '+subType); 
                    
                    if(subType == 'Other Charges Reversal' && sRRecord.InvoiceReversal__c == false){
                        if(sRRecord.Sales_Order_Other_Charges__c!=null){
                            List<ReceiptAllocation__c> receiptAllocList= [select ID,AmountApplied__c from ReceiptAllocation__c where SalesOrderOtherCharges__c=:sRRecord.Sales_Order_Other_Charges__c];
                            decimal sumAllocation=0.0;
                            for (ReceiptAllocation__c recep:receiptAllocList){
                                sumAllocation = sumAllocation+recep.AmountApplied__c;
                            }
                            if (sRRecord.Amount__c > sRRecord.Sales_Order_Other_Charges__r.amount__C){
                                return 'Amount should not be greater than other charges Amount';
                            }
                            if(sumAllocation > 0){
                                decimal lestoverammount= sRRecord.Sales_Order_Other_Charges__r.amount__C- sumAllocation;
                                if(sRRecord.Amount__c > lestoverammount){
                                    return 'Amount should not be greater than diffrence of other charge amount and total of recipt allocation Amount';
                                }
                            }
                        }
                    }
                    if(subType == REBATE) {
                        Boolean isPopulated = (sRRecord.InstallmentLine__c!=null || sRRecord.Sales_Order_Other_Charges__c!=null) ? true : false;
                        System.debug('#### isPopulated ->< '+isPopulated);
                        if(isPopulated) {
                            returnString = ERROR_DO_NOT_SELECT_IL_OR_OC_FOR_REBATE;
                            return returnString;
                        }
                        if(sRRecord.Amount__c == null || sRRecord.Amount__c == 0) {
                            return ERROR_SR_AMOUNT_SHOULD_BE_POPULATED;
                        }
                        
                        if(!SRUtility.checkSumOfRebateAmount(sRRecord.SalesOrder__c, sRRecord.Amount__c)) {
                            returnString = ERROR_INVALID_REBATE_AMOUNT;
                        } else {
                            returnString = null;
                        }
                        //SS_REBATE_IMPLEMENTATION_09Aug23-END
                    } else {
                        if(isPaymentStartedIL) { //If Started - Partially Cleared or Cleared
                            returnString = INVALID_REVERSAL_MESSAGE+sRRecord.InstallmentLine__r.Name;
                        } else {
                            //Proceed with the next step of Invoice Reversal
                            returnString = null;
                        }
                    }
                } else if(stp.HexaBPM__Summary__c == VERIFY_REQUEST  && stepStatus == Constants.STATUS_APPROVED) { //a0S8d0000062Xv2EAE - Approved
                    System.debug('$$$ subType -> '+subType);
                    if(manageReceiptOwner == verifyRequestOwner) { //Common code for Maker and Checker validation
                        returnString = WARNING_INITIATOR_CANNOT_BE_THE_VERIFIER;//'Initiator Cannot Verify the Request.';
                        return returnString;
                    }
                    
                    if(isPaymentStartedIL) {
                        returnString = INVALID_REVERSAL_MESSAGE+sRRecord.InstallmentLine__r.Name;
                        return returnString;
                    }
                    
                    returnString = returnString+' >>';
                    System.debug('$$$2 subType -> '+subType);
                    if(sRRecord.InvoiceReversal__c) {
                        doCreditNoteCallout(null, cdLinkEntityId, subType, stp.HexaBPM__SR__c, sRRecord.InstallmentLine__c, sRRecord.InstallmentLine__r.InvoiceId__c,true);
                    } else if(subType == REBATE) {
                        System.debug('$$$3 subType -> '+subType);
                        //SS_REBATE_IMPLEMENTATION_09Aug23-START
                        ReceiptAcknowledgement__c rack = prepareReceiptAck(sRRecord);
                        insert rack;
                        System.debug('$$$ rack -> '+rack.Id);
                        doCreditNoteCallout(new List<Id>{rack.Id}, cdLinkEntityId, subType, stp.HexaBPM__SR__c, sRRecord.InstallmentLine__c, sRRecord.InstallmentLine__r.InvoiceId__c,false);
                        
                        //SS_REBATE_IMPLEMENTATION_09Aug23-END
                    } else {
                        ReceiptAcknowledgement__c rack = prepareReceiptAck(sRRecord);
                        insert rack;
                        System.debug('rack -> '+rack.Id);
                        
                        ReceiptAllocation__c ralloc = prepareRAlloc(sRRecord, rack);
                        insert ralloc;
                        
                        System.debug('ralloc -> '+ralloc.Id);
                        System.debug('### cdLinkEntityId -> '+cdLinkEntityId.values());
                        doCreditNoteCallout(new List<Id>{ralloc.Id}, cdLinkEntityId, subType, stp.HexaBPM__SR__c, null, null, false);
                    }
                    returnString = null;
                }
                
            }
            
        } catch(Exception ex) {
            
            returnString = returnString+ex.getMessage()+ex.getLineNumber()+ex.getStackTraceString();
            System.debug('ex cep tion -> '+ex.getMessage()+ex.getLineNumber()+returnString);
            Logger__c lg = LoggerService.addApexLog(ex, 'Credit note SR Process', 'CC_ALDRA_CreditNoteCreationProcess', 'EvaluateCustomCode');
            upsert lg;
        }
        return returnString;
    }
    //SS_REBATE_IMPLEMENTATION_09Aug23-START
    public static ReceiptAcknowledgement__c prepareReceiptAck(HexaBPM__Service_Request__c sRRecord) {
        ReceiptAcknowledgement__c rack = new ReceiptAcknowledgement__c();
        rack.Account__c = sRRecord.HexaBPM__Customer__c;
        rack.SalesOrder__c = sRRecord.SalesOrder__c;
        rack.Amount__c = sRRecord.Amount__c;
        System.debug('### sRRecord.PaymentType__c -> '+sRRecord.ChargeType__c);
        System.debug('### sRRecord.Credit_Note_Sub_Type__c -> '+sRRecord.Credit_Note_Sub_Type__c);
        rack.Status__c = Constants.RECEIPT_STATUS_CLEARED; //As we are inserting the credit note and passing to ERP, marking the receipt as Cleared
        rack.PaymentType__c = sRRecord.ChargeType__c;
        rack.PaymentSubType__c = sRRecord.Credit_Note_Sub_Type__c;
        rack.ServiceRequest__c = sRRecord.Id;
        rack.IsStopSyncingWithERP__c = true;
        rack.Opportunity__c = sRRecord.SalesOrder__r.Opportunity__c;
        //insert rack;
        return rack;
    }
    
    public static ReceiptAllocation__c prepareRAlloc(HexaBPM__Service_Request__c sRRecord,ReceiptAcknowledgement__c rack) {
        ReceiptAllocation__c ralloc = new ReceiptAllocation__c();
        if(sRRecord.InstallmentLine__c!=null) {
            ralloc.InstallmentLine__c = sRRecord.InstallmentLine__c;
            ralloc.TypeOfInvoice__c = Constants.INVOICE_TYPE_INSTALLMENT;
        }
        if(sRRecord.Sales_Order_Other_Charges__c!=null) {
            ralloc.SalesOrderOtherCharges__c = sRRecord.Sales_Order_Other_Charges__c;
            ralloc.TypeOfInvoice__c = Constants.INVOICE_TYPE_CREDIT_NOTE;
        }
        ralloc.ReceiptAcknowledgement__c = rack.Id;
        ralloc.Account__c = sRRecord.HexaBPM__Customer__c;
        ralloc.SalesOrder__c = sRRecord.SalesOrder__c;
        ralloc.AmountApplied__c = sRRecord.Amount__c;
        ralloc.IsStopSyncingWithERP__c = true;
        //insert ralloc;
        return ralloc;
    }
    //SS_REBATE_IMPLEMENTATION_09Aug23-END
    
    @Future(callout=true)
    public static void doCreditNoteCallout(List<Id> recordIds, Map<String, String> cdLinkEntityId, String subType, String srRecordId, String installmentIdForInvoiceReversal, String installmentInvoiceIdForInvoiceReversal, Boolean invoiceReversal) 
    {
        //Credit note callout will happen from here   
        //This Method will being invoked from aldCreateOtherCharges LWC in Realtime From SalesOrderOtherCharges__c on Insert
        //recordId 		-> SalesOrderOtherCharges__c Id
        //muleConfigs 	->  Metadata to get the necessary information
        
        System.debug('doOtherChargeCallout -> invoked');
        Boolean IsTesting = FALSE; //For Admin Test
        List<ReceiptAllocation__c> receiptAlloWithAckToUpdate = new List<ReceiptAllocation__c>(); //Allocation with 
        List<HexaBPM__Service_Request__c> creditNoteSRListToUpdate = new List<HexaBPM__Service_Request__c>(); //SRs 
        
        List<Logger__c> loggerList = new List<Logger__c>();
        List<SObject> updateSObjectList = new List<SObject>(); //If record failed, then updating this list
        String requestBody = '';
        MuleSOResponeWrapper responseBody = new MuleSOResponeWrapper();
        
        try {
            System.debug('Level 1');
            MuleSoftSetting__mdt muleConfigs = MuleSoftSetting__mdt.getInstance(ALD_Constants.ALD_OTHER_CHARGES_MULE_NAME); //DML_ACTION
            Organization org = Utilities.getOrganizationDetails(); //DML_ACTION
            HexaBPM__Service_Request__c sRRecord = [SELECT Id,Amount__c, AmountWithoutVAT__c, VATAmount__c, ServiceRequestComments__c, Sales_Order_Other_Charges__c, 
                                                        InstallmentLine__c, InstallmentLine__r.InstallmentAmount__c,InstallmentLine__r.InvoicedAmount__c,
                                                        InstallmentLine__r.Name,InstallmentLine__r.InvoiceId__c,
                                                        PaymentType__c, Credit_Note_Sub_Type__c, Unit__c, SalesOrder__c, HexaBPM__Customer__c,
                                                        Sales_Order_Other_Charges__r.ERPID__c,ChargeType__c,
                                                        HexaBPM__External_SR_Status__r.Name,
                                                        InvoiceReversal__c,SRType__c,
                                                        SalesOrder__r.Opportunity__c,
                                                        (SELECT Id, HexaBPM__Step_Status__c, OwnerId, HexaBPM__Summary__c FROM HexaBPM__Steps_SR__r),
                                                        (SELECT Id FROM HexaBPM__SR_Docs__r)
                                                        FROM HexaBPM__Service_Request__c
                                                        WHERE Id =: srRecordId  Limit 1];
             
            //If the SR is for Invoice Reversal
            if(invoiceReversal || subType == REBATE) {
                String SrId = srRecordId;
                ReceiptAcknowledgement__c rAck = new ReceiptAcknowledgement__c();
                if(subType == REBATE) {
                    rAck = [SELECT Id FROM ReceiptAcknowledgement__c WHERE Id IN:recordIds Limit 1];
                }
                
                //Do Callout
                requestBody = JSON.serialize(frameRequestBody(sRRecord, SrId, subType == REBATE ? rAck : null, subType, 'Installment', installmentIdForInvoiceReversal, installmentInvoiceIdForInvoiceReversal, cdLinkEntityId, invoiceReversal));
                String EndPointURL = muleConfigs.SandboxURL__c;
                if(!org.IsSandbox){
                    EndPointURL = muleConfigs.ProductionURL__c;
                }
                
                requestBody = requestBody.replaceAll(':null', ':""');
                System.debug('*** EndPointURL -> '+EndPointURL);
                System.debug('### *** requestBody -> '+requestBody);
                HTTPResponse response = new HTTPResponse();
                
                if(IsTesting) {
                    response.setStatusCode(201);
                    response.setBody('{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "50c29210-d82d-11ed-9436-SARAN", "results": { "othChgRes": [ { "sfRequestId": "50c29210-d82d-11ed-9436-SARAN", "srSFId": "STANDALONE", "sfId": "a292500000228qxAAA", "erpId": "9058910", "recAcct": "02.10.SARAN.123142.02.00.000.000", "expAcct": "02.10.SARAN.421101.02.00.000.000", "taxAcct": "02.10.SARAN.233169.02.00.000.000", "status": "Success", "errorMsg": "", "invoiceNo": "70019940" } ] } }');
                } else {                
                    Map<String,string> headerMap = new Map<String,string>();
                    headerMap.put('client_id', muleConfigs.APIId__c);
                    headerMap.put('client_secret', muleConfigs.APIKey__c);
                    headerMap.put('Content-Type', 'application/json');
                    
                    response = Utilities.makeHHTTPCallout(muleConfigs.Method__c, EndPointURL, 
                                                          requestBody, headerMap); //CALLOUT_ACTION
                    System.debug('### *** response.getBody() -> '+response.getBody());
                    
                    responseBody = ALDOC_OtherChargesHelper.parse(response.getBody());
                    
                    if(responseBody.statusCode != Constants.MULESOFT_SUCCESS_STATUS){
                        loggerList.add(LoggerService.addApexServiceCalls(ALD_Constants.ALD_OTHER_CHARGES_MULE_NAME,'CC_ALDRA_CreditNoteCreationProcess', 'doCreditNoteCallout_ERROR',  requestBody, response.getBody()+' ** '+response.getStatusCode(), SrId));
                        updateSObjectList.add(ALDOC_OtherChargesHelper.updateAsFailed(new List<Id>{SrId}, null, 'Status Code: '+responseBody.statusCode+'.', false));
                    } else {
                        loggerList.add(LoggerService.addApexServiceCalls(ALD_Constants.ALD_OTHER_CHARGES_MULE_NAME,'CC_ALDRA_CreditNoteCreationProcess', 'doCreditNoteCallout_SUCCESS',  requestBody, response.getBody(), SrId));
                        HexaBPM__Service_Request__c creditNoteSR = updateCreditNoteSReq(responseBody, true);
                        System.debug('creditNoteSRListToUpdate -> '+creditNoteSR);
                        if(creditNoteSR!=null) {
                            creditNoteSRListToUpdate.add(creditNoteSR);
                        }
                    }
                }
            } else {
                //If Normal Installment Reversal or OC Reversal
                AllocationReceiptWithAckOCList = [SELECT Id, Account__c, AmountApplied__c, ErrorReason__c,
                                                  InstallmentLine__c, InstallmentLine__r.ERPID__c, InstallmentLine__r.InvoiceId__c, 
                                                  ReceiptAcknowledgement__c,
                                                  ReceiptAcknowledgement__r.ServiceRequest__r.Id,
                                                  ReceiptAcknowledgement__r.ServiceRequest__r.SRType__c,
                                                  ReceiptAcknowledgement__r.ServiceRequest__r.ServiceRequestComments__c,
                                                  ReceiptAcknowledgement__r.PaymentType__c, ReceiptAcknowledgement__r.PaymentSubType__c,
                                                  SalesOrderOtherCharges__c, SalesOrderOtherCharges__r.ERPID__c,
                                                  SalesOrderOtherCharges__r.Amount__c,
                                                  
                                                  SalesOrderOtherCharges__r.AmountWithoutVAT__c,SalesOrderOtherCharges__r.VATAmount__c,
                                                  SyncStatus__c, SalesOrder__c
                                                  FROM ReceiptAllocation__c 
                                                  WHERE  Id IN :recordIds]; //DML_ACTION
                System.debug('LEvel 2');
                for(ReceiptAllocation__c allocation : AllocationReceiptWithAckOCList) {
                    Id SrId = allocation.ReceiptAcknowledgement__r.ServiceRequest__r.Id;
                    System.debug('## ReceiptAllocation__c -> SrId = '+SrId);
                    String ErpIdInAllocSection = allocation.InstallmentLine__c != null ? allocation.InstallmentLine__r.InvoiceId__c : allocation.SalesOrderOtherCharges__r.ERPID__c;
                    String TYPE_OF_CHARGE = allocation.InstallmentLine__c != null ? 'Installment' : 'Other Charges';
                    String SFIdInAllocSection = allocation.InstallmentLine__c != null ? allocation.InstallmentLine__c : allocation.SalesOrderOtherCharges__c;
                    
                    //We didnt do bulkify in sending response by considering the previous challenges in getting response time. 
                    //With this approach, response will be captured immediately on each records. Failiure response will not affect other records.
                    
                    //Do Callout
                    requestBody = JSON.serialize(frameRequestBody(sRRecord, SrId, allocation, subType, TYPE_OF_CHARGE, SFIdInAllocSection, ErpIdInAllocSection, cdLinkEntityId, false));
                    
                    String EndPointURL = muleConfigs.SandboxURL__c;
                    if(!org.IsSandbox){
                        EndPointURL = muleConfigs.ProductionURL__c;
                    }
                    
                    requestBody = requestBody.replaceAll(':null', ':""');
                    System.debug('*** EndPointURL -> '+EndPointURL);
                    System.debug('### *** requestBody -> '+requestBody);
                    HTTPResponse response = new HTTPResponse();
                    
                    if(IsTesting) {
                        response.setStatusCode(201);
                        response.setBody('{ "applicationName": "x-ald-sferp-api", "success": true, "statusCode": "201", "correlationId": "50c29210-d82d-11ed-9436-0211179397d0", "results": { "othChgRes": [ { "sfRequestId": "50c29210-d82d-11ed-9436-0211179397d0", "srSFId": "STANDALONE", "sfId": "a292500000228qxAAA", "erpId": "9058910", "recAcct": "02.10.A439020.123142.02.00.000.000", "expAcct": "02.10.A439020.421101.02.00.000.000", "taxAcct": "02.10.A439020.233169.02.00.000.000", "status": "Success", "errorMsg": "", "invoiceNo": "70083100" } ] } }');
                    } else {                
                        Map<String,string> headerMap = new Map<String,string>();
                        headerMap.put('client_id', muleConfigs.APIId__c);
                        headerMap.put('client_secret', muleConfigs.APIKey__c);
                        headerMap.put('Content-Type', 'application/json');
                        
                        response = Utilities.makeHHTTPCallout(muleConfigs.Method__c, EndPointURL, 
                                                              requestBody, headerMap); //CALLOUT_ACTION
                        System.debug('### **** response.getBody() -> '+response.getBody());
                        
                        responseBody = ALDOC_OtherChargesHelper.parse(response.getBody());
                        
                        if(responseBody.statusCode != Constants.MULESOFT_SUCCESS_STATUS){
                            loggerList.add(LoggerService.addApexServiceCalls(ALD_Constants.ALD_OTHER_CHARGES_MULE_NAME,'CC_ALDRA_CreditNoteCreationProcess', 'doCreditNoteCallout_ERROR',  requestBody, response.getBody()+' ** '+response.getStatusCode(), SrId));
                            updateSObjectList.add(ALDOC_OtherChargesHelper.updateAsFailed(new List<Id>{SrId}, null, 'Status Code: '+responseBody.statusCode+'.', false));
                        } else {
                            HexaBPM__Service_Request__c creditNoteSR = updateCreditNoteSReq(responseBody, true);
                            System.debug('creditNoteSRListToUpdate -> '+creditNoteSR);
                            if(creditNoteSR!=null) {
                                creditNoteSRListToUpdate.add(creditNoteSR);
                            }
                            loggerList.add(LoggerService.addApexServiceCalls(ALD_Constants.ALD_OTHER_CHARGES_MULE_NAME,'CC_ALDRA_CreditNoteCreationProcess', 'doCreditNoteCallout_SUCCESS',  requestBody, response.getBody(), SrId));
                        }
                    }
                }
            }
            if(updateSObjectList.size()>0) {
                System.debug('updateSObjectList size -> '+updateSObjectList.size());
                update updateSObjectList;
            }
            if(loggerList.size()>0) {
                System.debug('loggerList size -> '+loggerList.size());
                insert loggerList;
            }
            if(creditNoteSRListToUpdate.size()>0) {
                System.debug('creditNoteSRListToUpdate size -> '+creditNoteSRListToUpdate.size());
                update creditNoteSRListToUpdate;
            }
        } catch(Exception ex) {
            Logger__c lgs = LoggerService.saveAndReturnLogger(LoggerService.addApexServiceCallsLog(ex, 'CC_ALDRA_CreditNoteCreationProcess', 'doCreditNoteCallout_EXCEPTION', ALD_Constants.ALD_OTHER_CHARGES_MULE_NAME, requestBody, String.valueOf(responseBody)));
            ALDOC_OtherChargesHelper.updateAsFailed(new List<Id>{srRecordId}, null, lgs.Id+' ** '+ex.getMessage()+' ** '+ex.getLineNumber()+' ** '+ex.getLineNumber(), true);
            System.debug('EXCEPTION CC_ALDRA_CreditNoteCreationProcess ** '+lgs.Id+' ** '+ex.getMessage()+' ** '+ex.getLineNumber()+' ** '+ex.getLineNumber()+' ## '+ex.getStackTraceString());
        }
        
    }
    
    private static Map<String, Object> frameRequestBody(HexaBPM__Service_Request__c sRRecord, Id SrId, SObject allocationObj, String subType, String TYPE_OF_CHARGE,String SFIdInAllocSection,String ErpIdInAllocSection, Map<String, String> cdLinkEntityId, Boolean isInvoiceReversal) {
        ReceiptAllocation__c allocation = new ReceiptAllocation__c();
        ReceiptAcknowledgement__c rAck = new ReceiptAcknowledgement__c();
        
        Map<String, Object> CreditNoteCharges = new Map<String, Object>();
        List<Object> CreditNoteList = new List<Object>();
        Map<String, Object> CreditNoteMap = new Map<String, Object>();
        CreditNoteMap.put('SR_SFID', SrId);
        System.debug('isInvoiceReversal -> '+isInvoiceReversal);
        if(isInvoiceReversal || subType == REBATE) {
            rAck = (ReceiptAcknowledgement__c)allocationObj;
            //INVOICE_REVERSAL); //Cntrl+F and Find other occurance -  INVOICE_REVERSAL); //Venu can confirm this Static Text for reversal, which attribute we need to pass this and how we get to kno in the response that its reversal
            CreditNoteMap.put('SFId', subType == REBATE ? rAck.Id : sRRecord.InstallmentLine__c);
            CreditNoteMap.put('OC_Name', sRRecord.SRType__c);
            CreditNoteMap.put('Sf_SalesOrderId', sRRecord.SalesOrder__c);
            CreditNoteMap.put('AccountId', sRRecord.HexaBPM__Customer__c);
            CreditNoteMap.put('Amount', String.valueOf(sRRecord.Amount__c));
            CreditNoteMap.put('AmountWithoutVAT', '');
            CreditNoteMap.put('VATAmount', '');
            CreditNoteMap.put('TypeOfCharge', 'Credit Note');
            CreditNoteMap.put('Description', sRRecord.ServiceRequestComments__c);
            CreditNoteMap.put('InstallmentLine', '');
            CreditNoteMap.put('IsInvoiceReversal', isInvoiceReversal ? 'Y':'N'); //SS_REBATE_IMPLEMENTATION_09Aug23
            
        } else {
            allocation = (ReceiptAllocation__c)allocationObj;
            CreditNoteMap.put('SFId', allocation.ReceiptAcknowledgement__c);
            CreditNoteMap.put('OC_Name', allocation.ReceiptAcknowledgement__r.ServiceRequest__r.SRType__c); //Mostly Credit Note with the current email    
            CreditNoteMap.put('Sf_SalesOrderId', allocation.SalesOrder__c);
            CreditNoteMap.put('AccountId', allocation.Account__c);
            CreditNoteMap.put('Amount', String.valueOf(allocation.AmountApplied__c));
            
            if(allocation.SalesOrderOtherCharges__c !=null && allocation.SalesOrderOtherCharges__r.Amount__c != sRRecord.Amount__c && allocation.SalesOrderOtherCharges__r.VATAmount__c!=0 && allocation.SalesOrderOtherCharges__r.VATAmount__c!=null)
            { 
                
                decimal amountWithoutVAT =sRRecord.Amount__c/1.05;
                decimal vATAmount = sRRecord.Amount__c - amountWithoutVAT;
                CreditNoteMap.put('AmountWithoutVAT', String.valueOf(amountWithoutVAT.setScale(2))); //Reson behind empty is ERP to identify whther it includes VAT or No           
                CreditNoteMap.put('VATAmount',String.valueOf(vATAmount.setScale(2)));
                
            }
            else
            {
                CreditNoteMap.put('AmountWithoutVAT', allocation.InstallmentLine__c != null ? '' : allocation.SalesOrderOtherCharges__r.VATAmount__c!=0 && allocation.SalesOrderOtherCharges__r.VATAmount__c!=null ? String.valueOf(allocation.SalesOrderOtherCharges__r.AmountWithoutVAT__c) : ''); //Reson behind empty is ERP to identify whther it includes VAT or No           
                CreditNoteMap.put('VATAmount', allocation.InstallmentLine__c != null ? '' : String.valueOf(allocation.SalesOrderOtherCharges__r.VATAmount__c));
                
            }
            
            //CreditNoteMap.put('AmountWithoutVAT', allocation.InstallmentLine__c != null ? '' : allocation.SalesOrderOtherCharges__r.VATAmount__c!=0 && allocation.SalesOrderOtherCharges__r.VATAmount__c!=null ? String.valueOf(allocation.SalesOrderOtherCharges__r.AmountWithoutVAT__c) : ''); //Reson behind empty is ERP to identify whther it includes VAT or No
            //CreditNoteMap.put('VATAmount', allocation.InstallmentLine__c != null ? '' : String.valueOf(allocation.SalesOrderOtherCharges__r.VATAmount__c));
            CreditNoteMap.put('TypeOfCharge', allocation.ReceiptAcknowledgement__r.PaymentType__c);
            CreditNoteMap.put('Description', allocation.ReceiptAcknowledgement__r.ServiceRequest__r.ServiceRequestComments__c);
            CreditNoteMap.put('InstallmentLine', '');
            CreditNoteMap.put('DocumentURls', cdLinkEntityId.get(allocation.Id));
            CreditNoteMap.put('IsInvoiceReversal', 'N');
        }
        
        CreditNoteMap.put('CurrencyCode', 'AED');
        
        CreditNoteMap.put('AmountReceived', '');                
        CreditNoteMap.put('OutAmountWords', '');
        
        CreditNoteMap.put('Opportunity', '');
        CreditNoteMap.put('SubType', subType);//String.valueOf(allocation.ReceiptAcknowledgement__r.PaymentSubType__c));
        
        Map<String, Object> AllocationMap = new Map<String, Object>();
        AllocationMap.put('TypeOfCharge', TYPE_OF_CHARGE);
        AllocationMap.put('SFID', SFIdInAllocSection);
        AllocationMap.put('ERPID', ErpIdInAllocSection);
        AllocationMap.put('Amount', isInvoiceReversal || subType == REBATE ? String.valueOf(sRRecord.Amount__c) : String.valueOf(allocation.AmountApplied__c));
        
        CreditNoteMap.put('othAllocations', AllocationMap);
        
        CreditNoteList.add(CreditNoteMap);
        CreditNoteCharges.put('OtherCharges', CreditNoteList); //Credit note but the header will continue as OtherCharges
        return CreditNoteCharges;
    }
    
    private static HexaBPM__Service_Request__c updateCreditNoteSReq(MuleSOResponeWrapper response, Boolean shallProcessResp) 
    {
        MuleSOResponeWrapper.MuleResponse results = response.results; 
        List<HexaBPM__Service_Request__c> creditNoteSRList = new List<HexaBPM__Service_Request__c>();
        if(shallProcessResp && response.statusCode == ALD_Constants.ALD_OTHER_CHARGES_SUCCESS_CODE && response.success) {
            for(MuleSOResponeWrapper.SOResponse oc : results.othChgRes) {
                HexaBPM__Service_Request__c creditNoteSR = new HexaBPM__Service_Request__c();
                creditNoteSR.Id = oc.srSFId; 
                if(oc.status == ALD_Constants.ALD_OTHER_CHARGES_STATUS_FAILURE || oc.erpId == null || oc.erpId == '') {
                    System.debug('oc.status -> '+oc.status);
                    creditNoteSR.ErrorReason__c = oc.errorMsg;
                    creditNoteSR.SyncStatus__c = ALD_Constants.STATUS_FAILED;
                } else if(oc.errorMsg != null && oc.errorMsg!= '' && oc.status == 'E') {
                    System.debug('oc.errorMsg -> '+oc.errorMsg);
                    creditNoteSR.ErrorReason__c = oc.errorMsg;
                    creditNoteSR.SyncStatus__c = ALD_Constants.STATUS_FAILED;
                } else {
                    System.debug('oc.erpId -> '+oc.erpId);
                    creditNoteSR.ErrorReason__c = '';
                    creditNoteSR.SyncStatus__c = ALD_Constants.STATUS_SYNCED;
                    if(oc.IsInvoiceReversal == 'Y') { //Cntrl+F and Find other occurance - INVOICE_REVERSAL); //Venu can confirm this Static Text for reversal
                        //To Remove the Invoice number from IL
                        //Capture ERP id in SF
                        creditNoteSR.ERPID__c = oc.erpId;
                        InstallmentLines__c il = new InstallmentLines__c();
                        il.Id = oc.sfId;
                        il.InvoiceId__c = null;
                        il.InvoiceNumber__c = null;
                        update il;
                        System.debug('il Id -> '+il.Id);
                    } else {
                        ReceiptAcknowledgement__c ack = new ReceiptAcknowledgement__c();
                        ack.Id = oc.sfId;
                        ack.ERPID__c = oc.erpId;
                        ack.ReceivableAccount__c = oc.recAcct;
                        ack.RevenueAccount__c = oc.expAcct;
                        ack.TaxAccount__c = oc.taxAcct;
                        ack.ReceiptNumber__c = 'CN-'+oc.invoiceNo;
                        ack.ReferenceNumber__c = 'CN-'+oc.invoiceNo;
                        ack.ClearedDate__c = System.today();
                        ack.ReceiptDate__c = System.today();
                        //ack.InvoiceNumber__c = oc.invoiceNo;
                        ack.SyncStatus__c = ALD_Constants.STATUS_SYNCED;
                        update ack;
                    }
                }
                return creditNoteSR;
            }
            
            /*if(soOtherCharges.size()>0) {
System.debug('soOtherCharges size -> '+soOtherCharges.size());
update soOtherCharges;
}*/
        }
        return null;
    }
    
    public static HexaBPM__Service_Request__c updateCreditNoteSR(HexaBPM__Service_Request__c newRecord) {
        HexaBPM__Service_Request__c updateSR = new HexaBPM__Service_Request__c();
        updateSR.Id = newRecord.Id;
        if(newRecord.Credit_Note_Sub_Type__c != REBATE) {
            if(newRecord.InstallmentLine__c!=null) {
                updateSR.Credit_Note_Sub_Type__c = Constants.PAYMENT_SUB_TYPE_INSTALLMENT_REVERSAL;
            }
            if(newRecord.Sales_Order_Other_Charges__c!=null) {
                updateSR.Credit_Note_Sub_Type__c = Constants.PAYMENT_SUB_TYPE_OTHER_CHARGE_REVERSAL;
            }
        } else  if(newRecord.InvoiceReversal__c && newRecord.Credit_Note_Sub_Type__c == REBATE) {
            //throw new OtherException(ERROR_IR_CANNOT_BE_REBATE);
        } //If Invoice reversal of Rebate Type, then throw error
        
        updateSR = newRecord.InvoiceReversal__c ? updateIfCreditNote(updateSR) : updateSR;
        return updateSR;
    }
    
    //To update the Amount as same as Installment amount in the SR of Credit note only if valid, else throw error
    //SS_21062023
    public static HexaBPM__Service_Request__c updateIfCreditNote(HexaBPM__Service_Request__c newRecord) {
        HexaBPM__Service_Request__c sRRecord = [SELECT Id,Amount__c, AmountWithoutVAT__c, VATAmount__c, ServiceRequestComments__c, Sales_Order_Other_Charges__c, 
                                                InstallmentLine__c, InstallmentLine__r.InstallmentAmount__c,InstallmentLine__r.InvoicedAmount__c,
                                                InstallmentLine__r.Name,InstallmentLine__r.InvoiceId__c,
                                                PaymentType__c, Credit_Note_Sub_Type__c, Unit__c, SalesOrder__c, HexaBPM__Customer__c,
                                                Sales_Order_Other_Charges__r.ERPID__c,ChargeType__c,
                                                HexaBPM__External_SR_Status__r.Name,
                                                InvoiceReversal__c,
                                                SalesOrder__r.Opportunity__c,
                                                (SELECT Id, HexaBPM__Step_Status__c, OwnerId, HexaBPM__Summary__c FROM HexaBPM__Steps_SR__r),
                                                (SELECT Id FROM HexaBPM__SR_Docs__r)
                                                FROM HexaBPM__Service_Request__c
                                                WHERE Id=:newRecord.Id  Limit 1];
        
        if(sRRecord.InvoiceReversal__c) {
            Boolean isPaymentStartedIL = false;
            System.debug('sRRecord.InstallmentLine__r.InvoicedAmount__c -> '+sRRecord.InstallmentLine__r.InvoicedAmount__c);
            isPaymentStartedIL = sRRecord.InstallmentLine__r.InvoicedAmount__c!=0 && sRRecord.InstallmentLine__r.InvoicedAmount__c!=null && sRRecord.InstallmentLine__r.InstallmentAmount__c == sRRecord.InstallmentLine__r.InvoicedAmount__c;
            System.debug('InstallmentAmount__c -> '+sRRecord.InstallmentLine__r.InstallmentAmount__c+isPaymentStartedIL);
            System.debug('####### isPaymentStartedIL >> '+isPaymentStartedIL);
            
            if(isPaymentStartedIL) {
                throw new OtherException('Invalid Installment Line, Please unallocate to proceed with Invoice Reversal');
                //newRecord.addError('Please unallocate to proceed with Invoice Reversal');
            } else {
                newRecord.Amount__c = sRRecord.InstallmentLine__r.InstallmentAmount__c;
            }
        }
        return newRecord;
    }
}