public with sharing class ADMRegistrationModel {

    /*
    * Model for CreateApplication API
    */
    public Class CreateApplication {
        public String dmtNumber {get;set;} 
        public String applicationType {get;set;} 
        public String key {get;set;} 
        public Boolean priority {get;set;} 
        public Boolean isDraft {get;set;} 
        public List<Buyers> buyers {get;set;} 
        public ContractDetails contractDetails {get;set;} 
        public String paymentPlanType {get;set;} 
        public List<InstalmentPlanList> instalmentPlanList {get;set;} 
        public List<Brokers> brokers {get;set;} 
    }

    /*
    * Used with CreateApplication API
    */
    public class InstalmentPlanList {
        public Decimal displayOrder {get;set;} 
        public String categoryType {get;set;} 
        public String instalmentType {get;set;} 
        public Decimal value {get;set;} 
        public String frequency {get;set;} 
        public Decimal percentage {get;set;} 
        public Date date_Z {get;set;} // in json: date
    }

    /*
    * Used with CreateApplication API
    */
    public class Brokers {
        public String eidNumberOrUnified {get;set;} 
    }

    /*
    * Used with CreateApplication API
    */
    public class Buyers {
        public String eidNumberOrUnified {get;set;} 
        public Object tradeLicenseNo {get;set;} 
        public Object email {get;set;} 
        public Decimal transactionShare {get;set;} 
        public List<Representatives> representatives {get;set;} 
    }

    /*
    * Used with CreateApplication API
    */
    public class Representatives {
        public String eidNumberOrUnified {get;set;} 
    }

    /*
    * Used with CreateApplication API
    */
    public class ContractDetails {
        public Date dateOfSale {get;set;} 
        public Date projectCompletionDate {get;set;} 
        public Decimal salePrice {get;set;} 
        public String paidBy {get;set;} 
    }

    /*
    * Used with Upload Document API
    */
    public class UploadDocumentRequest {
        public String fileName {get;set;} 
        public String fileData {get;set;} 
        public String applicationId {get;set;}
        public String srDocId {get;set;}
        public String contentVersionId {get;set;}
    }
}