@RestResource(urlMapping = '/updateMarketingReimbursement')
global class BrokerRequestWebService {

    @HTTPPost
    global static void doPost() {
        RestContextHandler handler = new RestContextHandler(true); 
        RestRequest req = RestContext.request;

        // Call the parse method
        BrokerRequestDetail brokerDetailsRequest = parseBrokerRequestJson(req.requestBody.toString());
        BrokerRequest__c brokerRequestToUpdate = new BrokerRequest__c();

        try {
            // Validate the provided BrokerRequestId
            if (brokerDetailsRequest.BrokerRequestId == null || String.isEmpty(brokerDetailsRequest.BrokerRequestId)) {
                throw new IllegalArgumentException('BrokerRequestId cannot be null.');
            }
            
            if (brokerDetailsRequest.invoiceStatus == null || String.isEmpty(brokerDetailsRequest.invoiceStatus)) {
                throw new IllegalArgumentException('invoiceStatus cannot be null.');
            }

            // Fetch the Broker Request record (only one record should be retrieved)
            List<BrokerRequest__c> brokerRequestRetrieved = [SELECT Id, InvoiceStatus__c FROM BrokerRequest__c WHERE Id = :brokerDetailsRequest.BrokerRequestId LIMIT 1];

            if (brokerRequestRetrieved == null || brokerRequestRetrieved.isEmpty()) {
                throw new IllegalArgumentException('No Broker Request found with this BrokerRequestId.');
            }

            // Map incoming parameters to the respective fields on Broker Request
            brokerRequestToUpdate.Id = brokerDetailsRequest.BrokerRequestId;
            brokerRequestToUpdate.InvoiceStatus__c = brokerDetailsRequest.invoiceStatus;
            brokerRequestToUpdate.ERPID__c = brokerDetailsRequest.ErpId;
           
            if(brokerDetailsRequest.invoiceStatus == 'Invoice Approval In Progress'){
                brokerRequestToUpdate.InvoiceResponse__c = brokerDetailsRequest.invResponse;
                brokerRequestToUpdate.InvoiceApproverName__c = brokerDetailsRequest.invApprName;
                brokerRequestToUpdate.InvoiceApproverComments__c = brokerDetailsRequest.invApprComments != null ? brokerDetailsRequest.invApprComments : '';
                if(brokerDetailsRequest.invApprDate != ''){
                    brokerRequestToUpdate.InvoiceApprovalDate__c = Date.valueOf(brokerDetailsRequest.invApprDate);
                }
            } else if(brokerDetailsRequest.invoiceStatus == 'Payment Approval In Progress'){
                brokerRequestToUpdate.PaymentResponse__c = brokerDetailsRequest.payResponse;
                brokerRequestToUpdate.PaymentApproverName__c = brokerDetailsRequest.payApprName;
                brokerRequestToUpdate.PaymentApproverComments__c = brokerDetailsRequest.payApprComments != null ? brokerDetailsRequest.payApprComments : '';
                if(brokerDetailsRequest.payApprDate != ''){
                    brokerRequestToUpdate.PaymentApprovaldate__c = Date.valueOf(brokerDetailsRequest.payApprDate);
                }
                
            } else if(brokerDetailsRequest.invoiceStatus =='Payment Under Bank Clearance'){
                brokerRequestToUpdate.BankResponse__c = brokerDetailsRequest.bankResponse;
                brokerRequestToUpdate.BankComments__c = brokerDetailsRequest.bankComments != null ? brokerDetailsRequest.bankComments : '';
                if(brokerDetailsRequest.bankApprDate != ''){
                    brokerRequestToUpdate.PaymentClearanceDate__c = Date.valueOf(brokerDetailsRequest.bankApprDate);
                }                
            }
            
            update brokerRequestToUpdate;

            // Return success response
            handler.response.success = true;
            handler.response.data = brokerRequestToUpdate;
            handler.finalize();            

        } catch (DMLException exc) {
            // Handling DML errors explicitly
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
            handler.finalize(exc);

        } catch (Exception ex) {
            // Handle generic errors
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);            
        }
    }

    public class BrokerRequestDetail {
        public String BrokerRequestId;
        public String invoiceStatus;
        public String ErpId;
        public String invApprDate;
        public String payApprDate;
        public String bankApprDate;
        public String invResponse;
        public String invApprName;
        public String invApprComments;
        public String payResponse;
        public String payApprName;
        public String payApprComments;
        public String bankResponse;
        public String bankComments;
    }
    
    // Method to parse the JSON string
    public static BrokerRequestDetail parseBrokerRequestJson(String jsonString) {
        BrokerRequestDetail br = (BrokerRequestDetail) JSON.deserialize(jsonString, BrokerRequestDetail.class);
        return br;
    }
}