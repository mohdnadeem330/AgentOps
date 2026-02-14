public class AccountAction {
  @InvocableMethod(label='Create Case through future method' description='create case if account email is duplicate' category='Account')
  public static void  createCase(List<ID> ids) {
      try{
     Account accountData = [select id,PersonEmail from Account where id =: ids[0]];
     Case cs = CustomerProfileWebservice.createCaseHelper(new List<Account>{accountData}, true);
     cs.Origin ='Chat';
     cs.Subject = 'Account has been duplicated - Action on Account';
     insert cs;
      }catch(Exception ex){
          LoggerService.save(LoggerService.addApexLog(ex,'AccountAction','createCase',ids[0]));
      }
  }
  
}