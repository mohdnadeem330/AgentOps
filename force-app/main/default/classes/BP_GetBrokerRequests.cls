/**********************************************************************************
 * Name             : BP_GetBrokerRequests
 * Description      : API Call for Get all broker request based on type
 * Created Date     : 20/05/25
 * Created By       : Moh Sarfaraj
 * Test Class       : 
 * -------------------------------------------------------------------------------*
Version     |   Date(DD/MM/YYYY)    |   Last Modified By    | Comments
----------------------------------------------------------------------------------
1.0         |   20/05/25            |   Moh Sarfaraj        | Initial Draft
**********************************************************************************/
@RestResource(urlMapping = '/getBrokerRequests')   
global with sharing class BP_GetBrokerRequests extends BP_BaseRestResource {
    String MARKETING_REIMBURSEMENT = 'Marketing Reimbursement';

    @HttpPost
    global static void execute() {
        RestContextHandler handler = new RestContextHandler(false);

        try {
            String requestBody = RestContext.request.requestBody.toString();
            System.debug('Received Request Body: ' + requestBody);

            if (!String.isEmpty(requestBody)) {   
                BP_GetBrokerRequests service = new BP_GetBrokerRequests();
                Map<String, String> params = RestContext.request.params;
                ApiResponse response = service.processRequest(params, requestBody);

                handler.response.data = response.data;
                handler.response.success = response.success;
                handler.response.statusCode = response.statusCode;
                handler.response.message = response.message;
            } else {
                handler.response.success = false;
                handler.response.statusCode = 400;
                handler.response.message = 'Invalid Request Body';
            }
        } catch (Exception ex) {
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = 'Error: ' + ex.getMessage();
            System.debug('Error in execute: ' + ex.getMessage());
        } finally {
            handler.finalize();
        }
    }

    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        System.debug('Processing Request: ' + requestBody);

        if(String.isBlank(requestBody)){
            return new ApiResponse(true, 400, 'Broker Request body is not valid', null);
        }

        DeserializeWrapper requestData = (DeserializeWrapper) JSON.deserialize(requestBody, DeserializeWrapper.class);
        String type = requestData?.type?.trim();
        String quarter = requestData?.quarter?.trim();
        String year = requestData?.year?.trim();

        if(String.isBlank(type)){
            return new ApiResponse(true, 400, 'Broker Request type is not valid', null);
        }
       
        User userInfo = Utilities.getLoggedInUserDetail();
        Id accountId = userInfo.Contact.AccountId;
        //accountId  = '001FW000008w9D2YAI';
        System.debug('accountId'+accountId); 

        String status = 'Draft';
        
        if(String.isBlank(accountId)){
            return new ApiResponse(true, 400, 'User is not valid', null);
        }

        String query = 'SELECT Id, AgencyName__c, Name, Type__c, StartDate__c, EndDate__c, Location__c, '+
                 'InvoiceAmount__c, SodicInvoiceAmount__c, Comment__c, TaxAmount__c, InvoiceDate__c, Invoice__c,'+
                 'TotalAmount__c, InvoiceStatus__c, ApprovalStatus__c, Agency__c, RequestYear__c, RequestQuarter__c,'+
                 'AgencyName__r.Name, AgencyName__r.BankAccountNumber__c, AgencyName__r.IBANNumber__c, AgencyName__r.CurrencyISOCode,'+
                 'AgencyName__r.SwiftCode__c, AgencyName__r.BankName__c, AgencyName__r.BranchAddress__c, AgencyName__r.BankCountry__c, '+
                 'Description__c FROM BrokerRequest__c WHERE AgencyName__c =: accountId AND InvoiceStatus__c != :status AND Type__c = :type ';
                 
        if(String.isNotBlank(quarter)){
            query += ' AND RequestQuarter__c = :quarter ';
        }

        if(String.isNotBlank(year)){
            query += ' AND RequestYear__c = :year ';
        }

        query += ' ORDER BY CreatedDate DESC';

        System.debug('query--->'+query);

        List<BrokerRequest__c> listBrokerRequests = Database.query(query);
        ResponseWrapper responseWrap = new ResponseWrapper();
        responseWrap.totalCount = listBrokerRequests.size();

        if(responseWrap.totalCount == 0){
            return new ApiResponse(true, 200, 'No Broker Request related with this agency', null );
        }

        for(BrokerRequest__c br : listBrokerRequests) {
            BrokerWrapper wrap = new BrokerWrapper(); 
            wrap.Id = br.Id;
            wrap.Agency = br.Agency__c;
            wrap.BrokerRequestNumber = br.Name;
            wrap.StartDate = br.StartDate__c;
            wrap.EndDate = br.EndDate__c;
            wrap.InvoiceDate = br.InvoiceDate__c;
            wrap.Location = br.Location__c;
            wrap.Comments = br.Comment__c;
            wrap.Type = br.Type__c;
            wrap.ApprovalStatus = br.ApprovalStatus__c;
            wrap.Invoice = br.Invoice__c;
            wrap.InvoiceAmount = br.InvoiceAmount__c;
            wrap.SodicInvoiceAmount = br.SodicInvoiceAmount__c;
            wrap.TotalAmount = br.TotalAmount__c;
            wrap.TaxAmount = br.TaxAmount__c;
            wrap.invoiceStatus = br.InvoiceStatus__c;
            wrap.requestYear = br.RequestYear__c;
            wrap.requestedQuarter = br.RequestQuarter__c;
            wrap.description = br.Description__c;
            responseWrap.listBrokerRequests.add(wrap);
        }
        if(type?.equalsIgnoreCase(MARKETING_REIMBURSEMENT)){
            responseWrap.vatConsent = System.Label.BPM_VATConsent_Message;
            responseWrap.bankConsent = System.Label.BPM_BankAccount_Consent;
        }

        System.debug('finalwrapResponse '+responseWrap);
        return new ApiResponse(true, 200, 'Broker Request fetched successfully', responseWrap);
    }

    public class DeserializeWrapper {
        public String type;
        public String quarter;
        public String year;

        public DeserializeWrapper(){}
    }
    
    public class ResponseWrapper {
        public List<BrokerWrapper> listBrokerRequests;
        public Integer totalCount = 0;
        public String vatConsent; 
        public String bankConsent; 

        public ResponseWrapper(){
            listBrokerRequests = new List<BrokerWrapper>();
        }
    }

    public class BrokerWrapper{
        public String Attachment {get;set;}
        public Id  Id {get;set;} 
        public String ApprovalStatus {get;set;} 
        public String invoiceStatus {get;set;} 
        public String Agency {get;set;}
        public String Location {get;set;} 
        public Decimal InvoiceAmount {get;set;} 
        public Decimal SodicInvoiceAmount {get;set;}
        public Date InvoiceDate {get;set;}
        public Decimal TotalAmount {get;set;} 
        public Decimal TaxAmount {get;set;} 
        public String Comments {get;set;} 
        public String Type {get;set;} 
        public String BrokerRequestNumber {get;set;} 
        public Date StartDate {get;set;} 
        public Date EndDate {get;set;} 
        public String Invoice {get;set;} 
        public String requestYear {get;set;} 
        public String requestedQuarter {get;set;} 
        public String description {get;set;} 

        public BrokerWrapper(){
        }
    }
}