@RestResource (urlMapping = '/query/getCases')
global with sharing class GetCasesWebService {
    @HTTPPost
    global static void doPost(String phone, String email){
        RestContextHandler handler = new RestContextHandler(false);  
        String query;
        Integer count=0;
        try{
            CaseDetailModel responsef = new CaseDetailModel();
            List<CaseDetail> responselist = new List<CaseDetail>();
            if(phone!=null && phone!=''){
                query = 'select id,CaseNumber,Status,OwnerId,Type,Description from case where (ContactMobile= :phone or ContactPhone=:phone or SuppliedPhone=:phone) limit 100';
            } else if(email!=null && email!=''){
                query = 'select id,CaseNumber,Status,OwnerId,Type,Description from case where (ContactEmail=:email or SuppliedEmail=:email) limit 100';
            }
            List<Case> caselist = Database.Query(query);
            System.debug('***Cases Queried***'+caselist.size());
            for(Case c:caselist){
                CaseDetail response = new CaseDetail();
                count++;
                response.caseId=c.id;
                if(c.CaseNumber!=null){
                    response.CaseNumber=c.CaseNumber;
                }
                if(c.Status!=null){
                    response.Status=c.Status;
                }
                response.OwnerId=c.OwnerId;
                if(c.Type!=null){
                    response.Type=c.Type;
                }
                if(c.Description!=null){
                    response.Description=c.Description;
                }
                responselist.add(response);
            }
            responsef.totalSize = count;
            responsef.casedetails = responselist;
            handler.response.data = responsef;
            handler.response.success = true;
            handler.finalize();
        }
        catch (DMLException exc) {
            handler.response.success    = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message    = exc.getDMLMessage(0);
            handler.finalize(exc);
        } catch (Exception ex) {
            System.debug('msg '+ex.getMessage());
            System.debug('line no '+ex.getLineNumber());
            handler.response.success    = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message    = Constants.MESSAGE_GENERIC_ERROR;
            handler.finalize(ex);            
        }
    }

    global class CaseDetailModel{

        public Integer totalSize;
        public List<CaseDetail> casedetails;

        public CaseDetailModel(){

            this.totalSize = 0;
            this.casedetails = new List<CaseDetail>();
        }
    }

    global class CaseDetail{
        public id caseId ;
        public String CaseNumber ;
        public String Status;
        public id OwnerId;
        public String Type ;
        public String Description ;

        public CaseDetail(){
            this.caseId =null;
            this.CaseNumber ='';
            this.Status='';
            this.OwnerId=null;
            this.Type='' ;
            this.Description ='';
        }
    }
}