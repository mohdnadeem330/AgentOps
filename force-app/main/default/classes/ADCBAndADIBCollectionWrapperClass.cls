public class ADCBAndADIBCollectionWrapperClass {
	public Data Data {get;set;} 
		
	public class Data {
		public String RequestType {get;set;} 
		public String CustomerReference {get;set;} 
		public String DDRReference {get;set;} 
		public String MandateReferenceNumber {get;set;} 
		public Instruction Instruction {get;set;} 
		public Data() {
			this.Instruction = new Instruction();
		}
	}
	
	public class Instruction {
		public String OICCode {get;set;} 
		public String OriginatorAccountNumber {get;set;} 
		public String IBAN {get;set;} 
		public String DueDate {get;set;} 
		public ClaimedAmount ClaimedAmount {get;set;} 
		public Instruction() {
			this.ClaimedAmount = new ClaimedAmount();
		}
	}

	public class ClaimedAmount {
		public String Amount {get;set;} 
		public String Currency_Z {get;set;}// it will not accept Currency
    }
}