public without sharing class BrokerAgentsWithoutSharingController {
    

    @AuraEnabled
    public static void updateContactAgentStatus(String userId,String checkboxVal){

        System.debug('checkboxVal: '+checkboxVal);
        Contact con = new Contact(Id= userId);

        if(checkboxVal == 'Active'){
            con.AgentStatus__c='In Active'; 
        }else{
            con.AgentStatus__c='Active';
        }
        update con;
    }

    @AuraEnabled
    public static void updateUserAgentStatus(String userId,String checkboxVal){

        System.debug('checkboxVal: '+checkboxVal);
        User user = new User(Id= userId);

        if(checkboxVal == 'Active'){
            user.IsActive = false; 
        }else{
            user.IsActive = true;
        }
        update user;
    }


}