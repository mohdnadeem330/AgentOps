public without sharing class JointOwnerTriggerHandler extends TriggerHandler{
    
    public override void beforeInsertMethod(list<SObject> newList,Map<Id, SObject> newMap){
        createJointOwnerDocuments(newList);  
        Map<String, Decimal> salesOrderSharePercentageMap = sharePercentageForaSalesOrder(newList);
        Set<Id> salesOrderIdSet = new Set<Id>();
        List<SalesOrder__c> updateSalesOrderList = new List<SalesOrder__c>();
        List<Id> soIds = new List<Id>();
        List<JointOwner__c> jointOwnerOpportunityList = new List<JointOwner__c>();
        for (JointOwner__c jo: (list<JointOwner__c>) newList) {
            if(jo.SalesOrder__c == null && jo.Opportunity__c != null){
                jointOwnerOpportunityList.add(jo);
                continue;
            }
            if (jo.SalesOrderStatus__c != Constants.SALES_STATUS_CANCELLED && jo.SalesOrderStatus__c != Constants.SO_STATUS_SOLD) {
                jo.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
            }
            jo.UniqueKey__c = jo.SalesOrder__c + '_' + jo.Account__c;
            if (jo.SharePercentage__c != null) {
                Decimal sharePercentage = salesOrderSharePercentageMap.containsKey(jo.SalesOrder__c) ? salesOrderSharePercentageMap.get(jo.SalesOrder__c) + (jo.SharePercentage__c) : jo.SharePercentage__c;
                if (sharePercentage > 99) {
                    jo.addError('Total Joint Owner Share Percentage cannot exceed 99%');
                } else {
                    if (salesOrderIdSet.contains(jo.SalesOrder__c)) {
                        continue;
                    }
                    SalesOrder__c updateSalesOrder = new SalesOrder__c();
                    updateSalesOrder.Id = jo.SalesOrder__c;
                    updateSalesOrder.OwnerSharePercentage__c = 100 - sharePercentage;
                    updateSalesOrderList.add(updateSalesOrder);
                    salesOrderIdSet.add(jo.SalesOrder__c);
                }
            }
            soIds.add(jo.SalesOrder__c);
        }
        if (!updateSalesOrderList.isEmpty()) {
            update updateSalesOrderList;
        }
        if(!soIds.isEmpty()) {
            UpdateSOWithJointOwnerDetailsFuture(soIds);
        }
        if(jointOwnerOpportunityList.size() > 0){
            ResaleUnitService.manageOpportunityJointOwners(jointOwnerOpportunityList);
        }
        // SalesOrderRelationshipTriggerHelper.validateAccountDocuemnts(newList,'JointOwner__c'); //ASF-3481 changes
        populateJointOwnerOwnerId(newList); // ASF-3568 Changes
    }
    
    
    
    //*** Before Update Action***//
    public override void beforeUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        Map<String, Decimal> salesOrderSharePercentageMap = sharePercentageForaSalesOrder(newList);
        Set<Id> salesOrderIdSet = new Set<Id>();
        List<SalesOrder__c> updateSalesOrderList = new List<SalesOrder__c>();
        User usr = Utilities.getLoggedInUserDetail();
        Map<Id, Decimal> jointOwnerNewPercentageMap = new Map<Id, Decimal>();
        Map<Id, Decimal> jointOwnerOldPercentageMap = new Map<Id, Decimal>();
        List<Id> soIds = new List<Id>();
        //added by Dharnesh for nintex docgen issue start
        List<Id> accountIds = new List<Id>();
        List<Id> salesOrderIds = new List<Id>();
        List<Account> accList = new List<Account>();
		List<SalesOrder__c> soList = new List<SalesOrder__c>();

        for (JointOwner__c jo : (list<JointOwner__c>)newList) {
            if (jo.Account__c != null) {
                accountIds.add(jo.Account__c);
            }
            if (jo.SalesOrder__c != null) {
                salesOrderIds.add(jo.SalesOrder__c);
            }
        }
        if (!accountIds.isEmpty()) {
        accList = [SELECT Id, Name, NameInArabic__c,
                                 Nationality__pc, NationalityinArabic__pc, PassportNumber__pc                        
                                 FROM Account WHERE Id IN :accountIds];
        }
        if (!salesOrderIds.isEmpty()) {
        soList = [SELECT Id, JointOwnerNames__c, JointOwnerNamesinArabic__c, JointOwnerNationalities__c,
                                      JointOwnerNationalitiesinArabic__c,JointOwnerPassportNumbers__c
                                      FROM SalesOrder__c WHERE Id IN :salesOrderIds];
        }
        Map<Id, Account> accData = new Map<Id, Account>(accList);
        Map<Id, SalesOrder__c> soData = new Map<Id, SalesOrder__c>(soList);
        //added by Dharnesh for nintex docgen issue end
        
        for (JointOwner__c jo: (list<JointOwner__c>) newList) {
            JointOwner__c oldJO = (JointOwner__c)oldmap.get(jo.Id);
            if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && jo.SyncTime__c == oldJO.SyncTime__c && jo.SyncStatus__c == Constants.STATUS_SYNCED && jo.SalesOrderStatus__c != Constants.SALES_STATUS_CANCELLED && jo.SalesOrderStatus__c != Constants.SO_STATUS_SOLD) {
                jo.SyncStatus__c = Constants.STATUS_IN_PROGRESS;
            }
            if (jo.Account__c != oldJo.Account__c) {
                jo.UniqueKey__c = jo.SalesOrder__c + '_' + jo.Account__c;
                soIds.add(jo.SalesOrder__c);
            } else if (jo.SharePercentage__c != oldJo.SharePercentage__c) {
                soIds.add(jo.SalesOrder__c);
            }
            //added by Dharnesh for nintex docgen issue Start
            else{
                
                SalesOrder__c salesOrder = soData.get(jo.SalesOrder__c);
                Account account = accData.get(jo.Account__c);
                
                Boolean namesMismatch = !safeStringContains(salesOrder.JointOwnerNames__c, account.Name);
                Boolean arabicNamesMismatch = !safeStringContains(salesOrder.JointOwnerNamesinArabic__c, account.NameInArabic__c);
                Boolean nationalitiesMismatch = !safeStringContains(salesOrder.JointOwnerNationalities__c, account.Nationality__pc);
                Boolean arabicNationalitiesMismatch = !safeStringContains(salesOrder.JointOwnerNationalitiesinArabic__c, account.NationalityinArabic__pc);
                Boolean passportsMismatch = !safeStringContains(salesOrder.JointOwnerPassportNumbers__c, account.PassportNumber__pc);
                
                if (namesMismatch || arabicNamesMismatch || nationalitiesMismatch || 
                    arabicNationalitiesMismatch || passportsMismatch) {
                                              
                        soIds.add(jo.SalesOrder__c);
                    }
                //added by Dharnesh for nintex docgen issue End
                
            } 
            
            if (jo.SharePercentage__c != null && salesOrderSharePercentageMap.containsKey(jo.SalesOrder__c)) {
                // Decimal sharePercentage = salesOrderSharePercentageMap.get(jo.SalesOrder__c) + (jo.SharePercentage__c - (oldJO.SharePercentage__c != null ? oldJO.SharePercentage__c : 0));
                if (jointOwnerNewPercentageMap.containsKey(jo.SalesOrder__c)) {
                    if (!jo.IsDeleted__c) {
                        jointOwnerNewPercentageMap.put(jo.SalesOrder__c, jointOwnerNewPercentageMap.get(jo.SalesOrder__c) + jo.SharePercentage__c);
                    }
                    if(oldJO.SharePercentage__c!= null){
                        jointOwnerOldPercentageMap.put(jo.SalesOrder__c, jointOwnerOldPercentageMap.get(jo.SalesOrder__c) + oldJO.SharePercentage__c);
                    }
                } else {
                    jointOwnerNewPercentageMap.put(jo.SalesOrder__c, (!jo.IsDeleted__c ? jo.SharePercentage__c : 0));
                    if(oldJO.SharePercentage__c!= null){
                        jointOwnerOldPercentageMap.put(jo.SalesOrder__c, oldJO.SharePercentage__c);
                    }
                }
                // if (sharePercentage > 99) {
                //     jo.addError('Total Joint Owner Share Percentage cannot exceed 99%');
                // } else {
                //     if (salesOrderIdSet.contains(jo.SalesOrder__c)) {
                //         continue;
                //     }
                //     SalesOrder__c updateSalesOrder = new SalesOrder__c();
                //     updateSalesOrder.Id = jo.SalesOrder__c;
                //     updateSalesOrder.OwnerSharePercentage__c = 100 - sharePercentage;
                //     updateSalesOrderList.add(updateSalesOrder);
                //     salesOrderIdSet.add(jo.SalesOrder__c);
                // }
            }
        }
        for(String key: jointOwnerNewPercentageMap.keySet()){
            Decimal sharePercentage = (salesOrderSharePercentageMap.containsKey(key) ? salesOrderSharePercentageMap.get(key) : 0) + (jointOwnerNewPercentageMap.containsKey(key) ? jointOwnerNewPercentageMap.get(key) : 0) - (jointOwnerOldPercentageMap.containsKey(key) ? jointOwnerOldPercentageMap.get(key) : 0);
            if (sharePercentage > 99) {
                System.debug('Line 74');
                newList[0].addError('Total Share Percentage cannot exceed 99%');
            } else {
                SalesOrder__c updateSalesOrder = new SalesOrder__c();
                updateSalesOrder.Id = key;
                updateSalesOrder.OwnerSharePercentage__c = 100 - sharePercentage;
                updateSalesOrderList.add(updateSalesOrder);
            }
        }
        if (!updateSalesOrderList.isEmpty()) {
            update updateSalesOrderList;
        }
        if(!soIds.isEmpty()) {
            UpdateSOWithJointOwnerDetailsFuture(soIds);
        }
    }
    
    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        
        List<Id> joIds = new List<Id>();
        for (JointOwner__c jo: (list<JointOwner__c>) newList) {
            if (jo.SyncStatus__c == Constants.STATUS_IN_PROGRESS) {
                joIds.add(jo.Id);
            }
        }
        User usr = Utilities.getLoggedInUserDetail();
        if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && !joIds.isEmpty()) {
            JointOwnerCalloutHelper.PrepareDataForCallout(joIds, false, new Map<String, String>());
        }
        updateSalesOrderRecord(newList,null); //ASF-3320
    }
    
    //*** After Update Action***//
    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        
        List<Id> joIds = new List<Id>();
        Set<Id> deleteIds = new Set<Id>();
        
        //added by dharanesh
        List<Id> delByApproval = new List<Id>();
        List<Id> approvalCheckIds = new List<Id>();
        List<Id> ids = new List<Id>();
        //added by dharanesh
        
        for (JointOwner__c jo: (list<JointOwner__c>) newList) {
            if ((jo.SyncStatus__c == Constants.STATUS_IN_PROGRESS || jo.IsDeleted__c)& jo.DeleteJointOwner__c == false){
                joIds.add(jo.Id);
            }
            system.debug('jo.DeleteJointOwner__c--'+jo.DeleteJointOwner__c);
            if(jo.DeleteJointOwner__c == true){
                deleteIds.add(jo.Id);
                //added by dharanesh to check this update is through aproval process
                if(jo.SharePercentage__c==0){
                    approvalCheckIds.add(jo.Id); 
                }
                //added by dharanesh to check this update is through aproval process
            }
            
            
        }
        
        
        User usr = Utilities.getLoggedInUserDetail();
        if (usr.Profile.Name != Constants.INTEGRATION_PROFILE && !joIds.isEmpty()) {
            JointOwnerCalloutHelper.PrepareDataForCallout(joIds, false, new Map<String, String>());
        }
        
        //added by dharnesh for new jointownerlogic
        
        if (!approvalCheckIds.isEmpty()){
            
            for(ProcessInstance pi : [
                SELECT Id, Status, TargetObjectId, ProcessDefinition.Name
                FROM ProcessInstance 
                WHERE TargetObjectId In: approvalCheckIds
                AND ProcessDefinition.Name = 'JointOwnerDeleteApproval'
                AND Status = 'Approved']) {
                    delByApproval.add(pi.TargetObjectId);
                }
            
        }
        
        if(usr.Profile.Name != Constants.INTEGRATION_PROFILE && !delByApproval.isEmpty()){
            JointOwnerCalloutHelper.PrepareDataForCallout(delByApproval, false, new Map<String, String>());
            
        }
        
        updateSalesOrderRecord(newList,trigger.oldmap); //ASF-3320
        system.debug('!System.isBatch()--'+!System.isBatch());
        //added delbyapproval variable check by dharanesh
        if(!deleteIds.isEmpty() && !System.isBatch() && delByApproval.isEmpty()){
            deleteJointOwner(deleteIds);
        }
        //SalesOrderRelationshipTriggerHelper.createTask(newList,oldMap,'JointOwner__c'); //ASF-3560 changes
    }
    
    public static Map<String, Decimal> sharePercentageForaSalesOrder(list<JointOwner__c> jointOwnerList) {
        Set<String> soIds = new Set<String>();
        // Map<Id, Decimal> jointOwnerPercentageMap = new Map<Id, Decimal>();
        for (JointOwner__c jointOwner: jointOwnerList) {
            soIds.add(jointOwner.SalesOrder__c);
            // jointOwnerPercentageMap.put(jointOwner.Id, jointOwner.SharePercentage__c);
        }
        Map<String, Decimal> salesOrderSharePercentageMap = new Map<String, Decimal>();
        List<SalesOrder__c> salesOrderSharePercentageList = [SELECT Id, OwnerSharePercentage__c, (SELECT Id, SharePercentage__c FROM Joint_OwnersSalesOrder__r WHERE IsDeleted__c = false) FROM SalesOrder__c WHERE Id IN :soIds];
        for (SalesOrder__c salesOrder: salesOrderSharePercentageList) {
            // Decimal sharePercentage = salesOrder.OwnerSharePercentage__c != null ? salesOrder.OwnerSharePercentage__c : 0;
            Decimal sharePercentage = 0;
            if (!salesOrder.Joint_OwnersSalesOrder__r.isEmpty()) {
                for (JointOwner__c jointOwner: salesOrder.Joint_OwnersSalesOrder__r) {
                    // sharePercentage += jointOwnerPercentageMap.containsKey(jointOwner.Id) ? jointOwnerPercentageMap.get(jointOwner.Id) : jointOwner.SharePercentage__c != null ? jointOwner.SharePercentage__c : 0;
                    sharePercentage += jointOwner.SharePercentage__c != null ? jointOwner.SharePercentage__c : 0;
                }
                salesOrderSharePercentageMap.put(salesOrder.Id, sharePercentage);
            }
        }
        return salesOrderSharePercentageMap;
    }
    
    public static void createJointOwnerDocuments(list<JointOwner__c> jointOwnerDocuments){
        List<Document__c> documentListToInsert = new List<Document__c>();
        map<string,ID> documentRecordTypeMap = new map<string,ID>();
        map<string,list<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{Constants.DOCUMENT_PLACEHOLDER_CATEGORY_JOINT_OWNER});
        set<Id> accountIDs = new set<Id>();
        
        for(JointOwner__c newJointOwner : jointOwnerDocuments){
            accountIDs.add(newJointOwner.Account__c);
        }
        if(!documentMap.isEmpty()){
            //get Existing Documents
            map<string,Document__c> existingDocMap = new map<string,Document__c>();
            if(!accountIDs.isEmpty())
            {
                for(Document__c tempDoc : [select id,DocumentType__c,Account__c from Document__c where Account__c in :accountIDs]){
                    existingDocMap.put(tempDoc.Account__c+tempDoc.DocumentType__c,tempDoc);
                }}
            
            for(JointOwner__c newJointOwner : jointOwnerDocuments){
                for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(Constants.DOCUMENT_PLACEHOLDER_CATEGORY_JOINT_OWNER)){
                    string recordTypeID=null;
                    if(tempMetaRec.RecordTypeDeveloperName__c!=null ){
                        if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID= documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                    
                    if(!existingDocMap.containsKey(newJointOwner.Account__c + tempMetaRec.DocumentType__c)){
                        Document__c documentRecord = DocumentService.createDocumentRecord('','','',tempMetaRec.DocumentType__c,'',newJointOwner.Account__c,recordTypeID);
                        /*new Document__c(Account__c = newJointOwner.Account__c,
DocumentType__c = tempMetaRec.DocumentType__c,
SalesOrder__c = newJointOwner.Id,
RecordtypeId= recordTypeID);*/
                        //documentRecord.GenerateDocument__c = (tempMetaRec.GeneratedManually__c != true);
                        documentListToInsert.add(documentRecord);        
                    }
                }
            }
        }
        
        if(!documentListToInsert.isEmpty()){
            insert documentListToInsert;  
        } 
    }
    
    @future
    public static void UpdateSOWithJointOwnerDetailsFuture(List<Id> soIds) {
        List<SalesOrder__c> soList = SalesOrderService.queryAllFieldsWithExtraFields(soIds);
        
        Map<Id, List<JointOwner__c>> joMap = new Map<Id, List<JointOwner__c>>();
        for (SalesOrder__c serviceRequest: soList) {
            for (JointOwner__c jointOwner: serviceRequest.Joint_OwnersSalesOrder__r) {
                if(jointOwner.IsDeleted__c) {
                    continue;
                }
                if (!joMap.isEmpty() && joMap.containsKey(jointOwner.SalesOrder__c)) {
                    List<JointOwner__c> joList = joMap.get(jointOwner.SalesOrder__c);
                    joList.add(jointOwner);
                    joMap.put(jointOwner.SalesOrder__c, joList);
                } else {
                    joMap.put(jointOwner.SalesOrder__c, new List<JointOwner__c>{jointOwner});
                }
            }
        }
        Set<Id> soIdSet = new Set<Id>();
        soIdSet.addAll(soIds);
        List<SalesOrder__c> updateSOs = new List<SalesOrder__c>();
        for (Id soId: soIdSet) {
            String jointOwnerNames = '';
            String jointOwnerNamesinArabic = '';
            String jointOwnerNationalities = '';
            String jointOwnerNationalitiesinArabic = '';
            String jointOwnerPassportNumbers = '';
            String jointOwnerSharePercentages = '';
            if (joMap.containsKey(soId)) {
                for (JointOwner__c jointOwner: joMap.get(soId)) {
                    jointOwnerNames += jointOwner.Account__c != null && jointOwner.Account__r.Name != null ? ' and ' + jointOwner.Account__r.Name : '';
                    jointOwnerNamesinArabic += jointOwner.Account__c != null && jointOwner.Account__r.NameInArabic__c != null ? ' و ' + jointOwner.Account__r.NameInArabic__c : '';
                    jointOwnerNationalities += jointOwner.Account__c != null && jointOwner.Account__r.Nationality__pc != null ? ' / ' + jointOwner.Account__r.Nationality__pc : '';
                    jointOwnerNationalitiesinArabic += jointOwner.Account__c != null && jointOwner.Account__r.NationalityinArabic__pc != null ? ' / ' + jointOwner.Account__r.NationalityinArabic__pc : '';
                    jointOwnerPassportNumbers += jointOwner.Account__c != null && jointOwner.Account__r.PassportNumber__pc != null ? ' / ' + jointOwner.Account__r.PassportNumber__pc : '';
                    jointOwnerSharePercentages += jointOwner.SharePercentage__c != null ? ' , ' + jointOwner.SharePercentage__c + '%' : '';
                }
            }
            
            SalesOrder__c so = new SalesOrder__c();
            so.Id = soId;
            so.JointOwnerNames__c = jointOwnerNames;
            so.JointOwnerNamesinArabic__c = jointOwnerNamesinArabic;
            so.JointOwnerNationalities__c = jointOwnerNationalities;
            so.JointOwnerNationalitiesinArabic__c = jointOwnerNationalitiesinArabic;
            so.JointOwnerPassportNumbers__c = jointOwnerPassportNumbers;
            so.JointOwnerSharePercentages__c = jointOwnerSharePercentages;
            updateSOs.add(so);
        }
        if (!updateSOs.isEmpty()) {
            update updateSOs;
        }
    }
    
    //ASF-3320
    public static void updateSalesOrderRecord(List<JointOwner__c> newList, Map<Id,Sobject> oldMap){
        //List<SalesOrder__c> salesOrderToUpdate = new  List<SalesOrder__c>();
        Map<Id,SalesOrder__c> salesOrderToUpdateMap = new  Map<Id,SalesOrder__c>();
        Set<Id> salesOrderIds = new  Set<Id>();
        for(JointOwner__c newJO: newList){ 
            JointOwner__c oldJO = oldMap != null ? (JointOwner__c)oldmap.get(newJO.Id) : null;
            if( oldJO == null && newJO.SalesOrder__c != null ){
                SalesOrder__c so = new SalesOrder__c();
                so.Id = newJO.SalesOrder__c;
                so.JointOwnerComplianceStatus__c = 'Under Review';
                so.JointComplianceStatusModifiedBy__c = UserInfo.getUserId();
                salesOrderToUpdateMap.put(so.Id,so);
                //salesOrderToUpdate.add(so);
            }
            if( oldJO != null && newJO.SalesOrder__c != null && newJO.Compliance_status__c != oldJO.Compliance_status__c && newJO.Compliance_status__c != 'Cleared'){
                SalesOrder__c so = new SalesOrder__c();
                so.Id = newJO.SalesOrder__c;
                so.JointOwnerComplianceStatus__c = newJO.Compliance_status__c;
                so.JointComplianceStatusModifiedBy__c = UserInfo.getUserId();
                salesOrderToUpdateMap.put(so.Id,so);
                //salesOrderToUpdate.add(so);
            }
            if( oldJO != null && newJO.SalesOrder__c != null && newJO.Compliance_status__c != oldJO.Compliance_status__c && newJO.Compliance_status__c == 'Cleared'){
                salesOrderIds.add(newJO.SalesOrder__c);
            } 
        }
        if(!salesOrderIds.isEmpty()){
            Map<Id,Integer> mapSalesOrderIdtoTotalJOCount = new Map<Id,Integer>();
            for(SalesOrder__c so: [Select Id,(Select Id,Compliance_status__c from Joint_OwnersSalesOrder__r) from SalesOrder__c where Id in: salesOrderIds]){
                mapSalesOrderIdtoTotalJOCount.put(so.Id,so.Joint_OwnersSalesOrder__r.size());
            }
            //ASF-3596 - Added JOComplianceStatusClearedDate__c field to track when compliance status is cleared
            for(SalesOrder__c so: [Select Id,JointOwnerComplianceStatus__c,JointComplianceStatusModifiedBy__c,JOComplianceStatusClearedDate__c,(Select Id,Compliance_status__c from Joint_OwnersSalesOrder__r where Compliance_status__c = 'Cleared') from SalesOrder__c where Id in: salesOrderIds]){
                Integer ClearedThrirdPartyCount = so.Joint_OwnersSalesOrder__r.size();
                if(ClearedThrirdPartyCount == mapSalesOrderIdtoTotalJOCount.get(so.Id)){
                    so.JointOwnerComplianceStatus__c = 'Cleared';
                    so.JointComplianceStatusModifiedBy__c = UserInfo.getUserId();
                    so.JOComplianceStatusClearedDate__c = system.today(); 
                    salesOrderToUpdateMap.put(so.Id,so);
                    // salesOrderToUpdate.add(so);
                }
            }
        }
        if(!salesOrderToUpdateMap.values().isEmpty()){
            Update salesOrderToUpdateMap.values();
        }
        /*if(!salesOrderToUpdate.isEmpty()){
Update salesOrderToUpdate;
}*/
    }
    // ASF-3568 Related Changes start here
    public void populateJointOwnerOwnerId(List<JointOwner__c> newList){
        Set<Id> soIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Map<Id,Id> ownerMap = new Map<Id,Id>();
        Map<Id,Id> ownerOppMap = new Map<Id,Id>();
        
        for(JointOwner__c jo:newList){
            soIds.add(jo.SalesOrder__c);
            oppIds.add(jo.Opportunity__c);
        }
        if(!soIds.isEmpty() || oppIds.size() >0){
            for(SalesOrder__c so:[SELECT Id,OwnerId from SalesOrder__c WHERE ID IN:soIds]){
                ownerMap.put(so.Id,so.OwnerId);
            }
            for(Opportunity opp: [SELECT Id,OwnerId FROM Opportunity WHERE Id in:oppIds]){
                ownerOppMap.put(opp.Id,opp.OwnerId);
            }
            
            for(JointOwner__c jo:newList){
                if(ownerMap.get(jo.SalesOrder__c) != null){
                    jo.OwnerId = ownerMap.get(jo.SalesOrder__c);
                } 
                if(ownerMap.get(jo.SalesOrder__c) == null && ownerOppMap.get(jo.Opportunity__c) != null){
                    jo.OwnerId = ownerOppMap.get(jo.Opportunity__c);
                }
            }
        }
    }
    // ASF-3568 Related Changes start here
    
    @future
    public static void deleteJointOwner(Set<Id> jointOwnerIds){
        if(!jointOwnerIds.isEmpty()){
            List<JointOwner__c> lstToDelete = new List<JointOwner__c>();
            lstToDelete = [SELECT Id from JointOwner__c WHERE Id IN: jointOwnerIds];
            if(!lstToDelete.isEmpty()){
                Delete lstToDelete;
            }
        }
    }
    
    //added by Dharnesh for nintex docgen issue
    private Boolean safeStringContains(String sourceString, String searchString) {
        if (String.isBlank(sourceString) || String.isBlank(searchString)) {
            return false;
        }
        return sourceString.contains(searchString);
    }
    
}