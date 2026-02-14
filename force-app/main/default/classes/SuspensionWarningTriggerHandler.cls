/*
****************************************************************************************
Apex Class Name    : SuspensionWarningTriggerHandler
Created Date       : 01-08-2024
@description       : This is class is used for Suspension/Warning
@author            : Moh Sarfaraj
Modification Log:
Ver   Date              Author                               Modification
1.0   01-08-2024      Moh Sarfaraj                          Initial Version
*****************************************************************************************
*/
public class SuspensionWarningTriggerHandler extends TriggerHandler{

    public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        for(Suspensions_Warning__c sw : (List<Suspensions_Warning__c>)newList){

        }
        autoSelectCategoryBasedOnSubCategory((List<Suspensions_Warning__c>)newList);
    }

    public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        Map<Id,Id> mapSuspensionIdToAgencyId = new Map<Id,Id>();
        Map<Id,Id> mapSuspensionIdToAgentId = new Map<Id,Id>();
        
        for(Suspensions_Warning__c sw : (List<Suspensions_Warning__c>)newList){
            Suspensions_Warning__c oldSuspenWarn = (Suspensions_Warning__c) oldMap.get(sw.Id);

            if(sw.SuspensionApprovalStatus__c != oldSuspenWarn.SuspensionApprovalStatus__c && sw.SuspensionApprovalStatus__c =='Suspension Approved' && sw.SuspensionWarning__c == 'Warning'){
                if(sw.Suspension_Warning_Days__c != null && sw.Suspension_Warning_Days__c != 0){
                    sw.SuspensionEndDate__c = System.today() + Integer.valueOf(sw.Suspension_Warning_Days__c);
                }else{
                    sw.SuspensionEndDate__c = System.today() + 7;
                }
            }
            if(String.isNotBlank(sw.BrokerAgency__c) && sw.SuspensionApprovalStatus__c != oldSuspenWarn.SuspensionApprovalStatus__c && sw.SuspensionApprovalStatus__c =='Suspension Approved' && sw.SuspensionWarning__c == 'Suspension'){
                // sw.SuspensionEndDate__c = system.today()+30;
                mapSuspensionIdToAgencyId.put(sw.Id, sw.BrokerAgency__c);
            }

            if(String.isNotBlank(sw.Broker_Agent__c) && sw.SuspensionApprovalStatus__c != oldSuspenWarn.SuspensionApprovalStatus__c && sw.SuspensionApprovalStatus__c =='Suspension Approved' && sw.SuspensionWarning__c == 'Suspension'){
                // sw.SuspensionEndDate__c = system.today()+30;
                mapSuspensionIdToAgentId.put(sw.Id, sw.Broker_Agent__c);
            }
        }
        if(!mapSuspensionIdToAgencyId.isEmpty() || !mapSuspensionIdToAgentId.isEmpty()){
            suspensionExtensions(mapSuspensionIdToAgencyId, mapSuspensionIdToAgentId, (List<Suspensions_Warning__c>)newList);
        }
        autoSelectCategoryBasedOnSubCategory((List<Suspensions_Warning__c>)newList);
    }

    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        Map<Id,Suspensions_Warning__c> mapSuspensionWarningsForDocuments = new Map<Id,Suspensions_Warning__c>();
        for(Suspensions_Warning__c eachSuspWarn : (List<Suspensions_Warning__c>)newList){
            // Added By Moh Sarfaraj for BPM-536
            if(eachSuspWarn?.SuspensionWarning__c?.equalsIgnoreCase('Suspension') || eachSuspWarn?.SuspensionWarning__c?.equalsIgnoreCase('Warning')){
                mapSuspensionWarningsForDocuments.put(eachSuspWarn.Id, eachSuspWarn);
            }
        }
        // Added By Moh Sarfaraj for BPM-536
        if(!mapSuspensionWarningsForDocuments.isEmpty()){
            createSuspensionWarningDocuments(mapSuspensionWarningsForDocuments);
        }
    }
    
    public override void afterUpdateMethod(List<SObject> newList, Map<Id,SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        Map<Id,Suspensions_Warning__c> suspenWarnFilteredMap = new Map<Id,Suspensions_Warning__c>();
        Map<Id,Suspensions_Warning__c> mapSuspensionWarningsForDocuments = new Map<Id,Suspensions_Warning__c>();
        
        for(Suspensions_Warning__c sw : (List<Suspensions_Warning__c>)newList){
            Suspensions_Warning__c oldSuspenWarn = (Suspensions_Warning__c) oldMap.get(sw.Id);

            // Added by Moh Sarfaraj for BPM-391
            if((String.isNotBlank(sw.BrokerAgency__c) ||  String.isNotBlank(sw.Broker_Agent__c)) && sw.SuspensionApprovalStatus__c != oldSuspenWarn.SuspensionApprovalStatus__c && 
                (sw.SuspensionApprovalStatus__c == 'Suspension Approved' || 
                sw.SuspensionApprovalStatus__c == 'Suspension Removal Approved')){
                 
                suspenWarnFilteredMap.put(sw.Id, sw);
            }
            // Added By Moh Sarfaraj for BPM-536
            if(sw.SuspensionApprovalStatus__c != oldSuspenWarn.SuspensionApprovalStatus__c && sw.SuspensionApprovalStatus__c == 'Suspension Approved' && 
               (sw?.SuspensionWarning__c?.equalsIgnoreCase('Suspension') || sw?.SuspensionWarning__c?.equalsIgnoreCase('Warning'))){
                mapSuspensionWarningsForDocuments.put(sw.Id, sw);
            }
        }
        // Added by Moh Sarfaraj for BPM-391
        if(!suspenWarnFilteredMap.isEmpty()){
            updateAgenciesViaSuspensions(suspenWarnFilteredMap);
        }
        // Added By Moh Sarfaraj for BPM-536
        if(!mapSuspensionWarningsForDocuments.isEmpty()){
            createSuspensionWarningDocuments(mapSuspensionWarningsForDocuments);
        }
    }
    public override void beforeDeleteMethod(List<SObject> oldList, Map<Id, SObject> oldMap) {
        
    }

    // Added by Moh Sarfaraj for BPM-391
    private static void updateAgenciesViaSuspensions(Map<Id,Suspensions_Warning__c> suspenWarnFilteredMap){
        Map<Id,SObject> mapAgencyAgentToUpdate = new Map<Id,SObject>();
        Set<Id> setAgenciesToUpdateLastActiveSuspension = new Set<Id>();
        Set<Id> setAgenciesAgentToNotifyWarning = new Set<Id>();
        
        for(Suspensions_Warning__c eachSuspWarn : suspenWarnFilteredMap.values()){
            if(eachSuspWarn.SuspensionApprovalStatus__c == 'Suspension Approved'){
                
                if(String.isNotBlank(eachSuspWarn.BrokerAgency__c)){
                    if(Approval.isLocked(eachSuspWarn.BrokerAgency__c)){
                        Approval.unlock(eachSuspWarn.BrokerAgency__c);
                    }

                    Account objAccount = new Account( 
                        Id = eachSuspWarn.BrokerAgency__c,
                        SuspensionStartDate__c = eachSuspWarn?.SuspensionStartDate__c,
                        SuspensionEndDate__c = eachSuspWarn?.SuspensionEndDate__c,
                        SuspensionApprovalStatus__c = eachSuspWarn?.SuspensionApprovalStatus__c,
                        SuspensionRemovalReason__c = null
                    );
                    if(eachSuspWarn?.SuspensionWarning__c?.equalsIgnoreCase('Suspension')){
                        objAccount.AgencyStatus__c = 'Suspended';
                    }else if(eachSuspWarn?.SuspensionWarning__c?.equalsIgnoreCase('Warning')){
                        setAgenciesAgentToNotifyWarning.add(eachSuspWarn.BrokerAgency__c);
                    }
                    mapAgencyAgentToUpdate.put(eachSuspWarn.BrokerAgency__c, objAccount);
                }
                // else if(String.isNotBlank(eachSuspWarn.Broker_Agent__c)){
                //     if(Approval.isLocked(eachSuspWarn.Broker_Agent__c)){
                //         Approval.unlock(eachSuspWarn.Broker_Agent__c);
                //     }

                //     Contact objContact = new Contact( 
                //         Id = eachSuspWarn.Broker_Agent__c,
                //         SuspensionStartDate__c = eachSuspWarn?.SuspensionStartDate__c,
                //         SuspensionEndDate__c = eachSuspWarn?.SuspensionEndDate__c,
                //         SuspensionApprovalStatus__c = eachSuspWarn?.SuspensionApprovalStatus__c,
                //         SuspensionRemovalReason__c = null
                //     );
                //     if(eachSuspWarn?.SuspensionWarning__c?.equalsIgnoreCase('Suspension')){
                //         objContact.AgentStatus__c = 'Suspended';
                //     }else if(eachSuspWarn?.SuspensionWarning__c?.equalsIgnoreCase('Warning')){
                //         setAgenciesAgentToNotifyWarning.add(eachSuspWarn.Broker_Agent__c);
                //     }
                //     mapAgencyAgentToUpdate.put(eachSuspWarn.BrokerAgency__c, objContact);
                // }

            }else if(eachSuspWarn.SuspensionApprovalStatus__c == 'Suspension Removal Approved'){
                if(String.isNotBlank(eachSuspWarn.BrokerAgency__c)){
                    if(Approval.isLocked(eachSuspWarn.BrokerAgency__c)){
                        Approval.unlock(eachSuspWarn.BrokerAgency__c);
                    }
                    mapAgencyAgentToUpdate.put(eachSuspWarn.BrokerAgency__c, new Account( 
                        Id = eachSuspWarn.BrokerAgency__c,
                        AgencyStatus__c = 'Active',
                        SuspensionStartDate__c = null,
                        SuspensionEndDate__c = null,
                        SuspensionApprovalStatus__c = null,
                        SuspensionReason__c = null,
                        SuspensionRemovalReason__c = null
                    ));

                    setAgenciesToUpdateLastActiveSuspension.add(eachSuspWarn.BrokerAgency__c);
                }
                // else if(String.isNotBlank(eachSuspWarn.Broker_Agent__c)){
                //     if(Approval.isLocked(eachSuspWarn.Broker_Agent__c)){
                //         Approval.unlock(eachSuspWarn.Broker_Agent__c);
                //     }

                //     mapAgencyAgentToUpdate.put(eachSuspWarn.BrokerAgency__c, new Contact( 
                //         Id = eachSuspWarn.Broker_Agent__c,
                //         AgentStatus__c = 'Active',
                //         SuspensionStartDate__c = null,
                //         SuspensionEndDate__c = null,
                //         SuspensionApprovalStatus__c = null,
                //         SuspensionReason__c = null,
                //         SuspensionRemovalReason__c = null
                //     ));

                //     setAgenciesToUpdateLastActiveSuspension.add(eachSuspWarn.Broker_Agent__c);
                // }
            }
        }
        if(!mapAgencyAgentToUpdate.isEmpty()){
            update mapAgencyAgentToUpdate.values();
        }
        if(!setAgenciesToUpdateLastActiveSuspension.isEmpty()){
            List<Suspensions_Warning__c> listSuspensionWarnsToUpdateLastActiveRecord = new List<Suspensions_Warning__c>();
            for(Account eachAccount : [SELECT Id,(SELECT Id,SuspensionEndDate__c FROM Suspensions_Warning__r WHERE SuspensionWarning__c = 'Suspension' AND IsActiveSuspensionWarning__c = true ORDER BY CreatedDate DESC LIMIT 1) 
                                        FROM Account WHERE Id IN : setAgenciesToUpdateLastActiveSuspension]){

                if(!eachAccount.Suspensions_Warning__r.isEmpty()){
                    eachAccount.Suspensions_Warning__r[0].SuspensionEndDate__c = System.today();
                    listSuspensionWarnsToUpdateLastActiveRecord.add(eachAccount.Suspensions_Warning__r[0]);
                }
            }
            if(!listSuspensionWarnsToUpdateLastActiveRecord.isEmpty()){
                update listSuspensionWarnsToUpdateLastActiveRecord;
            }
        }
        if(!setAgenciesAgentToNotifyWarning.isEmpty()){
            notifyWarningToAgencyUsers(setAgenciesAgentToNotifyWarning);
        } 
    }

    // Added by Moh Sarfaraj for BPM-391
    public static void suspensionExtensions(Map<Id,Id> mapSuspensionIdToAgencyId, Map<Id, Id> mapSuspensionIdToAgentId, List<Suspensions_Warning__c> newList){
        final List<String> setSupensionDays = System.Label.BPM_SuspensionExtensionDays.split(',');
        Map<Id,Date> mapSuspensionIdToSuspensionEndDate = new Map<Id,Date>();
        
        Date lastYearDateFromToday = System.today().addMonths(-Integer.valueOf(System.Label.BPM_SuspensionExtensionResetInMonths));

        if(!mapSuspensionIdToAgencyId.isEmpty()){
            for(Account eachAgency : [SELECT Id,(SELECT Id,Suspension_Warning_Days__c FROM Suspensions_Warning__r WHERE SuspensionWarning__c = 'Suspension' AND
                                    ((SuspensionApprovalStatus__c = 'Suspension Approved' AND SuspensionEndDate__c >= :lastYearDateFromToday AND 
                                        SuspensionEndDate__c <= TODAY) OR (Id IN :mapSuspensionIdToAgencyId.keySet())) 
                                    ORDER By CreatedDate DESC) FROM Account WHERE Id IN :mapSuspensionIdToAgencyId.values()]){
                
                if(!eachAgency.Suspensions_Warning__r.isEmpty()){
                    Integer customSuspensionDays = Integer.valueOf(eachAgency?.Suspensions_Warning__r[0]?.Suspension_Warning_Days__c);
                    if(customSuspensionDays != null && customSuspensionDays != 0){ 
                        mapSuspensionIdToSuspensionEndDate.put(eachAgency?.Suspensions_Warning__r[0]?.Id, System.today()+ customSuspensionDays);                
                    }
                    else if(setSupensionDays?.size() >= eachAgency?.Suspensions_Warning__r?.size()){
                        mapSuspensionIdToSuspensionEndDate.put(eachAgency?.Suspensions_Warning__r[0]?.Id, System.today()+ Integer.valueOf(setSupensionDays[eachAgency?.Suspensions_Warning__r?.size() - 1]));
                    }else{
                        // default value
                        mapSuspensionIdToSuspensionEndDate.put(eachAgency?.Suspensions_Warning__r[0]?.Id, System.today()+ 30);
                    }
                }
            }   
        }
        if(!mapSuspensionIdToAgentId.isEmpty()){
            System.debug('innn');
            for(Contact eachAgent : [SELECT Id,(SELECT Id,Suspension_Warning_Days__c FROM Suspensions_Warning__r WHERE SuspensionWarning__c = 'Suspension' AND
                                    ((SuspensionApprovalStatus__c = 'Suspension Approved' AND SuspensionEndDate__c >= :lastYearDateFromToday AND 
                                        SuspensionEndDate__c <= TODAY) OR (Id IN :mapSuspensionIdToAgentId.keySet())) 
                                    ORDER By CreatedDate DESC) FROM Contact WHERE Id IN :mapSuspensionIdToAgentId.values()]){
                
                if(!eachAgent.Suspensions_Warning__r.isEmpty()){
                    Integer customSuspensionDays = Integer.valueOf(eachAgent?.Suspensions_Warning__r[0]?.Suspension_Warning_Days__c);
                    if(customSuspensionDays != null && customSuspensionDays != 0){ 
                        mapSuspensionIdToSuspensionEndDate.put(eachAgent?.Suspensions_Warning__r[0]?.Id, System.today()+ customSuspensionDays);                
                    }
                    else if(setSupensionDays?.size() >= eachAgent?.Suspensions_Warning__r?.size()){
                        mapSuspensionIdToSuspensionEndDate.put(eachAgent?.Suspensions_Warning__r[0]?.Id, System.today()+ Integer.valueOf(setSupensionDays[eachAgent?.Suspensions_Warning__r?.size() - 1]));
                    }else{
                        // default value
                        mapSuspensionIdToSuspensionEndDate.put(eachAgent?.Suspensions_Warning__r[0]?.Id, System.today()+ 30);
                    }
                }
            }   
        }
        if(!mapSuspensionIdToSuspensionEndDate.isEmpty()){
            for(Suspensions_Warning__c eachSuspension : newList){
                if(mapSuspensionIdToSuspensionEndDate.containsKey(eachSuspension.Id)){
                    eachSuspension.SuspensionEndDate__c = mapSuspensionIdToSuspensionEndDate.get(eachSuspension.Id);
                }
            }
        }
    }

    private static void autoSelectCategoryBasedOnSubCategory(List<Suspensions_Warning__c> newList){
        for(Suspensions_Warning__c suspensionRecord : newList){
            if(String.isNotBlank(suspensionRecord.LeadRegistrationSubCategory__c)){
                suspensionRecord.LeadRegistrationAndManagement__c = true;
            }

            if(String.isNotBlank(suspensionRecord.CommissionSubCategory__c)){
                suspensionRecord.Commission__c = true;
            }

            if(String.isNotBlank(suspensionRecord.LegalMattersSubCategory__c)){
                suspensionRecord.LegalMatters__c = true;
            }

            if(String.isNotBlank(suspensionRecord.DisputesSubCategory__c)){
                suspensionRecord.Disputes__c = true;
            }

            if(String.isNotBlank(suspensionRecord.BusinessEthicsSubCategory__c)){
                suspensionRecord.BusinessEthics__c = true;
            }

            if(String.isNotBlank(suspensionRecord.MarketingAndCommunicationsSubCategory__c)){
                suspensionRecord.MarketingAndCommunications__c = true;
            }

            if(String.isNotBlank(suspensionRecord.BrokerRegistrationSubCategory__c)){
                suspensionRecord.BrokerRegistration__c = true;
            }

            if(String.isNotBlank(suspensionRecord.PropertyViewingsSubCategory__c)){
                suspensionRecord.OpenHousesKioskSalesPropertyViewing__c = true;
            }

            if(String.isNotBlank(suspensionRecord.ResaleSubCategory__c)){
                suspensionRecord.Resale__c = true;
            }

            if(String.isNotBlank(suspensionRecord.ConfidentialityInfoFailureSubCategory__c)){
                suspensionRecord.FailureToProtectConfidentialInfo__c = true;
            }

            if(String.isNotBlank(suspensionRecord.LeadRegistrationSubCategory__c)){
                suspensionRecord.LeadRegistrationAndManagement__c = true;
            }

            if(String.isNotBlank(suspensionRecord.PublishingWoConsentSubCategory__c)){
                suspensionRecord.PublishingArticlesWoConsent__c = true;
            }

            if(String.isNotBlank(suspensionRecord.OtherReasonforSuspension__c)){
                suspensionRecord.Others__c = true;
            }
        }
    }

    @future
    private static void notifyWarningToAgencyUsers(Set<Id> setAgenciesAgentsToNotifyWarning){
        Map<Id,Set<String>> mapAgencyIdTorecipientsIds = new Map<Id,Set<String>>();
        for(User eachUser : [SELECT Id,AccountId FROM User WHERE isActive = true AND (AccountId IN :setAgenciesAgentsToNotifyWarning OR ContactId IN : setAgenciesAgentsToNotifyWarning)]){
            if(mapAgencyIdTorecipientsIds.containsKey(eachUser.AccountId)){
                mapAgencyIdTorecipientsIds.get(eachUser.AccountId).add(eachUser.Id);
            }else{
                mapAgencyIdTorecipientsIds.put(eachUser.AccountId, new Set<String>{eachUser.Id});
            }
        }
        if(!mapAgencyIdTorecipientsIds.isEmpty()){
            CustomNotificationType notificationType = [SELECT Id,DeveloperName FROM CustomNotificationType WHERE DeveloperName='Broker_Notification']; 

            for(Id agencyId : mapAgencyIdTorecipientsIds.keySet()){
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Agency Breach Warning');
                notification.setBody('Your agency breaches Aldar policies, This is warning from Aldar Properties');
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(agencyId);
                notification.send(mapAgencyIdTorecipientsIds.get(agencyId));
            }
        }
    }

    // Added By Moh Sarfaraj for BPM-536
    public static void createSuspensionWarningDocuments(Map<Id,Suspensions_Warning__c> mapSuspensionWarnings){
        String DOCUMENT_PLACEHOLDER_CATEGORY_BROKER = 'Broker Suspension/Warning';
        Set<String> setSuspensionDocumentType = new Set<String>{'Suspension Letter', 'Suspension Letter Draft'};
        Set<String> setWarningDocumentType = new Set<String>{ 'Warning Letter', 'Warning Letter Draft'};
        Set<String> setDocuGenDocumentType = new Set<String>{ 'Suspension Letter Draft', 'Warning Letter Draft'};

        if(mapSuspensionWarnings != null && !mapSuspensionWarnings.isEmpty()){
            Map<String,List<DocumentPlaceHolder__mdt>> documentMap = DocumentService.getDocumentMetaDataByCategory(new set<String>{DOCUMENT_PLACEHOLDER_CATEGORY_BROKER});
            
            List<Loop__DDP_Integration_Option__c> listDocuGen = [SELECT Id,Loop__DDP__c FROM Loop__DDP_Integration_Option__c 
                                                                 WHERE Loop__DDP__r.Name = 'Suspension/Warning letter Draft'];
            
            if(documentMap != null && !documentMap.isEmpty()){
                List<Document__c> documentListToInsert = new List<Document__c>();
                Map<String,Id> documentRecordTypeMap = new Map<String,Id>();
                //get Existing Documents
                Map<String, Document__c> existingDocMap = new Map<String, Document__c>();
                for(Document__c tempDoc : [SELECT Id,DocumentType__c,Suspensions_Warning__c FROM Document__c WHERE Suspensions_Warning__c IN :mapSuspensionWarnings.keySet()]){
                    existingDocMap.put(tempDoc.Suspensions_Warning__c+tempDoc.DocumentType__c,tempDoc);
                }
                for(Suspensions_Warning__c suspenWarn : mapSuspensionWarnings.values()){
                    for(DocumentPlaceHolder__mdt tempMetaRec : documentMap.get(DOCUMENT_PLACEHOLDER_CATEGORY_BROKER)){

                        if((suspenWarn?.SuspensionWarning__c?.equalsIgnoreCase('Suspension') && setSuspensionDocumentType.contains(tempMetaRec.DocumentType__c)) || 
                           (suspenWarn?.SuspensionWarning__c?.equalsIgnoreCase('Warning') && setWarningDocumentType.contains(tempMetaRec.DocumentType__c))){
                            String recordTypeID = null;
                            if(tempMetaRec.RecordTypeDeveloperName__c != null){
                                if(!documentRecordTypeMap.containsKey(tempMetaRec.RecordTypeDeveloperName__c)){
                                    documentRecordTypeMap.put(tempMetaRec.RecordTypeDeveloperName__c,Schema.SObjectType.Document__c.getRecordTypeInfosByDeveloperName().get(tempMetaRec.RecordTypeDeveloperName__c).getRecordTypeId());
                                }
                                recordTypeID = documentRecordTypeMap.get(tempMetaRec.RecordTypeDeveloperName__c);
                            }
                            if(!existingDocMap.containsKey(suspenWarn.Id + tempMetaRec.DocumentType__c)){
                                Document__c documentRecord = DocumentService.createDocumentRecord('','','',tempMetaRec.DocumentType__c,'','',recordTypeID);
                                documentRecord.Suspensions_Warning__c   = suspenWarn.Id;
                                documentRecord.DocumentPlaceHolderId__c = tempMetaRec.DeveloperName;
                                documentRecord.DocumentType__c = tempMetaRec.DocumentType__c;
                                documentRecord.Status__c = 'Pending';

                                if(listDocuGen != null && !listDocuGen.isEmpty() && setDocuGenDocumentType.contains(tempMetaRec.DocumentType__c)){
                                    documentRecord.DeliveryOptionId__c = listDocuGen[0].Id;
                                    documentRecord.DocgenPackageId__c = listDocuGen[0].Loop__DDP__c;
                                    documentRecord.GenerateDocument__c =  true;
                                }
                                documentListToInsert.add(documentRecord); 
                            }
                        }
                    }
                }
                if(!documentListToInsert.isEmpty()){
                    insert documentListToInsert;  
                }
            }
        }
    }
}