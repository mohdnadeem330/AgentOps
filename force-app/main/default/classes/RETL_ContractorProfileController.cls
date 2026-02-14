public without sharing class RETL_ContractorProfileController {
    @AuraEnabled
    public static map<string,string> validateMobileNumber(string mobNo){
        if(mobNo != null){
            map<string,string> res = MobileNumberValidation.validatePhoneNo(new list<string>{mobNo});
            return res;
        }else{
            return null;
        }         
    } 
	 @AuraEnabled
    public static void updateContact(Contact con, RETL_Contact_role__c conRole){
        try{
            if( con != null){
                Update con;        
                User u = new User();
                u.Id = UserInfo.getUserId();
                u.LastName = con.LastName;
                u.FirstName= con.FirstName;
                u.MobilePhone= con.MobilePhone;
                Update u;
            }
            
            if( conRole != null){
                conRole.Name = conRole.RETL_Contact_role__c;
                update conRole;
            }
                }catch(Exception e){
            throw new AuraHandledException(e.getMessage());    
        }
    }
    
     @AuraEnabled
    public static List<Contact> getRelatedContacts(String accountId, String contactId){
        List<Contact> contacts = [ Select Id,Name, MobilePhone, Email, Account.Name, Title, (Select Id, RETL_Contact_role__c From Contact_roles__r ) from Contact where AccountId =: accountId and Id !=: contactId];
        return contacts;
    }
    
    @AuraEnabled
    public static void createContact(Contact con, RETL_Contact_role__c conRole) { 
        con.recordTypeId= Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contractor').getRecordTypeId();
        con.Is_Portal_Register_User__c=true;
        list<contact> conlist = [select id from Contact where email=:con.email AND recordtypeId=:con.recordTypeId];
        if(conlist.size()>0){
            throw new AuraHandledException('Email already registered.');
        }else{
            try {
                insert con;
                if( con.Id != null && conRole != null){
                    conRole.RETL_Contact__c = con.Id;
                    insert conRole;
                }
            } catch (DmlException e) {
                throw new AuraHandledException(e.getMessage());
            }
        }     
    }
}