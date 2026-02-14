@RestResource (urlMapping = '/query/VerifyVIP')
global class ECSSGenesysWebService {

    @HTTPPost
    global static void doPost(String phone){
        RestContextHandler handler = new RestContextHandler(false);  
        String query;
        Integer count=0;
        try{
            List<GenesysDetailModel> responselist = new List<GenesysDetailModel>();
            GenesysDetail responselistf = new GenesysDetail();
            if(phone!=null){
                query = 'select AccountNumber__c, ECSS_VIP__c from account where PersonMobilePhone=:phone';
                List<Account> accountlist = Database.Query(query);
                System.debug('***Account Queried***'+accountlist.size());
                for(Account a:accountlist){
                    GenesysDetailModel response = new GenesysDetailModel();
                    response.actnumber=a.AccountNumber__c;
                    response.isVIP=a.ECSS_VIP__c;
                    count++;
                    responselist.add(response);
                    
                }
                responselistf.totalSize=count;
                responselistf.accDetails=responselist;


            }
            handler.response.data = responselistf;
            handler.response.success = true;
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

    global class GenesysDetail{
        public Integer totalSize;
        public List<GenesysDetailModel> accDetails;

        public GenesysDetail(){
            this.totalSize=0;
            this.accDetails=new List<GenesysDetailModel>();
        }
    }

    global class GenesysDetailModel{
        public String actnumber;
        public Boolean isVIP;

        public GenesysDetailModel(){
            this.actnumber=null;
            this.isVIP=false;
        }
    }
}