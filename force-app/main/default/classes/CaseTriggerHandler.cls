/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-06-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * @last modified by  : smaartt 23/08 v2.1 changes
**/
public without sharing class CaseTriggerHandler extends TriggerHandler{
    
    public static Boolean isSkipCaseTrigger = false;
    public static String Cancelled = System.Label.Cancelled;
    
    //*** Before Insert Action***//
    
    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){

        updateSalesOrderAndCustomer(newList, new Map<Id, SObject>(), false);
        ResaleService.beforeActionsOnResaleCase(newList, new Map<Id, SObject>(), false);
        DevControlValidation.DevcontrolUnitValidation(newList);// added by smaartt
        DevControlValidation.AccountShare(newList);   
        checkAndupdateProductForOnDeamnd(newList, new Map<Id, SObject>(),false);
        Set<Id> accountIds = new Set<Id>();
        map<Id,account> accountIDToRecMap = new map<Id,account>();
        map<Id,Id> caseWithSalesOrderMap = new map<Id,Id>();
        map<Id,String> caseSubVerticalMap = new map<Id,String>();
        List<Id> UnitIdsList = New List<Id>();
        Set<String> casestatuses = new Set<String>{'New', 'Assigned', 'Re-scheduled'};
        Id entitlementId = System.Label.DefaultEntitlementId ;
        Id dlpEntitlementId = System.Label.DLPEntitlementId ;    
        Id dlpEmergEntitlementId = System.Label.DLPEmergEntitlementId;
        List<Case> emailCases = new List<Case>(); //Case revamp : For email validation
        Set<String> emailCasesSuppliedEmails = new Set<String>();
        //Case : KAR changes
        Set<Id> caseUnit = new Set<Id>();
        Map<Id, String> karMap = new Map<Id, String>();
        // Case Revamp : For getting queue ID
        Map<String, Group> queueMap = caseQueryInformation();  
        Group Onboarding = queueMap.get(Constants.Customer_Onboarding_Queue);
        Group surveyQueue = queueMap.get(Constants.SURVEY_QUEUE);
        Group dlpQueue = queueMap.get(Constants.DLP_QUEUE);
        Group postSalesCaseQueue = queueMap.get('Post Sales Queue');
        Group admCommunityCaseQueue =queueMap.get('ADM Community');
        Group admRegCaseQueue = queueMap.get('ADM Registration');
        Group commsRegCaseQueue =queueMap.get('Comms Queue');
        Group homeFinanceQueueQueue = queueMap.get('Home Finance Queue');
        Group goldenVisaCaseQueue = queueMap.get('Golden Visa');
        // Case Revamp : For getting record ID
        Map<String, id> recordMap = recordInformation();
        Id feedbackRecordTypeId = recordMap.get(Constants.FEEDBACK_CASE_RT);
        Id standardRecordTypeId = recordMap.get( Constants.STANDARD_CASE_RT);
        Id corporateLegalRecordTypeId = recordMap.get(Constants.LEGAL_CASE_RT);
        Id dlpRecordTypeId = recordMap.get(Constants.DLP_CASE_RT); 
        Id devcontrolRT=  recordMap.get(Constants.Development_Control);       
        //Case Revamp:New record types
        Id QueriesRecordTypeId = recordMap.get(Constants.Queries);
        Id ComplaintsRecordTypeId =  recordMap.get(Constants.Complaints);
        Id RequestsRecordTypeId =  recordMap.get(Constants.Requests);
        /* Added by Cloudzlab to handle ECSS Record Types */
        Id ECSSQueriesRecordTypeId = recordMap.get(Constants.ECSSQueries);
        Id ECSSComplaintsRecordTypeId =  recordMap.get(Constants.ECSSComplaints);
        //Id ECSSRequestsRecordTypeId =  recordMap.get(Constants.ECSSRequests);
        Id ECSSMaintenanceRecordTypeId =  recordMap.get(Constants.ECSSMaintenance);
        Set<Id> assetIds = new Set<Id>();
        map<Id,String> caseCatSubCatMap = new map<Id,String>();
        string ecssMapKey='';
         List<Case> ecssCases = new List<Case>();
         Group ECSS_CaseHandlingQueue = [SELECT Id from Group where Type='Queue' and DeveloperName= :System.Label.ECSS_CaseHandling_Queue Limit 1];
        /* End */
        
        String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Profile.Name;
        
        List<String> standardRecordskip = System.label.Case_Standard_record_type_skip.split(','); //For standard case error validation
        List<String> CaseConversionSkipsubvertical = System.label.Skip_converstion_subvertical.split(',');
        map<Id,String> caseSubVerticalMapNew = new map<Id,String>();
        Set<Id> skipRecordTypeIds = new Set<Id>{QueriesRecordTypeId,ComplaintsRecordTypeId,RequestsRecordTypeId};              
        
        //R3 changes by Smaartt
        String DevControlRTName = Label.DevControRT;               
        Map<String,List<Id>> objectNameWithListOfIds = new Map<String,List<Id>>();
        User loggedInUser = Utilities.getLoggedInUserDetail();
        Set<Id> assetIdsCaseInRestictedType = new Set<Id>();//livin Changes
        Map<String,Case> caseCategoryIdVsExistingGeneralCaseInRestrictedType = new Map<String,Case>();// livin Changes
        Map<Id,Id> assetIdMappedToUnit = new Map<Id,Id>();
        Map<Id,Id> unitIdMappedToSalesOrder = new Map<Id,Id>();
        
        for(Case caseRecord : (List<Case>)newList){ 
              if(caseRecord.Priority =='P3'  && caseRecord.Origin =='Email'
               && caseRecord.Recordtype_Name__c =='ECSS_Email_to_Case' && caseRecord.Description!=null
               ){
                   if(caseRecord.Description.contains('Classification : Internal General Purpose')){
                       String delimiter = 'Classification : Internal General Purpose';

						// Find the position of the delimiter
						Integer pos = caseRecord.Description.indexOf(delimiter);

						// Extract the part before the delimiter
						String result;

						if(pos != -1) {
    						result = caseRecord.Description.substring(0, pos).trim();
						} else {
    						// If delimiter not found, store whole string or handle accordingly
    							result = caseRecord.Description;
						}
                		caseRecord.Description = result;
                   }
                   
                
            }
            //Case revamp:New trigger merge
            if(caseRecord.RecordTypeId == QueriesRecordTypeId || caseRecord.RecordTypeId == ComplaintsRecordTypeId || caseRecord.RecordTypeId == RequestsRecordTypeId){
                caseSubVerticalMapNew.put(caseRecord.Id, caseRecord.SubCategory__c);                             
                //Case revamp:For queries record type                  
                if(caseRecord.RecordTypeId == QueriesRecordTypeId){                   
                    caseRecord.FCR__c = true;
                    caseRecord.Assigned_To__c = UserInfo.getUserId();
                    caseRecord.Status = Constants.CLOSED_CASE; 
                    //For qualtric survey **Need to Check**
                    //caseRecord.Survey_Required__c=true;
                    //caseRecord.Survey_Point__c=Constants.CLOSED_CASE;
                }    
                if(!Test.isRunningTest() && caseRecord.IsScreenCase__c == False && (caseRecord.origin !='Customer Portal' && caseRecord.origin != 'Email') && (UserInfo.GetUsername() != system.label.Integration_Username  && UserInfo.GetUsername() != system.label.Aldar_development_username && profileName != system.label.Case_profile_system_admin ))
                {
                    caseRecord.addError('Case using RecordType Queries,Request,Complaint can only create via Account');
                }
                //Case : KAR changes
                if(caseRecord.CaseCategory__c == System.label.Case_KAR_category && caseRecord.Unit__c != null) {
                    caseUnit.add(caseRecord.Unit__c);
                }
                
               
            }
            /* Added by Cloudzlab to handle ECSS Record Types */
            else if(caseRecord.RecordTypeId == ECSSQueriesRecordTypeId || caseRecord.RecordTypeId == ECSSComplaintsRecordTypeId || caseRecord.RecordTypeId == ECSSMaintenanceRecordTypeId){
                ecssCases.add(caseRecord);
                if(caseRecord.SubVertical__c == 'Provis' && caseRecord.ECSS_CompanyOptions__c == 'Provis' && (caseRecord.CaseCategory__c =='Pet Registration' || caseRecord.CaseCategory__c =='Access Card' || caseRecord.CaseCategory__c =='Booking' ||caseRecord.CaseCategory__c =='Community Management' ||caseRecord.CaseCategory__c =='Common Area Maintenance' || caseRecord.CaseCategory__c =='NOC for Unit modifications'|| caseRecord.CaseCategory__c =='Out of home'|| caseRecord.CaseCategory__c =='Community Management/OA' )){
                   assetIds.add(caseRecord.AssetId);
                }
                
                //Tenant Onboarding
                if(caseRecord.RecordTypeId == ECSSQueriesRecordTypeId && caseRecord.CaseCategory__c =='Tenant Onboarding' && caseRecord.Status == Constants.CASE_IN_PROGRESS){
                   assetIds.add(caseRecord.AssetId);
                }
                
                if(System.Label.GeneralCaseTypeResctric.split(';').contains(caseRecord.CaseCategory__c) && caseRecord.AssetId  != null)//livin changes
                {
                    assetIdsCaseInRestictedType.add(caseRecord.AssetId);
                }
                if(caseRecord.RecordTypeId == ECSSMaintenanceRecordTypeId)
                {
                    ecssMapKey = caseRecord.SubVertical__c+'|'+caseRecord.CaseCategory__c+'|'+caseRecord.ECSS_Sub_Category_Text__c;
                    if(ECSS_CaseHandlingQueue!=null){
                        caseRecord.ownerId = ECSS_CaseHandlingQueue.Id;
                }
                    
                }
                else
                    ecssMapKey = caseRecord.SubVertical__c+'|'+caseRecord.CaseCategory__c+'|'+caseRecord.ECSS_Object_Category__c+'|'+caseRecord.ECSS_Sub_Category_Text__c;
                
                caseCatSubCatMap.put(caseRecord.Id,ecssMapKey);
                
                // caseSubVerticalMapNew.put(caseRecord.Id, caseRecord.ECSS_Sub_Category__c); 
                if(caseRecord.ECSS_Created_From_Component__c && (caseRecord.RecordTypeId == ECSSQueriesRecordTypeId || caseRecord.RecordTypeId == ECSSComplaintsRecordTypeId))
                    assetIds.add(caseRecord.AssetId);
                
            }
            /* End */
            else{
                //Case revamp:Changing record type to requests for email and customerportal cases

                              
                if(caseRecord.RecordTypeId == StandardRecordTypeId && (caseRecord.Origin == 'Customer Portal' || caseRecord.Origin == 'Customer App') && system.label.Revamp_Case_toggle.tolowercase() == 'true' && !CaseConversionSkipsubvertical.contains(caseRecord.SubVertical__c) ){
                    caseRecord.RecordTypeId = RequestsRecordTypeId;                       
                }                
                //Case revamp : Email validation same day 1 email with same account and subject
                if((caseRecord.RecordTypeId == StandardRecordTypeId || caseRecord.RecordTypeId == RequestsRecordTypeId ) && caseRecord.Origin == 'Email' && system.label.Case_Email_Validation_Switch.tolowercase() == 'true'){
                     emailCases.add(caseRecord);
           if (caseRecord.SuppliedEmail != null) {
                     emailCasesSuppliedEmails.add(caseRecord.SuppliedEmail.toLowerCase());                     
                 }                     
                }
                
                if(caseRecord.RecordTypeId == StandardRecordTypeId && caseRecord.Origin == 'Email' && system.label.Revamp_Case_email_converstion.tolowercase() == 'true'){
                    caseRecord.RecordTypeId = RequestsRecordTypeId; 
                }
                
                
                //Case revamp : standard case sub vertical validation
                if (!Test.isRunningTest() && caseRecord.RecordTypeId == StandardRecordTypeId && !standardRecordskip.contains(caseRecord.SubVertical__c) &&  (UserInfo.GetUsername() != system.label.Integration_Username && UserInfo.GetUsername() != system.label.Aldar_development_username && profileName != system.label.Case_profile_system_admin )  && system.label.Revamp_case_subvertical.tolowercase() == 'true' && caseRecord.Origin != 'Email'){
                    caseRecord.addError('The selected vertical and sub vertical combination is not allowed for this record type. Please review your selections and select a revamped record type.');
                }
                
               
                //Case revamp:For starting entitilements
                if(caseRecord.RecordTypeId == RequestsRecordTypeId  || caseRecord.RecordTypeId == ComplaintsRecordTypeId){
                    If(caseRecord.Priority == 'P1'){
                        caseRecord.EntitlementId =System.label.Case_Normal_Entitlement_ID;
                    }Else If(caseRecord.Priority == 'P2'){
                        caseRecord.EntitlementId =System.label.Case_Complaint_Request_P2;
                    }Else If(caseRecord.Priority == 'P3'){
                        caseRecord.EntitlementId =System.label.Case_Complaint_Request_P3;
                    }                    
                }  
               
            
            if(caseRecord.RecordId__c != null){                
                Id recId = null;
                String sObjName = null;
                try{
                    recId = Id.valueOf(caseRecord.RecordId__c.split('#')[0]);
                    sObjName = recId.getSObjectType().getDescribe().getName();
                } Catch(Exception e){
                    recId = null;
                    sObjName = null;
                }

                if(sObjName != null && recId != null){

                    if(objectNameWithListOfIds.containsKey(sObjName)){
                        objectNameWithListOfIds.get(sObjName).add(recId);
                    } else{
                        objectNameWithListOfIds.put(sObjName, new List<Id>{(recId)});
                    }
                }
            }

            if(caseRecord.SubVertical__c == Constants.CONTACT_CENTRE_SUB_VERTICAL){
                
                //if(caseRecord.CaseCategory__c != null && (caseRecord.CaseCategory__c == Constants.QUALTRICS_SURVEY_CATEGORY || Constants.RELATED_TO_QUALTRICS_SURVEY.contains(caseRecord.CaseCategory__c))){
                if(caseRecord.CaseCategory__c == Constants.QUALTRICS_SURVEY_CATEGORY){
                    if(caseRecord.SubCategory__c == Constants.NO_RESPONSE_SUB_CATEGORY){
                        caseRecord.RecordTypeId = standardRecordTypeId;
                    } else {
                        caseRecord.RecordTypeId = feedbackRecordTypeId;
                    }
                } else if(caseRecord.CaseCategory__c == Constants.CONTACT_DETAILS_UPDATE_CATEGORY){
                        caseRecord.RecordTypeId = standardRecordTypeId;
                }
            }
            
             if(caseRecord.RecordTypeId == corporateLegalRecordTypeId){
                  caseRecord.Status = 'Legal Notice';
            }
            

            if(loggedInUser.Profile.Name == Constants.CONTACT_CENTER_AGENT && caseRecord.RecordTypeId != ResaleConstants.Resale_Case_RecordTypeId ){
                caseRecord.CCAOwner__c = caseRecord.OwnerId;
               //R3 changes by smaartt                                                          //2.2 change here
                if(caseRecord.RecordTypeId != dlpRecordTypeId && caseRecord.RecordTypeId != recordMap.get(System.Label.AMCRecTypeLabel))               
                caseRecord.Status = Constants.CASE_WORK_IN_PROGRESS;
            }
        }
        }
        //livin changes
        if(!assetIdsCaseInRestictedType.isEmpty()){
            List<Case> generalCaseListInRestrictedType = [Select Id,CaseCategory__c,Unit__c, Status from Case where AssetId IN :assetIdsCaseInRestictedType
                                                          AND Status NOT IN('Closed','Cancelled')
                                                          AND CaseCategory__c IN ('Out of home','NOC for Unit modifications','Access Card')];
            
            For(Case currentCase :generalCaseListInRestrictedType){
                caseCategoryIdVsExistingGeneralCaseInRestrictedType.put(currentCase.CaseCategory__c,currentCase);
            }
        }
        
        if(!assetIds.isEmpty()){
            
            List<Asset> assetList = [Select Id, Unit__c from Asset where Id IN :assetIds];
            
            For(Asset currentAsset : assetList){
                if(currentAsset.Unit__c != null)
                    assetIdMappedToUnit.put(currentAsset.Id,currentAsset.Unit__c);
            }
        }
        
        if(assetIdMappedToUnit.values().Size()>0){
            List<SalesOrder__c> salesorderList = [Select Id,Unit__c from SalesOrder__c where Status__c  NOT IN ('Cancelled','Cancelled By User') And Unit__c IN :assetIdMappedToUnit.values()];
            
            For(SalesOrder__c salesOrder : salesorderList){
                if(salesOrder.Unit__c != null)
                    unitIdMappedToSalesOrder.put(salesOrder.Unit__c,salesOrder.Id);
            }
        }
        
        //Case : KAR changes
        if(!caseUnit.isEmpty()) {
            List<HexaBPM__Service_Request__c> servKar = [SELECT Id, Unit__c, HOKAR__c FROM HexaBPM__Service_Request__c 
                                            WHERE HexaBPM__Record_Type_Name__c = 'Handover' 
                                            AND Unit__c IN :caseUnit 
                                            AND HOKAR__c != null];
            
            for(HexaBPM__Service_Request__c sr : servKar) {
                karMap.put(sr.Unit__c, sr.HOKAR__c);
            }
        }

        
        
        //Case revamp : email validation 
        if (!emailCases.isEmpty() && !emailCasesSuppliedEmails.isEmpty()) {            
           caseEmailValidation(emailCases,emailCasesSuppliedEmails);             
        }

        if(objectNameWithListOfIds.size() > 0){
           populateFieldsFromRecordIdField(newList, objectNameWithListOfIds);
        }  
         //Case revamp:New case trigger fields populate
        if(caseSubVerticalMapNew.size() > 0){            
            populateSubVerticalDependentInfoNew(caseSubVerticalMapNew, newList, null);                
        }  
        
        for(Case caseRecord : (List<Case>)newList){ 
            
            //livin changes
            if(System.Label.GeneralCaseTypeResctric.split(';').contains(caseRecord.CaseCategory__c) && caseCategoryIdVsExistingGeneralCaseInRestrictedType.get(caseRecord.CaseCategory__c)!= null){
                caseRecord.addError('Duplicate General Case Not Allowed For Out of home,NOC for Unit modifications and Access Card');
            }
            
            if(caseRecord.RecordTypeId == ECSSQueriesRecordTypeId || caseRecord.RecordTypeId == ECSSComplaintsRecordTypeId){
                if(caseRecord.SubVertical__c == 'Provis' && caseRecord.ECSS_CompanyOptions__c == 'Provis' && (caseRecord.CaseCategory__c =='Pet Registration' || caseRecord.CaseCategory__c =='Access Card' || caseRecord.CaseCategory__c =='Booking' ||caseRecord.CaseCategory__c =='Community Management' ||caseRecord.CaseCategory__c =='Common Area Maintenance' || caseRecord.CaseCategory__c =='NOC for Unit modifications'|| caseRecord.CaseCategory__c =='Out of home'|| caseRecord.CaseCategory__c =='Community Management/OA' )){
                    
                    if(assetIdMappedToUnit.get(caseRecord.assetId) !=  null){
                        caseRecord.Unit__c = assetIdMappedToUnit.get(caseRecord.assetId);
                        caseRecord.SalesOrder__c = unitIdMappedToSalesOrder.get(assetIdMappedToUnit.get(caseRecord.assetId));
                    }
                    
                    if(caseRecord.CaseCategory__c == 'Community Management/OA'){
                        caseRecord.Type = 'Other Requests';
                    }
                    else if(caseRecord.CaseCategory__c == 'Community Management'){
                        caseRecord.Type = 'Complaints';
                    }
                    else{
                        caseRecord.Type = caseRecord.CaseCategory__c;
                    }
                }
            }
            
            ////Case : KAR changes
            if(karMap.containsKey(caseRecord.Unit__c)) {
                caseRecord.KAR__c = karMap.get(caseRecord.Unit__c);
            }
            
            if(caseRecord.AccountId != null){
                accountIDToRecMap.put(caseRecord.AccountId, null);
            }
            //Case revamp : To skip new record types
            if(!skipRecordTypeIds.contains(caseRecord.RecordTypeId)){
                system.debug('NSV entered');
            String recordTypeName = caseRecord.recordTypeId != null ? Utilities.getRecordTypeName('Case', caseRecord.recordTypeId) : '';
            
            if(caseRecord.SalesOrder__c != null && recordTypeName != ResaleConstants.Resale_Case_RecordTypeName  && caseRecord.recordTypeId != corporateLegalRecordTypeId){
                caseWithSalesOrderMap.put(caseRecord.Id, caseRecord.SalesOrder__c);
            }
            if(recordTypeName == Constants.DLP_CASE_RT && caseRecord.ParentId == null && caseRecord.Priority != 'Emergency' &&
               caseRecord.Origin != 'Customer Portal' && caseRecord.Origin != 'Customer App' && caseRecord.Single_DLP_slot__c )
            {
                UnitIdsList.add(caseRecord.Unit__c);
            }    
            //R3 changes by smaartt                            //v2.1 change here         
            if ( recordTypeName == Label.DM_CAFM_RecType || recordTypeName == Constants.FEEDBACK_CASE_RT|| recordTypeName ==System.Label.AMCRecTypeLabel || recordTypeName == Constants.DLP_CASE_RT || recordTypeName == Constants.STANDARD_CASE_RT || recordTypeName == Constants.HOME_FINANCE_CASE_RT || recordTypeName ==DevControlRTName){
                caseSubVerticalMap.put(caseRecord.Id, caseRecord.SubVertical__c);
                if(caseRecord.SubVertical__c != Constants.DLP_SUB_VERTICAL && caseRecord.SubVertical__c != Constants.DLP_CONTRACTOR_SUB_VERTICAL && recordTypeName !=System.Label.AMCRecTypeLabel ){
                    caseRecord.EntitlementId = entitlementId ;
                }else{
                     if(caseRecord.Vertical__c == Constants.DLP_VERTICAL && caseRecord.CaseCategory__c != System.Label.ODCaseCategoty)
                         caseRecord.EntitlementId = dlpEntitlementId;
                    if(caseRecord.Priority =='Emergency')
                        caseRecord.EntitlementId = dlpEmergEntitlementId ; 
                    else if(caseRecord.SubCategory__c =='PPM Visit' || caseRecord.SubCategory__c =='PMA Visit') 
                        caseRecord.EntitlementId = System.Label.AMCEntitlementId ; 
                     else if(caseRecord.CaseCategory__c == System.Label.ODCaseCategoty) 
                        caseRecord.EntitlementId = System.Label.AMC_OD_Entitlement_Id ;
                }                
                //R3 changes by smaartt
                //if(caseRecord.CaseCategory__c != null && (caseRecord.CaseCategory__c == Constants.QUALTRICS_SURVEY_CATEGORY || Constants.RELATED_TO_QUALTRICS_SURVEY.contains(caseRecord.CaseCategory__c)) && caseRecord.Origin == Constants.SURVEY_CASE_ORIGIN){
                if (caseRecord.Origin != Constants.CASE_ORIGIN_CUSTOMER_PORTAL && caseRecord.Origin != Constants.CASE_ORIGIN_CUSTOMER_APP) {
                    if(caseRecord.CaseCategory__c == Constants.QUALTRICS_SURVEY_CATEGORY && caseRecord.Origin == Constants.SURVEY_CASE_ORIGIN){
                        caseRecord.OwnerId = surveyQueue.Id;
                    } else if(((caseRecord.SubVertical__c == Constants.DLP_SUB_VERTICAL || caseRecord.SubVertical__c == Constants.DLP_CONTRACTOR_SUB_VERTICAL) && recordTypeName == Constants.STANDARD_CASE_RT) ||
                    recordTypeName == Constants.DLP_CASE_RT){
                        caseRecord.OwnerId = dlpQueue.Id;
                        //if(recordTypeName != Constants.DLP_CASE_RT)
                         // caseRecord.AsiteSyncStatus__c = Constants.STATUS_IN_PROGRESS;
                        if(caseRecord.ResolutionType__c == ''){
                            caseRecord.ResolutionType__c = 'Repair';
                        }
                        //TODO Needs to review ASF-426
                    }else if(caseRecord.SubVertical__c != null && caseRecord.SubVertical__c=='Customer Care'){
                        /* if(caseRecord.CaseCategory__c == 'Golden Visa'){    // Commented by Muzammil on 13/12 for Ice Ridge deployment
                            caseRecord.OwnerId = goldenVisaCaseQueue.Id;
                        } else{*/
                            caseRecord.OwnerId = postSalesCaseQueue.Id;
                       // }
                    }else if(caseRecord.SubVertical__c != null && caseRecord.SubVertical__c=='CMO'){
                         caseRecord.OwnerId = admCommunityCaseQueue.Id;
                    }else if(caseRecord.SubVertical__c != null && caseRecord.SubVertical__c=='ADM Services'){
                         caseRecord.OwnerId = admRegCaseQueue.Id;
                    }else if(caseRecord.SubVertical__c != null && caseRecord.SubVertical__c=='Comms'){
                         caseRecord.OwnerId = commsRegCaseQueue.Id;
                    }else if(caseRecord.SubVertical__c != null && caseRecord.SubVertical__c=='Home Finance'){
                         caseRecord.OwnerId = homeFinanceQueueQueue.Id;
                    }
                } else {
                   // caseRecord.AsiteSyncStatus__c = Constants.STATUS_IN_PROGRESS;
                    if(caseRecord.ResolutionType__c == ''){
                        caseRecord.ResolutionType__c = 'Repair';
                    }
                }
                if(caseRecord.SubVertical__c== System.Label.Case_Subvertical_Onboarding){
                    caseRecord.ADM_Email__c = System.Label.Case_Subvertical_Onboarding_email;
                    caseRecord.OwnerId = Onboarding.Id;
                    if (caseRecord.AccountId != null) {                        
                          accountIds.add(caseRecord.AccountId);
                        }                    
                }
                else if (caseRecord.SubVertical__c==System.Label.Case_Subvertical_GCEO_Comms){
                    caseRecord.ADM_Email__c =System.Label.Case_Subvertical_GCEO_Comms_email;                                                           
                }
                else if (caseRecord.SubVertical__c==System.Label.Case_Subvertical_Riyadh_city){
                    caseRecord.ADM_Email__c =System.Label.Riyadh_city_Email;
                }
                
            }
          }
        }
        
        Map<Id, Case> accountRecordMap = new Map<Id, Case>(); 
        if(accountIds.size() > 0)
        {
            for (Case matchingCase : [SELECT Id, OwnerId, Owner.IsActive, AccountId FROM Case WHERE AccountId IN :accountIds AND SubVertical__c = :System.Label.Case_Subvertical_Onboarding AND Status =: Constants.CLOSED_CASE ORDER BY CreatedDate DESC]) {
            accountRecordMap.put(matchingCase.AccountId, matchingCase);           
            }
        }
      accountIDToRecMap = new map<Id,account>([SELECT Id, Company__pc, Position__pc, CompanyAddress__pc, NoofYearswithCompany__pc, Industry, AnnualIncome__pc, Name,RecordType.Name, PersonContactId, FirstName, MiddleName, LastName, PassportNumber__pc, ResidentStatus__pc, MaritalStatus__pc, EmploymentStatus__pc, PersonEmail, MobilePhone__pc, MobileCountryCode__pc,IsPersonAccount,MobileNumber__c from Account WHERE ID IN:accountIDToRecMap.keyset()]);
          
        for(Case caseRecord : (List<Case>)newList){
            
            String recordTypeName = caseRecord.recordTypeId != null ? Utilities.getRecordTypeName('Case', caseRecord.recordTypeId) : '';
            if(caseRecord.AccountId != null){
                if(accountIDToRecMap.containsKey(caseRecord.AccountId) && accountIDToRecMap.get(caseRecord.AccountId) != null &&
                   accountIDToRecMap.get(caseRecord.AccountId).RecordType.Name == Constants.PERSON_ACCOUNT_RT &&
                   (recordTypeName != Constants.DLP_CASE_RT || (recordTypeName == Constants.DLP_CASE_RT && caseRecord.CustomerType__c == 'Owner'))
                  ){
                      caseRecord.ContactId = accountIDToRecMap.get(caseRecord.AccountId).PersonContactId;
                  }
                if( (caseRecord.SubVertical__c == Constants.DLP_SUB_VERTICAL || caseRecord.SubVertical__c == Constants.DLP_CONTRACTOR_SUB_VERTICAL ) && accountIDToRecMap.containsKey(caseRecord.AccountId)){
                    Boolean isEmptyMobile=false;
                    if(accountIDToRecMap.get(caseRecord.AccountId).IsPersonAccount){
                        isEmptyMobile=String.isBlank(accountIDToRecMap.get(caseRecord.AccountId).MobilePhone__pc);
                    }else {
                        isEmptyMobile=String.isBlank(accountIDToRecMap.get(caseRecord.AccountId).MobileNumber__c);
                    }
                    if(isEmptyMobile){
                        caseRecord.addError(Utilities.getSystemMessages(Constants.DLP_CUSTOMER_MOBILE_NUMBER_VALIDATION).Message__c);
                    }
                    
                }
            }
            //Case revamp : To skip new record types         
            if(!skipRecordTypeIds.contains(caseRecord.RecordTypeId)){
                
                if(caseRecord.SubVertical__c==System.Label.Case_Subvertical_Onboarding && caseRecord.AccountId != null){
                    
                    Case matchingCase = accountRecordMap.get(caseRecord.AccountId);            
                    
                    if (matchingCase != null && matchingCase.Owner.IsActive && matchingCase.OwnerId != null && String.valueOf(matchingCase.OwnerId).startsWith('005')) {
                        
                        caseRecord.OwnerId = matchingCase.OwnerId;
                    }
                }
            }
        }
        
        if(UnitIdsList.size() > 0)
        {            
            List<Case> caselist = [Select Id, ParentId, CaseNumber, (select Id, SchedStartTime, SchedEndTime, RecordType.Name from Service_Appointments__r Where RecordType.Name = 'Assessment') 
                                   From Case Where RecordTypeId = :dlpRecordTypeId and Unit__c In :UnitIdsList and ParentId = null and Single_DLP_slot__c = true and Status In :casestatuses order by CreatedDate Desc]; 
            if(caselist.size() > 0){ 
                for(Case csrec : (List<Case>)newList){   ServiceAppointment sa = New ServiceAppointment(); if(csrec.Service_Appointments__r.size() > 0)  sa = csrec.Service_Appointments__r[0];
                    if(sa.SchedEndTime == null || sa.SchedEndTime > DateTime.now()) {  String msg = 'Already Open Case is exist for this Unit. Please create this case as child case by populating Parent case with ' + caselist[0].CaseNumber; csrec.ParentId.addError(msg);}                    
                }
            }
        }  

        if(accountIDToRecMap.size() > 0 ){
            populateCustomerDetailsFromAccount(newList, accountIDToRecMap);
        }

        if(caseWithSalesOrderMap.size() > 0){
           // populateLPCInformation(caseWithSalesOrderMap, newList);
        } 
        
        if(caseSubVerticalMap.size() > 0){
            populateSubVerticalDependentInfo(caseSubVerticalMap, newList, null);
        }

        if(!caseWithSalesOrderMap.isEmpty()){
            customerRelatedToUnitValidation(caseWithSalesOrderMap, newList);
        }
        /*Added by Cloudzlab */
        if(assetIds.size()>0)
        {
            populateOwnerIdfromProjectMetadata(assetIds,newList);
        }
        
        if(caseCatSubCatMap.size()>0)
        {
            populateECSSData(caseCatSubCatMap,newList);
        }
        // To create the new account for case account creation request
        if(!ecssCases.isEmpty()){
            ECSS_CaseTriggerHelper.createRelatedAcc(ecssCases);
        }
        /*End*/
    }

    public static void populateCustomerDetailsFromAccount(list<Case> caseRecords, map<Id,account> accountIDToRecMap){
        for(Case caseRecord : caseRecords){

            if(caseRecord.AccountId != null && (caseRecord.CaseCategory__c == Constants.CONTACT_DETAILS_UPDATE_CATEGORY || caseRecord.SubCategory__c == Constants.CONTACT_DETAILS_UPDATE_CATEGORY)){
                Account accRecord = accountIDToRecMap.get(caseRecord.AccountId);
                if(accRecord != null && accRecord.RecordType.Name == Constants.PERSON_ACCOUNT_RT){
                    caseRecord.PassportNumber__c = accRecord.PassportNumber__pc;
                    caseRecord.ResidentStatus__c = accRecord.ResidentStatus__pc;
                    caseRecord.MaritalStatus__c = accRecord.MaritalStatus__pc;
                    caseRecord.EmploymentStatus__c = accRecord.EmploymentStatus__pc;
                    caseRecord.Email__c = accRecord.PersonEmail;
                    caseRecord.MobileCountryCode__c = accRecord.MobileCountryCode__pc;
                    caseRecord.MobileNumber__c = accRecord.MobilePhone__pc;
                    caseRecord.Company__c = accRecord.Company__pc;
                    caseRecord.Position__c = accRecord.Position__pc;
                    caseRecord.CompanyAddress__c = accRecord.CompanyAddress__pc;
                    caseRecord.NumberOfYearsWithCompany__c = accRecord.NoofYearswithCompany__pc;
                    caseRecord.Industry__c = accRecord.Industry;
                    caseRecord.AnnualIncome__c = accRecord.AnnualIncome__pc;
                }
            }
        }
    }

    //*** Before Update Action***//
    public override void beforeUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        
        updateSalesOrderAndCustomer(newList, oldMap, true);
        ResaleService.beforeActionsOnResaleCase(newList, oldMap, true);

        map<Id,account> accountIDToRecMap = new map<Id,account>();
        map<Id,Id> caseWithSalesOrderMap = new map<Id,Id>();
        List<Case> casesWithTask = new List<Case>();
        Map<Id,Case> transferredCases = new Map<Id,Case>();
        List<Case> reopenCases = new List<Case>();
        map<Id,String> caseSubVerticalMap = new map<Id,String>(); 
        Set<Id> closedcasedIds = new Set<Id>(); // Case revamp : Added by Faaiz for validating the Cases closing without completing tasks
        Set<Id> casesWithOpenTasks = new Set<Id>(); // Case revamp : Added by Faaiz for validating the Cases closing without completing tasks
        Set<Id> srcaseIds = new Set<Id>(); // Case revamp : Added by Faaiz for validating the Cases closing without closing SR
        Set<Id> casesWithOpenSR = new Set<Id>(); // Case revamp : Added by Faaiz for validating the Cases closing without closing SR
        List<Id> UnitIdsList = New List<Id>();
        List<Id> caseIdlist = New List<Id>();
        DateTime csdatetime;
        Set<String> casestatuses = new Set<String>{'New', 'Assigned', 'Re-scheduled'};
        String RecordTypeID = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Resolver Task').getRecordTypeId();
        Id dlpRecordTypeId = Utilities.getRecordTypeId('Case', Constants.DLP_CASE_RT);
        Id entitlementId = System.Label.DefaultEntitlementId ;
        Id dlpEntitlementId = System.Label.DLPEntitlementId ;
        //Case : KAR changes
        Set<Id> caseUnit = new Set<Id>();
        Map<Id, String> karMap = new Map<Id, String>();
        
        Map<String, Group> queueMap = caseQueryInformation();
        Group surveyQueue = queueMap.get(Constants.SURVEY_QUEUE);
        Group dlpQueue = queueMap.get(Constants.DLP_QUEUE);
        Group postSaleQueue = queueMap.get(Constants.POST_SALE_QUEUE); //23-09-2024:Harsh changed to Map
        Group cmFinanceQueue = queueMap.get(Constants.CM_FINANCE_QUEUE);//23-09-2024:Harsh changed to Map
        Group newSalesQueue = queueMap.get(Constants.CM_NEW_SALE_QUEUE);
        
        //Case revamp
        Map<String, id> recordMap = recordInformation();
        Id standardRecordTypeId = recordMap.get( Constants.STANDARD_CASE_RT);
        Id QueriesRecordTypeId = recordMap.get(Constants.Queries);
        Id ComplaintsRecordTypeId =  recordMap.get(Constants.Complaints);
        Id corporateLegalRecordTypeId = recordMap.get(Constants.LEGAL_CASE_RT);
        Id RequestsRecordTypeId =  recordMap.get(Constants.Requests);
        map<Id,String> caseSubVerticalMapNew = new map<Id,String>();
        Id amcRecTypeId = recordMap.get(Constants.AMC_CASE_RT);
        Set<Id> skipRecordTypeIds = new Set<Id>{QueriesRecordTypeId,ComplaintsRecordTypeId,RequestsRecordTypeId}; 
        List<case> tasksToInsert = new List<case>();
        //List <String> skipResolvedQueueIds = new List <String>(System.label.Case_Skip_Resovled_Queue_ID.split(','));

        
        /* Added by Cloudzlab to handle ECSS Record Types */
        List<Case> ecssCases = new List<Case>();
        Id ECSSQueriesRecordTypeId = recordMap.get(Constants.ECSSQueries);
        Id ECSSComplaintsRecordTypeId =  recordMap.get(Constants.ECSSComplaints);
        //  Id ECSSRequestsRecordTypeId =  recordMap.get(Constants.ECSSRequests);
        Id ECSSMaintenanceRecordTypeId =  recordMap.get(Constants.ECSSMaintenance);
        map<Id,String> caseCatSubCatMap = new map<Id,String>();
        Set<Id> assetIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        string ecssMapKey='';
        /* End */

        //--- to get the latest case number created from the selected cases.
        Integer newestCaseNumber = 0;
        String newestCaseNumberString = '0';
        //Fifo Logic
        /*String FIFO_Label = system.label.FIFO_Case_Queue;        
        List<String> FIFO_QUEUE = FIFO_Label.split(','); */
         
        //: Mass Ownership Changes
        List<Case> ownershipchangeCases = new List<Case>();
        Map<String, String> MapownerIds = new Map<String,String>();

        // to check if the user picked the oldest case on the queue.
        Id queueId;
        //List<Case> oldestCases = CaseService.getOldestCaseFromQueue(surveyQueue, newestCaseNumberString);
        Map<Id, String> casesOwnerChangedFromQueueToUser = new Map<Id, String>();
        Constant__mdt constantMdt = new Constant__mdt();
        String caseVerticale;
        
        List<String> standardRecordskip = System.label.Case_Standard_record_type_skip.split(','); //For standard case error validation

        User loggedInUser = Utilities.getLoggedInUserDetail();
        List<Id> contactUpdateCasesIds = new List<Id>();
        List<Id> closedcaseids = new List<Id>();
        set<ID> qualtricsEligibleIds=validateQualtricsCaseEligibility(newList, oldMap);
        //System.debug('*** qualtricsEligibleIds ***'+qualtricsEligibleIds);
    List<case> lstOwnerChangeCases = new  List<case>();

        for(Case caseRecord : (List<Case>)newList){            
            Case oldCase = (Case)oldmap.get(caseRecord.Id);
       //logic to handle case owner changes
            if((caseRecord.Status == 'New' || caseRecord.Status =='Assigned' || caseRecord.Status == 'Re-scheduled') && caseRecord.OwnerId != oldCase.OwnerId && !caseRecord.isValidationBypass__c 
               && caseRecord.RecordTypeId == recordMap.get(Constants.DLP_CASE_RT) && caseRecord.CustomerDLPStatus__c == 'Active' && caseRecord.Origin != 'Customer Portal' && caseRecord.Origin != 'Customer App'){
                lstOwnerChangeCases.add(caseRecord);
            }
            
            //district management(added by smaartt) - Start
            Id DmrecordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.DM_CaseRecordType).getRecordTypeId();
            if(caseRecord.Sub_Status__c!=oldCase.Sub_Status__c && caseRecord.RecordTypeId == DmrecordtypeId){
                DMcaseMilestonehandler.milestone(caseRecord,oldCase); 
            }
            //district management(added by smaartt) - end
            
            if(!qualtricsEligibleIds.isEmpty() && qualtricsEligibleIds.contains(caseRecord.Id)){
                 caseRecord.Survey_Required__c=true;
                if(caseRecord.Vertical__c == Constants.DLP_SUB_VERTICAL && caseRecord.SubVertical__c == 'AMC' && caseRecord.AMC_Closure_Reason__c ==System.Label.AMCClosureForComleted)//V2.1 change Start
                    caseRecord.Survey_Point__c=System.Label.Case_AMC;//V2.1 Ends here
                else if(caseRecord.Vertical__c == Constants.DLP_VERTICAL && (caseRecord.SubVertical__c == Constants.DLP_SUB_VERTICAL  || caseRecord.SubVertical__c =='New Sale' ||  caseRecord.SubVertical__c == Constants.DLP_CONTRACTOR_SUB_VERTICAL ))                   {
                    caseRecord.Survey_Point__c=System.Label.Case_DLP_Closed;   
                }else if(caseRecord.SubVertical__c ==System.Label.Case_Home_finance &&  caseRecord.Sub_Status__c==System.Label.Case_Sub_status_loan){
                    caseRecord.Survey_Point__c=System.Label.Case_Home_finance_closed;
                }else if(caseRecord.SubVertical__c ==System.Label.Case_Subvertical_Onboarding) {
                    caseRecord.Survey_Point__c='Customer Onboarding Closed';
                }
                else if(caseRecord.SubVertical__c !=System.Label.Case_Home_finance && caseRecord.SubVertical__c !='Customer Onboarding' && caseRecord.SubVertical__c !='New Sale') {
                    caseRecord.Survey_Point__c=Constants.CLOSED_CASE;
                }
            }
            
            if(caseRecord.RecordTypeId == QueriesRecordTypeId || caseRecord.RecordTypeId == ComplaintsRecordTypeId || caseRecord.RecordTypeId == RequestsRecordTypeId){
                 //Case : KAR changes
                if((caseRecord.CaseCategory__c != oldcase.CaseCategory__c || caseRecord.Unit__c != oldcase.Unit__c) && caseRecord.CaseCategory__c == System.label.Case_KAR_category && caseRecord.Unit__c != null) {
                caseUnit.add(caseRecord.Unit__c);
                } 
                //FIFO LOGIC
               /* IF(caseRecord.Status == 'New' && caseRecord.Assigned_To__c != null && oldcase.Assigned_To__c == null && FIFO_QUEUE.Contains(caseRecord.OwnerId)){
                    casesOwnerChangedFromQueueToUser.put(caseRecord.Id, caseRecord.CaseNumber);
                    if(Integer.valueOf(caseRecord.CaseNumber) > newestCaseNumber){
                        newestCaseNumberString = caseRecord.CaseNumber;
                        newestCaseNumber = Integer.valueOf(caseRecord.CaseNumber);
                    }
                    queueId = caseRecord.OwnerId;                    
                } */
                
                //Case revamp: Added by Faaiz for validating the Cases closing without completing tasks
                if((caseRecord.Status == 'Closed'|| caseRecord.Status == 'Resolved') && caseRecord.Status != oldcase.Status && UserInfo.GetUsername() != system.label.Integration_Username){ 
                    closedcasedIds.add(caseRecord.Id);
                }
                system.debug('closedcasedIds-->'+closedcasedIds);
                //Case revamp: Added by Faaiz for validating the Cases closing without closing SR
                if(caseRecord.Status == 'Closed' && caseRecord.Status != oldcase.Status && caseRecord.SRCreated__c){ 
                    srcaseIds.add(caseRecord.Id);
                }                 
                if(caseRecord.Status != oldCase.Status){
                    caseRecord.Sub_Status__c = null;
                }
                //Case revamp:For changing status when case is assinged to user
                if(caseRecord.Status == 'New' && caseRecord.Assigned_To__c != null && caseRecord.Assigned_To__c != oldcase.Assigned_To__c && oldCase.Ownership_Bulk_Changed__c == caseRecord.Ownership_Bulk_Changed__c){
                    //caseRecord.Status = 'Work In Progress';                    
                }
                //Case revamp:For escalating a case when followup count is greater than a value
                integer Max_count = integer.valueof(system.label.Case_Follow_Up_Count_Escalation);               
                if(caseRecord.Customer_Follow_up_Count__c >= Max_count && caseRecord.Customer_Follow_up_Count__c != oldCase.Customer_Follow_up_Count__c ){
                    caseRecord.Status = 'Escalated';
                } 
               
                
                // Case revamp:For Creating task attempt 1 when case is resolved
                if(caseRecord.Status == 'Resolved' && oldCase.Status == caseRecord.Status && oldCase.Assigned_To__c == null && caseRecord.Assigned_To__c != null && caseRecord.Sub_Status__c != 'Call Attempt 1' && caseRecord.FCR__c == false){
                   tasksToInsert.add(caseRecord); 
                    caseRecord.Sub_Status__c = 'Call Attempt 1';                    
                }
                //Case revamp:To store resolved time, resolver group queue and user when case is resolved
                if(caseRecord.Status == 'Resolved'  && oldCase.Status != caseRecord.Status && caseRecord.FCR__c == false){
                    Caserecord.Resolved_Time__c = system.now();
                    Caserecord.Resolver_Group_Queue_Id__c = oldCase.OwnerId;
                    Caserecord.Resolver_Group_User__c = oldCase.Assigned_To__c;                   
                    if(caseRecord.CaseCategory__c=='Aldar Select') {
                        caseRecord.OwnerId = System.label.Aldar_Select_Queue;
                        caseRecord.Assigned_To__c = null ;
                    } else if(caseRecord.Origin == 'Walk-In'){
                        caseRecord.OwnerId = System.label.Walk_in_team_queue;
                        caseRecord.Assigned_To__c = null ;
                    }
                    //Adarsh - Cases related to Handover,CFR,Baniyas and Al Saad to Shared Service Queue 
                    //else if(skipResolvedQueueIds.contains(oldCase.OwnerId)){
                        //caseRecord.OwnerId = System.label.Shared_Service_Queue_ID;
                        //caseRecord.Assigned_To__c = null ;
                    //}
                    else if (!(caseRecord.OwnerId == System.label.Walk_in_team_queue && caseRecord.Origin == 'Email')){
                        caseRecord.OwnerId = System.label.Contact_center_team_queue;
                        caseRecord.Assigned_To__c = null ;
                    }                    
                }
                // For Escalation Team Review 
                if((Caserecord.Status == Constants.CASE_WORK_IN_PROGRESS ||Caserecord.Status == 'Escalated' || Caserecord.Status == 'Re Opened' )  && (oldCase.Status == 'Resolved' || oldCase.Status == 'Closed') && oldCase.Status != caseRecord.Status){
                  
                    if(Caserecord.Status == Constants.CASE_WORK_IN_PROGRESS){
                        Caserecord.Is_resolver_escalation__c = true;  
                    }
                    if(Caserecord.Resolver_Group_Queue_Id__c != null){
                        Caserecord.OwnerId = Caserecord.Resolver_Group_Queue_Id__c;
                    }
                    Caserecord.Assigned_To__c = Caserecord.Resolver_Group_User__c;
                   
                }
                
                if(oldCase.Ownership_Bulk_Changed__c != caseRecord.Ownership_Bulk_Changed__c)
                {
                    
                    ownershipchangeCases.add(caseRecord);
                    MapownerIds.put(caseRecord.id, oldCase.OwnerId);
                    caseRecord.Ownership_Bulk_Changed__c = oldCase.Ownership_Bulk_Changed__c;
                    
                }
                
                if(oldCase.Assigned_To__c != caseRecord.Assigned_To__c && oldCase.Assigned_To__c != null)
                {
                    caseRecord.Previous_Owner__c = oldCase.Assigned_To__c;
                }
                
                if(caseRecord.Recordtype_Name__c != Constants.Queries)
                {
                    if(oldCase.Status != caseRecord.Status){
                        
                        caseRecord.Previous_Status__c = oldCase.Status;
                        if(caseRecord.Status != 'New' && caseRecord.Status != 'Closed')
                        {
                            RefreshComp__e event = new RefreshComp__e(
                                message__c = 'status-'+caseRecord.Status+'-'+caseRecord.RecordTypeId+'-'+caseRecord.Id);
                            Database.SaveResult result = EventBus.publish(event);
                        }
                        
                    }                                        
                    if(oldCase.Sub_Status__c != caseRecord.Sub_Status__c){
                        if(caseRecord.Sub_Status__c != 'Pending with other Department' && caseRecord.Sub_Status__c != 'Follow up by other Department')
                        {
                            caseRecord.Previous_SubStatus__c = oldCase.Sub_Status__c;
                            RefreshComp__e event = new RefreshComp__e(
                                message__c = 'Substatus-'+caseRecord.Sub_Status__c );
                            Database.SaveResult result = EventBus.publish(event);
                        }
                        
                    }
                }                         
                
                //Case revamp : To populate new fields when subvertical,Case category,Sub category or record type changes.
                if(caseRecord.SubVertical__c != oldCase.SubVertical__c || caseRecord.CaseCategory__c != oldCase.CaseCategory__c || caseRecord.SubCategory__c != oldCase.SubCategory__c || caseRecord.RecordTypeId != oldCase.RecordTypeId || (caseRecord.FCR__c != oldcase.FCR__c && caseRecord.FCR__c == false)){
                    caseSubVerticalMapNew.put(caseRecord.Id, caseRecord.SubCategory__c);
                    //caseRecord.Assigned_To__c = null;                   
                }
                //Case revamp : If record type Changed to quries
                if(caseRecord.RecordTypeId != oldcase.RecordTypeId && caseRecord.RecordTypeId == QueriesRecordTypeId){
                    caseRecord.Status = 'Closed';
                    caseRecord.FCR__c = true;
                }
                if(caseRecord.FCR__c != oldcase.FCR__c && caseRecord.FCR__c == true){ 
                    caseRecord.Assigned_To__c = null;
                    
                    if(caseRecord.Origin == 'Walk-In' || oldcase.OwnerId == System.label.Walk_in_team_queue){
                        caseRecord.OwnerId = System.label.Walk_in_team_queue;                                
                    }
                    else {
                        caseRecord.OwnerId = System.label.Contact_center_team_queue;
                    }                       
                }  
                //Case revamp : For entitlement process
                if(caseRecord.RecordTypeId != oldcase.RecordTypeId && ((caseRecord.Recordtype_Name__c == Constants.Requests && caseRecord.FCR__c == false) || caseRecord.Recordtype_Name__c == Constants.Complaints)){
                   
                    caseRecord.FCR__c = false;
                    If(caseRecord.Priority == 'P1'){
                        caseRecord.EntitlementId =System.label.Case_Normal_Entitlement_ID;
                    }Else If(caseRecord.Priority == 'P2'){
                        caseRecord.EntitlementId =System.label.Case_Complaint_Request_P2;
                    }Else If(caseRecord.Priority == 'P3'){
                        caseRecord.EntitlementId =System.label.Case_Complaint_Request_P3;
                    }   
                 
                }  
            }
            //FSL Closed Looping
            else if(caseRecord.Status == Constants.Resolved  && oldCase.Status != caseRecord.Status && (caserecord.RecordTypeId == amcRecTypeId || caserecord.RecordTypeId == dlpRecordTypeId)){
                Caserecord.Resolved_Time__c = system.now();
                caseRecord.OwnerId = System.label.Contact_center_team_queue;
                caseRecord.Assigned_To__c = null ;
            } 
            else if((caserecord.RecordTypeId == dlpRecordTypeId || caserecord.RecordTypeId == amcRecTypeId) && caseRecord.Status == 'Resolved' && oldCase.Status == caseRecord.Status && oldCase.Assigned_To__c == null && caseRecord.Assigned_To__c != null && caseRecord.Sub_Status__c != 'Call Attempt 1' ){
                tasksToInsert.add(caseRecord);
                caseRecord.Sub_Status__c = 'Call Attempt 1';                   
            }               
            /* Added by Cloudzlab to handle ECSS Record Types */
            else if(caseRecord.RecordTypeId == ECSSQueriesRecordTypeId || caseRecord.RecordTypeId == ECSSComplaintsRecordTypeId || caseRecord.RecordTypeId == ECSSMaintenanceRecordTypeId){
                ecssCases.add(caseRecord);
                //Case revamp : To populate new fields when subvertical,Case category,Sub category or record type changes.
                if(caseRecord.SubVertical__c != oldCase.SubVertical__c || caseRecord.CaseCategory__c != oldCase.CaseCategory__c || caseRecord.ECSS_Sub_Category_Text__c != oldCase.ECSS_Sub_Category_Text__c || caseRecord.RecordTypeId != oldCase.RecordTypeId ){
                    
                    if(caseRecord.RecordTypeId == ECSSMaintenanceRecordTypeId)
                        ecssMapKey = caseRecord.SubVertical__c+'|'+caseRecord.CaseCategory__c+'|'+caseRecord.ECSS_Sub_Category_Text__c;
                    else
                        ecssMapKey = caseRecord.SubVertical__c+'|'+caseRecord.CaseCategory__c+'|'+caseRecord.ECSS_Object_Category__c+'|'+caseRecord.ECSS_Sub_Category_Text__c;
                    
                    caseCatSubCatMap.put(caseRecord.Id,ecssMapKey);
                    
                    // caseCatSubCatMap.put(caseRecord.Id,caseRecord.SubVertical__c+'|'+caseRecord.CaseCategory__c+'|'+caseRecord.ECSS_Sub_Category_Text__c);
                    //caseSubVerticalMapNew.put(caseRecord.Id, caseRecord.ECSS_Sub_Category__c);
                    //caseRecord.Assigned_To__c = null;                   
                }
                //if any of the below fields change, reset SLA/entitlement and milestones
                if(caseRecord.AssetId != oldCase.AssetId || caseRecord.SubVertical__c != oldCase.SubVertical__c || caseRecord.CaseCategory__c != oldCase.CaseCategory__c || caseRecord.ECSS_Sub_Category_Text__c != oldCase.ECSS_Sub_Category_Text__c || caseRecord.ECSS_Object_Category__c != oldCase.ECSS_Object_Category__c){
                    
                    if(caseRecord.ECSS_Created_From_Component__c && (caseRecord.RecordTypeId == ECSSQueriesRecordTypeId || caseRecord.RecordTypeId == ECSSComplaintsRecordTypeId))
                    {   
                        caseIds.add(caseRecord.Id);
                        assetIds.add(caseRecord.AssetId);
                    }
                }
                
                //Living changes Close Case looping
                if(System.Label.GeneralCaseType.split(';').contains(caseRecord.Type) && caseRecord.Status == Constants.Resolved  && oldCase.Status != caseRecord.Status && (caserecord.RecordTypeId == ECSSQueriesRecordTypeId || caseRecord.RecordTypeId == ECSSComplaintsRecordTypeId) ){
                    
                    Caserecord.Resolved_Time__c = system.now();
                    caseRecord.OwnerId = System.label.ECSS_Contact_Center_Queue;
                    caseRecord.Assigned_To__c = null ;
                }
                
                if((caseRecord.Status == 'Closed'|| caseRecord.Status == 'Resolved') && caseRecord.Status != oldcase.Status && UserInfo.GetUsername() != system.label.Integration_Username){ 
                    closedcasedIds.add(caseRecord.Id);
                }
                
                if(System.Label.GeneralCaseType.split(';').contains(caseRecord.Type) && caseRecord.Status == 'Resolved' && oldCase.Status == caseRecord.Status && oldCase.Assigned_To__c == null && caseRecord.Assigned_To__c != null && caseRecord.Sub_Status__c != 'Call Attempt 1' && (caserecord.RecordTypeId == ECSSQueriesRecordTypeId || caseRecord.RecordTypeId == ECSSComplaintsRecordTypeId)){
                    tasksToInsert.add(caseRecord);
                    caseRecord.Sub_Status__c = 'Call Attempt 1';
                }
            }  
            /* End */
            else{ 
                String recordTypeName = Utilities.getRecordTypeName('Case', caseRecord.recordTypeId);
                                
                
                if(caseRecord.Status == 'Closed' && caseRecord.Status != oldCase.Status && recordTypeName == Constants.STANDARD_CASE_RT)
                {
                closedcaseids.add(caseRecord.Id);
            }
            System.debug('Point: recordTypeName= ' + recordTypeName);
            caseVerticale = caseRecord.Vertical__c;
            if(caseVerticale != Null && String.isNotBlank(caseVerticale)){
                caseVerticale = caseVerticale.replaceAll( '&', '');
                if(caseRecord.Vertical__c != oldCase.Vertical__c){
                constantMdt = Constant__mdt.getInstance(caseVerticale.replaceAll( '\\s+', ''));
                if(constantMdt != NULL)
                    caseRecord.VerticalHeadEmail__c = constantMdt.ConstantValue__c;
               }
            }
            
            if(recordTypeName == Constants.DLP_CASE_RT && caseRecord.ParentId == null && caseRecord.priority != 'Emergency' &&
               caseRecord.Origin != 'Customer Portal' && caseRecord.Origin != 'Customer App' && caseRecord.Single_DLP_slot__c)
            {
                UnitIdsList.add(caseRecord.Unit__c);
                caseIdlist.add(caseRecord.Id);
                csdatetime = caseRecord.CreatedDate;
            }            
            //Ticket ASF-516
            String caseSubCategory = caseRecord.SubCategory__c;
            if(caseRecord.SubVertical__c =='CMO' &&  caseSubCategory != Null && String.isNotBlank(caseSubCategory)){
                caseSubCategory = caseSubCategory.replaceAll( ' ', '_').removeEnd('_');
                if(caseRecord.SubCategory__c != oldCase.SubCategory__c){
                 Constant__mdt constantMdtALD = Constant__mdt.getInstance(caseSubCategory);
                if(constantMdtALD != NULL)
                    caseRecord.ADM_Email__c = constantMdtALD.ConstantValue__c;
               }
            }
            if(caseRecord.SubVertical__c== System.Label.Case_Subvertical_Onboarding){
                    caseRecord.ADM_Email__c = System.Label.Case_Subvertical_Onboarding_email;
                    
                }
                else if (caseRecord.SubVertical__c==System.Label.Case_Subvertical_GCEO_Comms){
                    caseRecord.ADM_Email__c =System.Label.Case_Subvertical_GCEO_Comms_email;
                }
             else if (caseRecord.SubVertical__c==System.Label.Case_Subvertical_Riyadh_city){
                    caseRecord.ADM_Email__c =System.Label.Riyadh_city_Email;
                }
            
            if(caseRecord.AccountId != null && caseRecord.AccountId != oldCase.AccountId){
                accountIDToRecMap.put(caseRecord.AccountId, null);
            }
            if(caseRecord.SalesOrder__c != null && recordTypeName != ResaleConstants.Resale_Case_RecordTypeName && caseRecord.recordTypeId != corporateLegalRecordTypeId){
                caseWithSalesOrderMap.put(caseRecord.Id, caseRecord.SalesOrder__c);
            }

            if ((recordTypeName == Constants.FEEDBACK_CASE_RT || recordTypeName == Constants.DLP_CASE_RT || recordTypeName == Constants.STANDARD_CASE_RT)
             && oldCase.OwnerId != caseRecord.OwnerId && oldCase.OwnerId.getsobjecttype() != User.sobjecttype ){
                 if(caseRecord.OwnerId.getSObjectType() == User.sObjectType){
                casesOwnerChangedFromQueueToUser.put(caseRecord.Id, caseRecord.CaseNumber);
                 }
                if(Integer.valueOf(caseRecord.CaseNumber) > newestCaseNumber){
                    newestCaseNumberString = caseRecord.CaseNumber;
                    newestCaseNumber = Integer.valueOf(caseRecord.CaseNumber);
                }

                //--- To create "Call Atempt 1" only for Survey related cases.
                if(oldCase.OwnerId == surveyQueue.Id){
                    casesWithTask.add(caseRecord);
                }
                queueId = oldCase.OwnerId;
          
            }

            if ((recordTypeName == Constants.FEEDBACK_CASE_RT || recordTypeName == Constants.DLP_CASE_RT || recordTypeName == Constants.STANDARD_CASE_RT) && oldCase.OwnerId != caseRecord.OwnerId && oldCase.OwnerId.getsobjecttype() != User.sobjecttype && caseRecord.OwnerId.getsobjecttype() != User.sobjecttype){
                transferredCases.put(caseRecord.Id, caseRecord);
            }

            if(oldCase.OwnerId != caseRecord.OwnerId && caseRecord.OwnerId.getsobjecttype() == User.sobjecttype && caseRecord.CCAOwner__c == null && loggedInUser.Profile.Name == Constants.CONTACT_CENTER_AGENT){
                caseRecord.CCAOwner__c = caseRecord.OwnerId;
            }
            
            if(caseRecord.Status != 'Closed' && oldCase.Status == 'Closed'){
                reopenCases.add(caseRecord);               
            }
            
            //Monika: Mass Ownership change restriction
            if(oldCase.Ownership_Bulk_Changed__c != caseRecord.Ownership_Bulk_Changed__c)
                {
                    ownershipchangeCases.add(caseRecord);
                    MapownerIds.put(caseRecord.id, oldCase.OwnerId);
                    caseRecord.Ownership_Bulk_Changed__c = oldCase.Ownership_Bulk_Changed__c;
                }

            if((recordTypeName == Constants.STANDARD_CASE_RT || recordTypeName == Constants.DLP_CASE_RT ) && caseRecord.AccountId != null && (oldCase.CaseCategory__c != caseRecord.CaseCategory__c || oldCase.AccountId != caseRecord.AccountId) && caseRecord.CaseCategory__c == Constants.CONTACT_DETAILS_UPDATE_CATEGORY){
                accountIDToRecMap.put(caseRecord.AccountId, null);
            }

            if (caseRecord.SubVertical__c == Constants.DLP_SUB_VERTICAL && recordTypeName == Constants.STANDARD_CASE_RT && caseRecord.SubVertical__c != oldCase.SubVertical__c) {
                //caseRecord.AsiteSyncStatus__c = Constants.STATUS_IN_PROGRESS;
            }
            //v2.1 change here
            if ( (recordTypeName == Constants.FEEDBACK_CASE_RT || recordTypeName == Constants.DLP_CASE_RT || recordTypeName ==System.Label.AMCRecTypeLabel || recordTypeName == Constants.STANDARD_CASE_RT || recordTypeName == Constants.HOME_FINANCE_CASE_RT) && caseRecord.CaseCategory__c != oldCase.CaseCategory__c){
                caseSubVerticalMap.put(caseRecord.Id, caseRecord.SubVertical__c);
                if((caseRecord.SubVertical__c != Constants.DLP_SUB_VERTICAL || caseRecord.SubVertical__c != Constants.DLP_CONTRACTOR_SUB_VERTICAL) && recordTypeName !=System.Label.AMCRecTypeLabel){
                    caseRecord.EntitlementId = entitlementId ;
                }else if(recordTypeName ==System.Label.AMCRecTypeLabel && (caseRecord.SubCategory__c == 'PPM Visit' || caseRecord.SubCategory__c == 'PMA Visit'))
                    caseRecord.EntitlementId = System.Label.AMCEntitlementId ;  
                else if(recordTypeName ==System.Label.AMCRecTypeLabel && caseRecord.CaseCategory__c  == System.Label.ODCaseCategoty){ caseRecord.EntitlementId = System.Label.AMC_OD_Entitlement_Id ; } //V2.2 
                else if(caseRecord.SubVertical__c == Constants.DLP_SUB_VERTICAL){ caseRecord.EntitlementId = dlpEntitlementId ;}
                //Smaartt added new condition && caseRecord.Status == Constants.DLP_NEW_CASE_STATUS at else part not execute owner change after new status
                //if(caseRecord.CaseCategory__c != null && (caseRecord.CaseCategory__c == Constants.QUALTRICS_SURVEY_CATEGORY || Constants.RELATED_TO_QUALTRICS_SURVEY.contains(caseRecord.CaseCategory__c)) && caseRecord.Origin == Constants.SURVEY_CASE_ORIGIN){
        if(caseRecord.CaseCategory__c == Constants.QUALTRICS_SURVEY_CATEGORY && caseRecord.Origin == Constants.SURVEY_CASE_ORIGIN){
                    caseRecord.OwnerId = surveyQueue.Id;
                } else if((caseRecord.SubVertical__c == Constants.DLP_SUB_VERTICAL || caseRecord.SubVertical__c == Constants.DLP_CONTRACTOR_SUB_VERTICAL ) && (recordTypeName == Constants.STANDARD_CASE_RT || (recordTypeName == Constants.DLP_CASE_RT && caseRecord.Status == Constants.CASE_NEW) ) && caseRecord.Origin != Constants.CASE_ORIGIN_CUSTOMER_PORTAL && caseRecord.Origin != Constants.CASE_ORIGIN_CUSTOMER_APP){
                    caseRecord.OwnerId = dlpQueue.Id;
                }
            }

            if((caseRecord.CaseCategory__c == Constants.CONTACT_DETAILS_UPDATE_CATEGORY || caseRecord.SubCategory__c == Constants.CONTACT_DETAILS_UPDATE_CATEGORY) && (caseRecord.CustomerInformationConfirmed__c == true || oldCase.CustomerInformationConfirmed__c == true)){
               contactUpdateCasesIds.add(caseRecord.Id);
            }
             //ASF-2864
             // To call populateSubVerticalDependentInfo only when subvertical or case category is changed
            if(caseRecord.SubVertical__c != oldCase.SubVertical__c || caseRecord.CaseCategory__c != oldCase.CaseCategory__c ){
                caseSubVerticalMap.put(caseRecord.Id, caseRecord.SubVertical__c);
            }
          }
        }
        if(!caseUnit.isEmpty()) {
            List<HexaBPM__Service_Request__c> servKar = [SELECT Id, Unit__c, HOKAR__c FROM HexaBPM__Service_Request__c 
                                            WHERE HexaBPM__Record_Type_Name__c = 'Handover' 
                                            AND Unit__c IN :caseUnit 
                                            AND HOKAR__c != null];           

            for(HexaBPM__Service_Request__c sr : servKar) {
                karMap.put(sr.Unit__c, sr.HOKAR__c);
            }
        }
        if(!lstOwnerChangeCases.isEmpty())
            validateDLPCases(lstOwnerChangeCases);
        
        if(tasksToInsert.size() > 0){
            CreateResolvertask(tasksToInsert);
        } 
        // Case revamp : Added by Faaiz for validating the Cases closing without completing tasks    
        if (!closedcasedIds.isEmpty()) {
            List<Task> openTasks = [SELECT Id, WhatId FROM Task WHERE WhatId IN :closedcasedIds AND Status != 'Completed'];
            
            for (Task t : openTasks) {
                casesWithOpenTasks.add(t.WhatId);
            }
        }
        System.debug('casesWithOpenTasks-->'+casesWithOpenTasks);
        //added by vijay for child cases must be closed before closing parent case        
        if(closedcaseids.size() > 0)
        {
            Map<Id, Case> casemap = new Map<Id, Case>([Select Id, CaseNumber, (Select Id, CaseNumber From Cases Where Status != 'Closed') From Case Where Id In :closedcaseids and RecordType.Name = :Constants.STANDARD_CASE_RT ]);
            
            for(Case cs : (List<Case>)newList)
            {
                Case parentcs = casemap.get(cs.Id);
                if(parentcs.Cases.size() > 0)
                {
                   
                    cs.Status.addError('Please close child cases before closing Parent Case');
                }
            }
        } 
            
         // Case revamp:Added by Faaiz for validating the Cases closing without closing SR 
        if (!srcaseIds.isEmpty()) {
            List<HexaBPM__Service_Request__c> openSRlist = [SELECT Id, Case__c FROM HexaBPM__Service_Request__c WHERE Case__c IN :srcaseIds AND HexaBPM__External_Status_Name__c != 'Closed'];
            
            for (HexaBPM__Service_Request__c h : openSRlist) {
                casesWithOpenSR.add(h.Case__c);
            }
        }

        if(UnitIdsList.size() > 0)
        {            
            List<Case> caselist = [Select Id, ParentId, CaseNumber, (select Id, SchedStartTime, SchedEndTime, RecordType.Name from Service_Appointments__r Where RecordType.Name = 'Assessment') 
                                   From Case Where Id Not In :caseIdlist and RecordTypeId = :dlpRecordTypeId and Unit__c In :UnitIdsList and ParentId = null 
                                   and Single_DLP_slot__c = true and CreatedDate < :csdatetime and Status In :casestatuses order by CreatedDate Desc]; 
            if(caselist.size() > 0)
            {                
                for(Case csrec : (List<Case>)newList) {   ServiceAppointment sa = New ServiceAppointment();                   
                    if(csrec.Service_Appointments__r.size() > 0)  sa = csrec.Service_Appointments__r[0];
                    if(sa.SchedEndTime == null || sa.SchedEndTime > DateTime.now()){    
                        String msg = 'Already Open Case is exist for this Unit. Please create this case as child case by populating Parent case with ' + caselist[0].CaseNumber;
                        csrec.ParentId.addError(msg);
                    }                    
                }
            }
        }
        // To check if CIS sheet is already sent to customer and prevent the user to edit this case.
        if(!contactUpdateCasesIds.isEmpty()){
            List<Document__c> documentList = [Select Id, DocuSignEnvelopeID__c, Case__c, Case__r.Status From Document__c Where Case__c IN: contactUpdateCasesIds AND DocuSignEnvelopeID__c != ''];

            for (Document__c docRec : documentList) {
                if(((Case)newMap.get(docRec.Case__c)).Status != 'Closed'){
                    Case caseRec = (Case)newMap.get(docRec.Case__c);
                    //caseRec.addError(Utilities.getSystemMessages(Constants.CASE_CIS_SHEET_SENT_VALIDATION).Message__c);
                }
            }
        }
        //System.debug('point: newestCaseNumber' + newestCaseNumber);
        //System.debug('point: queueId' + queueId);

        if(casesOwnerChangedFromQueueToUser.size() > 0 && loggedInUser.Profile.Name != Constants.INTEGRATION_PROFILE && loggedInUser.UserRole.Name != Constants.CONTACT_CENTER_MANAGER && 
           queueId != dlpQueue.Id &&  queueId != postSaleQueue.Id &&  queueId != cmFinanceQueue.Id && queueId != newSalesQueue.Id){
            List<Case> oldestCases = CaseService.getOldestCaseFromQueue(queueId, newestCaseNumberString);
            List<String> oldestCasesNumber = new List<String>();
            //System.debug('point: oldestCases' + oldestCases);
            for (Integer i = 0; i < oldestCases.size(); i++) {
                if(!casesOwnerChangedFromQueueToUser.containsKey(oldestCases[i].Id)){
                    oldestCasesNumber.add(oldestCases[i].CaseNumber);
                }
            }
               
               Id userId = UserInfo.getUserId();
               User userRoleName = [SELECT Id, UserRole.Name FROM User WHERE Id =:userId];
              
               String NonUser = system.label.CASE_FIRST_COME_FIRST_SERVE;
              
               List<String> exemptUserIds = NonUser.split(',');
              
               if(oldestCasesNumber.size() > 0 && userRoleName.UserRole != null && userRoleName.UserRole.Name ==system.label.Contact_Centre_Agent){
                  
                   if(!exemptUserIds.contains(userId)){
                       
                       ((List<Case>)newList)[0].addError(Utilities.getSystemMessages(Constants.CASE_FIRST_COME_FIRST_SERVE_ERROR).Message__c + oldestCasesNumber.toString());
                   }
               }
               
           }
        
        if(casesWithTask.size() > 0){
            taskCreationForCase(casesWithTask);
        }

        if(transferredCases.size() > 0){
            handleTransferredCases(transferredCases);
        }

        if(reopenCases.size() > 0){
            updateReopenCount(reopenCases);
        }
        if(!caseWithSalesOrderMap.isEmpty()){
            customerRelatedToUnitValidation(caseWithSalesOrderMap, newList);
        }

        accountIDToRecMap = new map<Id,account>([SELECT Id, Company__pc, Position__pc,Workplace_Street__pc, CompanyAddress__pc, NoofYearswithCompany__pc, Industry, AnnualIncome__pc, Name,RecordType.Name, PersonContactId, FirstName, MiddleName, LastName, PassportNumber__pc, ResidentStatus__pc, MaritalStatus__pc, EmploymentStatus__pc, PersonEmail, MobilePhone__pc, MobileCountryCode__pc from Account WHERE ID IN:accountIDToRecMap.keyset()]);

        for(Case caseRecord : (List<Case>)newList){
              //Case : KAR changes
            if(karMap.containsKey(caseRecord.Unit__c)) {
                caseRecord.KAR__c = karMap.get(caseRecord.Unit__c);
            }
            
            //!isPortalUser this is added by Daksh 
            Boolean isPortalUser = [SELECT UserType FROM User WHERE Id = :UserInfo.getUserId()].UserType == 'PowerPartner';
            // Case revamp:Added by Faaiz for validating the Cases closing without completing tasks
            if (casesWithOpenTasks.contains(caseRecord.Id) && (caseRecord.Status == 'Closed' ||caseRecord.Status == 'Resolved') && !isPortalUser) {
                caseRecord.addError(System.label.Cases_Closing_Task_Error);
            }
            
            // Case revamp:Added by Faaiz for validating the Cases closing without completing tasks
            /*if (casesWithOpenTasks.contains(caseRecord.Id) && (caseRecord.Status == 'Closed' ||caseRecord.Status == 'Resolved')) {
                caseRecord.addError(System.label.Cases_Closing_Task_Error);
            }*/
            // Case revamp:Added by Faaiz for validating the Cases closing without closing SR
            if (casesWithOpenSR.contains(caseRecord.Id) && caseRecord.Status == 'Closed') {
                caseRecord.addError(System.label.Case_Closing_SR_Error);
            }
            
            String recordTypeName = Utilities.getRecordTypeName('Case', caseRecord.recordTypeId);
            if(caseRecord.AccountId != null && accountIDToRecMap.containsKey(caseRecord.AccountId)){
                if(accountIDToRecMap.get(caseRecord.AccountId).RecordType.Name ==Constants.PERSON_ACCOUNT_RT && 
                  (recordTypeName != Constants.DLP_CASE_RT || (recordTypeName == Constants.DLP_CASE_RT && caseRecord.CustomerType__c == 'Owner'))
                  ){
                    caseRecord.ContactId = accountIDToRecMap.get(caseRecord.AccountId).PersonContactId;
                }
            }
        }

        if(accountIDToRecMap.size() > 0 ){
            populateCustomerDetailsFromAccount(newList, accountIDToRecMap);
        }

        if(caseWithSalesOrderMap.size() > 0){
            //populateLPCInformation(caseWithSalesOrderMap, newList);
        }

        if(caseSubVerticalMap.size() > 0){
            populateSubVerticalDependentInfo(caseSubVerticalMap, newList, oldMap);
        }
        if(caseSubVerticalMapNew.size() > 0){
            populateSubVerticalDependentInfoNew(caseSubVerticalMapNew, newList, oldMap);
        }         
        /*Added by Cloudzlab */
        if(assetIds.size()>0)
        {   //completeMilestones(caseIds);
            populateOwnerIdfromProjectMetadata(assetIds,newList);
        }
        if(caseCatSubCatMap.size()>0)
        {
            populateECSSData(caseCatSubCatMap,newList);
        }
        /*End*/
             
        if(ownershipchangeCases.size() > 0){ //Monika: Mass Ownership change restriction                
                MassOwnerShipChangeLogics.updateCaseOwner(OwnershipchangeCases, MapownerIds);
            } 
    }
   

    
    
    
    
    public static void customerRelatedToUnitValidation(map<Id,Id> caseWithSalesOrderMap, list<Case> caseRecords){

        Map<Id, List<Id>> soWithRelatedAccounts = new Map<Id, List<Id>>();
        List<SalesOrder__c> soRecords = SalesOrderService.queryAllFieldsWithExtraFields(caseWithSalesOrderMap.values());

        for(SalesOrder__c so : soRecords){
            soWithRelatedAccounts.put(so.Id, new List<Id>{so.Account__c});
            for(JointOwner__c joRec : so.Joint_OwnersSalesOrder__r){
                soWithRelatedAccounts.get(joRec.SalesOrder__c).add(joRec.Account__c);
            }
        }
        Id userId = UserInfo.getUserId();
        User userRoleName = [SELECT Id, UserRole.Name, UserType FROM User WHERE Id =:userId];
        Id amcRcTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('AMC').getRecordTypeId();
        for(Case caseRecord : caseRecords){
            if(caseRecord.SalesOrder__c != null && caseRecord.AccountId != null && userRoleName.UserType != 'PowerPartner' && caseRecord.RecordTypeId != amcRcTypeId ){
                List<Id> accountsList = soWithRelatedAccounts.get(caseRecord.SalesOrder__c);
                if(caseRecord.CaseCategory__c != Constants.QUALTRICS_SURVEY_CATEGORY && (accountsList == null || !accountsList.contains(caseRecord.AccountId))){
                    caseRecord.addError(Utilities.getSystemMessages(Constants.CASE_ACCOUNT_RELATED_TO_UNIT_VALIDATION).Message__c);
                }
            }
        }
    }

    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        Set<Id> dlpCasesIds = new Set<Id>();
        Set<Id> dlpStatusChangeIds = new Set<Id>();
        list<Case> caseToProcess = new list<Case>();        
        Map<Id,Set<Id>> mapSOProdId = new Map<Id,Set<Id>>();//2.2    
    List<Id> cafmCaseIdList = new List<Id>();//Added by Smaartt for CAFM Cases
        Id cafmRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.CAFMRecordType).getRecordTypeId();//Added by Smaartt for CAFM Cases
        Id amcRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('AMC').getRecordTypeId();//2.2
        ResaleService.ResaleCaseInfos resaleCaseInfos = new ResaleService.ResaleCaseInfos();
      
        /* Added by Cloudzlab to handle ECSS Record Types */
        Map<String, id> recordMap = recordInformation();
        Id ECSSQueriesRecordTypeId = recordMap.get(Constants.ECSSQueries);
        Id ECSSComplaintsRecordTypeId =  recordMap.get(Constants.ECSSComplaints);
        //Id ECSSRequestsRecordTypeId =  recordMap.get(Constants.ECSSRequests);
        Id ECSSMaintenanceRecordTypeId =  recordMap.get(Constants.ECSSMaintenance);
        List<Case> ecssCases = new List<Case>();
        /* End */
      
        // Added By Moh Sarfaraj for BPM-475
        Id homeFinanceRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Home_Finance').getRecordTypeId();
        List<Case> listCaseToCreateDocumentPlaceHolderForHFCases = new List<Case>();
        List<Case> casesToUpdate = new List<Case>();
        
        
        // TeamMemberHelper.SharingWrapper sharingWrapper = new TeamMemberHelper.SharingWrapper();

        for(Case caseRecord : (List<Case>)newList){  
            /* Added by cloudzlab to retrieve the values of ecss cases*/
            if(caseRecord.RecordTypeId == ECSSQueriesRecordTypeId || caseRecord.RecordTypeId == ECSSComplaintsRecordTypeId || caseRecord.RecordTypeId == ECSSMaintenanceRecordTypeId){
                ecssCases.add(caseRecord);
            }
            /* End */   
            
        String recordTypeName = caseRecord.recordTypeId != null ? Utilities.getRecordTypeName('Case', caseRecord.recordTypeId) : '';
            if(caseRecord.RecordtypeId == ResaleConstants.Resale_Case_RecordTypeId){
                ResaleService.getInfoFromResaleCases_Insert(caseRecord, caseToProcess, resaleCaseInfos); // , sharingWrapper);
            }
    //Added by Smaartt for CAFM Cases
            if (caseRecord.RecordtypeId == cafmRecordTypeId) {
                cafmCaseIdList.add(caseRecord.Id);
            }       
             //v2.2 START
            if(caseRecord.RecordtypeId == amcRecordTypeId && caseRecord.CaseCategory__c == System.Label.ODCaseCategoty){
                if(!mapSOProdId.containsKey(caseRecord.SalesOrder__c))
                    mapSOProdId.put(caseRecord.SalesOrder__c,new Set<Id>());
                mapSOProdId.get(caseRecord.SalesOrder__c).add(caseRecord.ProductId);
            }//v2.2 END
            //Added by Smaartt for CAFM Cases
            if(!cafmCaseIdList.isEmpty()) {
                CAFMCalloutToMuleSoft.callCAFMCaseCreationQueue(cafmCaseIdList); 
            } 
            // Added By Moh Sarfaraj for BPM-475

            if(!isByPassCaseTrigger && caseRecord.RecordTypeId == homeFinanceRTId && String.isBlank(caseRecord.ParentId)){

                listCaseToCreateDocumentPlaceHolderForHFCases.add(caseRecord);
            }
        }     
        UpdateOffLineQtyInprogress(mapSOProdId,'create');//V2.2
        if(!caseToProcess.isEmpty()){
            createCaseDocuments(caseToProcess);
        }

        if(!resaleCaseInfos.caseIdsToCreateTask.isEmpty() ){ // || !sharingWrapper.userIdToGiveAccessWrapperMap.isEmpty()){
            ResaleService.operateOnResaleCases_Insert(resaleCaseInfos); // , sharingWrapper);
        }
        // Adarsh for Work log 
        // Commenting for prod deployment
      //  ALD_WorkLogHelper.receiveCallFromPrimObjTriggers(newList, null, true);
      
        // Added By Moh Sarfaraj for BPM-475
        if(!listCaseToCreateDocumentPlaceHolderForHFCases.isEmpty()){
            createHomeFinanceDocuments(listCaseToCreateDocumentPlaceHolderForHFCases);
        }
        /* Added by cloudzlab to call the helper method */
        ECSS_CaseTriggerHelper.UpdateSAPValues(ecssCases);
        /* End */
    }

    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        list<Case> caseToProcess = new list<Case>();
        list<Case> closedCase = new list<Case>();
        Map<Id, Case> closedCasesMap = new Map<Id, Case>();     
        Set<Id> dlpCasesIds = new Set<Id>();
        //2.2 START
        Map<Id,Set<Id>> mapSOProdId = new Map<Id,Set<Id>>();//v2.2
        Map<Id,Set<Id>> mapSOProdIdCncl= new Map<Id,Set<Id>>();//v2.2
        Id amcRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('AMC').getRecordTypeId();
        //2.2 END
        ResaleService.ResaleCaseInfos resaleCaseInfos = new ResaleService.ResaleCaseInfos();
        // TeamMemberHelper.SharingWrapper sharingWrapper = new TeamMemberHelper.SharingWrapper();
        
        List<Account> updateAccountList = new List<Account>();
        Set<Id> dlpClosedCasesIds = new Set<Id>(); 
        Set<Id> accIds=new Set<Id>();
        for(Case caseRec:(List<Case>)newList){
            if(caseRec.RecordTypeId != ResaleConstants.Resale_Case_RecordTypeId)
           accIds.add(caseRec.AccountId); 
        }
        Map<Id, Account> accountMap=new Map<Id, Account>([select Id, isValidationBypass__c from Account where Id IN:accIds]);
       List<Task> tasksToInsert = new List<Task>();
       
        // Added By Moh Sarfaraj for BPM-431
        Id homeFinanceRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Home_Finance').getRecordTypeId();
        Set<Id> setHomeFinnaceCaseIds = new Set<Id>();
        Set<Id> setParentCaseIdToCreateCommission = new Set<Id>();
        Set<Id> caseIdToCreateContract = new Set<Id>();
        
        for(Case newCase : (List<Case>)newList){
            Case oldCase = (Case)oldMap.get(newCase.Id);
            
            String recordTypeName = Utilities.getRecordTypeName('Case', newCase.recordTypeId);
           // asf 2842             
             if( newCase.SubVertical__c == system.label.Case_Subvertical_Onboarding && ((String.valueOf(oldCase.OwnerId).startsWith('00G') && String.valueOf(newCase.OwnerId).startsWith('005')) || (String.valueOf(newCase.OwnerId).startsWith('005') && newCase.Status == Constants.CASE_WORK_IN_PROGRESS )) ){
               Task newTask = new Task(); newTask.Subject = 'Call'; newTask.OwnerId = newCase.OwnerId; newTask.WhatId = newCase.Id;newTask.Task_Name__c = 'Call Attempt 1';
               tasksToInsert.add(newTask);
            }

            //Tenant Onboarding
                if(recordTypeName == 'ECSS Query' && newCase.CaseCategory__c =='Tenant Onboarding' && (newCase.Status == Constants.CLOSED_CASE || newCase.Status == 'Completed') && newCase.Status != oldCase.Status){
                   caseIdToCreateContract.add(newCase.Id);
                }

            if((recordTypeName == Constants.DLP_CASE_RT  || recordTypeName == Constants.STANDARD_CASE_RT || newCase.Recordtype_Name__c == constants.Requests || newCase.Recordtype_Name__c == constants.Complaints ) && newCase.CustomerInformationConfirmed__c != oldCase.CustomerInformationConfirmed__c && newCase.CustomerInformationConfirmed__c == true){
                caseToProcess.add(newCase);
            }//v2.1 change here
            if(((recordTypeName == Constants.DLP_CASE_RT || recordTypeName == System.Label.AMCRecTypeLabel) && newCase.status == Constants.CLOSED_CASE ) || ( recordTypeName == System.Label.AMCRecTypeLabel && newCase.Customer_Response__c != null && newCase.Customer_Response__c != oldCase.Customer_Response__c)) {
              dlpClosedCasesIds.add(newCase.Id);               
            }            
            if(newCase.isClosed != oldCase.isClosed && newCase.isClosed && recordTypeName != ResaleConstants.Resale_Case_RecordTypeName){ // avoid resale support process
                closedCase.add(newCase);
                closedCasesMap.put(newCase.Id, newCase);
            }
           /* if(newCase.AsiteSyncStatus__c == Constants.STATUS_IN_PROGRESS && recordTypeName != ResaleConstants.Resale_Case_RecordTypeName){ // avoid resale support process
                dlpCasesIds.add(newCase.Id);
            }*/
            
           /* if (newCase.Status == Constants.CLOSED_CASE && newCase.StatusReason__c == Constants.WITH_RESOLUTION_CASE && newCase.CaseCategory__c == Constants.CONTACT_DETAILS_UPDATE_CATEGORY && (newCase.Origin == Constants.CASE_ORIGIN_CUSTOMER_PORTAL || newCase.Origin == Constants.CASE_ORIGIN_CUSTOMER_APP))*/
            //modified by Dharnesh for live aldar issue
            if (newCase.Status == Constants.CLOSED_CASE && oldCase.Status != Constants.CLOSED_CASE &&
                (newCase.StatusReason__c == Constants.WITH_RESOLUTION_CASE ||String.isBlank(newCase.StatusReason__c)) && 
                (newCase.CaseCategory__c == Constants.CONTACT_DETAILS_UPDATE_CATEGORY) &&
                (newCase.Origin == Constants.CASE_ORIGIN_CUSTOMER_PORTAL || newCase.Origin == Constants.CASE_ORIGIN_CUSTOMER_APP || newCase.Origin == Constants.PHONE || newCase.Origin == Constants.EMAIL)&& newCase.AccountId != null && newCase.RecordTypeId != ResaleConstants.Resale_Case_RecordTypeId)
            {
                Account accRecord = new Account();
                accRecord.Id = newCase.AccountId;
                if (newCase.Email__c != null) accRecord.PersonEmail = newCase.Email__c;
                if (newCase.Email__c != null) accRecord.EmailAddress__pc = newCase.Email__c;
                if (newCase.MobileCountryCode__c != null) accRecord.MobileCountryCode__pc = newCase.MobileCountryCode__c;
                if (newCase.MobileNumber__c != null) accRecord.MobilePhone__pc = newCase.MobileNumber__c;
                if (newCase.MobileCountryCode__c != null && newCase.MobileNumber__c != null) accRecord.PersonMobilePhone = newCase.MobileCountryCode__c + newCase.MobileNumber__c;
                if (newCase.MobileCountryCode__c != null && newCase.MobileNumber__c != null) accRecord.MobileNumberEnc__pc = newCase.MobileCountryCode__c + newCase.MobileNumber__c;
                if (newCase.MaritalStatus__c != null) accRecord.MaritalStatus__pc = newCase.MaritalStatus__c;
                /*accRecord.BillingStreet = newCase.PermanentStreet__c;
                accRecord.BillingCity = newCase.PermanentCity__c;
                accRecord.BillingState = newCase.PermanentState__c;
                accRecord.BillingPostalCode = newCase.PermanentPostalCode__c;
                accRecord.BillingCountry = newCase.PermanentCountry__c;

                accRecord.PassportNumber__pc = newCase.PassportNumber__c;
                accRecord.PassportType__pc = newCase.PassportType__c;
                accRecord.PlaceofIssue__pc = newCase.PlaceofIssue__c;
                accRecord.PassportIssueDate__pc = newCase.PassportIssueDate__c;
                accRecord.PassportExpiryDate__pc = newCase.PassportExpiryDate__c;

                accRecord.ResidentStatus__pc = newCase.ResidentStatus__c;
                accRecord.CountryOfResidence__pc = newCase.Current_Residential_Country__c;
                accRecord.Nationality__pc = newCase.Nationality__c;
                accRecord.NationalIdNumber__pc = newCase.NationalIdNumber__c;
                accRecord.NationalIdExpiryDate__pc = newCase.NationalIdExpiryDate__c;
                
                accRecord.EmploymentStatus__pc = newCase.EmploymentStatus__c;
                accRecord.SourceofFunds__pc = newCase.SourceofFunds__c;
                accRecord.Company__pc = newCase.Company__c;
                accRecord.Position__pc = newCase.Position__c;
                accRecord.CompanyAddress__pc = newCase.CompanyAddress__c;
                accRecord.AnnualIncome__pc = newCase.AnnualIncome__c;
                accRecord.NoofYearswithCompany__pc = newCase.NumberOfYearsWithCompany__c;
                accRecord.Industry = newCase.Industry__c;*/
                
                 if (newCase.PermanentStreet__c != null) accRecord.BillingStreet = newCase.PermanentStreet__c;
                if (newCase.PermanentCity__c != null) accRecord.BillingCity = newCase.PermanentCity__c;
                if (newCase.PermanentState__c != null) accRecord.BillingState = newCase.PermanentState__c;
                if (newCase.PermanentPostalCode__c != null) accRecord.BillingPostalCode = newCase.PermanentPostalCode__c;
                if (newCase.PermanentCountry__c != null) accRecord.BillingCountry = newCase.PermanentCountry__c;
                if (newCase.PassportNumber__c != null) accRecord.PassportNumber__pc = newCase.PassportNumber__c;
                if (newCase.PassportType__c != null) accRecord.PassportType__pc = newCase.PassportType__c;
                if (newCase.PlaceofIssue__c != null) accRecord.PlaceofIssue__pc = newCase.PlaceofIssue__c;
                if (newCase.PassportIssueDate__c != null) accRecord.PassportIssueDate__pc = newCase.PassportIssueDate__c;
                if (newCase.PassportExpiryDate__c != null) accRecord.PassportExpiryDate__pc = newCase.PassportExpiryDate__c;
                if (newCase.ResidentStatus__c != null) accRecord.ResidentStatus__pc = newCase.ResidentStatus__c;
                if (newCase.Current_Residential_Country__c != null) accRecord.CountryOfResidence__pc = newCase.Current_Residential_Country__c;
                if (newCase.Nationality__c != null) accRecord.Nationality__pc = newCase.Nationality__c;
                if (newCase.NationalIdNumber__c != null) accRecord.NationalIdNumber__pc = newCase.NationalIdNumber__c;
                if (newCase.NationalIdExpiryDate__c != null) accRecord.NationalIdExpiryDate__pc = newCase.NationalIdExpiryDate__c;
                if (newCase.EmploymentStatus__c != null) accRecord.EmploymentStatus__pc = newCase.EmploymentStatus__c;
                if (newCase.SourceofFunds__c != null) accRecord.SourceofFunds__pc = newCase.SourceofFunds__c;
                if (newCase.Company__c != null) accRecord.Company__pc = newCase.Company__c;
                if (newCase.Position__c != null) accRecord.Position__pc = newCase.Position__c;
                if (newCase.CompanyAddress__c != null) accRecord.CompanyAddress__pc = newCase.CompanyAddress__c;
                if (newCase.AnnualIncome__c != null) accRecord.AnnualIncome__pc = newCase.AnnualIncome__c;
                if (newCase.NumberOfYearsWithCompany__c != null) accRecord.NoofYearswithCompany__pc = newCase.NumberOfYearsWithCompany__c;
                if (newCase.Industry__c != null) accRecord.Industry = newCase.Industry__c;
                
                Account accRecordMatched = accountMap.get(newCase.AccountId);
                if(accRecordMatched!=null){
                    accRecord.isValidationBypass__c=!accRecordMatched.isValidationBypass__c;
                }

                updateAccountList.add(accRecord);
            }
            // actions only for Resale Case Record Type
            if(recordTypeName == ResaleConstants.Resale_Case_RecordTypeName){
                ResaleService.getInfoFromResaleCases_Update(newCase, oldCase, caseToProcess, resaleCaseInfos); // , sharingWrapper);
            }
            //2.2 START
             if (newCase.Status == Constants.CLOSED_CASE && newCase.Status != oldCase.Status  &&  newCase.RecordtypeId == amcRecordTypeId && newCase.CaseCategory__c == 'On Demand'){
                if(newCase.AMC_Closure_Reason__c == System.Label.AMCClosureForComleted){
                    if(!mapSOProdId.containsKey(newCase.SalesOrder__c)) mapSOProdId.put(newCase.SalesOrder__c,new Set<Id>());
                    mapSOProdId.get(newCase.SalesOrder__c).add(newCase.ProductId); 
                }else{  
                    if(!mapSOProdIdCncl.containsKey(newCase.SalesOrder__c))  mapSOProdIdCncl.put(newCase.SalesOrder__c,new Set<Id>()); 
                    mapSOProdIdCncl.get(newCase.SalesOrder__c).add(newCase.ProductId);  
                }
            }//V2.2 END
            
            // Added By Moh Sarfaraj for BPM-431
            if(newCase.RecordTypeId == homeFinanceRTId && newCase.Verified_by_Finance__c && newCase.Verified_by_Finance__c != oldCase.Verified_by_Finance__c){
                setHomeFinnaceCaseIds.add(newCase.Id);
            }
            
            // Added By Moh Sarfaraj for BPM-460
            if(newCase.RecordTypeId == homeFinanceRTId &&  
               newCase.Sum_of_Total_Commission_for_Aldar__c != null && 
               newCase.PaymentReceived__c &&
               newCase.PaymentReceived__c != oldCase.PaymentReceived__c){
                   
                setParentCaseIdToCreateCommission.add(newCase.Id);
            }
        }
        //2.2 START
        if(!mapSOProdId.isEmpty())
             UpdateOffLineQtyInprogress(mapSOProdId,'closed');

        if(!mapSOProdIdCncl.isEmpty())
            UpdateOffLineQtyInprogress(mapSOProdIdCncl,'cancelled');
        //2.2 END
        if (!tasksToInsert.isEmpty()) {
        insert tasksToInsert; 
        }        
        if(dlpClosedCasesIds.size() > 0){
            sendServiceReport(dlpClosedCasesIds);
        }
        if (!updateAccountList.isEmpty()) {
            update updateAccountList;
        }
        if(!caseToProcess.isEmpty()){
            createCaseDocuments(caseToProcess);
        }
        if(!closedCasesMap.isEmpty()){
            tasksValidation(closedCasesMap);
        }
        if(!closedCase.isEmpty()){
          //  validateQualtricsCase(closedCase);
        }
        /*if(!dlpCasesIds.isEmpty()){
            System.enqueueJob(new DLPCalloutUtilities.AsiteIntegration(dlpCasesIds));
        }*/
        if(!resaleCaseInfos.caseIdsToCreateTask.isEmpty() 
                || !resaleCaseInfos.listedUnitIdToCaseIdMap.isEmpty() 
                // || !resaleCaseInfos.cancellationInProgressCases.isEmpty() 
                || !resaleCaseInfos.cancelledCaseIds.isEmpty() ){ 
                // || !sharingWrapper.userIdToGiveAccessWrapperMap.isEmpty() 
                // || !sharingWrapper.userIdToRemoveAccessWrapperMap.isEmpty()){
            ResaleService.operateOnResaleCases_Update(resaleCaseInfos); // , sharingWrapper);
        }
        // Adarsh for Work log
        // Commenting for prod deployment
       // ALD_WorkLogHelper.receiveCallFromPrimObjTriggers(newList, oldMap, false);
       
        // Added By Moh Sarfaraj for BPM-431
        if(!setHomeFinnaceCaseIds.isEmpty()){
            sentEmailToHuspyAfterVerified(setHomeFinnaceCaseIds);
        }
        
        // Added By Moh Sarfaraj for BPM-460
        if(!setParentCaseIdToCreateCommission.isEmpty()){
            createCommissionRecord (setParentCaseIdToCreateCommission, (List<Case>)newList);  
        }
        
        // Tenant onboarding
        if(!caseIdToCreateContract.isEmpty()){
            TenantCreateAccountWebService.createTenantContract(caseIdToCreateContract);  
        }
    }
    
    public static void tasksValidation(Map<Id, Case> closedCasesMap) {
        List<Task> tasksList = [Select Id, WhatId, TaskNumber__c, CustomerResponse__c From Task Where WhatId in : closedCasesMap.keySet() AND TaskNumber__c != null];

        Map<Id, Integer> caseWithNumberOfTasks = new Map<Id, Integer>();
        Integer cutomerNotReachableTasksCount = 0;
        Boolean customerReached = false;
        for (Task taskRec : tasksList) {
            Integer tasksCount = 1;
            if(caseWithNumberOfTasks.containsKey(taskRec.WhatId)){
                tasksCount = caseWithNumberOfTasks.get(taskRec.WhatId);

                if(taskRec.CustomerResponse__c == Constants.CUSTOMER_REACHED){
                    tasksCount = tasksCount + 4;
                }
                caseWithNumberOfTasks.put(taskRec.WhatId, tasksCount + 1);
            } else {

                if(taskRec.CustomerResponse__c == Constants.CUSTOMER_REACHED){
                    tasksCount = tasksCount + 4;
                }
                caseWithNumberOfTasks.put(taskRec.WhatId, tasksCount);
            }
        }

        if(!caseWithNumberOfTasks.isEmpty()){
            for(Id caseId : caseWithNumberOfTasks.keySet()) {
                if(caseWithNumberOfTasks.get(caseId) < 4){
                    closedCasesMap.get(caseId).addError(Utilities.getSystemMessages(Constants.CASE_TASKS_VALIDATION).Message__c);
                }
            }
        }
        
    }
    
    
    public static set<ID> validateQualtricsCaseEligibility(List<SObject> newCaseList, Map<Id,SObject> oldMap) {
        set<ID> qualtircsIDsToProcess = new Set<ID>();
        //Skip Invalid Record Types
        //Skip Legal Case
        //Skip Survey Case
        set<ID> recordTypeToPorcess = new set<ID>{Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.FEEDBACK_CASE_RT).getRecordTypeId(),Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.STANDARD_CASE_RT).getRecordTypeId(),Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.DLP_CASE_RT).getRecordTypeId(),Schema.SObjectType.Case.getRecordTypeInfosByName().get(System.label.Case_Home_finance).getRecordTypeId(),Utilities.getRecordTypeId('Case', System.Label.AMCRecTypeLabel),Utilities.getRecordTypeId('Case', 'Queries'),Utilities.getRecordTypeId('Case', 'Complaints'), Utilities.getRecordTypeId('Case', 'Requests')};
        map<id,id> caseToAccountId = new map<id,id>();
        for(Case tempCaseRecord : (List<Case>)newCaseList){
            //Ticket ASF-516
            Case oldCase=(Case)oldMap.get(tempCaseRecord.Id);
            if(tempCaseRecord.status=='Closed' 
                && !tempCaseRecord.Survey_Required__c  
                && tempCaseRecord.status != oldCase.status
                &&tempCaseRecord.Qualtrics_Survey_Required__c
                && tempCaseRecord.Origin != Constants.ORIGIN_SURVEY
                && tempCaseRecord.Vertical__c != Constants.LEGAL_VERTICAL
                && recordTypeToPorcess.Contains(tempCaseRecord.RecordTypeID)
                && tempCaseRecord.DLP_Closure_Reason__c !=Constants.DLP_CLOSURE_REASON_NOT_UNDER_DLP
                && tempCaseRecord.DLP_Closure_Reason__c !=Constants.DLP_CLOSURE_REASON_COMMON_AREA_DLP
                && tempCaseRecord.DLP_Closure_Reason__c !=Constants.DLP_CLOSURE_REASON_CUSTOMER_NOT_AVAILABLE
                && tempCaseRecord.AMC_Closure_Reason__c !=Constants.DLP_CLOSURE_REASON_CUSTOMER_NOT_AVAILABLE
                && tempCaseRecord.AMC_Closure_Reason__c != 'Customer Cancellation Request'

              ){              
                    caseToAccountId.put(tempCaseRecord.Id,tempCaseRecord.AccountId);
               
            }
        }
        //Exclude the property tansfer SR Case
        //Try to get Property Transfer SR
        set<ID> caseIdsPropTrans = new set<ID>();
        for(HexaBPM__Service_Request__c tempS : [select id,Case__c from HexaBPM__Service_Request__c where Case__c in :caseToAccountId.keySet() and HexaBPM__Record_Type_Name__c in (:Constants.PROPERTY_TRANSFER_DEV_RT, :Constants.PLOT_PROPERTY_TRANSFER_DEV_RT ,  :Constants.PROPERTY_TRANSFER_NOC_DEV_RT) ]){
            caseToAccountId.remove(tempS.Case__c);
        }
        
        //Validate the DLP Case close Date
        set<Id> accountIdsToSkip = new set<Id>();
        for(Case tempClosedDLP : [select id,AccountID from Case where AccountID in :caseToAccountId.values() and isCLosed=true and ClosedDate = LAST_N_DAYS:5 and (Vertical__c = :Constants.DLP_SUB_VERTICAL OR  Vertical__c = :Constants.DLP_VERTICAL)  and  id not in :caseToAccountId.keySet() and Survey_Point__c = 'DLP Closed'])
        {
            accountIdsToSkip.add(tempClosedDLP.AccountID);
        }

        for(ID tempRecID : caseToAccountId.keySet() ){
            if( !accountIdsToSkip.contains(caseToAccountId.get(tempRecID))){
                qualtircsIDsToProcess.add(tempRecID);
            }
        }
        return qualtircsIDsToProcess;
    }

   
    public static void updateSalesOrderAndCustomer(List<SObject> newCaseList, Map<Id, SObject> oldCaseMap, Boolean isUpdate) {
        List<Id> unitIds = new List<Id>();
        for (Case caseRecord: (List<Case>)newCaseList) {
            Case oldCase = (Case)oldCaseMap.get(caseRecord.Id);
            if ( ( caseRecord.Unit__c != null || (isUpdate && oldCase.Unit__c == null) ) && caserecord.RecordTypeId != ResaleConstants.Resale_Case_RecordTypeId && caseRecord.recordTypeId != ResaleService.getRecordTypeId('Case', 'Corporate_Legal')) {
                unitIds.add(caseRecord.Unit__c);
            }
        }
        
        if (!unitIds.isEmpty()) {
            Map<String, SalesOrder__c> unitSalesOrderMap = new Map<String, SalesOrder__c>();
            List<SalesOrder__c> SalesOrderlist = [SELECT Id, Unit__c, Account__c, Account__r.PersonContactId, Status__c, Contact__c, TotalInstallmentReceived__c, TotalOutstanding__c, NetAmount__c, TotalBilled__c, NumberOfDefaults__c, HoldFlag__c, Unit__r.Project__r.AsiteProjectName__c  FROM SalesOrder__c WHERE Unit__c IN: unitIds and Status__c != :Cancelled];
            for (SalesOrder__c salesOrder: SalesOrderlist) {
                unitSalesOrderMap.put(salesOrder.Unit__c, salesOrder);
            }
            
            for (Case caseRecord: (List<Case>)newCaseList) {
                if (caseRecord.Unit__c != null && unitSalesOrderMap.containsKey(caseRecord.Unit__c)) {
                    SalesOrder__c salesOrder = unitSalesOrderMap.get(caseRecord.Unit__c);
                    if(caseRecord.CaseCategory__c != Constants.CONTACT_DETAILS_UPDATE_CATEGORY){
                        caseRecord.AccountId = caseRecord.AccountId != null && (caseRecord.Origin == Constants.CASE_ORIGIN_CUSTOMER_PORTAL || caseRecord.Origin == Constants.CASE_ORIGIN_CUSTOMER_APP) ? caseRecord.AccountId : salesOrder.Account__c;
                        caseRecord.AccountId = salesOrder.Account__c;
                    }
                    caseRecord.SalesOrder__c = salesOrder.Id;
                }
            }
        }
    }

    public static void populateLPCInformation(map<Id,Id> caseWithSalesOrderMap, List<SObject> newList){

        List<SalesOrder__c> salesOrdersListDetail = StatementOfAccountController.getListSalesOrderDetail(caseWithSalesOrderMap.values());

        Map<Id,List<ReceiptAllocation__c>> installmentAllocationMap = new Map<Id,List<ReceiptAllocation__c>>();
        Map<Id,List<InstallmentLines__c>> salesordersInstallmentMap = new Map<Id,List<InstallmentLines__c>>();
        Map<Id,SalesOrder__c> salesOrdersMap = new Map<Id,SalesOrder__c>();

        List<InstallmentLines__c> installmentLinesList = new List<InstallmentLines__c>();

        for(SalesOrder__c salesOrderRecord : salesOrdersListDetail){

            salesOrdersMap.put(salesOrderRecord.Id, salesOrderRecord);

            for(ReceiptAllocation__c receiptAllocationRec : salesOrderRecord.ReceiptAllocations__r){

                List<ReceiptAllocation__c> allocationList = new List<ReceiptAllocation__c>();
                allocationList.add(receiptAllocationRec);

                if(receiptAllocationRec.InstallmentLine__r.Id !=null && receiptAllocationRec.ReceiptAcknowledgement__r.Status__c==Constants.RECEIPT_STATUS_CLEARED){
                    System.debug(receiptAllocationRec.InstallmentLine__c+'**installmentAllocationMap**'+installmentAllocationMap);

                    if(installmentAllocationMap.containsKey(receiptAllocationRec.InstallmentLine__r.Id)){
                        allocationList.addAll(installmentAllocationMap.get(receiptAllocationRec.InstallmentLine__r.Id));
                    }
                    installmentAllocationMap.put(receiptAllocationRec.InstallmentLine__r.Id,allocationList);
                }
            }

            System.debug(installmentAllocationMap+'**Installment Receipt Map**');
            salesordersInstallmentMap.put(salesOrderRecord.Id, salesOrderRecord.InstallmentLines__r);
        }

        for(Case caseRecord : (List<Case>)newList){

            SalesOrder__c salesOrderRec = salesOrdersMap.get(caseWithSalesOrderMap.get(caseRecord.Id));
            List<InstallmentLines__c> InstallmentsList = salesordersInstallmentMap.get(salesOrderRec.Id);

            caseRecord.TotalLPCAmount__c = LPCService.getLPCForSalesOrder(salesOrderRec, InstallmentsList, installmentAllocationMap);
            System.debug('*Point: *' + LPCService.getLPCForSalesOrder(salesOrderRec, InstallmentsList, installmentAllocationMap));
        }

    }
    
     // Case Revamp : To populate fields from new revised metadata  
    public static List<Case_Field_Dependency_Revised__mdt> getCaseFieldDependencyNew()
    {
        List<Case_Field_Dependency_Revised__mdt> caseDependencyList = Case_Field_Dependency_Revised__mdt.getall().values();
        return caseDependencyList;
    }
    
     //Case revamp: : New method to populate fields from the metadata
    public static void populateSubVerticalDependentInfoNew(Map<Id, String> caseSubVerticalMap, List<SObject> newList, Map<Id, SObject> oldMap){
        
        try {
            List<Case_Field_Dependency_Revised__mdt> caseFieldDependencyList = getCaseFieldDependencyNew() != null ? getCaseFieldDependencyNew() : new List<Case_Field_Dependency_Revised__mdt>();
            Map<String, List<Case_Field_Dependency_Revised__mdt>> caseFieldDependencyMap = new Map<String, List<Case_Field_Dependency_Revised__mdt>>();
            Map<String, String> locationLabelMap = new Map<String, String>{'Yas Island' => System.Label.YasIsland_Queue_Label,'Saraya & Shams'  => System.Label.SarayaShams_Queue_Label,'North Baniyas'   => System.Label.NorthBaniyas_Queue_Label,'Merief' => System.Label.Merief_Queue_Label,'Al Wathba' => System.Label.AlWathba_Queue_Label, 'AL Raha' => System.Label.AlRaha_Queue_Label,'Al Falah' => System.Label.AlFalah_Queue_Label};
      Id ComplaintsRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.Complaints).getRecordTypeId();
            Id RequestsRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.Requests).getRecordTypeId();
            //For case autoassingment
            Map<Id, Case> caseMapForAutoAssign = new Map<Id, Case>();
            Map<Id, Case_Field_Dependency_Revised__mdt> dependencyMapForAutoAssign = new Map<Id, Case_Field_Dependency_Revised__mdt>();
           
                for(Case_Field_Dependency_Revised__mdt caseDependency : caseFieldDependencyList) {
                String key = caseDependency.Category__c + '-' + caseDependency.Sub_Category__c;
                System.debug('$$key$$'+key);
                if(!caseFieldDependencyMap.containsKey(key))
                    caseFieldDependencyMap.put(key, new List<Case_Field_Dependency_Revised__mdt> {caseDependency});
                else {
                    List<Case_Field_Dependency_Revised__mdt> fieldMapList = caseFieldDependencyMap.get(key);
                    fieldMapList.add(caseDependency);
                    caseFieldDependencyMap.put(key, fieldMapList);
                }           
            }
            System.debug('$$caseFieldDependencyMap$$'+caseFieldDependencyMap);
            
            for(Case caseRecord : (List<Case>)newList) {
                
                if(caseSubVerticalMap.containsKey(caseRecord.Id)) {
                    String Casekey = caseRecord.CaseCategory__c + '-' + caseRecord.SubCategory__c;
                    System.debug('$$Casekey$$'+Casekey);
                    List<Case_Field_Dependency_Revised__mdt> fieldList = caseFieldDependencyMap.get(Casekey) != null ? caseFieldDependencyMap.get(Casekey) : new List<Case_Field_Dependency_Revised__mdt>();
                    
                    for(Case_Field_Dependency_Revised__mdt caseFieldDependency : fieldList) {                        
                          if (oldMap != null) {
                          Case oldCase = (Case)oldMap.get(caseRecord.Id);
                          if(caseRecord.CaseCategory__c != null && caseRecord.CaseCategory__c=='Aldar Select'){
                                caseRecord.OwnerId = System.label.Aldar_Select_Queue;
                            }
                            else if(caseRecord.Origin == 'Walk-In' || oldcase.OwnerId == System.label.Walk_in_team_queue){
                            caseRecord.OwnerId = System.label.Walk_in_team_queue;                                
                        }
                        else {
                            caseRecord.OwnerId = System.label.Contact_center_team_queue;
                        }      
                         }
                        else{
                       if(caseRecord.CaseCategory__c != null && caseRecord.CaseCategory__c=='Aldar Select'){
                                caseRecord.OwnerId = System.label.Aldar_Select_Queue;
                            }
                            else if(caseRecord.Origin == 'Walk-In'){
                            caseRecord.OwnerId = System.label.Walk_in_team_queue;                                
                        }
                        else {
                            caseRecord.OwnerId = System.label.Contact_center_team_queue;
                        } 
                        }
                       if(caseRecord.CaseCategory__c !='Aldar Select' && ((caseRecord.Recordtype_Name__c == constants.Requests && caseRecord.FCR__c == false) || caseRecord.Recordtype_Name__c == constants.Complaints )){
                            caseRecord.OwnerId = caseFieldDependency.Case_Owner_Queue__c; 
                        }
                        if(caseFieldDependency.Location_Required__c && caseRecord.Location__c != null && locationLabelMap.containsKey(caseRecord.Location__c)){                            
                            caseRecord.OwnerId = locationLabelMap.get(caseRecord.Location__c);
                        }
                        if(caseRecord.Recordtype_Name__c == constants.Requests && caseRecord.FCR__c == true){
                            caseRecord.Assigned_To__c = UserInfo.getUserId();
                        }  
                        caseRecord.Organization__c = caseFieldDependency.Organization__c;
                        caseRecord.Department__c = caseFieldDependency.Department__c;
                        caseRecord.Vertical__c = caseFieldDependency.Vertical__c; 
                        caseRecord.SubVertical__c = caseFieldDependency.Sub_Vertical__c;
                        //System.debug('Priority' + caseRecord.Customer_Type__c);
                        if (caseRecord.Customer_Type__c == System.label.Select_Customer && (caseRecord.RecordTypeId == RequestsRecordTypeId || caseRecord.RecordTypeId == ComplaintsRecordTypeId)) {
                            caseRecord.Priority = 'P1';
                        }else {
                            caseRecord.Priority = caseFieldDependency.Priority__c;
                        }                        
                        //caseRecord.Case_Field_Dependency_Id__c = caseFieldDependency.Id;
                        caseRecord.Escalation_level_1_Email__c = caseFieldDependency.Senior_Agent_Escalation__c;
                        caseRecord.Escalation_level_2_Email__c = caseFieldDependency.senior_associate_escalation__c;
                        caseRecord.Escalation_level_3_Email__c = caseFieldDependency.AVP_Escalation__c;
                        caseRecord.Escalation_level_4_Email__c = caseFieldDependency.Department_Head_Level_4__c;
                        caseRecord.Qualtrics_Survey_Required__c= caseFieldDependency.Customer_Survey__c; 
                        caseRecord.Email_Not_Triggered__c = caseFieldDependency.Email_Not_Triggered__c;
                        caseRecord.Service_request_Creation__c = caseFieldDependency.Is_Service_Created__c;                      
                       if((caseRecord.origin != 'Customer Portal' && caseRecord.origin != 'Customer App' && caseRecord.origin !='Email'))
                        {
                             caseRecord.Subject = caseRecord.CaseCategory__c +'-'+ caseRecord.SubCategory__c;
                        }
                        //For populating ADM email for riyadh city
                        if (caseRecord.CaseCategory__c == System.Label.Case_Subvertical_Riyadh_city){
                            caseRecord.ADM_Email__c = System.Label.Riyadh_city_Email;
            }
                        if (oldMap != null) {
                            Case oldCase = (Case)oldmap.get(caseRecord.Id);               
                            
                            if(oldCase.OwnerId != caseRecord.OwnerId && caseRecord.FCR__c == false){
                                caseRecord.Assigned_To__c = null;
                            }
                        }
                        //By Adarsh for case auto assingment
                        if(caseFieldDependency.Auto_Assingment__c != null){
                            caseMapForAutoAssign.put(caseRecord.Id, caseRecord);
                            dependencyMapForAutoAssign.put(caseRecord.Id, caseFieldDependency);
                        }
                    }                
                    if((caseRecord.Recordtype_Name__c == constants.Requests) || caseRecord.Recordtype_Name__c == constants.Complaints){
                        If(caseRecord.Priority == 'P1'){
                            caseRecord.EntitlementId =System.label.Case_Normal_Entitlement_ID;
                        }Else If(caseRecord.Priority == 'P2'){
                            caseRecord.EntitlementId =System.label.Case_Complaint_Request_P2;
                        }Else If(caseRecord.Priority == 'P3'){
                           caseRecord.EntitlementId =System.label.Case_Complaint_Request_P3;
                        }                    
                    }         
                }
            }
            // For case auto assingment
            if(!caseMapForAutoAssign.isEmpty()) {
                autoassigmentBulk(caseMapForAutoAssign, dependencyMapForAutoAssign);
            }
        } catch (Exception e) {            
            System.debug('Error in populateSubVerticalDependentInfo: ' + e.getMessage());
        }
    }


    public static void populateSubVerticalDependentInfo(map<Id,String> caseSubVerticalMap, List<SObject> newList, Map<Id, SObject> oldMap){

        List<CaseFieldDependency__mdt> caseFieldDependencyList = Utilities.getCaseFieldDependency() != null ? Utilities.getCaseFieldDependency() : new List<CaseFieldDependency__mdt>();

        Map<String,List<CaseFieldDependency__mdt>> caseFieldDependencyMap = new Map<String,List<CaseFieldDependency__mdt>>();
        
        for(CaseFieldDependency__mdt caseDependency : caseFieldDependencyList)
        {
            if(!caseFieldDependencyMap.containsKey(caseDependency.SubVertical__c))
                caseFieldDependencyMap.put(caseDependency.SubVertical__c, new List<CaseFieldDependency__mdt> {caseDependency});
            else{
                List<CaseFieldDependency__mdt> fieldMapList = caseFieldDependencyMap.get(caseDependency.SubVertical__c);
                fieldMapList.add(caseDependency);
                caseFieldDependencyMap.put(caseDependency.SubVertical__c, fieldMapList);
            } 
        }
        //ASF-892
        String loggedInUserEmail=UserInfo.getUserEmail();
        //ASF-1351
        Group handoverCaseQueue = Utilities.getQueueInformation('Handover');
        List<String> codeRedUsersEmailList=new  List<String>();
        for(Case_Code_Red_Allow_Users__mdt codeRedConfig : Case_Code_Red_Allow_Users__mdt.getall().values()) {
            codeRedUsersEmailList.add(codeRedConfig.User_Email__c);
        }
        //ASF-892
        for(Case caseRecord : (List<Case>)newList){
           //ASF-1351   
          if(caseRecord.Id!=null){
            Case oldCaseRecord = (Case)oldMap.get(caseRecord.Id);
            if((oldCaseRecord==null && caseRecord.SubVertical__c != null && caseRecord.SubVertical__c=='Property Handover') ||
                  oldCaseRecord!=null && caseRecord.SubVertical__c!=oldCaseRecord.SubVertical__c && 
                   caseRecord.SubVertical__c != null && caseRecord.SubVertical__c=='Property Handover' ) {
                    caseRecord.OwnerId = handoverCaseQueue.Id;
                }
              }else if (caseRecord.Id==null && caseRecord.SubVertical__c=='Property Handover'){
                   caseRecord.OwnerId = handoverCaseQueue.Id;
              }         
           
            if(caseSubVerticalMap.containsKey(caseRecord.Id))
            {
                List<CaseFieldDependency__mdt> fieldList = caseFieldDependencyMap.get(caseRecord.SubVertical__c) != null ? caseFieldDependencyMap.get(caseRecord.SubVertical__c) : new List<CaseFieldDependency__mdt>();
                System.debug('fieldList '+fieldList);
                
               
                
                for(CaseFieldDependency__mdt caseFieldDependency : fieldList){
                    //System.debug('caseFieldDependency '+caseFieldDependency);
                    caseRecord.Organization__c = caseFieldDependency.Organization__c;
                    caseRecord.Department__c = caseFieldDependency.Department__c;
                    caseRecord.Vertical__c = caseFieldDependency.Vertical__c;   
                    //2.2 START
                    if(caseRecord.SubCategory__c ==   caseFieldDependency.SubCategory__c && caseFieldDependency.Skills_Required__c != null)
                        caseRecord.Skills_Required__c = caseFieldDependency.Skills_Required__c; 
                    //2.2 END
                    if(caseRecord.SubVertical__c =='Comms'){
                        caseRecord.Vertical__c = caseRecord.CaseCategory__c;
                    }  
                    //For Emergency cases
                   /* if(caseRecord.SubCategory__c == 'Emergency' && caseFieldDependency.SubCategory__c == caseRecord.SubCategory__c){
                        caseRecord.Priority = caseFieldDependency.Priority__c;  caseRecord.EscalationPriority__c = caseFieldDependency.EscalationPriority__c;
                        caseRecord.Qualtrics_Survey_Required__c=caseFieldDependency.Survey_Required__c; caseRecord.Email_Not_Triggered__c=caseFieldDependency.Email_Not_Triggered__c;
                        caseRecord.MilestoneStatus__c = 'Within SLA';
                    }  */                  
                    //Added by Adarsh       
                    if((caseRecord.CaseCategory__c == label.DM_CAFM || caseRecord.CaseCategory__c ==system.label.Case_Etihad_mile || caseRecord.CaseCategory__c == system.label.Case_CEO_Comms) && caseFieldDependency.Case_Owner_Queue__c != null ){
                        caseRecord.OwnerId = caseFieldDependency.Case_Owner_Queue__c;
                    }                                  
                    
                    if (caseFieldDependency.Case_Owner_Queue__c != null && caseRecord.SubVertical__c == system.label.Case_Subvertical_Riyadh_city) {
                        caseRecord.OwnerId = caseFieldDependency.Case_Owner_Queue__c;
                    }  
                    

                    // to populate DLP priority fields depends on 
                    if( (caseRecord.SubVertical__c == Constants.DLP_SUB_VERTICAL || caseRecord.SubVertical__c == Constants.DLP_CONTRACTOR_SUB_VERTICAL  ||caseRecord.SubVertical__c == 'New Sale') && (caseRecord.CaseCategory__c == 'Civil' || caseRecord.CaseCategory__c == 'MEP')){
                        if(caseFieldDependency.SubVertical__c == caseRecord.SubVertical__c && caseFieldDependency.CaseCategory__c == caseRecord.CaseCategory__c && caseFieldDependency.SubCategory__c == caseRecord.SubCategory__c && caseFieldDependency.ProblemCode__c == caseRecord.ProblemCode__c && caseFieldDependency.IncidentDescription__c == caseRecord.IncidentDescription__c && caseFieldDependency.ResolutionType__c == caseRecord.ResolutionType__c){

                            caseRecord.Priority = caseFieldDependency.Priority__c; 
                            caseRecord.EscalationPriority__c = caseFieldDependency.EscalationPriority__c;
                            //Ticket ASF-516
                            //Added below condition for ASF-1598 do not send survey & Email for child cases
                            if(caseRecord.ParentId == null)
                            {
                                caseRecord.Qualtrics_Survey_Required__c=caseFieldDependency.Survey_Required__c;
                                caseRecord.Email_Not_Triggered__c=caseFieldDependency.Email_Not_Triggered__c;
                            } 
                            else
                            {
                                caseRecord.Qualtrics_Survey_Required__c = false;
                            caseRecord.Email_Not_Triggered__c=true;
                            }
                           
                            //ASF-892
                            if(caseRecord.Priority==Constants.CODE_RED_PRIORITY){
                                if(!codeRedUsersEmailList.contains(loggedInUserEmail)){
                                    caseRecord.addError('Your are not allowed to create code Red cases');
                                }
                            }
                        }
                    } else{

                         if(caseFieldDependency.SubVertical__c == caseRecord.SubVertical__c && caseFieldDependency.CaseCategory__c == caseRecord.CaseCategory__c 
                            && ( String.isNotBlank( caseRecord.SubCategory__c) && caseFieldDependency.SubCategory__c == caseRecord.SubCategory__c)
                            && ( String.isNotBlank(caseRecord.IncidentDescription__c) && caseFieldDependency.IncidentDescription__c.equalsIgnoreCase( caseRecord.IncidentDescription__c )) ){
                            caseRecord.Priority = caseFieldDependency.Priority__c; 
                            //ASF-892
                             if(caseRecord.Priority==Constants.CODE_RED_PRIORITY){
                                if(!codeRedUsersEmailList.contains(loggedInUserEmail)){
                                    caseRecord.addError('Your are not allowed to create code Red cases');
                                }
                            }
                            //Ticket ASF-516
                            //Added below condition for ASF-1598 do not send survey for child cases
                            if(caseRecord.ParentId == null){
                              caseRecord.Qualtrics_Survey_Required__c=caseFieldDependency.Survey_Required__c;
                                caseRecord.Email_Not_Triggered__c=caseFieldDependency.Email_Not_Triggered__c;
                            }
                            else
                            {
                                caseRecord.Qualtrics_Survey_Required__c = false;
                            caseRecord.Email_Not_Triggered__c=true;
                            }
                            if(oldMap == null){
                                caseRecord.ResolutionType__c = caseFieldDependency.ResolutionType__c; 
                            }
                        }

                    }
                }                  
            }

            Constant__mdt constantMdt = new Constant__mdt();
            String caseVerticale;
            caseVerticale = caseRecord.Vertical__c;
            if(caseVerticale != Null || String.isNotBlank(caseVerticale)){
                caseVerticale = caseVerticale.replaceAll( '&', '');
                constantMdt = Constant__mdt.getInstance(caseVerticale.replaceAll( '\\s+', ''));
                if(constantMdt != NULL)
                    caseRecord.VerticalHeadEmail__c = constantMdt.ConstantValue__c;
            }
            
            //Ticket ASF-516
            String caseSubCategory = caseRecord.SubCategory__c;
            if(caseRecord.SubVertical__c =='CMO' &&  caseSubCategory != Null && String.isNotBlank(caseSubCategory)){
                caseSubCategory = caseSubCategory.replaceAll( ' ', '_').removeEnd('_');
                 System.debug('*** caseSubCategory ****'+caseSubCategory);
                Constant__mdt constantMdtALD = Constant__mdt.getInstance(caseSubCategory);
                System.debug('*** constantMdtALD ****'+constantMdtALD);
                if(constantMdtALD != NULL)
                    caseRecord.ADM_Email__c = constantMdtALD.ConstantValue__c;
            }
            
            
            
            
        }
    }

    public static void taskCreationForCase(List<Case> newList){

        list<Task> taskToInsert = new list<Task>();

        for(Case caseRecord : newList){
            Task newTask = new Task(Subject=Constants.CASE_CALL_ATTEMPT_1, WhoId=caseRecord.ContactId, WhatId=caseRecord.Id, ActivityDate=Date.today(), OwnerId=caseRecord.OwnerId, TaskNumber__c=10);
            taskToInsert.add(newTask);
        }
        insert taskToInsert;
    }


    public static void handleTransferredCases(Map<Id,Case> transferredCases){

        Set<Id> casesWithCustomerReached = new Set<Id>();
        Set<Id> ownersIds = new Set<Id>();
        for(Case caseRec : transferredCases.values()){
            ownersIds.add(caseRec.OwnerId);
        }
        //----- Get all tasks Have Customer Response equal 'Customer Reached'.
        for(Task taskRec : TaskService.getCustomerReachedTasks(transferredCases.keySet())){
            casesWithCustomerReached.add(taskRec.WhoId);
        }

        Map<Id, User> usersDetails = new Map<Id, User>(UserService.getUsersById(ownersIds));

        for(Case caseRec : transferredCases.values()){

            User userRec = usersDetails.get(caseRec.OwnerId);

            //---- Error message to the user if there is no task with customer response equal 'Customer Reached'.
            if(!casesWithCustomerReached.contains(caseRec.Id) && userRec != null && userRec.ProfileName__c != Constants.CONTACT_CENTER_AGENT){
                SystemMessages__mdt messageDetails = Utilities.getSystemMessages(Constants.TRANSFER_CASES_ERROR);
                caseRec.addError(messageDetails.Message__c);
            }
        }
        
    }

    
    /* Added by Cloudzlab to assign ECSS case based on project metadata*/
    public static void populateOwnerIdfromProjectMetadata(Set<Id> assetIds,List<sObject> newList)
    {
        ECSS_CaseAssiggnmentSLAFromMtd.getProjectMetadata('Owner',assetIds,newList); 
    }
    
    /* Added by Cloudzlab New method to get populate from Case Field Dependency Revised Metadata for ECSS Case records*/
    public static void populateECSSData(Map<Id, String> caseCatSubCatMap, List<SObject> newList){
        
        List<Case_Field_Dependency_Revised__mdt> caseFieldDependencyList = new List<Case_Field_Dependency_Revised__mdt>([SELECT ECSS_Is_ECSS__c,
                                                                                                                         Category__c, 
                                                                                                                         Sub_Vertical__c,
                                                                                                                         Damage_Code__c,
                                                                                                                         ECSS_ObjectCategory__c,
                                                                                                                         Category_Code__c,
                                                                                                                         Case_Owner_Queue__c,Case_Owner_User__c,
                                                                                                                         Organization__c, Department__c,
                                                                                                                         Vertical__c, Priority__c,
                                                                                                                         ECSS_Sub_Category__r.MasterLabel,Survey_Type__c 
                                                                                                                         FROM Case_Field_Dependency_Revised__mdt
                                                                                                                         WHERE ECSS_Is_ECSS__c = true]);
        Map<String,Case_Field_Dependency_Revised__mdt> caseFieldDependencyMap = new Map<String, Case_Field_Dependency_Revised__mdt>();
        String mapKey ='';
        for(Case_Field_Dependency_Revised__mdt caseDependency : caseFieldDependencyList) 
        {   
            if(caseDependency.ECSS_ObjectCategory__c!='' && caseDependency.ECSS_ObjectCategory__c!=null)
                mapKey = caseDependency.Sub_Vertical__c+'|'+caseDependency.Category__c+'|'+caseDependency.ECSS_ObjectCategory__c+'|'+caseDependency.ECSS_Sub_Category__r.MasterLabel;
            else
                mapKey = caseDependency.Sub_Vertical__c+'|'+caseDependency.Category__c+'|'+caseDependency.ECSS_Sub_Category__r.MasterLabel;
            
            
            caseFieldDependencyMap.put(mapKey,caseDependency);
            
        }
        for(Case caseRecord : (List<Case>)newList) {
            
            if(caseCatSubCatMap.containsKey(caseRecord.Id)) {
                
                if(caseFieldDependencyMap.containsKey(caseCatSubCatMap.get(caseRecord.Id)))
                {   
                    Case_Field_Dependency_Revised__mdt caseFieldDependency = caseFieldDependencyMap.get(caseCatSubCatMap.get(caseRecord.Id));
                    caseRecord.ECSS_DamageCode__c = caseFieldDependency.Damage_Code__c;
                    caseRecord.ECSS_CaseCategoryCode__c = caseFieldDependency.Category_Code__c;
                    //caseRecord.ECSS_Survey_Type__c = caseFieldDependency.Survey_Type__c;
                    /*if(caseRecord.ECSS_Created_From_Component__c)
{
if( caseFieldDependency.Case_Owner_Queue__c!=null)
{
caseRecord.OwnerId = caseFieldDependency.Case_Owner_Queue__c; 
}
if( caseFieldDependency.Case_Owner_User__c!=null)
{
caseRecord.OwnerId = caseFieldDependency.Case_Owner_User__c; 
}
}*/
                    caseRecord.Organization__c = caseFieldDependency.Organization__c;
                    caseRecord.Department__c = caseFieldDependency.Department__c;
                    caseRecord.Vertical__c = caseFieldDependency.Vertical__c;
                    
                    caseRecord.Priority = caseFieldDependency.Priority__c;
                    if(caseRecord.Priority != null && caseRecord.Priority != label.ECSS_EmergencyPriority && caseRecord.ECSS_Account_Contract_Request__c ){
                        caseRecord.ECSS_isCaseApproved__c = false;
                    }
                    
                }
                else
                    if(caseRecord.ECSS_Account_Contract_Request__c ){
                        caseRecord.ECSS_isCaseApproved__c = false;
                    }
                
            }
            else
                if(caseRecord.ECSS_Account_Contract_Request__c ){
                    caseRecord.ECSS_isCaseApproved__c = false;
                }
        }
        
    }
    
    /*End */
    public static void updateReopenCount(List<Case> reopenCases){

        for(Case caseRecord : reopenCases){
            caseRecord.CaseReopenCount__c = caseRecord.CaseReopenCount__c + 1;
        }
    }

    public static void populateFieldsFromRecordIdField(List<Case> newList, Map<String,List<Id>> objectNameWithListOfIds){

        Map<Id, SObject> objectIdWithRecord = new Map<Id, SObject>();

        for(String objectName : objectNameWithListOfIds.keySet()){
            List<Id> objectIds = objectNameWithListOfIds.get(objectName);

            if(objectName == 'HexaBPM__Service_Request__c'){
                objectIdWithRecord.putAll(new map<Id, SObject>(ServiceRequestService.queryAllFieldsWithExtraFields(objectIds)));

            } else if(objectName == 'Lead'){
                objectIdWithRecord.putAll(new map<Id, SObject>(LeadService.getAllLeadByIds(new Set<Id>(objectIds))));

            } else if(objectName == 'Opportunity'){
                String oppQuery = 'Select Id, Contact__c, AccountId From Opportunity Where Id in (\''+ String.join(objectIds, '\',\'')+ '\')';
                objectIdWithRecord.putAll(new map<Id, SObject>(OpportunityService.getOpportunityQuery(oppQuery)));

            } else if(objectName == 'SalesOrder__c'){
                objectIdWithRecord.putAll(new map<Id, SObject>(SalesOrderService.queryAllFieldsWithExtraFields(objectIds)));
            }
        }

        for(Case caseRecord : newList){
            if(caseRecord.RecordId__c != null && objectIdWithRecord.containsKey(caseRecord.RecordId__c.split('#')[0])){
                SObject relatedRecord = objectIdWithRecord.get(caseRecord.RecordId__c.split('#')[0]);

                if(relatedRecord.getSObjectType().getDescribe().getName() == 'HexaBPM__Service_Request__c'){

                    HexaBPM__Service_Request__c srRecord = (HexaBPM__Service_Request__c)relatedRecord;

                    caseRecord.AccountId = srRecord.HexaBPM__Customer__c == null ? null : srRecord.HexaBPM__Customer__c;

                    if(srRecord.SalesOrder__c != null && srRecord.SalesOrder__r.Opportunity__c != null){
                        caseRecord.Opportunity__c = srRecord.SalesOrder__r.Opportunity__c;
                    }
                    caseRecord.ContactId = srRecord.HexaBPM__Contact__c == null ? null : srRecord.HexaBPM__Contact__c;
                    caseRecord.SalesOrder__c = srRecord.SalesOrder__c == null || srRecord.Unit__c == null ? null : srRecord.SalesOrder__c;
                    caseRecord.ServiceRequest__c = srRecord.Id;
                    caseRecord.Unit__c = srRecord.Unit__c == null ? null : srRecord.Unit__c;
                    
                } else if(relatedRecord.getSObjectType().getDescribe().getName() == 'Lead'){
                    
                    Lead leadRecord = (Lead)relatedRecord;
                    caseRecord.Lead__c = leadRecord.Id;
    
                } else if(relatedRecord.getSObjectType().getDescribe().getName() == 'Opportunity'){
                    Opportunity oppRecord = (Opportunity)relatedRecord;caseRecord.Opportunity__c = oppRecord.Id;caseRecord.AccountId = oppRecord.AccountId == null ? null : oppRecord.AccountId;
                    caseRecord.ContactId = oppRecord.Contact__c == null ? null : oppRecord.Contact__c;

                } else if(relatedRecord.getSObjectType().getDescribe().getName() == 'SalesOrder__c'){
                    String recordTypeName = Utilities.getRecordTypeName('Case', caseRecord.recordTypeId);
                    SalesOrder__c soRecord = (SalesOrder__c)relatedRecord;
                    caseRecord.AccountId = soRecord.Account__c == null ? null : soRecord.Account__c;
                    caseRecord.Opportunity__c = soRecord.Opportunity__c == null ? null : soRecord.Opportunity__c;
                    if((recordTypeName != Constants.DLP_CASE_RT || (recordTypeName == Constants.DLP_CASE_RT && caseRecord.CustomerType__c == 'Owner')))
                        caseRecord.ContactId = soRecord.Contact__c == null ? null : soRecord.Contact__c;
                    caseRecord.SalesOrder__c = soRecord.Unit__c == null ? null : soRecord.Id;
                    caseRecord.Unit__c = soRecord.Unit__c == null ? null : soRecord.Unit__c;

                }
            }
        }
    }
    // Case Revamp : For getting queue ID
    // 23-09-2024:Updated by Harsh - changed for loop query to single query
    public static Map<String, Group> caseQueryInformation (){
        Map<String, Group> queueMap = new Map<String, Group>();
        Set<String> queuenames = new Set <String> {Constants.SURVEY_QUEUE, Constants.DLP_QUEUE,Constants.POST_SALE_QUEUE,Constants.ADM_Community,Constants.ADM_Registration,Constants.Comms_Queue,Constants.Home_Finance_Queue,Constants.CM_FINANCE_QUEUE,Constants.Customer_Onboarding_Queue, Constants.CM_NEW_SALE_QUEUE};
            
            try{  
                for(Group gr :[select Id,Name from Group WHERE name=:queuenames]){
                    queueMap.put(gr.Name,gr);
                }                
                
            }catch(exception e){
                System.debug('Case query error'+e.getMessage());
            }
        return queueMap;  
    }
    // Case Revamp : For getting record ID
    public static Map<String, id> recordInformation (){
        Map<String, id> recordMap = new Map<String, id>();
        /* Cloudzlab added ECSS record types to the list */
        List<String> recordnames = new list <String> {Constants.FEEDBACK_CASE_RT,Constants.STANDARD_CASE_RT,Constants.LEGAL_CASE_RT,Constants.DLP_CASE_RT,Constants.Development_Control,'Queries','Complaints', 'Requests',System.Label.AMCRecTypeLabel,Constants.ECSSQueries,Constants.ECSSMaintenance,Constants.ECSSComplaints}; // ,'Third Party Payment NOC'
            for(String recordname:recordnames){
                Id RecordTypeId =  Utilities.getRecordTypeId('Case',recordname);
                if(RecordTypeId!=null){
                    recordMap.put(recordname,RecordTypeId);
                }else {
                    System.debug('No queueInfo for '+recordname);
                }
            }
        return recordMap;
    }
    
    public static void createCaseDocuments(list<Case> caseRecords){
        List<Document__c> documentListToInsert = new List<Document__c>();
        map<String,ID> documentRecordTypeMap = new map<String,ID>();
        map<String,list<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{Constants.DOCUMENT_PLACEHOLDER_CATEGORY_CASE, ResaleConstants.DOCUMENT_PLACEHOLDER_CATEGORY_RESALE_CASE});
        map<Id,Case> caseIDToRecMap = new map<Id,Case>(caseRecords);

        if(!documentMap.isEmpty() && !caseIDToRecMap.isEmpty()){
            //get Existing Documents
            map<String,Document__c> existingDocMap = new map<String,Document__c>();
            for(Document__c tempDoc : [select id,DocumentType__c,Case__c from Document__c where Case__c in :caseIDToRecMap.keySet()]){
                    existingDocMap.put(tempDoc.Case__c+tempDoc.DocumentType__c,tempDoc);
            }

            for(Case caseRecord : caseRecords){
                String recordTypeName = Utilities.getRecordTypeName('Case', caseRecord.recordTypeId);
                String documentTypeToProcess; 
                if( recordTypeName == Constants.STANDARD_CASE_RT || recordTypeName == Constants.DLP_CASE_RT || caseRecord.Recordtype_Name__c == constants.Requests || caseRecord.Recordtype_Name__c == constants.Complaints ){
                    documentTypeToProcess = Constants.DOCUMENT_PLACEHOLDER_CATEGORY_CASE;
                }else if(recordTypeName == ResaleConstants.Resale_Case_RecordTypeName){
                    documentTypeToProcess = ResaleConstants.DOCUMENT_PLACEHOLDER_CATEGORY_RESALE_CASE;
                }
                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(documentTypeToProcess)){
                    String recordTypeID=null;
                    
                    if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                        
                    if(!existingDocMap.containsKey(caseRecord.Id + tempMetaRec.DocumentType__c)){
                        Document__c documentRecord = DocumentService.createDocumentRecord('','','',tempMetaRec.DocumentType__c,'','',recordTypeID);
                        documentRecord.SendForESign__c= tempMetaRec.eSignRequired__c;
                        documentRecord.DocumentPlaceHolderId__c=tempMetaRec.DeveloperName;
                        documentRecord.EligibleForeSign__c=tempMetaRec.EligibleForeSign__c;
                        documentRecord.Case__c = caseRecord.Id;
                        if(recordTypeName != ResaleConstants.Resale_Case_RecordTypeName){
                            documentRecord.Account__c = caseRecord.AccountId;
                        }else{
                            if(ResaleService.ResaleRRQueue != null && caseRecord.OwnerId != ResaleService.ResaleRRQueue.Id){
                                documentRecord.OwnerId = caseRecord.OwnerId;
                            }
                        }

                        documentListToInsert.add(documentRecord); 
                        existingDocMap.put(caseRecord.Id + tempMetaRec.DocumentType__c,documentRecord);       
                    }
                }    
            }
        }
        
        if(!documentListToInsert.isEmpty()){
            insert documentListToInsert;  
        } 
    }
 //R3 changes by Smaartt
    // Final Email to customer with SERVICE report    
    public static void sendServiceReport(Set<Id> caseIds) {
        
        try{   
            //v2.1 START  here
                Map<String, String> amcTemplates = new Map<String, String>{
                    System.Label.AMCClosureForComleted => 'PPM_Service_Complete_Confirmation',
                    System.Label.AMCClosureCustNA => 'PPM_schedule_with_no_access',
                    System.Label.First_Call =>'No_response_to_the_call',
                    System.Label.Last_Call =>'No_response_to_the_call_Last_Trial'
                };//v2.1 END  here 
            //Start V2.2       
            Map<String, String> amcODTemplates = new Map<String, String>{
                System.Label.AMCClosureForComleted => 'AMC_OD_Service_Complete_Confirmation',
                System.Label.AMCClosureCustNA => 'AMC_OD_schedule_with_no_access'
            };
            //V2.2 End        
            List<Case> caseRecords = [select id,ContactId,CaseCategory__c,CustomerType__c,DLP_Closure_Reason__c,Status,Customer_Response__c,Contact.Email ,ContactEmail,AccountId,SuppliedEmail,contact.EmailAddress__c,AMC_Closure_Reason__c,Recordtype_Name__c from case where id in: caseIds ];//2.1 change here in SOQL            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();             
            Map<id,ServiceAppointment> mapSAandCase = new Map<id,ServiceAppointment>();
            for(ServiceAppointment saRecord : [select Id,Case__c, (Select Id, ContentVersionDocumentId From ServiceReports ORDER BY LastModifiedDate desc Limit 1 ) from ServiceAppointment where Case__c in:caseIds  and Status ='Closed' and (Record_Type_Name__c='Assessment' OR Record_Type_Name__c='AMC')  ORDER BY LastModifiedDate desc] ){ //2.1 change here
                if(!mapSAandCase.containskey(saRecord.Case__c)){ mapSAandCase.put(saRecord.Case__c,saRecord); }
            }            
            //EmailTemplate em = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Email_Template_on_notification_to_user_on_task_completing'];  
            for(case caseId :caseRecords){
                ServiceAppointment saRec = mapSAandCase.get(caseId.Id);
                if(saRec != null && saRec.ServiceReports.size() > 0 ){list<ID> docid=new list<ID>(); docid.add(saRec.ServiceReports[0].ContentVersionDocumentId);mail.setEntityAttachments(docid);}
                if(caseId.ContactId != null){ mail.setTargetObjectId(caseId.ContactId);
                }else{ mail.setTargetObjectId(caseId.AccountId);   }                      
                //string emailtemplateId = caseId.DLP_Closure_Reason__c == System.Label.DLPFinalReportStatus ? System.Label.DLPCompletedEmailtemplate: System.Label.DLPOutofscopeEmailtemplate ; 
                string emailtemplateId;
                if(caseId.Recordtype_Name__c==Constants.DLP_CASE_RT){  //v2.1
                if(caseId.DLP_Closure_Reason__c == System.Label.DLPFinalReportStatus)
                    emailtemplateId = System.Label.DLPCompletedEmailtemplate;
                else if(caseId.DLP_Closure_Reason__c == System.Label.DLP_customernotavailable)
                    emailtemplateId = System.Label.DLP_CustNotAvailEmailTemplate;
                else
                    emailtemplateId = System.Label.DLPOutofscopeEmailtemplate;
                }
                //v2.1 change start here
                 if(caseId.Recordtype_Name__c==System.Label.AMCRecTypeLabel || test.isRunningTest()){//v2.1 START
                    List<String> lstDLPMembers =  new  List<String>();  
                    String templateDevName ='';
                    if(caseId.Status == 'Closed'  || test.isRunningTest()){  templateDevName = (caseId.CaseCategory__c == System.Label.ODCaseCategoty ? amcODTemplates.get(caseId.AMC_Closure_Reason__c) : amcTemplates.get(caseId.AMC_Closure_Reason__c)); lstDLPMembers = getEmailsFromPublicGroup(System.Label.DLPManagerGroupName);
                        if(lstDLPMembers.size() > 0)    mail.setCCAddresses(lstDLPMembers );
                    }else if(caseId.Customer_Response__c != null){ templateDevName = amcTemplates.get(caseId.Customer_Response__c);  }
                    if (templateDevName != null) {  emailtemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateDevName LIMIT 1]?.Id; }
                 }//v2.1 END
                mail.setTemplateId(emailtemplateId); string toEmail = '';            
                if(caseId.CustomerType__c == 'Owner'){ toEmail = caseId.ContactEmail ; 
                }else {  toEmail = caseId.Contact.Email  ;   }                
                if(toEmail != '' && toEmail != null){
                    string[] toaddresses = new String[] {toEmail};  
                    mail.setToAddresses(toAddresses);                   
                    mail.setWhatId(saRec.Id); mail.setOrgWideEmailAddressId(System.Label.DLPOrgWideCustomerCareId);
                    mail.setBccSender(false); mail.setUseSignature(false); mail.setSaveAsActivity(true); 
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });                    
                }
            }
        }catch(exception e){ LoggerService.save(LoggerService.addApexLog(e,'BookingSystemIntegration','BookingSystemIntegration',''));}
    }

    //v2.1 START  here
    public static List<String> getEmailsFromPublicGroup(String groupName) {
        // Step 1: Get the Id of the public group
        Id grId = [SELECT Id FROM Group WHERE Name = :groupName LIMIT 1]?.Id;
        Set<Id> setUserId = new  Set<Id> ();
        // Step 2: Get the User Ids of members in the group
        for(GroupMember  gm: [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :grId]){   setUserId.add(gm.UserOrGroupId );}

        // Step 3: Get the email addresses of the users
        List<User> users = [SELECT Email FROM User WHERE Id IN :setUserId];

        // Extract emails from the users list
        List<String> emails = new List<String>();
        for (User user : users) {  emails.add(user.Email); }
        if(test.isRunningTest())
            emails.add('test@gmail.com');
        return emails;
    }
 //v2.1 END  here
 
    //v2.2 Start
 public static void checkAndupdateProductForOnDeamnd(List<Case> caseRecords, Map<Id, SObject> caseMap, Boolean isUpdate) {
        Map<String, String> mpCaseSubCat = new Map<String, String>();
        Map<String, String> mpCaseSO = new Map<String, String>();
        Set<String> caseSubCatSet = new Set<String>();
        Set<String> caseSOSet = new Set<String>();
        
        // Populate maps and sets for efficient querying
        for (Case c : caseRecords) {
            if(c.CaseCategory__c == System.Label.ODCaseCategoty){
                mpCaseSubCat.put(c.Id, c.SubCategory__c);
                mpCaseSO.put(c.Id, c.SalesOrder__c);
                caseSubCatSet.add(c.SubCategory__c);
                caseSOSet.add(c.SalesOrder__c);
            }
        }
        if(!mpCaseSubCat.isEmpty()){
            // Query OpportunityOfferLine__c based on case SubCategory and SalesOrder
            Map<String, Set<String>> mpSOOffLines = new Map<String, Set<String>>();
            Map<String, Set<String>> mpSOOffLinesId = new Map<String, Set<String>>();
            
            for (OpportunityOfferLine__c offLi : [ SELECT Id,Product_Item__r.Product2Id,Product_Item__r.Product2.Name, SalesOrder__c  FROM OpportunityOfferLine__c WHERE Product_Item__r.Product2.Name IN :caseSubCatSet AND SalesOrder__c IN :caseSOSet AND BalanceQuantity__c > 0]) {
                if (!mpSOOffLines.containsKey(offLi.SalesOrder__c)) {
                    mpSOOffLines.put(offLi.SalesOrder__c, new Set<String>());
                }
                mpSOOffLines.get(offLi.SalesOrder__c).add(offLi.Product_Item__r.Product2.Name);
                
                if (!mpSOOffLinesId.containsKey(offLi.SalesOrder__c)) {
                    mpSOOffLinesId.put(offLi.SalesOrder__c, new Set<String>());
                }
                mpSOOffLinesId.get(offLi.SalesOrder__c).add(offLi.Product_Item__r.Product2.Name + '--' + offLi.Product_Item__r.Product2Id);
            }
            
            // Update cases based on the queried OpportunityOfferLine__c records
            for (Case c : caseRecords) {
                
                if (c.CaseCategory__c== System.Label.ODCaseCategoty && mpSOOffLines.containsKey(c.SalesOrder__c)) {
                    System.debug('****'+mpSOOffLines);
                    Set<String> setProd = mpSOOffLines.get(c.SalesOrder__c);
                    if (!setProd.contains(c.SubCategory__c)) {
                        c.addError('Case cannot be created, all the quantities are consumed for on-demand.');
                    } else {
                        for (String prod : mpSOOffLinesId.get(c.SalesOrder__c)) {
                            if (prod.startsWith(c.SubCategory__c + '--')) {
                                c.ProductId = prod.split('--')[1];
                                break; // Exit loop early once product is found
                            }
                        }
                    }
                }else if(c.CaseCategory__c=='On Demand'){
                    c.addError('No On Demand Service found.');
                }
            }
        }    
    }//V2.2 END
    
    //V2.2 START
    Public static void UpdateOffLineQtyInprogress(Map<Id,Set<Id>> mapSOProdId,String evt){
        if(!mapSOProdId.isEmpty()){
            List<OpportunityOfferLine__c> lstOffLines = new List<OpportunityOfferLine__c>();
            
            for(OpportunityOfferLine__c oppOff: [SELECT Id,QuantityInProgress__c,SalesOrder__c,ConsumedQuantity__c,Product_Item__r.Product2Id FROM OpportunityOfferLine__c WHERE SalesOrder__c=: mapSOProdId.keySet() AND Product_Item__r.Product2.Type__c = 'On Demand' AND Product_Item__r.Product2.isActive = True]){
                Set<Id> setprods = mapSOProdId.get(oppOff.SalesOrder__c);
                if(setprods != null && setprods.contains(oppOff.Product_Item__r.Product2Id)){
                    if(evt =='create')
                        oppOff.QuantityInProgress__c = (oppOff.QuantityInProgress__c != null ? oppOff.QuantityInProgress__c + 1 : 1);   
                    else if(evt =='closed')    {
                        oppOff.QuantityInProgress__c = (oppOff.QuantityInProgress__c != null ? oppOff.QuantityInProgress__c - 1 : 0);   
                        oppOff.ConsumedQuantity__c = (oppOff.ConsumedQuantity__c != null ? oppOff.ConsumedQuantity__c + 1 : 1);   
                    }
                    else if(evt =='cancelled'){
                        oppOff.QuantityInProgress__c = (oppOff.QuantityInProgress__c != null ? oppOff.QuantityInProgress__c - 1 : 0);   
                    }
                    lstOffLines.add(oppOff);
                }    
            }
            UPDATE lstOffLines;
        }
    }//V2.2 END
    
    // Added By Moh Sarfaraj for BPM-431
    public static void sentEmailToHuspyAfterVerified (Set<Id> setVerifiedCaseIds){
        List<String> toRecipents = System.Label.FinanceAfterApprovedCaseEmail.split(',');
        String emailTemplateDeveloperName = 'FinanceAfterApprovedEmailTemplate';
        Map<Id,Attachment> attachmentMap = new Map<Id,Attachment>();
        Set<Id> setToCheckCaseAttachmentTaken = new Set<Id>();
        
        for(Attachment eachAttachment : [SELECT Id,ParentId FROM Attachment WHERE ParentId IN: setVerifiedCaseIds ORDER BY CreatedDate DESC]){
            if(!setToCheckCaseAttachmentTaken.contains(eachAttachment.ParentId)){
                
                attachmentMap.put(eachAttachment.Id, eachAttachment);
                setToCheckCaseAttachmentTaken.add(eachAttachment.ParentId);
            }
        }
        // Calling Queueable to sending emails
        if(!attachmentMap.isEmpty() && toRecipents != null && !toRecipents.isEmpty()){
            Integer delayInMinutes = 1;
            System.enqueueJob(new HomeFinanceCaseSubmissionInvocable.FinanceUtilityToSentEmail(attachmentMap, emailTemplateDeveloperName, toRecipents, null), delayInMinutes);
        }
    }
    
    // Added By Moh Sarfaraj for BPM-460 Home Finance Case
    public static void createCommissionRecord (Set<Id> setParentCaseIds, List<Case> newCaseList){
        try{
            final List<String> listCommissionPercentagePot = new List<String>(System.Label.HomeFinanceCommissionPercentValue.split(','));
            List<CommissionLineItem__c> listCLIToInsert = new List<CommissionLineItem__c>();
            
            for(Case eachCase : newCaseList){
                if(setParentCaseIds.contains(eachCase.Id)){
                    CommissionLineItem__c commissionLineItem = new CommissionLineItem__c();
                    commissionLineItem.SalesManager__c = UserInfo.getUserId(); //eachCase.OwnerId;
                    commissionLineItem.CommissionType__c = 'Internal';
                    commissionLineItem.Case__c = eachCase.Id;
                    commissionLineItem.CommissionPercentage__c = 0;
                    Double commissionPot = (Double.valueOf(listCommissionPercentagePot[0]) * eachCase?.Sum_of_Total_Commission_for_Aldar__c)/100;
                    commissionLineItem.CommissionAmount__c = (Double.valueOf(listCommissionPercentagePot[1]) * commissionPot)/100;
                    listCLIToInsert.add(commissionLineItem);
                }
            }
            if(!listCLIToInsert.isEmpty()){
                insert listCLIToInsert;
            }
        }catch(Exception ex){System.debug('error->'+ex.getMessage());}
    }

    // Added By Moh Sarfaraj for BPM-475 starts
    public static Boolean isByPassCaseTrigger = false;
    
    @InvocableMethod(label='CaseTriggerHandler class byPassCaseTrigger method to avoid document placeholder records')
    public static void byPassCaseTrigger(List<Id> ids){
        isByPassCaseTrigger = true;
    }

    public static void createHomeFinanceDocuments(List<Case> caseRecords){
        String HOME_FINANCE_CASE = 'Home Finance Case';
        List<Document__c> documentListToInsert = new List<Document__c>();
        Map<string,Id> documentRecordTypeMap = new Map<String,Id>();
        Map<Id,Case> caseIdToRecMap = new map<Id,Case>(caseRecords);
        Map<String,List<DocumentPlaceHolder__mdt>> documentMap = 
            DocumentService.getDocumentMetaDataByCategory(new Set<String>{HOME_FINANCE_CASE});

        if(!documentMap.isEmpty() && !caseIdToRecMap.isEmpty()){
            //get Existing Documents
            Map<String,Document__c> existingDocMap = new Map<String,Document__c>();
            for(Document__c tempDoc : [SELECT Id,DocumentType__c,Case__c FROM Document__c WHERE Case__c IN :caseIdToRecMap.keySet()]){
                existingDocMap.put(tempDoc.Case__c+tempDoc.DocumentType__c, tempDoc);
            }

            for(Case eachCase : caseRecords){
                String documentTypeToProcess; 
                List<DocumentPlaceHolder__mdt> documentsToProcess = new List<DocumentPlaceHolder__mdt>();

                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(HOME_FINANCE_CASE)){
                    string recordTypeID = null;
                
                    if(tempMetaRec.RecordTypeDeveloperName__c != null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c, Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID = documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                    
                    if(!existingDocMap.containsKey(eachCase.Id + tempMetaRec.DocumentType__c)){
                        Document__c documentRecord = new Document__c();// DocumentService.createDocumentRecord('','','',tempMetaRec.DocumentType__c,'', eachCase.Id, recordTypeID);
                        documentRecord.Case__c = eachCase.Id; 
                        documentRecord.RecordTypeId = recordTypeID;
                        documentRecord.DocumentType__c = tempMetaRec.DocumentType__c;
                        documentRecord.SendForESign__c = tempMetaRec.eSignRequired__c;
                        documentRecord.DocumentPlaceHolderId__c = tempMetaRec.DeveloperName;  
                        documentRecord.EligibleForeSign__c = tempMetaRec.EligibleForeSign__c;
                        documentListToInsert.add(documentRecord); 
                        existingDocMap.put(eachCase.Id + tempMetaRec.DocumentType__c,documentRecord);       
                    }
                }
            }
        }
        if(!documentListToInsert.isEmpty()){
            insert documentListToInsert;  
        } 
    }
    public static void caseEmailValidation(List<Case> emailCases , Set<String> emailCasesSuppliedEmails){
        Map<String, List<String>> emailSubjectMap = new Map<String, List<String>>();
        List<Case> existingCases = [SELECT Id, Subject, SuppliedEmail FROM Case WHERE SuppliedEmail IN :emailCasesSuppliedEmails AND CreatedDate = TODAY];
        for (Case existingCase : existingCases) {
            if (existingCase.SuppliedEmail<> null) {
                if (emailSubjectMap.containsKey(existingCase.SuppliedEmail)) {
                    List<String> tempList =  new List<String>();
                    tempList.add(existingCase.Subject);
                    tempList.addAll(emailSubjectMap.get(existingCase.SuppliedEmail));
                    emailSubjectMap.put(existingCase.SuppliedEmail,tempList);
                } else {
                    emailSubjectMap.put(existingCase.SuppliedEmail,new List<String>{existingCase.Subject});
                }
            }
        }            
        for (Case newCase : emailCases) {
            String suppliedEmail = newCase.SuppliedEmail != null ? newCase.SuppliedEmail : null;
            if (suppliedEmail != null && emailSubjectMap.containsKey(suppliedEmail) && emailSubjectMap.get(suppliedEmail).contains(newCase.Subject)) {
                // if (emailSubjectMap.get(suppliedEmail) == newCase.Subject) {
                newCase.addError('A case with the same subject and email address already exists today.');                        
                //}
            }
        }
    }
    
    public static void CreateResolvertask(list<case> caserec){
        String RecordTypeID = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Resolver Task').getRecordTypeId();
        List<Task> tasksToInsert = new List<Task>();
        for(case caseRecord : caserec){
        Task newTask = new Task();
        newTask.Subject = 'Call Attempt 1';
        newTask.OwnerId = caseRecord.Assigned_To__c;
        newTask.WhatId = caseRecord.Id;
        newTask.Task_Name__c = 'Call Attempt 1';
        newTask.RecordTypeId = RecordTypeID;
        newTask.Type__c = 'Resolver Attempt Task';
        newTask.Case_Resolved_Time__c =caseRecord.Resolved_Time__c; 
        tasksToInsert.add(newTask);
        }
         if(tasksToInsert.size() > 0){
            insert tasksToInsert;
        }  
    }
    //Added be adarsh for case auto assingment
    public static void autoassigmentBulk(Map<Id, Case> caseMap,Map<Id, Case_Field_Dependency_Revised__mdt> dependencyMap){
        
        list<case> autoSaleCases = new list<case>();
        list<case> autoBrokerCases = new list<case>();
        list<case> autoResaleCases = new list<case>();
        list<ID> autoResaleCasesUnit = new list<ID>();
        Map<Id, Id> unitToCaseMap = new Map<Id, Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Opportunity> accountToOppMap = new Map<Id, Opportunity>();
        for (Id caseId : caseMap.keySet()) {
            Case caseRec = caseMap.get(caseId);
            Case_Field_Dependency_Revised__mdt fieldDep = dependencyMap.get(caseId);
            
            if (fieldDep != null && fieldDep.Auto_Assingment__c != null) {
                if (fieldDep.Auto_Assingment__c == 'Sales queue') {
                    autoSaleCases.add(caseRec);
                    accountIds.add(caseRec.AccountId);
                } else if (fieldDep.Auto_Assingment__c == 'Broker queue') {
                    autoBrokerCases.add(caseRec); 
                    accountIds.add(caseRec.AccountId);
                }
                else if (fieldDep.Auto_Assingment__c == 'ReSale queue') {
                    autoResaleCases.add(caseRec);
                    autoResaleCasesUnit.add(caseRec.Unit__c);                   
                }                
            }
        }
        if(!autoResaleCasesUnit.isempty()){
            list <case> resaleCase = [Select id,OwnerId,Unit__c from case where Unit__c IN :autoResaleCasesUnit And Recordtype_Name__c = 'Resale' AND Status != :Constants.CLOSED_CASE ORDER BY LastModifiedDate DESC  ];
            for(case rsc : resaleCase){
              unitToCaseMap.put(rsc.Unit__c,rsc.OwnerId);  
            }
        }
        for (Opportunity opp : [SELECT Id, AccountId, SalesManager__c,SalesManager__r.Team__c FROM Opportunity WHERE AccountId IN :accountIds ORDER BY LastModifiedDate DESC]) {
            if (!accountToOppMap.containsKey(opp.AccountId)) {
                accountToOppMap.put(opp.AccountId, opp);
            }
        }
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, OwnerId,Owner.Team__c FROM Account WHERE Id IN :accountIds]);
        map<id,string> salesGroupUser = checkUserQueue ('Sales Queue');
        if(!autoSaleCases.isEmpty()){
            for (Case cs : autoSaleCases) {
                Opportunity opp = accountToOppMap.get(cs.AccountId);
                if (opp != null && opp.SalesManager__c != null && salesGroupUser.containsKey(opp.SalesManager__c)) {
                    cs.Assigned_To__c = opp.SalesManager__c;
                    cs.User_Location__c = opp.SalesManager__r.Team__c;
                    
                } else {
                    Account acc = accountMap.get(cs.AccountId);
                    if (acc != null && acc.OwnerId !=null && salesGroupUser.containsKey(acc.OwnerId)) {
                        cs.Assigned_To__c = acc.OwnerId;
                        cs.User_Location__c = acc.Owner.Team__c;
                        
                    }
                }
            }
        }
        else if (!autoBrokerCases.isEmpty()){
            Map<Id, String> brokerGroupUser = checkUserQueue ('Broker Queue');
            For(Case cs : autoBrokerCases){
                Account acc = accountMap.get(cs.AccountId);
                if (acc != null && acc.OwnerId !=null && brokerGroupUser.containsKey(acc.OwnerId)) {
                    cs.Assigned_To__c = acc.OwnerId;
                    cs.User_Location__c = acc.Owner.Team__c;
                    
                }
            }
        }
        else if (!autoResaleCases.isEmpty()){
            map<id,string> resaleGroupUser = checkUserQueue ('Resale Queue');
            For(Case cs : autoResaleCases){
                Id assignedUserId = unitToCaseMap.get(cs.Unit__c);
                if (assignedUserId != null && resaleGroupUser.containsKey(assignedUserId)) {
                    cs.Assigned_To__c = assignedUserId;
                }
            }
        }
              
    }
    public static map<id,string> checkUserQueue (string grpName){
        List<GroupMember> groupMembers = [ SELECT Id, UserOrGroupId, Group.Name FROM GroupMember WHERE Group.Name =: grpName];
        Map<Id, String> userGroupMap = new Map<Id, String>();
        
        for (GroupMember gm : groupMembers) {
            if (gm.UserOrGroupId != null && gm.Group != null) {
                userGroupMap.put(gm.UserOrGroupId, gm.Group.Name);
            }
        }
        return userGroupMap;
    }
    // Added By Moh Sarfaraj for BPM-475 end
