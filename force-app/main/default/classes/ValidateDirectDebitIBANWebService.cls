//FIN-74 - Anuroop Vipin
@RestResource (urlMapping = '/validate/directDebit')
global with sharing class ValidateDirectDebitIBANWebService {
    
    @HTTPPost
    global static void doPost(String customerAccountName, String customerIBANNumber){
        RestContextHandler handler = new RestContextHandler(true);  
        try {            
            if(customerIBANNumber!=null && customerIBANNumber!='' &&
               customerAccountName!=null && customerAccountName!='')
               {
                Pattern ibanPattern = Pattern.compile('^[AE]{2}[0-9]{2}[0-9]{3}[0-9]{16}$');
                Matcher ibanMatcher = ibanPattern.matcher(customerIBANNumber);
                if(!ibanMatcher.matches()){
                    handler.response.success = false;
                    handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                    handler.response.message = 'Invalid IBAN Number format. Please check the IBAN number and try again.';
                    handler.finalize();
                    return;
                }
                system.debug(ibanMatcher.matches()); 
                Map<String,Object> ibanResult = IBANValidatorController.validateIBANCallout(customerIBANNumber);
                if(ibanResult.get('success')==true){
                    Boolean restrictDDRequestOnIBANValidation = Boolean.valueOf(ibanResult.get('Restrict_DD_Request_On_IBAN_Validation'));
                    String customerNameFromBank = ibanResult.get('IBANAccountTitle') != null ? ((String)ibanResult.get('IBANAccountTitle')).trim() : '';
                    String tempName = customerNameFromBank.trim().split(' ')[0].replace('*','');
                    Boolean isMatching = customerAccountName.startsWithIgnoreCase(tempName);
                    handler.response.success = !(!isMatching && restrictDDRequestOnIBANValidation);
                    handler.response.message = 'The Customer Name \''+customerAccountName+'\' is '+(isMatching? '' : 'not ') +
                        'matching with the Customer Name \''+customerNameFromBank+'\' from Bank.'+
                        (handler.response.success?' Do you want to proceed with the IBAN Number \''+customerIBANNumber+'\'?':' Check the IBAN number and try again.');
                    handler.finalize();                                                    
                }else{
                    handler.response.success = false;
                    handler.response.message = 'Invalid IBAN Number '+customerIBANNumber+'. Please check the IBAN number and try again.';
                    handler.finalize();
                }
            }
    }
        catch (Exception ex) {
            System.debug('msg '+ex.getMessage());
            System.debug('line no '+ex.getLineNumber());
            handler.response.success    = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message    = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);            
        }                      
        
    }
}