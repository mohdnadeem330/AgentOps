/**Author: Saravana Sekar
* Created on : 17-03-2023
* Objective - To Provide the Ability to the Finance Team to enter the Other Charges manually
* It will do integration call to ERP to create the same
//SS_CHANGES_OTHER_CHARGE
*/

public class ALDOC_OtherChargesHelper {
        
    public static Boolean BYPASS_TRIGGER = FALSE; //By-pass existing integration for the Other Charges
    public static Boolean IsTesting_FOR_ADMIN = FALSE; //ADMIN TEST TO MOCK
    public static List<SalesOrderOtherCharges__c> soOtherChargeList = new List<SalesOrderOtherCharges__c>();
    
    //Entry point method - checks context and routes accordingly
    //Changes made by Sai Kumar as part of FIN-11 to handle future/batch contexts
    public static void doOtherChargeCallout(List<Id> recordIds, Map<String, String> cdLinkEntityId) {
        if(System.isFuture() || System.isBatch()) {
            //If already in future/batch context, call implementation directly
            doOtherChargeCalloutImpl(recordIds, cdLinkEntityId);
        } else {
            //If in regular context, make future call
            doOtherChargeCalloutFuture(recordIds, cdLinkEntityId);
        }
    }
    
    //Changes made by Sai Kumar as part of FIN-11 to handle future/batch contexts
    @Future(callout=true) 
    public static void doOtherChargeCalloutFuture(List<Id> recordIds, Map<String, String> cdLinkEntityId) {
        doOtherChargeCalloutImpl(recordIds, cdLinkEntityId);
    }
    
