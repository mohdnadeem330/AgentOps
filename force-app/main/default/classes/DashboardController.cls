/**********************************************************************************************************************
* Name               : DashboardController                                                        
* Description        : Class to provide helper methods for the Dashboard.
* Usage              : Agency and Agent Dashboard LWC                                                          
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/06/2022      Initial Draft       
******************************************************************************************************************/
public with sharing class DashboardController {
    /**
    * getMyCommunication
    *
    * This method used to return all logged in user related communication records
    *
    * @param  none
    * @return list of logged in user related Communication__c 
    */
    @AuraEnabled(cacheable=true)
    public static list<Communication__c> getMyCommunication(){
        return [select id,CommunicationTemplate__r.Title__c,CommunicationTemplate__r.PlainTextBody__c,lastModifiedDate from Communication__c where Recipient__c = :userInfo.getUserId() and isPublished__c=true WITH SECURITY_ENFORCED  order by lastModifiedDate desc];
        
    }

    /**
    * getAgentDashboardDetails
    *
    * This method used to agent related Dashboard details
    *
    * @param  none
    * @return DashboardDetails wrapper class
    */
    @AuraEnabled
    public static DashboardDetails getAgentDashboardDetails(Date startDate, Date endDate){
        string dateFilter='';
        if(startDate!=null){
            string timeUserContext = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).formatGMT('yyyy-MM-dd\'T\'hh:mm:ss\'z\'');
            dateFilter= ' and ( (OriginalCreationDate__c != null and OriginalCreationDate__c >= '+timeUserContext+' ) or (OriginalCreationDate__c = null and createdDate >= '+timeUserContext+') )';
            //dateFilter= ' and createdDate >= :startDate';
        }
        if(endDate!=null){
            string timeUserContext = DateTime.newInstance(endDate.year(), endDate.month(), endDate.day()).formatGMT('yyyy-MM-dd\'T\'hh:mm:ss\'z\'');
            dateFilter+= ' and ( (OriginalCreationDate__c != null and OriginalCreationDate__c <= '+timeUserContext+' ) or (OriginalCreationDate__c = null and createdDate <= '+timeUserContext+') )';
            //dateFilter+= ' and createdDate <= :endDate';
        }

        DashboardDetails valsToReturn = new DashboardDetails();
        User currentUserDetails = Utilities.getLoggedInUserDetail();
        valsToReturn.userName = currentUserDetails.Name;
        valsToReturn.agentId = currentUserDetails.Contact.AgentID__c;
        Set<Id> contactIdSet = new Set<Id>{currentUserDetails.ContactId};

        Integer currentHour=Datetime.now().hour();
        valsToReturn.greetings= (currentHour<12)?'Morning': (currentHour<17?'Afternoon':'Evening') ;
      //   Integer openLeads=[select count() from lead where BrokerAgent__c = :currentUserDetails.ContactId and isConverted=false and status != :Constants.DUPLICATE_LEAD and status != :Constants.RETIRED and status !=:Constants.CONVERTED_LEAD WITH SECURITY_ENFORCED];
        Integer openLeads=database.countQuery('select count() from lead where BrokerAgent__c in :contactIdSet and isConverted=false and status != \'' +Constants.DUPLICATE_LEAD+'\' and status != \''+Constants.RETIRED+'\' and status != \''+Constants.CONVERTED_LEAD+'\'' + dateFilter +' WITH SECURITY_ENFORCED');

      //  Integer openOpportunity=[select count() from Opportunity where BrokerAgentContact__c = :currentUserDetails.ContactId and isclosed=false];
        Integer openOpportunity=database.countQuery('select count() from Opportunity where BrokerAgentContact__c in :contactIdSet and isclosed=false' + dateFilter);

      //  list<SalesOrder__c> salesOrderList = [select id,NetAmount__c,Status__c from SalesOrder__c where Opportunity__r.BrokerAgentContact__c = :currentUserDetails.ContactId and Status__c in( :Constants.UNIT_STATUS_SOLD, :Constants.SALES_STATUS,:Constants.OPPO_UNIT_STATUS_PENDING) WITH SECURITY_ENFORCED];
        list<SalesOrder__c> salesOrderList = database.Query('select id,NetAmount__c,Status__c,ProjectName__c,BookingDate__c from SalesOrder__c where Opportunity__r.BrokerAgentContact__c IN :contactIdSet and Status__c in (\''+Constants.UNIT_STATUS_SOLD+'\' ) '+dateFilter );
        system.debug('salesOrderList::'+salesOrderList);
        Decimal totalSum=0;
        Integer soldUnitCOunt=0;
        for(SalesOrder__c tempSO : salesOrderList){
            if(tempSO.Status__c== Constants.UNIT_STATUS_SOLD){
                soldUnitCOunt++;
            }
            if(tempSO.NetAmount__c!=null)
            totalSum = totalSum + tempSO.NetAmount__c;
        } 
        String totalSumString=getShortStringValue(totalSum);
        valsToReturn.accountCustomerRating = currentUserDetails.Contact.Account.BadgesTier__c;
        valsToReturn.kpiList.add(new map<string,string>{'label' =>'Open Leads' , 'value' => String.ValueOf(openLeads) ,'link' =>'../s/manage-leads'} );
        valsToReturn.kpiList.add(new map<string,string>{'label' =>'Open Opportunities' , 'value' => String.ValueOf(openOpportunity) ,'link' =>'../s/manage-opportunities' } );
        valsToReturn.kpiList.add(new map<string,string>{'label' =>'Units Sold' , 'value' => String.ValueOf(soldUnitCOunt) ,'link' =>'../s/sales-report'} );
        valsToReturn.kpiList.add(new map<string,string>{'label' =>'Total Sales Value' , 'value' => totalSumString ,'link' =>'../s/sales-report'} );
        
        return valsToReturn;
    }
   
    /**
    * getAgencyDashboardDetails
    *
    * This method used to agency related Dashboard details
    *
    * @param  accountId - Child account Ids to filter  the KPIs and chart data 
    * @param  startDate - start date to get the KPIs and chart data 
    * @param  endDate   - end date to get the KPIs and chart data 
    * @return AgencyDashboardDetails wrapper class
    */
    @AuraEnabled(cacheable=true)
    public static AgencyDashboardDetails getAgencyDashboardDetails(String accountId,Date startDate, Date endDate){
        System.debug('accountId:::'+accountId);
        AgencyDashboardDetails valsToReturn = new AgencyDashboardDetails();
        User currentUserDetails=Utilities.getLoggedInUserDetail();
        map<string,decimal> projectToSales = new map<string,decimal>();
        map<string,decimal> projectToCommission= new map<string,decimal>();
        //get all relatedAccountIds
        set<Id> accoountIds = new set<Id>{};
        if(accountId==null || accountId==''){
            accountId=currentUserDetails.AccountId;
        }
            accoountIds.add(accountId);
        
       
        valsToReturn.childAccounts.add(new map<string,string>{'label' =>'All' , 'value' => ''});
        for(Account tempAcc : [select id,Name, ParentId from Account where (ParentId =: currentUserDetails.AccountId OR id =: accountId OR Id =: currentUserDetails.AccountId) WITH SECURITY_ENFORCED]){
            if(tempAcc.Id == accountId && tempAcc.ParentId ==null){
                valsToReturn.childAccounts.add(new map<string,string>{'label' =>tempAcc.Name+'- Parent' , 'value' => tempAcc.id} );  
            }else { 
                valsToReturn.childAccounts.add(new map<string,string>{'label' =>tempAcc.Name , 'value' => tempAcc.id} );
            }
            if(accountId == currentUserDetails.AccountId){
                accoountIds.add(tempAcc.id);
            }
        }
        
        integer tempRank=0;
        decimal classificationAmount=-1;
        Map<Id, Account> accountMap =  new Map<Id, Account>([select id,Name, ParentId, BrokerClassification__r.Name, BadgesTier__c from Account where (ParentId = :currentUserDetails.AccountId OR id=: accountId OR Id =: currentUserDetails.AccountId) WITH SECURITY_ENFORCED]);
        for(Account tempAcc : DashboardWitoutShareController.getAccountRanking()){
            if(classificationAmount != tempAcc.ClassificationSalesAmount__c){
                tempRank++;
                classificationAmount = tempAcc.ClassificationSalesAmount__c;
            }
            if(tempAcc.Id == currentUserDetails.AccountId){
                valsToReturn.accountName = tempAcc.Name;
                valsToReturn.accountClassification = tempAcc.BrokerClassification__r.Name;
                valsToReturn.accountRank = String.ValueOf(tempRank);
                valsToReturn.accountCustomerRating = tempAcc.BadgesTier__c;
            }
            valsToReturn.linkedAccountClassification.put(tempAcc.id, accountMap.get(tempAcc.Id)?.BrokerClassification__r.Name);
            valsToReturn.linkedAccountCustomerRating.put(tempAcc.id, accountMap.get(tempAcc.Id)?.BadgesTier__c);
            if(accountMap.containsKey(tempAcc.Id) && (accountMap.get(tempAcc.Id).Id == tempAcc.Id)){
                valsToReturn.linkedAccountRanks.put(tempAcc.id , String.ValueOf(tempRank));
            } 
            if(valsToReturn.topAccountRanking.size()<10){
                valsToReturn.topAccountRanking.add(new AccountRankWrapper(tempAcc,tempRank));
            }
        }
        
        system.debug('valsToReturn.linkedAccountRanks::::'+valsToReturn.linkedAccountRanks);
        system.debug('valsToReturn.childAccounts::::'+valsToReturn.childAccounts);
        string dateFilter='';

        //OriginalCreationDate__c
        if(startDate!=null){
            string timeUserContext = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).formatGMT('yyyy-MM-dd\'T\'hh:mm:ss\'z\'');
            dateFilter= ' and ( (OriginalCreationDate__c != null and OriginalCreationDate__c >= '+timeUserContext+' ) or (OriginalCreationDate__c = null and createdDate >= '+timeUserContext+') )';
            //dateFilter= ' and createdDate >= :startDate';
        }
        if(endDate!=null){
            string timeUserContext = DateTime.newInstance(endDate.year(), endDate.month(), endDate.day()).formatGMT('yyyy-MM-dd\'T\'hh:mm:ss\'z\'');
            dateFilter+= ' and ( (OriginalCreationDate__c != null and OriginalCreationDate__c <= '+timeUserContext+' ) or (OriginalCreationDate__c = null and createdDate <= '+timeUserContext+') )';
            //dateFilter+= ' and createdDate <= :endDate';
        }
        
        Integer openLeads=database.countQuery('select count() from lead where BrokerAgency__c in :accoountIds and isConverted=false and status != \'' +Constants.DUPLICATE_LEAD+'\' and status != \''+Constants.RETIRED+'\' and status != \''+Constants.CONVERTED_LEAD+'\'' + dateFilter +' WITH SECURITY_ENFORCED');//[select count() from lead where BrokerAgency__c in :accoountIds and isConverted=false and status != :Constants.DUPLICATE_LEAD and status != :Constants.RETIRED];
        Integer openOpportunity=database.countQuery('select count() from Opportunity where BrokerAgencyAccount__c in :accoountIds and isclosed=false' + dateFilter);
        list<SalesOrder__c> salesOrderList = database.Query('select id,NetAmount__c,ExternalCommissionAmount__c,Status__c,ProjectName__c,BookingDate__c from SalesOrder__c where Opportunity__r.BrokerAgencyAccount__c in :accoountIds and Status__c in (\''+Constants.UNIT_STATUS_SOLD+'\' ) '+dateFilter +' WITH SECURITY_ENFORCED');
