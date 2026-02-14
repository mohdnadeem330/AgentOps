/*
*********************************************************
Apex Class Name    : ECSS_ServiceRequestTriggerHelper
Created Date       : June 27 2025
@description       : This Class is used for Specfic for Aldar MoveIn Service Requests
@author            : 
Modification Log:
Ver   Date         Author                     Modification
1.0   27-06-2025                              Initial Version
*********************************************************
*/
public with sharing class ECSS_ServiceRequestTriggerHelper {
    
    public static void estatesBeforeInsert(List<HexaBPM__Service_Request__c> moveInRequests){
        Set<Id> unitIds = new Set<Id>();
        Set<Id> queueIds = new Set<Id>();
        Map<Id, HexaBPM__Service_Request__c> recordMap = new Map<Id, HexaBPM__Service_Request__c>();
        for(HexaBPM__Service_Request__c ecssSR : moveInRequests){
            // Default Values for estates start
            if(ecssSR.Origin__c == null){
                ecssSR.Origin__c ='Salesforce';
            }
            // Default Values for estates start end
            if (ecssSR.Unit__c != null) {
                unitIds.add(ecssSR.Unit__c);
            }
            if (ecssSR.OwnerId != null && String.valueOf(ecssSR.OwnerId).startsWith('00G')) {
                queueIds.add(ecssSR.OwnerId);
                recordMap.put(ecssSR.Id, ecssSR);
            }
        }
        if (!unitIds.isEmpty()) {
            Map < Id, Unit__c > unitMap = new Map < Id, Unit__c >([SELECT Id,Name, Project__r.OA_Community_Name__c FROM Unit__c WHERE Id IN: unitIds]);
            if(!unitMap.values().isEmpty()){
                updateQueueForMoveIn(moveInRequests,unitMap);
                updateAssetOnSR(moveInRequests,unitMap);
            }
        }
    }

    public static void estatesBeforeUpdate(List<HexaBPM__Service_Request__c> moveInRequests){
        Set<Id> unitIds = new Set<Id>();
        Map<Id, HexaBPM__Service_Request__c> recordMap = new Map<Id, HexaBPM__Service_Request__c>();
        for(HexaBPM__Service_Request__c ecssSR : moveInRequests){
            if (ecssSR.Unit__c != null) {
                unitIds.add(ecssSR.Unit__c);
            }
        }
        if (!unitIds.isEmpty()) {
            Map < Id, Unit__c > unitMap = new Map < Id, Unit__c >([SELECT Id,Name, Project__r.OA_Community_Name__c FROM Unit__c WHERE Id IN: unitIds]);
            if(!unitMap.values().isEmpty()){
                updateAssetOnSR(moveInRequests,unitMap);
            }
        }
    }
    
    public static void estatesAfterInsert(List<HexaBPM__Service_Request__c> moveInRequests){
        Set<Id> queueIds = new Set<Id>();
        Map<Id, HexaBPM__Service_Request__c> recordMap = new Map<Id, HexaBPM__Service_Request__c>();
        for(HexaBPM__Service_Request__c ecssSR : moveInRequests){
            if (ecssSR.OwnerId != null && String.valueOf(ecssSR.OwnerId).startsWith('00G')) {
                queueIds.add(ecssSR.OwnerId);
                recordMap.put(ecssSR.Id, ecssSR);
            }
        }
        if (!queueIds.isEmpty()) {
            shareSRWithQueueMembers(queueIds,recordMap);
        }
    }

    /*
    *********************************************************
    @Method Name    : updateQueueForMoveIn
    @author         : 
    @description    : Method to update the Queue on the MoveIn Service Request
    @param          : moveInRequests, unitMap 
    @return         : void
    ********************************************************
    */ 
    private static void updateQueueForMoveIn(List<HexaBPM__Service_Request__c> moveInRequests, Map < Id, Unit__c > unitMap ){
        Map<String, String> communityToQueueName = new Map<String, String>();
        Set<String> communityNames = new Set<String>();
        Map<String, Group> queueNameToGroup = new Map<String, Group>();
        Map<Id, List<HexaBPM__Service_Request__c>> queueIdToSRs = new Map<Id, List<HexaBPM__Service_Request__c>>();
        
        for(Unit__c unitRec : unitMap.values()){
            if(unitRec.Project__c != null && unitRec.Project__r.OA_Community_Name__c != null){
                communityNames.add(unitRec.Project__r.OA_Community_Name__c);
            }
        }
        for (AE_Comunity_Details__mdt meta : [SELECT Label,Queue_Name__c  FROM AE_Comunity_Details__mdt WHERE Label IN :communityNames ]) {
            communityToQueueName.put(meta.Label, meta.Queue_Name__c);
        }
        if(!communityToQueueName.keySet().isEmpty()){
            Set<String> queueNames = new Set<String>(communityToQueueName.values());
            for (Group g : [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name IN :queueNames]) {
                queueNameToGroup.put(g.Name, g);
            }
            for (HexaBPM__Service_Request__c sr : moveInRequests) {
                if(unitMap.containsKey(sr.Unit__c) && communityToQueueName.containsKey(unitMap.get(sr.Unit__c).Project__r.OA_Community_Name__c)){
                    String queueName = communityToQueueName.get(unitMap.get(sr.Unit__c).Project__r.OA_Community_Name__c);
                    if(queueNameToGroup.containsKey(queueName)){
                        sr.OwnerId = queueNameToGroup.get(queueName).Id;
                    }
                }
            }
        }
    }

    /*
    *********************************************************
    @Method Name    : updateAssetOnSR
    @author         : 
    @description    : This method ensures that each Service Request (SR) of type Move-In is linked to the correct Asset, based on the related Unit’s name.
    @param          : moveInRequests, unitMap 
    @return         : void
    ********************************************************
    */    
    private static void updateAssetOnSR(List<HexaBPM__Service_Request__c> moveInRequests, Map < Id, Unit__c > unitMap){
        Set<String> unitNames = new Set<String>();
        for (Unit__c unit : unitMap.values()) {
            unitNames.add(unit.Name);
        }
        Map<String, Asset> unitNameToAssetMap = new Map<String, Asset>();
        for (Asset asset : [SELECT Id, ECSS_Unit_Number__c,Unit__r.Name FROM Asset WHERE Unit__r.Name IN :unitNames]) {
            unitNameToAssetMap.put(asset.Unit__r.Name, asset);
        }
        for (HexaBPM__Service_Request__c sr : moveInRequests) {
            if(unitMap.containsKey(sr.Unit__c)){
                HexaBPM__Service_Request__c moveInSr = new HexaBPM__Service_Request__c(Id= sr.Id );
                Asset matchingAsset = unitNameToAssetMap.get(unitMap.get(sr.Unit__c).Name);
                if (matchingAsset != null && sr.Asset__c != matchingAsset.Id) {
                    sr.Asset__c = matchingAsset.Id;
                }
            }
        }
        ServiceRequestTriggerHelper.checkSRAutomation(moveInRequests,null);
    }
    
    /*
    *********************************************************
    @Method Name    : shareSRWithQueueMembers
    @author         : 
    @description    : Sharing the Service Request with the Queue Members
    @param          : quueIds, recordMap 
    @return         : void
    ********************************************************
    */
    private static void shareSRWithQueueMembers(Set<Id> queueIds,Map<Id, HexaBPM__Service_Request__c> recordMap){
        Map<Id, List<Id>> queueToUsersMap = new Map<Id, List<Id>>();
        List<HexaBPM__Service_Request__Share> shares = new List<HexaBPM__Service_Request__Share>();
        for (GroupMember gm : [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :queueIds]) {
            if (!queueToUsersMap.containsKey(gm.GroupId)) {
                queueToUsersMap.put(gm.GroupId, new List<Id>());
            }
            queueToUsersMap.get(gm.GroupId).add(gm.UserOrGroupId);
        }
        for (HexaBPM__Service_Request__c record : recordMap.values()){ 
            List<Id> userIds = queueToUsersMap.get(record.OwnerId);
            if (userIds != null) {
                for (Id userId : userIds) {
                    shares.add(new HexaBPM__Service_Request__Share(ParentId = record.Id,UserOrGroupId = userId,AccessLevel = 'Edit',RowCause = Schema.HexaBPM__Service_Request__Share.RowCause.Manual));
                }
            }
        }
        if (!shares.isEmpty()){
            insert shares;
        }
    } 
	/*
    *********************************************************
    @Method Name    : afterUpdSRStatusUpd
    @author         : 
    @description    : Method to update the Status of the Service Request to Approved.
    @param          : quueIds, recordMap 
    @return         : void
    ********************************************************
    */
    public static void afterUpdSRStatusUpd(List<HexaBPM__Service_Request__c> moveInRequests) {
        List<HexaBPM__Service_Request__c> srUpdList = new List<HexaBPM__Service_Request__c>();
        Id approvedStatus = ServiceRequestTriggerHelper.getSRStatus().get(Constants.STATUS_APPROVED)?.Id;
        for(HexaBPM__Service_Request__c serReq : moveInRequests) {
            HexaBPM__Service_Request__c sReq = new HexaBPM__Service_Request__c();
            sReq.id = serReq.id;            
            sReq.HexaBPM__External_SR_Status__c = approvedStatus;
            sReq.HexaBPM__Internal_SR_Status__c = approvedStatus;
            srUpdList.add(sReq);
        }
        if(!srUpdList.isEmpty()) {
            update srUpdList;
        }
    }
}