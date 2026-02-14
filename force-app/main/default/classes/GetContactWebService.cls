@RestResource (urlMapping = '/query/getContacts')
global with sharing class GetContactWebService {
    @HTTPPost
    global static void doPost(String phone){
        RestContextHandler handler = new RestContextHandler(false);  
        String query;
        String casequery;
        Integer actcount=0;
        Integer casecount=0;
        try{
            AccountDetailModel actdetailmodel = new AccountDetailModel();
            List<AccountDetail> actdetail = new List<AccountDetail>();
            
            query = 'select id,AccountNumber__c, LanguagePreference__pc, firstname, lastname, PersonEmail, CountryOfResidence__pc, IsNagwaCustomer__c, IsVIP__c, CustomerType__c, CustomerSubType__c, CustomerClass__c, VIPClass__c,Nationality__pc, (select id, Ownerid,Owner.Email, CaseNumber, Status, Type from cases where status<>\'Closed\') from account where (PersonMobilePhone=:phone or Phone=:phone)';
            casequery = 'select id, Ownerid,Owner.Email, CaseNumber, Status, Type from case where status<> \'Closed\' and (ContactMobile=:phone or ContactPhone=:phone or SuppliedPhone=:phone)';
            List<Account> accountlist = Database.Query(query);
            System.debug('***Accounts Queried***'+accountlist.size());

            for(Account a:accountlist){
                List<CaseDetail> cresponselist = new List<CaseDetail>();
                CaseDetailModel csdtlmodel = new CaseDetailModel();
                AccountDetail response = new AccountDetail();
                actcount++;
                response.actId=a.id;
                response.actnumber=a.AccountNumber__c;
                response.nationality = a.Nationality__pc;
                if(a.LanguagePreference__pc!=null){
                    response.langpref=a.LanguagePreference__pc;
                }
                if(a.firstname!=null){
                    response.fname=a.firstname;
                }
                if(a.lastname!=null){
                    response.lname=a.lastname;
                }
                if(a.PersonEmail!=null){
                    response.email=a.PersonEmail;
                }
                if(a.CountryOfResidence__pc!=null){
                    response.country=a.CountryOfResidence__pc;
                }
                
                response.isnagwa=a.IsNagwaCustomer__c;
                response.isvip=a.IsVIP__c;
                if(a.CustomerType__c!=null){
                    response.custtype=a.CustomerType__c;
                }
                if(a.CustomerSubType__c!=null){
                    response.cussubtype=a.CustomerSubType__c;
                }
                if(a.CustomerClass__c!=null){
                    response.custclass=a.CustomerClass__c;
                }
                if(a.VIPClass__c!=null){
                    response.vipclass=a.VIPClass__c;
                }
                
                
                casecount=0;
                for(Case c:a.cases){
                    CaseDetail cresponse = new CaseDetail();
                    casecount++;
                    cresponse.caseid=c.id;
                    cresponse.cownerid=c.OwnerId;
                    if(c.Owner.Email!=null){
                        cresponse.cemail=c.Owner.Email;
                    }                    
                    cresponse.casenum=c.CaseNumber;
                    if(c.Status!=null){
                        cresponse.cstatus=c.Status;
                    }
                    if(c.Type!=null){
                        cresponse.ctype=c.Type;
                    }
                    cresponselist.add(cresponse);
                }
                
                csdtlmodel.totalSizeCase=casecount;
                csdtlmodel.caseData=cresponselist;
                response.cases=csdtlmodel;
                //response.cases=csdtlmodel;
                actdetail.add(response);
            }

            actdetailmodel.totalSizeAct=actcount;
            actdetailmodel.actData=actdetail;


                
            
            handler.response.data = actdetailmodel;
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

    global class AccountDetailModel{
        public Integer totalSizeAct;
        public List<AccountDetail> actData;
        

        public AccountDetailModel(){
            this.totalSizeAct=0;
            this.actData = new List<AccountDetail>();
        }
    }

    global class AccountDetail{
        public Id actId ;
        public String actnumber;
        public String nationality;
        public String langpref ;
        public String fname;
        public String lname;
        public String email;
        public String country;
        public Boolean isnagwa;
        public Boolean isvip;
        public String custtype;
        public String cussubtype;
        public String custclass;
        public String vipclass;
        public CaseDetailModel cases;

        public AccountDetail(){
            this.actId=null;
            this.actnumber='';
            this.nationality ='';
            this.langpref='';
            this.fname='';
            this.lname='';
            this.email='';
            this.country='';
            this.isnagwa=false;
            this.isvip=false;
            this.custtype='';
            this.cussubtype='';
            this.custclass='';
            this.vipclass='';
            this.cases=new CaseDetailModel();
        }
    }

    global class CaseDetailModel{
        public Integer totalSizeCase;
        public List<CaseDetail> caseData;
    
        public CaseDetailModel(){
            this.totalSizeCase=0;
            this.caseData=new List<CaseDetail>();
        }
    }

    global class CaseDetail{
        public id caseid;
        public id cownerid;
        public String cemail;
        public String casenum;
        public String cstatus;
        public String ctype;

        public CaseDetail(){
            this.caseid=null;
            this.cownerid=null;
            this.cemail='';
            this.casenum='';
            this.cstatus='';
            this.ctype='';
        }
    }
}