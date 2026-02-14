/***
Class       : Dm_ERPIntegrationCtrl
Author      : Smaartt
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date       Author                Details
1.        V1.0              12/02/2025  Smaartt             Initial Version 
2.        v1.1              15/09/2025  Harsh@Aldar         Added ERP Invoice Number and future method for callout from trigger
****************************************************************************************************************/

public class Dm_ERPIntegrationCtrl {

    /**
* To call ERP in future - Called from PaymentRequestTriggerHandler
* Created By harsh@aldar 15/09/2025
*/
    @future(callout = true)
    public static void pushToERPAsync(String paymentReqId){

        //Added Bypass logic be pooja@aldar
        String bypass = Label.DM_ERPBypass;

        if (bypass != null && bypass.trim().toLowerCase() == 'true') {
            return;
        }
        Payment_Request__c pr = [SELECT Id,Case__c FROM Payment_Request__c WHERE Id=: paymentReqId LIMIT 1];
        system.debug('payment case=='+pr.Case__c);
        system.debug('payment request=='+pr.Id);
        createPayments(pr.id,pr.Case__c);
    }
    
    @auraEnabled
    public static string createPayments(string prId, string caseId){
        list<Account> accList = new List<Account>();
        list<Payment_Request__c> payments = new list<Payment_Request__c>();
        List<Logger__c> logslist = new List<Logger__c>();
		list<Payment_Request__c> prList= [SELECT Id,Name,Amount_without_VAT__c,VAT_Amount__c,Instalment_No__c,Case__r.Type,Amount_Exclusive_VAT__c,VAT__c,Instalment_Percentage__c,Instalment_Date__c,Payment_Type__c,CurrencyIsoCode,Status__c,Bank_Name__c,Payment_Reference_No__c,Case__r.Commencement_Date__c, Case__r.Expiry_Date__c, Transaction_No__c,Cheque_Date__c from Payment_Request__c Where ERP_Receipt_Id__c=null and ID=:prId];
        list<case> caseList = [Select Id,accountId,account.ERPID__c,Type from Case where Id=:caseId];
        system.debug('CaseList=='+caseList);
        if(caseList.size()>0){
            Case ca = caseList[0];
          //  list<Payment_Request__c> prList = ca.Payment_Requests__r;
            if(!prList.isEmpty()){
                if(ca.account.ERPID__c==null ){
                    Account acc = createERPAccount(ca.accountId,logslist);
                    accList.add(acc);
                }
                Decimal toalAmtExcVat=0;
                Decimal toatlVat =0;
                Payment_Request__c pReq = prList[0];
                if(pReq.Case__r.Type =='Temporary License Agreement'){ //using diff fields to calculate CDC will have full amount VAT
                    toalAmtExcVat += pReq.Amount_without_VAT__c;
                    toatlVat += pReq.VAT_Amount__c;
                }else{
                    toalAmtExcVat += pReq.Amount_Exclusive_VAT__c;
                    toatlVat += pReq.VAT__c;
                }
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeStringField('accountId', ca.accountId);
                gen.writeStringField('caseId', ca.Id);
                gen.writeStringField('reqType', ca.Type);
                gen.writeStringField('totalamountExclVat', string.valueOf(toalAmtExcVat));
                gen.writeStringField('totalVatAmount', string.valueOf(toatlVat));
                gen.writeFieldName('paymentRequests');
                gen.writeStartArray(); 
                gen.writeStartObject();
                gen.writeStringField('id', pReq.Id);
                //Harsh@aldar changes start
                //for online use txn No
                if(pReq.Payment_Type__c == 'Online'){
                    gen.writeStringField('refNo', pReq.Transaction_No__c); 
                }else{
                    //for wire transer / cdc / pdc use payment ref no
                    gen.writeStringField('refNo', pReq.Payment_Reference_No__c); 
                }
                gen.writeStringField('sfRefId', pReq.Name);
                gen.writeStringField('instalmentNo', pReq.Instalment_No__c!=null?string.valueOf(pReq.Instalment_No__c):''); 
                if(pReq.Case__r.Type =='Temporary License Agreement'){
                    gen.writeStringField('amountExclVat', pReq.Amount_without_VAT__c!=null?string.valueOf(pReq.Amount_without_VAT__c):''); 
                    gen.writeStringField('vatAmount', pReq.VAT_Amount__c!=null?string.valueOf(pReq.VAT_Amount__c):''); 
                      // Add TLA start/end date //added by neelesh
                    gen.writeStringField('tlaStartDate', pReq.Case__r.Commencement_Date__c != null ? String.valueOf(pReq.Case__r.Commencement_Date__c) : '');
                    gen.writeStringField('tlaEndDate', pReq.Case__r.Expiry_Date__c != null ? String.valueOf(pReq.Case__r.Expiry_Date__c) : '');
                }else{
                    gen.writeStringField('amountExclVat', pReq.Amount_Exclusive_VAT__c!=null?string.valueOf(pReq.Amount_Exclusive_VAT__c):''); 
                    gen.writeStringField('vatAmount', pReq.VAT__c!=null?string.valueOf(pReq.VAT__c):''); 
                }
                
                gen.writeStringField('instalmentPercentage', pReq.Instalment_Percentage__c!=null?string.valueOf(pReq.Instalment_Percentage__c):'');
                gen.writeStringField('instalmentDate', pReq.Instalment_Date__c!=null?string.valueOf(pReq.Instalment_Date__c):'');
                gen.writeStringField('paymentType', pReq.Payment_Type__c);
                gen.writeStringField('currencyCode', pReq.CurrencyIsoCode);
                gen.writeStringField('Status', pReq.Status__c!=null?pReq.Status__c:'');
                gen.writeStringField('bankName', pReq.Bank_Name__c!=null?pReq.Bank_Name__c:'');
                gen.writeStringField('chequeOrWireTransferNo', pReq.Payment_Reference_No__c!=null?pReq.Payment_Reference_No__c:'');
                gen.writeStringField('chequeOrpaymentDate', pReq.Cheque_Date__c!=null? string.valueOf(pReq.Cheque_Date__c):'');
                gen.writeEndObject();          
                gen.writeEndArray();
                gen.writeEndObject();
                //system.debug('---Payment--Re--'+gen.getAsString());
                HttpResponse res  = makeCallout('DM_ERP',gen.getAsString(),'payment');
                system.debug('ReporterId Response=='+res.getBody());
                //List<Logger__c> logslist = new List<Logger__c>();
                Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());   
                
                if (res.getStatusCode() == 200) { 
                    if(accList.size()>0){
                        Update accList;
                    }               
                    list<object> muleRes = (list<object>)(result.get('results')); 
                    if(muleRes.size()>0){
                        
                        for(object obj : muleRes){
                            Map<String, Object> data = (Map<String, Object>)(obj);
                            system.debug(String.ValueOf(data.get('status')));
                            if(String.ValueOf(data.get('status')) =='S'){
                                Payment_Request__c pr = new Payment_Request__c();
                                pr.Id = String.ValueOf(data.get('paymentid'));
                                pr.ERP_Id__c = String.ValueOf(data.get('erpId'));
                                pr.ERP_Receipt_Id__c =String.ValueOf(data.get('receiptErpId'));
                                //added by Harsh@Aldar 15/09/2025 - Add ERP Invoice Number on Payment Request to display on the generated invoice
                                pr.ERP_Invoice_Number__c = String.ValueOf(data.get('erpInvNumber'));
                                payments.add(pr);
                            }else{
                                Logger__c log = LoggerService.addApexServiceCalls('DM ERP Integration', 'Dm_ERPIntegrationCtrl', 'createERPAccount', null, res.getBody(), null);           
                                logslist.add(log);
                                
                            }
                        }
                    }else{
                        return res.getBody();
                    }
                    
                    
                }else {            
                    Logger__c log = LoggerService.addApexServiceCalls('DM ERP Integration', 'Dm_ERPIntegrationCtrl', 'createPayments', null, res.getBody(), null);           
                    logslist.add(log);               
                    
                } 
                
                if(logslist.size()>0){
                    Insert logslist;
                }
               if (payments.size() > 0) {
                    update payments;
                    
                    // Collect all payment record Ids after update //added by sadhana fr testing
                    List<Id> paymentIds = new List<Id>();
                    for (Payment_Request__c pay : payments) {
                        if (pay.Id != null) {
                            paymentIds.add(pay.Id);
                }
                    }
                    
                    /*if (!paymentIds.isEmpty()) {
                        DmCaseInvoiceDoc.generatePDF(paymentIds);
                        DM_SendPaymentInvoice.sendInvoicepdfHelper(paymentIds[0], 'xyz');
                    }*/
                    //System.enqueueJob(new GenerateInvoicePDFQueueable(paymentIds));
                }
//end              
/*
                if (payments.size() > 0) {
                    update payments;

                    for (Payment_Request__c pr : payments) {
                        if (pr.ERP_Invoice_Number__c != null) {
                            DM_ERP__e evt = new DM_ERP__e(
                                Payment_Request_Id__c = pr.Id,
                                ERP_Invoice_Number__c = pr.ERP_Invoice_Number__c
                            );
                            EventBus.publish(evt);
                        }
                    }
                }


*/
                return res.getBody();
            }else{
                return 'no payment records';
            }
            
        }
        return null;
    }
    
    public static account createERPAccount(string accId,List<Logger__c> logsList){
        
        list<Account> acclist = [Select Id,Role__c,Name,Email__c,MobileCountryCode__c,MobileNumber1__c,BillingStreet,BillingCity,BillingPostalCode,BillingState,BillingCountry,P_O_Box__c,Fax,PlaceOfRegistration__c,RegistrationExpiryDate__c,RegistrationNumber__c,UAEVATRegisterNumber__c from Account where Id=:accId AND ERPID__c = null];
        if(acclist.size()>0){
            Account acc = acclist[0];
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('accountId', acc.Id);
            gen.writeStringField('role', acc.Role__c!= null?acc.Role__c:'');
            gen.writeStringField('companyName', acc.Name);
            gen.writeStringField('email', acc.Email__c!= null?acc.Email__c:'');
            gen.writeStringField('mobileCountryCode', acc.MobileCountryCode__c!= null?acc.MobileCountryCode__c:'');
            gen.writeStringField('mobileNumber', acc.MobileNumber1__c!= null?acc.MobileNumber1__c:'');
            gen.writeStringField('billingStreet', acc.BillingStreet!= null?acc.BillingStreet:'');
            gen.writeStringField('billingCity', acc.BillingCity!= null?acc.BillingCity:'');
            gen.writeStringField('billingPostalCode', acc.BillingPostalCode!= null?acc.BillingPostalCode:'');
            gen.writeStringField('billingState', acc.BillingState!= null?acc.BillingState:'');
            gen.writeStringField('billingCountry', acc.BillingCountry!= null?acc.BillingCountry:'');
            gen.writeStringField('poBox', acc.P_O_Box__c!= null?acc.P_O_Box__c:'');
            gen.writeStringField('fax', acc.Fax!= null?acc.Fax:'');
            gen.writeStringField('taxRegistrationNumber', acc.UAEVATRegisterNumber__c!= null?acc.UAEVATRegisterNumber__c:'');
            gen.writeStringField('tradeLicenseNumber', acc.RegistrationNumber__c!= null?acc.RegistrationNumber__c:'');
            gen.writeStringField('tradeLicenseExpDate', acc.RegistrationExpiryDate__c!= null?string.valueOf(acc.RegistrationExpiryDate__c):'');
            gen.writeStringField('placeOfIssueofTradeLicense', acc.PlaceOfRegistration__c!= null?acc.PlaceOfRegistration__c:'');        
            gen.writeEndObject();
            
            HttpResponse res  = makeCallout('DM_ERP',gen.getAsString(),'customer');
            system.debug('ReporterId Response=='+res.getBody());
            Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());       
            if (res.getStatusCode() == 200) { 
                list<object> muleRes = (list<object>)(result.get('results'));
                if(muleRes.size()>0 ){
                    Map<String, Object> data = (Map<String, Object>)(muleRes[0]);
                    if(String.ValueOf(data.get('status')) =='S'){
                        acc.ERPID__c =String.ValueOf(data.get('erpId'));
                        return acc;
                    }else{
                        Logger__c log = LoggerService.addApexServiceCalls('DM ERP Integration', 'Dm_ERPIntegrationCtrl', 'createERPAccount', null, res.getBody(), null);           
                        //insert log;
                        logsList.add(log);
                    }
                    system.debug(String.ValueOf(data.get('status')));  
                    system.debug(String.ValueOf(data.get('erpId')));
                    system.debug(String.ValueOf(data.get('errorMsg')));
                }
                
            }else {            
                Logger__c log = LoggerService.addApexServiceCalls('DM ERP Integration', 'Dm_ERPIntegrationCtrl', 'createERPAccount', null, res.getBody(), null);           
                //insert log;               
				logsList.add(log);                
            }  
        }
        return null;
    }
    
    public static HttpResponse makeCallout(String processName,String requestBody,string urlParam){
        //---- Fetch mulesoft URLs
        MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(processName);
        Organization org = Utilities.getOrganizationDetails();        
        String endPointURL = mulesoftAPI.SandboxURL__c ;        
        if(!org.IsSandbox){
            endPointURL = mulesoftAPI.ProductionURL__c ; 
        }
        Http http = new Http();
        HttpRequest request = new HttpRequest();        
        request.setHeader('client_secret',mulesoftAPI.APIKey__c);
        request.setHeader('client_id',mulesoftAPI.APIId__c);
        request.setTimeout(120000);
        request.setEndpoint(endPointURL+urlParam);
        request.setMethod(mulesoftAPI.Method__c);
        System.debug('**Request Body**'+requestBody);
        if(mulesoftAPI.Method__c !='GET'){
            request.setHeader('Content-Type','application/json');
            request.setBody(requestBody);
        }
        return http.send(request);
    }
    
}