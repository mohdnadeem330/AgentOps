public with sharing class ServiceRequestTriggerHandler extends TriggerHandler{
    public static Boolean isSkipSrRequestTrigger = false; // Added by kuhinoor...
    /*ServiceChargeFee-Start*/
    private static Set<String> serviceChargeSRTypeUtilSet = new Set<String>{Constants.PAYMENT_EXTENSION_TYPE,Constants.PAYMENT_PLAN_CHANGE_RT,Constants.INVESTOR_CERTIFICATE_RT,Constants.LPC_WAIVER_TYPE,Constants.INVESTOR_CERT_LETTER_ISSUE,Constants.INVESTOR_CERT_ATTESTED_SPA};
        /*ServiceChargeFee-End*/
        
        //*** Before Insert Action***//
        /*public override void beforeInsertMethod(list<SObject> newList,Map<Id, SObject> newMap){
            
            updateSalesOrderAndCustomer(newList);
            checkSRAutomation(newList, null);
            
            List<HexaBPM__Service_Request__c> agencyRegSRList = new List<HexaBPM__Service_Request__c>();
            List<HexaBPM__Service_Request__c> serviceRequestList = new List<HexaBPM__Service_Request__c>();
            List<HexaBPM__Service_Request__c> serviceRequestGLList = new List<HexaBPM__Service_Request__c>();
            List<HexaBPM__Service_Request__c> srHandoverList = new List<HexaBPM__Service_Request__c>();
            List<HexaBPM__Service_Request__c> sList = new List<HexaBPM__Service_Request__c>();
            Set<Id> customerIdSet = new Set<Id>();
            List<Id> buyerIdList = new List<Id>();
            Map<Id,HexaBPM__Service_Request__c> goldenVisaAccountsIdsWithSR = new Map<Id,HexaBPM__Service_Request__c>();
            List<String> directDebitSaleOrder=new List<String>();
            List<String> directDebitAccount=new List<String>();
            
            // SR Resale Case Validation
            set<Id> ptunitIds = new set<Id>(); 
            set<Id> caseIds = new set<Id>();
            Id propertyTransferRecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Property Transfer').getRecordTypeId();
            Id propertyTransferNocRecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByName().get('Property Transfer NOC').getRecordTypeId();
            set<Id> propertyTransferRecIds = new set<Id>();
            propertyTransferRecIds.add(propertyTransferRecordTypeId);
            propertyTransferRecIds.add(propertyTransferNocRecordTypeId);
            
            //SS_DandT_Revamp_SP17-START
            Map<Id, String> custIdAndFlagType = new Map<Id, String>();
            Map<Id, String> soIdAndFlagType = new Map<Id, String>();
            //SS_DandT_Revamp_SP17-END
            
            //movein changes
            
            List<HexaBPM__Service_Request__c> moveInSRtoUpdateOwner = new list<HexaBPM__Service_Request__c>();
            List<HexaBPM__Service_Request__c> moveInSRtoUpdateOwnerList = new list<HexaBPM__Service_Request__c>();
            List<HexaBPM__Service_Request__c> srToUpdate = new List<HexaBPM__Service_Request__c>();
            Map<Id, List<Id>> queueIdToUserIds = new Map<Id, List<Id>>();
            Set<String> communityNames = new Set<String>();
            Set<Id> unitIds = new Set<Id>();
            for (HexaBPM__Service_Request__c sr : (List<HexaBPM__Service_Request__c>)newList) {
                if (sr.Unit__c != null) {
                    unitIds.add(sr.Unit__c);
                }
                if(sr.SRType__c =='Aldar Estates Move-In' && sr.Origin__c == null){
                	sr.Origin__c ='Salesforce';
                }
            }
            Map<Id, Unit__c> unitMap = new Map<Id, Unit__c>( [SELECT Id,Project__r.OA_Community_Name__c FROM Unit__c WHERE Id IN :unitIds] );
            
            for (HexaBPM__Service_Request__c newRecord: (List<HexaBPM__Service_Request__c>) newList) {
                
                // SR Resale Case Validation
                if(newRecord.Unit__c != null && propertyTransferRecIds.contains(newRecord.recordTypeId)){
                    //unitIds.add(sr.Unit__c);
                    ptunitIds.add(newRecord.Unit__c);
                    if(newRecord.Case__c!=null){
                        caseIds.add(newRecord.Case__c);
                    }                
                }
                
                //SS_DandT_Revamp_SP17-START
                soIdAndFlagType.put(newRecord.SalesOrder__c, '');
                custIdAndFlagType.put(newRecord.HexaBPM__Customer__c, '');
                //SS_DandT_Revamp_SP17-END
                
                if (newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PLOT_PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_NOC_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.INTERNAL_MORTGAGE_REGISTRATION_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.JOINT_OWNER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.JOINT_OWNER_NOC_DEV_RT) {
                    serviceRequestList.add(newRecord);
                }
                if (newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PLOT_PROPERTY_TRANSFER_DEV_RT) {
                    srHandoverList.add(newRecord);
                }
                
                if(newRecord.HexaBPM__Record_Type_Name__c == Constants.Golden_Visa_DEV_RT && newRecord.SRType__c == Constants.Golden_Visa_RT){
                    goldenVisaAccountsIdsWithSR.put(newRecord.HexaBPM__Customer__c, newRecord);
                }
                
                if (newRecord.HexaBPM__Record_Type_Name__c == Constants.PAYMENT_EXTENSION_DEV_RT) {
                    if(newRecord.InstallmentDate__c != null && newRecord.PaymentExtensionDate__c != null){
                        Integer monthDiff = newRecord.InstallmentDate__c.monthsBetween(newRecord.PaymentExtensionDate__c);
                        if (newRecord.PaymentExtensionDate__c.day() >= newRecord.InstallmentDate__c.day()) {
                            monthDiff++;
                        }
                        newRecord.PaymentExtensionPeriod__c = monthDiff;
                    }
                    
                    if(newRecord.SRType__c == Constants.CHEQUE_REPLACEMENT_SR_TYPE){
                        newRecord.HexaBPM__SR_Template__c = SRUtility.getSRTemplate(Constants.CHEQUE_REPLACEMENT_SR_TYPE);
                        
                    } else {
                        newRecord.HexaBPM__SR_Template__c = SRUtility.getSRTemplate(Constants.PAYMENT_EXTENSION_SR_TYPE);
                    }
                }
                
                if (newRecord.HexaBPM__Record_Type_Name__c == Constants.PAYMENT_PLAN_CHANGE_DEV_RT) {
                    if (newRecord.PaidEquity__c == 100) {
                        newRecord.addError(Utilities.getSystemMessages(Constants.PPC_PAID_EQUITY_100_VALIDATION).Message__c);
                    }
                }           
                
                //To Populate LPC Total, LPC Collected/Paid, LPC Waived and LPC Due
                if((newRecord.HexaBPM__Record_Type_Name__c == Constants.LPC_WAIVER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.TITLE_DEED_REGISTRATION_DEV_RT) && newRecord.SalesOrder__c != null){
                    LPCModel lpcDetail = LPCService.getOutstandingLPCforSalesOrder(newRecord.SalesOrder__c);
                    System.debug('**lpcDetail**'+ lpcDetail);
                    
                    newRecord.TotalLPCAmount__c = lpcDetail.totalLPC.setScale(2);
                    newRecord.TotalLPCDue__c = lpcDetail.totalLPCDue.setScale(2);
                    newRecord.TotalLPCCollected__c = lpcDetail.lpcPaid.setScale(2);
                    newRecord.ChargeCollected__c = newRecord.TotalLPCDue__c != null ? (newRecord.TotalLPCDue__c).setScale(2) : 0;
                    newRecord.TotalLPCWaivedAmount__c = lpcDetail.lpcWaivedAmount;
                    newRecord.LPCCalculatedDate__c = Date.today();
                    
                    if(newRecord.HexaBPM__Record_Type_Name__c == Constants.TITLE_DEED_REGISTRATION_DEV_RT){
                        newRecord.OldNetAmount__c = lpcDetail.orderDetail.NetAmount__c;
                        newRecord.TotalBilledAmount__c = lpcDetail.orderDetail.NetAmount__c - lpcDetail.orderDetail.TotalOutstanding__c;
                        newRecord.TotalOutstandingAmount__c = lpcDetail.orderDetail.TotalOutstanding__c;
                    }
                }
                if (newRecord.RefundAmount__c > 0 || newRecord.ReallocationAmount__c > 0) {
                    newRecord.IsRefundApplicable__c = true;
                }
                
                if (newRecord.HexaBPM__Record_Type_Name__c == Constants.Golden_Visa_DEV_RT) {
                    customerIdSet.add(newRecord.HexaBPM__Customer__c);
                    serviceRequestGLList.add(newRecord);
                }
                
                if (newRecord.BuyerName__c != null) {
                    buyerIdList.add(newRecord.BuyerName__c);
                }
                
                //Added by Tharun to update ReferredBy Profile Name - ASF-1367
                if (newRecord.HexaBPM__Record_Type_Name__c == ALD_Constants.Agency_Registration_DEV_RT && 
                    newRecord.ReferredBy__c != null &&
                    newRecord.ReferredBy__c != 'No Referral') {
                        agencyRegSRList.add(newRecord);
                    }
                if (newRecord.SRType__c == 'Aldar Estates Move-In' && unitMap.containsKey(newRecord.Unit__c) ){Unit__c unit = unitMap.get(newRecord.Unit__c);if (unit.Project__r != null && unit.Project__r.OA_Community_Name__c != null) {communityNames.add(unit.Project__r.OA_Community_Name__c);moveInSRtoUpdateOwner.add(newRecord);
                                                                                                                                                                                                                                          }
                                                                                                              }
                
                
            }
            
            //movein Changes
            if (!moveInSRtoUpdateOwner.isEmpty() || Test.isRunningTest()){
                Map<String, String> communityToQueueName = new Map<String, String>();
                for (AE_Comunity_Details__mdt meta : [SELECT Label,Queue_Name__c  FROM AE_Comunity_Details__mdt WHERE Label IN :communityNames]) {
                    communityToQueueName.put(meta.Label, meta.Queue_Name__c);
                    system.debug('communityToQueueName QueryonMdt::'+communityToQueueName);
                }
                Set<String> queueNames = new Set<String>(communityToQueueName.values());
                
                Map<String, Group> queueNameToGroup = new Map<String, Group>();
                for (Group g : [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name IN :queueNames]) {
                    queueNameToGroup.put(g.Name, g);
                    system.debug('queueNameToGroup queryonGroup::'+ queueNameToGroup);
                }
                Map<Id, List<HexaBPM__Service_Request__c>> queueIdToSRs = new Map<Id, List<HexaBPM__Service_Request__c>>();
                
                for (HexaBPM__Service_Request__c sr : moveInSRtoUpdateOwner) {
                    unit__c unit = unitMap.get(sr.Unit__c);String community = unit.Project__r.OA_Community_Name__c;String queueName = communityToQueueName.get(community); Group q = queueNameToGroup.get(queueName);
                    
                    if (q != null) { sr.OwnerId = q.Id;
                                    
                                   }
                                     
                }
            }
            
            validatePropertyTransferSR(newList,propertyTransferRecIds, ptunitIds, caseIds); // SR Resale Case Validation
            //SS_DandT_Revamp_SP17-START
            ALD_DandTSR_Handler_CC.updateSRIfFlagged((List<HexaBPM__Service_Request__c>) newList, custIdAndFlagType, soIdAndFlagType);
            //SS_DandT_Revamp_SP17-END
            
            //Added by Tharun to update ReferredBy Profile Name ASF-1367
            if(!agencyRegSRList.isEmpty()){
                updateAgencySrReferredByProfileName(agencyRegSRList);
            }
            
            
            if (!serviceRequestList.isEmpty()) {
                updateChargeCollected(newList, serviceRequestList);
            }
            
            if (!customerIdSet.isEmpty() && !serviceRequestGLList.isEmpty()) {
                updateGoldenVisaDetails(serviceRequestGLList, customerIdSet);
            }
            
            if (!srHandoverList.isEmpty()) {
                updateHandoverDetail(srHandoverList, newList);
            }
            
            if (!buyerIdList.isEmpty()) {
                updateBuyerContact(newList, buyerIdList);
            }
            
            blockTheSwappedUnit(newList, new Map<Id, SObject>());
            
            if (!goldenVisaAccountsIdsWithSR.isEmpty()) {
                List<Account> AccountsList = [Select Id, IsPersonAccount From Account Where Id IN :goldenVisaAccountsIdsWithSR.keySet()];
                for (Account accountRec : AccountsList) {
                    if(!accountRec.IsPersonAccount){
                        (goldenVisaAccountsIdsWithSR.get(accountRec.Id)).addError(Utilities.getSystemMessages(Constants.GOLDEN_VISA_IS_APPLICABLE_FOR_PERSON_ACC).Message__c);
                    }
                }
            }
        }*/
    
    //*** Before Update Action***//
    /*public override void beforeUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        system.debug('----Updated');
        List<HexaBPM__Service_Request__c> serviceRequestList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> srHandoverList = new List<HexaBPM__Service_Request__c>();
        List<Id> salesOrderIdForRTORentCalculate = new List<Id>();
        Map<HexaBPM__Service_Request__c,Id> submittedLPCSRWithSOMap = new Map<HexaBPM__Service_Request__c,Id>();
        List<Id> buyerIdList = new List<Id>();
        
        checkBlacklisted((List<HexaBPM__Service_Request__c>) newList);
        checkForFailedSR((List<HexaBPM__Service_Request__c>) newList);
        //List<HexaBPM__Service_Request__c> newList = (List<HexaBPM__Service_Request__c>) newList;
        //System.debug('data '+newList);
        Set<Id> saleorderIds= new  Set<Id>();*/
        
        /*ServiceChargeFee-Start*/
        /*Set<String> serviceChargeSRTypeSet = new Set<String>();
        Map<String,ChargeRule__c> SRTypeChargeDetailsMap = new Map<String,ChargeRule__c>();
        Map<Id,HexaBPM__SR_Status__c> SRStatusIdWithNameMap = new Map<Id,HexaBPM__SR_Status__c>([SELECT Id,Name FROM HexaBPM__SR_Status__c WHERE NAME IN ('Submitted')]);
        Set<Id> installmentLinesIdSetForPESet = new Set<Id>();
        Map<Id,InstallmentLines__c> ILDetailsOfPESRTypeMap = new Map<Id,InstallmentLines__c>();*/
        /*ServiceChargeFee-End*/
        
        /*for (HexaBPM__Service_Request__c newRecord: (List<HexaBPM__Service_Request__c>) newList) {
            saleorderIds.add(newRecord.SalesOrder__c);*/
            
            /*ServiceChargeFee-START*/
            //Calculate Charge Fee
            
            
            
       /*     system.debug('###SRStatusIdWithNameMap###'+SRStatusIdWithNameMap);
            HexaBPM__Service_Request__c oldRecord = (HexaBPM__Service_Request__c)oldmap.get(newRecord.Id);
            serviceChargeSRTypeSet.add(newRecord.SRType__c);
            
            if(newRecord.BuyerOwnershipVerifiedDari__c == true && oldRecord.BuyerOwnershipVerifiedDari__c == false && newRecord.SRType__c =='Property Transfer NOC' ){
                newRecord.HexaBPM__Required_Docs_not_Uploaded__c = false;
            }
      */      
            /**** Un-Used block of code Start ****/
       /*     if(newRecord.HexaBPM__External_SR_Status__c <> oldRecord.HexaBPM__External_SR_Status__c && !SRStatusIdWithNameMap.IsEmpty() && SRStatusIdWithNameMap.containsKey(newRecord.HexaBPM__External_SR_Status__c) && SRStatusIdWithNameMap.get(newRecord.HexaBPM__External_SR_Status__c).Name == Constants.SUBMITTED && serviceChargeSRTypeUtilSet.contains(newRecord.SRType__c)){
                //serviceChargeSRTypeSet.add(newRecord.SRType__c); 
                if(newRecord.SRType__c == Constants.PAYMENT_EXTENSION_TYPE && newRecord.InstallmentLine__c <> NULL) {
                    installmentLinesIdSetForPESet.add(newRecord.InstallmentLine__c);
                }
            }
        }
        
        if(!installmentLinesIdSetForPESet.IsEmpty()){
            for(InstallmentLines__c ILDetails : [SELECT Id,OutstandingAmount__c FROM InstallmentLines__c WHERE Id IN :installmentLinesIdSetForPESet]){
                ILDetailsOfPESRTypeMap.put(ILDetails.Id,ILDetails);
            }
        }*/
        /**** Un-Used block of code ****/
       /* if(!serviceChargeSRTypeSet.IsEmpty()) {
            for(ChargeRule__c chargeRule : [SELECT SRType__c,ChargePercentage__c,VATChanges__c,ChargeAmount__c from ChargeRule__c WHERE SRType__c IN :serviceChargeSRTypeSet AND ChargeType__c =:Constants.OTHER_CHARGES_TYPE_SERVICE_CHARGE AND IsActive__c = True]){
                SRTypeChargeDetailsMap.put(chargeRule.SRType__c,chargeRule);
            }
        }*/
        /*ServiceChargeFee-END*/
       /* System.debug('saleorderIds::'+saleorderIds);
        map<id,SalesOrder__c> saleOrderMap = new map<id,SalesOrder__c>();
        if(saleorderIds.size()>0){
            for(SalesOrder__c so:[select id,Account__r.PersonEmail,Contact__c, Contact__r.Email,Account__r.Email__c from SalesOrder__c where id in :saleorderIds]){
                saleOrderMap.put(so.Id,so);
            }
        }
        
        for (HexaBPM__Service_Request__c newRecord: (List<HexaBPM__Service_Request__c>) newList) {
            HexaBPM__Service_Request__c oldRecord = (HexaBPM__Service_Request__c)oldmap.get(newRecord.Id);
            system.debug('----Updated' + newRecord.TitleDeedRegistrationFee__c );
            system.debug('----Updated'+  oldRecord.TitleDeedRegistrationFee__c );
         */   
            
            /*ServiceChargeFee-START*/
           /* Decimal chargeAmount = 0;
            Decimal amountWithoutVAT = 0;
            Decimal vatAmount = 0;*/
            /*ServiceChargeFee-END*/
            
            
            
           /* if(newRecord.SalesOrder__c!=null && newRecord.SalesOrder__c!=oldRecord.SalesOrder__c 
               && saleOrderMap!=null && !saleOrderMap.isEmpty()) {          
                   SalesOrder__c newSaleorder=saleOrderMap.get(newRecord.SalesOrder__c);
                   if(newSaleorder!=null){
                       newRecord.HexaBPM__Email__c=newSaleorder.Contact__c !=null? newSaleorder.Contact__r.Email : newSaleorder.Account__r.PersonEmail!=null?newSaleorder.Account__r.PersonEmail :newSaleorder.Account__r.Email__c;  
                   }
               }
            
            Map<Id,InstallmentLines__c> InstallmentLineMap = new Map<Id,InstallmentLines__c>([SELECT Id,OutstandingAmount__c,InstallmentDate__c FROM InstallmentLines__c WHERE Id=:newRecord.InstallmentLine__c]); 
            *///Calculate Service Charge : Begin ///*ServiceChargeFee-START*/
            // if(newRecord.HexaBPM__External_SR_Status__c <> oldRecord.HexaBPM__External_SR_Status__c && !SRStatusIdWithNameMap.IsEmpty() && SRStatusIdWithNameMap.containsKey(newRecord.HexaBPM__External_SR_Status__c) && SRStatusIdWithNameMap.get(newRecord.HexaBPM__External_SR_Status__c).Name == Constants.SUBMITTED && serviceChargeSRTypeUtilSet.contains(newRecord.SRType__c) && !SRTypeChargeDetailsMap.IsEmpty() && SRTypeChargeDetailsMap.containsKey(newRecord.SRType__c)){
            /*if(newRecord.PaymentExtensionDate__c <> null && newRecord.InstallmentLine__c <> null && InstallmentLineMap.containsKey(newRecord.InstallmentLine__c) && InstallmentLineMap.get(newRecord.InstallmentLine__c).InstallmentDate__c <> null && newRecord.PaymentExtensionDate__c <> oldRecord.PaymentExtensionDate__c){
                serviceChargeSRTypeSet.add(newRecord.SRType__c);
                
                Integer monthDiff = InstallmentLineMap.containsKey(newRecord.InstallmentLine__c) ? InstallmentLineMap.get(newRecord.InstallmentLine__c).InstallmentDate__c.monthsBetween(newRecord.PaymentExtensionDate__c):0;
                Integer daysDiff = InstallmentLineMap.containsKey(newRecord.InstallmentLine__c) ? InstallmentLineMap.get(newRecord.InstallmentLine__c).InstallmentDate__c.daysBetween(newRecord.PaymentExtensionDate__c):0;
                
                if (InstallmentLineMap.containsKey(newRecord.InstallmentLine__c) && newRecord.PaymentExtensionDate__c.day() >= InstallmentLineMap.get(newRecord.InstallmentLine__c).InstallmentDate__c.day()) {
                    monthDiff++;
                }
                
                newRecord.PaymentExtensionPeriod__c = monthDiff;
                newRecord.Payment_Extension_Period_In_Days__c = daysDiff;
                
            } 
            
            ChargeRule__c chargeRule = SRTypeChargeDetailsMap.get(newRecord.SRType__c);
            System.debug('chargeRule:'+chargeRule);
            //PAYMENT EXTENSION CHARGE CALC
            if(newRecord.SRType__c == Constants.PAYMENT_EXTENSION_TYPE && chargeRule <> null) {
                if(newRecord.InstallmentLine__c <> NULL && InstallmentLineMap.containsKey(newRecord.InstallmentLine__c) && InstallmentLineMap.get(newRecord.InstallmentLine__c).OutstandingAmount__c <> NULL){
                    amountWithoutVAT = newRecord.Payment_Extension_Period_In_Days__c <> 0 && newRecord.Payment_Extension_Period_In_Days__c <> null ? (chargeRule.ChargePercentage__c * InstallmentLineMap.get(newRecord.InstallmentLine__c).OutstandingAmount__c * newRecord.Payment_Extension_Period_In_Days__c)/100 : (chargeRule.ChargePercentage__c * InstallmentLineMap.get(newRecord.InstallmentLine__c).OutstandingAmount__c)/100;
                    vatAmount = (amountWithoutVAT * chargeRule.VATChanges__c)/100;
                    chargeAmount = amountWithoutVAT + vatAmount;
                    newRecord.Calculated_Service_Charge__c = chargeAmount;
                }
            }
            //ALL OTHERS
            else if(chargeRule <> null){
                amountWithoutVAT = chargeRule.ChargeAmount__c;
                vatAmount = (amountWithoutVAT * chargeRule.VATChanges__c)/100;
                chargeAmount = amountWithoutVAT + vatAmount;
                newRecord.Calculated_Service_Charge__c = chargeAmount;
            }                
            //}  */ 
            //Calculate Service Charge : End/*ServiceChargeFee-END*/
            
            //CLOSE SR- POPULATE DATE
            /*if (newRecord.HexaBPM__IsClosedStatus__c && newRecord.HexaBPM__Closed_Date_Time__c == null && newRecord.SRType__c == Constants.UNIT_SWAP_SR_TYPE) {
                newRecord.HexaBPM__Closed_Date_Time__c = system.now();
            } else if (newRecord.SRType__c == Constants.UNIT_SWAP_SR_TYPE && newRecord.UnitFromSameProject__c == Constants.YES && newRecord.HexaBPM__External_Status_Name__c == Constants.EQUITY_TRANSFERRED_SR) {
                newRecord.HexaBPM__Closed_Date_Time__c = system.now();
            } else if (newRecord.SRType__c == Constants.UNIT_SWAP_SR_TYPE && newRecord.UnitFromSameProject__c == Constants.NO && newRecord.HexaBPM__External_Status_Name__c == Constants.CLOSED_SR) {
                newRecord.HexaBPM__Closed_Date_Time__c = system.now();
            }
            if ((newRecord.HexaBPM__Record_Type_Name__c == Constants.PAYMENT_EXTENSION_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PLOT_PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_NOC_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.INTERNAL_MORTGAGE_REGISTRATION_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.JOINT_OWNER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.JOINT_OWNER_NOC_DEV_RT) && (newRecord.ChargeCollected__c == null || oldRecord.SRType__c != newRecord.SRType__c || oldRecord.ChargeType__c != newRecord.ChargeType__c)) {
                serviceRequestList.add(newRecord);
            }
            if (newRecord.HandoverDetail__c == null && (newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PLOT_PROPERTY_TRANSFER_DEV_RT)) {
                srHandoverList.add(newRecord);
            }
            
            if (newRecord.SRType__c == Constants.RTO_CANCELLATION_SR_TYPE) {
                newRecord.ChargeCollected__c = newRecord.LegalPenaltyFee__c != null ? newRecord.LegalPenaltyFee__c : 0;
                newRecord.ChargeCollected__c += newRecord.ExitPenaltyFee__c != null ? newRecord.ExitPenaltyFee__c : 0;
                newRecord.ChargeCollected__c += newRecord.CostofFix__c != null ? newRecord.CostofFix__c : 0;
            }
            
            if ((newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PLOT_PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_NOC_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.JOINT_OWNER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.JOINT_OWNER_NOC_DEV_RT) && newRecord.HexaBPM__External_Status_Name__c == Constants.BUYER_PROFILE_VERIFIED_STATUS) {
                newRecord.DocumentPrintedDate__c = Date.today();
            }
            if (newRecord.RefundAmount__c > 0 || newRecord.ReallocationAmount__c > 0) {
                newRecord.IsRefundApplicable__c = true;
            }
            
            if (newRecord.TermCommencementDate__c != null && newRecord.SalesOrder__c != null && newRecord.TermCommencementDate__c != oldRecord.TermCommencementDate__c) {
                salesOrderIdForRTORentCalculate.add(newRecord.SalesOrder__c);
            }
            
            if (newRecord.BuyerName__c != null && newRecord.BuyerName__c != oldRecord.BuyerName__c) {
                buyerIdList.add(newRecord.BuyerName__c);
            }
            
            // calculate PaymentExtensionPeriod__c 
            if (newRecord.PaymentExtensionDate__c != null && newRecord.InstallmentDate__c != null && (newRecord.PaymentExtensionDate__c != oldRecord.PaymentExtensionDate__c || newRecord.InstallmentDate__c != oldRecord.InstallmentDate__c)) {
                Integer monthDiff = newRecord.InstallmentDate__c.monthsBetween(newRecord.PaymentExtensionDate__c);
                if (newRecord.PaymentExtensionDate__c.day() >= newRecord.InstallmentDate__c.day()) {
                    monthDiff++;
                }
                newRecord.PaymentExtensionPeriod__c = monthDiff;
            }
            
            // calculate WaivedPercentage__c when WaivedAmount__c is populated or changed.
            Boolean WaivedAmountChanged = false;
            if(newRecord.TotalLPCDue__c != null && newRecord.TotalLPCDue__c != 0 && newRecord.WaivedAmount__c != null && newRecord.WaivedAmount__c != oldRecord.WaivedAmount__c){
                
                if(newRecord.WaivedBy__c != 'Amount'){
                    newRecord.WaivedAmount__c = oldRecord.WaivedAmount__c;
                    newRecord.PaymentExtensionPeriod__c = newRecord.WaivedAmount__c != null ? (newRecord.WaivedAmount__c).setScale(0) : 0;
                } else{
                    WaivedAmountChanged = true;
                    newRecord.PaymentExtensionPeriod__c = newRecord.WaivedAmount__c != null ? (newRecord.WaivedAmount__c).setScale(0) : 0;
                    
                    if(newRecord.WaivedAmount__c == 0){
                        newRecord.WaivedPercentage__c = 0;
                    } else{
                        newRecord.WaivedPercentage__c = ((newRecord.WaivedAmount__c / newRecord.TotalLPCDue__c) * 100).setScale(2);
                    }
                }
            }
            // calculate WaivedAmount__c when WaivedPercentage__c is populated or changed.
            if (newRecord.TotalLPCDue__c != null && !WaivedAmountChanged && newRecord.WaivedPercentage__c != null && (newRecord.TotalLPCDue__c != oldRecord.TotalLPCDue__c || newRecord.WaivedPercentage__c != oldRecord.WaivedPercentage__c)) {
                
                if(newRecord.WaivedBy__c != 'Percentage'){
                    newRecord.WaivedPercentage__c = oldRecord.WaivedPercentage__c;
                    newRecord.PaymentExtensionPeriod__c = newRecord.WaivedAmount__c != null ? (newRecord.WaivedAmount__c).setScale(0) : 0;
                    
                } else{
                    newRecord.WaivedAmount__c = (newRecord.TotalLPCDue__c * (newRecord.WaivedPercentage__c/100)).setScale(2);
                    newRecord.PaymentExtensionPeriod__c = newRecord.WaivedAmount__c != null ? (newRecord.WaivedAmount__c).setScale(0) : 0;
                }
            }
            
            if(newRecord.HexaBPM__Record_Type_Name__c == Constants.LPC_WAIVER_DEV_RT && newRecord.HexaBPM__External_Status_Name__c != oldRecord.HexaBPM__External_Status_Name__c && newRecord.HexaBPM__External_Status_Name__c == Constants.SUBMITTED){
                submittedLPCSRWithSOMap.put(newRecord, newRecord.SalesOrder__c);
            }
            // populate ChargeCollected__c for LPC Waiver.
            if(newRecord.HexaBPM__Record_Type_Name__c == Constants.LPC_WAIVER_DEV_RT && (newRecord.WaivedPercentage__c != oldRecord.WaivedPercentage__c || newRecord.WaivedAmount__c != oldRecord.WaivedAmount__c)){
                newRecord.ChargeCollected__c = newRecord.TotalLPCDue__c != null ? newRecord.TotalLPCDue__c - (newRecord.WaivedAmount__c != null ? newRecord.WaivedAmount__c  : 0) : 0;
                
                newRecord.ChargeCollected__c = (newRecord.ChargeCollected__c).setScale(2);
            }
            
            //To Populate LPC Total, LPC Collected/Paid, LPC Waived and LPC Due 
            if(newRecord.Unit__c != oldRecord.Unit__c || newRecord.SalesOrder__c != oldRecord.SalesOrder__c){
                updateSalesOrderAndCustomer(newList);
                checkSRAutomation(newList, oldMap);
                
                if (newRecord.HexaBPM__Record_Type_Name__c == Constants.LPC_WAIVER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == Constants.TITLE_DEED_REGISTRATION_DEV_RT) {
                    LPCModel lpcDetail = LPCService.getOutstandingLPCforSalesOrder(newRecord.SalesOrder__c);
                    newRecord.TotalLPCAmount__c = lpcDetail.totalLPC.setScale(2);
                    newRecord.TotalLPCDue__c = lpcDetail.totalLPCDue.setScale(2);
                    newRecord.TotalLPCCollected__c = lpcDetail.lpcPaid.setScale(2);
                    newRecord.ChargeCollected__c = newRecord.TotalLPCDue__c - (newRecord.WaivedAmount__c != null ? newRecord.WaivedAmount__c  : 0);
                    
                    newRecord.ChargeCollected__c = (newRecord.ChargeCollected__c).setScale(2);
                    
                    newRecord.TotalLPCWaivedAmount__c = lpcDetail.lpcWaivedAmount.setScale(2);
                    newRecord.LPCCalculatedDate__c = Date.today();
                    
                    if(newRecord.HexaBPM__Record_Type_Name__c == Constants.TITLE_DEED_REGISTRATION_DEV_RT){
                        newRecord.OldNetAmount__c = lpcDetail.orderDetail.NetAmount__c;
                        newRecord.TotalBilledAmount__c = lpcDetail.orderDetail.NetAmount__c - lpcDetail.orderDetail.TotalOutstanding__c;
                        newRecord.TotalOutstandingAmount__c = lpcDetail.orderDetail.TotalOutstanding__c;
                    }
                }
                
                if (newRecord.HexaBPM__Record_Type_Name__c == Constants.PAYMENT_PLAN_CHANGE_DEV_RT) {
                    if (newRecord.PaidEquity__c == 100) {
                        newRecord.addError(Utilities.getSystemMessages(Constants.PPC_PAID_EQUITY_100_VALIDATION).Message__c);
                    }
                }
            }
        }
        if (!serviceRequestList.isEmpty()) {
            updateChargeCollected(newList, serviceRequestList);
        }
        
        
        
        if (!buyerIdList.isEmpty()) {
            updateBuyerContact(newList, buyerIdList);
        }
        
        if (!srHandoverList.isEmpty()) {
            updateHandoverDetail(srHandoverList, newList);
        }
        
        if (!salesOrderIdForRTORentCalculate.isEmpty()) {
            updateRTORent(salesOrderIdForRTORentCalculate, newList);
        }
        
        if (!submittedLPCSRWithSOMap.isEmpty()) {
            submittedLPC(submittedLPCSRWithSOMap);
        }
        
        blockTheSwappedUnit(newList, oldMap);
    }*/
    
    //*** After Insert Action***//
    /*public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
        
        List<HexaBPM__Service_Request__c> moveInSRtoUpdateOwner = new list<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> moveInSRtoUpdateOwnerList = new list<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> srToUpdate = new List<HexaBPM__Service_Request__c>();        
       
        Set<String> communityNames = new Set<String>();
        system.debug('afterInsertMethod');
        checkSRAutoSubmitted((List<HexaBPM__Service_Request__c>)newList);
        Set<Id> unitIds = new Set<Id>();
        for (HexaBPM__Service_Request__c sr : (List<HexaBPM__Service_Request__c>)newList) {
            if (sr.Unit__c != null) {
                unitIds.add(sr.Unit__c);
            }
        }
        Set<Id> queueIds = new Set<Id>();
    		Map<Id, HexaBPM__Service_Request__c> recordMap = new Map<Id, HexaBPM__Service_Request__c>();

        // Added by Adarsh for ComplainceCheck
        for(HexaBPM__Service_Request__c newRecord : (List<HexaBPM__Service_Request__c>) newList){
            if (newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT && newRecord.BuyerName__c !=null ){
                ComplianceCheck(newRecord);             
                
            }
            if ( newRecord.SRType__c == 'Aldar Estates Move-In' && newRecord.OwnerId != null && String.valueOf(newRecord.OwnerId).startsWith('00G')) {
            queueIds.add(newRecord.OwnerId);
            recordMap.put(newRecord.Id, newRecord);
        }
            
        }
        if (!queueIds.isEmpty()) {
        // Query queue members
        Map<Id, List<Id>> queueToUsersMap = new Map<Id, List<Id>>();
        for (GroupMember gm : [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :queueIds]) {if (!queueToUsersMap.containsKey(gm.GroupId)) {queueToUsersMap.put(gm.GroupId, new List<Id>());
            }queueToUsersMap.get(gm.GroupId).add(gm.UserOrGroupId);
        } 

        List<HexaBPM__Service_Request__Share> shares = new List<HexaBPM__Service_Request__Share>();
        for (HexaBPM__Service_Request__c record : recordMap.values()) { List<Id> userIds = queueToUsersMap.get(record.OwnerId);if (userIds != null) {for (Id userId : userIds) {shares.add(new HexaBPM__Service_Request__Share(ParentId = record.Id,UserOrGroupId = userId,AccessLevel = 'Edit',RowCause = Schema.HexaBPM__Service_Request__Share.RowCause.Manual
                    ));
                }
            }
        }
            if (!shares.isEmpty()) {insert shares;
        	}
        
        }
        //MOVE-IN OWNER CHANGE END
    }*/
    
    //*** After Update Action***//
   /* public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
        List<HexaBPM__Service_Request__c> serviceRequestLists = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> serviceRequestList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> updateSRList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> updateMoveInSR = new List<HexaBPM__Service_Request__c>();
         List<HexaBPM__Service_Request__c> NOCSRToUpdateStepList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Service_Request__c> srToCloseADMStepList = new List<HexaBPM__Service_Request__c>();
        
        
        
        //SS_SEND_CANCELLATION_SR_CHANGES_TO_ERP_26Jul23-START
        List<ID> cancellationSrIds = new List<ID>(); //SS_SEND_CANCELLATION_SR_CHANGES_TO_ERP_26Jul23
        Boolean isCancellationDetailsChanged = false;
        //SS_SEND_CANCELLATION_SR_CHANGES_TO_ERP_26Jul23-END
        
        //SS_DandT_Revamp_SP19-START
        set<ID> srIDsToClose = new set<ID>();
        set<ID> custIDsToBlock = new set<ID>();
        Map<ID,HexaBPM__Service_Request__c> srIDAndSrToProcess = new Map<ID,HexaBPM__Service_Request__c>();//GENERIC ATTRIBUTE//SS_DandT_Revamp_SP15-Start
        //SS_DandT_Revamp_SP19-END
        list<HexaBPM__SR_Status__c > ApprovedStatus =[SELECT Id FROM HexaBPM__SR_Status__c WHERE Name IN ('Approved')];
        
        
        set<ID> parentSRToClose = new set<ID>();
        List<Id> lpcFreezeSRsIds = new List<Id>();
        List<Id> salesOrderIdsForAPI = new List<Id>();
        List<Unit__c> updateUnitList = new List<Unit__c>();
        MAP<ID,ID> karChangedsalesordersMap=new MAP<ID,ID>();
        for(HexaBPM__Service_Request__c newRecord : (List<HexaBPM__Service_Request__c>) newList){
            HexaBPM__Service_Request__c oldRecord = (HexaBPM__Service_Request__c) oldMap.get(newRecord.ID);
            // Added by Adarsh for ComplainceCheck
            String results = '';
            
            if(newRecord.HOKAR__c!=null && oldRecord.HOKAR__c!=newRecord.HOKAR__c){
                karChangedsalesordersMap.put(newRecord.SalesOrder__c,newRecord.HOKAR__c);
            }
            
            if ((newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT || newRecord.HexaBPM__Record_Type_Name__c == 'PropertyTransferNOC')){
                if(newRecord.BuyerName__c != oldRecord.BuyerName__c){  // Added by Chirag 
                    ComplianceCheck(newRecord); 
                }
                if (newRecord.Retrive_Buyer_Acc_Docs__c == true){
                    
                    FastTRackSRDOC job = new FastTRackSRDOC(newRecord);
                    System.enqueueJob(job);
                    HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c();
                    sr.id = newRecord.id;
                    sr.Retrive_Buyer_Acc_Docs__c = false;
                    update sr;
                }
            }
            
            
            if (newRecord.HexaBPM__Record_Type_Name__c == Constants.PROPERTY_TRANSFER_DEV_RT && ((newRecord.IsComplianceReturned__c != oldRecord.IsComplianceReturned__c && newRecord.IsComplianceReturned__c == true)  ||(newRecord.HexaBPM__External_Status_Name__c == 'Buyer Profile Verified') || (newRecord.Compliance_Status__c != oldRecord.Compliance_Status__c))) {
                List<HexaBPM__Step__c> stepToUpdateList = [SELECT Id, HexaBPM__SR_Step__c, HexaBPM__Status__c,HexaBPM__Summary__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c = :newRecord.Id AND HexaBPM__Summary__c = 'Compliance Check for Buyers' ORDER BY CreatedDate DESC LIMIT 1];
                System.debug('Inside condition'+stepToUpdateList);
                if (!stepToUpdateList.isEmpty() ) {
                    HexaBPM__Step__c stepToUpdate = stepToUpdateList[0];
                    Map<String, HexaBPM__Status__c> closureStatusMap = new Map<String, HexaBPM__Status__c>();
                    
                    for (HexaBPM__Status__c tempRec : [SELECT Id, Name FROM HexaBPM__Status__c WHERE Name IN (:Constants.Cleared, :Constants.Rejected, :Constants.Returned)]) {
                        closureStatusMap.put(tempRec.Name, tempRec);
                    }
                    
                    Map<String, HexaBPM__SR_Status__c> SRStatusMap = new Map<String, HexaBPM__SR_Status__c>();
                    
                    for (HexaBPM__SR_Status__c tempRec : [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name IN (:Constants.Compliance_Cleared, :Constants.Compliance_Rejected, :Constants.Returned)]) {
                        SRStatusMap.put(tempRec.Name, tempRec);
                    }
                    
                    String statusId = '';
                    String externalstatusid = '';
                    
                    if (newRecord.Compliance_Status__c == 'Returned') {
                        statusId = closureStatusMap.get(Constants.Returned)?.Id;
                        externalstatusid=SRStatusMap.get(Constants.Returned)?.Id;
                    } else if (newRecord.Compliance_Status__c == 'Cleared') {
                        statusId = closureStatusMap.get(Constants.SRCleared)?.Id;                        
                        externalstatusid=SRStatusMap.get(Constants.Compliance_Cleared)?.Id;                        
                    } else if (newRecord.Compliance_Status__c == 'Rejected') {
                        statusId = closureStatusMap.get(Constants.Rejected)?.Id;
                        externalstatusid=SRStatusMap.get(Constants.Compliance_Rejected)?.Id;
                    }
                    
                    if (String.isNotBlank(statusId)) {
                        HexaBPM__Step__c step = new HexaBPM__Step__c(Id = stepToUpdate.Id, HexaBPM__Status__c = statusId);
                        HexaBPM__Service_Request__c SR = new HexaBPM__Service_Request__c(Id = newRecord.Id, HexaBPM__External_SR_Status__c =externalstatusid );
                        update step;
                        if(newRecord.Compliance_Status__c == 'Returned'){
                            SR.IsComplianceReturned__c = true;
                        }else{
                            SR.IsComplianceReturned__c = false;
                        }
                        update SR;
                    }
                }
            }
            
            
            if (newRecord.BrokerManager__c != null && newRecord.BrokerManager__c != oldRecord.BrokerManager__c) {
                serviceRequestList.add(newRecord);
            }
            
            if(newRecord.LPCFreezeStatus__c != oldRecord.LPCFreezeStatus__c && newRecord.LPCFreezeStatus__c == Constants.STATUS_IN_PROGRESS){
                lpcFreezeSRsIds.add(newRecord.Id);
            }
            
            if ((newRecord.HexaBPM__Record_Type_Name__c == Constants.INTERNAL_MORTGAGE_REGISTRATION_DEV_RT || (newRecord.SRType__c == Constants.CANCELLATION_SR_TYPE && newRecord.SubType__c == Constants.UNIT_SWAP_SR_TYPE)) && newRecord.HexaBPM__External_Status_Name__c == Constants.DOCUMENTS_ARCHIVED_STATUS && newRecord.HexaBPM__Parent_SR__c != null) {
                HexaBPM__Service_Request__c updateSR = new HexaBPM__Service_Request__c();
                updateSR.Id = newRecord.HexaBPM__Parent_SR__c;
                updateSR.IsChildSRCompleted__c = true;
                updateSRList.add(updateSR);
            } else if (newRecord.HexaBPM__Record_Type_Name__c == Constants.INTERNAL_MORTGAGE_REGISTRATION_DEV_RT && newRecord.HexaBPM__Parent_SR__c != null) {
                HexaBPM__Service_Request__c updateSR = new HexaBPM__Service_Request__c();
                updateSR.Id = newRecord.HexaBPM__Parent_SR__c;
                updateSR.IsChildSRCompleted__c = true;
                updateSRList.add(updateSR);
            }
            if (newRecord.SRType__c == Constants.UNIT_SWAP_SR_TYPE && newRecord.HexaBPM__External_Status_Name__c == Constants.SALES_ORDER_CANCELLATION_COMPLETED_STATUS && newRecord.HexaBPM__External_SR_Status__c != oldRecord.HexaBPM__External_SR_Status__c) {
                Unit__c updateUnit = new Unit__c();
                updateUnit.Id = newRecord.SwappedUnit__c;
                updateUnit.Status__c = Constants.UNIT_STATUS_AVAILABLE;
                updateUnit.AssignedToUser__c = UserInfo.getUserId();
                updateUnit.AllocationGroup__c = null;
                updateUnitList.add(updateUnit);
            }
            //TODO Status still unknown
            //SS_DandT_Revamp_SP15-Start
            if(newRecord.HexaBPM__Record_Type_Name__c == Constants.DEFAULT_AND_TERMINATION_DEV_RT){
                System.debug('DnT newRecord.LegalStatus__c > '+newRecord.LegalStatus__c);
                System.debug('DnT oldRecord.LegalStatus__c > '+oldRecord.LegalStatus__c);
                System.debug('DnT oldRecord.Special_Exceptional_Case__c > '+oldRecord.Special_Exceptional_Case__c);
                if(newRecord.LegalStatus__c != oldRecord.LegalStatus__c && newRecord.LegalStatus__c=='Legal Cleared') {
                    srIDsToClose.add(newRecord.Id);
                } else if(newRecord.LegalStatus__c != oldRecord.LegalStatus__c) {
                    //Logic to block
                    srIDAndSrToProcess.put(newRecord.Id,newRecord);
                    custIDsToBlock.add(newRecord.HexaBPM__Customer__c);
                }
                if(newRecord.Special_Exceptional_Case__c && newRecord.Special_Exceptional_Case__c!=oldRecord.Special_Exceptional_Case__c && newRecord.LegalFees__c!=null) {
                    //If Exceptional case, then create Other Charge with the fee entered by the legal team. Then Legal will manually move the step to DnT Team for Negotiation
                    srIDAndSrToProcess.put(newRecord.Id,newRecord);
                    custIDsToBlock.add(newRecord.HexaBPM__Customer__c);
                    ALD_DandTSR_Handler_CC.Special_Exceptional_Case = true;
                }
            }
            //CLose parent
            if(newRecord.HexaBPM__External_Status_Name__c!= oldRecord.HexaBPM__External_Status_Name__c && newRecord.HexaBPM__External_Status_Name__c=='Closed' && newRecord.HexaBPM__Parent_SR__c != null){
                //parentSRToClose.add(newRecord.HexaBPM__Parent_SR__c);
            }
            
            if (newRecord.SalesOrder__c != null && newRecord.HexaBPM__External_Status_Name__c == Constants.SUBMITTED && newRecord.HexaBPM__Internal_SR_Status__c != oldRecord.HexaBPM__Internal_SR_Status__c) {
                salesOrderIdsForAPI.add(newRecord.SalesOrder__c);
            }
            //SS_CREDIT_NOTE_CHANGES_SARAN_23-May-START
            if (newRecord.HexaBPM__Record_Type_Name__c == Constants.CREDIT_NOTE_CREATION_DEV_RT && !newRecord.HexaBPM__IsClosedStatus__c) {          
                updateSRList.add(CC_ALDRA_CreditNoteCreationProcess.updateCreditNoteSR(newRecord));
            }
            //SS_CREDIT_NOTE_CHANGES_SARAN_23-May-END
            
            //SS_SEND_CANCELLATION_SR_CHANGES_TO_ERP_SP15-START
            if(isValidForCancellationCall(newRecord,oldRecord)) {
                isCancellationDetailsChanged = true;
                cancellationSrIds.add(newRecord.Id);
            }
            //SS_SEND_CANCELLATION_SR_CHANGES_TO_ERP_SP15-END
            
            //MOVE-IN_SR_APPROVED-START
            if ((newRecord.SRType__c == 'Aldar Estates Move-In' && newRecord.HexaBPM__External_Status_Name__c == 'Submitted' && oldRecord.HexaBPM__External_Status_Name__c != newRecord.HexaBPM__External_Status_Name__c) ){HexaBPM__Service_Request__c moveInSr = new HexaBPM__Service_Request__c();moveInSr.Id = newRecord.Id;moveInSr.HexaBPM__External_SR_Status__c= ApprovedStatus[0].Id ;moveInSr.HexaBPM__Internal_SR_Status__c = ApprovedStatus[0].Id ;updateMoveInSR.add(moveInSr);
            }
                        //NOC SR Step Auto Closure
            if( ( newRecord.SRType__c == 'Property Transfer NOC' && (newRecord.IsChargeReceiptCreated__c != oldRecord.IsChargeReceiptCreated__c) && newRecord.IsChargeReceiptCreated__c == true && (newRecord.Origin__c == 'Customer Portal' || newRecord.Origin__c == 'Customer App') ) ){
                NOCSRToUpdateStepList.add(newRecord);
                system.debug('Inside AUTO CLOSURE');
            }
            if( ( newRecord.SRType__c == 'Property Transfer NOC' && (newRecord.BuyerOwnershipVerifiedDari__c != oldRecord.BuyerOwnershipVerifiedDari__c) && newRecord.BuyerOwnershipVerifiedDari__c == true  ) ){
                srToCloseADMStepList.add(newRecord);
                
            }
            
        }
        
        if (!updateMoveInSR.isEmpty()) {
            update updateMoveInSR;
        }
        //MOVE-IN_SR_STATUS_TO_APPROVED END
        if (!NOCSRToUpdateStepList.isEmpty()) {
            System.enqueueJob(new CloseDigitalPaymentStepQueueable(NOCSRToUpdateStepList));
        }
        //NOC SR Step Auto Closure END
        //NOC SR ADM STEP AUTO CLOSURE 
		if (!srToCloseADMStepList.isEmpty()) {
           closeADMStepList(srToCloseADMStepList);
        }
        if(!karChangedsalesordersMap.isEmpty()){
            // titledeedKARMapping(karChangedsalesordersMap);
        }
        if (!updateSRList.isEmpty()) {
            update updateSRList;
        }
        if (!updateUnitList.isEmpty()) {
            update updateUnitList;
        }
        
        if (!serviceRequestList.isEmpty()) {
            //---- to share SR record with Broker Manager.
            ShareHelper.shareServiceRequestBrokerManager(serviceRequestList, Constants.EDIT_ACCESS);
        }
        if(!srIDsToClose.isEmpty()){
            DefaultAndTerminationUtility.closeDandTSRAfterLegal( srIDsToClose);
        }
        
        //SS_DandT_Revamp_SP15-Start
        if(!custIDsToBlock.isEmpty()){
            ALD_DandTSR_Handler_CC.handleDandTSR(custIDsToBlock, srIDAndSrToProcess);//push to helper class for d&t process
        }
        //SS_DandT_Revamp_SP15-END
        
        if(!lpcFreezeSRsIds.isEmpty()){
            LPCCalloutHelper.getDataForFreezeCallout(lpcFreezeSRsIds, true);
        }
        if(!salesOrderIdsForAPI.isEmpty()) {
            List<Id> soIds = new List<Id>();
            for(SalesOrder__c salesOrder :[SELECT Id, SyncStatus__c FROM SalesOrder__c WHERE Id IN: salesOrderIdsForAPI AND SyncStatus__c =:Constants.STATUS_FAILED]) {
                soIds.add(salesOrder.Id);
            }
            if (!soIds.isEmpty()) {
                SalesOrderCalloutHelper.PrepareDataForCallout(soIds, false, new Map<String, String>());
            }
        }
        /*if(!parentSRToClose.isEmpty()){
DefaultAndTerminationUtility.verifyandCloseParentSR(parentSRToClose);
} ADDED Feb 12*/
        
        //SS_SEND_CANCELLATION_SR_CHANGES_TO_ERP_SP15-START
      /* ADDED FEB 12  /doCancellationCall(isCancellationDetailsChanged, cancellationSrIds);
        //SS_SEND_CANCELLATION_SR_CHANGES_TO_ERP_SP15-END
        handleOfflineProceess(newList,oldMap);
        handleOfflineProcessTDSR(newList,oldMap);
    }
    
    public static void closeADMStepList(List<HexaBPM__Service_Request__c> newSRList ){
        list<Id> srIdList = new list<Id>();
        List<HexaBPM__Step__c> srStepsToUpdateList = new List<HexaBPM__Step__c>();
        List<HexaBPM__Step__c> titleDeedStepsToClose  = new List<HexaBPM__Step__c>();
        List<HexaBPM__Service_Request__c> srToUpdateStatusList = new List<HexaBPM__Service_Request__c>();
        List<HexaBPM__Step__c> stepsToUpdate = new List<HexaBPM__Step__c>();
        List<HexaBPM__Step__c> stepsToInsert = new List<HexaBPM__Step__c>();
        List<HexaBPM__Service_Request__c>srListtoUpdate = new List<HexaBPM__Service_Request__c>();
        for( HexaBPM__Service_Request__c sr: newSRList){
            srIdList.add(sr.Id);
        }
        map<string, HexaBPM__Status__c> stepStatusMap = new map<string, HexaBPM__Status__c>();
        for (HexaBPM__Status__c srStepStatus : [SELECT Id, Name FROM HexaBPM__Status__c WHERE Name IN ('Completed','Pending','Approved')]) {
            stepStatusMap.put(srStepStatus.Name, srStepStatus);
        }
        
        List<HexaBPM__Step__c> stepList = [SELECT Id, HexaBPM__Status__c, HexaBPM__SR__c,HexaBPM__Summary__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN :srIdList AND HexaBPM__Summary__c IN ('Transfer Execution status in ADM','Verify Title Deed & Checklist','Title Deed Approval') AND HexaBPM__Step_Status__c = 'Pending'];        
        list<HexaBPM__SR_Steps__c> tdTemplate = [ SELECT Id, OwnerId, HexaBPM__Sys_Custom_Conditions_Actions__c, HexaBPM__Step_No__c, HexaBPM__Step_Template__c,  HexaBPM__Step_Template__r.Name FROM HexaBPM__SR_Steps__c WHERE HexaBPM__SR_Template__r.Name = 'Property Transfer NOC' AND HexaBPM__Step_Template__r.Name = 'Title Deed Approval' LIMIT 1];
        
        for (Id srId : srIdList) {
            Boolean admOrVerifyOpen = false;
            Boolean titleApprovalOpen = false;
            
            for (HexaBPM__Step__c step : stepList) {
                if (step.HexaBPM__SR__c == srId) {
                    if (step.HexaBPM__Summary__c == 'Transfer Execution status in ADM') {
                        step.HexaBPM__Status__c = stepStatusMap.get('Completed').Id;stepsToUpdate.add(step);admOrVerifyOpen = true;
                    } else if (step.HexaBPM__Summary__c == 'Verify Title Deed & Checklist') {
                        step.HexaBPM__Status__c = stepStatusMap.get('Approved').Id;stepsToUpdate.add(step);admOrVerifyOpen = true;
                    } else if (step.HexaBPM__Summary__c == 'Title Deed Approval') {
                        step.HexaBPM__Status__c = stepStatusMap.get('Approved').Id;stepsToUpdate.add(step);titleApprovalOpen = true;
                    }
                }
            }
            if (admOrVerifyOpen) {
                HexaBPM__Step__c newStep = new HexaBPM__Step__c(
                ExecuteCustomCode__c = tdTemplate[0].HexaBPM__Sys_Custom_Conditions_Actions__c, HexaBPM__SR_Step__c = tdTemplate[0].Id, OwnerId = tdTemplate[0].OwnerId, HexaBPM__SR__c = srId,HexaBPM__Start_Date__c = System.today(), HexaBPM__Step_No__c = tdTemplate[0].HexaBPM__Step_No__c,HexaBPM__Status__c = stepStatusMap.get('Pending').Id, HexaBPM__Step_Template__c = tdTemplate[0].HexaBPM__Step_Template__c,HexaBPM__Summary__c = tdTemplate[0].HexaBPM__Step_Template__r.Name, HexaBPM__Sys_Step_Loop_No__c = tdTemplate[0].HexaBPM__Step_No__c + '_1');stepsToInsert.add(newStep); }
        }
        if (!stepsToUpdate.isEmpty() && !Test.isRunningTest() ) { update stepsToUpdate;}
        if (!stepsToInsert.isEmpty() && !Test.isRunningTest() ) {  insert stepsToInsert;}
        List<HexaBPM__Step__c> titleDeedStepToClose = [SELECT Id, HexaBPM__Status__c, HexaBPM__SR__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN :srIdList AND HexaBPM__Summary__c IN ('Title Deed Approval') AND HexaBPM__Step_Status__c = 'Pending'];
        for (HexaBPM__Step__c titleStep : titleDeedStepToClose) { titleStep.HexaBPM__Status__c = stepStatusMap.get('Approved').Id;titleDeedStepsToClose.add(titleStep); 
        }
        if(!titleDeedStepsToClose.IsEmpty() && !Test.isRunningTest() ){ update titleDeedStepsToClose;}   
        
    }
    
    //SS_SEND_CANCELLATION_SR_CHANGES_TO_ERP_SP15-START
    public static Boolean isValidForCancellationCall(HexaBPM__Service_Request__c newRecord,HexaBPM__Service_Request__c oldRecord) {
        Boolean isCancellationDetailsChanged = false;
        
        if (Test.isRunningTest() || isCancellationSRNonClosed(newRecord)) {
            System.debug('#$#$ newRecord.HexaBPM__Submitted_DateTime__c > '+newRecord.HexaBPM__Submitted_DateTime__c);
            System.debug('#$#$ oldRecord.HexaBPM__Submitted_DateTime__c > '+oldRecord.HexaBPM__Submitted_DateTime__c);
            if( (newRecord.HexaBPM__Submitted_DateTime__c != oldRecord.HexaBPM__Submitted_DateTime__c && newRecord.HexaBPM__External_Status_Name__c == Constants.SUBMITTED) || 
               newRecord.CancellationReason__c != oldRecord.CancellationReason__c ||
               newRecord.SocialReason__c != oldRecord.SocialReason__c ||
               newRecord.TotalCollectedAmount__c != oldRecord.TotalCollectedAmount__c || 
               newRecord.AgreementType__c != oldRecord.AgreementType__c ||
               newRecord.ReallocationAmount__c != oldRecord.ReallocationAmount__c ||
               newRecord.CancellationOption__c != oldRecord.CancellationOption__c ||
               newRecord.ForfeitAmount__c != oldRecord.ForfeitAmount__c ||
               newRecord.PriceRevisionRequired__c != oldRecord.PriceRevisionRequired__c)
            {
                isCancellationDetailsChanged = true;
                //cancellationSrIds.add(newRecord.Id);
                System.debug('#$#$ isCancellationDetailsChanged > '+isCancellationDetailsChanged);
            }
        }
        return isCancellationDetailsChanged;
    }
    
    public static Boolean isCancellationSRNonClosed(HexaBPM__Service_Request__c newRecord) {
        return newRecord.SRType__c == Constants.CANCELLATION_INTEGRATION && !newRecord.HexaBPM__IsClosedStatus__c;
    }
    
    public static void doCancellationCall(Boolean isCancellationDetailsChanged, List<Id> cancellationSrIds) {
        if(isCancellationDetailsChanged && cancellationSrIds.size() > 0) {
            CancellationCalloutHelper.ApprovalStatus = 'Open';
            CancellationCalloutHelper.getDataForCallout(cancellationSrIds);
        }
    }
    //SS_SEND_CANCELLATION_SR_CHANGES_TO_ERP_SP15-END
    
    public static void checkBlacklisted(List<HexaBPM__Service_Request__c> newSRList) {
        List<SRAutomation__mdt> srAutomationList = SRAutomation__mdt.getall().values();
        
        User usr = Utilities.getLoggedInUserDetail();
        Map<String, Boolean> srAutomationMap = new Map<String, Boolean>();
        Map<String, Boolean> srAllowCancellationForBlackilistedMap = new Map<String, Boolean>();
        for(SRAutomation__mdt srAutomation : srAutomationList){
            srAutomationMap.put(srAutomation.SRType__c, srAutomation.AllowBlacklisted__c);
            //ASF-584(Begin): Added validation by pass logic based on Allow_Cancellation__c flag set, on SRAutomation__mdt
            srAllowCancellationForBlackilistedMap.put(srAutomation.SRType__c.toUpperCase(),srAutomation.Allow_Cancellation__c);
            //ASF-584(End)
        }
        if(usr.ProfileName__c!='Integration Profile'){
            for (HexaBPM__Service_Request__c srRecord: newSRList) { 
                if (srRecord.HexaBPM__Record_Type_Name__c != Constants.CREDIT_NOTE_CREATION_HEXA_SR_TYPE){
                    if (srRecord.HexaBPM__Record_Type_Name__c != Constants.HANDOVER_RT && srRecord.HexaBPM__Record_Type_Name__c != Constants.DEFAULT_AND_TERMINATION_DEV_RT && srRecord.BlacklistedCustomer__c.containsIgnoreCase(Constants.BLACKLISTED_CUSTOMER_COMPLIANCE)) {
                        srRecord.addError(Utilities.getSystemMessages('CUSTOMER_BLACKLISTED_COMPLIANCE').Message__c);
                    } else if (srRecord.HexaBPM__Record_Type_Name__c != Constants.HANDOVER_RT && srRecord.HexaBPM__Record_Type_Name__c != Constants.DEFAULT_AND_TERMINATION_DEV_RT && srAutomationMap.containsKey(srRecord.SRType__c) && srRecord.SalesOrderHoldFlag__c && srAutomationMap.get(srRecord.SRType__c) == false) {
                        srRecord.addError(Utilities.getSystemMessages('CUSTOMER_BLACKLISTED_DEFAULT').Message__c);
                    } else if (srRecord.HexaBPM__Record_Type_Name__c != Constants.HANDOVER_RT && srRecord.HexaBPM__Record_Type_Name__c != Constants.DEFAULT_AND_TERMINATION_DEV_RT && srRecord.BlacklistedCustomer__c.containsIgnoreCase(Constants.BLACKLISTED_CUSTOMER_LEGAL)) 
                    {
                        /* //SS_091023 Restriction is not required for Legal flag as we are taking care in validation rule, if it is external order not allowing.
//ASF-584(Begin): Added validation by pass logic based on Allow_Cancellation__c flag set, on SRAutomation__mdt
if(srAllowCancellationForBlackilistedMap.isEmpty() || (!srAllowCancellationForBlackilistedMap.isEmpty() && srAllowCancellationForBlackilistedMap.containsKey(srRecord.SRType__c.toUpperCase()) && !srAllowCancellationForBlackilistedMap.get(srRecord.SRType__c.toUpperCase())) || (!srAllowCancellationForBlackilistedMap.isEmpty() && !srAllowCancellationForBlackilistedMap.containsKey(srRecord.SRType__c.toUpperCase()))){
srRecord.addError(Utilities.getSystemMessages('CUSTOMER_BLACKLISTED_LEGAL').Message__c);
} ADDED FEB 12*/
//ASF-584(End)
/* ADDED FEB 12
                    } else if (srRecord.HexaBPM__Record_Type_Name__c != Constants.HANDOVER_RT && srRecord.HexaBPM__Record_Type_Name__c != Constants.DEFAULT_AND_TERMINATION_DEV_RT && srRecord.BlacklistedCustomer__c.equalsIgnoreCase('true')) {
                        srRecord.addError(Utilities.getSystemMessages('CUSTOMER_BLACKLISTED').Message__c);
                    }
                }
            }
        }
    }
    
    public static void checkForFailedSR(List<HexaBPM__Service_Request__c> newSRList) {
        List<Id> soIds = new List<Id>();
        List<Id> srIds = new List<Id>();
        User usr = Utilities.getLoggedInUserDetail();
        for (HexaBPM__Service_Request__c srRecord: newSRList) {
            srIds.add(srRecord.Id);
            if (srRecord.HexaBPM__Record_Type_Name__c != Constants.HANDOVER_RT && srRecord.HexaBPM__External_Status_Name__c != Constants.SR_STATUS_DRAFT && srRecord.HexaBPM__External_Status_Name__c != Constants.SUBMITTED) {
                soIds.add(srRecord.SalesOrder__c);
            }
        }
        
        List<HexaBPM__Service_Request__c> failedSRList = [SELECT Id, SalesOrder__c, SyncStatus__c FROM HexaBPM__Service_Request__c 
                                                          WHERE Id NOT IN: srIds AND SalesOrder__c IN: soIds AND SalesOrder__c != null
                                                          AND SyncStatus__c =: Constants.STATUS_FAILED];
        
        if(usr.ProfileName__c!='Integration Profile' && usr.ProfileName__c!=Label.System_Admin){for (HexaBPM__Service_Request__c srRecord: newSRList) { if (!failedSRList.isEmpty()) {SystemMessages__mdt message = Utilities.getSystemMessages('SYNC_STATUS_ERROR_SR_MESSAGE'); srRecord.addError(message.Message__c);   break;
                }
            }
        }
    }
    
    public static void updateSalesOrderAndCustomer(List<HexaBPM__Service_Request__c> newSRList) {
        List<Id> unitIds = new List<Id>();
        List<HexaBPM__Service_Request__c> assetUpdateList = new List<HexaBPM__Service_Request__c>();
        for (HexaBPM__Service_Request__c srRecord: newSRList) {
            if (srRecord.Unit__c != null) {
                unitIds.add(srRecord.Unit__c);
            }
            if (srRecord.SRType__c == 'Aldar Estates Move-In' ) {
                system.debug('INSIDE_MOVEIN_RT::');
                assetUpdateList.add(srRecord);
            }
        }
        
        Map<String, SalesOrder__c> unitSalesOrderMap = new Map<String, SalesOrder__c>();
        for (SalesOrder__c salesOrder: SalesOrderService.getSalesOrdersByUnitIds(unitIds)) {
            if(salesOrder.Status__c == Constants.SO_STATUS_SOLD || salesOrder.Status__c == Constants.SO_STATUS_RTO_SOLD || salesOrder.Status__c == Constants.STATUS_APPROVAL_PENDING){
                unitSalesOrderMap.put(salesOrder.Unit__c, salesOrder);
            }
            
        }
        
        for (HexaBPM__Service_Request__c srRecord: newSRList) {
            if (srRecord.Unit__c != null && unitSalesOrderMap.containsKey(srRecord.Unit__c) && srRecord.SRType__c !='Cancellation' && srRecord.SubType__c !='Sales Cancellation') {
                SalesOrder__c salesOrder = unitSalesOrderMap.get(srRecord.Unit__c);
                srRecord.HexaBPM__Customer__c = salesOrder.Account__c;
                srRecord.HexaBPM__Contact__c = salesOrder.Contact__c;
                srRecord.SalesOrder__c = salesOrder.Id;
                
                if (srRecord.TotalCollectedAmount__c == null || srRecord.TotalCollectedAmount__c == 0) {
                    srRecord.TotalCollectedAmount__c = salesOrder.TotalBilled__c;
                }
                
                if(srRecord.HexaBPM__Contact__c == null){
                    srRecord.HexaBPM__Contact__c = salesOrder.Account__r.PersonContactId;
                }
                //To Populate PaidEquity__c for Payment Plan Change
                if(srRecord.HexaBPM__Record_Type_Name__c == Constants.PAYMENT_PLAN_CHANGE_DEV_RT){
                    
                    srRecord.PaidEquity__c = ((salesOrder.TotalBilled__c / salesOrder.NetAmount__c) * 100).round();
                    
                    if(!srRecord.Bypass_Equity_Check__c && salesOrder.NumberOfDefaults__c > 0 && srRecord.PaidEquity__c < 20 && salesOrder.HoldFlag__c == true && !srRecord.ExemptValidations__c){
                        srRecord.addError(Utilities.getSystemMessages(Constants.PPC_PAID_EQUITY_VALIDATION).Message__c);
                    }
                }
            }
        }
        
        
        //moveinChanges
        if(!assetUpdateList.isEmpty() || Test.isRunningTest()){
            
            Map<Id, Unit__c> unitMap = new Map<Id, Unit__c>( [SELECT Id,Name FROM Unit__c WHERE Id IN :unitIds] );
            Set<String> unitNames = new Set<String>();
            for (Unit__c unit : unitMap.values()) {
                unitNames.add(unit.Name);
            }
            Map<String, Asset> unitNameToAssetMap = new Map<String, Asset>();
            for (Asset asset : [SELECT Id, ECSS_Unit_Number__c,Unit__r.Name FROM Asset WHERE Unit__r.Name IN :unitNames]) {
                unitNameToAssetMap.put(asset.Unit__r.Name, asset);
            }
            for (HexaBPM__Service_Request__c sr : assetUpdateList) {HexaBPM__Service_Request__c moveInSr = new HexaBPM__Service_Request__c(Id= sr.Id );Unit__c unit = unitMap.get(sr.Unit__c);
                if (unit != null) {Asset matchingAsset = unitNameToAssetMap.get(unit.Name);if (matchingAsset != null && sr.Asset__c != matchingAsset.Id) {sr.Asset__c = matchingAsset.Id;}
                }
            }
        }
        
    }
    
    public static void blockTheSwappedUnit(List<SObject> newSRList, Map<Id, SObject> oldSRMap) {
        List<Unit__c> unitList = new List<Unit__c>();
        List<Id> unitIds = new List<Id>();
        for (HexaBPM__Service_Request__c srRecord: (List<HexaBPM__Service_Request__c>)newSRList) {
            HexaBPM__Service_Request__c oldSR = !oldSRMap.isEmpty() ? (HexaBPM__Service_Request__c)oldSRMap.get(srRecord.Id) : null;
            if (srRecord.SwappedUnit__c != null && (oldSR == null || (oldSR.SwappedUnit__c != srRecord.SwappedUnit__c && oldSR.SwappedUnit__c == null))) {
                Unit__c unit = new Unit__c();
                unit.Id = srRecord.SwappedUnit__c;
                unit.Status__c = Constants.UNIT_STATUS_BLOCKED;
                unit.BlockedBy__c = UserInfo.getUserId();
                unit.BlockedDate__c = Datetime.now();
                unit.BlockedComments__c = Constants.UNIT_BLOCKED_COMMENT;
                unit.BlockedReason__c = Constants.UNIT_BLOCKED_REASON;
                unitList.add(unit);
                
                unitIds.add(srRecord.Unit__c);
                unitIds.add(srRecord.SwappedUnit__c);
            }
        }
        if (!unitIds.isEmpty()) {
            Map<Id, Unit__c> unitMap = new Map<Id, Unit__c>([SELECT Id, Project__r.Name FROM Unit__c WHERE Id IN: unitIds]);
            for (HexaBPM__Service_Request__c srRecord: (List<HexaBPM__Service_Request__c>)newSRList) {
                if (unitMap.containsKey(srRecord.Unit__c) && unitMap.containsKey(srRecord.SwappedUnit__c) && unitMap.get(srRecord.Unit__c).Project__r.Name == unitMap.get(srRecord.SwappedUnit__c).Project__r.Name) {
                    srRecord.UnitFromSameProject__c = Constants.YES;
                } else if (srRecord.UnitFromSameProject__c != Constants.YES) {
                    srRecord.UnitFromSameProject__c = Constants.No;
                }
            }
        }
        if (!unitList.isEmpty()) {
            update unitList;
        }
    }
    
    public static void updateHandoverDetail(List<HexaBPM__Service_Request__c> newHandoverSRList, List<HexaBPM__Service_Request__c> newSRList) {
        
        List<Id> soIds = new List<Id>();
        for (HexaBPM__Service_Request__c srRecord: newHandoverSRList) {
            if (srRecord.SalesOrder__c != null) {
                soIds.add(srRecord.SalesOrder__c);
            }
        }
        System.debug('soIds>>>' + soIds);
        
        List<HexaBPM__Service_Request__c> handoverSRList = [SELECT Id, HandoverDetail__c, SalesOrder__c, HandoverDetail__r.RFODate__c, 
                                                            HandoverDetail__r.ServiceChargeStartDate__c FROM HexaBPM__Service_Request__c 
                                                            WHERE RecordType.Name =: Constants.HANDOVER_RT AND SalesOrder__c IN: soIds 
                                                            AND HandoverDetail__c != null];
        
        Map<Id, HexaBPM__Service_Request__c> handoverSRMap = new Map<Id, HexaBPM__Service_Request__c>();
        for (HexaBPM__Service_Request__c handoverSR: handoverSRList) {
            handoverSRMap.put(handoverSR.SalesOrder__c, handoverSR);
        }
        System.debug('handoverSRMap>>>' + handoverSRMap);
        for (HexaBPM__Service_Request__c srRecord: newSRList) {
            if (srRecord.SalesOrder__c != null && handoverSRMap.containsKey(srRecord.SalesOrder__c)) {
                srRecord.HandoverDetail__c = handoverSRMap.get(srRecord.SalesOrder__c).HandoverDetail__c;
                srRecord.RFODate__c = handoverSRMap.get(srRecord.SalesOrder__c).HandoverDetail__r.RFODate__c;
                srRecord.ServiceChargeStartDate__c = handoverSRMap.get(srRecord.SalesOrder__c).HandoverDetail__r.ServiceChargeStartDate__c;
            }
        }
    }
    
    public static void updateRTORent(List<Id> salesOrderIdForRTORentCalculate, List<HexaBPM__Service_Request__c> newSRList) {
        System.debug('salesOrderIdForRTORentCalculate>>>' + salesOrderIdForRTORentCalculate);
        List<SalesOrder__c> salesOrderList = [SELECT Id, Name, (SELECT Id, Name, InstallmentDate__c, RTOEndDate__c, InstallmentAmount__c 
                                                                FROM InstallmentLines__r ORDER BY InstallmentNumber__c ASC) FROM SalesOrder__c 
                                              WHERE Id IN: salesOrderIdForRTORentCalculate];
        System.debug('salesOrderList>>>' + JSON.serialize(salesOrderList));
        
        Map<Id, List<InstallmentLines__c>> soInstallmentLineMap = new Map<Id, List<InstallmentLines__c>>();
        for (SalesOrder__c salesOrder: salesOrderList) {
            soInstallmentLineMap.put(salesOrder.Id, salesOrder.InstallmentLines__r);
        }
        System.debug('soInstallmentLineMap>>>' + soInstallmentLineMap);
        
        for (HexaBPM__Service_Request__c srRecord: newSRList) {
            if (srRecord.SalesOrder__c != null && soInstallmentLineMap.containsKey(srRecord.SalesOrder__c)) {
                Decimal rent = 0;
                Boolean IsCurrentYear = false;
                for (InstallmentLines__c lines: soInstallmentLineMap.get(srRecord.SalesOrder__c)) {
                    if (!IsCurrentYear && srRecord.TermCommencementDate__c >= lines.InstallmentDate__c && srRecord.TermCommencementDate__c < lines.RTOEndDate__c) {
                        IsCurrentYear = true;
                        Integer noOfDays = srRecord.TermCommencementDate__c.daysBetween(lines.RTOEndDate__c);
                        rent = (lines.InstallmentAmount__c / 365) * noOfDays;
                        break;
                    }
                    // else if (IsCurrentYear) {
                    //     rent += lines.InstallmentAmount__c;
                    // }
                }
                srRecord.AnnualRentForTheRemainingYear__c = rent.setScale(2);
                System.debug('srRecord>>>' + srRecord);
            }
        }
    }
    
    public static void updateChargeCollected(List<HexaBPM__Service_Request__c> newList, List<HexaBPM__Service_Request__c> serviceRequestList) {
        Map<String, ChargeRuleModel> chargeMap = new Map<String, ChargeRuleModel>();
        List<ChargeRuleModel> chargeList = ChargeRuleService.getChargeRuleByType(serviceRequestList);
        for (ChargeRuleModel charge: chargeList) {
            chargeMap.put(charge.serviceRequestId, charge);
        }
        
        for(HexaBPM__Service_Request__c newRecord: newList) {
            if(!chargeMap.isEmpty() && chargeMap.containsKey(newRecord.Id)) {
                ChargeRuleModel chargeRule = chargeMap.get(newRecord.Id);
                newRecord.AmountWithoutVAT__c = chargeRule.chargeAmountPercentage;
                newRecord.ChargeCollected__c = chargeRule.chargeAmountPercentage;
                if (chargeRule.vatChanges != null && chargeRule.vatChanges != 0) {
                    newRecord.ChargeCollected__c = chargeRule.chargeAmountPercentage + ((chargeRule.chargeAmountPercentage * chargeRule.vatChanges) / 100).setScale(2);
                }
                if (chargeRule.chargeRuleId != null) {
                    newRecord.ChargeRule__c = chargeRule.chargeRuleId;
                }
                newRecord.ChargeCollectedInWords__c = Utilities.amountInWords(newRecord.ChargeCollected__c,'Dirham','Fils');
            }
        }
    }
    
    public static void updateBuyerContact(List<HexaBPM__Service_Request__c> newList, List<Id> buyerIdList) {
        List<Account> acclist = AccountService.queryAllFieldsWithExtraFields(buyerIdList);
        Map<Id, Id> accountContactMap = new Map<Id, Id>();
        for (Account acc: acclist) {
            if (acc.isPersonAccount) {
                accountContactMap.put(acc.Id, acc.PersonContactId);
            } else {
                for (Contact con: acc.Contacts) {
                    accountContactMap.put(acc.Id, con.Id);
                }
            }
        }
        
        for(HexaBPM__Service_Request__c newRecord: newList) {
            if(newRecord.BuyerName__c != null && accountContactMap.containsKey(newRecord.BuyerName__c)) {
                newRecord.BuyerContact__c = accountContactMap.get(newRecord.BuyerName__c);
            }
        }
    } ADDED FEB 12*/
    
    /* 
* To check SR configuration logic
*/
    /* ADDED FEB 12 public static void checkSRAutomation(List<HexaBPM__Service_Request__c> newSRList, Map<Id, SObject> oldMap) {
        Set<String> srTypesList = new Set<String>();
        
        for (HexaBPM__Service_Request__c srRecord: newSRList) {
            if (srRecord.SRType__c != null) {
                srTypesList.add(srRecord.SRType__c);
            }
        }
        System.debug('srTypesList: '+ srTypesList);
        
        Map<String, SRAutomation__mdt> srAutomationMap = new Map<String, SRAutomation__mdt>();
        
        if(srTypesList.size() > 0){
            srAutomationMap = Utilities.getSRAutomation(srTypesList);
        }
        System.debug('srAutomationMap: '+ srAutomationMap);
        
        if(srAutomationMap.size() > 0){
            
            Map<String,HexaBPM__Service_Request__c> openSRMap = ServiceRequestService.getOpenServiceRequestByType(srAutomationMap.keySet());
            
            System.debug('openSRMap: '+ openSRMap.size());
            System.debug('openSRMap: '+ openSRMap);
            
            //List<Id> newSRRecordsToBeSubmitted = new List<Id>();
            //HexaBPM__SR_Status__c objSRStatus = [SELECT Id, Name FROM HexaBPM__SR_Status__c WHERE Name =: Constants.SUBMITTED LIMIT 1];
            
            for (HexaBPM__Service_Request__c srRecord: newSRList) {
                
                SRAutomation__mdt srAuto = srRecord.SRType__c != null ? srAutomationMap.get(srRecord.SRType__c) : null;
                HexaBPM__Service_Request__c openSRRecord = new HexaBPM__Service_Request__c();
                if(srRecord.SRType__c =='Aldar Estates Move-In'){
                    openSRRecord = srAuto != null && openSRMap.get(srRecord.Asset__c + '-' + srRecord.SRType__c) != null ? openSRMap.get(srRecord.Asset__c + '-' + srRecord.SRType__c) : null;
                    if (srAuto != null && srAuto.DuplicateCheckRequired__c == true && openSRRecord != null && srRecord.Asset__c != null) {
                        SystemMessages__mdt messageDetails = Utilities.getSystemMessages(Constants.DUPLICATE_SR_MESSAGE);
                        srRecord.addError(messageDetails.Message__c);
                    }
                }else{
                    openSRRecord = srAuto != null && openSRMap.get(srRecord.SalesOrder__c + '-' + srRecord.SRType__c) != null ? openSRMap.get(srRecord.SalesOrder__c + '-' + srRecord.SRType__c) : null;
                    
                    if (srAuto != null && srAuto.DuplicateCheckRequired__c == true && openSRRecord != null && srRecord.SalesOrder__c != null) {
                        SystemMessages__mdt messageDetails = Utilities.getSystemMessages(Constants.DUPLICATE_SR_MESSAGE);
                        srRecord.addError(messageDetails.Message__c);
                    } /*else if(oldMap == null && srAuto != null && srAuto.AutoSubmission__c == true){
newSRRecordsToBeSubmitted.add(srRecord.Id);
}*//* ADDED FEB 12
                }
            } ADDED FEB 12*/
            
            /*if(newSRRecordsToBeSubmitted.size() > 0){
SRUtility.submitSRFuture(newSRRecordsToBeSubmitted);
}*//* ADDED FEB 12
        }
    }
ADDED FEB 12*/    
    /*
* to Auto submit SR
*/
  /* ADDED FEB 12  public static void checkSRAutoSubmitted(List<HexaBPM__Service_Request__c> newSRList) {
        Set<String> srTypesList = new Set<String>();
        
        system.debug('***newSRList: '+newSRList);
        
        for (HexaBPM__Service_Request__c srRecord: newSRList) {
            if (srRecord.SRType__c != null) {
                srTypesList.add(srRecord.SRType__c);
            }
        }
        
        system.debug('***srTypesList: '+srTypesList);
        
        
        Map<String, SRAutomation__mdt> srAutomationMap = new Map<String, SRAutomation__mdt>();
        
        if(srTypesList.size() > 0){
            srAutomationMap = Utilities.getSRAutomation(srTypesList);
        }
        system.debug('***srAutomationMap: '+srAutomationMap);
        
        if(srAutomationMap.size() > 0){
            
            List<Id> newSRRecordsToBeSubmitted = new List<Id>();
            
            for (HexaBPM__Service_Request__c srRecord: newSRList) {
                
                SRAutomation__mdt srAuto = srRecord.SRType__c != null ? srAutomationMap.get(srRecord.SRType__c) : null;
                
                if(srAuto != null && srAuto.AutoSubmission__c == true){
                    newSRRecordsToBeSubmitted.add(srRecord.Id);
                }
            }
            
            if(newSRRecordsToBeSubmitted.size() > 0){
                SRUtility.submitSRFuture(newSRRecordsToBeSubmitted);
            }
        }
    }
    
    public static void updateGoldenVisaDetails(List<HexaBPM__Service_Request__c> newList, Set<Id> customerIdSet) {
        
        List<AggregateResult> aggregateResultList = [SELECT Account__c, SUM(TotalOutstanding__c), Count(Unit__c), SUM(TotalBilled__c) FROM SalesOrder__c Where Account__c IN: customerIdSet AND Status__c = 'Sold' GROUP BY Account__c];
        
        for (HexaBPM__Service_Request__c newRecord: (List<HexaBPM__Service_Request__c>) newList) {
            for(AggregateResult ar : aggregateResultList){               
                String customerId = (String) ar.get('Account__c');
                if(newRecord.HexaBPM__Customer__c == customerId){
                    newRecord.TotalOutstandingAmount__c = (Decimal) ar.get('expr0');
                    newRecord.TotalNumberofUnits__c = (Decimal) ar.get('expr1');
                    newRecord.TotalBilledAmount__c = (Decimal) ar.get('expr2');
                }
            }
        }
    }
    
    public static void submittedLPC(Map<HexaBPM__Service_Request__c, Id> submittedLPCSRWithSOMap) {
        
        List<InstallmentLines__c> installmentLinesList = [SELECT Id, Name, LPCFreezeDate__c, LPCFreezeUntilDate__c FROM InstallmentLines__c WHERE SalesOrder__c IN: submittedLPCSRWithSOMap.values()];
        
        for (InstallmentLines__c ilRecord: installmentLinesList) {
            ilRecord.LPCFreezeDate__c = ilRecord.LPCFreezeDate__c <> null && ilRecord.LPCFreezeDate__c < Date.Today() ? ilRecord.LPCFreezeDate__c : Date.Today();
            ilRecord.LPCFreezeUntilDate__c = ilRecord.LPCFreezeUntilDate__c <> null && ilRecord.LPCFreezeUntilDate__c > Date.Today() + 30 ? ilRecord.LPCFreezeUntilDate__c : Date.Today() + 30;
        }
        update installmentLinesList;
        
        List<Id> srIds = new List<Id>();
        for(HexaBPM__Service_Request__c srRec : submittedLPCSRWithSOMap.keySet()){
            srIds.add(srRec.Id);
        }
        LPCCalloutHelper.getDataForFreezeCallout(srIds, true);
    }
    
    // Added by Adarsh for buyers complaince check 
    public static void ComplianceCheck(HexaBPM__Service_Request__c serviceRequest) {
        if (serviceRequest.BuyerName__c != null) {
            Account accountToUpdate = new Account(Id = serviceRequest.BuyerName__c, Trigger_screening_Case__c = true);
            TriggerHandler.processedIds = new Set<Id>(); // Added by kuhinoor...
            update accountToUpdate;
        }
    }      
    
    
    //Added by Tharun to update ReferredBy Profile Name ASF-1367
    public static void updateAgencySrReferredByProfileName(List<HexaBPM__Service_Request__c> agencySRs)
    {
        Map<String, String> getProfileNameByName = new Map<String, String>();
        List<User> userList =  [SELECT id, Name, ProfileName__c 
                                FROM User 
                                WHERE profilename__c in ('Broker Manager','Sales Manager') 
                                ORDER BY Name ASC];
        for(User singleUser : userList){
            getProfileNameByName.put(singleUser.Name, singleUser.ProfileName__c);
        }
        
        for(HexaBPM__Service_Request__c sr : agencySRs){
            sr.ReferredByProfileName__c = getProfileNameByName.get(sr.ReferredBy__c) != null ? getProfileNameByName.get(sr.ReferredBy__c) : '' ;
        }
    }ADDED FEB 12*/
    //Added by Tharun to update ReferredBy Profile Name ASF-1367
   /* ADDED FEB 12 public static String aldarstaffPTValidation(HexaBPM__Service_Request__c serviceRequest, SalesOrder__c salesOrder){ ADDED FEB 12 */
        /*
* Logic: Staff Purchase Validation for Property Transfer Process : @jira:ASF-1860
*//* ADDED FEB 12
        try{
            if(serviceRequest.RecordType.Name == Constants.PROPERTY_TRANSFER_RT && serviceRequest.HexaBPM__Customer__c != null && serviceRequest.HexaBPM__Customer__r.CustomerType__c!=null && serviceRequest.HexaBPM__Customer__r.CustomerType__c.equalsIgnoreCase(Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF) && serviceRequest.Unit__r.BuildingSectionName__c!=null && serviceRequest.Unit__r.BuildingSectionName__r.AldarStaffTransferThresholdLimit__c !=null){            
                List<String> installmentValues = System.Label.Staff_Purchase_PP_Validation.contains(',')?System.Label.Staff_Purchase_PP_Validation.split(','):new List<string>{System.Label.Staff_Purchase_PP_Validation};
                    List<InstallmentLines__c> installmentLineList = [SELECT Id,InstallmentPercentage__c FROM InstallmentLines__c WHERE SalesOrder__c=:salesOrder.Id ORDER BY InstallmentNumber__c DESC LIMIT 1]; 
                if(!installmentLineList.isEmpty() && installmentLineList[0].InstallmentPercentage__c != null && installmentValues.contains(String.valueOf(installmentLineList[0].InstallmentPercentage__c))){
                    return System.label.Staff_Purchase_Validation_PP_Plan_Error;
                }
                if(!serviceRequest.BuyerName__r.CustomerType__c.equalsIgnoreCase(Constants.ACCOUNT_CUSTOMER_TYPE_ALDAR_STAFF) && salesOrder.EquityPercentage__c != null && serviceRequest.Unit__c!=null ){
                    if(serviceRequest.Unit__r.BuildingSectionName__r.AldarStaffTransferThresholdLimit__c >= salesOrder.EquityPercentage__c){
                        return System.Label.Staff_Purchase_Validation_Threshold_Error;
                    }
                }
            } 
            return null;
        }catch(Exception ex){
            system.debug('Exception:'+ex.getMessage());
            return 'Error! Occured. Reachout your admin.';
        }
    }
    // SR Resale Case Validation
    public static void validatePropertyTransferSR(List<HexaBPM__Service_Request__c> serviceRequests, set<Id> propertyTransferRecIds, set<Id> ptunitIds, set<Id> caseIds){         
        List<case>  casesList=  [select Id,Recordtype_Name__c, Unit__c,Opportunity__c,CaseNumber  from case where ID IN : caseIds];    
        List<Case> listResaleCase=[select Id,CaseCategory__c, SubCategory__c,Opportunity__c,Status,CaseNumber,Unit__c from case  where  CaseCategory__c IN ('Property Transfer', 'Property Transfer NOC') and Opportunity__c !=null and status!='Closed' and Unit__c  IN :ptunitIds];
        Map<ID,Case> listResaleCaseMap =new   Map<ID,Case>();
        for(Case resaleCase:listResaleCase){
            listResaleCaseMap.put(resaleCase.Unit__c, resaleCase);
        }       
        Map<ID,case> unitCaseMap=new Map<ID,case>();
        for (case cs:casesList){
            unitCaseMap.put(cs.Unit__c,cs);
        }
        Map<Id, Unit__c> ptunitsMap = new Map<Id, Unit__c>([SELECT Id, Listed_Date__c, ResaleListed__c, Listing_Expiry_Date__c, ListedCase__c, ListedCase__r.Recordtype_Name__c FROM Unit__c WHERE Id IN :ptunitIds]);
        for(HexaBPM__Service_Request__c sr: serviceRequests){
            if(propertyTransferRecIds.contains(sr.recordTypeId) && listResaleCaseMap.get(sr.Unit__c)!=null){             
                case matchedCase=unitCaseMap.get(sr.Unit__c);
                if(matchedCase==null || matchedCase.CaseNumber!=listResaleCaseMap.get(sr.Unit__c).CaseNumber){
                    String casenumber= listResaleCaseMap.get(sr.Unit__c).CaseNumber;
                    sr.addError(System.label.Resale_Listed_SR_Error + ' ' +casenumber);
                }             
            }          
        }
    }    
    public static void titledeedKARMapping(MAP<ID,ID> salesOrderIdMap){      
        List<String> titleDeedSRs=new List<String>();
        titleDeedSRs.add(Constants.TITLE_DEED_REGISTRATION_RT);
        titleDeedSRs.add(Constants.SPA_READY_TITLE_DEED_REGISTRATION_RT);
        titleDeedSRs.add(Constants.SPA_RTO_PHPP_TITLE_DEED_REGISTRATION_RT);
        
        List<HexaBPM__Service_Request__c> relatedSRs=[select Id,SalesOrder__c from HexaBPM__Service_Request__c where SalesOrder__c IN :salesOrderIdMap.keySet() and RecordType.Name IN :titleDeedSRs];
        if(!relatedSRs.isEmpty()){  
            for (HexaBPM__Service_Request__c sr:relatedSRs){
                if(salesOrderIdMap.get(sr.SalesOrder__c)!=null)
                    sr.HOKAR__c=salesOrderIdMap.get(sr.SalesOrder__c);
            }
            update relatedSRs; 
        }
    }
    public static void handleOfflineProceess(List<sObject> serviceRequests, Map<Id,sObject> oldMap){
        Set<Id> srIdset = new Set<Id>();
        Id pendingSts = [SELECT Id FROM HexaBPM__Status__c WHERE Name ='Pending' LIMIT 1]?.Id;
        for(HexaBPM__Service_Request__c sr: (List<HexaBPM__Service_Request__c>)serviceRequests){
            HexaBPM__Service_Request__c oldSR = (HexaBPM__Service_Request__c)oldMap.get(sr.id);
            if((sr.SRType__c == 'SPA Registration' || sr.SRType__c == 'SPA & Title Deed Registration For Ready Properties') && sr.Proceed_with_Offline__c && oldSR.Proceed_with_Offline__c != sr.Proceed_with_Offline__c){
                srIdset.add(sr.Id);
            }
        }
        if(!srIdset.isEmpty()){
            System.debug('debug:'+[SELECT Id,HexaBPM__Summary__c,HexaBPM__Step_Status__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN: srIdset]);
            List<HexaBPM__Step__c> stpUpd = new List<HexaBPM__Step__c>();
            for(HexaBPM__Step__c stp :[SELECT Id FROM HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Submit Registration' AND HexaBPM__SR__c IN: srIdset AND HexaBPM__Step_Status__c != 'Pending']){
                HexaBPM__Step__c stepObj = new HexaBPM__Step__c();
                stepObj.Id = stp.Id;
                //stepObj.OwnerId = UserInfo.getUserId();
                stepObj.HexaBPM__Status__c = pendingSts;
                stpUpd.add(stepObj);
            }
            if(!stpUpd.isEmpty()){
                update stpUpd;
            }
        }
    }
    
    public static void handleOfflineProcessTDSR(List<sObject> serviceRequests, Map<Id,sObject> oldMap){
        Set<Id> srIdset = new Set<Id>();
        Id pendingSts = [SELECT Id FROM HexaBPM__Status__c WHERE Name ='Pending' LIMIT 1]?.Id;
        for(HexaBPM__Service_Request__c sr: (List<HexaBPM__Service_Request__c>)serviceRequests){
            HexaBPM__Service_Request__c oldSR = (HexaBPM__Service_Request__c)oldMap.get(sr.id);
            if((Test.isRunningTest() && sr.Proceed_with_Offline__c) || (sr.SRType__c == 'Title Deed Registration') && sr.Proceed_with_Offline__c && oldSR.Proceed_with_Offline__c != sr.Proceed_with_Offline__c){
                srIdset.add(sr.Id);
            }
        }
        if(!srIdset.isEmpty()){
            set<String> templateNames =new set<String>();
            templateNames.add('Registration Completion'); 
            templateNames.add('Registration In Progress');
            
            map<string,HexaBPM__SR_Steps__c> stepTemplateMap =new map<string,HexaBPM__SR_Steps__c>();
            for(HexaBPM__SR_Steps__c tempStepCode : [select id,OwnerId,Name,HexaBPM__Sys_Custom_Conditions_Actions__c,HexaBPM__Estimated_Hours__c,HexaBPM__Step_No__c,HexaBPM__Step_Template__c,HexaBPM__Step_Template__r.Name
                                                     from HexaBPM__SR_Steps__c where HexaBPM__SR_Template__r.Name ='Title Deed Registration' and HexaBPM__Step_Template__r.Name IN :templateNames]){
                                                         stepTemplateMap.put(tempStepCode.HexaBPM__Step_Template__r.Name,tempStepCode);
                                                     }
            
            list<HexaBPM__Step__c> stepsToInsert = new list<HexaBPM__Step__c>();
            for(HexaBPM__Service_Request__c srDetails:(List<HexaBPM__Service_Request__c>)serviceRequests){
                for(String tpStepname : templateNames){ 
                    if(stepTemplateMap.containsKey(tpStepname)){
                        HexaBPM__SR_Steps__c tempStep = stepTemplateMap.get(tpStepname);
                        List<HexaBPM__Step__c> stepdupList=[select Id from HexaBPM__Step__c where HexaBPM__SR__c =:srDetails.Id and  HexaBPM__SR_Step__c =:tempStep.Id and HexaBPM__Step_No__c =: tempStep.HexaBPM__Step_No__c];
                        if(stepdupList==null || stepdupList.isEmpty()){
                            HexaBPM__Step__c tempRec = new 
                                HexaBPM__Step__c( ExecuteCustomCode__c =
                                                 tempStep.HexaBPM__Sys_Custom_Conditions_Actions__c,
                                                 HexaBPM__SR_Step__c = tempStep.Id,
                                                 OwnerId = tempStep.OwnerId,
                                                 HexaBPM__SR__c = srDetails.Id,
                                                 HexaBPM__Start_Date__c = System.today(),
                                                 HexaBPM__Step_No__c = tempStep.HexaBPM__Step_No__c,
                                                 HexaBPM__Status__c = pendingSts,
                                                 HexaBPM__Step_Template__c =  tempStep.HexaBPM__Step_Template__c,
                                                 HexaBPM__Summary__c = tempStep.HexaBPM__Step_Template__r.Name,
                                                 HexaBPM__Sys_Step_Loop_No__c = tempStep.HexaBPM__Step_No__c +'_1' );
                            stepsToInsert.add(tempRec);   
                        }
                    }
                }
            }
            if(!stepsToInsert.isEmpty()){
                insert stepsToInsert;
            }
        }
    }ADDED FEB 12*/
    
}