    //Changes made by Sai Kumar as part of FIN-11 to handle future/batch contexts
    //Main implementation method containing the actual logic
    public static void doOtherChargeCalloutImpl(List<Id> recordIds, Map<String, String> cdLinkEntityId) {
        //This Method will being invoked from aldCreateOtherCharges LWC in Realtime From SalesOrderOtherCharges__c on Insert
        //recordId     -> SalesOrderOtherCharges__c Id
        //muleConfigs   ->  Metadata to get the necessary information
        
        System.debug('doOtherChargeCallout -> invoked');
        Boolean IsTesting = IsTesting_FOR_ADMIN; //For Admin Test
        List<SalesOrderOtherCharges__c> soOtherChargeListToUpdate = new List<SalesOrderOtherCharges__c>();
        List<Logger__c> loggerList = new List<Logger__c>();
        List<SObject> updateSObjectList = new List<SObject>(); //If record failed, then updating this list
        String requestBody = '';
        MuleSOResponeWrapper responseBody = new MuleSOResponeWrapper();
        
        try {
            
            MuleSoftSetting__mdt muleConfigs = MuleSoftSetting__mdt.getInstance(ALD_Constants.ALD_OTHER_CHARGES_MULE_NAME); //DML_ACTION
            Organization org = Utilities.getOrganizationDetails(); //DML_ACTION
            if(Test.isRunningTest()) {
                soOtherChargeList = [SELECT Id, Name, Account__c, AmountReceived__c, Amount__c, AmountWithoutVAT__c, ERPID__c, OutstandingAmount__c, OutstandingAmountinwords__c, 
                                     OutstandingAmountNumber__c, PendingAmount__c, SalesOrder__c, TypeOfCharge__c, SubType__c, VATAmount__c, SalesOrder__r.UnitNumber__c,
                                     Beneficiary_Name__c, Bank_Name__c, Bank_Account_Number__c, Bank_Account_Name__c,Description__c,IBAN_Number__c,Branch_Name__c,
                                     Operating_Unit__c,Payment_Method__c,PO_Box__c, CreatedBy.Email
                                     FROM SalesOrderOtherCharges__c 
                                     WHERE Id IN :recordIds AND ERPID__c=null]; //DML_ACTION
            } else {
                soOtherChargeList = [SELECT Id, Name, Account__c, AmountReceived__c, Amount__c, AmountWithoutVAT__c, ERPID__c, OutstandingAmount__c, OutstandingAmountinwords__c, 
                                     OutstandingAmountNumber__c, PendingAmount__c, SalesOrder__c, TypeOfCharge__c, SubType__c, VATAmount__c, SalesOrder__r.UnitNumber__c,
                                     Beneficiary_Name__c, Bank_Name__c, Bank_Account_Number__c, Bank_Account_Name__c,Description__c,IBAN_Number__c,Branch_Name__c,
                                     Operating_Unit__c,Payment_Method__c,PO_Box__c, CreatedBy.Email
                                     FROM SalesOrderOtherCharges__c 
                                     WHERE Id IN :recordIds and SyncStatus__c =: ALD_Constants.STATUS_INPROGRESS AND ERPID__c=null]; //DML_ACTION
            }
            
            // changes made by Sai Kumar as part of FIN-48
            // Get approval history for all records to find approver emails
            Map<Id, String> approverEmailMap = new Map<Id, String>();
            for(ProcessInstance pi : [SELECT Id, TargetObjectId, 
                                     (SELECT Id, ActorId, Actor.Email, StepStatus 
                                      FROM StepsAndWorkitems 
                                      WHERE StepStatus = 'Approved' 
                                      ORDER BY CreatedDate DESC LIMIT 1)
                                     FROM ProcessInstance 
                                     WHERE TargetObjectId IN :recordIds]) {
                if(!pi.StepsAndWorkitems.isEmpty()) {
                    approverEmailMap.put(pi.TargetObjectId, pi.StepsAndWorkitems[0].Actor.Email);
                }
            }
            
            for(SalesOrderOtherCharges__c soOtherCharge : soOtherChargeList) {
                //We didnt do bulkify in sending response by considering the previous challenges in getting response time. 
                //With this approach, response will be captured immediately and each records. Failiure response will not affect other records.
                Map<String, Object> salesOrderOtherCharges = new Map<String, Object>();
                List<Object> OtherChargesList = new List<Object>();
                Map<String, Object> OtherChargesMap = new Map<String, Object>();
                OtherChargesMap.put('SR_SFID', 'STANDALONE');
                OtherChargesMap.put('SFId', soOtherCharge.Id);
                OtherChargesMap.put('OC_Name', soOtherCharge.Name);
                OtherChargesMap.put('CurrencyCode', 'AED');
                OtherChargesMap.put('Sf_SalesOrderId', soOtherCharge.SalesOrder__c);
                OtherChargesMap.put('AccountId', soOtherCharge.Account__c);
                OtherChargesMap.put('AmountReceived', String.valueOf(soOtherCharge.AmountReceived__c));
                OtherChargesMap.put('Amount', String.valueOf(soOtherCharge.Amount__c));
                OtherChargesMap.put('Opportunity', '');
                OtherChargesMap.put('OutAmountWords', soOtherCharge.OutstandingAmountinwords__c);
                OtherChargesMap.put('TypeOfCharge', soOtherCharge.TypeOfCharge__c);
                OtherChargesMap.put('InstallmentLine', '');
                OtherChargesMap.put('AmountWithoutVAT', String.valueOf(soOtherCharge.AmountWithoutVAT__c));
                OtherChargesMap.put('VATAmount', String.valueOf(soOtherCharge.VATAmount__c));
                OtherChargesMap.put('SubType', String.valueOf(soOtherCharge.SubType__c));
                OtherChargesMap.put('Description', soOtherCharge.Description__c);
                OtherChargesMap.put('DocumentURls', cdLinkEntityId != null && cdLinkEntityId.containsKey(soOtherCharge.Id) && cdLinkEntityId.get(soOtherCharge.Id) <> null ? cdLinkEntityId.get(soOtherCharge.Id):'');
                
                /*Refund Section - START*/
                OtherChargesMap.put('BeneficiaryName', String.valueOf(soOtherCharge.Beneficiary_Name__c));
                OtherChargesMap.put('BankName', String.valueOf(soOtherCharge.Bank_Name__c));
                OtherChargesMap.put('BankAccountName', String.valueOf(soOtherCharge.Bank_Account_Name__c));
                OtherChargesMap.put('BankAccountNum', String.valueOf(soOtherCharge.Bank_Account_Number__c));
                OtherChargesMap.put('IBAN', String.valueOf(soOtherCharge.IBAN_Number__c));
                OtherChargesMap.put('BranchName', String.valueOf(soOtherCharge.Branch_Name__c));
                OtherChargesMap.put('OperatingUnit', String.valueOf(soOtherCharge.Operating_Unit__c));
                OtherChargesMap.put('PaymentMethod', String.valueOf(soOtherCharge.Payment_Method__c));
                OtherChargesMap.put('UnitDetails', String.valueOf(soOtherCharge.SalesOrder__r.UnitNumber__c));
                OtherChargesMap.put('POBox', String.valueOf(soOtherCharge.PO_Box__c));
                /*Refund Section - END*/
                
                /* changes made by Sai Kumar as part of FIN-48 - Add Maker and Checker information */
                OtherChargesMap.put('Maker', String.valueOf(soOtherCharge.CreatedBy.Email));
                OtherChargesMap.put('Checker', (approverEmailMap != null && approverEmailMap.containsKey(soOtherCharge.Id)) ? approverEmailMap.get(soOtherCharge.Id) : '');
                
                OtherChargesList.add(OtherChargesMap);
                salesOrderOtherCharges.put('OtherCharges', OtherChargesList);
                
                //Do Callout
                requestBody = JSON.serialize(salesOrderOtherCharges);
                
                String EndPointURL = muleConfigs.SandboxURL__c;
                if(!org.IsSandbox){
                    EndPointURL = muleConfigs.ProductionURL__c;
                }
                
                requestBody = requestBody.replaceAll(':null', ':""');
                System.debug('*** EndPointURL -> '+EndPointURL);
                System.debug('*** requestBody -> '+requestBody);
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
                    System.debug('** response.getBody() -> '+response.getBody());
                    
                    responseBody = parse(response.getBody());
                    
                    if(responseBody.statusCode != Constants.MULESOFT_SUCCESS_STATUS){
                        loggerList.add(LoggerService.addApexServiceCalls(ALD_Constants.ALD_OTHER_CHARGES_MULE_NAME,'ALDOC_OtherChargesHelper', 'doOtherChargeCallout_ERROR',  requestBody, response.getBody()+' ** '+response.getStatusCode(), soOtherCharge.Id));
                        updateSObjectList.add(updateAsFailed(new List<Id>{soOtherCharge.Id}, null, 'Status Code: '+responseBody.statusCode+'.', false));
                    } else {
                        SalesOrderOtherCharges__c soCharge = updateSoOtherCharges(responseBody, true);
                        System.debug('soOtherCharge -> '+soCharge);
                        if(soCharge!=null) {
                            soOtherChargeListToUpdate.add(soCharge);
                        }
                        loggerList.add(LoggerService.addApexServiceCalls(ALD_Constants.ALD_OTHER_CHARGES_MULE_NAME,'ALDOC_OtherChargesHelper', 'doOtherChargeCallout_SUCCESS',  requestBody, response.getBody(), soOtherCharge.Id));
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
            if(soOtherChargeListToUpdate.size()>0) {
                System.debug('soOtherCharges size -> '+soOtherChargeListToUpdate.size());
                update soOtherChargeListToUpdate;
            }
        } catch(Exception ex) {
            Logger__c lgs = LoggerService.saveAndReturnLogger(LoggerService.addApexServiceCallsLog(ex, 'ALDOC_OtherChargesHelper', 'doOtherChargeCallout_EXCEPTION', ALD_Constants.ALD_OTHER_CHARGES_MULE_NAME, requestBody, String.valueOf(responseBody)));
            updateAsFailed(recordIds, null, lgs.Id+' ** '+ex.getMessage()+' ** '+ex.getLineNumber()+' ** '+ex.getLineNumber(), true);
            System.debug('EXCEPTION ** '+lgs.Id+' ** '+ex.getMessage()+' ** '+ex.getLineNumber()+' ** '+ex.getLineNumber());
        }
    }    
    public static SObject updateAsFailed(List<Id> recordIds, String loggerId, String exceptionMessage, Boolean shallDoDML) {
        String objectType = '';
        if (!recordIds.isEmpty()) {
            
            if (recordIds[0].getSObjectType() == SalesOrderOtherCharges__c.SObjectType) {
                objectType = 'SalesOrderOtherCharges__c';
            } else if (recordIds[0].getSObjectType() == ReceiptAcknowledgement__c.SObjectType) {
                objectType = 'ReceiptAcknowledgement__c';
            } else if (recordIds[0].getSObjectType() == HexaBPM__Service_Request__c.SObjectType) {
                objectType = 'HexaBPM__Service_Request__c';
            }
            Boolean includeLoggerField = true;
            if(objectType == 'HexaBPM__Service_Request__c') {
                includeLoggerField = false;
            }
            
            if (objectType != '') {
                List<SObject> updateSObjectList = new List<SObject>();
                for (Id rId: recordIds) {
                    SObject updateSObject = Schema.getGlobalDescribe().get(objectType).newSObject();
                    updateSObject.put('Id', rId);
                    updateSObject.put('SyncStatus__c', Constants.STATUS_FAILED);
                    if(includeLoggerField) {
                        updateSObject.put('Logger_Id__c', loggerId);
                    }
                    updateSObject.put('ErrorReason__c', loggerId!=null ? loggerId : exceptionMessage);
                    updateSObjectList.add(updateSObject);
                }
                if (!updateSObjectList.isEmpty() && shallDoDML) {
                    update updateSObjectList; //If DML true, then add it in list and update
                } else if(!updateSObjectList.isEmpty() && !shallDoDML) {
                    return updateSObjectList[0]; //If NO DML, then its always single record
                }
            }
        }
        return null; //No use with this return
    }
    
    private static SalesOrderOtherCharges__c updateSoOtherCharges(MuleSOResponeWrapper response, Boolean shallProcessResp) 
    {
        MuleSOResponeWrapper.MuleResponse results = response.results; 
        List<SalesOrderOtherCharges__c> soOtherCharges = new List<SalesOrderOtherCharges__c>();
        if(shallProcessResp && response.statusCode == ALD_Constants.ALD_OTHER_CHARGES_SUCCESS_CODE && response.success) {
            for(MuleSOResponeWrapper.SOResponse oc : results.othChgRes) {
                SalesOrderOtherCharges__c soOtherCharge = new SalesOrderOtherCharges__c();
                soOtherCharge.Id = oc.sfId;
                if(oc.status == ALD_Constants.ALD_OTHER_CHARGES_STATUS_FAILURE) {
                    System.debug('oc.status -> '+oc.status);
                    soOtherCharge.ErrorReason__c = oc.errorMsg;
                    soOtherCharge.SyncStatus__c = ALD_Constants.STATUS_FAILED;
                } else if(oc.errorMsg != null && oc.errorMsg!= '' && oc.status == 'E') {
                    System.debug('oc.errorMsg -> '+oc.errorMsg);
                    soOtherCharge.ErrorReason__c = oc.errorMsg;
                    soOtherCharge.SyncStatus__c = ALD_Constants.STATUS_FAILED;
                } else {
                    System.debug('oc.erpId -> '+oc.erpId);
                    soOtherCharge.ERPID__c = oc.erpId;
                    soOtherCharge.InvoiceId__c = oc.erpId;
                    soOtherCharge.ReceivableAccount__c = oc.recAcct;
                    soOtherCharge.RevenueAccount__c = oc.expAcct;
                    soOtherCharge.TaxAccount__c = oc.taxAcct;
                    soOtherCharge.InvoiceNumber__c = oc.invoiceNo;
                    soOtherCharge.SyncStatus__c = ALD_Constants.STATUS_SYNCED;
                    soOtherCharge.ErrorReason__c = '';
                }
                return soOtherCharge;
            }
            
            /*if(soOtherCharges.size()>0) {
                System.debug('soOtherCharges size -> '+soOtherCharges.size());
                update soOtherCharges;
            }*/
        }
        return null;
    }
    
    
    @AuraEnabled
    public static string insertSalesOrderOtherCharge(SalesOrderOtherCharges__c ocCharge) {
        //BYPASS_TRIGGER = TRUE;
        //Organization org = Utilities.getOrganizationDetails();//DML_ACTION
        //MuleSoftSetting__mdt muleConfigs = MuleSoftSetting__mdt.getInstance(ALD_Constants.ALD_OTHER_CHARGES_MULE_NAME); //DML_ACTION
        try{
            insert ocCharge;//DML_ACTION
        } catch(Exception ex) {
            System.debug('$$$ Exception --> '+ex.getMessage()+ex.getLineNumber()+ex.getStackTraceString());
        }
        return ocCharge.Id;
        //List<SalesOrderOtherCharges__c> soOtherChargeList = new List<SalesOrderOtherCharges__c>();
        //soOtherChargeList.add(ocCharge);
    }
    
    public static void executeUponApproval(List<Id> recordIds) {
        System.debug('executeUponApproval -> invoked');
        //From SalesOrderOtherChargesHandler.beforeUpdateMethod
        Boolean isPBUrlExecuted = false;
        //TO GET THE PUBLIC URLs
        Map<String, String> cdLinkEntityId = new Map<String, String>();
        
        for(Id recordId : recordIds) {
            cdLinkEntityId.put(recordId, generatePublicURL(recordId));
            isPBUrlExecuted = true;
        }
        if(isPBUrlExecuted) {
            doOtherChargeCallout(recordIds, cdLinkEntityId); //It is Other Charges Callout. 
        }
        
    }
    public static String generatePublicURL(Id recordId) {
        List<ContentDocumentLink> cdlList = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:recordId];
        String url_doc = '';
        if(cdlList.size()>0) {
            List<ContentDistribution> cdb = [SELECT Id, DistributionPublicUrl FROM ContentDistribution WHERE RelatedRecordId=:recordId];
            for(ContentDistribution cd: cdb) {
                url_doc = cd.DistributionPublicUrl+';'+url_doc;
            }
            System.debug('### url_doc > '+url_doc);
        }
        
        return url_doc;
    }
    
    @AuraEnabled
    public static SalesOrder__c fetchSalesOrder(Id recordId) {
        return [SELECT Id, Account__c FROM SalesOrder__c WHERE Id=:recordId Limit 1];
    }
    
    
    @AuraEnabled
    public static String checkIsFinanceHeadGroup() {
        String isValidUser = Label.ALDOC_InvalidUser;
        String userNames = Label.ALDOC_FinanceGroup_Owners;
        List<String> userNamesList = userNames.split(';');
        String CurrUserName = UserInfo.getUserName();
        for(String uname : userNamesList) {
            if(CurrUserName == uname) {
                isValidUser = Constants.SUCCESS_MESSAGE;
                break;
            }
        }
        
        return isValidUser;
    }
    
    @AuraEnabled
    public static FieldSetSection fetchOCFields(Id recordId, String objectName, String fieldSetName) {
        FieldSetSection form = new FieldSetSection();       
        form.fieldsList = getFSetFields(recordId, objectName, fieldSetName);
        
        return form;
    }
    
    private static List<ALD_FSetFormFields> getFSetFields(Id recordId, String objectName, String fieldSetName) {
        Schema.SObjectType objectType = null;
        if (recordId != null) {
            objectType = recordId.getSobjectType();
        }
        else if (String.isNotBlank(objectName)) {
            objectType = Schema.getGlobalDescribe().get(objectName); //Read the Object
        }
        
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe(); //Get All
        Map<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap(); // Read the Fieldsets
        Schema.FieldSet fieldSet = fieldSetMap.get(fieldSetName); //Get by FSet Name
        List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields(); //Get All Members of FSet
        
        List<ALD_FSetFormFields> fields = new List<ALD_FSetFormFields>();
        for (Schema.FieldSetMember fsm : fieldSetMembers) {
            ALD_FSetFormFields f = new ALD_FSetFormFields(fsm);
            f.IsDisabled = f.APIName == 'Account__c' || f.APIName == 'SalesOrder__c' || f.APIName == 'Amount__c' || f.APIName == 'VATAmount__c'; //Add fields in OR Condition to make it as disabled
            fields.add(f);
        }
        
        return fields;
    }
    
    
    public static MuleSOResponeWrapper parse(String json){
        return (MuleSOResponeWrapper)System.JSON.deserialize(json, MuleSOResponeWrapper.class);
    }
    
    public class FieldSetSection {
        @AuraEnabled
        public List<ALD_FSetFormFields> fieldsList {get;set;}
        
        public FieldSetSection() {
            fieldsList = new List<ALD_FSetFormFields>(); 
        }
    }
}