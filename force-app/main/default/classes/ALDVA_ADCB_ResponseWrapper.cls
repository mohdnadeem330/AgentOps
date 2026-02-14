/*
 * This Wrapper Can Handle the Create and Cancellation of Virtual Account Response
 * Created By : ssekar@aldar.com Saravanan Sekar 20/12/2022
 */ 
public class ALDVA_ADCB_ResponseWrapper{
    public String success;	//true
    public String reqTimeStamp;	//2020-02-21T13:55:52
    public String resTimeStamp;	//2020-02-21T13:55:52
    public String responseId;	//adf0b22-2eb4-4141-bc6c-0c56fb8cbbde
    public cls_response response;
    public class cls_response {
        public String requestId;	//984848
        public String customerID;	//1234567
        public String virtualCustomerID;	//12345
        public String errorCode;
        public String errorDescription;
        public String physicalAccountNumber;	//123456789001
        public String physicalAccountTitle;	//ACDESC_123456789001
        public String virtualAccountNumber;	//12345678911111
        public String defaultAccount;	//Y
        public String virtualAccountTitle;	//Title1
        public String virtualIBAN;	//AE123456789111111111112
        //public String currency;	//AED
        public String virtualAccountType;	//N
        public String splitRequired;	//Y
        public String virtualAccountStatus;	//A //C
        public String virtualAccountOpenDate;	//2020-02-21T13:55:52
        public String virtualAccountClosureDate;	//2020-02-21T13:55:52
        public String uniqueReferenceNumber;	//734899
        public cls_splitAccDetails splitAccDetails;
    }
    public class cls_splitAccDetails {
        public cls_accDetails[] accDetails;
    }
    public class cls_accDetails {
        public String accountNumber;	//123456789001
        public String splitPercentage;	//50
        public String accountDescription;	//ACDESC_123456789001
        //public String currency;	//AED
    }
    public static ALDVA_ADCB_ResponseWrapper parse(String json){
        return (ALDVA_ADCB_ResponseWrapper) System.JSON.deserialize(json, ALDVA_ADCB_ResponseWrapper.class);
    }    
}