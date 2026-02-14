@RestResource (urlMapping = '/upsert/opportunity')
global without sharing class OpportunityCreateWebService {
   
    @HttpPost
    global static void doPost(Opportunity opp, Account account,Contact contactRec,Boolean isPersonAccount) {
        RestContextHandler handler = new RestContextHandler(true);
        Savepoint savePoint = null;
        try {
            savePoint = Database.setSavepoint();

            Account parentAccount = null ;
            //----- When the service is invoked for opportunity is updated
            if(account != null){
                //----- Create or Update Account record
                if(account.Id == null){
                    if(isPersonAccount)
                        account.RecordTypeId = Constants.PERSON_RECORD_TYPE_ID ;
                    else
                        account.RecordTypeId = Constants.ORGANIZATION_RECORD_TYPE_ID ;
                }else {
                    if(isPersonAccount){
                        if(account.MobileCountryCode__pc == '' || account.MobilePhone__pc == ''  || account.PersonEmail== ''|| Test.isRunningTest()){
                                throw new Exceptions.InsufficientAccessException() ;
                        }
                    }
                 }
                Upsert account;
                parentAccount = account; 
                //parentAccount = AccountMergeUtility.upsertAccount(account);
                System.debug('**Account Record**'+parentAccount);
            }
            
            //---- When the service is invoked only for account created
            if(opp!=null){

                //----- Associated new/existing account with Opportunity
                if(parentAccount!=null)
                    opp.AccountId = parentAccount.Id ;

                //----- Create a Lead and convert it if Opp.Id doesn't exists
                if(opp.Id == null){
                    Map<String,Map<String,String>> objectNameobjectLeadAPI = getLeadConversionMapping(isPersonAccount);
                    Lead newLead = new Lead();
                    newLead.ExistingAccount__c = parentAccount.Id ; 
                    newLead.CountryOfResidence__c = account.CountryOfResidence__pc;
                    newLead.ResidentStatus__c = account.ResidentStatus__pc;
                    Map<String,String> leadAPIAccountAPI = objectNameobjectLeadAPI.get('Account');
                    for(String fieldAPI : leadAPIAccountAPI.keySet()){
                        Object accountValue =  account.get(fieldAPI);
                        if(accountValue !=null)
                            newLead.put(leadAPIAccountAPI.get(fieldAPI),accountValue);
                    }

                    if(!isPersonAccount){
                        Map<String,String> leadAPIContactAPI = objectNameobjectLeadAPI.get('Contact');
                        System.debug(leadAPIContactAPI+'**Contact Field**');
                        for(String fieldAPI : leadAPIContactAPI.keySet()){
                            Object contactValue =  contactRec.get(fieldAPI);
                            if(contactValue !=null)
                                newLead.put(leadAPIContactAPI.get(fieldAPI),contactValue);
                        }
                    }  

                    Map<String,String> leadAPIOpportunityAPI = objectNameobjectLeadAPI.get('Opportunity');
                    for(String fieldAPI : leadAPIOpportunityAPI.keySet()){
                        String opportunityValue = String.valueof(opp.get(fieldAPI));
                        if(String.isNotBlank(opportunityValue))
                            newLead.put(leadAPIOpportunityAPI.get(fieldAPI),opportunityValue);
                    }

                    System.debug(newLead+'**Lead Record**'+newLead.FirstName);
                    insert newLead ;

                    list<Database.LeadConvertResult> convertedLeadResult = UtilitiesWithoutSharing.convertLeads(new set<id>{newLead.Id});

                    for (Database.LeadConvertResult leadConverted: convertedLeadResult) {
                            opp.Id = leadConverted.getOpportunityId();
                            contactRec.Id = leadConverted.getContactId();
                    }
                
                }
                update opp ;
                handler.response.data = opp;
            }
            else{
                handler.response.data = account;
            }
            if(isPersonAccount!=null && !isPersonAccount && contactRec !=null){
                System.debug('***contactRec***'+contactRec);
                contactRec.AccountId = parentAccount.Id ;
                contactRec.PrimaryContact__c = true ;
                upsert contactRec ;
            }

            handler.response.success = true;
            handler.finalize();
        }catch (DMLException exc) {
            Database.rollback(savePoint);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
             if(isPersonAccount){
                // Get duplciate account based emirated id and passport
                List<Account> lstAcc = new List<Account>();
                if(account.ResidentStatus__pc == 'Resident' && Label.AccountDuplicationEnabled == 'true'){
                    lstAcc = UseExistingAccount.getAccount(account.Id,account.NationalIdNumber__pc,'','',null);
                } else if(account.ResidentStatus__pc == 'Non-Resident' && Label.AccountDuplicationEnabled == 'true'){
                    lstAcc = UseExistingAccount.getAccount(account.Id,'',account.PassportNumber__pc,account.Nationality__pc,account.PersonBirthdate);
                }
                if(!lstAcc.isEmpty()){
                    handler.response.data = new OpportunityWrapper(account,lstAcc,true);
                }
                
            }
            handler.finalize(exc);
        }
         catch(Exceptions.InsufficientAccessException exAccess){
             Database.rollback(savePoint);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = 'Email or phone missing on account. Please update contact details to proceed.';
            handler.finalize(exAccess);
        }
        catch (Exception exc) {
            Database.rollback(savePoint);
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(exc);
        }
    }

    public static Map<String,Map<String,String>> getLeadConversionMapping(Boolean isPersonAccount){
    
        //------ Object Name mapped with object api and lead api
        Map<String,Map<String,String>> objectNameobjectLeadAPI = new Map<String,Map<String,String>>();

        List<LeadFieldMapping__mdt> leadFieldMetadata = [Select LeadAPI__c,sObjectAPI__c,sObjectName__c FROM LeadFieldMapping__mdt Order By sObjectName__c];

        for(LeadFieldMapping__mdt leadField : [Select LeadAPI__c,sObjectAPI__c,sObjectName__c,IsPersonAccountFieldOnly__c FROM LeadFieldMapping__mdt Order By sObjectName__c]){
            Map<String,String> objectAPILeadAPI = new Map<String,String>();
            if(leadField.IsPersonAccountFieldOnly__c && !isPersonAccount){
                continue ;
            }
            String objectName = leadField.sObjectName__c ;
            if(objectNameobjectLeadAPI !=null && objectNameobjectLeadAPI.containsKey(objectName))
                objectAPILeadAPI = objectNameobjectLeadAPI.get(objectName) ;
            objectAPILeadAPI.put(leadField.sObjectAPI__c,leadField.LeadAPI__c);
            objectNameobjectLeadAPI.put(objectName,objectAPILeadAPI);
        }

        return objectNameobjectLeadAPI ;

    }
    public class OpportunityWrapper{

        Account account;

        List<Account> duplicateAccounts;

        Boolean hasDuplicates;

        public OpportunityWrapper(Account account, List<Account> duplicateAccounts, Boolean hasDuplicates){

            this.account = account;

            this.duplicateAccounts = duplicateAccounts;

            this.hasDuplicates = hasDuplicates;

        }

    }

}