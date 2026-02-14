@RestResource (urlMapping = '/customer/agents')
global without sharing class CustomerSalesManagersWebService {
    
    @HttpPost
    global static void getSalesManagersData() {
        RestContextHandler handler = new RestContextHandler(false);
        try {
             Map<String,String> mapFieldApiFieldValues = handler.getRequestBodyMap();
            Map<String, Object> responseData = new Map<String, Object>(); 
           	String CustomerId =  mapFieldApiFieldValues.get('customerId');
            handler.response.data = getSalesManagers(customerId);
            handler.response.success = true;
            handler.finalize();
        }catch(Exception ex){
             System.debug('Ex'+ex.getLineNumber());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);
        }
    }
    public static List<UserWrapper> getSalesManagers(String CustomerId){
        List<User> salesManagers = [SELECT Id,Name,Email FROM User WHERE Profile.Name = 'Sales Manager' And IsActive=true ORDER BY Name ASC];
        List<UserWrapper> usWrapperList = new List<UserWrapper>();
        for(User us:salesManagers){
            UserWrapper uswp = new UserWrapper();
            uswp.userId = us.Id;
            uswp.name = us.Name;
            uswp.Email = us.Email;
            usWrapperList.add(uswp);
        }
        return usWrapperList;
    }
    public class UserWrapper{
        public String userId;
        public String name;
        public String Email;
    }
}