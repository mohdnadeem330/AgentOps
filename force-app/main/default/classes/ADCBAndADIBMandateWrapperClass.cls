public class ADCBAndADIBMandateWrapperClass {
    
    public cls_Data Data;
    public class cls_Data {
        public String RequestType;
        public String CustomerReference;
        public String PayerId;
        public String CancellationCode;
        public cls_CustomerDetails CustomerDetails;
        public cls_PayerDetails PayerDetails;
        public cls_MandateDetails MandateDetails;
        public String CaptureMode;
        public String PreApprovalReference; 
        public String MandateReferenceNumber;
    }
    public class cls_CustomerDetails {
        public String CustomerType;
        public String CustomerId;
        public String CustomerIdType;
    }
    public class cls_PayerDetails {
        public String FullName;
        public String MobileNumber;
        public String EmailId;
        public String BankCode;
    }
    public class cls_MandateDetails {
        public String OICCode;
        public String FundingAccountType;
        public String DDAIssuedFor;
        public String DDACommencementDate;
        public String DDAExpiryDate;
        public String DDAAmountType;
        public String DDAInstancesAllowed;
        public String DDAFileName;
        //public String CancellationCode;
        public cls_PaymentDetails PaymentDetails;
    }
    public class cls_PaymentDetails {
        public String PaymentFrequency;
        public String IBAN;
        public String DefinedDays;
        public cls_MinimumAmount MinimumAmount;
        public cls_MaximumAmount MaximumAmount;
    }
    public class cls_MinimumAmount {
        public String Amount;
        public String min_Currency;
    }
    public class cls_MaximumAmount {
        public String Amount;
        public String max_Currency;	
    }
    public static ADCBAndADIBMandateWrapperClass parse(String json){
        return (ADCBAndADIBMandateWrapperClass) System.JSON.deserialize(json, ADCBAndADIBMandateWrapperClass.class);
    }
}