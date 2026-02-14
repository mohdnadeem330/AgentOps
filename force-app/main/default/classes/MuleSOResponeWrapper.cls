public class MuleSOResponeWrapper {
    public String applicationName;
    public boolean success;
    public String statusCode;
    public String correlationId;
    public MuleResponse results; 
    
    public class MuleResponse {
        public List<SOResponse> paymentRes;
        public List<SOResponse> receiptApplRes;
        public List<SOResponse> salesOrderRes;
//        public List<SOResponse> salesConsultantRes;
//        public List<SOResponse> salesOrderlineRes;
        public List<SOResponse> supplBrokerRes;
        public List<SOResponse> brkrAgentDtls;
        public List<SOResponse> cancellationRes;
        public List<SOResponse> othChgRes;
        public List<SOResponse> lpcRes;
        public List<SOResponse> prpTransRs;
        public List<SOResponse> prpTransJORs;
        public List<SOResponse> pmtPlanRes;
        public List<SOResponse> instLinesRes;
        public List<SOResponse> ownershipChangeResp;
        public List<SOResponse> creditNoteRes;
    }

    public class SOResponse {
        public String sfRequestId;
        public String sfSalesOrderNum;
        public String erpSalesOrderId;
        public String erpPayPlanId;
        public String erpCustAcctId;
        public String commInstNum;
        public String brokerAgent;
        public String salesManager;
		public String sfRecId;
        public String saleConsulRecId;
        public String status;
		public String errorMsg;
		public String errorMessage;
		public String sfInstId;
		public String erpInstId;
        public String recordId;
        public String recackRecordId;
        public String erpCheckId;
        public String erpCheckApplId;
        public String sfSupplierId;
		public String sfResourceId;
		public String sfSiteId;
		public String sfContactId;
		public String oracleResourceId;
		public String oracleSupplierId;
		public String oracleSiteId;
		public String oracleContactId;
        public String sfAgentId;
		public String oracleAgentId;
		public String srSFId;
		public String srERPId;
		public String sfSalesOrderId;
		public String erpId;
		public String soSFId;
		public String sfTransferSFId;
		public String cusSFId;
		public String cusERPId;
		public String sfId;
		public String recAcct;
		public String expAcct;
		public String taxAcct;
		public String jointOwnerId;
		public String salesOrderId;
		public String partyId;
		public String mode;
		public String type;
		public String instNum;
		public String invoiceId;
		public String cnErpId;
        public String invoiceNo;
        public String IsInvoiceReversal;//SS_220623
        public String bankDetailsStatus; // Added By Moh Sarfaraj for BPE-164
        public List<SOResponse> receiptApplRes;
        public List<SOResponse> salesOrderlineRes;
        public List<SOResponse> salesConsultantRes;
        public List<SOResponse> brkrAgentDtls;
        public String custAccountNum;
    }
    
    public MuleSOResponeWrapper parse(String json) {
        return (MuleSOResponeWrapper) System.JSON.deserialize(json, MuleSOResponeWrapper.class);
    }
}