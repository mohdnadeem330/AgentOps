public class ADCBAndADIBCollectionAPIResponse {

    public Data Data;
    public String Id {get;set;}
    public String Code {get;set;}
    public String Message {get;set;}
    public List<Error> Errors;
    public ADCBAndADIBCollectionAPIResponse(){
        this.Data = new Data();
        this.Errors = new List<Error>();
    }
	public class Data {
        public String CollectionBatchId {get;set;}
		public String RequestType {get;set;} 
		public String CustomerReference {get;set;} 
		public String DDRReference {get;set;} 
		public String MandateReferenceNumber {get;set;} 
	}
    public class Error {
        public String ErrorCode {get;set;}
        public String Message {get;set;}
    }
}