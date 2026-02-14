public with sharing class DocumentValidationService {
    
    
    @InvocableMethod(label='KYC Validation' description='KYC Validation')
    public static List<String> documentInvocableMethod(List<Id> recordIds){
        Set<Id> Ids = new Set<Id>(recordIds);
        List<String> lst = new List<String>();
        String returnString = '';
        String objectName = recordIds[0].getSObjectType().getDescribe().getName();
        if(objectName == 'Account'){
            returnString = validateDocumentAccount(Ids);
        }
        if(objectName == 'DirectDebitRequest__c'){
            returnString = validateDocumentDebitRequest(Ids);
        }
        lst.add(returnString);
        return lst;
        
        //Set<Id> setAccountIds = new Set<Id>();
        /*Set<Id> eoiIdSet = new Set<Id>();
        Map<Id,Id> oeiToAccountMap = new Map<Id,Id>();
        for(Document__c doc : [SELECT ExpressionofInterest__c FROM Document__c WHERE Id IN: recordIds]){
            if(doc.ExpressionofInterest__c != null){
                eoiIdSet.add(doc.ExpressionofInterest__c);
            }
        }
        
        for(OpportunityEOI__c oei : [SELECT Account__c FROM OpportunityEOI__c WHERE Id IN: eoiIdSet]){
            if(oei.Account__c != null){
                oeiToAccountMap.put(oei.Id,oei.Account__c);
            }
        }*/
        
        /*for(Document__c doc : [SELECT Id,Account__c, DocumentType__c, ExpressionofInterest__c FROM Document__c WHERE Id IN: recordIds]){
            if(doc.DocumentType__c == Constants.DOCUMENT_TYPE_KYC && doc.Account__c != null){
                setAccountIds.add(doc.Account__c);
            }*/
            /*if(doc.DocumentType__c == Constants.DOCUMENT_TYPE_EOI && doc.ExpressionofInterest__c != null){
                System.debug('OEI Account'+  oeiToAccountMap.get(doc.ExpressionofInterest__c));
                if(oeiToAccountMap.containsKey(doc.ExpressionofInterest__c) && oeiToAccountMap.get(doc.ExpressionofInterest__c)!= null)
                    setAccountIds.add(oeiToAccountMap.get(doc.ExpressionofInterest__c));
            }*/
        //}
        
        /*if(!setAccountIds.isEmpty()){
            return new List<String>{validateDocumentAccount(setAccountIds)};
                }else{
                    return new List<String>();
                }*/
        
    }
    
    public static String validateDocumentAccount(Set<Id> recordIds){
        
        String validationString = ''; 
        Id recordId = new List<Id> (recordIds)[0];
        String objectName = recordId.getSObjectType().getDescribe().getName();
        
        SObject record = Database.query('SELECT RecordTypeId FROM ' + objectName + ' WHERE Id =: recordId LIMIT 1');
        Id recordTypeId = (Id)record.get('RecordTypeId');
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        String RECORD_TYPE_NAME = globalDescribe.get(objectName).getDescribe().getRecordTypeInfosById().get(recordTypeId).getDeveloperName();  		
        
        System.debug('RecType Name '+RECORD_TYPE_NAME);
        
        Set<String> accountFieldSet = globalDescribe.get('Account').getDescribe().fields.getMap().keySet();
        Set<String> contactFieldSet = globalDescribe.get('Contact').getDescribe().fields.getMap().keySet();
        
        List<String> accountFieldList = new List<String>(accountFieldSet);
        List<String> contactFieldList = new List<String>(contactFieldSet);
        List<Contact> contactList = new List<Contact>();
        String accountFields = String.join(accountFieldList,',');
        String contactFields = String.join(contactFieldList,',');
        String queryAccount = 'SELECT ' + accountFields + ' FROM Account WHERE Id IN: recordIds ';
        String queryContact = 'SELECT ' + contactFields + ' FROM Contact WHERE AccountId IN: recordIds ';
        List<Account> accountList = Database.Query(queryAccount);
        
        if(RECORD_TYPE_NAME == 'OrganizationAccount'){
            contactList = Database.Query(queryContact);
        }
        
        
        for(KYC_Mandatory_Field__mdt field : KYC_Mandatory_Field__mdt.getall().values()){
            if(field.Enable__c){
                if(RECORD_TYPE_NAME == 'OrganizationAccount' && contactList.isEmpty()) {
                    validationString = 'No Primary Contact assocaited with Account';
                    break;
                } else if(field.RecordType__c == RECORD_TYPE_NAME && field.ObjectName__c == 'Account') {
                    for(Account ac : accountList){
                        if(ac.ResidentStatus__pc == 'Non-Resident' && (field.FieldAPI__c == 'NationalIdNumber__pc' || field.FieldAPI__c == 'EIDPlaceofissuance__c' || field.FieldAPI__c == 'NationalIDIssueDate__c') && field.Applicable_Resident__c == 'Resident'){
                            break;
                        }
                        if(ac.SourceofFunds__c == 'Profits' && field.FieldAPI__c == 'OtherSourceofFunds__c'){
                            break;
                        }
                        
                        if(field.ApplicableEmploymentStatus__c != null && field.FieldAPI__c != null  ){
                            List<String> applicableEmploymentStatusLst = field.ApplicableEmploymentStatus__c.split(';');
                            if(ac.EmploymentStatus__pc != null && applicableEmploymentStatusLst.contains(ac.EmploymentStatus__pc)) {
                                if(ac.get(field.FieldAPI__c) != null){
                                    break;
                                } 
                            }else{
                                break;
                            } 
                        }
                        validationString += (ac.get(field.FieldAPI__c) != null ? '': (String.isNotBlank(validationString) ? +', ' : '') + field.Label);
                    }
                }
            }
        }
        return validationString;
    }
    
    public static String validateDocumentDebitRequest(Set<Id> recordIds){
        
        String validationString = ''; 
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Set<String> debitRequestFieldSet = globalDescribe.get('DirectDebitRequest__c').getDescribe().fields.getMap().keySet();        
        List<String> debitRequestFieldList = new List<String>(debitRequestFieldSet);
        String debitRequestFields = String.join(debitRequestFieldList,',');
        String queryDebitRequest = 'SELECT ' + debitRequestFields + ' FROM DirectDebitRequest__c WHERE Id IN: recordIds ';
        List<DirectDebitRequest__c> debitRequestList = Database.Query(queryDebitRequest);
        
        for(KYC_Mandatory_Field__mdt field : KYC_Mandatory_Field__mdt.getall().values()){
            if(field.Enable__c){
                  if(field.ObjectName__c == 'DirectDebitRequest__c') {
                    for(DirectDebitRequest__c dr : debitRequestList){
                        validationString += (dr.get(field.FieldAPI__c) != null ? '': (String.isNotBlank(validationString) ? +', ' : '') + field.Label);
                    }
                }
            }
        }
        return validationString;
    }
}