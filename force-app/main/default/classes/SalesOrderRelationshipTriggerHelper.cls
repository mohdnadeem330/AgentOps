Public class SalesOrderRelationshipTriggerHelper {
    //ASF-3319
    public static void validateDuplicatesForThridParty(List<Sales_Order_Relationship__c> newList){
        Set<Id> salesOrderIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Id thirdPartyRecordTypeId = Schema.SObjectType.Sales_Order_Relationship__c.getRecordTypeInfosByName().get('Third Party').getRecordTypeId();
        String existThirdPartyOnSalesOrder = System.label.Third_Party_Relationship_On_Sales_Order;
        for(Sales_Order_Relationship__c sor: newList){
            if(sor.SalesOrder__c != null && sor.Account__c != null && sor.RecordTypeId == thirdPartyRecordTypeId){
                salesOrderIds.add(sor.SalesOrder__c);
                accountIds.add(sor.Account__c);
            }
        }
        Map<Id, SalesOrder__c> salesOrderMap = new Map<Id, SalesOrder__c>();
        for (SalesOrder__c so : [SELECT Id, Account__c FROM SalesOrder__c WHERE Id IN :salesOrderIds]) {
            salesOrderMap.put(so.Id, so);
        }
        Set<String> salesOrderAccountStr = new  Set<String>();
        for(Sales_Order_Relationship__c sor: [Select Id,SalesOrder__c,Account__c,SalesOrder__r.Account__c from Sales_Order_Relationship__c where SalesOrder__c in: salesOrderIds And Account__c in: accountIds  AND RecordTypeId = :thirdPartyRecordTypeId] ){ //RecordType.Name = 'Third Party'
            salesOrderAccountStr.add(sor.SalesOrder__c+'-'+sor.Account__c);
        }
        for(Sales_Order_Relationship__c sor: newList){
            if(sor.SalesOrder__c != null && sor.RecordTypeId == thirdPartyRecordTypeId){
                sor.Customer_Account__c = salesOrderMap.get(sor.SalesOrder__c).Account__c;
            }
            // Throw validation if sales order relationship account is same as that of sales order account
            if (sor.RecordTypeId == thirdPartyRecordTypeId && 
                sor.Account__c == salesOrderMap.get(sor.SalesOrder__c).Account__c) {
                    sor.addError('Third party account cannot be the same as the sales order account.');
                }
            if(salesOrderAccountStr.contains(sor.SalesOrder__c+'-'+sor.Account__c) ){
                sor.addError(ExistThirdPartyOnSalesOrder);
            }
        }
        
    }
    //ASF-3319
    public static void inserAARealtionShipRecords(List<Sales_Order_Relationship__c> newList){
        Map<String,String> salesOrderIdToSORAccountId = new  Map<String,String>();
        Map<String,SalesOrder__c> salesOrderIdToSORec = new  Map<String,SalesOrder__c>();
        Id thirdPartyRecordTypeId = Schema.SObjectType.Sales_Order_Relationship__c.getRecordTypeInfosByName().get('Third Party').getRecordTypeId();
        for(Sales_Order_Relationship__c sor: newList){
            if(sor.SalesOrder__c != null && sor.Account__c != null && sor.RecordTypeId == thirdPartyRecordTypeId){
                salesOrderIdToSORAccountId.put(sor.SalesOrder__c,sor.Account__c);
            }
        }
        Set<Id> salesOrderAccountIds = new Set<Id>();
        if(salesOrderIdToSORAccountId != null){
            for(SalesOrder__c so: [Select Id,Account__c from SalesOrder__c where Id in: salesOrderIdToSORAccountId.keyset()]){
                salesOrderAccountIds.add(so.Account__c);
                salesOrderIdToSORec.put(so.Id,so);
            }
        }
        Set<String> AccountIdRelatedIdStr = new  Set<String>();
        for(AccountRelationship__c ar: [Select Id,RelatedAccount__c,Account__c from AccountRelationship__c where Account__c in: salesOrderAccountIds]){
            AccountIdRelatedIdStr.add(ar.Account__c+'-'+ar.RelatedAccount__c);
        }
        List<AccountRelationship__c> arList = New List<AccountRelationship__c>();
        for(Sales_Order_Relationship__c sor: newList){
            if(sor.SalesOrder__c != null && sor.Account__c != null && sor.RecordTypeId == thirdPartyRecordTypeId){
                String SalesOrderAccountId = salesOrderIdToSORec.get(sor.SalesOrder__c).Account__c;
                if(!AccountIdRelatedIdStr.contains(SalesOrderAccountId+'-'+sor.Account__c)){
                    AccountRelationship__c ar = new AccountRelationship__c();
                    ar.Account__c = Id.ValueOf(SalesOrderAccountId);
                    ar.RelatedAccount__c = sor.Account__c;
                    ar.RelationshipType__c = 'Third Party'; // If given as Third Party, validation rule is firing
                    //ar.RelationshipSubType__c = 'Owner'; 
                    arList.add(ar);
                }
            }
        }
        if(!arList.isEmpty()){
            Insert arList;
        }
    }
    //ASF-3320
    public static void updateSalesOrderRecord(List<Sales_Order_Relationship__c> newList, Map<Id,Sales_Order_Relationship__c> oldMap){
        Id thirdPartyRecordTypeId = Schema.SObjectType.Sales_Order_Relationship__c.getRecordTypeInfosByName().get('Third Party').getRecordTypeId();
        Set<Id> clearedIds = new Set<Id>();
        Set<Id> rejectedIds = new Set<Id>();
        Set<Id> returnedIds = new Set<Id>();
        List<SalesOrder__c> salesOrderToUpdate = new  List<SalesOrder__c>();
        Set<Id> salesOrderIds = new  Set<Id>();
        for(Sales_Order_Relationship__c newSOR: newList){
            Sales_Order_Relationship__c oldSOR = oldMap != null ? oldMap.get(newSOR.Id) : null;
            if( oldSOR == null && newSOR.SalesOrder__c != null && newSOR.RecordTypeId == thirdPartyRecordTypeId){
                SalesOrder__c so = new SalesOrder__c();
                so.Id = newSOR.SalesOrder__c;
                so.ThirdPartyComplianceStatus__c = 'Under Review';
                so.ThirdPartyComplianceModifiedBy__c = UserInfo.getUserId();
                salesOrderToUpdate.add(so);
            }
            if( oldSOR != null && newSOR.SalesOrder__c != null && newSOR.RecordTypeId == thirdPartyRecordTypeId && newSOR.Compliance_status__c != oldSOR.Compliance_status__c && newSOR.Compliance_status__c != 'Cleared'){
                SalesOrder__c so = new SalesOrder__c();
                so.Id = newSOR.SalesOrder__c;
                so.ThirdPartyComplianceStatus__c = newSOR.Compliance_status__c;
                so.ThirdPartyComplianceModifiedBy__c = UserInfo.getUserId();
                salesOrderToUpdate.add(so);
            }
            if( oldSOR != null && newSOR.SalesOrder__c != null && newSOR.RecordTypeId == thirdPartyRecordTypeId && newSOR.Compliance_status__c != oldSOR.Compliance_status__c && newSOR.Compliance_status__c == 'Cleared'){
                salesOrderIds.add(newSOR.SalesOrder__c);
                clearedIds.add(newSOR.Id);
            }
            if( oldSOR != null && newSOR.RecordTypeId == thirdPartyRecordTypeId && newSOR.Compliance_status__c != oldSOR.Compliance_status__c && newSOR.Compliance_status__c == System.Label.SOR_Returned_Status){
                returnedIds.add(newSOR.Id);
            }
            if( oldSOR != null && newSOR.RecordTypeId == thirdPartyRecordTypeId && newSOR.Compliance_status__c != oldSOR.Compliance_status__c && newSOR.Compliance_status__c == System.Label.SOR_Rejected_Status){
                rejectedIds.add(newSOR.Id);
            }
        }
        if (!clearedIds.isEmpty()) {
            List<Case> clearedCaseList = [SELECT Id, Status, Sub_Status__c FROM Case WHERE Sales_Order_Relationship__c IN :clearedIds AND Recordtype_Name__c = :System.Label.Third_Party_Payment_NOC_Record_Type_Name];
			List<Case> clearedCasesToUpdate = new List<Case>();
            for (Case caseRecord : clearedCaseList) {
				if(caseRecord.Status != System.Label.Finance_Clearance_Status && caseRecord.Sub_Status__c == System.Label.Pending_Sub_Status){
                    caseRecord.Status = System.Label.Finance_Clearance_Status;
					clearedCasesToUpdate.add(caseRecord);
				}
            }
            if (!clearedCasesToUpdate.isEmpty()) {
                update clearedCasesToUpdate;
            }
        }
        if (!rejectedIds.isEmpty()) {
            List<Case> rejectedCaseList = [SELECT Id, Status, Sub_Status__c FROM Case WHERE Sales_Order_Relationship__c IN :rejectedIds AND Recordtype_Name__c = :System.Label.Third_Party_Payment_NOC_Record_Type_Name];
			List<Case> rejectedCasesToUpdate = new List<Case>();
            for (Case caseRecord : rejectedCaseList) {
				if(caseRecord.Sub_Status__c == System.Label.Pending_Sub_Status){
                    caseRecord.Status = System.Label.Compliance_Check_Status;
                    caseRecord.Sub_Status__c = System.Label.Rejected_Sub_Status;
				    rejectedCasesToUpdate.add(caseRecord);
				}
            }
            if (!rejectedCasesToUpdate.isEmpty()) {
                update rejectedCasesToUpdate;
            }
        }
        if (!returnedIds.isEmpty()) {
            List<Case> returnedCaseList = [SELECT Id, Status, Sub_Status__c FROM Case WHERE Sales_Order_Relationship__c IN :returnedIds AND Recordtype_Name__c = :System.Label.Third_Party_Payment_NOC_Record_Type_Name];
			List<Case> returnedCasesToUpdate = new List<Case>();
            for (Case caseRecord : returnedCaseList) {
				if(caseRecord.Sub_Status__c == System.Label.Pending_Sub_Status){
                    caseRecord.Status = System.Label.Verify_Request_Status;
				    returnedCasesToUpdate.add(caseRecord);
				}
            }
            if (!returnedCasesToUpdate.isEmpty()) {
                update returnedCasesToUpdate;
            }
        }
        if(!salesOrderIds.isEmpty()){
            Map<Id,Integer> mapSalesOrderIdtoTotalThrirdPartyCount = new Map<Id,Integer>();
            for(SalesOrder__c so: [Select Id,(Select Id,Compliance_status__c from Sales_Order_Relationship2__r where recordTypeId =: thirdPartyRecordTypeId) from SalesOrder__c where Id in: salesOrderIds]){
                mapSalesOrderIdtoTotalThrirdPartyCount.put(so.Id,so.Sales_Order_Relationship2__r.size());
            }
            for(SalesOrder__c so: [Select Id,ThirdPartyComplianceStatus__c,ThirdPartyComplianceModifiedBy__c,(Select Id,Compliance_status__c from Sales_Order_Relationship2__r where recordTypeId =: thirdPartyRecordTypeId AND Compliance_status__c = 'Cleared') from SalesOrder__c where Id in: salesOrderIds]){
                Integer ClearedThrirdPartyCount = so.Sales_Order_Relationship2__r.size();
                if(ClearedThrirdPartyCount == mapSalesOrderIdtoTotalThrirdPartyCount.get(so.Id)){
                    so.ThirdPartyComplianceStatus__c = 'Cleared';
                    so.ThirdPartyComplianceModifiedBy__c = UserInfo.getUserId();
                    salesOrderToUpdate.add(so);
                }
            }
        }
        
        if(!salesOrderToUpdate.isEmpty()){
            Update salesOrderToUpdate;
        }
    }
    
    public static void createSORDocuments(List<Sales_Order_Relationship__c> newList) {
        Id thirdPartyRecordTypeId = Schema.SObjectType.Sales_Order_Relationship__c.getRecordTypeInfosByName().get('Third Party').getRecordTypeId();
        List<Document__c> documentListToInsert = new List<Document__c>();
        Map<String, ID> documentRecordTypeMap = new Map<String, ID>();
        Map<String, List<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new Set<String>{
            'Third Party'
                });
        
        if (!documentMap.isEmpty()) {
            for (Sales_Order_Relationship__c sorRecord : newList) {
                String documentTypeToProcess;
                List<DocumentPlaceHolder__mdt> documentsToProcess = new List<DocumentPlaceHolder__mdt>();
                
                if (sorRecord.RecordTypeId == thirdPartyRecordTypeId) {
                    documentTypeToProcess = 'Third Party';
                }
                if (documentTypeToProcess != null && documentMap.containsKey(documentTypeToProcess)) {
                    documentsToProcess.addAll(documentMap.get(documentTypeToProcess));
                }
                
                for (DocumentPlaceHolder__mdt tempMetaRec : documentsToProcess) {
                    String recordTypeID = null;
                    
                    if (tempMetaRec.RecordTypeDeveloperName__c != null) {
                        if (!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)) {
                            documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c, 
                                                      Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                        }
                        recordTypeID = documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                    }
                    
                    Document__c documentRecord = New Document__c(); 
                    documentRecord.RecordtypeId= recordTypeID;
                    documentRecord.DocumentType__c = tempMetaRec.DocumentType__c;
                    documentRecord.Sales_Order_Relationship__c = sorRecord.Id;
                    documentRecord.SendForESign__c = tempMetaRec.eSignRequired__c;
                    documentRecord.DocumentPlaceHolderId__c = tempMetaRec.DeveloperName;
                    documentRecord.EligibleForeSign__c = tempMetaRec.EligibleForeSign__c;
                    // SSC-125 changes by BASHIM: Adding the delivery package and delivery option id
                    // Start
                    documentRecord.DocgenPackageId__c = tempMetaRec.DocgenPackageName__c;
                    documentRecord.DeliveryOptionId__c = tempMetaRec.DeliveryOption__c;
                    // SSC-125 changes by BASHIM: End
                    
                    documentListToInsert.add(documentRecord);      
                }
            }
        }
        
        if (!documentListToInsert.isEmpty()) {
            insert documentListToInsert;  
        } 
    }
    
    //ASF-3481 chnges start here 
    public static void validateAccountDocuemnts(List<Sobject> newList,String objName){
        Map<Id,Boolean> nonResidentMap = new Map<Id,Boolean>();
        Map<Id,Boolean> residentMap = new Map<Id,Boolean>();
        Map<Id,List<Document__c>> nonResidentAccounts = new Map<Id,List<Document__c>>();
        Map<Id,List<Document__c>> residentAccounts = new Map<Id,List<Document__c>>();
        Set<Id> accIds = new Set<Id>();
        Set<Id> residentAccIds = new Set<Id>();
        Set<Id> nonResidentAccIds = new Set<Id>();
        if(objName == 'Sales_Order_Relationship__c'){
            for(Sales_Order_Relationship__c sr: (list<Sales_Order_Relationship__c>) newList){
                accIds.add(sr.Account__c);
            }
        }else if(objName == 'JointOwner__c'){
            for(JointOwner__c sr:(list<JointOwner__c>) newList){
                accIds.add(sr.Account__c);
            }
        }
        
        for(Account acc:[SELECT Id,ResidentStatus__pc FROM Account WHERE ID IN: accIds]){
            if(acc.ResidentStatus__pc == 'Resident'){
                residentAccIds.add(acc.Id);
            }else if(acc.ResidentStatus__pc == 'Non-Resident'){
                nonResidentAccIds.add(acc.Id);
            }
        }
        if(!accIds.isEmpty()){
            system.debug('docuemnt data:'+[SELECT Id,Account__c,Account__r.ResidentStatus__pc,DocumentType__c,(SELECT Id from Contentdocumentlinks) from Document__c WHERE Account__c IN:accIds AND Status__c = 'Uploaded'  AND Account__r.ResidentStatus__pc IN ('Resident','Non-Resident') AND DocumentType__c IN('Passport Copy','Signed KYC Form','National ID Back Copy','National ID Front Copy')]);
            for(Document__c doc:[SELECT Id,Account__c,Account__r.ResidentStatus__pc,DocumentType__c,(SELECT Id from Contentdocumentlinks) from Document__c WHERE Account__c IN:accIds AND Status__c = 'Uploaded'  AND Account__r.ResidentStatus__pc IN ('Resident','Non-Resident') AND DocumentType__c IN('Passport Copy','Signed KYC Form','National ID Back Copy','National ID Front Copy')]){
                if(doc.Account__r.ResidentStatus__pc == 'Resident' &&  !doc.Contentdocumentlinks.isEmpty()){
                    if(residentAccounts.containskey(doc.Account__c)){
                        List<Document__c> docs = residentAccounts.get(doc.Account__c);
                        docs.add(doc);
                        residentAccounts.put(doc.Account__c,docs);
                    }else{
                        residentAccounts.put(doc.Account__c,new List<Document__c>{doc});
                    }
                }
                if(doc.Account__r.ResidentStatus__pc == 'Non-Resident' && (doc.DocumentType__c == 'Passport Copy' || doc.DocumentType__c == 'Signed KYC Form') && !doc.Contentdocumentlinks.isEmpty()){
                    if(nonResidentAccounts.containskey(doc.Account__c)){
                        List<Document__c> docs = nonResidentAccounts.get(doc.Account__c);
                        docs.add(doc);
                        nonResidentAccounts.put(doc.Account__c,docs);
                    }else{
                        nonResidentAccounts.put(doc.Account__c,new List<Document__c>{doc});
                    }
                }
            }
        }
        if(!nonResidentAccounts.isEmpty()){
            for(Id accId:nonResidentAccounts.keySet()){
                Boolean passportCheck = false;
                Boolean kycCheck = false;
                for(Document__c doc:nonResidentAccounts.get(accId)){
                    if(doc.DocumentType__c == 'Passport Copy'){
                        passportCheck = true;
                    }
                    if(doc.DocumentType__c == 'Signed KYC Form'){
                        kycCheck = true;
                    }
                }
                if(passportCheck == true && kycCheck == true){
                    nonResidentMap.put(accId,True);
                }
            }
        }
        if(!residentAccounts.isEmpty()){
            for(Id accId:residentAccounts.keySet()){
                Boolean passportCheck = false;
                Boolean kycCheck = false;
                Boolean nationalIdBack = false;
                Boolean nationalIdFront = false;
                for(Document__c doc:residentAccounts.get(accId)){
                    if(doc.DocumentType__c == 'Passport Copy'){
                        passportCheck = true;
                    }
                    if(doc.DocumentType__c == 'Signed KYC Form'){
                        kycCheck = true;
                    }
                    if(doc.DocumentType__c == 'National ID Back Copy'){
                        nationalIdBack = true;
                    }
                    if(doc.DocumentType__c == 'National ID Front Copy'){
                        nationalIdFront = true;
                    }
                }
                if(passportCheck == true && kycCheck == true && nationalIdBack == true && nationalIdFront == true){
                    residentMap.put(accId,True);
                }
            }
        }
        if(objName == 'Sales_Order_Relationship__c'){
            for(Sales_Order_Relationship__c sr:(list<Sales_Order_Relationship__c>) newList){
                if(nonResidentAccIds.contains(sr.Account__c) && ( (nonResidentMap.containskey(sr.Account__c) && nonResidentMap.get(sr.Account__c) == false) || !nonResidentMap.containskey(sr.Account__c) )){
                    sr.addError('For Non Resident Accounts Passport copy and Singned KYC form should be completed');
                }
                if(residentAccIds.contains(sr.Account__c) && ( (residentMap.containskey(sr.Account__c) && residentMap.get(sr.Account__c) == false) || !residentMap.containskey(sr.Account__c) ) ){
                    sr.addError('For Resident Accounts National Id,Passport copy,Singned Kyc form should be uploaded');
                }
            }
        }else if(objName == 'JointOwner__c'){
            for(JointOwner__c sr:(list<JointOwner__c>) newList){
                if(nonResidentAccIds.contains(sr.Account__c) && ( (nonResidentMap.containskey(sr.Account__c) && nonResidentMap.get(sr.Account__c) == false) || !nonResidentMap.containskey(sr.Account__c) )){
                    sr.addError('For Non Resident Accounts Passport copy and Singned KYC form should be completed');
                }
                if(residentAccIds.contains(sr.Account__c) && ( (residentMap.containskey(sr.Account__c) && residentMap.get(sr.Account__c) == false) || !residentMap.containskey(sr.Account__c) ) ){
                    sr.addError('For Resident Accounts National Id,Passport copy,Singned Kyc form should be uploaded');
                }
            }
        }
    }
    //ASF-3481 changes end here 
    //ASF-3480 changes start here 
    public static void preventDeleteOfReceipt(List<Sales_Order_Relationship__c> oldLst){
        Set<Id> accIds = new Set<Id>();
        Set<Id> salesOrderIds = new Set<Id>();
        Map<Id,Id> salesOrderAccountMap = new Map<Id,Id>();
        for(Sales_Order_Relationship__c sr:oldLst){
            salesOrderIds.add(sr.SalesOrder__c);
            accIds.add(sr.Account__c);
        }
        if(!salesOrderIds.isEmpty()){
            for(ReceiptAcknowledgement__c ra:[SELECT Id,SalesOrder__c,RecievedFromAccount__c FROM ReceiptAcknowledgement__c WHERE SalesOrder__c IN:salesOrderIds AND RecievedFromAccount__c IN :accIds]){
                salesOrderAccountMap.put(ra.SalesOrder__c,ra.RecievedFromAccount__c);
            }
        }
        system.debug('salesOrderAccountMap:'+salesOrderAccountMap);
        if(!salesOrderAccountMap.isEmpty()){
            for(Sales_Order_Relationship__c sr:oldLst){
                system.debug('salesOrderAccountMap.get(sr.SalesOrder__c):'+salesOrderAccountMap.get(sr.SalesOrder__c));
                system.debug('sr.Account__c:'+sr.Account__c);
                if(salesOrderAccountMap.containskey(sr.SalesOrder__c) && salesOrderAccountMap.get(sr.SalesOrder__c) == sr.Account__c){
                    sr.addError('This Sales Order Relationship can not delete');
                }
            }
        }
    }
    //ASF-3480 changes start here
}