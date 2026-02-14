@RestResource (urlMapping = '/query/opportunity')
global with sharing class OpportunityQueryWebService {
    
    @HttpPost
    global static void doPost() {   
        RestContextHandler handler = new RestContextHandler(false); String city = '';
        try {
            Map<String,String> mapFieldApiFieldValues = handler.getRequestBodyMap();
            Utilities.objType = 'Opportunity'; 
            String opportunityId;
            OpportunityDetailResponse detailResponse = new OpportunityDetailResponse();            
            
            if(mapFieldApiFieldValues != null && mapFieldApiFieldValues.keySet().contains('brokerLeadNumber')){
                String leadNumber = mapFieldApiFieldValues.get('brokerLeadNumber'); 
                String accountId = mapFieldApiFieldValues.get('selectedAccountId');
                List<Lead> ld = UtilitiesWithoutSharing.getleadbyLeadNumber(leadNumber);
                Map<Id, User> mapOfCurrentUser = Utilities.getOwnersDetail(new Set<Id>{UserInfo.getUserId()});
                if(ld[0].BrokerAgency__r.BillingState != null){
                if(ld[0].BrokerAgency__r.BillingState =='Abu Dhabi'){ 
                    city='AUH';
                }
                else if(ld[0].BrokerAgency__r.BillingState =='Dubai' || ld[0].BrokerAgency__r.BillingState =='Ajman'|| ld[0].BrokerAgency__r.BillingState =='Fujairah'||ld[0].BrokerAgency__r.BillingState =='Ras Al Khaimah'||ld[0].BrokerAgency__r.BillingState =='Sharjah' || ld[0].BrokerAgency__r.BillingState =='Umm Al Quwain'){
                    city='DXB'; 
                }
                }
                //Arvind Removed the DXB City, all the international Broker will be Convert/Handle by both team
                else{
                    city=''; 
                }
                if(ld[0].BrokerAgency__r.AgencyCategory__c == System.Label.AgencyCategoryWealth){
                    city='';
                }
                
                if( city != '' && ld.size() >0 && city != mapOfCurrentUser.get(UserInfo.getUserId()).Team__c && (mapOfCurrentUser.get(UserInfo.getUserId()).Team__c  =='DXB'|| mapOfCurrentUser.get(UserInfo.getUserId()).Team__c =='AUH') && ld[0].Approval_Status__c !='Approved'){ 
                    throw new Exceptions.BrokerCityException(); 
                }
                
                else if(ld.size() >0 && ld[0].ExistingAccount__c != null && (ld[0].ExistingAccount__r.FastTrackedAccount__c== true  || (ld[0].ExistingAccount__r.FastTrackedAccount__c == false && ld[0].ExistingAccount__r.ProspectAccount__c== false))){
                    UtilitiesWithoutSharing.getConvertedOppBySearchLead(leadNumber,''); 
                    
                    mapFieldApiFieldValues = new Map<String,String>();
                    mapFieldApiFieldValues.put('LeadNumber__c',leadNumber);
                }
                else if(ld.size() >0 && ld[0].SkipDuplicateApprovalStatus__c != 'Approved'  && ld[0].IsConverted==false && (accountId == '' || accountId == null)){
                    Boolean hasDuplicates = false;
                    // SSC-697, Duplicate Account check based on Email or Mobile Number: Bashim
                    // In the below method we have added one more parameter mobile number to get duplicate account based on mobile number
                    List<UtilitiesWithoutSharing.DuplicateAccountWrapper> AccountMap  = new List<UtilitiesWithoutSharing.DuplicateAccountWrapper>();
                    
                    AccountMap = UseExistingAccount.findDuplicateAccountsByEmailAndMobileNumber(new Set<String>{ld[0].Email}, new Set<String>{ld[0].MobilePhone});
                    System.debug(AccountMap);
                    if( AccountMap.size() > 0){ 
                        hasDuplicates = true;
                    }
                    
                    List<DuplicateAccountResponseWrapper.duplicateAcc> duplicateList = new List<DuplicateAccountResponseWrapper.duplicateAcc>();
                    if(hasDuplicates == true){
                        for(UtilitiesWithoutSharing.DuplicateAccountWrapper ac : AccountMap){
                            DuplicateAccountResponseWrapper.duplicateAcc dup= new  DuplicateAccountResponseWrapper.duplicateAcc();
                            dup.Name  = ac.Account.Name; 
                            dup.AccountNumber  = ac.Account.AccountNumber__c;
                            dup.SalesOrderCount  = ac.salesOrderCount;
                            dup.CustomerType  = ac.Account.CustomerType__c;
                            dup.CustomerSubType  = ac.Account.CustomerSubType__c;
                            dup.PassportNumber  = ac.Account.PassportNumber__pc;
                            dup.KYCValidity  = ac.Account.KYC_Validity_Status__c;
                            dup.EmiratesId  = ac.Account.NationalIdNumber__pc;
                            dup.ResidentStatus  = ac.Account.ResidentStatus__pc;
                            dup.AccountId = ac.Account.Id; 
                            duplicateList.add(dup);
                            }
                        
                        DuplicateAccountResponseWrapper.dupAcc duplicatea = new  DuplicateAccountResponseWrapper.dupAcc(null,null,hasDuplicates,false,null,ld[0].SkipDuplicateApprovalStatus__c == 'Sent for Approval'?true:false,true,''); duplicatea.DuplicateAccounts = duplicateList; handler.response.data = duplicatea;
                        
                    }else{
                        UtilitiesWithoutSharing.getConvertedOppBySearchLead(leadNumber,'');
                        mapFieldApiFieldValues = new Map<String,String>();
                        mapFieldApiFieldValues.put('LeadNumber__c',leadNumber);
                       
                    }
                }else{ 
                    UtilitiesWithoutSharing.getConvertedOppBySearchLead(leadNumber,accountId);
                    mapFieldApiFieldValues = new Map<String,String>();
                    mapFieldApiFieldValues.put('LeadNumber__c',leadNumber);
                    
                }
            }else{
                
                if(mapFieldApiFieldValues != null && mapFieldApiFieldValues.keySet().contains('Id')) {
                    opportunityId = mapFieldApiFieldValues.get('Id');
                    detailResponse.opportunityRecord = OpportunityService.fetchOpportunityById(opportunityId);
                    
                    //Details for VIP Exception
                    String accountCustomerType = detailResponse.opportunityRecord.Account.CustomerType__c;
                    Id opportunityOwnerId = detailResponse.opportunityRecord.OwnerId;
                    Map<Id, User> mapOfOpportunityOwner = Utilities.getOwnersDetail(new Set<Id>{opportunityOwnerId});
                    String oppOwnerTeam = mapOfOpportunityOwner.get(opportunityOwnerId).Team__c;
                    String approvalStatusVIP = detailResponse.opportunityRecord.VIPApproval__c;                    
                    Boolean showVIPExceptionButton = accountCustomerType.equals('VIP') && (oppOwnerTeam.equals('AUH') || oppOwnerTeam.equals('DXB')) && (approvalStatusVIP != 'Sent for Approval' || approvalStatusVIP != 'Approved');
                                        
                    OpportunityUnitSearchController.blockWrapper wrap = OpportunityUnitSearchController.checkSMAuthorizationForBooking(opportunityId);
                    detailResponse.isBlocked = wrap.isBlocked;
                    detailResponse.showVIPException = showVIPExceptionButton;
                    detailResponse.blockedMessage = wrap.blockedMessage;
                    if(detailResponse.opportunityRecord.LossReason__c == 'Lost - Inter Department Referral'){ 
                        detailResponse.hasInterDeptReferral = false;
                    }
                    Id accountId = detailResponse.opportunityRecord.AccountId ; 
                    Map<Id,List<Document__c>> accountDocumentMap = DocumentService.getDocumentbyAccountId(new Set<Id>{accountId});
                    if(accountDocumentMap.containsKey(accountId)){ 
                        List<Document__c> documentList = accountDocumentMap.get(accountId);
                        Map<Id,Document__c> documentMap = new Map<Id,Document__c>(documentList);
                        Map<Id,DocumentQueryModel> documentQueryModelMap = DocumentService.getDocumentDetails(documentMap);
                        for(Document__c documentRec : documentList){
                            if(documentQueryModelMap.containsKey(documentRec.Id)) detailResponse.documents.add(documentQueryModelMap.get(documentRec.Id)); 
                        }
                    }
                    list<OpportunityEOI__c> OppEoi = [select id from OpportunityEOI__c where Opportunity__c = :opportunityId ];
                    if(OppEoi.size()>0) {  
                        detailResponse.isOpportunityEOIAvailable = true; 
                    } else{
                        detailResponse.isOpportunityEOIAvailable = false; 
                    } 
                    handler.response.data = detailResponse; 
                }
                else{
                    List<Opportunity> opportunities = OpportunityService.fetchOpportunities(Utilities.getWhereConditionfrmMap(mapFieldApiFieldValues));
                    OpportunityQueryResponse response = new OpportunityQueryResponse(opportunities, 'Opportunity', false);
                    handler.response.data = response;                  
                    }
            } 
            handler.response.success = true; 
            handler.finalize();
        }
        catch(Exceptions.IncorrectFilterException ex){ handler.response.success = false; handler.response.statusCode =  Constants.STATUS_CODE_SUCCESS; handler.response.message = 'Lead number provided is not the correct one'; handler.finalize(ex); }
        catch(Exceptions.InsufficientAccessException exAccess){ 
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SUCCESS;
            handler.response.message = 'Insufficient Privileges to search for Lead.';
            handler.finalize(exAccess); 
        }
        catch(Exceptions.VIPBrokerLeadException exVIP){handler.response.success = false;  handler.response.statusCode = Constants.STATUS_CODE_SUCCESS; handler.response.message = 'This lead matches an existing VIP Lead/Customer in the system. This cannot be converted.'; LeadVIpResponse lp = new LeadVIpResponse(); lp.showVIPException = true; lp.showBrokerException= false;handler.response.data = lp;handler.finalize(exVIP); }
        catch(Exceptions.BrokerCityException exBroker){ handler.response.success = false; handler.response.statusCode = Constants.STATUS_CODE_SUCCESS; handler.response.message = 'You can not convert '+city+' Lead'; LeadVIpResponse lp = new LeadVIpResponse(); lp.showVIPException = false; lp.showBrokerException= true; handler.response.data = lp; handler.finalize(exBroker); }
        catch(Exceptions.AlreadyConvertedException ex){ handler.response.success = false; handler.response.statusCode = Constants.STATUS_CODE_SUCCESS; handler.response.message = 'This Lead Is Already Converted.'; handler.finalize(ex); }
        catch(Exceptions.BrokerSuspensionException ex){ handler.response.success = false; handler.response.statusCode = Constants.STATUS_CODE_SUCCESS; handler.response.message = 'Lead is not allowed for Suspended Broker.'; handler.finalize(ex); }
        catch (DMLException exc) { handler.response.success = false;   handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR; handler.response.message = exc.getDMLMessage(0); handler.finalize(exc); }
        catch (Exception exc) { 
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR; 
            handler.response.message = Constants.MESSAGE_GENERIC_ERROR; 
            handler.finalize(exc); 
        } 
    }
    
    global with sharing class OpportunityQueryResponse extends QueryResponse {
        
        Set<String> projects = new Set<String>();  
        global OpportunityQueryResponse (List<SObject> records, String objectName, Boolean processRecords) {   
            super(records, objectName, processRecords);
            
            for (SObject record : records) {
                Opportunity opportunityRecord = (Opportunity) record;
                if (opportunityRecord.Project__c != null) 
                    projects.add(opportunityRecord.Project__c);
            }
        }
    } 
    
    global class LeadVIpResponse {
        
        public Boolean showVIPException;
        public Boolean showBrokerException;
        public String BrokerExceptionMessage;
        public LeadVIpResponse(){
            this.showVIPException = true;
            this.showBrokerException = false;
            this.BrokerExceptionMessage='';
        }
        
    }
    
    global class OpportunityDetailResponse {
        
        public Opportunity opportunityRecord ;
        public List<DocumentQueryModel> documents ;
        public boolean isOpportunityEOIAvailable;   
        public boolean  hasInterDeptReferral;
        public boolean isBlocked;
        public boolean showVIPException;
        public string blockedMessage;
        
        public OpportunityDetailResponse(){
            this.opportunityRecord = new Opportunity();
            this.documents = new List<DocumentQueryModel>();
            this.hasInterDeptReferral = true;
            this.isBlocked = false;
            this.showVIPException = true;
            this.blockedMessage = 'Booking for VIP/Aldar Staff is restricted and not within your authorization.';
        }
    }
    
}