public with sharing class SetNewPassword {
    
    @InvocableMethod( label='generatePassword')
    public static  void  calFutureMethod(List<Id> recordId) {
        try{  
            setNewPasswordMethod(recordId);
        }catch(Exception e){
            System.debug('Exception>>>>>>>'+ e);
        }
    }
    
    @future
    public static  void  setNewPasswordMethod(List<Id> recordId){
        String newPassword;

        User users=UserService.getUserDetails(recordId);
        Id userId= users.Id;
        String userEmail= users.Email;
        String usrFullName=users.Name;

        newPassword ='Ad'+Utilities.getRandomNumber(8);

        System.setPassword(userId,newPassword );
        sendEmail(userEmail,usrFullName,newPassword);
}


    public static  void  sendEmail(string userEmail,string userFullName,string newPassword){
    
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        List<String> toAddresses = new    List<String>();
        toAddresses.add(userEmail);
        
        
        mail.setToAddresses(toAddresses);
        mail.setOrgWideEmailAddressId(Utilities.getOrgWideEmailAddressId());
        
        // String orgWidedisplayName = Constants.DISPLAY_NAME;

        // OrgWideEmailAddress orgWideRecords=Utilities.getOrgWideEmailAddressId();
        // string getAddress=orgWideRecords.Address;

        // if( getAddress != null){
        
        // }
    
        mail.setSubject('New Password to login to Aldar' );
        
        mail.setPlainTextBody('Dear' + ' ' +  userFullName  + ', \n \n' + 'Please note that your password has been regenerated. Your new password to login to Aldar broker portal: '  + newPassword + '\n\n' + 'Thank You\n' + 'Aldar Properties'  );
        
        if(!Test.isRunningTest())
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
            
    }

}