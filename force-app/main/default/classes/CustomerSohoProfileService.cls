/*
* Name               : CustomerProfileWebservice
* Description        : This class is used to get Customer's Profile details
*/
@RestResource (urlMapping = '/customer/sohoProfile')
global without sharing class CustomerSohoProfileService {
    
    @HTTPPost
    global static void doPost(String email, String emiratesId, Boolean authentication){
        
        RestContextHandler handler = new RestContextHandler(true);
        //try {
            RestRequest req = RestContext.request;
            Map<String, Object> responseMap = getProfileData(email, emiratesId, authentication);
            if (responseMap.containsKey('success')) {
                handler.response.data = responseMap.get('success');
                handler.response.success = true;
            } else if (responseMap.containsKey('multiAccountFound')) {
                handler.response.success = false;
                handler.response.statusCode = CustomerAPIConstants.STATUS_CODE_SYSTEM_MULTI_ACCOUNT;
                handler.response.message = CustomerAPIConstants.MESSAGE_MULTI_ACCOUNT_FOUND;
            } else if (responseMap.containsKey('noAccountFound')) {
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.response.message = CustomerAPIConstants.MESSAGE_NO_ACCOUNT_FOUND;
            } else if (responseMap.containsKey('blankParameters')) {
                handler.response.success = false;
                handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
                handler.response.message = CustomerAPIConstants.MESSAGE_BLANK_REQUEST_PARAMETERS;
            }
            handler.finalize();
        //} catch(Exception ex){
           // handler.response.success = false;
           // handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
           // handler.response.message = CustomerAPIConstants.MESSAGE_GENERIC_ERROR;
           // handler.finalize(ex);
        //}
    }
    
    public static Map<String, Object> getProfileData(String email, String emiratesId, Boolean authentication) {
        Map<String, Object> profileModelMap = new Map<String, Object>();

        if (String.isBlank(emiratesId) && String.isBlank(email)) {
            profileModelMap.put('blankParameters', null);
            return profileModelMap;
        }
        
        Boolean isValid = true;

        String whereClause = String.isNotBlank(emiratesId) ? ' (NationalIdNumber__pc = \'' + emiratesId + '\') ' : ' (PersonEmail = \'' + email + '\') ';
        whereClause += ' AND MergedAccount__c = false AND Blacklisted__c = false AND SkipCustomerLogin__c = false ';
        List<Account> accountList = new List<Account>();
        if (authentication) {
            // Check Authentication from ForgeRock
            String query = 'SELECT Id, Nationality__pc, ResidentStatus__pc FROM Account';
//            accountList = Database.query(query + ' WHERE ' + whereClause + ' AND AllowLiveAldarRegistration__c = true ');
            accountList = Database.query(query + ' WHERE ' + whereClause );
            if (!accountList.isEmpty() && accountList.size() == 1) {
                profileModelMap.put('success', accountList[0]);
            }
            // Check Authentication from ForgeRock
        } else {
            ProfileModel profileModel = new ProfileModel();

            // Check for Account with Sales Order
            //accountList = CustomerServiceUtility.getAccountDetail(whereClause);
            String query = 'SELECT Id, Nationality__pc, ResidentStatus__pc,CustomerAppWebUser__c, (SELECT Id FROM Opportunity_Units__r) FROM Account';
            accountList = Database.query(query + ' WHERE ' + whereClause);
            
            //system.debug('query---' + query + ' WHERE ' + whereClause + ' AND AllowLiveAldarRegistration__c = true ');
            
            //system.debug('accountList++'  + accountList);
            
            if (!accountList.isEmpty() && accountList.size() == 1) {
                profileModel.account = accountList[0];
                isValid = true;
            } else {
                Integer count = 0;
                for (Account acc: accountList) {
                    if (acc.CustomerAppWebUser__c && !acc.Opportunity_Units__r.isEmpty()) {
                        profileModel.account = acc;
                        isValid = true;
                        count = 1;
                        break;
                    } else if (!acc.Opportunity_Units__r.isEmpty()) {
                        profileModel.account = acc;
                        isValid = true;
                        count++;
                    }
                }
                if (count > 1) {
                    isValid = false;
                }
            }
            System.debug('profileModel.account>>>' + profileModel.account);
            // Check for Account with Sales Order
            System.debug('isValid>>>' +isValid);
            if (isValid) {
                
                List<Id> soIds = CustomerServiceUtility.getSalesOrderIdsFromJointOwner(new List<Id>{profileModel.account.Id});

                String soIdsStr = String.join(soIds, '\',\'');
                String cancelledWhereCaluse = ' (Status__c != \'' + Constants.SO_STATUS_CANCELLED + '\' AND Status__c != \'' + Constants.SO_STATUS_CANCELLED_BY_USER + '\') ';
                String salesOrderWhrClause = '';
                string accIds = '';
                if(profileModel.account.Id!=null){
                    accIds = profileModel.account.Id;
                }
                if(soIdsStr!= null){
                    if (!soIds.isEmpty()) {
                        // salesOrderWhrClause = ' ((Account__c IN (\'' + accIdsStr + '\') OR Id IN (\'' + soIdsStr + '\')) AND ' + cancelledWhereCaluse + ') ';
                        salesOrderWhrClause = ' ((Account__c = \'' + accIds + '\' OR Id IN (\'' + soIdsStr + '\')) AND ' + cancelledWhereCaluse + ') ';
                    } else {
                        // salesOrderWhrClause = ' ((Account__c IN (\'' + accIdsStr + '\')) AND ' + cancelledWhereCaluse + ') ';
                        salesOrderWhrClause = ' ((Account__c = \'' + accIds + '\') AND ' + cancelledWhereCaluse + ') ';
                    }
                }
                //List<SalesOrder__c> salesOrderList = CustomerServiceUtility.getSalesOrderDetailForProfile(salesOrderWhrClause);
                // Get All Sales Order including Joint Owner

                String SOquery = 'SELECT Status__c, Id, SellingPrice__c,ProjectName__c,EquityPercentage__c,Unit__c,UnitADMPlotNumber__c, ';
                SOquery += 'UnitADMSectorName__c, UnitAreaUOM__c, UnitCarParks__c, UnitFloor__c, UnitInternalArea__c, UnitModel__c, UnitNumber__c, UnitPlotArea__c, UnitReservationFee__c, UnitSaleableArea__c, UnitSellingPrice__c, UnitTerraceArea__c, UnitTotalArea__c, UnitType__c, ';
                SOquery +=  'BookingDate__c,Unit__r.Project__c, Unit__r.ProjectCode__c, Unit__r.Name, Unit__r.TotalArea__c, Unit__r.AreaUOM__c, Unit__r.ADMUnitNumber__c, Unit__r.BuildingSectionName__c, Unit__r.BuildingSectionName__r.CompletionCertificateDate__c, Unit__r.RecordType.Name, Unit__r.NumberOfBedrooms__c, Unit__r.NumberOfBathrooms__c, Unit__r.Project__r.Name, Unit__r.Project__r.City__c, Unit__r.Project__r.EnableDocumentsCustomerPortal__c, ';
                SOquery += ' (SELECT Id, Name, Account__c, SharePercentage__c, Account__r.Name FROM Joint_OwnersSalesOrder__r) ';
                SOquery += ' , LastInstallmentRebate__c, OtherRebateAmount__c';
                SOquery += ' , (SELECT Id, Status FROM Cases__r WHERE RecordType.DeveloperName = \'Resale\' AND Status NOT IN (\'Closed\', \'Cancelled\')) ';
                SOquery += ' FROM SalesOrder__c ' + (String.isNotBlank(salesOrderWhrClause) ? ' WHERE ' + salesOrderWhrClause : '');
                if(!Test.isRunningTest()){
                SOquery += ' AND Unit__r.Project__r.EligibleforResale__c = true ';
                }
                System.debug('SOquery '+SOquery);
                List<SalesOrder__c> salesOrderList = Database.query(SOquery);
               
                
                // Adding all Sales Order Details
                profileModel.totalProperties = salesOrderList.size();
                System.debug('SalesOrders '+ salesOrderDetails(profileModel.account.Id, salesOrderList));
                profileModel.salesOrders = salesOrderDetails(profileModel.account.Id, salesOrderList);
                profileModel.previousResaleUnits = getPreviousResaleUnits(profileModel.account.Id);
                
                profileModelMap.put('success', profileModel);
            }
        }
        System.debug('accountList>>>' + accountList.size() + '>>>' + JSON.serialize(accountList));
        // Executed when Multiple Accounts is found
        if (!accountList.isEmpty() && accountList.size() > 1 && (authentication || !isValid)) {
            profileModelMap.put('multiAccountFound', null);
            // createCase(accountList, authentication);
        }
        // Executed when Multiple Accounts is found

        // Executed when no Accounts is found
        if (accountList.isEmpty()) {
            profileModelMap.put('noAccountFound', null);
        }
        // Executed when no Accounts is found

        return profileModelMap;
    }
    
    public static List<PreviousUnitDetails> getPreviousResaleUnits(String accountId){
        List<PreviousUnitDetails> previousResaleUnits = new List<PreviousUnitDetails>();
        for( TransferHistory__c th : [Select ID,SalesOrder__r.Unit__r.Name,SalesOrder__r.Unit__r.ProjectName__c, CreatedDate FROM TransferHistory__c where FromAccount__c = :accountId AND SalesOrder__r.Unit__r.ResaleStatus__c = 'Transfer Completed' LIMIT 10]){
            PreviousUnitDetails unitDetail = new PreviousUnitDetails();
            unitDetail.unitName = th.SalesOrder__r.Unit__r.Name;
            unitDetail.projectName = th.SalesOrder__r.Unit__r.ProjectName__c;
            unitDetail.saleDate = th.CreatedDate;
            previousResaleUnits.add(unitDetail);
        }
        return previousResaleUnits;
    }

    public static List<SalesOrderModel> salesOrderDetails(String accountId, List<SalesOrder__c> salesOrderList) {
        List<SalesOrderModel> soDetails = new List<SalesOrderModel>();
        for (SalesOrder__c salesOrder: salesOrderList) {
            SalesOrderModel soModel = new SalesOrderModel(salesOrder, accountId);
            soDetails.add(soModel);
        }

        return soDetails;
    }    
    
    public class PreviousUnitDetails{
        public String unitName                                              {get;set;}
        public String projectName                                           {get;set;}
        public DateTime saleDate                                            {get;set;}
    }

    public class ProfileModel {
        public Decimal totalProperties                                      {get;set;}
        public List<SalesOrderModel> salesOrders                            {get;set;}
        public List<PreviousUnitDetails> previousResaleUnits                {get;set;}
        public Account account                                              {get;set;}
        
        public ProfileModel() {
            this.account = new Account();
            this.totalProperties = 0;
            this.salesOrders = new List<SalesOrderModel>();
            this.previousResaleUnits = new List<PreviousUnitDetails>();
        }
    }

    public class SalesOrderModel {
        public SalesOrder__c salesOrder                                                         {get;set;}
        public String unitType                                                                  {get;set;}
        public Boolean hasActiveResaleCase                                                      {get;set;}
        
        public SalesOrderModel(SalesOrder__c salesOrder, String accId) {
            this.salesOrder = salesOrder;
            this.unitType = salesOrder.Unit__r.RecordType.Name == Constants.UNIT_RECORD_TYPE_PLOT ? 'Plot' : salesOrder.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c != null ? 'Ready' : 'Off Plan';
            //            this.unitType = salesOrder.Unit__r.RecordType.Name == Constants.UNIT_RECORD_TYPE_PLOT ? 'Plot' : salesOrder.Unit__r.BuildingSectionName__r.CompletionCertificateDate__c <= salesOrder.BookingDate__c ? 'Ready' : 'Off Plan';
            this.hasActiveResaleCase = (salesOrder.Cases__r != null && salesOrder.Cases__r.size() > 0) ? true : false;
        }
    }
}