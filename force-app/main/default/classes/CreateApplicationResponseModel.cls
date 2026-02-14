public class CreateApplicationResponseModel{
	public String applicationName;
	public boolean success;
	public String statusCode;
	public String correlationId;
	public Results results;
	public class Results {
		public boolean success;
		public Integer elapsed;
		public Result result;
	}
	public class Result {
		public String statusCode;
        public String applicationId;
		public String contractNo;
        public String error;
        public String description;
        public String errorMessgae;
        public String failureCode;
        public String errorDetails;
		public ApplicationDetails applicationDetails;
        public List<ACTIVE_APPLICATION> ACTIVE_APPLICATION;
        public List<CONCURRENT_APPLICATION> CONCURRENT_APPLICATION;
	}

	public class ApplicationDetails {
		public Integer applicationId;	//28259
		public String applicationNumber;	//20230000028259
		public String applicationType;	//OFF_PLAN_FIRST_SELL_LAND
		public Integer plotID;	//99214
		public String registrationDate;	//2023-03-24
		public String applicationStatusEn;	//Draft
		public String applicationStatusAr;	//مسودة
		public String applicationAdminStatus;	//DRAFT
		public Integer initiatorUserId;	//84576
		public String initiatorName;	//SAMEER HELAL HAMAD YEHIA AL-HALALA
		public String initiatorNameAr;	//سمير هلال حمد يحيى الهلالى
		public String source;	//ONLINE
		public String creationDate;	//2023-03-24T02:37:59
		public String applicationStatus;	//DRAFT
		public String progressStatus;	//DRAFT
		public boolean initiator;
		public boolean canCancel;
		public String submittedDate;	//2023-03-24 02:37
		public boolean paymentDone;
	}
    
    public class ACTIVE_APPLICATION{	//Monika: 15/02/2024: Changes for storing applicationId
        public String failureCode;
        public String days;
        public List<String> results;
        public details details;
    }
    public class CONCURRENT_APPLICATION{	//Monika: 15/02/2024: Changes for storing applicationId
        public String failureCode;
        public String days;
        public List<String> results;
        public details details;
    }
    public class details{
        
    }
}