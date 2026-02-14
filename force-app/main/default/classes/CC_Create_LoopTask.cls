global without sharing class CC_Create_LoopTask implements HexaBPM.iLoopTaskExecutable {
    global string GenerateLoopTask(list < HexaBPM__Step__c > lstExistingSteps, map < string, Id > mapStepQueues, map < Id, string > mapStepTemplateQueues, map < Id, string > mapSRStepQueues, map < Id, string > mapSRTemplateQueues, map < id, id > mapSROwner,
        map < id, string > mapUserLicense, map < string, Id > mapStepRecType, list < HexaBPM__SR_Steps__c > lstSRSteps, HexaBPM__Action__c action, HexaBPM__Step__c stp) {
        string strResult = 'Success';
        System.debug('mapStepQueues-----------' + mapStepQueues);
        System.debug('stp-----------' + stp);
        System.debug('stp-----------' + lstSRSteps);
        System.debug('stp-----------' + lstExistingSteps);
        HexaBPM__Step__c insStp = new HexaBPM__Step__c();
        string queueName = '';
        string SROwnerId = null;
        integer maxLoopStepNo = 0;
        integer LoopStepNo;
        HexaBPM__SR_Steps__c CurrentSRStep = new HexaBPM__SR_Steps__c();
        for (HexaBPM__SR_Steps__c srstep: lstSRSteps) {
            system.debug('+++>' + srstep.HexaBPM__Step_No__c + ' ' + action.HexaBPM__Field_Value__c);
            if (string.valueOf(srstep.HexaBPM__Step_No__c) == action.HexaBPM__Field_Value__c) {
                CurrentSRStep = srstep;
                break;
            }
        }
        if(CurrentSRStep != null && CurrentSRStep.id != null) {
            insStp.HexaBPM__SR__c = stp.HexaBPM__SR__c;
            insStp.HexaBPM__Step_Template__c = CurrentSRStep.HexaBPM__Step_Template__c;
            insStp.HexaBPM__Status__c = CurrentSRStep.HexaBPM__Start_Status__c;
            insStp.HexaBPM__SR_Step__c = CurrentSRStep.id;
            for (HexaBPM__Step__c objstep: lstExistingSteps) {
                //if(objstep.HexaBPM__Sys_Step_Loop_No__c!=null && objstep.HexaBPM__SR_Step__c == CurrentSRStep.id){ 
                if (objstep.HexaBPM__Sys_Step_Loop_No__c != null) {
                    LoopStepNo = integer.valueOf(objstep.HexaBPM__Sys_Step_Loop_No__c.substringAfter('_'));
                    if (maxLoopStepNo < LoopStepNo) {
                        maxLoopStepNo = LoopStepNo;
                    }
                }
            }
            if (CurrentSRStep.HexaBPM__Do_not_use_owner__c == false) {
                if (string.valueOf(CurrentSRStep.OwnerId).startsWith('005')) {
                    insStp.OwnerId = CurrentSRStep.OwnerId;
                } else {
                    if (mapSRStepQueues.containsKey(CurrentSRStep.OwnerId)) {
                        queueName = mapSRStepQueues.get(CurrentSRStep.OwnerId);
                    }
                    if (queueName.contains('Client')) {
                        insStp.HexaBPM__Step_Notes__c = stp.HexaBPM__Step_Notes__c;
                        insStp.OwnerId = mapStepQueues.get(queueName);
                    } else if (mapStepQueues.containsKey(queueName)) {
                        insStp.OwnerId = mapStepQueues.get(queueName);
                    }
                }
            }else if (CurrentSRStep.HexaBPM__SR_Template__c != null && CurrentSRStep.HexaBPM__SR_Template__r.HexaBPM__Do_not_use_owner__c == false) {
                if (string.valueOf(CurrentSRStep.HexaBPM__SR_Template__r.OwnerId).startsWith('005')) {
                    insStp.OwnerId = CurrentSRStep.HexaBPM__SR_Template__r.OwnerId;
                } else {
                    if (mapSRTemplateQueues.containsKey(CurrentSRStep.OwnerId)) {
                        queueName = mapSRTemplateQueues.get(CurrentSRStep.OwnerId);
                    }
                    if (queueName.contains('Client')) {
                        insStp.HexaBPM__Step_Notes__c = stp.HexaBPM__Step_Notes__c;
                        insStp.OwnerId = mapStepQueues.get(queueName);
                    } else
                    if (mapStepQueues.containsKey(queueName)) {
                        insStp.OwnerId = mapStepQueues.get(queueName);
                    }
                }
            }else if (CurrentSRStep.HexaBPM__Step_Template__c != null) {
                if (string.valueOf(CurrentSRStep.HexaBPM__Step_Template__r.OwnerId).startsWith('005')) {
                    insStp.OwnerId = CurrentSRStep.HexaBPM__Step_Template__r.OwnerId;
                } else {
                    if (mapStepTemplateQueues.containsKey(CurrentSRStep.OwnerId)) {
                        queueName = mapStepTemplateQueues.get(CurrentSRStep.OwnerId);
                    }
                    if (queueName.contains('Client')) {
                        insStp.HexaBPM__Step_Notes__c = stp.HexaBPM__Step_Notes__c;
                        insStp.OwnerId = mapStepQueues.get(queueName);
                    } else
                    if (mapStepQueues.containsKey(queueName)) {
                        insStp.OwnerId = mapStepQueues.get(queueName);
                    }
                }
            }
            if(CurrentSRStep.HexaBPM__Step_RecordType_API_Name__c != null) {
                if(mapStepRecType.get(CurrentSRStep.HexaBPM__Step_RecordType_API_Name__c) != null)
                    insStp.RecordTypeId = mapStepRecType.get(CurrentSRStep.HexaBPM__Step_RecordType_API_Name__c);
            }else{
                if (CurrentSRStep.HexaBPM__Step_Template__c != null && CurrentSRStep.HexaBPM__Step_Template__r.HexaBPM__Step_RecordType_API_Name__c != null && mapStepRecType.get(CurrentSRStep.HexaBPM__Step_Template__r.HexaBPM__Step_RecordType_API_Name__c) != null) {
                    insStp.RecordTypeId = mapStepRecType.get(CurrentSRStep.HexaBPM__Step_Template__r.HexaBPM__Step_RecordType_API_Name__c);
                }
            }
            insStp.HexaBPM__Start_Date__c = system.today();
            insStp.HexaBPM__Summary__c = CurrentSRStep.HexaBPM__Summary__c;
            insStp.HexaBPM__Step_Notes__c = stp.HexaBPM__Step_Notes__c;
            insStp.HexaBPM__Step_No__c = CurrentSRStep.HexaBPM__Step_No__c;
            maxLoopStepNo = maxLoopStepNo + 1;
            insStp.HexaBPM__Parent_Step__c = stp.Id;
            insStp.HexaBPM__Sys_Step_Loop_No__c = string.valueOf(insStp.HexaBPM__Step_No__c) + '_' + maxLoopStepNo;
            if(CurrentSRStep.HexaBPM__Estimated_Hours__c != null && label.HexaBPM.Business_Hours_Id!=null){
                ID BHId = Id.valueOf(label.HexaBPM.Business_Hours_Id);
                Long sla = CurrentSRStep.HexaBPM__Estimated_Hours__c.longvalue();
                sla = sla * 60 * 60 * 1000L;
                datetime CreatedTime = system.now();
                insStp.HexaBPM__Due_Date__c = BusinessHours.add(BHId, CreatedTime, sla);
            }
            try {
                insert insStp;
            }catch (Exception e) {
                strResult = string.valueOf(e.getMessage());
                throw new HexaBPM.CommonCustomException(string.valueOf(e.getMessage()));
            }
        }
        return strResult;
    }
}