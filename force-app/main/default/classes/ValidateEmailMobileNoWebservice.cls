/*
* Purpose : To validate the Email Id or Mobile No
* Created by : Ajay Thakur
*/
@Restresource(urlMapping='/validate/EmailOrMobileNumber')
global class ValidateEmailMobileNoWebservice {
    @httppost
    global static void doPostMethod(String email, String mobileNumber) {  

        RestContextHandler handler = new RestContextHandler(false);
        ValidationResponse validationResponse = new ValidationResponse();
        try {
            List<String> emailList = new List<String>();
            List<String> mobileList = new List<String>();
            List<Boolean> validateEmailMobileNo = new List<Boolean>();
            List<Boolean> falseList = new List<Boolean>();
            falseList.add(false);

            if(email != null && String.isNotBlank(email))
            emailList.add(email);

            if(mobileNumber != null && String.isNotBlank(mobileNumber))
            mobileList.add(mobileNumber);

        if(emailList.size() > 0 && mobileList.size() > 0){
            validationResponse.validEmail = EmailValidation.validateEmail(emailList);
            validationResponse.validMobileNumber = PhoneNoValidation.validatePhoneNo(mobileList);

        }
        else if (emailList.size() > 0) {           
            validationResponse.validEmail = EmailValidation.validateEmail(emailList);
            validationResponse.validMobileNumber = falseList;            
        }
        else if(mobileList.size() > 0){
            validationResponse.validMobileNumber = PhoneNoValidation.validatePhoneNo(mobileList);
            validationResponse.validEmail = falseList;
        }

        handler.response.success = true;
        handler.response.data = validationResponse;
        handler.finalize();            
        } 
        catch (Exception e) {

            System.debug(e.getLineNumber());
            System.debug(e.getMessage());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
            
        }        
    }

    public class ValidationResponse{
        List<Boolean> validEmail {get;set;}
        List<Boolean> validMobileNumber {get;set;}
    }
}