@RestResource(urlMapping = '/update/InvoiceBundle')
global class InvoiceBundleWebService {

    @HTTPPost
    global static void doPost() {
        
        RestContextHandler handler = new RestContextHandler(true); 
        RestRequest req = RestContext.request;
        
        // Call the parse method
        InvoiceDetails inv = parseInvoiceJson(req.requestBody.toString());
        
        InvoiceBundle__c invoiceBundle = new InvoiceBundle__c();

        try {
            // Validate the provided InvoiceBundleId
            if (inv.InvoiceBundleId == null) {
                throw new IllegalArgumentException('InvoiceBundleId cannot be null.');
            }

            // Fetch the InvoiceBundle record (only one record should be retrieved)
            invoiceBundle = [SELECT Id, Status__c, ERPID__c, RejectionReasonPicklist__c, InvoiceResponse__c, InvoiceApproverName__c, 
                             InvoiceApproverComments__c, InvoiceApprovedDate__c, PaymentResponse__c, PaymentApproverName__c, 
                             PaymentApproverComments__c, PaymentApprovedDate__c, BankResponse__c, BankComments__c, BankApprovedDate__c 
                             FROM InvoiceBundle__c WHERE Id = :inv.InvoiceBundleId LIMIT 1];

            // Map incoming parameters to the respective fields on InvoiceBundle
            invoiceBundle.Status__c = inv.Status;
            invoiceBundle.ERPID__c = inv.ErpId;
            if (inv.cancelReason != null) {
                invoiceBundle.RejectionReasonPicklist__c = inv.cancelReason;
            }

            if(inv.Status == 'Invoice Approval In Progress'){
                invoiceBundle.InvoiceResponse__c = inv.invResponse;
                invoiceBundle.InvoiceApproverName__c = inv.invApprName;
                invoiceBundle.InvoiceApproverComments__c = inv.invApprComments != null ? inv.invApprComments : '';
                if (inv.invApprDate != '') {
                    invoiceBundle.InvoiceApprovedDate__c = Date.valueOf(inv.invApprDate);
                }
            }else if(inv.Status == 'Payment Approval In Progress'){
                invoiceBundle.PaymentResponse__c = inv.payResponse;
                invoiceBundle.PaymentApproverName__c = inv.payApprName;
                invoiceBundle.PaymentApproverComments__c = inv.payApprComments != null ? inv.payApprComments : '';
                if (inv.payApprDate != '') {
                    invoiceBundle.PaymentApprovedDate__c = Date.valueOf(inv.payApprDate);
                }
            }else if(inv.Status == 'Payment Under Bank Clearance'){
                invoiceBundle.BankResponse__c = inv.bankResponse;
                invoiceBundle.BankComments__c = inv.bankComments != null ? inv.bankComments : '';
                if (inv.bankApprDate != '') {
                    invoiceBundle.BankApprovedDate__c = Date.valueOf(inv.bankApprDate);
                }
            }
            
            //Perform Update DML
            Update invoiceBundle;

            // Return success response
            handler.response.success = true;
            handler.response.data = invoiceBundle;
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

    public class InvoiceDetails {
        public String InvoiceBundleId { get; set; }
        public String Status { get; set; }
        public String ErpId { get; set; }
        public String cancelReason { get; set; }
        public String invResponse { get; set; }
        public String invApprName { get; set; }
        public String invApprComments { get; set; }
        public String invApprDate { get; set; }
        public String payResponse { get; set; }
        public String payApprName { get; set; }
        public String payApprComments { get; set; }
        public String payApprDate { get; set; }
        public String bankResponse { get; set; }
        public String bankComments { get; set; }
        public String bankApprDate { get; set; }
    }
    
    // Method to parse the JSON string
    public static InvoiceDetails parseInvoiceJson(String jsonString) {
        InvoiceDetails invoice = (InvoiceDetails) JSON.deserialize(jsonString, InvoiceDetails.class);
        return invoice;
    }
}