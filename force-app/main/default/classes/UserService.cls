global with sharing class UserService {
        
    @AuraEnabled(cacheable=false)
    public static List<User> getUsersQuery(String query) {
        
        
        List<User> records = Database.query(query);
        
        List<User> finalUserList = new List<User>();
        finalUserList.addALL(records);
        
        Set<Id> managerIds = new Set<Id>();
        List<UserRole> usRoleNameList = [SELECT DeveloperName,Id,Name FROM UserRole WHERE Name = 'Head of Sales - CASA'];
       
        if(!usRoleNameList.isEmpty()){
            if(UserInfo.getUserRoleId() == usRoleNameList[0].Id){
                List<User> userList = [SELECT Id, Name, UserRole.Name, ManagerId FROM USER WHERE Manager.Manager.UserRoleId =: usRoleNameList[0].Id AND IsActive = true];
               
                for(User us: userList){
                    if(!finalUserList.contains(us)){
                        finalUserList.add(us);
                    }
                }
            }
        }
        return finalUserList;
    }

  @AuraEnabled(cacheable=false) 
  public static list<User> prepareUserId(String UserName){
      list<User> lstUserId = new list<User>();
      lstUserId.add([Select Id from User where Username =: UserName]);
      return lstUserId;
  }

  
  public static User getUserDetails(List<Id> contactId){
     
      User users = [Select Id,Name,Email,ContactId from User where ContactId IN: contactId];
      return users;
  }

  public static List<User> getUsersById(Set<Id> userIds){
    List<User> userList = new List<User>();
    userList = [Select Id,Name,Email,UserRoleId,RoleName__c,ProfileName__c from User where Id IN: userIds];
    return userList;
  }

  public static String getUserEmail(Id userIds){
  
    User  userEmail = [Select Email from User where Id =: userIds];
    String uEmail=userEmail.Email;
    return uEmail;
  }

  @AuraEnabled(cacheable=true)
  public static string getCurrentUserId(Id currentUserId){
    try {
      system.debug('userId>>'+currentUserId);
      User  userdetails = [select id,ContactId from user where id=:currentUserId];
      String uContactId=userdetails.ContactId;
      system.debug('contactId>>'+uContactId);
      return   uContactId;
      
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static User getUserDetailByEmail(String emailId){
    User userRecord = [Select Id,Name,Email,ContactId from User where Email =: emailId];
    return userRecord;
  }
  
  @InvocableMethod 
  public static void createPortalUserFromContact(CreateUser[] requests){
    UtilitiesWithoutSharing.createUserFromContact(requests[0].contactId, true, requests[0].profile);
  }

  global class CreateUser {
      @InvocableVariable(required=true)
      global String contactId;

      @InvocableVariable(required=true)
      global String profile;
  }

  public static List<User> getUsersByRoleName(String roleName){
    List<User> userList = new List<User>();
    userList = [Select Id,Name,Email,UserRoleId,RoleName__c,ProfileName__c,Team__c from User where RoleName__c=:roleName];
    return userList;
  }
}