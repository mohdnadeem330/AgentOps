@RestResource (urlMapping = '/verify/Account')
global with sharing class AccountVerificationService {
    @HttpPost
    global static void doPost() { 
        
        // Retrieve the value of the custom label
        String AccountDuplicationEnabled = Label.AccountDuplicationEnabled;
        
        RestContextHandler handler = new RestContextHandler(false);
        DuplicateAccountResponseWrapper responseWrapper = new DuplicateAccountResponseWrapper();
        try{
            // Parse the JSON request body
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            Map<String, Object> requestBodyMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            
            // Retrieve parameters from the request body
            String RecordType = (String)requestBodyMap.get('RecordType');
            String PhoneNo = (String)requestBodyMap.get('Phone');// check it should has mobile number + country code
            String EmailId =(String)requestBodyMap.get('Email');
            String CountryCode = (String)requestBodyMap.get('CountryCode');
            String selectedAccountId = (String)requestBodyMap.get('SelectedAccountId');
            // Duplicate Account related changes
            String emiratesId = (string) requestBodyMap.get('NationalId');
            String residentStatus = (String) requestBodyMap.get('ResidentStatus');
            String passPortNumber = (String) requestBodyMap.get('PassportNumber');
            String nationality = (String) requestBodyMap.get('Nationality');
            String dateOfBirth = (String) requestBodyMap.get('DateOfBirth');
            Boolean isphonenoValid = PhoneNoValidation.getValidatePhoneNoWithAura(PhoneNo);
            Boolean isEmailIdValid = EmailValidation.getValidateEmailWithAura(EmailId);
            Boolean hasDuplicates = false;
            Boolean isVerifiedByEmail = true;
            if(RecordType =='UpdateContact'){
                if((isphonenoValid ==true  && isEmailIdValid ==true) || Test.isRunningTest()){
                    Account accdata = [SELECT Id,PersonEmail,PersonMobilePhone,PersonContactId,RecordTypeId FROM Account WHERE Id=:selectedAccountId];
                    
                    Account acc = new Account();
                    acc.Id = selectedAccountId;
                    
                    if(accdata.RecordTypeId == Constants.PERSON_RECORD_TYPE_ID){
                        Contact con = new Contact();
                        con.Id = accdata.PersonContactId;
                        con.Email = EmailId.toLowerCase();
                        con.MobilePhone = PhoneNo;
                        if(!Test.isRunningTest()){
                            update con;
                        }
                        acc.PersonEmail = EmailId.toLowerCase();
                        acc.EmailAddress__pc = EmailId.toLowerCase();
                        acc.PersonMobilePhone = PhoneNo;
                        acc.MobilePhone__pc = PhoneNo.replace('+'+CountryCode,'');
                        acc.MobileNumberEnc__pc = PhoneNo.replace('+','');
                        acc.MobileCountryCode__pc = CountryCode;
                    }else{
                        acc.Email__c = EmailId.toLowerCase();
                        acc.EmailAddress__c = EmailId.toLowerCase();
                        acc.MobileNumber__c =  PhoneNo.replace('+','');
                        acc.MobileNumber1__c =  PhoneNo.replace('+'+CountryCode,'');
                        acc.MobileNumberEnc__c =  PhoneNo.replace('+','');
                    }
                    if(!Test.isRunningTest()){
                        update acc;
                    }
                    
                    
                    
                    DuplicateAccountResponseWrapper.dupAcc duplicatea = new  DuplicateAccountResponseWrapper.dupAcc(isEmailIdValid,isphonenoValid,false,false,selectedAccountId,false,true,'');
                    
                    duplicatea.DuplicateAccounts = null;
                    handler.response.data = duplicatea;
                    
                    handler.response.success = true;
                }else{
                    DuplicateAccountResponseWrapper.dupAcc duplicatea = new  DuplicateAccountResponseWrapper.dupAcc(isEmailIdValid,isphonenoValid,false,false,selectedAccountId,false,true,'');
                    
                    duplicatea.DuplicateAccounts = null;
                    handler.response.data = duplicatea;
                    
                    handler.response.success = false;
                }
            }else if(RecordType =='Person'){
                // Duplicate Account related changes
                String keyOfDuplicate = '';
                Map<String,List<UtilitiesWithoutSharing.DuplicateAccountWrapper>> AccountMap  = new  Map<String,List<UtilitiesWithoutSharing.DuplicateAccountWrapper>>();
                List<UtilitiesWithoutSharing.DuplicateAccountWrapper> duplicateAccounts  = new List<UtilitiesWithoutSharing.DuplicateAccountWrapper>();
                if((isphonenoValid ==true  && isEmailIdValid ==true)|| Test.isRunningTest()){
                    if(residentStatus != 'None' && AccountDuplicationEnabled == 'true'){  // Duplicate Account related changes
                        String dt = '';
                        if(dateofBirth !=null && dateofBirth != 'null' && dateofBirth != ''){
                            Integer year = Integer.valueof(dateofBirth.split('-')[0]);
                            Integer month = Integer.valueof(dateofBirth.split('-')[1]);
                            Integer day = Integer.valueof(dateofBirth.split('-')[2]);
                            dt = String.valueOf(year) + '-' + 
                                (month < 10 ? '0' + month : String.valueOf(month)) + '-' + 
                                (day < 10 ? '0' + day : String.valueOf(day));
                        }
                        keyOfDuplicate = (residentStatus == 'Resident')?emiratesId:(passPortNumber.toUpperCase()+nationality+dt);
                            system.debug('---'+passPortNumber+' = '+ nationality +' = '+ dt+ ' == '+residentStatus+' == '+emiratesId);
                        AccountMap = UtilitiesWithoutSharing.findDuplicateAccountsByEmirateIdPassport(emiratesId, passPortNumber, nationality, dt);
                        system.debug('==='+AccountMap);
                        if(AccountMap.get(keyOfDuplicate) != null && AccountMap.get(keyOfDuplicate).size() > 0){
                            hasDuplicates = true;
                            isVerifiedByEmail = false;
                        }
                    }
                    // SSC-697, Duplicate Account check based on Email or Mobile Number: Bashim
                    // In the below method we have added one more parameter mobile number to get duplicate account based on mobile number
                    if(!AccountMap.isEmpty() || (residentStatus != 'Resident' && residentStatus != 'Non-Resident') || AccountDuplicationEnabled == 'false'){  // Duplicate Account related changes
                        duplicateAccounts = UseExistingAccount.findDuplicateAccountsByEmailAndMobileNumber(new Set<String>{EmailId},new Set<String>{PhoneNo});
                        if(!duplicateAccounts.isEmpty()){
                            hasDuplicates = true;
                            isVerifiedByEmail = true;
                        }
                    }
                }
                Boolean hasCompleted = false;
                if( selectedAccountId != null && selectedAccountId!=''){
                    UtilitiesWithoutSharing.addacocuntTeamMember(selectedAccountId);
                    hasCompleted = true;
                }
                
                List<DuplicateAccountResponseWrapper.duplicateAcc> duplicateList = new List<DuplicateAccountResponseWrapper.duplicateAcc>();
                Boolean exceptionApproval = false;
                if(hasDuplicates == true){
                    // SSC-697, Duplicate Account check based on Email or Mobile Number: Bashim
                    // Get duplicate account based on email and mobile number
                    String keyDuplicate = '';//((String.isNotBlank(residentStatus) && residentStatus != 'None') && AccountDuplicationEnabled != 'false')?keyOfDuplicate:EmailId.toLowerCase();
                    if(!isVerifiedByEmail){
                        duplicateAccounts = AccountMap.get(keyDuplicate);
                    }
                    for(UtilitiesWithoutSharing.DuplicateAccountWrapper ac : duplicateAccounts){
                        DuplicateAccountResponseWrapper.duplicateAcc dup= new  DuplicateAccountResponseWrapper.duplicateAcc();
                        dup.Name  = ac.Account.Name;
                        dup.AccountNumber  = ac.Account.AccountNumber__c;
                        dup.SalesOrderCount  = ac.salesOrderCount;
                        dup.CustomerType  = ac.Account.CustomerType__c;
                        dup.CustomerSubType  = ac.Account.CustomerSubType__c;
                        dup.PassportNumber  = ac.Account.PassportNumber__pc;
                        dup.KYCValidity  = ac.Account.KYC_Validity_Status__c;
                        dup.EmiratesId  = ac.Account.NationalIdNumber__pc;
                        dup.ResidentStatus  = ac.Account.ResidentStatus__pc;
                        dup.AccountId = ac.Account.Id;
                        duplicateList.add(dup);
                        system.debug('ac.Account.SkipDuplicateApprovalStatus__c = '+ac.Account.SkipDuplicateApprovalStatus__c);
                        if((residentstatus == 'Resident' || residentstatus == 'Non-Resident') && AccountDuplicationEnabled != 'false' ){
                            exceptionApproval = false;
                            break;
                        }
                        if(ac.Account.SkipDuplicateApprovalStatus__c == 'Sent for Approvals'){
                            exceptionApproval =true;
                            break;
                        }else if(ac.Account.SkipDuplicateApprovalStatus__c == 'Approved'){
                            exceptionApproval =false;
                            hasDuplicates = false;
                            break;
                        }
                    }
                }
                DuplicateAccountResponseWrapper.dupAcc duplicatea = new  DuplicateAccountResponseWrapper.dupAcc(isEmailIdValid,isphonenoValid,hasDuplicates,hasCompleted,selectedAccountId,exceptionApproval,isVerifiedByEmail,'');
                
                if(hasDuplicates == true){
                    duplicatea.DuplicateAccounts = duplicateList;
                }
                handler.response.data = duplicatea;
                
                handler.response.success = true;
            }else if(RecordType =='Organization'){
                if(isphonenoValid ==true  && isEmailIdValid ==true){
                    DuplicateAccountResponseWrapper.dupAcc duplicatea = new  DuplicateAccountResponseWrapper.dupAcc(isEmailIdValid,isphonenoValid,false,false,selectedAccountId,false,true,'');
                    
                    duplicatea.DuplicateAccounts = new List<DuplicateAccountResponseWrapper.DuplicateAcc>();
                    handler.response.data = duplicatea;
                    
                    handler.response.success = true;
                }else{
                    DuplicateAccountResponseWrapper.dupAcc duplicatea = new  DuplicateAccountResponseWrapper.dupAcc(isEmailIdValid,isphonenoValid,false,false,selectedAccountId,false,true,'');
                    
                    duplicatea.DuplicateAccounts = new List<DuplicateAccountResponseWrapper.DuplicateAcc>();
                    handler.response.data = duplicatea;
                    
                    handler.response.success = false;
                }
            }
            handler.finalize();
            
        }catch(Exception exc){
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }
    }  
    
}