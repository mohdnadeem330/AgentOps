public class ADCBAndADIBCollectionEnqueryWrapper {
	public cls_Data Data;
	public class cls_Data {
		public String RequestType;	//COLL
		public cls_Collection[] Collection;
	}
	public class cls_Collection {
		public String CustomerReference;	//0045800749
		public String BankReference;	//54500189851
		public String MandateReferenceNumber;	//9901000000112
		public String DDRReference;	//94000033142024000004242
		public cls_Instruction Instruction;
		public cls_Status Status;
	}
	public class cls_Instruction {
		public String OICCode;	//940000331
		public String OriginatorAccountNumber;	//12961810
		public String IBAN;	//AE710500000000028153237
		public String DueDate;	//2024-04-18 00:00:00
		public cls_ClaimedAmount ClaimedAmount;
	}
	public class cls_ClaimedAmount {
		public String Amount;	//200
		//public String Currency;	//AED
	}
	public class cls_Status {
		public String Code;	//C
		public String Message;	//Checker Approved
	}
}