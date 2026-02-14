@RestResource(urlMapping = '/customer/createTenantSelfAccount')
global without sharing class TenantSelfCreateAccountWebService {
    
    @HttpPost
    global static void createTenantSelfAccount() {
        RestContextHandler handler = new RestContextHandler(false);
        TenantAccountCreationResponse responseData ;
        try {
            Map<String,String> mapFieldApiFieldValues = handler.getRequestBodyMap();
            responseData = createliveinTenantSelfAccount(mapFieldApiFieldValues);
            handler.response.data = responseData; 
            handler.response.success = true;
            handler.finalize();
        } catch (Exception ex) {
            System.debug('Exception at Line: ' + ex.getLineNumber() + ' Message: ' + ex.getMessage());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
        
    }
    
    public static TenantAccountCreationResponse createliveinTenantSelfAccount(Map<String,String> mapFieldApiFieldValues) {
        
        system.debug('mapFieldApiFieldValues::'+mapFieldApiFieldValues);
        TenantAccountCreationResponse response = new TenantAccountCreationResponse();
        
        //List<Unit__c> existingUnitListAsPerADMValues = [Select Id from Unit__c where ADMUnitNumber__C =: mapFieldApiFieldValues.get('ADMUnitNumber') AND ADMPlotNumber__c =:mapFieldApiFieldValues.get('ADMPlotNumber') AND ADMBuildingNumber__c =:mapFieldApiFieldValues.get('ADMBuildingNumber')];
    
            //Create Account //check duplicate also
            Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>> accountEmailPhoneMap =  UtilitiesWithoutSharing.findDuplicateAccountsByEmail(new set<string>{mapFieldApiFieldValues.get('email')});
            boolean doesAccountExist = accountEmailPhoneMap != null && accountEmailPhoneMap.containsKey(mapFieldApiFieldValues.get('email'));
           // List<Asset> relatedAsset = [Select Id,Unit__c from asset where Unit__c =:existingUnitListAsPerADMValues[0].Id and RecordType.Name = 'ECSS Unit' limit 1];
            
            Account accountToReturn = new Account();
            
            if(!doesAccountExist){
                Account newAccount = new Account();
                newAccount.PersonEmail = mapFieldApiFieldValues.get('email');
                newAccount.PersonMobilePhone = mapFieldApiFieldValues.get('mobileCountryCode')+mapFieldApiFieldValues.get('mobilePhone');
                newAccount.FirstName = mapFieldApiFieldValues.get('firstName');
                newAccount.LastName = mapFieldApiFieldValues.get('lastName');
                newAccount.AllowLiveAldarRegistration__c = true;
                newAccount.MobileCountryCode__pc =mapFieldApiFieldValues.get('mobileCountryCode');
                newAccount.MobileNumberEnc__pc = mapFieldApiFieldValues.get('mobileCountryCode') + mapFieldApiFieldValues.get('mobilePhone');
                newAccount.EmailAddress__pc = mapFieldApiFieldValues.get('email');
                newAccount.MobilePhone__pc = mapFieldApiFieldValues.get('mobilePhone');
                newAccount.Sync_with_SFMC__c = true;
                newAccount.Sync_with_SFMC__pc = true;
                newAccount.CustomerVertical__c = 'Aldar Estates;Aldar Properties';
                newAccount.ECSS_Customer_Type__c =  'Tenant';
                insert newAccount;
                
                accountToReturn = newAccount;
            }else{
                List<UtilitiesWithoutSharing.DuplicateAccountWrapper> matchingAccounts = accountEmailPhoneMap.get(mapFieldApiFieldValues.get('email'));
                Set<String> existingValues = new Set<String>();
                
                if (!matchingAccounts.isEmpty()) {
                    Account existingAccount = matchingAccounts[0].account;
                    Account acc = new Account();
                    acc.Id =matchingAccounts[0].account.Id;
                    
                    if (String.isNotBlank(acc.ECSS_Customer_Type__c)) {
                        existingValues.addAll(acc.ECSS_Customer_Type__c.split(';'));
                    }
                    if(!existingValues.contains('Tenant')) {
                        existingValues.add('Tenant');
                        acc.ECSS_Customer_Type__c = String.join(new List<String>(existingValues), ';');                    
                        update acc;
                    }               
                    
                    accountToReturn = acc;
                }
                
                System.Debug('accountToReturn-->'+accountToReturn);
            }
            
            response = getTenantAccountDetails(new List<Account>{accountToReturn});
            
        return response;
    }
    
    public static TenantAccountCreationResponse getTenantAccountDetails(List<Account> currentAccount) {
        
        String whereClause = '';
        List<Account> accountList = new List<Account>();
        
        if(!currentAccount.isEmpty() && currentAccount[0]?.Id != null){
            whereClause = 'Id = \'' + currentAccount[0]?.Id + '\' ';
            accountList = CustomerServiceUtility.getAccountDetail(whereClause);
        }
        
        return getTenantAccountCreationResponse(accountList);
    }
    
    public static TenantAccountCreationResponse getTenantAccountCreationResponse(List<Account> currentAccount) {
        
        TenantAccountCreationResponse response = new TenantAccountCreationResponse();
        
        System.debug('currentAccount-->'+currentAccount);
        if (!currentAccount.isEmpty()) {
            response.accountId = currentAccount[0].Id;
            response.name = currentAccount[0].Name;
            response.email = currentAccount[0].PersonEmail;
            response.mobilePhone =  currentAccount[0].MobilePhone__pc;
        }
        
        return response;
    }
    
    public class TenantAccountCreationResponse{
        public string accountId;
        public string name;
        public string email;
        public string mobilePhone;
    }
    
}