public static void validateDLPCases(List<Case> lstOwnerChangeCases){
        // Create a map to hold CaseId and corresponding Service Appointment OwnerId
        Map<Id, Id> serviceAppointmentOwnerMap = new Map<Id, Id>();
        for (ServiceAppointment sa : [SELECT Id, FSSK__FSK_Assigned_Service_Resource__r.RelatedRecordId, Case__c  FROM ServiceAppointment  WHERE Case__c IN :lstOwnerChangeCases AND Record_Type_Name__c='Assessment' AND Status !='Closed']) {
            serviceAppointmentOwnerMap.put(sa.Case__c, sa.FSSK__FSK_Assigned_Service_Resource__r.RelatedRecordId);
        }
        for(Case caseRecord : lstOwnerChangeCases){
            if(caseRecord.Status == 'New')
                caseRecord.addError(Label.CaseOwnerWarning);
            else if(caseRecord.Status == 'Assigned' || caseRecord.Status == 'Re-scheduled'){    
                Id serviceAppointmentOwnerId = serviceAppointmentOwnerMap.get(caseRecord.Id);
                // Check if Case Owner and Service Appointment Owner match
                if (caseRecord.OwnerId != serviceAppointmentOwnerId) {
                    caseRecord.addError(Label.CaseOwnerWarning);
                }
            }
        }
    }
}