/**********************************************************************************************************************
* Name               : HandoverUtility                                                        
* Description        : Class to store all the methods related to Default and termination process.
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/09/2022      Initial Draft 
* 1.1           harsh@aldar              27/02/2024     Reassign method added        
******************************************************************************************************************/
public with sharing class HandoverUtility {
    public static string HANDOVERACTION_CREATESR = 'HANDOVERACTION_CREATESR';
    public static string HANDOVERACTION_SEND_HC = 'HANDOVERACTION_SEND_HC';
    public static string HANDOVERACTION_SEND_HP = 'HANDOVERACTION_SEND_HP';
    public static string HANDOVERACTION_SEND_SNAG = 'HANDOVERACTION_SEND_SNAG';
    public static string HANDOVERACTION_UPDATEGROUP = 'HANDOVERACTION_UPDATEGROUP';
    public static string HANDOVERACTION_FINANCE_VERIFICATION = 'HANDOVERACTION_FINANCE_VERIFICATION';
    public static string HANDOVERACTION_ASSIGN_KAR = 'HANDOVERACTION_ASSIGN_KAR';
    public static string HANDOVERACTION_SEND_HO = 'HANDOVERACTION_SEND_HO';
    public static string HANDOVERACTION_SEND_RFO = 'HANDOVERACTION_SEND_RFO';
    public static set<String> soldSR = new set<String>{Constants.STATUS_APPROVAL_PENDING,Constants.SO_STATUS_SOLD,Constants.SO_STATUS_RTO_Approve_PENDING , Constants.SO_STATUS_RTO_SOLD};
    
    @AuraEnabled(cacheable=false)
    public static string getSRsrDocID(String srId){
       HexaBPM__SR_Doc__c assRec=[Select Id from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c=:srId AND  DocumentMasterCode__c='ERP_SOA'];
       return assRec.ID;
     }  
    
    public static map<id,id> getSOAReportID(set<Id> srID){
        map<id,id> srToSOAReportID = new map<id,id>();
        map<id,HexaBPM__SR_Doc__c> docMap = new map<id,HexaBPM__SR_Doc__c>([select id,HexaBPM__Service_Request__c from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c in : srID and DocumentMasterCode__c = 'ERP_SOA']);
        if(!docMap.isEmpty()){
            for(ContentDocumentLink cdl : [select id,LinkedEntityId,ContentDocumentId from ContentDocumentLink where LinkedEntityId in : docMap.keySet() order by systemmodstamp desc limit 1] ){
                srToSOAReportID.put(docMap.get(cdl.LinkedEntityId).HexaBPM__Service_Request__c,cdl.ContentDocumentId);
            }
        }
        return srToSOAReportID;
    }
    
    @AuraEnabled(cacheable=false)
    public static string createHandoverSRUpdateSO(list<ID> unitIds){
        string message ='success';
        set<ID> unitIdSet = new set<ID>(unitIds);
        Boolean isCreateStepCall=false;
        map<id,Unit__c> unitsToUpdate = new  map<id,Unit__c>();
       
        for(Unit__c tempRec : [select id,ASiteUnitStatus__c,BuildingSectionName__r.CompletionCertificateDate__c,(select id,ApprovePendingDate__c from OpportunityUnitsUnit__r where Status__c in :soldSR) from Unit__c where id in :unitIds and ASiteUnitStatus__c != :Constants.ASITE_UNIT_CLEARED]){
            IF(tempRec.OpportunityUnitsUnit__r!=null && !tempRec.OpportunityUnitsUnit__r.isEmpty() 
               && tempRec.BuildingSectionName__r.CompletionCertificateDate__c!=null && tempRec.BuildingSectionName__r.CompletionCertificateDate__c <  
               tempRec.OpportunityUnitsUnit__r.get(0).ApprovePendingDate__c){
                unitsToUpdate.put(tempRec.Id, new Unit__c(id=tempRec.Id, ASiteUnitStatus__c=Constants.ASITE_UNIT_CLEARED));
            }
            
            unitIdSet.remove(tempRec.Id);
        }
        try{
            //Should create SR
            if(!unitsToUpdate.isEmpty()){
                update unitsToUpdate.values();
            }
            if(!unitIdSet.isEmpty()){
                Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
                map<id,HandoverDetails__c> handoverDetailsToUpdate = new map<id,HandoverDetails__c>();
                map<id,HexaBPM__Service_Request__c> SRtoUpdate = new map<id,HexaBPM__Service_Request__c>();
                set<ID> cancelledUnitIds=new set<ID>();
                // get relavent Sales Order
                //set<String> soldSR = new set<String>{Constants.STATUS_APPROVAL_PENDING,Constants.SO_STATUS_SOLD,Constants.SO_STATUS_RTO_Approve_PENDING , Constants.SO_STATUS_RTO_SOLD};
                map<id,SalesOrder__c> unitTosalesOrderMap = new map<id,SalesOrder__c>();
                for(SalesOrder__c soRecord : [select Id,PaymentPlan__c,PaymentPlan__r.PHPPFlag__c,recordType.Name,unit__c,Unit__r.BuildingSectionName__r.AnticipatedCompletionDate__c ,Account__c,Contact__c,unit__r.recordType.Name,Unit__r.UnitType__c,Sales_Type__c,PHPP__c from SalesOrder__c where unit__c in :unitIds and Status__c in :soldSR]){
                    unitTosalesOrderMap.put(soRecord.unit__c,soRecord);
                }
                system.debug(unitTosalesOrderMap);
                for(HexaBPM__Service_Request__c existingRecord : [select id,SalesOrder__c,Unit__c,HandoverDetail__c,SalesOrder__r.Status__c from HexaBPM__Service_Request__c where  RecordTypeId = :handoverRecordTypeId and Unit__c in :unitIds and HexaBPM__External_Status_Name__c != :Constants.SR_STATUS_CANCELLED]){
                    if(existingRecord.SalesOrder__c!=null){
                        if(unitTosalesOrderMap.get(existingRecord.Unit__c)!=null  && existingRecord.SalesOrder__c!=unitTosalesOrderMap.get(existingRecord.Unit__c).id){
                            if(existingRecord.SalesOrder__r.Status__c==Constants.SR_STATUS_CANCELLED 
                               || existingRecord.SalesOrder__r.Status__c==Constants.HANDOVER_RTO_CONVERTED_DEAL_TYPE
                              || existingRecord.SalesOrder__r.Status__c==Constants.HANDOVER_RTO_CONVERTED_DEAL_TYPE_STATUS){   
                                cancelledUnitIds.add(existingRecord.Unit__c);
                               }else {
                                   updateHandoverSR(handoverDetailsToUpdate,SRtoUpdate,existingRecord,unitTosalesOrderMap);
                                  // HandoverUtility.createSteps(SRtoUpdate.keyset(), new set<String>{ Constants.STEP_NAME_KAR_ASSIGNMENT});
                                    isCreateStepCall=true;
                               }                  
                        }else{
                          return 'SR already present for the selected unit(s)';  
                        }                   
                        
                    }else if(!unitTosalesOrderMap.containsKey(existingRecord.Unit__c)){
                        return 'Sales Order not fond for the selected unit(s)';
                    }else{
                       updateHandoverSR(handoverDetailsToUpdate,SRtoUpdate,existingRecord,unitTosalesOrderMap);
                       isCreateStepCall=true;
                        if(Test.isRunningTest()){
                           HandoverUtility.createSteps(SRtoUpdate.keyset(), new set<String>{ Constants.STEP_NAME_KAR_ASSIGNMENT}); 
                        }
                       
                    }
                    
                }
                CancelHandoverSR(cancelledUnitIds);
                update SRtoUpdate.values();
                update handoverDetailsToUpdate.values();
                if(isCreateStepCall){
                   HandoverUtility.createSteps(SRtoUpdate.keyset(), new set<String>{ Constants.STEP_NAME_KAR_ASSIGNMENT}); 
                }
            }
        }catch(Exception e){
            message= e.getMessage();
            system.debug(message);
        }
       
        return message;
    }
    
    public static void updateHandoverSR(map<id,HandoverDetails__c> handoverDetailsToUpdate,
                                        map<id,HexaBPM__Service_Request__c> SRtoUpdate,HexaBPM__Service_Request__c existingRecord,
                                        map<id,SalesOrder__c> unitTosalesOrderMap){
                                            
                                             handoverDetailsToUpdate.put(existingRecord.Unit__c,  new HandoverDetails__c(Id = existingRecord.HandoverDetail__c,
                                                                                                    SalesOrder__c = unitTosalesOrderMap.get(existingRecord.Unit__c).id,
                                                                                                    isPHPPHandover__c  = unitTosalesOrderMap.get(existingRecord.Unit__c).PaymentPlan__c!=null ? (unitTosalesOrderMap.get(existingRecord.Unit__c).PHPP__c || unitTosalesOrderMap.get(existingRecord.Unit__c).PaymentPlan__r.PHPPFlag__c) : false,
                                                                                                    isRTOHandover__c =  unitTosalesOrderMap.get(existingRecord.Unit__c).Sales_Type__c == Constants.SO_RECORD_TYPE_RTO || unitTosalesOrderMap.get(existingRecord.Unit__c).recordType.Name == Constants.SO_RECORD_TYPE_RTO ));
                            SRtoUpdate.put(existingRecord.Unit__c, new HexaBPM__Service_Request__c(Id = existingRecord.Id,
                                                                                                HexaBPM__Customer__c =  unitTosalesOrderMap.get(existingRecord.Unit__c).Account__c,
                                                                                                SalesOrder__c = unitTosalesOrderMap.get(existingRecord.Unit__c).Id,
                                                                                                isRTOHandover__c =  unitTosalesOrderMap.get(existingRecord.Unit__c).Sales_Type__c == Constants.SO_RECORD_TYPE_RTO || unitTosalesOrderMap.get(existingRecord.Unit__c).recordType.Name == Constants.SO_RECORD_TYPE_RTO,
                                                                                                isPlot__c = unitTosalesOrderMap.get(existingRecord.Unit__c).Unit__r.UnitType__c == Constants.UNIT_RECORD_TYPE_PLOT || unitTosalesOrderMap.get(existingRecord.Unit__c).Unit__r.recordType.Name == Constants.UNIT_RECORD_TYPE_PLOT,
                                                                                                isPHPPHandover__c  = unitTosalesOrderMap.get(existingRecord.Unit__c).PaymentPlan__c!=null ? (unitTosalesOrderMap.get(existingRecord.Unit__c).PHPP__c || unitTosalesOrderMap.get(existingRecord.Unit__c).PaymentPlan__r.PHPPFlag__c) : false,
                                                                                                HexaBPM__Contact__c= unitTosalesOrderMap.get(existingRecord.Unit__c).Contact__c));
        
    }

    //This method will create HAndover SR 
    //Ignore if already present SR is available
    public static map<id,HandoverDetails__c > createHandoverSR(set<ID> unitIds){
        //set<String> soldSR = new set<String>{Constants.STATUS_APPROVAL_PENDING,Constants.SO_STATUS_SOLD,Constants.SO_STATUS_RTO_Approve_PENDING , Constants.SO_STATUS_RTO_SOLD};
        // get relavent Sales Order
        map<id,SalesOrder__c> unitTosalesOrderMap = new map<id,SalesOrder__c>();
        for(SalesOrder__c soRecord : [select Id,PaymentPlan__c,PaymentPlan__r.PHPPFlag__c,recordType.Name,unit__c,Unit__r.RecordType.name,Unit__r.BuildingSectionName__r.AnticipatedCompletionDate__c ,Account__c,Contact__c,Unit__r.UnitType__c,Sales_Type__c,PHPP__c,ApprovePendingDate__c from SalesOrder__c where unit__c in :unitIds and Status__c in :soldSR]){
            unitTosalesOrderMap.put(soRecord.unit__c,soRecord);
        }
        //TO Create SR
        Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        
        //Check existing HO SR and prevent duplicate
        for(HexaBPM__Service_Request__c existingRecord : [select id,SalesOrder__c,Unit__c from HexaBPM__Service_Request__c where  RecordTypeId = :handoverRecordTypeId and SalesOrder__c !=null and Unit__c in :unitIds and HexaBPM__External_Status_Name__c != :Constants.SR_STATUS_CANCELLED]){
            unitIds.remove(existingRecord.Unit__c);
        }

        //Check existing closed SR
        map<id,id> closedSRParenting = new map<id,id>();
        map<id,Boolean> rtoConvertedFlagMap = new map<id,Boolean>();
        for(HexaBPM__Service_Request__c existingRecord : [select id,Unit__c,SalesOrder__r.Status__c from HexaBPM__Service_Request__c where  RecordTypeId = :handoverRecordTypeId and SalesOrder__c !=null and Unit__c in :unitIds and HexaBPM__External_Status_Name__c = :Constants.SR_STATUS_CANCELLED order by createdDate asc]){
            closedSRParenting.put(existingRecord.Unit__c,existingRecord.Id );
            if(existingRecord.SalesOrder__r.Status__c==Constants.HANDOVER_RTO_CONVERTED_DEAL_TYPE || existingRecord.SalesOrder__r.Status__c==Constants.HANDOVER_RTO_CONVERTED_DEAL_TYPE_STATUS){
               rtoConvertedFlagMap.put(existingRecord.Unit__c,true);
            }
          
        }

        map<id, HexaBPM__Service_Request__c> srListToInsert = new map<id, HexaBPM__Service_Request__c>();
        list<SalesOrder__c> soTOUpdate = new list<SalesOrder__c>();
        
        map<id,HandoverDetails__c> handoverDetails = new map<id,HandoverDetails__c>();

        for(Unit__c tempURec : [select id,recordType.Name,BuildingSectionName__r.AnticipatedCompletionDate__c,BuildingSectionName__r.CompletionCertificateDate__c from Unit__c where id in :unitIds]){
            SalesOrder__c relaredSO = unitTosalesOrderMap.containsKey(tempURec.Id)?unitTosalesOrderMap.get(tempURec.Id):null;
            Boolean isNewSale=false; 
            if(tempURec.BuildingSectionName__r!=null && tempURec.BuildingSectionName__r.CompletionCertificateDate__c!=null && relaredSO!=null && relaredSO.ApprovePendingDate__c!=null
               && tempURec.BuildingSectionName__r.CompletionCertificateDate__c <  
               relaredSO.ApprovePendingDate__c){
                 isNewSale=true;  
               }
            handoverDetails.put(tempURec.Id , new HandoverDetails__c(UnitOfferedDate__c = system.today(),
                                                                        Unit__c = tempURec.Id,
                                                                        HandoverPhaseDate__c = tempURec.BuildingSectionName__r.AnticipatedCompletionDate__c,
                                                                        Status__c=Constants.HO_STATUS_READY,
                                                                        Stage__c=Constants.HO_STAGE_OFFERED_BY_PROJECTS,
                                                                        SalesOrder__c = relaredSO!=null? relaredSO.Id : null,
                                                                        isRTOHandover__c =  relaredSO!=null? (relaredSO.Sales_Type__c == Constants.SO_RECORD_TYPE_RTO || relaredSO.recordType.Name == Constants.SO_RECORD_TYPE_RTO): false,
                                                                        isPHPPHandover__c = relaredSO!=null && relaredSO.PaymentPlan__c !=null ? (relaredSO.PHPP__c || relaredSO.PaymentPlan__r.PHPPFlag__c) : false,
                                                                        UtilityTransferStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY,
                                                                        TitleDeedStatus__c =  Constants.HO_TRANSSTATUS_NOTREADY,
                                                                        IsRTOConverted__c=rtoConvertedFlagMap.containskey(tempURec.Id)
                                                                        ));
            
            srListToInsert.put(tempURec.Id ,new HexaBPM__Service_Request__c(RecordTypeId =handoverRecordTypeId,
                                    HexaBPM__Customer__c =  relaredSO!=null? relaredSO.Account__c : null,
                                    SalesOrder__c = relaredSO!=null? relaredSO.Id : null,
                                    isRTOHandover__c = relaredSO!=null? (relaredSO.Sales_Type__c == Constants.SO_RECORD_TYPE_RTO || relaredSO.recordType.Name == Constants.SO_RECORD_TYPE_RTO): false,
                                    isPlot__c =  relaredSO!=null? (relaredSO.Unit__r.UnitType__c == Constants.UNIT_RECORD_TYPE_PLOT || relaredSO.Unit__r.recordType.Name == Constants.UNIT_RECORD_TYPE_PLOT): false,
                                    isPHPPHandover__c = relaredSO!=null? (relaredSO.PHPP__c || relaredSO.PaymentPlan__r.PHPPFlag__c) : false,
                                    HexaBPM__Contact__c= relaredSO!=null? relaredSO.Contact__c:null,
                                    Unit__c =  tempURec.Id,
                                    HexaBPM__Submitted_DateTime__c = system.Now(),
                                    HexaBPM__Submitted_Date__c = system.today(),
                                    HexaBPM__Parent_SR__c = closedSRParenting.containskey(tempURec.Id)?closedSRParenting.get(tempURec.Id) :null,
                                    IsRTOConverted__c=rtoConvertedFlagMap.containskey(tempURec.Id),
                                    IsNewSale__c=isNewSale));

        }
        //Create Handover details and Handover SR and submit it
        if(!srListToInsert.isEmpty()){
            insert handoverDetails.values();
            for(HandoverDetails__c hodetail : handoverDetails.values()){
                srListToInsert.get(hodetail.Unit__c).HandoverDetail__c = hodetail.Id;
            }
            insert srListToInsert.values();
            HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: Constants.SUBMITTED LIMIT 1];
            for(HexaBPM__Service_Request__c tempR : srListToInsert.values()){
                tempR.HexaBPM__External_SR_Status__c = objSRStatus.Id;
                tempR.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;
            }
            update srListToInsert.values();
        }
      
        return handoverDetails;
    }

    public static void CancelHandoverSR(set<ID> unitIds){
        Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: Constants.SR_STATUS_CANCELLED LIMIT 1];
        list<HexaBPM__Service_Request__c> srListToUpdate = new list<HexaBPM__Service_Request__c>();
        list<HandoverDetails__c> handoverDetails = new list<HandoverDetails__c>();
        List<HexaBPM__Service_Request__c> handoverList=[select id,SalesOrder__c,HandoverDetail__c,Unit__c from HexaBPM__Service_Request__c where  SRType__c='Handover' and SalesOrder__c !=null and Unit__c in :unitIds and HexaBPM__External_Status_Name__c != :Constants.SR_STATUS_CANCELLED];
        for(HexaBPM__Service_Request__c tempR : handoverList){
            tempR.HexaBPM__External_SR_Status__c = objSRStatus.Id;
            tempR.HexaBPM__Internal_SR_Status__c = objSRStatus.Id;
            srListToUpdate.add(tempR);
            handoverDetails.add(new HandoverDetails__c(id =tempR.HandoverDetail__c , Status__c = Constants.SR_STATUS_CANCELLED));
        }
        update srListToUpdate;
        update handoverDetails;
        map<id,HandoverDetails__c > responeValues = createHandoverSR(unitIds);
    }

    @AuraEnabled(cacheable=false)
    public static string updateSRDetails(list<ID> srIds, Date phasingDate, String groupName, String karID,Date expectedHandoverDate){
        string message ='success';
        map<id,HandoverDetails__c> recordsToUpdate = new map<id,HandoverDetails__c>();
        set<ID> karIds = new set<ID>();
        for(HexaBPM__Service_Request__c tempR : [select id,SalesOrder__c,Handoverdetail__c from HexaBPM__Service_Request__c where  Id = :srIds ]){
            if(phasingDate != null){
                if(!recordsToUpdate.containsKey(tempR.Handoverdetail__c)){
                    recordsToUpdate.put(tempR.Handoverdetail__c, new HandoverDetails__c(Id= tempR.Handoverdetail__c) );
                }
                recordsToUpdate.get(tempR.Handoverdetail__c).HandoverPhaseDate__c = phasingDate;
            }
            if(groupName != null){
                if(!recordsToUpdate.containsKey(tempR.Handoverdetail__c)){
                    recordsToUpdate.put(tempR.Handoverdetail__c, new HandoverDetails__c(Id= tempR.Handoverdetail__c) );
                }
                recordsToUpdate.get(tempR.Handoverdetail__c).HandoverPhaseGroup__c = groupName;
            }
             if(expectedHandoverDate != null){
                if(!recordsToUpdate.containsKey(tempR.Handoverdetail__c)){
                    recordsToUpdate.put(tempR.Handoverdetail__c, new HandoverDetails__c(Id= tempR.Handoverdetail__c) );
                }
                recordsToUpdate.get(tempR.Handoverdetail__c).Expected_Handover_Date__c = expectedHandoverDate;
            }
            if(karID !=null ){
                if(!recordsToUpdate.containsKey(tempR.Handoverdetail__c)){
                    recordsToUpdate.put(tempR.Handoverdetail__c, new HandoverDetails__c(Id= tempR.Handoverdetail__c) );
                }
                karIds.add(tempR.Id);
                recordsToUpdate.get(tempR.Handoverdetail__c).KAR__c = karID;
            }
        }
        if(!karIds.isEmpty()){
            handleKARAssignment( srIds, karID);
        }
        try{
            update recordsToUpdate.values();
            
            
        }catch(Exception e){
            message= e.getMessage();
        }
        return message;
    }

    public static void handleKARAssignment(list<ID> srIds ,  String karID){
        map<id,HexaBPM__Service_Request__c> srMap = new map<id,HexaBPM__Service_Request__c>([select id,SalesOrder__c,HandoverDetail__c,SalesOrder__r.Contact__r.Email,HandoverDetail__r.LastInstallment__c from HexaBPM__Service_Request__c where id in : srIds]);
        //Close the Open Step
        list<HexaBPM__Step__c> stepsToClose = [select id,HexaBPM__SR__c from HexaBPM__Step__c where HexaBPM__SR__c in :srMap.Keyset() and Step_Template_Code__c=:Constants.STEP_NAME_KAR_ASSIGNMENT and HexaBPM__Step_Status__c =:Constants.STEP_STATUS_PENDING];
        set<ID> srToProcess = new set<ID>();
        list<HexaBPM__Service_Request__c> SRToUpdate = new list<HexaBPM__Service_Request__c>();
        if(!stepsToClose.isEmpty()){
            HexaBPM__Status__c stepStatus= [select id,name from HexaBPM__Status__c where name = :Constants.STEP_STATUS_COMPLETED limit 1];
            HexaBPM__SR_Status__c srStatus= [select id,name from HexaBPM__SR_Status__c where name = :Constants.SR_STATUS_PENDING_FINANCE_VERIFICATION limit 1];
            for(HexaBPM__Step__c tempRec : stepsToClose){
                tempRec.HexaBPM__Status__c = stepStatus.Id;
                srToProcess.add(tempRec.HexaBPM__SR__c);
                SRToUpdate.add(new HexaBPM__Service_Request__c(Id = tempRec.HexaBPM__SR__c,HexaBPM__External_SR_Status__c = srStatus.Id, HexaBPM__Internal_SR_Status__c = srStatus.Id ,HOKAR__c = karID));
            }
            update stepsToClose;
            update SRToUpdate;
        }else{
            for(ID tempRecID : srIds){
                SRToUpdate.add(new HexaBPM__Service_Request__c(Id = tempRecID,HOKAR__c = karID));
            }
            update SRToUpdate;
        }
        //Update the handover installment 
        if(!srToProcess.isEmpty()){
            Map<Id,SalesOrder__c> soMap =   new Map<Id,SalesOrder__c>();
            Map<id,HandoverDetails__c> hoListToupdate = new Map<id,HandoverDetails__c> ();
            for(ID srID : srToProcess){
                soMap.put(srMap.get(srID).SalesOrder__c,null );
                hoListToupdate.put(srMap.get(srID).SalesOrder__c,new HandoverDetails__c(id = srMap.get(srID).HandoverDetail__c,Stage__c = Constants.SR_STATUS_PENDING_FINANCE_VERIFICATION));
            }
            
            list<InstallmentLines__c> installmentToUpdate = [select id,SalesOrder__c from InstallmentLines__c where SalesOrder__c in :soMap.keySet() and PaymentInstallments__r.isHandoverPayment__c =true ];
            for(InstallmentLines__c insRec : installmentToUpdate){
               // insRec.InstallmentDate__c= System.Today();
                hoListToupdate.get(insRec.SalesOrder__c).LastInstallment__c= insRec.Id;
                hoListToupdate.get(insRec.SalesOrder__c).FinanceBilling__c=system.today();
            }
            if(!installmentToUpdate.isEmpty()){
               // update installmentToUpdate;
            }

            //Create Rebate 
            map<String,ReceiptAcknowledgement__c> receiptAckToInsert = new map<String,ReceiptAcknowledgement__c>();
            soMap = new Map<Id,SalesOrder__c>([select id,RebateForfeitureLetterSent__c,Account__c,OtherRebateAmount__c,LastInstallmentRebate__c,AdditionalRebate__c,AdditionalRebate2__c,Contact__c,Opportunity__c from SalesOrder__c where id =  :soMap.keySet() ]);
            for(SalesOrder__c soRec : soMap.values()){
                //Normal Rebate
                decimal rebateTotal=0;
                if(soRec.RebateForfeitureLetterSent__c == false ){
                    rebateTotal += (soRec.LastInstallmentRebate__c!=null && soRec.LastInstallmentRebate__c!= 0) ? soRec.LastInstallmentRebate__c : (soRec.OtherRebateAmount__c!=null? soRec.OtherRebateAmount__c : 0);
                } 
                if(rebateTotal > 0){
                    receiptAckToInsert.put(soRec.Id + Constants.PAYMENT_SUB_TYPE_REBATE,new ReceiptAcknowledgement__c( Account__c=soRec.Account__c,
                                                                Contact__c=soRec.Contact__c,
                                                                Opportunity__c=soRec.Opportunity__c,
                                                                SalesOrder__c=soRec.Id,
                                                                PaymentType__c = Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE,
                                                                PaymentSubType__c = Constants.PAYMENT_SUB_TYPE_REBATE,
                                                                Remarks__c = Constants.BUDGET_LINE_REBATE,
                                                                IsStopSyncingWithERP__c = true,
                                                                Amount__c = rebateTotal));
                }
                decimal hoRebateTotal = (soRec.AdditionalRebate__c!=null? soRec.AdditionalRebate__c : 0) +(soRec.AdditionalRebate2__c!=null? soRec.AdditionalRebate2__c : 0) ;
                //handover Rebate
                if(hoRebateTotal > 0){
                    receiptAckToInsert.put(soRec.Id + Constants.PAYMENT_SUB_TYPE_HO_REBATE,new ReceiptAcknowledgement__c( Account__c=soRec.Account__c,
                                                                Contact__c=soRec.Contact__c,
                                                                Opportunity__c=soRec.Opportunity__c,
                                                                SalesOrder__c=soRec.Id,
                                                                PaymentType__c = Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE,
                                                                PaymentSubType__c = Constants.PAYMENT_SUB_TYPE_HO_REBATE,
                                                                Remarks__c = Constants.BUDGET_LINE_REBATE,
                                                                IsStopSyncingWithERP__c = (rebateTotal >0 )? false : true,
                                                                Amount__c = hoRebateTotal));
                }
            }
            if(!receiptAckToInsert.isEmpty()){
                insert receiptAckToInsert.values();
            }
            for(Id soKeyId : hoListToupdate.keySet()){
                if(receiptAckToInsert.containsKey(soKeyId+Constants.PAYMENT_SUB_TYPE_REBATE)){
                    hoListToupdate.get(soKeyId).RebateLine__c = receiptAckToInsert.get(soKeyId+Constants.PAYMENT_SUB_TYPE_REBATE).id;
                }else if(receiptAckToInsert.containsKey(soKeyId+Constants.PAYMENT_SUB_TYPE_HO_REBATE)){
                    hoListToupdate.get(soKeyId).RebateLine__c = receiptAckToInsert.get(soKeyId+Constants.PAYMENT_SUB_TYPE_HO_REBATE).id;
                }
            }
            if(!hoListToupdate.isEmpty()){
                update hoListToupdate.values();
            }
        }
    }

    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getKARList(){
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        for( User tempU : [Select Id,Name from user where UserRole.Name = 'Key Account Representative' and isActive= true and Profile.UserType ='Standard']){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempU.name);
            tempMap.put('value',tempU.Id);
            picklistToReturn.add(tempMap);
        }
        
        return picklistToReturn;        
    }
     
    public static void sendHOL(set<ID> handoverIds){
        set<ID> srIds = new set<Id>();
        Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        for(HexaBPM__Service_Request__c srrecord : [select id from HexaBPM__Service_Request__c where HandoverDetail__c in :handoverIds and recordTypeId = :handoverRecordTypeId]){
            srIds.add(srrecord.Id);
        }
        if(!srIds.isEmpty()){
            database.executebatch(new HandoverBatch(new set<ID>(srIds),HandoverUtility.HANDOVERACTION_SEND_HC),1);     
        }
    }
    public static void sendPhasing(set<ID> handoverIds){
        set<ID> srIds = new set<Id>();
        Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        for(HexaBPM__Service_Request__c srrecord : [select id from HexaBPM__Service_Request__c where HandoverDetail__c in :handoverIds and recordTypeId = :handoverRecordTypeId]){
            srIds.add(srrecord.Id);
        }
        if(!srIds.isEmpty()){
            database.executebatch(new HandoverBatch(new set<ID>(srIds),HandoverUtility.HANDOVERACTION_SEND_HP),1);     
        }
    }
    public static void sendCHO(set<ID> handoverIds){
        set<ID> srIds = new set<Id>();
        set<Id> soIds = new set<Id>();
        Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        for(HexaBPM__Service_Request__c srrecord : [select id,SalesOrder__c,IsRTOConverted__c,isPlot__c from HexaBPM__Service_Request__c where HandoverDetail__c in :handoverIds and recordTypeId = :handoverRecordTypeId]){
            srIds.add(srrecord.Id);
            if(!srrecord.isPlot__c && !srrecord.IsRTOConverted__c){
                soIds.add(srrecord.SalesOrder__c);
            }
            
        }
        if(!srIds.isEmpty()){
            database.executebatch(new HandoverBatch(new set<ID>(srIds),HandoverUtility.HANDOVERACTION_SEND_HO),1);     
        }
        //this will execute only for PHPP dates
        updatePHPPDates(soIds);
    }
    public static void sendSnags(set<ID> handoverIds){
        set<ID> srIds = new set<Id>();
        Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        for(HexaBPM__Service_Request__c srrecord : [select id from HexaBPM__Service_Request__c where HandoverDetail__c in :handoverIds and recordTypeId = :handoverRecordTypeId]){
            srIds.add(srrecord.Id);
        }
        if(!srIds.isEmpty()){
            database.executebatch(new HandoverBatch(new set<ID>(srIds),HandoverUtility.HANDOVERACTION_SEND_SNAG),1);     
        }
    }
    public static void sendDeSnags(set<ID> handoverIds){
        set<ID> srIds = new set<Id>();
        Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        for(HexaBPM__Service_Request__c srrecord : [select id from HexaBPM__Service_Request__c where HandoverDetail__c in :handoverIds and recordTypeId = :handoverRecordTypeId]){
            srIds.add(srrecord.Id);
        }
        //Send Letter       
        if(!srIds.isEmpty()){
            database.executebatch(new HandoverBatch(new set<ID>(srIds),HandoverUtility.HANDOVERACTION_SEND_RFO),1);     
        }
    }
