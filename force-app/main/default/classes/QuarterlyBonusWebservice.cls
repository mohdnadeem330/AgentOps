@RestResource(urlMapping = '/updateQuarterlyBonus')
global class QuarterlyBonusWebservice {
    
    @HTTPPost
    global static void doPost() {
        RestContextHandler handler = new RestContextHandler(true); 
        RestRequest req = RestContext.request;
        
        QuarterlyBonusCommission qbc = parseInvoiceJson(req.requestBody.toString());
        QuarterlyBonusCommission__c quarterlyBonusCommission = new QuarterlyBonusCommission__c();
        
        try {
            // Validate the provided InvoiceBundleId
            if (qbc.qbcId == null) {
                throw new IllegalArgumentException('InvoiceBundleId cannot be null.');
            }

            // Fetch the InvoiceBundle record (only one record should be retrieved)
            quarterlyBonusCommission = [SELECT Approval_Status__c,
                                        BrokerAgency__c,
                                        Comments__c,
                                        CommentTrail__c,
                                        Id,
                                        InvoiceDate__c,
                                        Name,
                                        OwnerId,
                                        Quarter__c,
                                        Status__c,
                                        TotalCommissionAmount__c,
                                        TotalEligibleAmount__c,
                                        Year__c 
                                        FROM QuarterlyBonusCommission__c
                                        WHERE Id=: qbc.qbcId];

            // Map incoming parameters to the respective fields on InvoiceBundle
            quarterlyBonusCommission.Status__c = qbc.Status;
            quarterlyBonusCommission.ERPID__c = qbc.ErpId;
           
            if(qbc.Status == 'Invoice Approval In Progress'){
                quarterlyBonusCommission.InvoiceResponse__c = qbc.invResponse;
                quarterlyBonusCommission.InvoiceApproverName__c = qbc.invApprName;
                quarterlyBonusCommission.InvoiceApproverComments__c = qbc.invApprComments != null ? qbc.invApprComments : '';
                if (qbc.invApprDate != '') {
                    quarterlyBonusCommission.InvoiceApprovedDate__c = Date.valueOf(qbc.invApprDate);
                }
            }else if(qbc.Status == 'Payment Approval In Progress'){
                quarterlyBonusCommission.PaymentResponse__c = qbc.payResponse;
                quarterlyBonusCommission.PaymentApproverName__c = qbc.payApprName;
                quarterlyBonusCommission.PaymentApproverComments__c = qbc.payApprComments != null ? qbc.payApprComments : '';
                if (qbc.payApprDate != '') {
                    quarterlyBonusCommission.PaymentApprovedDate__c = Date.valueOf(qbc.payApprDate);
                }
            }else if(qbc.Status == 'Payment Under Bank Clearance'){
                quarterlyBonusCommission.BankResponse__c = qbc.bankResponse;
                quarterlyBonusCommission.BankComments__c = qbc.bankComments != null ? qbc.bankComments : '';
                if (qbc.bankApprDate != '') {
                    quarterlyBonusCommission.BankApprovedDate__c = Date.valueOf(qbc.bankApprDate);
                }
            }
            
            //Perform Update DML
            Update quarterlyBonusCommission;

            // Return success response
            handler.response.success = true;
            handler.response.data = quarterlyBonusCommission;
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
    
     public class QuarterlyBonusCommission {
        public String qbcId;
        public String Status;
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
    public static QuarterlyBonusCommission parseInvoiceJson(String jsonString) {
        QuarterlyBonusCommission qbc = (QuarterlyBonusCommission) JSON.deserialize(jsonString, QuarterlyBonusCommission.class);
        return qbc;
    }
}