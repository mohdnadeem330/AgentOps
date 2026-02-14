public with sharing class CancelSRController {
    
    @AuraEnabled
    public static Boolean checkToAllowCancelSR(string recordId){
        try {
            Boolean isAllowToCancelSR = true;

            List<HexaBPM__Service_Request__c> serviceRequest = [SELECT Id, SRType__c, HexaBPM__External_Status_Name__c FROM HexaBPM__Service_Request__c 
                                                                WHERE Id =: recordId AND HexaBPM__External_Status_Name__c != : Constants.CLOSED_SR 
                                                                AND HexaBPM__External_Status_Name__c != : Constants.SR_STATUS_CANCELLED 
                                                                AND HexaBPM__IsClosedStatus__c = false];

            if (!serviceRequest.isEmpty()) {
                for (SRAutomation__mdt srAutomation: SRAutomation__mdt.getall().values()) {
                    if (srAutomation.SRType__c == serviceRequest[0].SRType__c && srAutomation.SRStatusToStopCancellation__c != null) {
                        for (String status: srAutomation.SRStatusToStopCancellation__c.split(',')) {
                            if (status == serviceRequest[0].HexaBPM__External_Status_Name__c) {
                                isAllowToCancelSR = false;
                            }
                        }
                    }
                }
            } else {
                isAllowToCancelSR = false;
            }
            return isAllowToCancelSR;
        } catch (NoAccessException ex) { throw new CustomException(ex.getMessage());
        } catch (Exception ex) { throw new CustomException(Constants.MESSAGE_GENERIC_ERROR);
        }
    }

    //--- used to change the SR status to 'Canceled' and close all open steps by changeing the step status to 'Canceled'
    @AuraEnabled
    public static void cancelSR(string recordId){
        try {
            HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: Constants.SR_STATUS_CANCELLED LIMIT 1];
            HexaBPM__Status__c stepStatus = [SELECT Id, Name FROM HexaBPM__Status__c WHERE Name=: Constants.STEP_STATUS_CANCELLED];

            List<HexaBPM__Step__c> stepsList = [SELECT Id, HexaBPM__SR__c, HexaBPM__SR__r.RecordType.Name, HexaBPM__SR__r.SalesOrder__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c =: recordId AND HexaBPM__Closed_Date__c = null];

            HexaBPM__Service_Request__c srRecord = new HexaBPM__Service_Request__c(Id=recordId);
            srRecord.HexaBPM__External_SR_Status__c = objSRStatus.Id;
            srRecord.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;
            srRecord.HexaBPM__Required_Docs_not_Uploaded__c = false;
            srRecord.HexaBPM__Closed_Date_Time__c = system.now();

            if (stepsList <> NULL && stepsList.size() > 0 && stepsList[0].HexaBPM__SR__r.RecordType.Name == Constants.LPC_WAIVER_RT) {
                CC_VerifyLPCWaverRequest.updateInstallmentLines(stepsList[0].HexaBPM__SR__r.SalesOrder__c, srRecord);
            } else {
                update srRecord;
            }

            List<HexaBPM__Step__c> stepsListToUpdate = new List<HexaBPM__Step__c>();
            for (HexaBPM__Step__c stepRecord : stepsList) {
                stepRecord.HexaBPM__Closed_Date__c = Date.today();
                stepRecord.HexaBPM__Closed_Date_Time__c = system.now();
                stepRecord.HexaBPM__Status__c = stepStatus.Id;
                stepRecord.HexaBPM__Step_Notes__c = 'SR Cancelled';
                stepsListToUpdate.add(stepRecord);
            }
            update stepsListToUpdate;
        } catch (DMLException ex) { throw new CustomException(ex.getMessage());
        } catch (NoAccessException ex) { throw new CustomException(ex.getMessage());
        } catch (Exception ex) { throw new CustomException(ex.getMessage());
        }
    }
}