public class ADCBAndADIBMandateResponseWrapperClass {

    public class successResponsewrapper{
        public cls_Data Data;
    }
    /*public class cls_Data {
        public String BankReference;
        public String OICCode;
        public String CustomerReference;
        public String DDAFileName;
        public String MandateReferenceNumber;
    }*/
    
    public class cls_Data {
		public String CustomerReference;	//0041700695
		public String BankReference;	//202403220009227
		public String MandateReferenceNumber;	//9123000000043
		public String RequestType;	//RQST
		public String PayerId;	//SUS01
        public String DDRReference;
		public cls_CustomerDetails CustomerDetails;
		public cls_PayerDetails PayerDetails;
		public cls_MandateDetails MandateDetails;
		public cls_Status Status;
	}
	public class cls_CustomerDetails {
		public String CustomerType;	//IN
		public String CustomerId;	//784199483081123
		public String CustomerIdType;	//UAE Emirates Identity Card
	}
	public class cls_PayerDetails {
		public String FullName;	//Fahad Farooq
		public String MobileNumber;	//+971586312767
		public String EmailId;	//rsrivastava@aldar.com
	}
	public class cls_MandateDetails {
		public String OICCode;	//940000331
		public String FundingAccountType;	//CUR
		public String DDAIssuedFor;	//404
		public String DDACommencementDate;	//23-03-2024
		public String DDAExpiryDate;	//31-05-2027
		public String DDAAmountType;	//P
		public String DDAInstancesAllowed;	//5
		public String DDAFileName;	//0033000006952403.pdf
		public cls_PaymentDetails PaymentDetails;
	}
	public class cls_PaymentDetails {
		public String PaymentFrequency;	//Daily
		public String DefinedDays;	//
		public String IBAN;	//AE070500000000017222004
		public cls_MinimumAmount MinimumAmount;
		public cls_MaximumAmount MaximumAmount;
	}
	public class cls_MinimumAmount {
		public String Amount;	//1
		//public String Currency;	//AED
	}
	public class cls_MaximumAmount {
		public String Amount;	//370237.3
		//public String Currency;	//AED
	}
	public class cls_Status {
		public String Code;	//S
		public String Message;	//Sent to Central MMS
	}
    
    public class failureResponseWrapper{
        public String Code;
        public String Id;
        public String Message;
        public cls_Errors[] Errors;        
    }
    public class cls_Errors {
        public String ErrorCode;
        public String Message;
    }
}