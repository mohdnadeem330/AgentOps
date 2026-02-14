@RestResource (urlMapping = '/validate/accountopportunity')
global class ValidateAccountOpportunityWebService {
    @HTTPPost
    global static void doPost(Id accountId){
        
        RestContextHandler handler = new RestContextHandler(true);
        List<String> validationList = new List<String>();
        List<String> fieldAPIs = new List<String>();
        String validationMessage = accountId;
        try {       
            if (String.isNotBlank(accountId) && accountId != null) {
                String accountValdiation = AccountService.accountsFieldsValidationmtd(accountId);
                Map<String,List<ValidationFields__mdt>> validationFieldsMap = Utilities.getValidationFields();
                List<Account> accountRecList = AccountService.queryAllFieldsWithExtraFields(new List<Id>{accountId});
                Account accountRec = accountRecList[0];
                System.debug('accountValdiation '+accountValdiation);

                if(accountValdiation!=null && accountValdiation !='')
                {
                    validationMessage = 'Please populate values for '+accountValdiation +' field(s) on related Opportunity record';
                    validationList = accountValdiation.split(', ');
                   
                    for(String str : validationList){

                        if(accountRec.RecordType.Name == Constants.PERSON_ACCOUNT_RT){
                            for(ValidationFields__mdt vf : validationFieldsMap.get('Account')){
                                if(vf.RecordType__c == 'Person'){

                                    if(str == vf.Label)
                                        fieldAPIs.add(vf.FieldAPI__c);                                                                           
                                }
                            }
                        }
                        else if(accountRec.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT){

                            List<Contact> contactList = accountRec.Contacts ;
                            for(ValidationFields__mdt vf : validationFieldsMap.get('Account')){
                                if(vf.RecordType__c == 'Organization'){  
                                    if(str == vf.Label)
                                        fieldAPIs.add(vf.FieldAPI__c);
                                }
                            }
                            for (Contact contactObject : contactList) {
                                if (contactObject.PrimaryContact__c) {
                                    for(ValidationFields__mdt vf : validationFieldsMap.get('Contact')){
                                        if(vf.ObjectName__c == 'Contact'){
                                            if(str == vf.Label)
                                            fieldAPIs.add(vf.FieldAPI__c);   
                                        }
                                    }
                                }
                            }
                        }
                    }                    

                    handler.response.success = false;
                    handler.response.statusCode = Constants.STATUS_CODE_NOT_FOUND;
                    handler.response.message = validationMessage;
                    handler.response.data = fieldAPIs; 
                    handler.finalize();
                }  
                else {
                    handler.response.success = true;
                    handler.response.message = '';
                    handler.response.data = ''; 
                    handler.finalize();
                }                     
            }
        }
        catch(Exception e)
        {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(e);
        }
    }
}