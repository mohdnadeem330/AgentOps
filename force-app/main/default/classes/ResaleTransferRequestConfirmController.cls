public without sharing class ResaleTransferRequestConfirmController {
    @AuraEnabled
    public static String initiateTransfer(String recordId) {
        // System.debug('#########recordId: '+recordId);
        String returnString = '';
        Savepoint sp = Database.setSavepoint();
        try{
            Opportunity thisOpp = getOppDetails(recordId);
            
            // if(thisOpp.Equity_Paid__c < 20){
            //     return 'Equity Paid % must be greater than 20% before transferring';
            // }

            String propertyTransferTemplateId = [SELECT Id FROM HexaBPM__SR_Template__c WHERE HexaBPM__SR_RecordType_API_Name__c =: ResaleConstants.SR_RT_PROPERTY_TRANSFER LIMIT 1].Id;

            HexaBPM__Service_Request__c thisSR = new HexaBPM__Service_Request__c();
            thisSR.RecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByDeveloperName().get(ResaleConstants.SR_RT_PROPERTY_TRANSFER).getRecordTypeId();
            thisSR.HexaBPM__SR_Template__c = propertyTransferTemplateId;
            thisSR.SRType__c = ResaleConstants.SR_TYPE_PROPERTY_TRANSFER;
            thisSR.ChargeType__c = ResaleConstants.SR_CHARGETYPE_TRANSFER_NORMAL;
            thisSR.MOUSigned__c = ResaleConstants.YES;
            thisSR.CreatedFromResaleOpportunity__c = true;
            
            thisSR.ResaleOpportunity__c = thisOpp.Id;
            thisSR.SalesOrder__c = thisOpp.SalesOrder__c;
            thisSR.Unit__c = thisOpp.Unit__c;
            thisSR.TransferSellingPrice__c = thisOpp.Amount;
            
            thisSR.HexaBPM__Customer__c = thisOpp.Seller__c;
            thisSR.BuyerName__c = thisOpp.AccountId;
            thisSR.Resale_Initiated_By__c = thisOpp.OwnerId;
            
            insert thisSR;

            List<JointOwner__c> jointOwnersList = getJointOwners(thisOpp.Seller__c);
            if(jointOwnersList.size() > 0){
                List<AgencyTeam__c> agencyTeamInsertList = new List<AgencyTeam__c>();
                for(JointOwner__c thisJointOwner : jointOwnersList){
                    AgencyTeam__c thisRec = new AgencyTeam__c();
                    thisRec.Name = thisJointOwner.Name;
                    thisRec.Account__c = thisJointOwner.Account__c;
                    thisRec.JointOwner__c = thisJointOwner.Id;
                    thisRec.ServiceRequest__c = thisSR.Id;
                    thisRec.ShareHoldingPercentage__c = thisJointOwner.SharePercentage__c;

                    agencyTeamInsertList.add(thisRec);
                }

                if(agencyTeamInsertList.size() > 0){
                    insert agencyTeamInsertList;
                }
            }

            // close opportunity
            thisOpp.ResaleOpportunityStageFlag__c = String.valueOf(System.now());
            thisOpp.StageName = ResaleConstants.OPP_STATUS_CLOSED_WON;
            thisOpp.TransferRequestInitiationDate__c = System.today();
            update thisOpp;

            // updating Unit
            if(thisOpp.Unit__c != null){
                List<Unit__c> units = [ SELECT Id, ListedCase__c
                                        FROM Unit__c 
                                        WHERE Id =: thisOpp.Unit__c 
                                        LIMIT 1];
                if(units != null && units.isEmpty() ){
                    // if unit was listed, delist through case, else just update resale status
                    if(units[0].ListedCase__c != null){
                        ResaleService.delistUnitsWithCaseIds(new List<Id>{units[0].ListedCase__c}, ResaleConstants.UNIT_RESALESTATUS_TRANSFER_PROGRESS);
                    }else{
                        update new Unit__c(Id = thisOpp.Unit__c, ResaleStatus__c = ResaleConstants.UNIT_RESALESTATUS_TRANSFER_PROGRESS);
                    }
                }
            }

            returnString = 'success';
        }catch(Exception e){
            String errorMessage = e.getMessage(); // Get the exception message
            if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                returnString = errorMessage.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ',': []'); // Extract the validation error message
            }else{
                returnString = errorMessage;
            }
        }

        return returnString;
    }

    @AuraEnabled
    public static Boolean doesSRAlreadyExists(String recordId){
        List<HexaBPM__Service_Request__c> existingSRList = [SELECT Id FROM HexaBPM__Service_Request__c
                                                            WHERE ResaleOpportunity__c =: recordId 
                                                            AND SRType__c = :ResaleConstants.SR_TYPE_PROPERTY_TRANSFER 
                                                            AND ChargeType__c = :ResaleConstants.SR_CHARGETYPE_TRANSFER_NORMAL ];

        return existingSRList.size() > 0 ? true : false;
    }

    private static List<JointOwner__c> getJointOwners(Id accountId){
        return [SELECT Id, Name, SharePercentage__c, RelationshipType__c, Account__c
                FROM JointOwner__c 
                WHERE Account__c =: accountId];                  
    }

    private static Opportunity getOppDetails (Id recordId){
        return [SELECT Id, AccountId, SalesOrder__c, Unit__c, Seller__c, Amount, OwnerId, Equity_Paid__c
                FROM Opportunity
                WHERE Id =: recordId
                LIMIT 1];
    }
}