@RestResource (urlMapping = '/customer/createJointOwner')
global without sharing class CustomerCreateJointOwnerWebService {
    
    @HttpPost
    global static void createAccount() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
             RestRequest req = RestContext.request;
        	 String requestBody = req.requestBody.toString();
        
            handler.response.data = createliveinAccount(requestBody);
            handler.response.success = true;
            handler.finalize();
        }catch(Exception ex){
             System.debug('Ex'+ex.getLineNumber());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
    }
    public static accountData createliveinAccount(String requestBody){
         // Deserialize JSON to the RequestWrapper object
        RequestWrapper data = (RequestWrapper) JSON.deserialize(requestBody, RequestWrapper.class);
        
        List<AccountRelationship__c> accRelLiist = [SELECT Id from AccountRelationship__c WHERE Account__c=:data.customerId];
        Integer COunt = 0;
        COunt = accRelLiist.size() +data.JointOwnerList.size();
        if(accRelLiist.size() >=3 || data.JointOwnerList.size() >3 || COunt >3){
            accountData acco = new accountData();
            acco.Message ='You can add upto 3 JointOwners Only.';
            return acco;
        }
        Set<String> EmailSet = new Set<String>();
        Set<String> phoneNoSet = new Set<String>();
        for(JointOwner jo :data.JointOwnerList){
            EmailSet.add(jo.email);
        	phoneNoSet.add(jo.phone);
        }
       
        Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>> accountEmailPhoneMap = new Map<String, List<UtilitiesWithoutSharing.DuplicateAccountWrapper>>();
        accountEmailPhoneMap = UtilitiesWithoutSharing.findDuplicateAccountsByEmail(EmailSet);
        List<AccountRelationship__c> acrelList = new List<AccountRelationship__c>();
        for(JointOwner jo:data.JointOwnerList){
            String emailPhoneKey = jo.email;
            if(accountEmailPhoneMap != null && accountEmailPhoneMap.containsKey(emailPhoneKey) && accountEmailPhoneMap.get(emailPhoneKey) != null ){
                Account acc = new Account();
                acc.IsJointOwnerRegistration__c = true;
                acc.Id = accountEmailPhoneMap.get(emailPhoneKey)[0].account.Id;
                update acc;
                AccountRelationship__c acr = new AccountRelationship__c();
                acr.Account__c = data.customerId;
                acr.RelatedAccount__c = accountEmailPhoneMap.get(emailPhoneKey)[0].account.Id;
                acr.RelationshipType__c ='Joint Owner P-P';
                acr.RelationshipSubType__c =jo.relationship;
               	acrelList.add(acr);
                /*Communication_Preference__c cp = new Communication_Preference__c();
                cp.Status__c = 'Link Sent';
                cp.Account__c = accountEmailPhoneMap.get(emailPhoneKey)[0].account.Id;
                cp.Active__c = true;
                cp.Category__c ='FastTrack';
                insert cp;
                accountData acco = new accountData();
                acco.CustomerId =  data.customerId;
                acco.JointOwner = accountEmailPhoneMap.get(emailPhoneKey)[0].account.Id;
                return acco;*/
                
            }else{
                Account acc = new Account();
                acc.personEmail = jo.email;
                acc.MobilePhone__pc = jo.phone;
                acc.MobileCountryCode__pc = jo.countrycode;
                acc.FirstName = jo.firstname;
                acc.LastName = jo.lastname;
                acc.IsJointOwnerRegistration__c = true;
                insert acc;
                AccountRelationship__c acr = new AccountRelationship__c();
                acr.Account__c = data.customerId;
                acr.RelatedAccount__c = acc.Id;
                acr.RelationshipType__c ='Joint Owner P-P';
                acr.RelationshipSubType__c =jo.relationship;
               	acrelList.add(acr);
                /*Communication_Preference__c cp = new Communication_Preference__c();
                cp.Status__c = 'Link Sent';
                cp.Account__c = acc.Id;
                cp.Active__c = true;
                cp.Category__c ='NOC-FastTrack';
                insert cp;
                accountData acco = new accountData();
                acco.CustomerId =  mapFieldApiFieldValues.get('customerId');
                acco.JointOwner = acc.Id;
                return acco;*/
            }
        }
        
        if(!acrelList.isEmpty()){
            insert acrelList;
        }
        List<Communication_Preference__c> CpList = new List<Communication_Preference__c>();
        accountData acco = new accountData();
         List<String>strList =new List<String>();
        for(AccountRelationship__c acr :[SELECT Id,Name,RelatedAccount__c FROM AccountRelationship__c WHERE Id =:acrelList]){
            Communication_Preference__c cp = new Communication_Preference__c();
            cp.Status__c = 'Link Sent';
            cp.Account__c = acr.RelatedAccount__c;
            cp.Active__c = true;
            cp.Category__c ='FastTrack';
            CpList.add(cp);
            
           
            strList.add(acr.Id);
        }
        if(!CpList.isEmpty()){
            insert CpList;
        }
        acco.JointOwner = strList;
        acco.CustomerId = data.CustomerId;
        return acco;
        
        
    }
     public class accountData{
        public String CustomerId;
        public List<String> JointOwner;
         public String Message;
	}
    public class JointOwner {
    public String firstname;
    public String lastname;
    public String email;
    public String phone;
    public String countrycode;
    public String relationship;
	}

public class RequestWrapper {
    public String customerId;
    public List<JointOwner> JointOwnerList;
    
}
}