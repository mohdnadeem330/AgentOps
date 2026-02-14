public with sharing class SalesOrderTriggerHandler extends TriggerHandler{
    public static String DigitalSPASigned = 'Digital SPA Signed';
    public static String AFFECTIONPLAN = 'Affection Plan';
    public static String AFFECTIONPLAN2 = 'Affection Plan 2';
    public static Boolean  skipSalesOrderTrigger = false;
     
     public override void beforeInsertMethod(list<SObject> newList,Map<Id, SObject> newMap){
         //Added by CHirag START
         Map<Id, Set<String>> accIdToProjPayPlanKeysSetMap = new Map<Id, Set<String>>();
          Set<Id>PaymentPlanIds = new Set<Id>();
         Set<Id>UnitIds = new Set<Id>();
         Set<Id>AccountIds = new Set<Id>();
         set<Id> unitIdSet = new set<Id>();
         //Added by CHirag END
         for (SalesOrder__c so: (list<SalesOrder__c>) newList) {
             unitIdSet.add(so.Unit__c);
             // Added by Moh Sarfaraj ASF-1414
             if(String.isNotBlank(so.ProjectName__c)){
                 so.Project_Name__c = so.ProjectName__c;
             }
             
            if(so.CustomerType__c != null && so.CustomerType__c.trim().equalsIgnoreCase(Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF) && System.Label.AldarStaffON.equalsIgnoreCase('true')){
                UnitIds.add(so.Unit__c);
                 PaymentPlanIds.add(so.PaymentPlan__c);//Added by Chirag
              }
             if(so.Account__c != null){
                AccountIds.add(so.Account__c);
            }
             // so.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
             //If Salesorder Status is Pending or Booked initiate Qualtrics
             if(so.Status__c!=null && (so.Status__c == Constants.UNIT_STATUS_SOLD || so.Status__c == Constants.OPPO_UNIT_STATUS_PENDING)){
                 so.QualtricsIntegrationStatus__c=Constants.QUALTRICS_IN_PROGRESS;
             }
              //Added by Chirag
             if(so.ComplianceStatus__c != null){
                 so.ComplianceStatusModifiedBy__c = UserInfo.getUserId();
             }
             if(so.JointOwnerComplianceStatus__c != null){
                 so.JointComplianceStatusModifiedBy__c = UserInfo.getUserId();
             }
             if(so.ThirdPartyComplianceStatus__c != null){
                 so.ThirdPartyComplianceModifiedBy__c = UserInfo.getUserId();
             }

         }
         
           // Added BY Mahidhar Start ASF-3626 Check if any unit is already booked (Reserved, Approve pending, Sold, reservation in progress)

         /*if(System.Label.Unit_Status_Check == 'true' && UnitIds.size() > 0){

             Map<Id, SalesOrder__c> unitStatusMap = new Map<Id, SalesOrder__c>();

            for (SalesOrder__c so : [SELECT Id, Unit__c FROM SalesOrder__c
                                                     WHERE Unit__c IN :UnitIds AND Unit__r.Status__c 
                                                     IN :SalesOrder_Constants.UNIT_STATUSES]){
                unitStatusMap.put(so.Unit__c, so);
            }   

            for (SalesOrder__c so : (List<SalesOrder__c>) newList){
                if (unitStatusMap.containsKey(so.Unit__c)){
                    // Add error to the SalesOrder if the unit is already booked
                    so.addError(System.Label.Unit_Is_Already_Booked);
                }
            }
         }*/        //ASF-3626 - END

        if(!unitIdSet.isEmpty() && system.label.RestrictMultipleSO == 'true'){
            overrideSharing cls = new overrideSharing();
            cls.restrictMultipleSoOnSameUnit(unitIdSet, newList);
        }
         
         Map<Id,List<Communication_Preference__c>> ComMap = new Map<Id,List<Communication_Preference__c>>();
         for(Communication_Preference__c cp :[SELECT Id,Account__c,Account__r.FastTrack_Account__c FROM Communication_Preference__c WHERE Account__c =:AccountIds AND Status__c='Fasttrack Completed' AND FastTrack_Completion_Date_Time__c != null ORDER BY FastTrack_Completion_Date_Time__c DESC]){
            if(ComMap.containsKey(cp.Account__c)){
                List<Communication_Preference__c> CPlist = ComMap.get(cp.Account__c);
                CPlist.add(cp);
                ComMap.put(cp.Account__c,CPlist);
            }else{
                List<Communication_Preference__c> CPlist = new List<Communication_Preference__c>();
                CPlist.add(cp);
                ComMap.put(cp.Account__c,CPlist);
            }
         }
          //Added by CHirag START
          Map<String,List<String>>salesorderUnitMap = new Map<String,List<String>>();
         if(UnitIds.size() >0){
         //Added by Chirag START
         Map<Id,String>PaymentClassification = new Map<Id,String>();
         for(Paymentplan__c pc : [SELECT Id,Name,Classification__c FROM PaymentPlan__c WHERE Id=:PaymentPlanIds]){
             PaymentClassification.put(pc.Id,pc.Classification__c);
         }
         Map<Id,String>UnitSOMap = new Map<Id,String>();
         for(Unit__c pc : [SELECT Id,Name,BuildingSectionName__r.Project__r.CommunityName__c FROM Unit__c WHERE Id=:UnitIds]){
             UnitSOMap.put(pc.Id,pc.BuildingSectionName__r.Project__r.CommunityName__c);
         }  
         
         for(SalesOrder__c sorder :(list<SalesOrder__c>) newList){
             if(!ComMap.isEmpty() && ComMap.get(sorder.Account__c) != null){
                sorder.CommunicationPreference__c = ComMap.get(sorder.Account__c)[0].Id;
            }
             //System.debug('Chirag1'+sorder.CustomerType__c+'Test'+Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF+'Test1'+sorder.PaymentPlan__r.Classification__c);
             if(sorder.CustomerType__c.trim().equalsIgnoreCase(Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF) && sorder.Account__c != null  && UnitSOMap.get(sorder.Unit__c) != null && sorder.PaymentPlan__c != null && PaymentClassification.get(sorder.PaymentPlan__c)=='30-70'){//&& 
             
                if(salesorderUnitMap.containsKey(sorder.Account__c +'_'+ UnitSOMap.get(sorder.Unit__c) +'_'+ sorder.PaymentPlan__c)){
                    salesorderUnitMap.get(sorder.Account__c +'_'+ UnitSOMap.get(sorder.Unit__c) +'_'+ sorder.PaymentPlan__c).add( UnitSOMap.get(sorder.Unit__c) +'_'+ sorder.PaymentPlan__c );
                }else{
                    salesorderUnitMap.put(sorder.Account__c +'_'+ UnitSOMap.get(sorder.Unit__c) +'_'+ sorder.PaymentPlan__c, new List<String>{ UnitSOMap.get(sorder.Unit__c) +'_'+ sorder.PaymentPlan__c });
                }
                 if(accIdToProjPayPlanKeysSetMap.containsKey(sorder.Account__c)){
                    accIdToProjPayPlanKeysSetMap.get(sorder.Account__c).add( UnitSOMap.get(sorder.Unit__c) +'_'+ sorder.PaymentPlan__c );
                }else{
                    accIdToProjPayPlanKeysSetMap.put(sorder.Account__c, new Set<String>{ UnitSOMap.get(sorder.Unit__c) +'_'+ sorder.PaymentPlan__c });
                }
            }
         }
            
         for (SalesOrder__c so: (list<SalesOrder__c>) newList) {
             if(salesorderUnitMap.get( so.Account__c +'_'+ UnitSOMap.get(so.Unit__c)  +'_'+ so.PaymentPlan__c ) != null && salesorderUnitMap.get( so.Account__c +'_'+ UnitSOMap.get(so.Unit__c)  +'_'+ so.PaymentPlan__c ).size() >1){
                 so.addError(System.Label.CustomerPayPlanErrorPerProject);
             }
         }
             
             if(!accIdToProjPayPlanKeysSetMap.isEmpty()){
            Set<String> exitingAccProjPayPlanCombination = getExitingProjPayPlanByAccId(accIdToProjPayPlanKeysSetMap);
            if(exitingAccProjPayPlanCombination != null && !exitingAccProjPayPlanCombination.isEmpty()){
                for (SalesOrder__c so: (list<SalesOrder__c>) newList) {
                    
                    if(exitingAccProjPayPlanCombination.contains( so.Account__c +'_'+  UnitSOMap.get(so.Unit__c) +'_'+ so.PaymentPlan__c )){
                        so.addError(System.Label.CustomerPayPlanErrorPerProject);
                    }
                }
            }
        }
         }
         //Added BY Chirag END
//        updateAffectionDocumentId((list<SalesOrder__c>) newList);
         newUpdateAffectionDocumentId((list<SalesOrder__c>) newList);
         updateBrokerManager((list<SalesOrder__c>) newList);
         updateInventoryLaunch((list<SalesOrder__c>) newList);
     }


    public without sharing class overrideSharing{
        public void restrictMultipleSoOnSameUnit(set<Id> unitIdSet, list<SObject> newList){
            list<string> activeSoStatusList = system.label.ActiveSalesOrderStatus.split(';');
            map<string,string> invalidSoMap = new map<string,string>();
            for(Salesorder__c SO : [SELECT Id,Unit__c FROM Salesorder__c WHERE Unit__c IN: unitIdSet AND Status__c IN: activeSoStatusList]){
                invalidSoMap.put(SO.Unit__c,'Active sales order already present for this unit');
                break;
            }
            for(Salesorder__c SO : (list<Salesorder__c>)newList){
                if(invalidSoMap.containsKey(SO.Unit__c)){
                    SO.addError(invalidSoMap.get(SO.Unit__c));
                }
            }
        }
    }
    

    private static Set<String>  getExitingProjPayPlanByAccId(Map<Id, Set<String>> accIdToProjPayPlanKeysSetMap) {
        Set<String> exitingAccProjPayPlanCombination = new Set<String>(); 
        if(!accIdToProjPayPlanKeysSetMap.isEmpty()){
            List<SalesOrder__c> existingSOs = [ SELECT Id, Project_Id__c, CommunityName__c,Unit__r.BuildingSectionName__r.Project__r.CommunityName__c,
                                                    Account__c, Account__r.CustomerType__c, 
                                                    PaymentPlan__c, PaymentPlan__r.Classification__c 
                                                FROM SalesOrder__c 
                                                WHERE Account__c IN: accIdToProjPayPlanKeysSetMap.keySet()];
            if(existingSOs != null && !existingSOs.isEmpty()){
                for(SalesOrder__c so: existingSOs){
                    if(so.Account__r.CustomerType__c != null && so.Unit__r.BuildingSectionName__r.Project__r.CommunityName__c != null && so.PaymentPlan__c != null ){ // Updated ProjectId to CommunityName By CHirag
                        if(so.Account__r.CustomerType__c.trim().equalsIgnoreCase(Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF) && so.PaymentPlan__r.Classification__c=='30-70' ){//updated Classification from Is30_70Plan by CHirag
                            if(accIdToProjPayPlanKeysSetMap.get(so.Account__c).contains( so.Unit__r.BuildingSectionName__r.Project__r.CommunityName__c +'_'+ so.PaymentPlan__c )){// Updated ProjectId to CommunityName By CHirag
                                exitingAccProjPayPlanCombination.add( so.Account__c +'_'+ so.Unit__r.BuildingSectionName__r.Project__r.CommunityName__c +'_'+ so.PaymentPlan__c );// Updated ProjectId to CommunityName By CHirag
                            }
                        }
                    }
                }
            }
        }
        return exitingAccProjPayPlanCombination;
     }
     
     
     // Method to get affection plan id for Digital SPA.
     public static void newUpdateAffectionDocumentId(list<SalesOrder__c> newList){
        List<Id> unitIds =new List<Id>();
        Map<String,Id> docIdByUnit = new Map<String,Id>();
        Map<Id,SalesOrder__c> salesOrdersByUnit = new Map<Id,SalesOrder__c>();
        for(SalesOrder__c so : newList){
            salesOrdersByUnit.put(so.Unit__c, so);
            //unitIds.add(so.Unit__c);
        }
         List<String> documentTypeList = new List<String>{AFFECTIONPLAN,AFFECTIONPLAN2};
             Map<String,Id> documentIdsByType = new Map<String,Id>();
         Map<String,Map<String,Id>> documentIdsByTypeByUnit = new Map<String,Map<String,Id>>();
         Map<Id,Id> docByUnit = new Map<Id,Id>();
         Set<Id> docIds = new Set<Id>();
         for(Document__c doc : [SELECT Id,Unit__c,DocumentType__c FROM Document__c WHERE
                               Unit__c IN: salesOrdersByUnit.keySet() 
                               AND DocumentType__c IN: documentTypeList
                               AND Unit__c != NULL]){
                                   Map<String,Id> tempMapForDocType = new Map<String,Id>();
                                   if(documentIdsByTypeByUnit.containsKey(doc.Unit__c)){
                                       documentIdsByTypeByUnit.get(doc.Unit__c).put(doc.DocumentType__c,doc.Id );
                                   }else{
                                       documentIdsByTypeByUnit.put(doc.Unit__c,new Map<String,Id>{doc.DocumentType__c =>doc.Id});
                                       //tempMapForDocType.
                                   }
                                   docIds.add(doc.Id);
                                   //                docByUnit.put(doc.Unit__c,doc.Id);
                               }
        system.debug('docByUnit  '+docByUnit);
        if(!documentIdsByTypeByUnit.isEmpty() && !docIds.isEmpty()){
            Map<Id,Id> contentIdByDocId = new Map<Id,Id>();
            for(ContentDocumentLink cdl : [SELECT LinkedEntityId,ContentDocumentId FROM ContentDocumentLink 
                                           WHERE LinkedEntityId IN:docIds 
                                           ORDER BY ContentDocument.CreatedDate DESC]){
                                               if(!contentIdByDocId.containsKey(cdl.LinkedEntityId)){
                                                   contentIdByDocId.put(cdl.LinkedEntityId,cdl.ContentDocumentId);
                                               }
                                           }
            if(!contentIdByDocId.isEmpty()){
                for(SalesOrder__c so : newList){
                    if(documentIdsByTypeByUnit.containsKey(so.Unit__c)){
                        for(String docType : documentIdsByTypeByUnit.get(so.Unit__c).keySet()){
                            if(contentIdByDocId.containsKey(documentIdsByTypeByUnit.get(so.Unit__c).get(docType)) && contentIdByDocId.containsKey(documentIdsByTypeByUnit.get(so.Unit__c).get(docType)) != null){
                                if(docType == AFFECTIONPLAN){
                                    so.AffectionPlanId__c = contentIdByDocId.get(documentIdsByTypeByUnit.get(so.Unit__c).get(docType))  ;
                                    system.debug('Affection Plan -> '+so.AffectionPlanId__c);
                                }else if(docType == AFFECTIONPLAN2){
                                    so.AffectionPlanId2__c = contentIdByDocId.get(documentIdsByTypeByUnit.get(so.Unit__c).get(docType))  ;
                                    system.debug('Affection Plan 2 -> '+so.AffectionPlanId2__c);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
 /*   public static void updateAffectionDocumentId(list<SalesOrder__c> newList){
         List<Id> unitIds =new List<Id>();
         Map<String,Id> docIdByUnit = new Map<String,Id>();
         Map<Id,SalesOrder__c> salesOrdersByUnit = new Map<Id,SalesOrder__c>();
         for(SalesOrder__c so : newList){
             salesOrdersByUnit.put(so.Unit__c, so);
             //unitIds.add(so.Unit__c);
         }
         Map<Id,Id> docByUnit = new Map<Id,Id>();
         for(Document__c doc : [SELECT Id,Unit__c FROM Document__c WHERE Unit__c IN: salesOrdersByUnit.keySet() AND DocumentType__c = 'Affection Plan']){
             if(doc.Unit__c != null)
                 docByUnit.put(doc.Unit__c,doc.Id);
         }
         system.debug('docByUnit  '+docByUnit);
         if(!docByUnit.isEmpty()){
             Map<Id,Id> contentIdByDocId = new Map<Id,Id>();
             for(ContentDocumentLink cdl : [SELECT LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:docByUnit.values() ORDER BY ContentDocument.CreatedDate DESC]){
                 if(!contentIdByDocId.containsKey(cdl.LinkedEntityId)){
                     contentIdByDocId.put(cdl.LinkedEntityId,cdl.ContentDocumentId);
                 }
             }
             system.debug('contentIdByDocId '+contentIdByDocId);
             if(!contentIdByDocId.isEmpty()){
                 for(SalesOrder__c so : newList){
                     if(docByUnit.containsKey(so.Unit__c)){
                         if(contentIdByDocId.containsKey(docByUnit.get(so.Unit__c)) && contentIdByDocId.containsKey(docByUnit.get(so.Unit__c)) != null){
                             so.AffectionPlanId__c = contentIdByDocId.get(docByUnit.get(so.Unit__c)) ;
                             system.debug('so.AffectionPlanId__c '+so.AffectionPlanId__c);
                         }
                     }
                 }
             }
         }
     }
*/
     //*** Before Update Action***//
     public override void beforeUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
         // Added By Moh Sarfaraj for ASF-1468
         //---- to share Sales Order record with FAB Group for Balghailam
         //ShareHelper.shareSalesOrderFABGroup(newList, Constants.EDIT_ACCESS); //Commented by Jyoti Lankapati - SOQL 101 Error (Suggested by Rijwan)
         Set<Id> salesOrderSoldStatusIds = new Set<Id>();
         // Map<String, Decimal> salesOrderSharePercentageMap = new Map<String, Decimal>();
         System.debug('newList '+newList);
         System.debug('newMap.keySet() '+newMap.keySet());
         // List<SalesOrder__c> salesOrderSharePercentageList = [SELECT Id, OwnerSharePercentage__c, (SELECT Id, SharePercentage__c FROM Joint_OwnersSalesOrder__r) FROM SalesOrder__c WHERE Id IN :newMap.keySet()];
         // for (SalesOrder__c salesOrder: salesOrderSharePercentageList) {
         //     Decimal sharePercentage = salesOrder.OwnerSharePercentage__c != null ? salesOrder.OwnerSharePercentage__c : 0;
         //     if (!salesOrder.Joint_OwnersSalesOrder__r.isEmpty()) {
         //         for (JointOwner__c jointOwner: salesOrder.Joint_OwnersSalesOrder__r) {
         //             sharePercentage += jointOwner.SharePercentage__c != null ? jointOwner.SharePercentage__c : 0;
         //         }
         //         salesOrderSharePercentageMap.put(salesOrder.Id, sharePercentage);
         //     }
         // }
         User usr = Utilities.getLoggedInUserDetail();
         for (SalesOrder__c so: (list<SalesOrder__c>) newList) {
             SalesOrder__c oldSO = (SalesOrder__c)oldmap.get(so.Id);
             //Arvind - NetAmountInWords__c is blank for migrated Salesforder - below code is for auto update NetAmountInWords__c on saving 
             if (so.NetAmountInWords__c == null || (so.NetAmount__c != oldSO.NetAmount__c) )
             {
                 //Arvind chnaged  Dirham to Dirhams
                so.NetAmountInWords__c = Utilities.amountInWords(so.NetAmount__c,'Dirhams','Fils');
             }
             if(oldSO.SignatureType__c == 'Physical Signature' && so.SignatureType__c == 'Digital Signature') {
                 so.SignatureChangeApprovalStatus__c = ''; 
             }
             // if (so.OwnerSharePercentage__c != oldSO.OwnerSharePercentage__c && salesOrderSharePercentageMap.containsKey(so.Id)) {
             //     Decimal sharePercentage = salesOrderSharePercentageMap.get(so.Id) + (so.OwnerSharePercentage__c - (oldSO.OwnerSharePercentage__c != null ? oldSO.OwnerSharePercentage__c : 0));
             //     if (sharePercentage > 100) {
             //         so.addError('Total Share Percentage cannot exceed 100%');
             //     }
             // }
 
             //MandatoryDoccheck. 
             //
             system.debug('oldSO.SubStatus__c' + oldSO.SubStatus__c);
             system.debug('oldSO.SubStatus__c' + oldSO.SubStatus__c);
             
             //temporarily added here to avoid error while Constants override 
             String SUB_STATUS_CONTRACTDOCUMENTPRINTED = 'Contract Document Printed';
             String SUB_STATUS_PENDINGWITHSALESADMIN = 'Pending with Sales Admin';
             // || so.SubStatus__c == SUB_STATUS_CONTRACTDOCUMENTPRINTED - removed from line 85 - Muzammil
             if((oldSO.SubStatus__c == Constants.OPPO_UNIT_SUBSTATUS_PENDING_SM || oldSO.SubStatus__c == SUB_STATUS_CONTRACTDOCUMENTPRINTED) && oldSO.SubStatus__c <> so.SubStatus__c && ( so.SubStatus__c == Constants.SUB_STATUS || so.SubStatus__c ==  SUB_STATUS_PENDINGWITHSALESADMIN ) 
             ) {
                 set<string> MDoclist = SalesOrderService.getMandatoryDocsStatus(SO);
                 String docNames = '';
                 Integer MDoclistcount = MDocList.size();
                 if(MDoclistcount > 0) {
                     for(string docName : MDoclist){
                         if (docNames <> '') docNames = docNames + ',';
                         docNames += docName;
                     }
                     if(MDoclistcount==1) {
                         so.addError('Mandatory Document not uploaded. Missing document is ' + docNames);
                     }
                     else
                         so.addError('Mandatory Documents not uploaded. Missing documents are ' + docNames);
                     
                 }
             }
             //-------------
 
           
             if (!so.IsSalesOrderChange__c && so.IsInstallmentLinesChange__c == oldSO.IsInstallmentLinesChange__c && so.IsOtherChargesChange__c == oldSO.IsOtherChargesChange__c && so.IsSalesOffersChange__c == oldSO.IsSalesOffersChange__c && so.IsSalesConsultantsChange__c == oldSO.IsSalesConsultantsChange__c) {
                 so.IsSalesOrderChange__c = true;
             }
             //If Salesorder Status is Pending or Booked initiate Qualtrics
             if(so.Status__c!=null && so.Status__c != oldSO.Status__c && (so.Status__c == Constants.UNIT_STATUS_SOLD || so.Status__c == Constants.OPPO_UNIT_STATUS_PENDING) && so.Sales_Type__c == 'New Sale' ){
                 so.QualtricsIntegrationStatus__c=Constants.QUALTRICS_IN_PROGRESS;
                 system.debug('------QualtricsIntegrationStatus__c---- '+so.QualtricsIntegrationStatus__c  );
             }
             //for balghailam change to approve pending when sub status is changed to Validated by CM
             // Changed Condition by Moh Sarfaraj on 12-July-23 as suggested By Arvind
             if(so.Status__c != null && so.Status__c == Constants.OPPO_UNIT_STATUS_PENDING && 
                so.Final_Approval_from_Bank__c  && so.Final_Approval_from_Bank__c != oldSO.Final_Approval_from_Bank__c && 
                so.CustomerSPASigned__c && so.ProjectName__c == String.valueof(System.Label.ADHAProject)){
                 
                so.Status__c = Constants.SALES_STATUS;
             }
             if( (so.Status__c != oldSO.Status__c || so.SubStatus__c != oldSO.SubStatus__c ) && (so.Status__c == Constants.SALES_STATUS || so.Status__c == Constants.SO_STATUS_RTO_Approve_PENDING) &&  (so.SubStatus__c == Constants.SALES_SUB_STATUS_SPA_SIGNEDOFF || so.SubStatus__c == Constants.SALES_SUB_STATUS_REGISTRATION_COMPLETED ) ){
                 so.Status__c = so.Status__c == Constants.SALES_STATUS ? Constants.UNIT_STATUS_SOLD : Constants.SO_STATUS_RTO_SOLD;
                 so.SoldDate__c = so.SoldDate__c==null?system.Today():so.SoldDate__c;
                 so.SalesApprovedDate__c=so.SalesApprovedDate__c==null?system.Today():so.SalesApprovedDate__c;
             }
             if(so.Status__c != oldSO.Status__c && so.Status__c== Constants.SALES_STATUS && so.ApprovePendingDate__c==null){
                 so.ApprovePendingDate__c=system.Today();
             }
             if(so.SubStatus__c != oldSO.SubStatus__c && so.SubStatus__c == DigitalSPASigned){
                 so.DigitallySignedSPA__c = true;
             }
             system.debug('is batch :'+system.isBatch());
             if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && so.SyncTime__c == oldSO.SyncTime__c && so.SyncStatus__c == Constants.STATUS_SYNCED && ((so.Status__c == Constants.SO_STATUS_SOLD && so.Status__c != oldSO.Status__c) || so.Status__c != Constants.SO_STATUS_SOLD || so.IsSalesConsultantsChange__c) && so.SubStatus__c != Constants.SUB_STATUS_POST_SALES_CANCELLATION) {
                 // if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && so.SyncTime__c == oldSO.SyncTime__c && so.SyncStatus__c == Constants.STATUS_SYNCED) {
                 so.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
                    so.IsSalesOrderChange__c = true;
                }
             
             //KP - Compliance Satus/ JO / TP  status update and populating dates.
             if(so.ComplianceStatus__c != oldSO.ComplianceStatus__c && so.ComplianceStatus__c == 'Returned' && so.ComplianceStatusReturnedDate__c == null) {
                 so.ComplianceStatusReturnedDate__c = System.Today();
             }
             if(so.ComplianceStatus__c != oldSO.ComplianceStatus__c && so.ComplianceStatus__c == 'Cleared' && so.ComplianceStatusClearedDate__c == null) {
                 so.ComplianceStatusClearedDate__c = System.Today();
             }
             if(so.JointOwnerComplianceStatus__c != oldSO.JointOwnerComplianceStatus__c && so.JointOwnerComplianceStatus__c == 'Returned' && so.JOComplianceStatusReturnedDate__c == null) {
                 so.JOComplianceStatusReturnedDate__c = System.Today();
             }
             if(so.JointOwnerComplianceStatus__c != oldSO.JointOwnerComplianceStatus__c && so.JointOwnerComplianceStatus__c == 'Cleared' && so.JOComplianceStatusClearedDate__c == null) {
                 so.JOComplianceStatusClearedDate__c = System.Today();
             }
             if(so.ThirdPartyComplianceStatus__c != oldSO.ThirdPartyComplianceStatus__c && so.ThirdPartyComplianceStatus__c == 'Returned' && so.TPComplianceStatusReturnedDate__c == null) {
                 so.TPComplianceStatusReturnedDate__c = System.Today();
             }
             if(so.ThirdPartyComplianceStatus__c != oldSO.ThirdPartyComplianceStatus__c && so.ThirdPartyComplianceStatus__c == 'Cleared' && so.TPComplianceStatusClearedDate__c == null) {
                 so.TPComplianceStatusClearedDate__c = System.Today();
             }
             /*if(so.SubStatus__c != oldSO.SubStatus__c && so.SubStatus__c==Constants.SUB_STATUS_CM_VALIDATED && so.SalesApprovedDate__c==null ){
                 so.SalesApprovedDate__c=system.Today();
             }*/
               //Added by Chirag 
             if(so.ComplianceStatus__c != null && so.ComplianceStatus__c != oldSO.ComplianceStatus__c){
                 so.ComplianceStatusModifiedBy__c = UserInfo.getUserId();
             }
             if(so.JointOwnerComplianceStatus__c != null && so.JointOwnerComplianceStatus__c != oldSO.JointOwnerComplianceStatus__c){
                 so.JointComplianceStatusModifiedBy__c = UserInfo.getUserId();
             }
             if(so.ThirdPartyComplianceStatus__c != null && so.ThirdPartyComplianceStatus__c != oldSO.ThirdPartyComplianceStatus__c){
                 so.ThirdPartyComplianceModifiedBy__c = UserInfo.getUserId();
             }
             if(so.Status__c != oldSO.Status__c && so.Status__c == Constants.SO_STATUS_SOLD){
                 salesOrderSoldStatusIds.add(so.Id);
             }
         }
         updateBrokerManager((list<SalesOrder__c>) newList);
         if(Label.checkSalesOrderSoldValidation == 'True' && !salesOrderSoldStatusIds.isEmpty()) {
             SalesOrderTriggerHelper.checkSalesOrderSoldValidation((list<SalesOrder__c>) newList, salesOrderSoldStatusIds);
         }
     }
     //*** After Insert Action***//
     public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
         SalesOrderService.newOpportunityUnitRecord(newList);
         createAccountDocuments(newList);
         
//         Set<Id> unitIdSet = new Set<Id>();
//         Set<Id> projectIdSet = new Set<Id>(); 
         
         map<id,SalesOrder__c> createDocuments = new map<id,SalesOrder__c>();
         // List<Id> soIds = new List<Id>();
         set<ID> qualtircsIDsToProcess = new set<ID>();
         Set<Id> offPlanSOAccIds = new Set<Id>();
         Set<Id> OpportunityIds = new Set<Id>();
         map<id,Opportunity> opportunityMap = new map<id,Opportunity>();
          Map<Id,SalesOrder__c> SoUnitMap = new Map<Id,SalesOrder__c>();
        Set<Id>AccountIds = new Set<Id>();
         for(SalesOrder__c newRecord : (List<SalesOrder__c>) newList)
         {
                 if (newRecord.Opportunity__c !=null)
                 {
                     OpportunityIds.add(newRecord.Opportunity__c);
                 }
             if((newRecord.Status__c =='Reservation In Progress' || newRecord.Status__c =='Pending') && newRecord.Is_Digital_Sales__c == true){
                    SoUnitMap.put(newRecord.Unit__c,newRecord);
                    AccountIds.add(newRecord.Account__c);
                }
         }
         List<Communication_Preference__c> cpList = new List<Communication_Preference__c>();
        for(Communication_Preference__c cp : [SELECT Id,Unit__c,Active__c,Status__c FROM Communication_Preference__c WHERE UNit__c=:SoUnitMap.keySet() AND Category__c ='Booking' AND Status__c ='Fasttrack Completed' AND Account__c =:AccountIds]){
            if(cp.Active__c == true){
               
                if(SoUnitMap.get(cp.Unit__c).Status__c=='Reservation In Progress'){
                	cp.Sales_Order__c =SoUnitMap.get(cp.Unit__c).Id;
                    cpList.add(cp);
                }
                
            }
        }
         for(Communication_Preference__c cp : [SELECT Id,Unit__c,Active__c,Status__c FROM Communication_Preference__c WHERE UNit__c=:SoUnitMap.keySet() AND Category__c ='Booking']){
            if(cp.Active__c == true){
                if(SoUnitMap.get(cp.Unit__c).Status__c=='Pending'){
                	cp.Active__c =false;
                    cpList.add(cp);
                }
                
            }
        }
        if(cpList.size() >0){
            update cpList;
        }
         if(!OpportunityIds.isEmpty())
         {
             List<Opportunity> OppList = [Select id,ReferralCustomer__c,isDigitalSales__c from Opportunity where Id IN:OpportunityIds];
             opportunitymap.putAll(new Map<Id, Opportunity>(opplist));
         }
         for (SalesOrder__c so: (list<SalesOrder__c>) newList) {
             // if (so.SyncStatus__c == Constants.STATUS_IN_PROGRESS) {
             //     soIds.add(so.Id);
             // }
//             unitIdSet.add(so.Unit__c);
//             projectIdSet.add(so.Project_Id__c);
             if(so.QualtricsIntegrationStatus__c==Constants.QUALTRICS_IN_PROGRESS && so.Sales_Type__c == 'New Sale' ){
                 qualtircsIDsToProcess.add(so.Id);
             }
             // *RTO* Condition 
             if( so.Status__c !=null  && (so.SubStatus__c == Constants.STATUS_APPROVED || so.Status__c == constants.OPPO_UNIT_STATUS_PENDING || so.Status__c == constants.SO_STATUS_RTO_PENDING ||  (so.SubStatus__c =='Approve Pending' && opportunitymap.get(so.Opportunity__c).isDigitalSales__c))   ){
                 //adding for Balghailam
                 // if( so.Status__c !=null  && ((so.ProjectName__c == String.valueof(System.Label.ADHAProject) && so.status__c =='Reservation In Progress') || (so.SubStatus__c == Constants.STATUS_APPROVED || so.Status__c == constants.OPPO_UNIT_STATUS_PENDING || so.Status__c == constants.SO_STATUS_RTO_PENDING))  ){ - Commented for production deployment - Muzammil
                 createDocuments.put(so.id,so);
             }
             if(so.OffPlanSalesOrder__c && so.Account__c != null){
                offPlanSOAccIds.add(so.Account__c);
             }
         }
         // User usr = Utilities.getLoggedInUserDetail();
         // if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && !soIds.isEmpty()) {
         //     SalesOrderCalloutHelper.PrepareDataForCallout(soIds, false, new Map<String, String>());
         // }
//         if(!unitIdSet.isEmpty() && !projectIdSet.isEmpty()){
           //  updateVirtualAccountToUnit(unitIdSet,projectIdSet);
//         }
         if(!createDocuments.isEmpty()){
             createSalesOrderDocuments(new map<id,SalesOrder__c>(createDocuments));
         }
         if(!qualtircsIDsToProcess.isEmpty()){
            // System.enqueueJob(new Qualtrics.QualtricsIntegration(qualtircsIDsToProcess));
         }
 
         //---- to share Sales Order record with Sales Manager.
         ShareHelper.shareSalesOrderSalesManager(newList, Constants.EDIT_ACCESS);
 
         //---- to share Sales Order record with Broker Manager.
         ShareHelper.shareSalesOrderBrokerManager(newList, Constants.READ_ACCESS);
         // Commented by Moh Sarfaraj for ASF-1468
         //---- to share Sales Order record with FAB Group for Balghailam
         //ShareHelper.shareSalesOrderFABGroup(newList, Constants.EDIT_ACCESS);
         if(!offPlanSOAccIds.isEmpty()){
            processOffPlanSOAccounts(offPlanSOAccIds);
         }
     }
 
    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        map<id,SalesOrder__c> createDocuments = new map<id,SalesOrder__c>();
        set<id> soldUnits = new set<ID>();
        set<id> soldSOIds = new set<ID>();
        
        Set<Id> soUnitIds = new set<Id>();//Digital Sales
       // set<id> soldSOIdsForIncentives = new set<ID>();
        set<ID> qualtircsIDsToProcess = new set<ID>();
        set<ID> recordToUnloack = new set<ID>();
        list<ID> handoverUnitIds=new list<ID>();

        List<Id> soIds = new List<Id>();
        List<Id> soPTIds = new List<Id>();
        Set<id> soVAid = new set<id>();
        Map<id,String> soVAMap = new Map<id,String>();
        set<id> ADHASoId = new set<id>();
        List<SalesOrder__c> soList = new List<SalesOrder__c>();
        List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
        Map<Id, Id> makeUnitsAvailableForSOIdsMap = new Map<Id, Id>();
        Map<Id, Id> salesOrderAndOfferIdMap = new Map<Id, Id>();
        
        // ASF-1453 : yenshul@Aldar
//        Set<Id> soIdsToUnAllocateReceipts = new Set<Id>();
         //List<SalesOrder__c> CMFinanceNotifysoList = new List<SalesOrder__c>();
        // Added By Moh Sarfaraj for ASF-1468
       
        Map<Id,String> mapAccountCustomerVertical=new Map<Id,String>(); // added by Rajat Jain Jira-765
       	set<Id> accountIds =new Set<Id>();
        for(SalesOrder__c newRecord : (List<SalesOrder__c>) newList)
        {
             if(newRecord.Account__c !=null) // Added by Rajat Jira 765
            {
                accountIds.add(newRecord.Account__c);
            }
            SalesOrder__c oldRecord = (SalesOrder__c) oldMap.get(newRecord.ID);
            if(newRecord.Status__c != oldRecord.Status__c && newRecord.Status__c =='Reserved' && newRecord.Is_Digital_Sales__c ==true){
                soUnitIds.add(newRecord.Unit__c);
            }
            
        }

        // added by rajat jira -765
        for(Account acc :[Select Id,CustomerVertical__c from Account where Id In :accountIds])
        {
            mapAccountCustomerVertical.put(acc.Id,acc.CustomerVertical__c);
        }

        List<Communication_Preference__c> cpList = new List<Communication_Preference__c>();
        for(Communication_Preference__c cp : [SELECT Id,Unit__c,Active__c,Status__c FROM Communication_Preference__c WHERE UNit__c=:soUnitIds AND Category__c ='Booking']){
            if(cp.Active__c == true){
                cp.Active__c=  false;
                cpList.add(cp);
            }
        }
        if(cpList.size() >0){
            update cpList;
        }
        Set<Id> setOpportunityIds = new Set<Id>();
         for(SalesOrder__c newRecord : (List<SalesOrder__c>) newList){
             SalesOrder__c oldRecord = (SalesOrder__c) oldMap.get(newRecord.ID);
             
             /*if(newRecord.CMFinanceverified__c && !oldRecord.CMFinanceverified__c){
                 CMFinanceNotifysoList.add(newRecord);
             }*/

            // Added By Moh Sarfaraj for ASF-1468
            if(String.isNotBlank(newRecord.Status__c)  && newRecord.Status__c != oldRecord.Status__c && 
               String.isNotBlank(newRecord.Opportunity__c) && newRecord.ProjectName__c.equalsIgnoreCase(Label.ADHAProject) &&
               (newRecord.Status__c.equalsIgnoreCase(Constants.SO_STATUS_CANCELLED) || newRecord.Status__c.equalsIgnoreCase(Constants.SO_STATUS_CANCELLED_BY_USER))){
                
                setOpportunityIds.add(newRecord.Opportunity__c);
            }
             
             // SSC-385: Added By Suryapratap: If SO is cancelled, Make the Units Available again, if Cancellation Reason is Name Change or Upgrade
             if(String.isNotBlank(newRecord.Status__c)  && newRecord.Status__c != oldRecord.Status__c && 
                newRecord.Status__c.equalsIgnoreCase(Constants.SO_STATUS_CANCELLED)){  
                    makeUnitsAvailableForSOIdsMap.put(newRecord.Id, newRecord.Unit__c);
                    salesOrderAndOfferIdMap.put(newRecord.Id, newRecord.Offer__c);
                }
             
             //handoverUnitIds
             if(newRecord.Status__c !=null  && newRecord.Status__c != oldRecord.Status__c 
                && (newRecord.Status__c ==Constants.SALES_STATUS || newRecord.Status__c==Constants.SO_STATUS_RTO_Approve_PENDING)){
                 handoverUnitIds.add(newRecord.Unit__c);
             }
             
             if( newRecord.Status__c !=null  && newRecord.Status__c != oldRecord.Status__c && (newRecord.Status__c == constants.OPPO_UNIT_STATUS_PENDING)  ){
                 createDocuments.put(newRecord.id,newRecord);
             }
             system.debug('new record:'+newRecord.SubStatus__c+' old record:'+oldRecord.SubStatus__c);
             if(newRecord.SubStatus__c !=null  && newRecord.SubStatus__c != oldRecord.SubStatus__c  && newRecord.SubStatus__c == constants.STATUS_APPROVED){
                system.debug('Create documents for fab:');
                createDocuments.put(newRecord.id,newRecord);
             }
             
              //Added by Adarsh            
             if(newRecord.Status__c !=null && newRecord.Status__c != oldRecord.Status__c && newRecord.Status__c == Constants.SO_STATUS_SOLD){
                 CaseUtilities caseCreator = new CaseUtilities(newRecord);
                 System.enqueueJob(caseCreator);
             }
             //Commentted by CHirag For Digital SPA DEployment
            //  //Added by Monika for SendGrid Email Template on Sold Unit            
            //  if(newRecord.Status__c !=null && newRecord.Status__c != oldRecord.Status__c && newRecord.Status__c == Constants.SO_STATUS_SOLD){
            //     List<Id> sorList = new List<Id>();
            //     sorList.add(newRecord.id);
            //     SendGridSoldUnitEmailHelper.generateWrappercontrol(sorList); 
            //  }
              
            //Uncommeting for Demo - Rohit --> Commented for production deployment - Muzammil
             if(newRecord.ADHAApprovalStatus__c !=null  && (newRecord.ADHAApprovalStatus__c != oldRecord.ADHAApprovalStatus__c  && newRecord.ADHAApprovalStatus__c == constants.STATUS_APPROVED && newRecord.SubStatus__c == Constants.SUB_STATUS_DOCS_SIGNED) || (newRecord.SubStatus__c!=oldRecord.SubStatus__c && newRecord.SubStatus__c == Constants.SUB_STATUS_DOCS_SIGNED && newRecord.ADHAApprovalStatus__c == constants.STATUS_APPROVED)){
                //createDocuments.put(newRecord.id,newRecord);
                 ADHASoId.add(newRecord.id);
             }
             if( newRecord.Status__c != oldRecord.Status__c  && newRecord.Status__c == Constants.UNIT_STATUS_SOLD ){
                 soldUnits.add(newRecord.Unit__c);
                 soldSOIds.add(newRecord.Id);
             }
             /*Added by Sanath H M */
           /*  if((newRecord.Status__c != oldRecord.Status__c || newRecord.EquityPercentage__c != oldRecord.EquityPercentage__c)  && newRecord.Status__c == Constants.UNIT_STATUS_SOLD){
                  if(!Test.isRunningTest()){ 
                     if(newRecord.EquityPercentage__c >= 20){
                         soldSOIdsForIncentives.add(newRecord.Id);
                     }
                 } else{
                    soldSOIdsForIncentives.add(newRecord.Id); 
                 }
             } */
             if(newRecord.SpecialConditionApplicable__c  != oldRecord.SpecialConditionApplicable__c  && newRecord.SpecialConditionApplicable__c  == Constants.YES ){
                 recordToUnloack.add(newRecord.id);
             }
             System.debug('before if>>>' + newRecord);
             System.debug('newRecord.DeliveryConfirmationEmailTime__c '+newRecord.DeliveryConfirmationEmailTime__c);
             //System.debug('newRecord.DeliveryConfirmationEmailTime__c.addDays(3) '+newRecord.DeliveryConfirmationEmailTime__c.addDays(3));
             if (newRecord.Status__c == Constants.UNIT_STATUS_SOLD && newRecord.CustomerAddress__c != null && newRecord.DeliveryConfirmationEmailTime__c < newRecord.DeliveryConfirmationEmailTime__c.addDays(3)) {
                 System.debug('inside if>>>' + newRecord);
                 soList.add(newRecord);
             }
             if (newRecord.OwnerId != oldRecord.OwnerId) {
                 salesOrderList.add(newRecord);
             }
             String CustomerVertical = mapAccountCustomerVertical.containsKey(newRecord.Account__c) ? mapAccountCustomerVertical.get(newRecord.Account__c):'No Value';
             
             if ( CustomerVertical !=null && !CustomerVertical.contains('Government') && (newRecord.SyncStatus__c == Constants.STATUS_IN_PROGRESS || (newRecord.IsBookingCompleted__c && !oldRecord.IsBookingCompleted__c))) {
                 soIds.add(newRecord.Id);
             }
             //adding for VA
             
             /*if (newRecord.Status__c == Constants.SO_STATUS_CANCELLED && oldRecord.Status__c != Constants.SO_STATUS_CANCELLED) {
                 soVAid.add(newRecord.Id);
             }*/
             if ((newRecord.Status__c == Constants.SO_STATUS_CANCELLED && oldRecord.Status__c != Constants.SO_STATUS_CANCELLED) || (newRecord.Status__c == Constants.SO_STATUS_CANCELLED_BY_USER && oldRecord.Status__c != Constants.SO_STATUS_CANCELLED_BY_USER)) {
                 soVAid.add(newRecord.Id);
                 if(!soVAMap.containsKey(newRecord.id)){
                     soVAMap.put(newRecord.id, 'Cancelled');
                 }
             }
             // ASF-1453 : yenshul@Aldar
             /*if(((newRecord.Status__c == Constants.SO_STATUS_CANCELLED && ( oldRecord.Status__c == Constants.OPPO_UNIT_STATUS_PENDING || oldRecord.Status__c == Constants.STATUS_APPROVAL_PENDING)) || newRecord.Status__c == Constants.SO_STATUS_RTO_CONVERTED )  && System.label.StopReceiptUnAllocation != 'Stop' ){
                 soIdsToUnAllocateReceipts.add(newRecord.Id);
             }*/
             /*if (newRecord.Account__c != null && oldRecord.Account__c != null && newRecord.Account__c!=oldRecord.Account__c && oldRecord.Unit__r.VirtualAccountNumberForSR__c==null) {
                 soVAid.add(newRecord.Id);
                 soPTIds.add(newRecord.Id);
                 if(!soVAMap.containsKey(newRecord.id)){
                     soVAMap.put(newRecord.id, 'Transferred');
                 }
             }*/
             if(newRecord.QualtricsIntegrationStatus__c==Constants.QUALTRICS_IN_PROGRESS && newRecord.Sales_Type__c == 'New Sale' ){
                 qualtircsIDsToProcess.add(newRecord.Id);

             }
         }
         /*if(!CMFinanceNotifysoList.isEmpty()){
             //sendNotificationWhenCMFinanceisChecked(CMFinanceNotifysoList);
         }*/
         if(!createDocuments.isEmpty()){
             createSalesOrderDocuments(new map<id,SalesOrder__c>(createDocuments));
         }
         if(!soldUnits.isEmpty()){
             updateUnitStatus(soldUnits,Constants.UNIT_STATUS_SOLD);
             //Update commission Lines
             validateAndUpdateCommisions(soldSOIds);
             
         }
        /* if(!soldSOIdsForIncentives.isEmpty()){
             createStaffIncentiveCommissions(soldSOIdsForIncentives);
         } */
         if (!soList.isEmpty()) {
             createShipmentRecords(soList);
         }
         // ASF-1453 : yenshul@Aldar
        /* if(!soIdsToUnAllocateReceipts.isEmpty()){
             unAllocateReceiptsBySOIds(soIdsToUnAllocateReceipts);
         }*/
 
         //Uncommenting for Demo -Rohit --> Commented for production deployment - Muzammil
         if(!ADHASoId.isEmpty()){
             updateSOReserved(ADHASOId);
         }
         //adding for VA
         /*if (!soVAid.isEmpty()) {
             VirtualAccountService.updateUnitVA(soVAid);
         }*/
         if (!soVAid.isEmpty() && !soVAMap.isEmpty()) {
             //VirtualAccountService.updateUnitVA(soVAid);
             VirtualAccountService.updateUnitVA(soVAMap);
         }
 
         // for (SalesOrder__c so: (list<SalesOrder__c>) newList) {
         //     SalesOrder__c oldRecord = (SalesOrder__c) oldMap.get(so.Id);
         //     if (so.SyncStatus__c == Constants.STATUS_IN_PROGRESS || (so.IsBookingCompleted__c && !oldRecord.IsBookingCompleted__c)) {
         //         soIds.add(so.Id);
         //     }
         //     if(so.QualtricsIntegrationStatus__c==Constants.QUALTRICS_IN_PROGRESS){
         //         qualtircsIDsToProcess.add(so.Id);
         //     }
         // }
         system.debug('is batch :'+system.isBatch());
         User usr = Utilities.getLoggedInUserDetail();
         if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && !soIds.isEmpty()) {
             SalesOrderCalloutHelper.PrepareDataForCallout(soIds, false, new Map<String, String>());
         }
         if (!soPTIds.isEmpty() && usr.Profile.Name == Constants.INTEGRATION_PROFILE){
             SalesOrderCalloutHelper.PrepareDataForCallout(soPTIds, false, new Map<String, String>());
         }
         if(!qualtircsIDsToProcess.isEmpty()){
             system.debug('------TRiggering---- ' );

            // System.enqueueJob(new Qualtrics.QualtricsIntegration(qualtircsIDsToProcess));
         }
         if(!recordToUnloack.isEmpty()){
             system.debug('----'+recordToUnloack);
             UtilitiesWithoutSharing.unlockRecords(recordToUnloack);
         }
 
         if (!salesOrderList.isEmpty()) {
             //---- to share Sales Order record with Sales Manager.
             ShareHelper.shareSalesOrderSalesManager(newList, Constants.EDIT_ACCESS);
 
             //---- to share Sales Order record with Broker Manager.
             ShareHelper.shareSalesOrderBrokerManager(newList, Constants.READ_ACCESS);
 
             //---- to share Sales Order record with FAB Group for Balghailam - Commented for production deployment - Muzammil
             //ShareHelper.shareSalesOrderFABGroup(newList, Constants.EDIT_ACCESS);
         }
        // Commneted By Moh Sarfaraj for ASF-1468
        //  List<SalesOrder__c> sowithoplist = new List<SalesOrder__c>();
        //  sowithoplist = [Select id, ProjectName__c, Opportunity__c, Opportunity__r.RMVerified__c, Opportunity__r.FABPrincipalApproved__c, Opportunity__r.Top_Up_Bank__c from salesorder__c where id in :newMap.keyset() and (Opportunity__r.RMVerified__c=true or Opportunity__r.FABPrincipalApproved__c=true)];
        //  System.debug('For fab sharing :' +sowithoplist);
        //  if(!sowithoplist.isEmpty()){
        //     ShareHelper.shareSalesOrderFABGroup(sowithoplist, Constants.EDIT_ACCESS);
        //  }
        // Added By Moh Sarfaraj for ASF-1468
        if(!setOpportunityIds.isEmpty()){
            updateOpportunityCancelSaleOrder(setOpportunityIds);
        }
        
        
        if(!handoverUnitIds.isEmpty()){
            HandoverUtility.createHandoverSRUpdateSO(new list<ID>(handoverUnitIds));
        }
        KYCValidityController.updateKYCvalidity(newList, oldMap);
        populateJointOwnerOwnerId(newList, oldMap); // ASF-3568 Changes
        
        // SSC-385: Added Byt Suryapratap : Check if the SO Cancel have Name Change or Upgrage Reason, then Update the Unit to Available in
        if(!makeUnitsAvailableForSOIdsMap.isEmpty()) {
            SalesOrderTriggerHelper.checkSalesOrderCancellationReason(makeUnitsAvailableForSOIdsMap, salesOrderAndOfferIdMap, newMap);
        }
        if(soldSOIds.size() > 0 ){
            DocumentTriggerHandler.createSPAServiceRequest(soldSOIds);
        }
    }
 
     //update commissions to Ready for Submission
     public static void validateAndUpdateCommisions(set<id> soIds){
         map<id,InstallmentLines__c> installmentLineMap = new map<id,InstallmentLines__c>();
 
         for(InstallmentLines__c installmentLine : [select id,InvoicedAmount__c,InstallmentAmount__c,Account_Resident_Status__c from InstallmentLines__c where SalesOrder__c in :soIds and BrokerPayoutPercentage__c!=null]){
             //if( installmentLine.InvoicedAmount__c!=null && installmentLine.InstallmentAmount__c!=null && (installmentLine.InvoicedAmount__c >= installmentLine.InstallmentAmount__c || (installmentLine.InstallmentAmount__c - installmentLine.InvoicedAmount__c) < Integer.valueOf(System.Label.CommissionAmountBuffer) ) ){
             if( installmentLine.InvoicedAmount__c!=null && installmentLine.InstallmentAmount__c!=null && (installmentLine.InvoicedAmount__c >= installmentLine.InstallmentAmount__c || ((installmentLine.Account_Resident_Status__c =='Resident' && (installmentLine.InstallmentAmount__c - installmentLine.InvoicedAmount__c) < Integer.valueOf(System.Label.CommissionAmountBuffer)) || (installmentLine.Account_Resident_Status__c =='Non-Resident' && (installmentLine.InstallmentAmount__c - installmentLine.InvoicedAmount__c) < Integer.valueOf(System.Label.CommissionIntAmountBuffer))) ) ){
                 installmentLineMap.put(installmentLine.Id,installmentLine);
             }
         }
         if(!installmentLineMap.isEmpty()){
             InstallmentLinesTriggerHandler.createCommissionLineDocuments(installmentLineMap);
         }   
     }
     
     public static void updateUnitStatus(set<id> unitIds, String statusValue){
         list<Unit__c> unitsToUpdate = new list<Unit__c>();
         for(Id unitID : unitIds){
             unitsToUpdate.add(new Unit__c(id= unitID, Status__c = statusValue));
         }
         if(!unitsToUpdate.isEmpty()){ update unitsToUpdate; }
     }
     
     public static void updateSOReserved(set<id> salesorderids){
         List<SalesOrder__c> sotoreserved = new List<salesorder__c>();
         for(id soid : salesorderids){
             sotoreserved.add(new Salesorder__c(id=soid, Status__c = Constants.STATUS_RESERVED));
         }
         if(!sotoreserved.isEmpty()){ update sotoreserved;}
     }
 
     public static void createAccountDocuments(list<SalesOrder__c> salesOrders){
         List<Document__c> documentListToInsert = new List<Document__c>();
         map<string,ID> documentRecordTypeMap = new map<string,ID>();
         map<string,list<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{Constants.DOCUMENT_PLACEHOLDER_CATEGORY_PERSON_ACCOUNT,Constants.DOCUMENT_PLACEHOLDER_CATEGORY_ORGANIZATION});
         map<Id,account> accountIDToRecMap = new map<Id,account>();
 
         for(SalesOrder__c salesOrderRec : salesOrders){
             if(salesOrderRec.Account__c!=null){
                 accountIDToRecMap.put(salesOrderRec.Account__c,null);
             }
         }
         accountIDToRecMap = new map<Id,account>([SELECT Id, Name,RecordType.Name, Sync_with_SFMC__c, Sync_with_SFMC__pc, CustomerVertical__c, RecordTypeId from Account WHERE ID IN:accountIDToRecMap.keyset()]);
         if(!documentMap.isEmpty() && !accountIDToRecMap.isEmpty()){
             //get Existing Documents
             map<string,Document__c> existingDocMap = new map<string,Document__c>();
             for(Document__c tempDoc : [select id,DocumentType__c,Account__c from Document__c where Account__c in :accountIDToRecMap.keySet()]){
                     existingDocMap.put(tempDoc.Account__c+tempDoc.DocumentType__c,tempDoc);
             }
 
             for(SalesOrder__c salesOrderRec : salesOrders){
                 if(salesOrderRec.Account__c!=null){
                     string documentTypeToProcess; 
                     if( accountIDToRecMap.get(salesOrderRec.Account__c).RecordType.Name ==Constants.PERSON_ACCOUNT_RT ){
                         documentTypeToProcess = Constants.DOCUMENT_PLACEHOLDER_CATEGORY_PERSON_ACCOUNT;
                     }else if(accountIDToRecMap.get(salesOrderRec.Account__c).RecordType.Name ==Constants.ORGANISATION_ACCOUNT_RT){
                         documentTypeToProcess = Constants.DOCUMENT_PLACEHOLDER_CATEGORY_ORGANIZATION;
                     }
                     //if(documentMap.containsKey(documentTypeToProcess)){
                         for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(documentTypeToProcess)){
                             string recordTypeID=null;
                         
                             if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                                 if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                                     documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                                 }
                                 recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                             }
                             
                             if(!existingDocMap.containsKey(salesOrderRec.Account__c + tempMetaRec.DocumentType__c)){
                                 Document__c documentRecord = DocumentService.createDocumentRecord('','','',tempMetaRec.DocumentType__c,'',salesOrderRec.Account__c,recordTypeID);
                                 documentRecord.EligibleForeSign__c=tempMetaRec.EligibleForeSign__c;
                                 documentRecord.SendForESign__c= tempMetaRec.eSignRequired__c;
                                 documentRecord.DocumentPlaceHolderId__c=tempMetaRec.DeveloperName;
                                 //                              Digital Signature Start
                              //   documentRecord.Identityverification__c = tempMetaRec.Identityverification__c;
                                 //                              Digital Signature End
                                 /*new Document__c(Account__c = salesOrderRec.Account__c,
                                                                             DocumentType__c = tempMetaRec.DocumentType__c,
                                                                             RecordtypeId= recordTypeID);*/
                                 //documentRecord.GenerateDocument__c = (tempMetaRec.GeneratedManually__c != true);
                                 documentListToInsert.add(documentRecord);
                                 existingDocMap.put(salesOrderRec.Account__c + tempMetaRec.DocumentType__c,documentRecord);               
                             }
                         }
                     }
                // }
             }
         }
         
         if(!documentListToInsert.isEmpty()){ insert documentListToInsert; }
         //Sync with SFMC SSP-414 Rijwan || Commented for unit assignment deployemnt
         /*List<Account> updateAccount = new List<Account>();
         for(Account acc : accountIDToRecMap.values()) {
            if(!acc.Sync_with_SFMC__c && (acc.CustomerVertical__c == NULL || !acc.CustomerVertical__c.contains('LSQ'))) {
                Account act = new Account();
                act.Sync_with_SFMC__c = true;
                act.Id = acc.Id;

                if(acc.RecordTypeId == Constants.PERSON_RECORD_TYPE_ID) {
                    act.Sync_with_SFMC__c = true;
                }

                updateAccount.add(act);
            }
         }

         if(!updateAccount.isEmpty()) {
            update updateAccount;
         }*/
     }
 
     public static void createSalesOrderDocuments(map<id,SalesOrder__c> salesOrderMap){
         List<Document__c> documentListToInsert = new List<Document__c>();
         map<string,ID> documentRecordTypeMap = new map<string,ID>();
         
          // *RTO* Record Type and map added
         Id rtoRecordType = Schema.SObjectType.SalesOrder__c.getRecordTypeInfosByName().get('RTO').getRecordTypeId();
 			Set<Id> oppIds = new Set<Id>();
         /*// ASF-3647: Get related opportunity account details to check for Wealth Introducer broker agencies
         Set<Id> oppIds = new Set<Id>();
         for(SalesOrder__c so : salesOrderMap.values()) {
             if(so.Opportunity__c != null) {
                 oppIds.add(so.Opportunity__c); 
             }
         }
 
         // ASF-3647: Query opportunity and related account details
         Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
         if(!oppIds.isEmpty()){
             oppMap = new Map<Id, Opportunity>([SELECT Id, Account.RecordType.Name, Account.AgencyCategory__c 
                                                                FROM Opportunity 
                                                                WHERE Id IN :oppIds]);
         }*/
         
         map<string,list<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{Constants.DOCUMENT_PLACEHOLDER_CATEGORY_RESERVATION,Constants.DOCUMENT_PLACEHOLDER_CATEGORY_BOOKING,Constants.DOCUMENT_PLACEHOLDER_CATEGORY_RTO});
         if(!documentMap.isEmpty()){
             //get Existing Documents
             map<string,Document__c> existingDocMap = new map<string,Document__c>();
             for(Document__c tempDoc : [select id,DocumentType__c,SalesOrder__c from Document__c where SalesOrder__c in :salesOrderMap.keySet()]){
                     existingDocMap.put(tempDoc.SalesOrder__c+tempDoc.DocumentType__c,tempDoc);
             }
             map<id,Account> relatedAccountRecords = new map<id,Account>();
             for(SalesOrder__c newSalesOrder : salesOrderMap.values()){
                 relatedAccountRecords.put(newSalesOrder.Account__c,null);
             }
             relatedAccountRecords = new map<id,Account>([select id,RecordTypeId,AgencyCategory__c from account where id in :relatedAccountRecords.keySet()]);
             for(SalesOrder__c newSalesOrder : salesOrderMap.values()){
                  string documentCategory;
                 // *RTO* Condition added
                 if(newSalesOrder.RecordtypeId != rtoRecordType){
                     documentCategory = newSalesOrder.Status__c == Constants.OPPO_UNIT_STATUS_PENDING ? Constants.DOCUMENT_PLACEHOLDER_CATEGORY_BOOKING : Constants.DOCUMENT_PLACEHOLDER_CATEGORY_RESERVATION;
                 }else{
                     documentCategory = Constants.DOCUMENT_PLACEHOLDER_CATEGORY_RTO;
                 }
 
                 /*Account relatedAccount = relatedAccountRecords.get(newSalesOrder.Account__c);

                 if(relatedAccount != null && relatedAccount.AgencyCategory__c != null && relatedAccount.recordTypeID == constants.BROKER_AGENCY_RECORD_TYPE_ID && documentCategory == Constants.DOCUMENT_PLACEHOLDER_CATEGORY_BROKER_AGENCY){
                     continue;
                 }*/
 
                 for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(documentCategory)){
                    // Added by Moh Sarfaraj on 18 July 23 
                   /* Set<String> setExemptProjects = new Set<String>();
                    if(String.isNotBlank(tempMetaRec.Exempt_From_Project__c)){
                        setExemptProjects = new Set<String>(tempMetaRec.Exempt_From_Project__c.split(','));
                    } */
                    
                    //Skip if project setting doesn't match
                     if(tempMetaRec.ProjectName__c!=null && !tempMetaRec.ProjectName__c.equalsIgnoreCase(newSalesOrder.ProjectName__c)){
                         continue;
                     }
                     //skip wealth form for the Organization record types
                     if( (tempMetaRec.DocumentType__c.equalsIgnoreCase(Constants.DOCUMENT_TYPE_WEALTH) || tempMetaRec.DocumentType__c.equalsIgnoreCase(Constants.DOCUMENT_TYPE_SIGNED_WEALTH)) && relatedAccountRecords.containsKey(newSalesOrder.Account__c) && relatedAccountRecords.get(newSalesOrder.Account__c).RecordTypeId ==Constants.ORGANIZATION_RECORD_TYPE_ID){
                         continue;
                     }
                    
                     /*// ASF-3647: Skip brokerage form for Wealth Introducer broker agencies
                     if(tempMetaRec.DocumentType__c.equalsIgnoreCase(Constants.DOCUMENT_TYPE_BROKERAGE_FORM) && 
                        newSalesOrder.Opportunity__c != null && 
                        oppMap.containsKey(newSalesOrder.Opportunity__c) &&
                        oppMap.get(newSalesOrder.Opportunity__c).Account.RecordType.Name == Constants.BROKER_AGENCY_ACCOUNT_RT &&
                        oppMap.get(newSalesOrder.Opportunity__c).Account.AgencyCategory__c == Constants.ACCOUNT_AGENCY_CATEGORY_WEALTH_INTRODUCER) {
                         continue;    
                     }*/
                     
                     string recordTypeID=null;
                     if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                         if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                             documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                         }
                         recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                     }
                     
                     if(!existingDocMap.containsKey( newSalesOrder.Id + tempMetaRec.DocumentType__c)){
                         Document__c documentRecord = DocumentService.createDocumentRecord(newSalesOrder.Opportunity__c,'','',tempMetaRec.DocumentType__c,newSalesOrder.Id,'',recordTypeID);
                        // updated by Moh Sarfaraj on 20 July 23
                     /*   System.debug('setExemptProjects--->'+setExemptProjects); 
                        System.debug('newSalesOrder.ProjectName__c--->'+newSalesOrder.ProjectName__c); 
                        documentRecord.SendForESign__c = setExemptProjects.contains(newSalesOrder.ProjectName__c) ? false : tempMetaRec.eSignRequired__c;
                        
                        System.debug('newSdocumentRecord.SendForESign__c-->'+documentRecord.SendForESign__c); */
                         documentRecord.DocumentPlaceHolderId__c=tempMetaRec.DeveloperName;
                         documentRecord.DocumentPlaceHolderId__c=tempMetaRec.DeveloperName;
                         documentRecord.Identityverification__c =tempMetaRec.Identityverification__c;
                         /*new Document__c(Opportunity__c = newSalesOrder.Opportunity__c,
                                                                     //Unit__c=newSalesOrder.Unit__c,
                                                                     DocumentType__c = tempMetaRec.DocumentType__c,
                                                                     SalesOrder__c = newSalesOrder.Id,
                                                                     RecordtypeId= recordTypeID);*/
                         //documentRecord.GenerateDocument__c = (tempMetaRec.GeneratedManually__c != true);
                         documentListToInsert.add(documentRecord);        
                     }
                 }
             }
         }
         
         if(!documentListToInsert.isEmpty()){ insert documentListToInsert; } 
     }
 
     public static void createShipmentRecords(List<SalesOrder__c> soList){
         List<ShipmentRequest__c> srList = new List<ShipmentRequest__c>();
         for (SalesOrder__c so: soList) {
             ShipmentRequest__c sr = new ShipmentRequest__c();
             sr.SalesOrder__c = so.Id;
             sr.Account__c = so.Account__c;
             srList.add(sr);
         }
         insert srList;
     }
     
   /*  public static void sendNotificationWhenCMFinanceisChecked(List<SalesOrder__c> soList){
         list<CustomNotificationType> notificationTypes = [SELECT Id, DeveloperName FROM CustomNotificationType where DeveloperName='NotifywhenCMFinanceisChecked']; 
         
         for(SalesOrder__c so: soList){
             if(so.CMFinanceverified__c){
                 if(!notificationTypes.isEmpty()){
                     Messaging.CustomNotification notification = new Messaging.CustomNotification();
                     notification.setTitle('CM Finance is Verified');
                     notification.setBody(so.Name +' is verified by CM Finance' );
                     notification.setNotificationTypeId(notificationTypes[0].Id);
                     notification.setTargetId(so.Id);
                     notification.send(new set<string> { so.CMUser__c } );
                 }
             }
         }
     } */
     
    public static void updateBrokerManager(List<SalesOrder__c> newList) {
        Set<Id> oppotunityIdSet = new Set<Id>();
        
        for(SalesOrder__c so: newList) {
            if(so.BrokerManager__c == null && so.Opportunity__c != null){
                oppotunityIdSet.add(so.Opportunity__c);
            }
        }        
        if(!oppotunityIdSet.isEmpty()){		//Added empty check by Jyoti Lankapati - SOQL 101 Error (Suggested by Rijwan)
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT
                                                                Id,
                                                                BrokerAgencyAccount__c,
                                                                BrokerAgencyAccount__r.Name,
                                                                BrokerManager__c
                                                                FROM Opportunity
                                                                WHERE Id In:oppotunityIdSet ]);
            if(!oppMap.values().isEmpty()){
                for(SalesOrder__c so: newList){
                    if(so.BrokerManager__c == null && so.Opportunity__c != null && oppMap.containsKey(so.Opportunity__c)){
                        if(oppMap.get(so.Opportunity__c).BrokerAgencyAccount__c != null && oppMap.get(so.Opportunity__c).BrokerAgencyAccount__r.Name != null){
                            so.BrokerManager__c = oppMap.get(so.Opportunity__c).BrokerManager__c;
                        }
                    }  
                }
            }            
        }        
    }
    
    Public static void updateInventoryLaunch(List<SalesOrder__c> newList){
        Set<Id> unitIdSet = new Set<Id>();
        for(SalesOrder__c so: newList){
            unitIdSet.add(so.Unit__c);
        }
        system.debug('+++unitIdSet '+unitIdSet);
        
        Map<Id, Unit__c> unitMap = new Map<Id, Unit__c>([SELECT Id,
                                                         BuildingSectionName__c,
                                                         BuildingSectionName__r.LaunchStartDate__c,
                                                         BuildingSectionName__r.LaunchEndDate__c,
                                                         BuildingSectionName__r.DefaultUnitFinishing__c
                                                         FROM Unit__c
                                                         WHERE Id in:unitIdSet
                                                         AND BuildingSectionName__c != null]);
        system.debug('+++unitMap '+unitMap);
        
        for(SalesOrder__c so: newList){
            if(so.Unit__c != null && unitMap.containsKey(so.Unit__c) ){
                /*if(unitMap.get(so.Unit__c).BuildingSectionName__r.LaunchStartDate__c != null &&
                   unitMap.get(so.Unit__c).BuildingSectionName__r.LaunchEndDate__c  != null &&
                   unitMap.get(so.Unit__c).BuildingSectionName__r.LaunchStartDate__c <= Date.today() &&
                   unitMap.get(so.Unit__c).BuildingSectionName__r.LaunchEndDate__c >= Date.today()  ){
                       so.InventoryLaunch__c = 'Launch';
                   }*/
                if(unitMap.get(so.Unit__c).BuildingSectionName__r.DefaultUnitFinishing__c != null){
                    so.UnitFinishing__c = unitMap.get(so.Unit__c).BuildingSectionName__r.DefaultUnitFinishing__c;
                }
            }  
        }
    }
    /*Added by Sanath H M */
  /*  public static void createStaffIncentiveCommissions(set<id> soIds){
        List<CommissionLineItem__c> commissionLineItemList = new List<CommissionLineItem__c>();
        List<SalesOrder__c> salesOrderList = [SELECT
                                              Id,
                                              Opportunity__c,
                                              Opportunity__r.EmployeeId__c,
                                              Opportunity__r.EmployeeEmail__c,
                                              NetAmount__c,
                                              Unit__c,
                                              Unit__r.Project__c,
                                              (SELECT Id from CommissionLineItems__r WHERE CommissionType__c = 'Staff Incentive')
                                              FROM SalesOrder__c
                                              WHERE Id in:soIds
                                              AND Opportunity__r.EmployeeId__c != null
                                              AND Opportunity__r.EmployeeEmail__c != null];
        for(SalesOrder__c so: salesOrderList){
            if(so.CommissionLineItems__r.size() == 0){
            CommissionLineItem__c commissionLineItem = new CommissionLineItem__c();
            Decimal incentiveAmount = 0;
            if(so.NetAmount__c >= 1000000 ){
                incentiveAmount = 2500;
            }else{
                incentiveAmount = 5000;
               
            }
            commissionLineItem.CommissionType__c = 'Staff Incentive';
            commissionLineItem.SalesOrder__c = so.Id;
            commissionLineItem.EmployeeEmail__c = so.Opportunity__r.EmployeeEmail__c;
            commissionLineItem.EmployeeId__c = so.Opportunity__r.EmployeeId__c;
            commissionLineItem.CommissionPercentage__c = 0;
            commissionLineItem.CommissionAmount__c = incentiveAmount;
            commissionLineItem.TotalPayableCommission__c = incentiveAmount;
            commissionLineItem.Unit__c = so.Unit__c;
            commissionLineItem.Project__c = so.Unit__r.Project__c;
            commissionLineItemList.add(commissionLineItem);
            }
        }
        
        if(!commissionLineItemList.isEmpty()){
            insert commissionLineItemList;
        }
    } */
    // Added By Moh Sarfaraj for ASF-1468
    @testVisible private static void updateOpportunityCancelSaleOrder(Set<Id> setOpportunities){
        List<Opportunity> listOpportunitiesToUpdate = new List<Opportunity>();
        for(Id key : setOpportunities){
            listOpportunitiesToUpdate.add(new Opportunity(Id = key, RMVerified__c = false, FABIslamicApproved__c = false, FABPrincipalApproved__c = false));
        }
        if(!listOpportunitiesToUpdate.isEmpty()){
            update listOpportunitiesToUpdate;
        }
    }
    
    
   /* public static void updateVirtualAccountToUnit(Set<Id> unitIdSet, Set<Id> projectIdSet){
        List<BankVirtualAccounts__c> bvaListToUpdate = new List<BankVirtualAccounts__c> ();
        List<Unit__c> unitList = [SELECT
                                  Id,
                                  Project__c,
                                  (SELECT Id FROM Bank_Virtual_Accounts__r)
                                  FROM Unit__c
                                  WHERE Id IN: unitIdSet]; 
        
        List<BankVirtualAccounts__c> bankVirtualAccounts = [SELECT
                                                            Id,
                                                            Unit__c,
                                                            BufferFlag__c,
                                                            Project__c
                                                            FROM BankVirtualAccounts__c
                                                            WHERE Project__c IN: projectIdSet
                                                            AND Unit__c = null
                                                            AND BufferFlag__c = true
                                                            AND Statusflag__c = 'Available'];
        for(Integer i = 0; i < unitList.size(); i++ ){
            if(unitList[i].Bank_Virtual_Accounts__r.size() == 0 && bankVirtualAccounts.size() >= unitList.size()){
                
                BankVirtualAccounts__c bva = new BankVirtualAccounts__c();
                bva.Id = bankVirtualAccounts[i].Id;
                bva.Unit__c = unitList[i].Id;
                bva.BufferFlag__c = false;
                bvaListToUpdate.add(bva);
            }    
        }
        
        if(!bvaListToUpdate.isEmpty()){
          update bvaListToUpdate;
        }
    } */
    public static void processOffPlanSOAccounts(Set<Id> offPlanSOAccIds) {
        List<Account> offPlanSOAccsToUpdate = new List<Account>();
        if(offPlanSOAccIds != null && !offPlanSOAccIds.isEmpty()){
            for(Account acc: [SELECT Id, HasOffPlanSalesOrder__c FROM Account WHERE Id IN: offPlanSOAccIds AND HasOffPlanSalesOrder__c = false]){
                acc.HasOffPlanSalesOrder__c = true;
                offPlanSOAccsToUpdate.add(acc);
            }
            ResaleConstants.RUN_ACCOUNT_TRIGGER_RESALE_SWITCH = FALSE;
            update offPlanSOAccsToUpdate;
            ResaleConstants.RUN_ACCOUNT_TRIGGER_RESALE_SWITCH = TRUE;
        }
    }
    
    //ASF-3568 Changes Start here
    Public void populateJointOwnerOwnerId(List<SObject> newList,Map<Id,Sobject> oldMap){
        List<JointOwner__c> lstToUpdate = new List<JointOwner__c>();
        Map<Id,Id> salesOrderOwnerMap = new Map<Id,Id>();
        for(SalesOrder__c so:(List<SalesOrder__c>) newList){
            SalesOrder__c oldRecord = (SalesOrder__c) oldMap.get(so.ID);
            if(so.SalesManager__c  != oldRecord.SalesManager__c){
                salesOrderOwnerMap.put(so.Id,so.SalesManager__c);
            }
        }
        if(!salesOrderOwnerMap.isEmpty()){
            for(JointOwner__c jo:[SELECT Id,OwnerId,SalesOrder__c FROM JointOwner__c WHERE SalesOrder__c IN:salesOrderOwnerMap.keyset()]){
                jo.OwnerId = salesOrderOwnerMap.get(jo.SalesOrder__c);
                lstToUpdate.add(jo);
            }
            if(!lstToUpdate.isEmpty()){
                Update lstToUpdate;
            }
        }
    }
    //ASF-3568 Changes End here
    
    // ASF-1453 : yenshul@Aldar
    /*public static void unAllocateReceiptsBySOIds(Set<Id> soIds) {
        List<ReceiptAllocation__c> allocationsToUpdate = new List<ReceiptAllocation__c>();
        for(ReceiptAllocation__c ra : [ SELECT Id, AmountApplied__c 
                                        FROM ReceiptAllocation__c
                                        WHERE ReceiptAcknowledgement__r.SalesOrder__c IN: soIds
                                            AND AmountApplied__c > 0] ){
            ra.AmountApplied__c = 0;
            allocationsToUpdate.add(ra);
        }
        update allocationsToUpdate;
     }*/
}