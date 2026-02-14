public with sharing class DARIRegistrationModel {
    /**Create App**/
    public class createapplication {
        public String dmtNumber;
        public String applicationType;
        public Boolean withMortgage;   
    }
    
    public class createApplicationResponse { 
        public Boolean success;
        public String applicationName;
        public String statusCode;
        public createApplicationResponseResults results;
    }
    
	public class createApplicationResponseResults {
        public Boolean success;
        public Integer elapsed;
        public Result result;
    }
    
    public class Result {
        public Integer id;
        public String applicationType;
        public String applicationNumber;
        public decimal liabilityAmount;
        public decimal adminFeeAmount; 
        public decimal transactionTotalAmount;
        public String description;
        public String statusCode;
        public String error;
        public String errorMessgae;
        public String errorDetails;
        public String failureCode;
        public String premiseId;
        public decimal payLiability;
        public Boolean isPremiseIdRequired;
        public List<OFF_PLAN_CONTRACTS> OFF_PLAN_CONTRACTS;
		public List<DEVELOPER_LICENCE> DEVELOPER_LICENCE;
    }
    
    public class OFF_PLAN_CONTRACTS {
		public String failureCode;	//VAL125
		public String days;
		public String results;
	}
    
	public class DEVELOPER_LICENCE {
		public String failureCode;	//VAL125
		public String days;
		public String results;
	}
    /**Create App***/
    /**Fetch App**/
    public class fetchApplicationResponse {
        public Boolean success;
        public String applicationName;
        public String statusCode;
        public fetchApplication results;
    }
    
    public class fetchApplication { 
        public Boolean success;
        public Integer elapsed;
        public AppResult result;
    }
    
    public class AppResult {
        public ApplicationDetails applicationDetails;
        public String description;
        public List<Buyers> buyers;
        public List<OFF_PLAN_CONTRACTS> OFF_PLAN_CONTRACTS;
		public List<DEVELOPER_LICENCE> DEVELOPER_LICENCE;
    }
    
    public class ApplicationDetails {
        public Integer applicationId;
        public String applicationType;
        public String applicationNumber;
    }
    
    public class Buyers {
		public String partyType;	//BUYER
		public String ownerNameEn;	//YAWNAS ABDAL-RAZZAQ FADL MARZOOQ AL-YAZIDA
		public String ownerNameAr;	//يونس عبدالرزاق فضل مرزوق اليزيدى
		public String email;	//a
		public String phoneNumber;	//971582118066
		public String eidOrUnified;	//784198092739543
		public String tradeLicenseNumber;
		public String poaEidOrUnified;
		public String passportNumber;
        public String ownerId;
	}
    /**Fetch App**/
    /**Mortgage Details**/
    public class MortgageDetails {
        public Integer applicationId;
        public String key;
        public Mortgage mortgage;
    }    
    
    public class Mortgage {
        public BankDetails bankDetails;
        public PropertyDetails propertyDetails;
    }
    
    public class PropertyDetails {
        public Boolean isSharedMortgage;
    }
    
    public class BankDetails {
        public Integer bankCompanyId;
    }
    /**Mortgage Details**/
    /**Property Details**/
    public class PropertyDetail {
        public Integer applicationId;
        public String key;
        public PropDetails propertyDetails;
    }
    
    public class PropDetails {
        public String premiseNumber;
        public String premisesAddress;
    }
    /**Property Details**/
    /**Registration Fee Detail**/
    public class RegistrationFeeDetail {
        public Integer applicationId;
        public String key;
        public RegistrationFeeDetails registrationFeeDetails;
    }
    
    public class RegistrationFeeDetails {
        public String paidBy;
        public Boolean enrollPropertyInTawteeq;
        public Boolean payLiability;
        public String liabilityPaidBy;
    }
    
    public class RegistrationFeeDetailWithoutLiability {
        public Integer applicationId;
        public String key;
        public RegistrationFeeDetailsWithoutLiability registrationFeeDetails;
    }
    
    public class RegistrationFeeDetailsWithoutLiability {
        public String paidBy;
        public Boolean enrollPropertyInTawteeq;
    }
    /**Registration Fee Detail**/
    /**Developer Approval**/
    public class DeveloperApproval {
        public Integer applicationId;
        public Boolean approved;
    }
    /**Developer Approval**/
    /**Response**/
    public class Response{
        public Boolean success;
        public String statusCode;
        public CancelAppResults results;
    }
    
    public class CancelAppResults{
        public Boolean success;
        public Integer elapsed;
        public AppResult result;
    }
    
    public class MortgageDetailsResponse {
        public Boolean success;
        public String applicationName;
        public String statusCode;
        public createApplicationResponseResults results;
    }
    /**Response**/
    /*
    * Used with Upload Document API
    */
    public class UploadDocumentRequest {
        public String fileName {get;set;} 
        public String fileData {get;set;} 
        public String applicationId {get;set;}
        public String srDocId {get;set;}
    }
    
}