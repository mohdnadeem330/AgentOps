@RestResource(urlMapping='/updateBankDetails')
global class BP_UpdateBankDetails extends BP_BaseRestResource {
    static List<String> FieldExceptionCodes = new List<String>{ 'FIELD_CUSTOM_VALIDATION_EXCEPTION', 'FIELD_FILTER_VALIDATION_EXCEPTION', 'INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST'};
    static Map<String,Object> requestData = new Map<String,Object>();
    static List<User> userRecord = new List<User>();

    @HttpPost
    global static void updateBankDetails() {
        String bankCountry = '';
        RestContextHandler handler = new RestContextHandler(false);
        try {
            Map<String, Object> responseData = new Map<String, Object>(); 
            
            String requestBody = handler.getRequestBody();
            if(!String.isEmpty(requestBody)){
                requestData = (Map<String,Object>) JSON.deserializeUntyped(requestBody);

                System.debug('requestData-->'+requestData);
                
                bankCountry = requestData.containsKey('bankCountry') && (String) requestData.get('bankCountry') != null ? (String) requestData.get('bankCountry') : '';
        
                if(String.isNotBlank(bankCountry)){
                    ValidationWrapper validatedFieldWrapper = fieldValidationSuccess(requestData, bankCountry);
            
                    if(validatedFieldWrapper.isSuccess){
                        String userId = UserInfo.getUserId();
                            //'0052500000Bx4cgAAB'; //
                        userRecord = [SELECT Id,AccountId FROM User WHERE Id = :userId AND AccountId != null AND isActive = true AND Account.RecordType.DeveloperName = 'Broker_Agency'];
                        
                        if(userRecord != null && !userRecord.isEmpty() && String.isNotBlank(userRecord[0].Id)){
                            
                            Map<String, String> params = RestContext.request.params;
                            BP_UpdateBankDetails service = new BP_UpdateBankDetails();
                            ApiResponse response = service.processRequest(params, null);
                            
                            handler.response.data = response.data;
                            handler.response.success = true;
                            handler.response.statusCode = response.statusCode;
                            handler.response.message = response.message;
                            
                            
                            // String message  = bankDetailsCRSubmit(userRecord[0], requestData);
                            // responseData.put('agencyId', userRecord[0].AccountId);

                            // if(message == 'success'){
                            //     uploadDocument((String) responseData.get('bankCopy'), userRecord[0].AccountId);

                            //     handler.response.success = true;
                            //     handler.response.statusCode = 200;
                            //     handler.response.message = 'Success';
                            //     handler.response.data = responseData;
                            // }else{
                            //     handler.response.success = false;
                            //     handler.response.statusCode = 200;
                            //     handler.response.message = message;
                            //     handler.response.data = responseData;
                            // }
                        }
                    }else {
                        handler.response.success = false;
                        handler.response.statusCode = 200;
                        handler.response.message = validatedFieldWrapper.message;
                        handler.response.data = responseData;
                    }
                }
            }
      }catch(DMLException dmlEx){
            Integer statusCode = 500;
            String errorMessage = dmlEx.getMessage();
            List<String> fieldErrorStrs = new List<String>();
            for(Integer i=0; i<dmlEx.getNumDml(); i++){
                if(FieldExceptionCodes.contains(dmlEx.getDmlStatusCode(i))){
                    fieldErrorStrs.add(dmlEx.getDmlMessage(i));
                }
            }
            if(!fieldErrorStrs.isEmpty()){
                statusCode = 300;
                errorMessage = String.join(fieldErrorStrs, ' ');
            }
            
        }catch(Exception e){
            System.debug(e.getStackTraceString());
            handler.response.success = false;
            handler.response.statusCode = 500;
            handler.response.message = e.getMessage();
        } 
        handler.finalize();
    }

   private static ValidationWrapper fieldValidationSuccess(Map<String,Object> requestData, String bankCountry){
        ValidationWrapper wrap = new ValidationWrapper();
        Set<String> setRequiredFieldToBlank = new Set<String>();

        for(String fieldName : requestData.keySet()){
            if(bankCountry == 'United Arab Emirates'){
                if(checkRequiredFields?.containsKey(fieldName) && fieldName != 'beneficiaryName' && ((((String) requestData?.get(fieldName)) == null) || (((String) requestData?.get(fieldName)) == ''))){
                    wrap.isSuccess = false;
                    wrap.message = checkRequiredFields?.get(fieldName) + ' is Required.';
                    break;
                }
            }else{
                if(checkRequiredFields?.containsKey(fieldName) && ((((String) requestData?.get(fieldName)) == null) || (((String) requestData?.get(fieldName)) == ''))){
                    if(fieldName == 'accountNumber' || fieldName == 'ibanNumber'){
                        setRequiredFieldToBlank.add(fieldName);
                    }else{
                        wrap.isSuccess = false;
                        wrap.message = checkRequiredFields?.get(fieldName) + ' is Required.';
                        break;
                    }
                }
            }
        }
        if(setRequiredFieldToBlank.size() > 1){
            wrap.isSuccess = false;
            wrap.message = 'Account Number/ IBAN Number is Required.';
        }

        if(wrap.isSuccess){
            for(String fieldName : requestData.keySet()){
                if(checkRequiredDocuments.containsKey(fieldName)){
                    if((String) requestData.get('bankCopy') == null || (String) requestData.get('bankCopy') == ''){
                        wrap.isSuccess = false;
                        wrap.message = checkRequiredDocuments.get(fieldName);
                        break;
                    }
                }
            }
        }
        System.debug('wrap--->'+wrap);
        return wrap;
    }

    //@future
    public  String uploadDocument(String base64, String fileName, String extension, Id agencyId){
        try {
            String documentType = 'Bank Copy';
        	String fileNameWithExtension = fileName + '.' + extension;

            // Calling Apex Method
            UserProfileController.uploadFile(base64, fileNameWithExtension, documentType, agencyId);
            return 'success';
        }catch(Exception ex){
            return 'ERROR While Uploading the document : '+ex.getMessage();
        }
    }

    global override ApiResponse processRequest(Map<String, String> params, String requestBody) {
        try {
            String bankDetailUpdated =  bankDetailsCRSubmit(userRecord[0], requestData);
            
            if(bankDetailUpdated == 'success'){
            	return new ApiResponse(true, 200,
                                       'Bank detail are updated Successfully', 
                                       uploadDocument((String) requestData.get('bankCopy'),
                                                      (String) requestData.get('fileName'),
                                                      (String) requestData.get('extension'),
                                                      userRecord[0].AccountId));
            }else {
                return new ApiResponse(false, 500,'Bank detail updation failed ' + bankDetailUpdated, null);
            }            
        } catch (Exception e) {
            return new ApiResponse(false, 500,'Bank detail updation failed ' + e.getMessage(), null);
        } 
    }

    private static String bankDetailsCRSubmit(User userRecord, Map<String,Object> bankDetails){ 
       try{
            Account proposedBankUpdate = new Account();
            proposedBankUpdate.Id = userRecord.AccountId;
            proposedBankUpdate.ProposedBankName__c = (String) bankDetails.get('bankName');
            proposedBankUpdate.ProposedBranchAddress__c = (String) bankDetails.get('bankBranch');
            proposedBankUpdate.ProposedBankAccountNumber__c = (String) bankDetails.get('accountNumber');
            proposedBankUpdate.ProposedIBANNumber__c = (String) bankDetails.get('ibanNumber');
            proposedBankUpdate.ProposedSwiftCode__c =(String) bankDetails.get('swiftCode');
            proposedBankUpdate.ProposedBankCountry__c = (String) bankDetails.get('bankCountry');
            // proposedBankUpdate.ProposedBankName__c = bankDetails.get('currency');
            proposedBankUpdate.ProposedBeneficiaryName__c = (String) bankDetails.get('beneficiaryName');
            proposedBankUpdate.ProposedBankDetailStatus__c = 'Pending';
            proposedBankUpdate.Description = 'Please Review the Bank Copy Document Before Approve/Reject';
            update proposedBankUpdate;

            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setObjectId(proposedBankUpdate.Id);

            // Run The Approval Process 
            Approval.ProcessResult result = Approval.process(approvalRequest);
            return 'success';
       }catch (Exception ex){
            return ex.getMessage();
        }
    }
    
    public class ValidationWrapper{
        Boolean isSuccess = true;
        String message = '';
    }

    static Map<String,String> checkRequiredFields = new Map<String,String>{
        'bankCountry' => 'Bank Country',
        'bankName' => 'Bank Name',
        'bankBranch' => 'Bank Branch',
        'accountNumber' => 'Account Number',
        'ibanNumber' => 'IBAN Number',
        'swiftCode' => 'Swift Code',
        'beneficiaryName' => 'Beneficiary Name'
    };

    static Map<String,String> checkRequiredDocuments = new Map<String,String>{
        'bankCopy' => 'Bank Copy Document is required.' // mandatory for all
    };
}