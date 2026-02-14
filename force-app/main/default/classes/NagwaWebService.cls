@RestResource (urlMapping = '/query/VerifyNagwa')
global with sharing class NagwaWebService {
    @HTTPPost
    global static void doPost(String phone){
        RestContextHandler handler = new RestContextHandler(false);  
        String query;
        Integer count=0;
        try{
            List<NagwaDetailModel> responselist = new List<NagwaDetailModel>();
            NagwaDetail responselistf = new NagwaDetail();
            if(phone!=null){
                query = 'select AccountNumber__c, isnagwacustomer__c from account where PersonMobilePhone=:phone';
                List<Account> accountlist = Database.Query(query);
                System.debug('***Account Queried***'+accountlist.size());
                for(Account a:accountlist){
                    NagwaDetailModel response = new NagwaDetailModel();
                    response.actnumber=a.AccountNumber__c;
                    response.isnagwa=a.isnagwacustomer__c;
                    count++;
                    responselist.add(response);
                    
                }
                //NagwaDetail responselistf = new NagwaDetail();
                responselistf.totalSize=count;
                responselistf.accDetails=responselist;


            }
           // String countstr = String.valueOf(count);
            //handler.addResponseHeader('count',countstr);
            handler.response.data = responselistf;
            handler.response.success = true;
            //handler.response.count = count;
            handler.finalize();
        }
        catch (DMLException exc) {
            handler.response.success    = false; handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message    = exc.getDMLMessage(0); handler.finalize(exc);
        } catch (Exception ex) {
            System.debug('msg '+ex.getMessage());
            System.debug('line no '+ex.getLineNumber());
            handler.response.success    = false;  handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message    = Constants.MESSAGE_GENERIC_ERROR; handler.finalize(ex);            
        }
    }

    global class NagwaDetail{
        public Integer totalSize;
        public List<NagwaDetailModel> accDetails;
        //public Id actid ;
        //public Boolean isnagwa ;

        public NagwaDetail(){
            this.totalSize=0;
            this.accDetails=new List<NagwaDetailModel>();
            //this.actid =null;
            //this.isnagwa =false;
        }
    }

    global class NagwaDetailModel{
        public String actnumber;
        public Boolean isnagwa;

        public NagwaDetailModel(){
            this.actnumber=null;
            this.isnagwa=false;
        }
    }
}