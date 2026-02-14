public class ADCBAndADIBBulkCollectionWrapperClass {

    public Data Data {get;set;} 
    
    public class ClaimedAmount {
		public String Amount {get;set;} 
		public String Currency_Z {get;set;}
    }    
    public class Collection {
		public String CustomerReference {get;set;} 
		public String DDRReference {get;set;} 
		public String MandateReferenceNumber {get;set;} 
		public String RepresentmentFlag {get;set;} 
        public Instruction Instruction {get;set;}
    }    
    public class Data {
		public String OICCode {get;set;} 
		public String RequestType {get;set;} 
		public List<Collection> Collection {get;set;}
    }
    public class Instruction {
		public String OriginatorAccountNumber {get;set;} 
		public String IBAN {get;set;} 
		public String DueDate {get;set;} 
		public ClaimedAmount ClaimedAmount {get;set;} 
    }
}