//,\''+Constants.SALES_STATUS+'\',\''+Constants.OPPO_UNIT_STATUS_PENDING+'\'      
        Decimal totalSum=0;
        Decimal totalCommissionSum=0;
        set<ID> salesOrderIds = new set<ID>();
        map<integer,decimal> monthwiseSales = new map<integer,decimal>();
        integer soldUnitCOunt = 0;
        for(SalesOrder__c tempSO : salesOrderList){
            
            if(!projectToSales.containsKey(tempSO.ProjectName__c)){
                projectToSales.put(tempSO.ProjectName__c,0);
                projectToCommission.put(tempSO.ProjectName__c,0);
            }
            
            if(tempSO.Status__c== Constants.UNIT_STATUS_SOLD){
                soldUnitCOunt++;
                if(tempSO.ExternalCommissionAmount__c!=null){
                    totalCommissionSum = totalCommissionSum + tempSO.ExternalCommissionAmount__c;
                    projectToCommission.put(tempSO.ProjectName__c, projectToCommission.get(tempSO.ProjectName__c) + tempSO.ExternalCommissionAmount__c );
                }
            }
            
            salesOrderIds.add(tempSO.Id);
            if(tempSO.NetAmount__c!=null){
                totalSum = totalSum + tempSO.NetAmount__c;
                projectToSales.put(tempSO.ProjectName__c, projectToSales.get(tempSO.ProjectName__c) + tempSO.NetAmount__c );
            }
            
            Integer salesMonth = tempSO.BookingDate__c!=null ? tempSO.BookingDate__c.month() : 99;
            if(!monthwiseSales.containsKey(salesMonth) ){
                monthwiseSales.put(salesMonth,0);
            }
            if(tempSO.NetAmount__c!=null){
                monthwiseSales.put(salesMonth,monthwiseSales.get(salesMonth) + tempSO.NetAmount__c );
            }
            
        }
        String totalSumString=getShortStringValue(totalSum);
        String totalCommissionString=getShortStringValue(totalCommissionSum);
        
        //Commission Paid
        list<CommissionLineItem__c> commissionLines = database.Query('select id,CommissionAmount__c from CommissionLineItem__c where SalesOrder__c in :salesOrderIds and Status__c = \''+Constants.COMMISSION_LINE_STATUS_PAID+'\''+dateFilter +' WITH SECURITY_ENFORCED');
        totalSum=0;
        
        for(CommissionLineItem__c tempC : commissionLines){
            if(tempC.CommissionAmount__c!=null){
                totalSum = totalSum + tempC.CommissionAmount__c;
            }
        }
        String totalCommissionPaidString=getShortStringValue(totalSum);

        valsToReturn.kpiList.add(new map<string,string>{'label' =>'Open Leads' , 'value' => String.valueOf(openLeads) ,'link' =>'../s/manage-leads' } );
        valsToReturn.kpiList.add(new map<string,string>{'label' =>'Open Opportunities' , 'value' => String.valueOf(openOpportunity) ,'link' =>'../s/manage-opportunities' } );
        valsToReturn.kpiList.add(new map<string,string>{'label' =>'Units Sold' , 'value' => String.ValueOf(soldUnitCOunt) ,'link' =>'../s/sales-report'} );
        valsToReturn.kpiList.add(new map<string,string>{'label' =>'Total Sales Value' , 'value' => totalSumString ,'link' =>'../s/sales-report' } );
        valsToReturn.kpiList.add(new map<string,string>{'label' =>'Commission Earned' , 'value' => totalCommissionString ,'link' =>'../s/commissions-report'} );
        valsToReturn.kpiList.add(new map<string,string>{'label' =>'Commission Paid' , 'value' => totalCommissionPaidString ,'link' =>'../s/commissions-report'} );

        //Chart data
        valsToReturn.projectList = new list<string>(projectToSales.keySet());
        valsToReturn.salesByProject = projectToSales.values();
        valsToReturn.commissionbyProject = projectToCommission.values();
        for(integer i=1;i< valsToReturn.monthValues.size() ; i++){
            valsToReturn.totalSalesByMonth.add(monthwiseSales.containskey( valsToReturn.monthValues[i])? (monthwiseSales.get( valsToReturn.monthValues[i])).setScale(2) : 0 );
        }
        return valsToReturn;
    }
   
   
    /**
    * getShortStringValue
    *
    * This method used to return short format for the number. Example 1.5 M for 1500000
    *
    * @param  num - Decimal number to be formatted
    * @return formatted short string representation
    */
    private static string getShortStringValue(decimal num){
        string valueToReturn = '0';
        if(num > 1000000){
            valueToReturn = ((num/1000000).setScale(1)+' M').replace('.0','');
        }else if(num>1000){
            valueToReturn = ((num/1000).setScale(1)+' K' ).replace('.0','');
        }
        return valueToReturn;
    }

    /**
    * DashboardDetails
    *
    * Warrper class for the agent dashboard
    *
    */
    public class DashboardDetails{
        @AuraEnabled
        public string userName;
        @AuraEnabled
        public string agentId;
        @AuraEnabled
        public string accountCustomerRating;
        @AuraEnabled
        public string greetings;
        @AuraEnabled
        public list<map<string,string>> kpiList;
        public DashboardDetails(){kpiList= new list<map<string,string>>();}
    }

    /**
    * AgencyDashboardDetails
    *
    * Warrper class for the agency dashboard
    *
    */
    public class AgencyDashboardDetails{
        @AuraEnabled
        public list<AccountRankWrapper> topAccountRanking;
        @AuraEnabled
        public string accountName;
        @AuraEnabled
        public string accountClassification;
        @AuraEnabled
        public string accountCustomerRating;
        @AuraEnabled
        public string accountRank;
        @AuraEnabled
        public  list<map<string,string>> childAccounts;
        @AuraEnabled
        public list<map<string,string>> kpiList;
        @AuraEnabled
        public list<String> projectList;
        @AuraEnabled
        public list<Decimal> salesByProject;
        @AuraEnabled
        public list<Decimal> commissionbyProject;
        @AuraEnabled
        public list<Integer> monthValues;
        @AuraEnabled
        public list<Decimal> totalSalesByMonth;
        @AuraEnabled
        public map<string,string> linkedAccountRanks;
        @AuraEnabled
        public map<string,string> linkedAccountClassification;

        @AuraEnabled
        public map<string,string> linkedAccountCustomerRating;        

        public AgencyDashboardDetails(){
            topAccountRanking=new list<AccountRankWrapper>();
            childAccounts= new list<map<string,string>>();
            linkedAccountRanks = new map<string,string>();
            linkedAccountClassification = new map<string,string>(); 
            linkedAccountCustomerRating = new map<string,string>();
            kpiList= new list<map<string,string>>();
            projectList = new list<String>();
            salesByProject = new list<Decimal>();
            commissionbyProject = new list<Decimal>();
            monthValues = new list<Integer>();
            for(integer i = system.today().month() ; monthValues.size() <= 12 ; i ++ ){
                
                monthValues.add(i);
                if(i==12){i=0;}
            }
            totalSalesByMonth =new list<Decimal>();
        }
    }

    class AccountRankWrapper {
        @AuraEnabled
        public Account accountRecord;
        @AuraEnabled
        public Integer rank;
        public AccountRankWrapper(Account acc,Integer rankVal){
            accountRecord=acc;
            rank=rankVal;
        }
    }
}