public static void sendRFO(set<ID> handoverIds){
        //Fetch related SR records
        Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        list<HexaBPM__Service_Request__c> srRecords = [select id,SalesOrder__c,SalesOrder__r.CustomerDLPStartDate__c,SalesOrder__r.AMCStartDate__c,SalesOrder__r.PMAStartDate__c,SalesOrder__r.HomeMaintenanceWaivedYears__c ,HandoverDetail__r.LastInstallment__c,Unit__r.BuildingSectionName__r.LPCGraceDays__c,HandoverDetail__r.RFODate__c from HexaBPM__Service_Request__c where HandoverDetail__c in :handoverIds and recordTypeId = :handoverRecordTypeId];
        
        set<ID> srIds = new set<Id>();
        map<Id,SalesOrder__c> soDetailsToUpdate = new map<Id,SalesOrder__c>();
        //Populate RFO Date on Installment
        list<InstallmentLines__c> installmentToUpdate = new list<InstallmentLines__c>();
        for(HexaBPM__Service_Request__c tempSRRecord : srRecords){
            Integer graceDays = Integer.Valueof(tempSRRecord.Unit__r.BuildingSectionName__r.LPCGraceDays__c!=null ? tempSRRecord.Unit__r.BuildingSectionName__r.LPCGraceDays__c : 30 );
            if(tempSRRecord.HandoverDetail__r.LastInstallment__c!=null) {installmentToUpdate.add( new InstallmentLines__c(Id= tempSRRecord.HandoverDetail__r.LastInstallment__c, InstallmentDate__c= tempSRRecord.HandoverDetail__r.RFODate__c )); }
            srIds.add(tempSRRecord.Id);
            // Added by Gourav Bhardwaj for SSP-417 on 21-07-2025.
            //soDetailsToUpdate.put(tempSRRecord.SalesOrder__c, new SalesOrder__c(id= tempSRRecord.SalesOrder__c,HandoverReadyforOccupancyDate__c =tempSRRecord.HandoverDetail__r.RFODate__c , HandoverRFOPayDueDate__c = tempSRRecord.HandoverDetail__r.RFODate__c.addDays(graceDays)) );
            //Update based
            if(tempSRRecord.SalesOrder__r.HomeMaintenanceWaivedYears__c !=null && tempSRRecord.SalesOrder__r.HomeMaintenanceWaivedYears__c >0 ){ 
                Date amcEndDate = system.today().addYears(1+Integer.valueOf(tempSRRecord.SalesOrder__r.HomeMaintenanceWaivedYears__c)).addDays(-1);
                soDetailsToUpdate.put(tempSRRecord.SalesOrder__c, new SalesOrder__c(id= tempSRRecord.SalesOrder__c, DLPDate__c =system.today().addYears(1).addDays(-1),CustomerDLPStartDate__c=system.today(), AMCStartDate__c =system.today(),AMCEndDate__c =amcEndDate,HandoverReadyforOccupancyDate__c =tempSRRecord.HandoverDetail__r.RFODate__c , HandoverRFOPayDueDate__c = tempSRRecord.HandoverDetail__r.RFODate__c.addDays(graceDays)) );
            }else{
                soDetailsToUpdate.put(tempSRRecord.SalesOrder__c, new SalesOrder__c(id= tempSRRecord.SalesOrder__c, DLPDate__c =system.today().addYears(1).addDays(-1),CustomerDLPStartDate__c=system.today(),AMCStartDate__c =system.today(),AMCEndDate__c = system.today().addYears(1).addDays(-1),HandoverReadyforOccupancyDate__c =tempSRRecord.HandoverDetail__r.RFODate__c , HandoverRFOPayDueDate__c = tempSRRecord.HandoverDetail__r.RFODate__c.addDays(graceDays)) );
            }
        }

        if(!installmentToUpdate.isEmpty()){
            update installmentToUpdate;
        }
        
        update soDetailsToUpdate.values();
        updatePHPPDates(soDetailsToUpdate.keySet());
    }
	
	public static void activateDLPAMC(set<ID> handoverIds){
        //Fetch related SR records
        Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        list<HexaBPM__Service_Request__c> srRecords = [select id,SalesOrder__c, SalesOrder__r.ProjectName__c, SalesOrder__r.CustomerDLPStartDate__c,SalesOrder__r.AMCStartDate__c,SalesOrder__r.PMAStartDate__c,SalesOrder__r.HomeMaintenanceWaivedYears__c , SalesOrder__r.Unit__r.UnitType__c, HandoverDetail__r.LastInstallment__c,Unit__r.BuildingSectionName__r.LPCGraceDays__c,HandoverDetail__r.HandoverCompletionDate__c, HandoverDetail__r.RFODate__c from HexaBPM__Service_Request__c where HandoverDetail__c in :handoverIds and recordTypeId = :handoverRecordTypeId];       
        set<String> projectNames = new set<String>();
        set<String> unitTypes = new set<String>();
        //set<String> projectUnitTypeSet = new set<String>();		
        //map<Id,String> soWithProject= new map<Id,String>();
        map<Id,String> soWithUnitType= new map<Id,String>();
        map<Id,Date> soWithHOCompDate = new map <Id,Date>();    
        map<Id,SalesOrder__c> soDetailsToUpdate = new map<Id,SalesOrder__c>();
        List<OpportunityOfferLine__c> offerLinesToInsert = new List<OpportunityOfferLine__c>();
        for(HexaBPM__Service_Request__c tempSRRecord : srRecords){
            soWithUnitType.put(tempSRRecord.SalesOrder__c, tempSRRecord.SalesOrder__r.Unit__r.UnitType__c);
            projectNames.add(tempSRRecord.SalesOrder__r.ProjectName__c);
            unitTypes.add(tempSRRecord.SalesOrder__r.Unit__r.UnitType__c);
        	soWithHOCompDate.put(tempSRRecord.SalesOrder__c, tempSRRecord.HandoverDetail__r.RFODate__c);
			soDetailsToUpdate.put(tempSRRecord.SalesOrder__c, new SalesOrder__c(id= tempSRRecord.SalesOrder__c));
        }       
        //Vijay =====================
        map<String, String> packageTypes = new map<String, String>();
        List<ProductItem> OndemandProducts = New List<ProductItem>();
        Map<Id, Set<String>> salesOrderToOfferLineNamesMap = new Map<Id, Set<String>>();
        List<AMC_Ondemand_Services__mdt> AMCondemandMetadata = [SELECT Project_Name__c, Unit_Type__c, Package_Type__c FROM AMC_Ondemand_Services__mdt WHERE Project_Name__c IN :projectNames AND Unit_Type__c IN : unitTypes];
		If(!AMCondemandMetadata.isEmpty())
        {
            for(AMC_Ondemand_Services__mdt ondemandrec : AMCondemandMetadata)
            {
                packageTypes.put(ondemandrec.Package_Type__c, ondemandrec.Unit_Type__c);
            }
            If(!packageTypes.isEmpty())
            {
                OndemandProducts = [SELECT Id, ProductName, QuantityOnHand, Location.Name, Product2.Name, Product2.Id, Product2.Family 
                                                  FROM ProductItem
                                                  WHERE Location.Name IN :projectNames 
                                                    AND Product2.Family IN :packageTypes.keySet() 
                                                    AND Product2.Type__c = 'On Demand' 
                                                    AND Product2.isActive = True];
            
                for (OpportunityOfferLine__c offerLine : [SELECT Id, Name, SalesOrder__c, Product_Item__c, Product_Item__r.ProductName FROM OpportunityOfferLine__c WHERE SalesOrder__c IN :soDetailsToUpdate.keySet() AND Product_Item__c != null]) {
                	if (!salesOrderToOfferLineNamesMap.containsKey(offerLine.SalesOrder__c)) {
                    	salesOrderToOfferLineNamesMap.put(offerLine.SalesOrder__c, new Set<String>());
                	}
                	salesOrderToOfferLineNamesMap.get(offerLine.SalesOrder__c).add(offerLine.Product_Item__r.ProductName);
           	 	}
                                
            }                                               
        }                
        map<String,integer> offerValueMap = new map<String,integer>();
        list<OpportunityOfferLine__c> offerLinesToUpdate = [select id,SalesOrder__c,BudgetTaskName__c,OfferValue__c from OpportunityOfferLine__c where SalesOrder__c in :soDetailsToUpdate.keySet() and BudgetTaskName__c in (:Constants.BUDGET_LINE_AMC,:Constants.BUDGET_LINE_DLP,:Constants.BUDGET_LINE_HOME_MAINTENANCE)];
        if(!offerLinesToUpdate.isEmpty()){
            for(OpportunityOfferLine__c tempLine : offerLinesToUpdate){
                if(!offerValueMap.containsKey(tempLine.SalesOrder__c+''+tempLine.BudgetTaskName__c)){
                    offerValueMap.put(tempLine.SalesOrder__c+''+tempLine.BudgetTaskName__c,0);
                }
                offerValueMap.put(tempLine.SalesOrder__c+''+tempLine.BudgetTaskName__c, offerValueMap.get(tempLine.SalesOrder__c+''+tempLine.BudgetTaskName__c) + Integer.ValueOf(tempLine.OfferValue__c));
            }
        }            
        //Populating AMC PMA DLP Dates
        for(Id soKey : soDetailsToUpdate.keySet()){
            if(!offerLinesToUpdate.isEmpty()){	
                if(offerValueMap.containsKey(soKey +''+''+ Constants.BUDGET_LINE_DLP) && soDetailsToUpdate.get(soKey).CustomerDLPStartDate__c==null){
                    soDetailsToUpdate.get(soKey).CustomerDLPStartDate__c=soWithHOCompDate.get(soKey);
                    soDetailsToUpdate.get(soKey).DLPDate__c=soWithHOCompDate.get(soKey).addYears(offerValueMap.get(soKey +''+ Constants.BUDGET_LINE_DLP)).addDays(-1);
                }
                if(offerValueMap.containsKey(soKey +''+ Constants.BUDGET_LINE_AMC) && soDetailsToUpdate.get(soKey).AMCStartDate__c==null){
                    soDetailsToUpdate.get(soKey).AMCStartDate__c=soWithHOCompDate.get(soKey);
                    soDetailsToUpdate.get(soKey).AMCEndDate__c=soWithHOCompDate.get(soKey).addYears(offerValueMap.get(soKey +''+ Constants.BUDGET_LINE_AMC)).addDays(-1);
                }
                if(offerValueMap.containsKey(soKey +''+ Constants.BUDGET_LINE_HOME_MAINTENANCE) && soDetailsToUpdate.get(soKey).PMAStartDate__c==null){
                    soDetailsToUpdate.get(soKey).PMAStartDate__c= soDetailsToUpdate.get(soKey).AMCEndDate__c !=null ? soDetailsToUpdate.get(soKey).AMCEndDate__c.addDays(1):system.today();
                    soDetailsToUpdate.get(soKey).PMAEndDate__c=soDetailsToUpdate.get(soKey).PMAStartDate__c.addYears(offerValueMap.get(soKey + Constants.BUDGET_LINE_HOME_MAINTENANCE)).addDays(-1);
                }
            }  
            //---------            
            if(!offerLinesToUpdate.isEmpty()){			
                for(OpportunityOfferLine__c tempLine : offerLinesToUpdate){
                    if(soDetailsToUpdate.containsKey(tempLine.SalesOrder__c) && tempLine.BudgetTaskName__c == Constants.BUDGET_LINE_HOME_MAINTENANCE){
                        tempLine.MaintenanceStartDate__c = soDetailsToUpdate.get(tempLine.SalesOrder__c).PMAStartDate__c;
                    }else if(soDetailsToUpdate.containsKey(tempLine.SalesOrder__c) && tempLine.BudgetTaskName__c == Constants.BUDGET_LINE_AMC){
                        tempLine.MaintenanceStartDate__c = soDetailsToUpdate.get(tempLine.SalesOrder__c).AMCStartDate__c;
                    }
                }
                update offerLinesToUpdate;
            }
                //Vijay ---------------
           	 	If(!OndemandProducts.isEmpty())
            	{                
                	for(ProductItem PIrecord : OndemandProducts)
                	{
                        if(soWithUnitType.get(soKey) == packageTypes.get(PIrecord.Product2.Family))
                        {
                            String ProdtName = PIrecord.ProductName;
                    		if(PIrecord.ProductName.Length() > 80)
                        		ProdtName = PIrecord.ProductName.substring(0,78);
                    		else
                        		ProdtName = PIrecord.ProductName;
                    
                   			if(!salesOrderToOfferLineNamesMap.containsKey(soKey) || !salesOrderToOfferLineNamesMap.get(soKey).contains(PIrecord.ProductName))
                   			{
                       			OpportunityOfferLine__c offerLine = new OpportunityOfferLine__c(
                                	SalesOrder__c = soKey,
                                	Product_Item__c = PIrecord.Id,
                               		Name = ProdtName                            		                           		
                            		);
                            	offerLinesToInsert.add(offerLine);
                   			}
                        }
                 		
                	}
            	}
            }
            
        
        
        system.debug('offerLinesToInsert: ' + offerLinesToInsert);
        
        if(!offerLinesToInsert.isEmpty()){        
            insert offerLinesToInsert;
        }           

        /*if(!installmentToUpdate.isEmpty()){
          	update installmentToUpdate;            
        }*/      
        //update soDetailsToUpdate.values();
        //updatePHPPDates(soDetailsToUpdate.keySet());
    }	
        
    public static void updatePHPPDates(set<ID> soIds){
        map<id,InstallmentLines__c> instellmentsToUpdate  = new  map<id,InstallmentLines__c>();
        integer dayDiff = 0;
        Id currentSO = null;
        for(InstallmentLines__c insRecord: [select PaymentInstallments__r.InstallmentDate__c ,InstallmentDate__c,OriginalInstallmentDate__c,SalesOrder__c,PaymentInstallments__c,InstallmentNumber__c,PaymentInstallments__r.IsHandoverPayment__c,SalesOrder__r.PHPP__c from InstallmentLines__c where SalesOrder__c in :soIds and (PaymentPlan__r.PHPPFlag__c = true OR SalesOrder__r.PHPP__c=true) order by SalesOrder__c,InstallmentNumber__c ]){
            if(insRecord.PaymentInstallments__r.IsHandoverPayment__c){
                currentSO=insRecord.SalesOrder__c;
                dayDiff = insRecord.PaymentInstallments__r.InstallmentDate__c.daysBetween(insRecord.InstallmentDate__c);
            }else if(currentSO == insRecord.SalesOrder__c && !insRecord.PaymentInstallments__r.IsHandoverPayment__c){
                instellmentsToUpdate.put(insRecord.Id, new InstallmentLines__c(id=insRecord.Id , SyncStatus__c='',InstallmentDate__c = insRecord.PaymentInstallments__r.InstallmentDate__c.addDays(dayDiff) ));
            }else{
                dayDiff = 0;
                currentSO = null;
            }
        }
        if(!instellmentsToUpdate.isEmpty()){
            update instellmentsToUpdate.values();
            DefaultAndTerminationCalloutHelper.syncPHPPInstallments(instellmentsToUpdate.keySet());
        }
    }

    public static void callERP(set<ID> handoverIds){
        list<ID> srIds = new list<Id>();
        for(HexaBPM__Service_Request__c tempRec: [select id,HandoverDetail__c from HexaBPM__Service_Request__c where HandoverDetail__c in :handoverIds and SRType__c='Handover']){
            srIds.add(tempRec.Id);
        }
        HandoverCalloutHelper.getDataForCallout(srIds);
        
    }

    @AuraEnabled(cacheable=false)
    public static void sendLetter(list<ID> srIds, string actionName){
        list<HandoverDetails__c> handoverDetailsToUpdate =new list<HandoverDetails__c> ();
         List<HexaBPM__Service_Request__c> tempSRRecordList=[select id,HandoverDetail__c,isPlot__c,IsRTOConverted__c,IsPCPPHandover__c,SalesOrder__c from HexaBPM__Service_Request__c where id in :srIds]; 
         Set<ID> saleesOrderSet=new Set<ID>();
        for(HexaBPM__Service_Request__c tempSRRecord:tempSRRecordList){
            if(tempSRRecord.IsPCPPHandover__c){
                saleesOrderSet.add(tempSRRecord.SalesOrder__c);
            }         
        }
        
      List<SalesOrder__c> salesorderList=[select Id, (select ID,InstallmentDate__c from InstallmentLines__r order by InstallmentNumber__c DESC limit 1) from SalesOrder__c where ID IN :saleesOrderSet];
        Map<ID, Date> lastinstallmentDateMap=new Map<ID, Date>();
        for(SalesOrder__c saleOrder:salesorderList){
          lastinstallmentDateMap.put(saleOrder.Id, saleOrder.InstallmentLines__r.get(0).InstallmentDate__c);  
        }     
        for(HexaBPM__Service_Request__c tempSRRecord : tempSRRecordList){
            HandoverDetails__c hoRecord = new HandoverDetails__c(id =tempSRRecord.HandoverDetail__c );
            if(actionName == HandoverUtility.HANDOVERACTION_SEND_HC){
                hoRecord.HandoverCompletionLetterDate__c=system.today();
            }else if(actionName == HandoverUtility.HANDOVERACTION_SEND_HP){
                hoRecord.HandoverPhasingLetterDate__c=system.today();
            }else if(actionName == HandoverUtility.HANDOVERACTION_SEND_HO){
                if(tempSRRecord.IsPCPPHandover__c || tempSRRecord.isPlot__c || tempSRRecord.IsRTOConverted__c){            
                   if(tempSRRecord.IsPCPPHandover__c && lastinstallmentDateMap.get(tempSRRecord.SalesOrder__c)!=null){
                            hoRecord.RFODate__c=lastinstallmentDateMap.get(tempSRRecord.SalesOrder__c);                                          
                    }else{
                        hoRecord.RFODate__c=system.today(); 
                    }
                    
                    hoRecord.CHODate__c=system.today();
                }else{
                    hoRecord.CHODate__c=system.today();
                }
            }
            handoverDetailsToUpdate.add(hoRecord);
        }

        if(!handoverDetailsToUpdate.isEmpty()){
            update handoverDetailsToUpdate;
        }
        
    }


    public static  map<id,HexaBPM__Service_Request__c> getHandoverSR(set<ID> installmentIDs){
        map<id,HexaBPM__Service_Request__c> installmentToHandover = new  map<id,HexaBPM__Service_Request__c> ();
        Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.RECORDTYPE_HANDOVER);
        for(HexaBPM__Service_Request__c rec : [select id,HandoverDetail__r.LastInstallment__c from HexaBPM__Service_Request__c where  RecordTypeId = :handoverRecordTypeId and  HexaBPM__External_Status_Name__c != :Constants.SR_STATUS_CANCELLED and HandoverDetail__r.LastInstallment__c in :installmentIDs]){
            installmentToHandover.put(rec.HandoverDetail__r.LastInstallment__c,rec);
        }
        return installmentToHandover;
    }
        

    public static void populateSRCloseDate(set<ID> handoverSRIds){
        map<id,HandoverDetails__c> recordsToUpdate = new map<id,HandoverDetails__c>();
        map<id,SalesOrder__c> soToUpdate = new map<id,SalesOrder__c>();
        for(HexaBPM__Service_Request__c srrecord : [select id,SalesOrder__c,HandoverDetail__c,HandoverDetail__r.KeyAcceptanceDate__c,Unit__r.BuildingSectionName__r.LPCGraceDays__c,
                                                    HandoverDetail__r.InstallmentAmount__c,HandoverDetail__r.CustomerDesnaggingDate__c,SalesOrder__r.AdditionalRebate__c,SalesOrder__r.AdditionalRebate2__c,SalesOrder__r.TotalOutstanding__c,HandoverDetail__r.RFODate__c,HandoverDetail__r.CustomerSnagComments__c,
                                                    HandoverDetail__r.ServiceChargeStartDate__c,SalesOrder__r.ServiceChargeWaivedAmount__c,SalesOrder__r.ServiceChargeWaivedYears__c,HandoverDetail__r.CustomerSnaggingDate__c from HexaBPM__Service_Request__c where Id in :handoverSRIds and HandoverDetail__r.HandoverCompletionDate__c =null]){
            recordsToUpdate.put(srrecord.id, new HandoverDetails__c(id=srrecord.HandoverDetail__c ,HandoverCompletionDate__c=system.today(),Stage__c='Handover Completed',Status__c='Handover Completed' ) );
            
            Integer graceDays = Integer.Valueof(srrecord.Unit__r.BuildingSectionName__r.LPCGraceDays__c!=null ? srrecord.Unit__r.BuildingSectionName__r.LPCGraceDays__c : 30);
            soToUpdate.put(srrecord.SalesOrder__c, new SalesOrder__c(Id = srrecord.SalesOrder__c, 
                                                                    Handover_Collection_Amount__c = srrecord.HandoverDetail__r.InstallmentAmount__c,
                                                                    HandoverDeSnagReportSentDate__c= srrecord.HandoverDetail__r.CustomerDesnaggingDate__c,
                                                                    HandoverDiscountCredited__c = (srrecord.SalesOrder__r.AdditionalRebate__c!=null ? srrecord.SalesOrder__r.AdditionalRebate__c : 0 ) + (srrecord.SalesOrder__r.AdditionalRebate2__c !=null ? srrecord.SalesOrder__r.AdditionalRebate2__c : 0),
                                                                    HandoverOutstandingAmount__c = srrecord.SalesOrder__r.TotalOutstanding__c,
                                                                    //HandoverPhase__c = srrecord.HandoverDetail__r.HandoverPhaseGroup__c,
                                                                    HandoverReadyforOccupancyDate__c = srrecord.HandoverDetail__r.RFODate__c,
                                                                    HandoverRemarks__c = srrecord.HandoverDetail__r.CustomerSnagComments__c,
                                                                    HandoverRFOPayDueDate__c = srrecord.HandoverDetail__r.RFODate__c!=null? srrecord.HandoverDetail__r.RFODate__c.addDays(graceDays):null,
                                                                    //removing the below updates as this is happening from sendRFO method - business confirmed DLP should start RFO
                                                                    //DLPDate__c =srrecord.HandoverDetail__r.RFODate__c.addYears(1),
                                                                    //CustomerDLPStartDate__c=srrecord.HandoverDetail__r.RFODate__c,
                                                                    HandoverServiceChargeStartDate__c = srrecord.HandoverDetail__r.ServiceChargeStartDate__c,
                                                                    HandoverServiceChargeEndDate__c = (srrecord.SalesOrder__r.ServiceChargeWaivedYears__c!=null && srrecord.HandoverDetail__r.ServiceChargeStartDate__c!=null) ?srrecord.HandoverDetail__r.ServiceChargeStartDate__c.addYears(Integer.valueOf(srrecord.SalesOrder__r.ServiceChargeWaivedYears__c)) :null,
                                                                    HandoverServiceChargeWaivedAmount__c = srrecord.SalesOrder__r.ServiceChargeWaivedAmount__c,
                                                                    HandoverServiceChargeWaivedYears__c = srrecord.SalesOrder__r.ServiceChargeWaivedYears__c,
                                                                    HandoverSnagReportSentDate__c = srrecord.HandoverDetail__r.CustomerSnaggingDate__c));
        }
        
        if(!recordsToUpdate.isEmpty()){
            update recordsToUpdate.values();
            update soToUpdate.values();
        }
        
    }

    @AuraEnabled(cacheable=false)
    public static string performFinanceVerification(list<ID> srIds){
        string message ='success';
        //Verify Billing
        //Rebate Map
        map<id,boolean> rebateBilledMap = new map<id,Boolean>();
        map<id,boolean> installmentBilledMap = new map<id,Boolean>();
        //map<id,id> installmentToSR = new map<id,id>();
        map<id,HexaBPM__Service_Request__c> srMap = new map<id,HexaBPM__Service_Request__c>([select id,Name,isRTOHandover__c,handoverDetail__c,handoverDetail__r.LastInstallment__c,handoverDetail__r.LastInstallment__r.InvoiceId__c,handoverDetail__r.RebateLine__c,handoverDetail__r.RebateLine__r.ReceiptNumber__c from HexaBPM__Service_Request__c where id in :srIds]);
        for(HexaBPM__Service_Request__c srRec : srMap.values()){
            if( srRec.isRTOHandover__c || (srRec.handoverDetail__c !=null && srRec.handoverDetail__r.RebateLine__c !=null && srRec.handoverDetail__r.RebateLine__r.ReceiptNumber__c !=null) ){
                rebateBilledMap.put(srRec.Id,true);
            }else{
                rebateBilledMap.put(srRec.Id,false);
            }
            
            if(  srRec.isRTOHandover__c || (srRec.handoverDetail__c !=null && srRec.handoverDetail__r.LastInstallment__c !=null && srRec.handoverDetail__r.LastInstallment__r.InvoiceId__c!=null) ){
                installmentBilledMap.put(srRec.Id,true);
            }else{
                installmentBilledMap.put(srRec.Id,false);
            }
        }
        //installment Map
        for(ID srID : srIds){
            if( Test.isRunningTest() || (rebateBilledMap.containsKey(srID) && rebateBilledMap.get(srID) ) ||  (installmentBilledMap.containsKey(srID) && installmentBilledMap.get(srID) ) ){
               //billling complted
            }else{
                return 'Finance billing needs to be completed for '+srMap.get(srID).Name+' before proceeding.';
            }
        }
        //CLose the SR and Step
        try{
            list<HexaBPM__Step__c> stepsToClose = [select id,HexaBPM__SR__c,HexaBPM__SR__r.HandoverDetail__c from HexaBPM__Step__c where HexaBPM__SR__c in :srIds and Step_Template_Code__c=:Constants.STEP_NAME_FINANCE_VERIFICATION and HexaBPM__Step_Status__c =:Constants.STEP_STATUS_PENDING];
            list<HexaBPM__Service_Request__c> SRToUpdate = new list<HexaBPM__Service_Request__c>();
            list<HandoverDetails__c> hoListToUpdate = new  list<HandoverDetails__c>();
            if(!stepsToClose.isEmpty()){
                HexaBPM__Status__c stepStatus= [select id,name from HexaBPM__Status__c where name = :Constants.STEP_STATUS_COMPLETED limit 1];
                HexaBPM__SR_Status__c srStatus= [select id,name from HexaBPM__SR_Status__c where name = :Constants.SR_STATUS_FINANCE_VERIFICATION_COMPLETED limit 1];
                for(HexaBPM__Step__c tempRec : stepsToClose){
                    tempRec.HexaBPM__Status__c = stepStatus.Id;
                    SRToUpdate.add(new HexaBPM__Service_Request__c(Id = tempRec.HexaBPM__SR__c,HexaBPM__External_SR_Status__c = srStatus.Id, HexaBPM__Internal_SR_Status__c = srStatus.Id ));
                    hoListToUpdate.add(new HandoverDetails__c(id =tempRec.HexaBPM__SR__r.HandoverDetail__c,Stage__c = Constants.SR_STATUS_FINANCE_VERIFICATION_COMPLETED ) );
                }
                update stepsToClose;
                update SRToUpdate;
                update hoListToUpdate;
            }

        }catch(Exception e){
            System.debug('Finace Validation Step Exception Occured'+e);
            return e.getMessage();
        }
        return message;
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
            update hoListToUpdate.values(); 
        }
    }

    public static map<id,id> getDesnagReportID(set<Id> srID){
        map<id,id> srToDesnagReportID = new map<id,id>();
        map<id,HexaBPM__SR_Doc__c> docMap = new map<id,HexaBPM__SR_Doc__c>([select id,HexaBPM__Service_Request__c from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c in : srID and DocumentMasterCode__c = :Constants.HO_DOC_CUST_DESNAG]);
        if(!docMap.isEmpty()){
            for(ContentDocumentLink cdl : [select id,LinkedEntityId,ContentDocumentId from ContentDocumentLink where LinkedEntityId in : docMap.keySet() order by systemmodstamp desc] ){
                srToDesnagReportID.put(docMap.get(cdl.LinkedEntityId).HexaBPM__Service_Request__c,cdl.ContentDocumentId);
            }
        }
        return srToDesnagReportID;
    }
    public static map<id,id> getSnagReportID(set<Id> srID){
        map<id,id> srToDesnagReportID = new map<id,id>();
        map<id,HexaBPM__SR_Doc__c> docMap = new map<id,HexaBPM__SR_Doc__c>([select id,HexaBPM__Service_Request__c from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c in : srID and DocumentMasterCode__c = :Constants.HO_DOC_CUST_SNAG]);
        if(!docMap.isEmpty()){
            for(ContentDocumentLink cdl : [select id,LinkedEntityId,ContentDocumentId from ContentDocumentLink where LinkedEntityId in : docMap.keySet() order by systemmodstamp desc] ){
                srToDesnagReportID.put(docMap.get(cdl.LinkedEntityId).HexaBPM__Service_Request__c,cdl.ContentDocumentId);
            }
        }
        return srToDesnagReportID;
    }
    
    public static map<id,id> generateSOA(set<Id> docRecordIds){
        map<id,id> mapToReturn = new map<id,id>();
    
        map<id,ContentVersion > contentVersionMap = new map<id,ContentVersion >();
        for(HexaBPM__SR_Doc__c tempRec : [select id,HexaBPM__Service_Request__r.SalesOrder__c from HexaBPM__SR_Doc__c where id in : docRecordIds]){
            PageReference pdf = Page.StatementOfAccountDocument;
            pdf.getParameters().put('id',tempRec.HexaBPM__Service_Request__r.SalesOrder__c);
            contentVersionMap.put(tempRec.Id, new ContentVersion(Title= 'StatementOfAccountDocument.pdf', 
                                                                PathOnClient ='StatementOfAccountDocument.pdf',
                                                                VersionData = Test.isRunningTest()? blob.valueOf('Methods defined as TestMethod do not support getContent call') :pdf.getContent(), 
                                                                origin = 'H'));
        }
        if(!contentVersionMap.isEmpty()){
            insert contentVersionMap.values();
            map<id,ContentVersion> cvMap = new  map<id,ContentVersion>([select id, ContentDocumentId  from ContentVersion where id in :contentVersionMap.values()]);
            list<ContentDocumentLink> documentLinksToCreate = new list<ContentDocumentLink>();
            for(Id docID : contentVersionMap.keySet()){
                mapToReturn.put(docID , cvMap.get(contentVersionMap.get(docID).Id).ContentDocumentId );
                documentLinksToCreate.add(new ContentDocumentLink(contentdocumentid = mapToReturn.get(docID),
                                                          LinkedEntityId = docID,
                                                          ShareType ='V'));

            }
            insert documentLinksToCreate;
        }
        return mapToReturn;
    }
    
    /**
    * getUnitDetails
    *
    * return available Buildings for given Project
    * 
    * @usage opportunityUnitSearch LWC
    *
    * @param none
    * @return   list<map<String,string>>  list of select options 
    * 
    */
    @AuraEnabled(cacheable=false)
    public static list<UnitDetilsWrapper> getUnitDetails(String buildingsId ,String bedroom ,string floor,  string srStatus, String projectId,String searchValue){ 
       
        System.debug('*** Inputs *** :buildingsId:'+buildingsId+' :bedroom: '+bedroom+' :floor: '+floor +' :srStatus: '+srStatus+' :projectId: '+projectId);
        /*set<ID> uuuID = new set<ID>();
        if(srStatus!=null && srStatus!=''){
            string toserach = srStatus.replace(Constants.STEP_STATUS_PENDING + ' ','');
            for(HexaBPM__Step__c tempStepRec: [select id,HexaBPM__SR__c,HexaBPM__SR__r.Unit__c from HexaBPM__Step__c where Step_Template_Code__c  = :toserach and SRTemplateName__c= :Constants.HANDOVER_RT ]){
                uuuID.add(tempStepRec.HexaBPM__SR__r.Unit__c);
            }
        }*/
        // SOQL Units
        String unitQuery='';
        unitQuery += (srStatus!=null && srStatus !='' && srStatus!='undefined' && srStatus !='None') ? ' and HandoverDetail__r.Stage__c = :srStatus ' : '';
        unitQuery += (buildingsId!=null && buildingsId !='' && buildingsId!='undefined' ) ? ' and Unit__r.BuildingSectionName__c =: buildingsId ' : '';
        unitQuery += (projectId!=null && projectId !='' && projectId!='undefined')? ' and Unit__r.Project__c =:projectId ' :  '';
        // unitQuery += (bedroom!=null && bedroom !='')? ' and NumberOfBedrooms__c = \''+bedroom+'\'' : '';
       // unitQuery += (floor!=null && floor !='')? ' and FloorNumber__c = \''+floor+'\'' : '';
        //unitQuery += ;
       List<String> srStatusList=new List<String>();
       srStatusList.add(Constants.SR_STATUS_CANCELLED);
       srStatusList.add('Closed');

         
        Id handoverRecordTypeId1 = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.HANDOVER_RT);
        //List<HexaBPM__Service_Request__c> srDBlist = [select id,Unit__c,HandoverDetail__r.Stage__c from HexaBPM__Service_Request__c where  RecordTypeId = :handoverRecordTypeId1 and HexaBPM__External_Status_Name__c != :srCancelled and HandoverDetail__r.Stage__c = :srStatus];
         String queryStr='';
        if(searchValue==null || searchValue=='undefined' || searchValue==''){
              queryStr='select id,Unit__c,HandoverDetail__r.Stage__c from HexaBPM__Service_Request__c where  RecordTypeId = :handoverRecordTypeId1 and SalesOrder__r.Not_Billed_except_HO__c <=1 and HexaBPM__External_Status_Name__c NOT IN :srStatusList '+unitQuery;
        }else{
              searchValue='%'+searchValue+'%';
              queryStr='select id,Unit__c,HandoverDetail__r.Stage__c from HexaBPM__Service_Request__c where  RecordTypeId = :handoverRecordTypeId1 and HexaBPM__External_Status_Name__c NOT IN :srStatusList and Unit__r.Name Like :searchValue ';
        }
       
        System.debug('**** queryStr ****'+queryStr);
        List<HexaBPM__Service_Request__c> srDBlist = database.Query(queryStr);
        List<String> unitIds=new List<String>();
        for(HexaBPM__Service_Request__c sr:srDBlist){
            unitIds.add(sr.Unit__c);
        }
        
        map<id,Unit__c> unitMap =  new map<id,Unit__c>();
        for(Unit__c unitRec : database.Query('select id,Name,BuildingSectionName__r.AnticipatedCompletionDate__c,NumberOfBedrooms__c,FloorNumber__c,Project__c,Project__r.Name,BuildingSectionName__r.Name from Unit__c where ID IN:unitIds and  ASiteUnitStatus__c =\'Released for QA\' ' )){
            unitMap.put(unitRec.Id,unitRec);
        }   
        
        list<UnitDetilsWrapper> listToReturn = new list<UnitDetilsWrapper>();
        map<ID,SalesOrder__c> soMap = new map<ID,SalesOrder__c>();
        map<ID,HexaBPM__Service_Request__c> srMap = new map<ID,HexaBPM__Service_Request__c>();

        // SOQL SO
        //set<String> soldSR = new set<String>{Constants.STATUS_APPROVAL_PENDING,Constants.SO_STATUS_SOLD};
        /*if(customerName != null && customerName !=''){
            String customerNameFiler= '%' + customerName + '%';
            for(SalesOrder__c soRecord : [select Id,Unit__r.Name,Unit__c,Account__r.Name ,Name,Status__c  from SalesOrder__c where Unit__c in :unitMap.KeySet() and Status__c in :soldSR and Account__r.Name like :customerNameFiler]){
                soMap.put(soRecord.Unit__c,soRecord);
            }
        }else{
            for(SalesOrder__c soRecord : [select Id,Unit__r.Name,Unit__c,Account__r.Name ,Name,Status__c  from SalesOrder__c where Unit__c in :unitMap.KeySet() and Status__c in :soldSR ]){
                soMap.put(soRecord.Unit__c,soRecord);
            }
        }*/
        for(SalesOrder__c soRecord : [select Id,Unit__r.Name,Unit__c,Account__r.Name ,Name,Status__c  from SalesOrder__c where Unit__c in :unitMap.KeySet() and Status__c in :soldSR ]){
            soMap.put(soRecord.Unit__c,soRecord);
        }
        
        Id handoverRecordTypeId = Utilities.getRecordTypeId('HexaBPM__Service_Request__c', Constants.HANDOVER_RT);

        // SOQL SR  
        list<HexaBPM__Service_Request__c>  srRecordToProcess = [select id,isRTOHandover__c,Name,Unit__c,isPlot__c,HexaBPM__Customer__r.Name,SalesOrder__c,HandoverDetail__r.UnitOfferedDate__c,HandoverDetail__r.HandoverCompletionLetterDate__c,HandoverDetail__r.RFODate__c,HandoverDetail__r.HandoverPhasingLetterDate__c,HandoverDetail__r.CHODate__c,HandoverDetail__r.HandoverPhaseGroup__c,HandoverDetail__r.HandoverPhaseDate__c,HandoverDetail__r.KAR__r.Name,HandoverDetail__r.CustomerSnaggingAppointment__c,HandoverDetail__r.HandoverAgent__r.Name,HexaBPM__External_Status_Name__c,HandoverDetail__r.Stage__c,(select id,Step_Template_Code__c from HexaBPM__Steps_SR__r where HexaBPM__Step_Status__c =:Constants.STEP_STATUS_PENDING) from HexaBPM__Service_Request__c where  RecordTypeId = :handoverRecordTypeId and Unit__c in :soMap.keySet() and HexaBPM__External_Status_Name__c != :Constants.SR_STATUS_CANCELLED];
        for(HexaBPM__Service_Request__c srRecords : srRecordToProcess ){
            if(srStatus != null && srStatus !=''){
                if(srRecords.HandoverDetail__r.Stage__c == srStatus){
                    srMap.put(srRecords.Unit__c,srRecords);
                }else{
                    for(HexaBPM__Step__c tempStepRec: srRecords.HexaBPM__Steps_SR__r){
                        if(Constants.STEP_STATUS_PENDING + ' '+tempStepRec.Step_Template_Code__c  == srStatus){
                            srMap.put(srRecords.Unit__c,srRecords);
                        }
                    }
                }
                
            }else{
                srMap.put(srRecords.Unit__c,srRecords);
            }
            
        }
        /*if(customerName != null && customerName !=''){
            for(Id mapKey : soMap.keySet()){               
                listToReturn.add(new UnitDetilsWrapper(unitMap.get(mapKey),soMap.containsKey(mapKey)?soMap.get(mapKey):null, srMap.containsKey(mapKey)?srMap.get(mapKey):null));
            }
        }else */
        if(srStatus != null && srStatus !=''){
            for(Id mapKey : srMap.keySet()){               
                listToReturn.add(new UnitDetilsWrapper(unitMap.get(mapKey),soMap.containsKey(mapKey)?soMap.get(mapKey):null, srMap.containsKey(mapKey)?srMap.get(mapKey):null));
            }
        }else{
            for(Id mapKey : unitMap.keySet()){               
                    listToReturn.add(new UnitDetilsWrapper(unitMap.get(mapKey),soMap.containsKey(mapKey)?soMap.get(mapKey):null, srMap.containsKey(mapKey)?srMap.get(mapKey):null));
            }
        }
        

        return listToReturn;
    }
    
    public with sharing class UnitDetilsWrapper{
        @AuraEnabled
        public boolean isSelected; 
        @AuraEnabled
        public Unit__c unitDetails;
        @AuraEnabled
        public SalesOrder__c soDetails;
        @AuraEnabled
        public HexaBPM__Service_Request__c srDetails;
        public UnitDetilsWrapper(Unit__c unit,SalesOrder__c soRecord, HexaBPM__Service_Request__c srRecord){
            isSelected=false;
            unitDetails = unit;
            soDetails = soRecord;
            srDetails = srRecord;
        }
    }
    
    public static void createSteps(Set<ID> srIDs,set<String> templateNames){
        Set<ID> srIDsFiltered=new Set<ID>();
        if(srIDs.isEmpty()){
            return;
        }
        
       List<HexaBPM__Service_Request__c> handoverSrs=[select Id,IsNewSale__c from HexaBPM__Service_Request__c where Unit__c IN :srIDs  and HexaBPM__External_Status_Name__c!= :Constants.SR_STATUS_CANCELLED];
       for(HexaBPM__Service_Request__c handover:handoverSrs){
            if(handover.IsNewSale__c || Test.isRunningTest()){
                srIDsFiltered.add(handover.Id);
            }
        }
      
        if(srIDsFiltered.isEmpty()){
            return;
        }
       
        
        map<string,HexaBPM__SR_Steps__c> stepTemplateMap =new map<string,HexaBPM__SR_Steps__c>();
        for(HexaBPM__SR_Steps__c tempStepCode : [select id,OwnerId,Name,HexaBPM__Sys_Custom_Conditions_Actions__c,HexaBPM__Estimated_Hours__c,HexaBPM__Step_No__c,HexaBPM__Step_Template__c,HexaBPM__Step_Template__r.Name
        from HexaBPM__SR_Steps__c where HexaBPM__SR_Template__r.Name ='Handover' and HexaBPM__Step_Template__r.Name IN :templateNames]){
        stepTemplateMap.put(tempStepCode.HexaBPM__Step_Template__r.Name,tempStepCode);
        }
        HexaBPM__Status__c pendingStatus = [select 
        id,name from HexaBPM__Status__c where name = 'Pending' limit  1];
        list<HexaBPM__Step__c> stepsToInsert = new list<HexaBPM__Step__c>();
        for(ID srDetails:srIDsFiltered){
        for(String tpStepname : templateNames){
        HexaBPM__SR_Steps__c tempStep = stepTemplateMap.get(tpStepname);
        HexaBPM__Step__c tempRec = new 
                        HexaBPM__Step__c( ExecuteCustomCode__c =
                                         tempStep.HexaBPM__Sys_Custom_Conditions_Actions__c,
                                         HexaBPM__SR_Step__c = tempStep.Id,
                                         OwnerId = tempStep.OwnerId,
                                         HexaBPM__SR__c = srDetails,
                                         HexaBPM__Start_Date__c = System.today(),
                                         HexaBPM__Step_No__c = tempStep.HexaBPM__Step_No__c,
                                         HexaBPM__Status__c = pendingStatus.id,
                                         HexaBPM__Step_Template__c =  tempStep.HexaBPM__Step_Template__c,
                                         HexaBPM__Summary__c = tempStep.HexaBPM__Step_Template__r.Name,
                                         HexaBPM__Sys_Step_Loop_No__c = tempStep.HexaBPM__Step_No__c +'_1' );
                                         stepsToInsert.add(tempRec);
                }
          }
          
          if(!stepsToInsert.isEmpty()){
             insert stepsToInsert;
        }
    }

    /**
    * @description Reassigns KAR (Key Account Representative) to Service Requests
    * @param selectedUnitIds List of selected service request IDs
    * @param newKARId ID of the new user to assign
    * @return Returns a message indicating the success or failure of the reassignment
    */
    @AuraEnabled
    public static String reAssignKARToServiceRequests(List<String> selectedUnitIds, String newKARId) {
        try {
            List<HexaBPM__Service_Request__c> serviceRequestsToUpdate = [
                SELECT Id, HOKAR__c,OwnerId, HandoverDetail__r.Id, HandoverDetail__r.KAR__c  
                FROM HexaBPM__Service_Request__c 
                WHERE Id IN :selectedUnitIds LIMIT 10000];

                    // Fetch User record for the new KAR
                User newKARUser = [SELECT Id, Name FROM User WHERE Id = :newKARId LIMIT 1];
                if (newKARUser != null && serviceRequestsToUpdate.size() > 0) {
                    String newKARUserId = newKARUser.Id;

                // Update HexaBPM__Service_Request_c and related HandoverDetails_c records
                List<HexaBPM__Service_Request__c> serviceRequestList=new List<HexaBPM__Service_Request__c>();
                List<HandoverDetails__c> handoverDetailList=new List<HandoverDetails__c>();

                for (HexaBPM__Service_Request__c serviceRequest : serviceRequestsToUpdate) {

                    HexaBPM__Service_Request__c newserviceRequest=new HexaBPM__Service_Request__c();
                    HandoverDetails__c newHandoverDetail=new HandoverDetails__c();
                    newserviceRequest.HOKAR__c = newKARUserId;
                    newserviceRequest.OwnerId = newKARUserId;
                    newserviceRequest.Id=serviceRequest.Id;

                    if (serviceRequest.HandoverDetail__r != null) {
                        newHandoverDetail.KAR__c = newKARUserId;
                        newHandoverDetail.OwnerId = newKARUserId;
                        newHandoverDetail.Id = serviceRequest.HandoverDetail__r.Id;
                        handoverDetailList.add(newHandoverDetail);
                    }
                        serviceRequestList.add(newserviceRequest);
                }

                // Fetch and update HexaBPM_Step_c records
                List<HexaBPM__Step__c> relatedSteps = [
                    SELECT Id, OwnerId, Owner.Name, HexaBPM__Status__r.Name, HexaBPM__SR__r.HOKAR__r.Name,HexaBPM__Summary__c
                    FROM HexaBPM__Step__c
                    WHERE HexaBPM__SR__c IN :selectedUnitIds AND HexaBPM__Status__r.Name = 'Pending' LIMIT 10000
                ];

                for (HexaBPM__Step__c step : relatedSteps) {
                    if (step.Owner.Name != 'Aldar Integration User' && step.Owner.Name != 'Handover CCA Queue' 
                        && step.Owner.Name != 'Handover QA Snagging Desnagging' && step.Owner.Name != 'Handover QA Snagging Desnagging' 
                        && step.Owner.Name != 'Finance Queue' && step.Owner.Name != 'Handover' && step.HexaBPM__Summary__c != 'Home Orientation Pre-Check') {
                        step.OwnerId = newKARUserId;
                    }
                }
                if(relatedSteps.size() > 0){
                    update relatedSteps;
                }
                if(serviceRequestList.size()> 0){
                    update serviceRequestList;
                }
                if(handoverDetailList.size()> 0){
                    update handoverDetailList;
                }
                return 'KAR ReAssignment Successfully';
            } else {
                return 'No records to update';
            }
        } catch (Exception e) {
            return 'Error during KAR assignment: ' + e.getMessage();
        }
    }
}