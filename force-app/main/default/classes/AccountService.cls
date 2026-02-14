public class AccountService {
    
    /*
*Fetch All Acounts
*/
    public static Map<String,Account> getAllAccounts(Set<String> uniqueKeys){
        
        Map<String,Account> allAccountsRecMap = new Map<String,Account>();
        
        List<Account> accountDetails = [SELECT
                                        firstName,
                                        MiddleName,
                                        lastName, 
                                        PersonEmail,
                                        Phone, 
                                        Id, 
                                        createdDate,
                                        UniqueKey__c,
                                        MobileCountryCode__c,
                                        MobileNumber__c, 
                                        Email__c,
                                        Owner.Name,
                                        OwnerId
                                        FROM Account
                                        WHERE UniqueKey__c in : uniqueKeys 
                                        AND (RecordType.Name =: Constants.ORGANISATION_ACCOUNT_RT OR RecordType.Name =: Constants.PERSON_ACCOUNT_RT)
                                        AND MergedAccount__c = FALSE 
                                        ORDER BY createdDate ASC];
        
        
        System.debug('Point: accountDetails'+accountDetails);
        
        for(Account accountRec : accountDetails){ 
            System.debug('Point: accountRec'+accountRec);
            allAccountsRecMap.put(accountRec.UniqueKey__c.toLowerCase(),accountRec);
        }   
        return allAccountsRecMap ;
    }
    
    /*
*Fetch All Agencies
*/
    public static List<Account> getAgencies() {     
        List<Account> agencyList = new List<Account>();        
        try{           
            agencyList =  [SELECT Id, Name FROM Account WHERE RecordType.Name =: Constants.BROKER_AGENCY_ACCOUNT_RT];
        }
        catch(Exception e){
            system.debug('*** Exception e***'+e.getMessage());
        }        
        return agencyList;
    }
    
    /*
*Fetch All Agencies with Agents
*/
    public static List<Account> getAllActiveAgencies(){     
        List<Account> agencyList = new List<Account>();        
        try{           
            agencyList =  [SELECT Id, Name,(Select Id,Name From Contacts) FROM Account WHERE RecordType.Name =: Constants.BROKER_AGENCY_ACCOUNT_RT AND AgencyStatus__c=: Constants.ACTIVE];
        }
        catch(Exception e){
            system.debug('*** Exception e***'+e.getMessage());
        }        
        return agencyList;
    }
    
    /*
*Fetch All Agencies by Name
*/
    public static Map<String,Account> getAgenciesByName(Set<String> agencyNames) {   
        
        Map<String,Account> agencyNameMap = new Map<String,Account>();                  
        for(Account agencyRecord : [SELECT Id, Name FROM Account WHERE RecordType.Name =: Constants.BROKER_AGENCY_ACCOUNT_RT AND Name In : agencyNames]){
            agencyNameMap.put(agencyRecord.Name,agencyRecord);
        }       
        return agencyNameMap;
    }
 /*Commenting for Deployment - Muzammil
    public static List<Account> getAccountsWithWhereClause(String whrClause) {
        Set<String> accFieldList = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(accFieldList);
        String fields = string.join(strList,',');

        Set<String> docFieldList = Schema.getGlobalDescribe().get('Document__c').getDescribe().fields.getMap().keySet();
        List<String> strDocList = new List<String>();
        strDocList.addAll(docFieldList);
        String docFields = string.join(strDocList, ',');

        String query = 'SELECT ' + fields + ', ';
        query += ' (SELECT ' + docFields + ' FROM Documents__r ORDER BY DocumentType__c ASC) ';
        query += ' FROM Account ';
        if (String.isNotBlank(whrClause)) {
            query = query + ' WHERE ' + whrClause;
        }
        System.debug('Account query>>>' + query);
        List<Account> Accounts = Database.Query(query);
        System.debug('Account Data>>>' + Accounts);
        return Accounts;
    }
    */
    // Fetch Contact Details such as Email, Mobile
    public static Map<Id, Account> getContactInfoFromAccount(Set<Id> accountIds) {
        Map<Id, Account> returnMap = new Map<Id, Account>([SELECT Id, Name, PersonEmail, MobilePhone__pc, Email__c, MobileNumber1__c FROM Account WHERE Id IN : accountIds]);
        return returnMap;
    }
    
    @AuraEnabled(cacheable=false)
    public static String accountsFieldsValidation(String accountId){ 
        
        /*
map<id,Account> accountDetails = new map<id,Account>([SELECT Name, FirstName,LastName,PersonEmail,Phone,PersonBirthdate,Gender__pc,PersonMobilePhone,BillingCountry,
MaritalStatus__pc,Type,ResidentStatus__pc,RecordType.name,BillingCity,NationalIdNumber__pc,
Nationality__pc,MobileNumber__c,BillingPostalCode,PrimaryContact__pc,
PassportType__pc,PassportIssueDate__pc,CustomerType__c,PassportExpiryDate__pc,PlaceofIssue__pc,PassportNumber__pc,
RegistrationNumber__c,RegistrationIssueDate__c, RegistrationExpiryDate__c, PlaceOfRegistration__c, UAEVATRegisterNumber__c, Owner__c, EmploymentStatus__pc FROM Account WHERE Id =: accountId]); 


String accountValdiation = null;

map<Account,list<Contact>> mapOfrecords = new map<Account,list<Contact>>();

for(Contact tempContact : [SELECT FirstName,LastName,Email,ResidentStatus__c,Nationality__c,MailingCountry,
MailingCity,MailingPostalCode,AccountId,PrimaryContact__c FROM Contact where AccountId in :accountDetails.keySet()]){
if(!mapOfrecords.containsKey(accountDetails.get(tempContact.AccountId))){
mapOfrecords.put(accountDetails.get(tempContact.AccountId), new list<Contact>());
}
mapOfrecords.get(accountDetails.get(tempContact.AccountId)).add(tempContact);
}

for(id key : accountDetails.keySet()){
Account accountRec = accountDetails.get(key);

if(accountRec.RecordType.Name == Constants.PERSON_ACCOUNT_RT){

accountValdiation = (String.isNotBlank(accountRec.PersonMobilePhone) ? '': 'Mobile Phone');

String passportIssueDate = accountRec.PassportIssueDate__pc + '';
String passportExpiryDate = accountRec.PassportExpiryDate__pc + '' ;
String birthdate = accountRec.PersonBirthdate + '' ;

accountValdiation += (String.isNotBlank(accountRec.FirstName) ? '': (String.isNotBlank(accountValdiation) ? +', ' : '') + 'First Name');

accountValdiation += (String.isNotBlank(accountRec.LastName) ? '': (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Last Name');

accountValdiation += (String.isNotBlank(accountRec.Gender__pc)  ? '' : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Gender');

accountValdiation += (String.isNotBlank(birthdate) ? '' : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Date of Birth');

accountValdiation += (String.isNotBlank(accountRec.PassportNumber__pc) ? '' : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Passport Number');

accountValdiation += (String.isNotBlank(accountRec.MaritalStatus__pc) ? ''  : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Marital Status');

accountValdiation += (String.isNotBlank(accountRec.PersonEmail) ? '' : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Email');

accountValdiation += (String.isNotBlank(accountRec.PassportType__pc) ? '' : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Passport Type');

accountValdiation += (String.isNotBlank(passportIssueDate) ? '' : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Passport Issue Date');

accountValdiation += (String.isNotBlank(passportExpiryDate ) ? '' : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Passport Expiry Date');

accountValdiation += (String.isNotBlank(accountRec.PlaceofIssue__pc) ? '' : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Passport Place of Issue');

accountValdiation += (String.isNotBlank(accountRec.EmploymentStatus__pc)  ? '' : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Employment Status');

accountValdiation += (String.isNotBlank(accountRec.Nationality__pc)  ? '' : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Nationality');

accountValdiation += (String.isNotBlank(accountRec.ResidentStatus__pc) ? ''  : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Resident Type');

if(String.isNotBlank(accountRec.ResidentStatus__pc) && accountRec.ResidentStatus__pc == 'Resident'){
accountValdiation += (String.isNotBlank(accountRec.NationalIdNumber__pc)  ? ''  : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'National ID');
}

accountValdiation += (String.isNotBlank(accountRec.CustomerType__c)  ? ''  : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Customer Type');

accountValdiation += (String.isNotBlank(accountRec.BillingCountry)  ? ''  : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Permanent Country');

accountValdiation += (String.isNotBlank(accountRec.BillingCity)  ? ''  : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Permanent City');

// accountValdiation += (String.isNotBlank(accountRec.BillingPostalCode) ? '' : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Permanent Postal Code');

}else{

accountValdiation = (String.isNotBlank(accountRec.MobileNumber__c)  ? '' : 'Mobile Phone');

String registrationIssueDate = accountRec.RegistrationIssueDate__c == null ? '' : accountRec.RegistrationIssueDate__c + '';
String registrationExpiryDate = accountRec.RegistrationExpiryDate__c  == null ? '' : accountRec.RegistrationExpiryDate__c + '';

accountValdiation += (String.isNotBlank(accountRec.RegistrationNumber__c)
? ''
: (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Registration Number');

accountValdiation += (String.isNotBlank(registrationIssueDate)
? ''
: (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Registration Issue Date');

accountValdiation += (String.isNotBlank(registrationExpiryDate)
? ''
: (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Registration Expiry Date');

accountValdiation += (String.isNotBlank(accountRec.PlaceOfRegistration__c)
? ''
: (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Place of Registration');

accountValdiation += (String.isNotBlank(accountRec.Owner__c)
? ''
: (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Owner');

accountValdiation += (String.isNotBlank(accountRec.UAEVATRegisterNumber__c)
? ''
: (String.isNotBlank(accountValdiation) ? +', ' : '') + 'UAE VAT Register Number');

for (Contact contactObject : mapOfrecords.get(accountRec)) {
if (contactObject.PrimaryContact__c) {

accountValdiation += (String.isNotBlank(accountRec.FirstName) ? '': (String.isNotBlank(accountValdiation) ? +', ' : '') + 'First Name');

accountValdiation += (String.isNotBlank(accountRec.LastName) ? '': (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Last Name');

accountValdiation += (String.isNotBlank(contactObject.Email)
? ''
: (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Email');

accountValdiation += (String.isNotBlank(accountRec.CustomerType__c)
? ''
: (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Customer Type');

accountValdiation += (String.isNotBlank(contactObject.ResidentStatus__c)
? ''
: (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Resident Type');

if(String.isNotBlank(accountRec.ResidentStatus__pc) && accountRec.ResidentStatus__pc == 'Resident'){
accountValdiation += (String.isNotBlank(accountRec.NationalIdNumber__pc)  ? ''  : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'National ID');
}

accountValdiation += (String.isNotBlank(contactObject.Nationality__c)
? ''
: (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Nationality');

accountValdiation += (String.isNotBlank(contactObject.MailingCountry)
? ''
: (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Country');

accountValdiation += (String.isNotBlank(contactObject.MailingCity)
? ''
: (String.isNotBlank(accountValdiation) ? +', ' : '') + 'City');

// accountValdiation += (String.isNotBlank(contactObject.MailingZipPostalCode__c)  ? '' : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'Mailing Zip/Postal Code');
}
}
}
}
*/
        return accountsFieldsValidationmtd(accountId) ;
    }
    
    /*
* Purpose : To validate Account / Person Account fields added in custom metadata(Validate fields)
* Created by : Ajay Thakur
*/
    public static String accountsFieldsValidationmtd(String accountId){ 
        
        String accountValdiation = '';
        try
        {
            
            //------fetch records with all the fields
            List<Account> accountRecList = queryAllFieldsWithExtraFields(new List<Id>{accountId});
            System.debug('***Account Record***'+accountRecList);
            //LAS-7 starts here by Nikhil Mehra
            User userObj = Utilities.getLoggedInUserDetail();
            Boolean isLSQ = userObj.Team__c == 'LSQ'? true : false;
            //LAS-7 ends here by Nikhil Mehra
            if(accountRecList!=null && accountRecList.size()>0){
                Map<String,List<ValidationFields__mdt>> validationFieldsMap = Utilities.getValidationFields();
                
                Account accountRec = accountRecList[0];
                //------Field validation for Person account type
                if(accountRec.RecordType.Name == Constants.PERSON_ACCOUNT_RT){
                    for(ValidationFields__mdt vf : validationFieldsMap.get('Account')){
                        if(vf.RecordType__c == 'Person'){
                            // System.debug('value '+(String) accountRec.get(vf.FieldAPI__c));
                            System.debug('vf.FieldAPI__c '+vf.FieldAPI__c);
                            System.debug('----'+accountRec.get(vf.FieldAPI__c));
                            Boolean isApplicable = checkApplicablefor(isLSQ,vf.ApplicableFor__c);//LAS-7 added here by Nikhil Mehra
                            //accountValdiation += (String.isNotBlank(String.valueOf( accountRec.get(vf.FieldAPI__c))) && isApplicable ? '': (String.isNotBlank(accountValdiation) ? +', ' : '') + vf.Label);//LAS-7 commented here by Nikhil Mehra
                            //LAS-7 starts here by Nikhil Mehra
                            if (!String.isNotBlank(String.valueOf(accountRec.get(vf.FieldAPI__c))) && isApplicable) {
                                if (String.isNotBlank(accountValdiation)) {
                                    accountValdiation += ', ';
                                }
                                accountValdiation += vf.Label;
                            }
                             //LAS-7 ends here by Nikhil Mehra
                            if(vf.Label == 'Resident Type' && vf.FieldAPI__c == 'NationalIdNumber__pc'){
                                if(String.isNotBlank((String.valueOf(accountRec.get(vf.FieldAPI__c)))) && String.valueOf(accountRec.get(vf.FieldAPI__c)) == 'Resident'){
                                    accountValdiation += (String.isNotBlank(accountRec.NationalIdNumber__pc)  ? ''  : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'National ID');
                                }
                            }
                          
                            
                            if(vf.Label == 'Resident Type' && vf.FieldAPI__c == 'ResidentStatus__pc'){
                                if(String.isNotBlank((String.valueOf(accountRec.get(vf.FieldAPI__c)))) && String.valueOf(accountRec.get(vf.FieldAPI__c)) == 'Resident'){
                                    accountValdiation += (String.isNotBlank(accountRec.EIDPlaceofissuance__c)  ? ''  : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'EID Place of issuance');
                                   accountValdiation += (accountRec.NationalIdExpiryDate__pc != null   ? '': (String.isNotBlank(accountValdiation) ? ', ' : '') + 'National Id Expiry Date');
                                   accountValdiation += (accountRec.NationalIDIssueDate__c != null   ? '': (String.isNotBlank(accountValdiation) ? ', ' : '') + 'National ID Issue Date');
                                }
                            }
                        }                    
                    }
                }
                //------Field validation for Organization account type
                else if(accountRec.RecordType.Name == Constants.ORGANISATION_ACCOUNT_RT){
                    List<Contact> contactList = accountRec.Contacts ;
                    System.debug('***Contact Records***'+contactList);
                    for(ValidationFields__mdt vf : validationFieldsMap.get('Account')){
                        if(vf.RecordType__c == 'Organization'){
                            Boolean isApplicable = checkApplicablefor(isLSQ,vf.ApplicableFor__c);//LAS-7 added here by Nikhil Mehra
                            //accountValdiation += (String.isNotBlank(String.valueOf( accountRec.get(vf.FieldAPI__c))) && isApplicable? '': (String.isNotBlank(accountValdiation) ? +', ' : '') + vf.Label);//LAS-7 commented here by Nikhil Mehra
                        	//LAS-7 starts here by Nikhil Mehra
                            if (!String.isNotBlank(String.valueOf(accountRec.get(vf.FieldAPI__c))) && isApplicable) {
                                if (String.isNotBlank(accountValdiation)) {
                                    accountValdiation += ', ';
                                }
                                accountValdiation += vf.Label;
                            }
                             //LAS-7 ends here by Nikhil Mehra
                        }                  
                    }
                    for (Contact contactObject : contactList) {
                        if (contactObject.PrimaryContact__c) {
                            for(ValidationFields__mdt vf : validationFieldsMap.get('Contact')){
                                if(vf.ObjectName__c == 'Contact'){
                                    accountValdiation += (String.isNotBlank(String.valueOf(contactObject.get(vf.FieldAPI__c))) ? '': (String.isNotBlank(accountValdiation) ? +', ' : '') + vf.Label);
                                    
                                    if(vf.Label == 'Resident Type'){
                                        if(String.isNotBlank(String.valueOf(contactObject.get(vf.FieldAPI__c))) && String.valueOf(contactObject.get(vf.FieldAPI__c)) == 'Resident'){
                                            accountValdiation += (String.isNotBlank(contactObject.NationalIdNumber__c)  ? ''  : (String.isNotBlank(accountValdiation) ? +', ' : '') + 'National ID');
                                        }
                                    }
                                    
                                }
                            }
                        }
                    }
                }
            }
            
            System.debug('accountValdiation '+accountValdiation); 
            
            return accountValdiation ;
        }
        catch(Exception e)
        {
            
            System.debug('msg '+e.getMessage());
            System.debug('line no '+e.getLineNumber());
            accountValdiation = 'Exception : Please Contact System Administrator '+e.getMessage();
            return accountValdiation ;
        }
        
        
    }
    //LAS-7 starts here by Nikhil Mehra
    private static Boolean checkApplicablefor(Boolean isLSQ,String applicableFor){
        Boolean isApplicable = false;
        if (isLSQ) {
            if (applicableFor == 'LSQ' || applicableFor == 'All') {
                isApplicable = true;
            }
        } else {
            if (applicableFor == 'Aldar' || applicableFor == 'All') {
                isApplicable = true;
            }
        }
        return isApplicable;
    }
    //LAS-7 ends here by Nikhil Mehra
    
    /*
* Update Unique Keys for list of Ids
*/
    public static List<Account> updateUniqueKeys(List<Account> newList){
        
        Map<String,List<String>> allUniqueKeysMap = UniqueKeyUtility.getUniqueKeyMappings();
        
        for(Account newAccount: newList){
            if((newAccount.Id != null && newAccount.isPersonAccount) || (newAccount.LastName != null) ) {
                newAccount.UniqueKey1__c = UniqueKeyUtility.getUniqueKey(newAccount, allUniqueKeysMap.get(Constants.ACCOUNT_UNIQUE_KEY_1));
                newAccount.UniqueKey2__c = UniqueKeyUtility.getUniqueKeyWithAllFields(newAccount, allUniqueKeysMap.get(Constants.ACCOUNT_UNIQUE_KEY_2));
                newAccount.UniqueKey__c = UniqueKeyUtility.getUniqueKey(newAccount, allUniqueKeysMap.get(Constants.ACCOUNT_UNIQUE_KEYS));
            }else{
                newAccount.UniqueKey1__c = UniqueKeyUtility.getUniqueKeyWithAllFields(newAccount, allUniqueKeysMap.get(Constants.CORPORATEACCOUNT_UNIQUE_KEY_1));
                newAccount.UniqueKey__c = UniqueKeyUtility.getUniqueKey(newAccount, allUniqueKeysMap.get(Constants.ORGANISATION_ACCOUNT_UNIQUE_KEY));
                if (newAccount.Email__c != null) {
                    // newAccount.PersonEmail = newAccount.Email__c;
                    newAccount.EmailAddress__c = newAccount.Email__c;
                }
                if (newAccount.MobileNumber__c != null) {
                    // newAccount.PersonMobilePhone = newAccount.MobileNumber__c;
                    newAccount.MobileNumberEnc__c = newAccount.MobileNumber__c;
                }
                                
            }
            System.debug('Unique 1 '+newAccount.UniqueKey1__c+' Unique 2 '+newAccount.UniqueKey2__c);
            
        }
        return newList ;
    }
    
    /*
* Fetch Accounts for Duplicate check
*/
    public static List<Account> queryAllFieldsForDuplicateAccounts(Set<String> uniqueKey1List,Set<String> uniqueKey2List,Id recordTypeId,Set<Id> accountIds) {
        
        Set<String> accountFieldList = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(accountFieldList);
        String fields = String.join(strList,',');
        String query = 'SELECT ' + fields + ' FROM Account WHERE (UniqueKey1__c IN : uniqueKey1List OR UniqueKey2__c IN: uniqueKey2List) AND RecordTypeId =:recordTypeId AND Id !=null AND Id NOT IN:accountIds AND ExistingAccount__c=null';
        
        List<Account> accounts = Database.Query(query);
        System.debug('**Exisiting Accounts**'+accounts.size());
        return accounts;
    }
    
    /*
*Fetch Account by Id
*/
    public static List<Account> fetchAccountById(Id accountId) {   
        
        
        Set<String> accFieldList = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(accFieldList);
        String fields = string.join(strList, ',');
        
        Set<String> conFieldList = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap().keySet();
        List<String> strConList = new List<String>();
        strConList.addAll(conFieldList);
        String conFields = string.join(strConList, ',');
        
        Set<String> arFieldList = Schema.getGlobalDescribe().get('AccountRelationship__c').getDescribe().fields.getMap().keySet();
        List<String> strARList = new List<String>();
        strARList.addAll(arFieldList);
        String arFields = string.join(strARList, ',');
        
        Set<String> docFieldList = Schema.getGlobalDescribe().get('Document__c').getDescribe().fields.getMap().keySet();
        List<String> strDocList = new List<String>();
        strDocList.addAll(docFieldList);
        String docFields = string.join(strDocList, ',');
        
        String query = 'SELECT ' + fields + ', (SELECT ' + conFields + ' FROM Contacts where PrimaryContact__c ='+true+'), (SELECT Account__r.Name, RelatedAccount__r.Name, ' + arFields + ' FROM AccountRelationships__r),(SELECT ' + docFields + ' FROM Documents__r ORDER BY DocumentType__c ASC) FROM Account WHERE Id =\'' + accountId + '\'';
        
        System.debug('***Account query***'+query);
        
        List<Account> accountData = Database.Query(query);
        System.debug('***Account Queried***'+accountData);
        
        
        return accountData;
        
    }
    /*
public static  List<Account> getChildAccountIds(Id parentAccountId){
return [SELECT Id from Account WHERE ParentId != NULL AND ParentId =:parentAccountId];
}*/
    
    
    /*Create Broker Account By ServiceRequest*/
    
    public static Account createBrokerAccount(HexaBPM__Service_Request__c sr, String brokerAccountStatus, Account newAccount) {
        // Updated by Moh Sarfaraj for BPM-481
        //Account newAccount = new Account();
        newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.BROKER_AGENCY_ACCOUNT_RT).getRecordTypeId();
        newAccount.OwnerId = sr.BrokerManager__c != null ? sr.BrokerManager__c : UserInfo.getUserId();
        newAccount.name = sr.AccountName__c;
        newAccount.EstablishmentDate__c = sr.EstablishmentDate__c;
        newAccount.RegistrationNumber__c = sr.TradeCommercialLicenseNumber__c;
        newAccount.RegistrationExpiryDate__c = sr.ExpiryDate__c;
        newAccount.MobileCountryCode__c = sr.PhoneNumber__c != null ? (sr.PhoneNumber__c.split(' ').size() > 1 ? sr.PhoneNumber__c.split(' ')[0] : ''): '';
        newAccount.Phone = sr.PhoneNumber__c != null ? (sr.PhoneNumber__c.replaceAll('(\\s+)', '')) : '';
        newAccount.Phone__c = sr.PhoneNumber__c != null ? (sr.PhoneNumber__c.replaceAll('(\\s+)', '')) : ''; 
        newAccount.PhoneNumberEnc__c =  sr.PhoneNumber__c != null ? (sr.PhoneNumber__c.replaceAll('(\\s+)', '')): '';
        newAccount.BillingStreet = sr.Address1__c +' - '+ sr.Address2__c;
        newAccount.BillingCountry = sr.Country__c;
        newAccount.BillingState = sr.State__c;
        newAccount.BillingCity = sr.City__c;
        newAccount.BillingPostalCode = sr.POBox__c;
        newAccount.Email__c = sr.CompanyEmail__c;
        //newAccount.UAEVATRegisterNumber__c = sr.TaxRegistrationNumber__c;
        newAccount.NameOfPOA__c = sr.NameOfPOA__c;
        //Added by Tharun for adding all Bank Details
        //newAccount.BankName__c = sr.BankName__c;
        //newAccount.IBANNumber__c = sr.IBANNumber__c;
        //newAccount.SwiftCode__c = sr.SwiftCode__c;
        //newAccount.BranchAddress__c = sr.BankAddress__c;
        //newAccount.BankAccountNumber__c = sr.BankAccountNumber__c;
        //newAccount.BankCountry__c = sr.BankCountry__c;
        //Added by Tharun for adding all Bank Details
        newAccount.Website = sr.Website__c;
        newAccount.AgencyStatus__c = brokerAccountStatus;
        newAccount.ServiceRequest__c = sr.Id;
        // Added By Moh Sarfaraj for BPE-322
        newAccount.InterestedPropertyLocation__c = sr.InterestedPropertyLocation__c;
        // Added By Moh Sarfaraj for BPM-357
        newAccount.FIABCIRegistered__c = sr.FIABCIRegistered__c;
        newAccount.FIABCIStatus__c = sr.FIABCIStatus__c;
        newAccount.SubAccountManager__c = sr.SubAccountManager__c;

        // Added By Moh Sarfaraj for BPM-550
        newAccount.AgencyCategory__c = sr.AgencyCategory__c;
        newAccount.AgencySubCategory__c = sr.AgencySubCategory__c;

        newAccount.TradeLicenseType__c = sr.TradeLicenseType__c;
        newAccount.ReferralSource__c = sr.ReferralSource__c;
        newAccount.TradeName__c = sr.TradeName__c;
        newAccount.TradingAddress__c = sr.TradingAddress__c;
        newAccount.OrganizationName__c = sr.OrganizationName__c; 
        
        if(sr.HexaBPM__Required_Docs_not_Uploaded__c == false){
            newAccount.AMLFlag__c = true;
        } 
        
        upsert newAccount;
        return newAccount;
    }
    
    
    /*
* Queries and returns a list of all the accounts for the given accountIds. All the fields are queried using a describe
* on the account.
*/
    public static List<Account> queryAllFieldsForAccountIds(List<Id> accountIds) {
        
        Set<String> accFieldList = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(accFieldList);
        String fields = string.join(strList,',');
        String accountIdsStr = String.join(accountIds, '\',\'');
        String query = 'SELECT ' + fields + ' FROM Account WHERE Id IN (\'' + accountIdsStr + '\')';
        System.debug('***Account query***'+query);
        List<Account> accounts = Database.Query(query);
        System.debug('***Account Queried***'+accounts);
        return accounts;
    }
    
    public static List<Account> queryAllFieldsWithExtraFields(List<Id> accountIds) {
        Set<String> accFieldList = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().keySet();
        List<String> strList = new List<String>();
        strList.addAll(accFieldList);
        String fields = string.join(strList,',');
        
        Set<String> conFieldList = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap().keySet();
        List<String> strConList = new List<String>();
        
        strConList.addAll(conFieldList);
        String conFields = string.join(strConList,',');
        
        String accountIdsStr = String.join(accountIds, '\',\'');
        String query = 'SELECT ' + fields + ' , CreatedBy.Email, Owner.Email, RecordType.Name, (SELECT ' + conFields + ' FROM Contacts) FROM Account WHERE Id IN (\'' + accountIdsStr + '\')';
        System.debug('***Account query***'+query);
        List<Account> accounts = Database.Query(query);
        System.debug('***Account Queried***'+accounts);
        return accounts;
    }
    
    public static String getAccountRecordTypeName(Id accountId){
        
        Account AccountDetails = [select RecordType.Name from Account WHERE Id =: accountId LIMIT 1];
        String recordTypeName=AccountDetails.RecordType.Name;
        return recordTypeName;
    }  
    
    /*get SAlesOrder Account*/
    @AuraEnabled(cacheable=true)
    public static List<Account> getAllSalesOrderAccountName(String salesOrderId){
        Set<Id> accountIds = new  Set<Id>();
        
        List<Account> accountNames=new List<Account>();
        if(salesOrderId != null){  
            for(JointOwner__c s: [SELECT Account__c from JointOwner__c WHERE  SalesOrder__c=:salesOrderId]){
                accountIds.add(s.Account__c);
                System.debug('joint own accountIds>>'+accountIds);
            }
            
            for(SalesOrder__c s: [SELECT Account__c from SalesOrder__c WHERE  Id=:salesOrderId]){
                accountIds.add(s.Account__c);
            }
            if(accountIds.size()>0  ) {   
                accountNames = [SELECT name from Account WHERE Id IN:accountIds];  
            }    
        }   
        return accountNames;
    } 
    
    /*
* Fetch list of Accounts based on the condition
*/
    public static List<Account> fetchAccounts(string whereCondition){
        
        List<Account> accountList= new List<Account>();
        
        try{
            String strQuery = 'Select Id,Name,CustomerType__c,CustomerSubType__c,PassportNumber__pc,Email__c,MobileNumber__c ,MobileNumberEnc__c,MobilePhone__pc,PersonEmail,ResidentStatus__pc,AccountNumber__c,VisaUIDNo__pc,NationalIdNumber__pc,RecordType.Name,(select id, Account__c,Account__r.Name, RelatedAccount__c,RelatedAccount__r.Name, RelationshipType__c from AccountRelationships__r), (SELECT Id, DocumentType__c,DocumentContentType__c,Status__c FROM Documents__r),(SELECT Id, ResidentStatus__c FROM Contacts WHERE PrimaryContact__c=true) FROM Account WHERE Id != null AND RecordType.Name!=\'Broker Agency\'';
            if(whereCondition != null && string.isNotEmpty(whereCondition)){
                strQuery += ' and ('+whereCondition+')';
            }
            strQuery += ' Order By Name ASC limit '+Utilities.getRecordCount('AppFetchRecordCount',Utilities.getRecordCount('AppMaxRecordCount',0));
            system.debug('--Account Query--'+strQuery);
            accountList = Database.query(strQuery);
            return accountList;
        }
        catch(Exception e){
            system.debug('*** Exception e***'+e.getMessage());
            throw e;
        }
    }
    
    /*
* Queries and returns a list of all the accounts 
*/
    public static List<Account> getAllAccounts(Map<String, String> mapFieldApiFieldValues){
        List<String> andConditions = new List<String>();
        if (mapFieldApiFieldValues == null)
            mapFieldApiFieldValues = new Map<String, String>();
        
        Utilities.objType = 'account';
        String whereConditionFromMap = Utilities.getWhereConditionfrmMap(mapFieldApiFieldValues);
        if (String.isNotBlank(whereConditionFromMap))
            andConditions.add(whereConditionFromMap);
        System.debug(whereConditionFromMap);
        String whereCondition = String.join(andConditions, ' AND ');
        
        System.debug('**Query**'+whereCondition);
        List<Account> accountList = fetchAccounts(whereCondition);
        return accountList ;
    }
    
    /*
public static void createAccountContactRelationship(Map<Id, Contact> contactsToShare){

List<AccountContactRelation> accoutContactRelationRecords = new List<AccountContactRelation>();

insertAccoutContactRelationRecords(contactsToShare.keySet());


}

@future
public static void insertAccoutContactRelationRecordsFuture(Set<Id> contactsToShare){
insertAccoutContactRelationRecords(contactsToShare);
}

public static void insertAccoutContactRelationRecords(Set<Id> contactsToShare){

List<AccountContactRelation> accoutContactRelationRecords = new List<AccountContactRelation>();

for (Contact contactRecord : [Select Id, AccountId, Account.ParentId From Contact Where Id in : contactsToShare]) {
AccountContactRelation record = new AccountContactRelation();
record.AccountId = contactRecord.Account.ParentId;
record.ContactId = contactRecord.Id;
record.IsActive = true;

accoutContactRelationRecords.add(record);
}

database.Insert(accoutContactRelationRecords, false);
//Insert accoutContactRelationRecords;
}

public static void deleteAccountContactRelationship(Set<Id> deletedParentAccountsIds,Set<Id> accountIds){

List<AccountContactRelation> accoutContactRelationRecords = [Select Id, AccountId, Contact.BrokerType__c, Contact.AccountId from AccountContactRelation Where Contact.BrokerType__c =: Constants.AGENCY_ADMIN AND AccountId In : deletedParentAccountsIds And Contact.AccountId in: accountIds];

delete accoutContactRelationRecords;
}
*/
    public static Map<Id, Account> getAccountsByParentId(set<Id> accountIdWithAgencyAdminUsers){
        
        Map<Id, Account> AccountsMap = new Map<Id, Account>([Select Id, ParentId From Account Where ParentId in : accountIdWithAgencyAdminUsers]);
        
        return AccountsMap;
    }
    
    public static void blockAgencyUsers(list<Account> lstAccount){
        for(Account accountObj : lstAccount){
            accountObj.AgencyStatus__c = Constants.UNIT_STATUS_BLOCKED; 
        }
        if(lstAccount !=null && !lstAccount.isEmpty()){
            update lstAccount ;
        }
    }
    
    public static void blockedAgencyUsersActions(list<Id> lstAccount, Boolean blockFlag){
        map<id,Account> accountMap= new map<id,Account>([select id from account where id in:lstAccount]);
        List<Contact> contactList = [select Id,AgentStatus__c from Contact WHERE AccountId IN :accountMap.KeySet()];
        
        system.debug(contactList);
        for (Contact contactRecord : contactList) {
            contactRecord.AgentStatus__c = blockFlag ? Constants.UNIT_STATUS_BLOCKED : Constants.ACTIVE;
        }
        system.debug('New contactList ------'+contactList);
        if(!contactList.isEmpty()){
            update contactList;
        }
        
        System.enqueueJob(new UserBlockHelper(accountMap.keySet()));
        
    }
    
    class UserBlockHelper implements Queueable,Database.AllowsCallouts {
        Set<Id> accountIds = new Set<Id>(); 
        
        public UserBlockHelper(set<Id> accIds){
            accountIds = accIds;
        }
        
        public void execute(QueueableContext context){
            map<String,Profile> profileNameMap = new map<String,Profile>();
            for(profile prof : [select id,Name from Profile where name in (:Constants.PARTNER_COMMUNITY_USER,:Constants.AGENCY_ADMIN_PROFILE,:Constants.AGENCY_USER_PROFILE,:Constants.PARTNER_COMMUNITY_USER_LOGIN,:Constants.AGENCY_ADMIN_PROFILE_LOGIN,:Constants.AGENCY_USER_PROFILE_LOGIN)]){
                profileNameMap.put(prof.name,prof);
            }
            system.debug('profileNameMap' + profileNameMap);
            map<ID,boolean> userIDToFreezeFlag = new map<ID,boolean>();
            list<user> userListToUpdate = new list<User>();
            
            for(User tempU:[select id,Profile.Name,Account.AgencyStatus__c from User where AccountID in :accountIds and isActive=true ]){
                if(tempU.Account.AgencyStatus__c == Constants.UNIT_STATUS_BLOCKED){
                    if(tempU.Profile.Name == Constants.AGENCY_USER_PROFILE || tempU.Profile.Name == Constants.AGENCY_USER_PROFILE_LOGIN){
                        userIDToFreezeFlag.put(tempU.Id,true);
                    }else if(tempU.Profile.Name == Constants.AGENCY_ADMIN_PROFILE || tempU.Profile.Name == Constants.AGENCY_ADMIN_PROFILE_LOGIN){
                        userListToUpdate.add(new user(id=tempU.Id, ProfileId= profileNameMap.get(Constants.PARTNER_COMMUNITY_USER_LOGIN).id));
                    }
                    
                }else if(tempU.Account.AgencyStatus__c  == Constants.ACTIVE){
                    if(tempU.Profile.Name == Constants.AGENCY_USER_PROFILE || tempU.Profile.Name == Constants.AGENCY_USER_PROFILE_LOGIN){
                        userIDToFreezeFlag.put(tempU.Id,false);
                    }else if(tempU.Profile.Name == Constants.PARTNER_COMMUNITY_USER || tempU.Profile.Name == Constants.PARTNER_COMMUNITY_USER_LOGIN){
                        userListToUpdate.add(new user(id=tempU.Id, ProfileId= profileNameMap.get(Constants.AGENCY_ADMIN_PROFILE_LOGIN).id));
                    }
                }
            }
            system.debug('userListToUpdate' + userListToUpdate);
            if(!userListToUpdate.isEmpty()){
                update userListToUpdate;
            }
            
            if(!userIDToFreezeFlag.isEmpty()){
                List<UserLogin> UserLoginRecords = [SELECT IsFrozen,UserId FROM UserLogin WHERE UserId IN :userIDToFreezeFlag.KeySet()];
                
                for (UserLogin ul : UserLoginRecords){ 
                    ul.isFrozen = userIDToFreezeFlag.get(ul.UserId);
                }
                update UserLoginRecords;
            }
        }
    }
    
    /*
* Method to fetch all the relationships
*/
    public static List<AccountRelationship__c> getRelatedAccountsForAccountId(Id accountId){
        List<AccountRelationship__c> allRelationships = new List<AccountRelationship__c>();
        allRelationships = [SELECT Id,Account__c,RelatedAccount__c,RelationshipType__c,RelatedAccount__r.Name FROM AccountRelationship__c WHERE Account__c=:accountId]; // AND RelatedAccount__r.AMLScreeningResult__c=:Constants.AML_SCREENING_RESULT
        return allRelationships;
    }
    
    //Start ASF-3309
    public static List<Account> getAllRelatedAccountsForSalesOrderId(Id SalesOrderId){
        Set<Id> accountIds =new Set<Id>();
        List<Account> relatedAccounts = new List<Account>();
        Id salesOrderAccountId;
        if(salesOrderId != null){  
            for(JointOwner__c s: [SELECT Account__c from JointOwner__c WHERE  SalesOrder__c=:salesOrderId]){
                accountIds.add(s.Account__c);
                System.debug('joint own accountIds>>'+accountIds);
            }
            
            for(SalesOrder__c s: [SELECT Account__c from SalesOrder__c WHERE  Id=:salesOrderId]){
                accountIds.add(s.Account__c);
                salesOrderAccountId = s.Account__c;
            }

            for(Sales_Order_Relationship__c s: [SELECT Account__c from Sales_Order_Relationship__c WHERE  SalesOrder__c =:salesOrderId And Customer_Account__c =:salesOrderAccountId 
                                                AND RecordType.DeveloperName = 'Third_Party']){
                 accountIds.add(s.Account__c);
            }

            if(accountIds.size()>0  ) {   
                relatedAccounts = [SELECT Id,Name from Account WHERE Id IN:accountIds];  
            }    
        }  
        return  relatedAccounts;
    }      
    //End ASF-3309    
    
    public static Map<String, List<DuplicateAccountWrapper>> findDuplicateAccountsByEmail(Set<String> emails) {
        /* if(System.Label.DuplicateAccountEnable.trim().toUpperCase() == 'FALSE'){
            return null;
        }*/
        
        Map<String, List<DuplicateAccountWrapper>> dupeWrapperMap = new Map<String, List<DuplicateAccountWrapper>>();
        
        String salesOrderWhrClause = ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ';
        String accountWhrClause = ' ( RecordType.Name = \'' + Constants.PERSON_ACCOUNT_RT + '\')';
        String query = 'SELECT Id, Name, PersonEmail,PassportNumber__pc,KYC_Validity_Status__c,ResidentStatus__pc, AccountNumber__c,CustomerType__c,CustomerSubType__c,NationalIdNumber__pc,EligibleForMerge__c,MasterAccount__r.Name,ERPID__c,MasterAccount__c, (SELECT Id,Name FROM Opportunity_Units__r WHERE '+salesOrderWhrClause+' ) FROM Account WHERE '+accountWhrClause+' AND PersonEmail IN :emails AND MergedAccount__c= false ORDER BY CreatedDate DESC';
        
        System.debug('Print acc query '+query);
        //Execute the query
        List<Account> queriedAccounts = Database.query(query);
        
        if(!queriedAccounts.isEmpty() && queriedAccounts.size() > 0){
            for(Account ac : queriedAccounts){
                DuplicateAccountWrapper wrapper = new DuplicateAccountWrapper();
                wrapper.account = ac;
                wrapper.salesOrderCount = ac.Opportunity_Units__r.size() > 1 ? ac.Opportunity_Units__r.size() : 0;
                
                if(dupeWrapperMap.containsKey(ac.PersonEmail)){
                    dupeWrapperMap.get(ac.PersonEmail).add(wrapper);
                }else{
                    List<DuplicateAccountWrapper> wrapperList = new List<DuplicateAccountWrapper>{wrapper};
                    dupeWrapperMap.put(ac.PersonEmail, wrapperList);
                }
            }
        }
        
        return dupeWrapperMap;
    }
    
    public class DuplicateAccountWrapper {
        @AuraEnabled
        public Account account{get;set;}
        @AuraEnabled
        public Integer salesOrderCount{get;set;}
    }
    @AuraEnabled(cacheable=true)
    public static  List<DuplicateAccountWrapper> getduplicateAccountList(String recordId){
        try {
            Id recroddataId = recordId;
            String emailid = '';
            String sObjName = recroddataId.getSObjectType().getDescribe().getName();
            if(sObjName == 'Case'){
                Case cs = [SELECT Id,Account.PersonEmail from Case WHERE Id =:recordId ];
                emailid = cs.Account.PersonEmail;
            }else{
                Account acc = [select Id,PersonEmail FROM Account WHERE Id=:recordId LIMIT 1];
                emailid = acc.PersonEmail;
            }
            Map<String,List<DuplicateAccountWrapper>> AccountMap = findDuplicateAccountsByEmail(new Set<String>{emailid});
            return AccountMap.get(emailid);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static void createMasterAccount(String selectedId){
        Account acc = [select Id,PersonEmail FROM Account WHERE Id=:selectedId];
        Map<String,List<DuplicateAccountWrapper>> AccountMap = findDuplicateAccountsByEmail(new Set<String>{acc.PersonEmail});
        List<Account> accList = new List<Account>();
        for(DuplicateAccountWrapper dp: AccountMap.get(acc.PersonEmail)){
            if(dp.account.Id != selectedId){
                Account accupdate = new Account();
                accupdate.Id = dp.account.Id;
                accupdate.DuplicateConfirmedBy__c = UserInfo.getUserId();
                accupdate.DuplicateConfirmedDate__c = System.today();
                accupdate.EligibleForMerge__c = true;
                accupdate.MasterAccount__c = selectedId;
                accList.add(accupdate);
            }
        }
        update accList;
    }
}