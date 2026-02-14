/**********************************************************************************************************************
* Name               : CC_ChildOfHandoverSR                                                        
* Description        : This class is used by Handover + Title Deed Process to reparent the Title Deed SR under the Handover
* Usage              : Handover + Title Deed Process SR PRocess
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     29 Dec 2022      Initial Draft       
******************************************************************************************************************/
global without sharing class CC_ChildOfHandoverSR implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_ChildOfHandoverSR: Invalid SR or SR Step';
            }else{

                HexaBPM__Service_Request__c sRRecord = [SELECT Id, Unit__c, SalesOrder__c, HexaBPM__Record_Type_Name__c,RecordType.Name FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                
                String whereClosure = '';

                if(sRRecord.RecordType.Name == Constants.HANDOVER_RT){
                   
                    whereClosure = ' RecordType.Name IN :titleDeedSRs ';

                } else if(sRRecord.RecordType.Name == Constants.TITLE_DEED_REGISTRATION_RT || 
                         sRRecord.RecordType.Name == Constants.SPA_READY_TITLE_DEED_REGISTRATION_RT || 
                          sRRecord.RecordType.Name == Constants.SPA_RTO_PHPP_TITLE_DEED_REGISTRATION_RT){
                    whereClosure = ' RecordType.Name =\'' + Constants.HANDOVER_RT + '\'';

                } else {
                    return result;
                }

                List<String> titleDeedSRs=new List<String>();
                titleDeedSRs.add(Constants.TITLE_DEED_REGISTRATION_RT);
                titleDeedSRs.add(Constants.SPA_READY_TITLE_DEED_REGISTRATION_RT);
                titleDeedSRs.add(Constants.SPA_RTO_PHPP_TITLE_DEED_REGISTRATION_RT);
                String query='SELECT Id, Unit__c, SalesOrder__c, HexaBPM__Record_Type_Name__c,RecordType.Name FROM HexaBPM__Service_Request__c WHERE HexaBPM__External_Status_Name__c != \'' + Constants.SR_STATUS_CANCELLED + '\' AND Unit__c = \''+ sRRecord.Unit__c + '\' AND SalesOrder__c =\'' + sRRecord.SalesOrder__c +'\' AND '+ whereClosure + ' order by CreatedDate desc limit 1';
                List<HexaBPM__Service_Request__c> relatedSR = database.Query(query);
                system.debug('** Query ***'+query);
                system.debug('** Child of relatedSR ***'+relatedSR);
                if(relatedSR.size() == 0){
                    return result;
                }

                if(sRRecord.RecordType.Name == Constants.HANDOVER_RT){
                    relatedSR[0].HexaBPM__Parent_SR__c = sRRecord.Id;
                    update relatedSR[0];
                    closeTitleDeedStep(new set<ID>{sRRecord.Id}, false);

                } else {
                    sRRecord.HexaBPM__Parent_SR__c = relatedSR[0].Id;
                    update sRRecord;
                    closeTitleDeedStep(new set<ID>{relatedSR[0].Id}, true);
                }
                
            }
        } catch(Exception e){
            result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_ChildOfHandoverSR';
        }
        return result;
    }
    
     public static void closeTitleDeedStep(set<ID> hoIds,boolean forceClose){
        Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.HANDOVER_RT);
        Id tdRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.TITLE_DEED_REGISTRATION_RT);
        Id tdSPAReadyRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_READY_TITLE_DEED_REGISTRATION_RT);
        Id tdSPAROPHPPRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.SPA_RTO_PHPP_TITLE_DEED_REGISTRATION_RT);
        
        List<String> titleDeedRecordTypes=new List<String>();
        titleDeedRecordTypes.add(tdRecordTypeId);
        titleDeedRecordTypes.add(tdSPAReadyRecordTypeId);
        titleDeedRecordTypes.add(tdSPAROPHPPRecordTypeId);
        
        map<id,HandoverDetails__c> hoListToUpdate = new map<id,HandoverDetails__c>();
        list<HexaBPM__Service_Request__c> sHOrList = [select id,HandoverDetail__c,HandoverDetail__r.TitleDeedStatus__c,HandoverDetail__r.UtilityTransferStatus__c,HandoverDetail__r.TitleDeedCompletionDate__c,(select id,HexaBPM__IsClosedStatus__c from HexaBPM__Service_Requests__r where  recordTypeId = :titleDeedRecordTypes and HexaBPM__External_Status_Name__c != :Constants.SR_STATUS_CANCELLED) from HexaBPM__Service_Request__c where id = :hoIds and recordTypeId = :handoverRecordTypeId ];

        set<Id> srtoProcess = new set<ID>();
        for(HexaBPM__Service_Request__c tempSR :sHOrList ){
           
            string titledeedStatus = (tempSR.HandoverDetail__r.TitleDeedStatus__c == Constants.HO_TRANSSTATUS_NOTREADY || tempSR.HandoverDetail__r.TitleDeedStatus__c == null) ? Constants.HO_TRANSSTATUS_NOTSTRTED : tempSR.HandoverDetail__r.TitleDeedStatus__c ;
            string utilStatus = (tempSR.HandoverDetail__r.UtilityTransferStatus__c == Constants.HO_TRANSSTATUS_NOTREADY || tempSR.HandoverDetail__r.UtilityTransferStatus__c == null) ? Constants.HO_TRANSSTATUS_NOTSTRTED : tempSR.HandoverDetail__r.UtilityTransferStatus__c ;
            hoListToUpdate.put(tempSR.HandoverDetail__c,new  HandoverDetails__c(id= tempSR.HandoverDetail__c,UtilityTransferStatus__c = utilStatus , TitleDeedStatus__c = titledeedStatus ) );
           
            if(!tempSR.HexaBPM__Service_Requests__r.isEmpty() && (tempSR.HexaBPM__Service_Requests__r[0].HexaBPM__IsClosedStatus__c==true || forceClose) ){
                srtoProcess.add(tempSR.Id);

                if(tempSR.HandoverDetail__r.TitleDeedCompletionDate__c==null){
                    hoListToUpdate.put(tempSR.HandoverDetail__c,new  HandoverDetails__c(id= tempSR.HandoverDetail__c,UtilityTransferStatus__c =  Constants.HO_TRANSSTATUS_INPROGRESS, TitleDeedCompletionDate__c=system.today(), TitleDeedStatus__c =Constants.HO_TRANSSTATUS_COMPLTED));
                }
            }
        }
        list<HexaBPM__Step__c> stepsToClose = [select id,HexaBPM__SR__c from HexaBPM__Step__c where HexaBPM__SR__c in :srtoProcess and Step_Template_Code__c=:Constants.STEP_NAME_TITLE_DEED and HexaBPM__Step_Status__c =:Constants.STEP_STATUS_PENDING];
        if(!stepsToClose.isEmpty()){
            HexaBPM__Status__c stepStatus= [select id,name from HexaBPM__Status__c where name = :Constants.STEP_STATUS_COMPLETED limit 1];
            for(HexaBPM__Step__c tempRec : stepsToClose){
                tempRec.HexaBPM__Status__c = stepStatus.Id;
            }
            update stepsToClose;
        }
        
        //updatetitle deed date
        if(!hoListToUpdate.isEmpty()){
           // update hoListToUpdate.values(); 
        }
    }
    
    
    
    
    
    
    
}