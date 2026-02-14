global without sharing class CC_PropertyTransferOffplanValidation implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{
            
            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_PropertyTransferOffplanValidation: Invalid SR or SR Step';
            }else{
                
                HexaBPM__Service_Request__c sRRecord = [SELECT Id,Name,AppointmentDate__c, HexaBPM__Customer__c,Compliance_Status__c,Project_City__c,
                                                        ChargeWaivedOff__c, SalesOrder__r.Account__c, ElectronicServiceCharge__c, TitleDeedRegistrationFee__c, 
                                                        MortgageRegistrationFees__c, InProgressDate__c,ChargeType__c, MortgageAmount__c, MortgageBank__c, 
                                                        MortgageApplicationNumber__c,
                                                        MortgageApplicable__c, PaymentDate__c, SPARegistrationDate__c, RegistrationDate__c,EvaluationFee__c,
                                                        EvaluationApplicationNumber__c,ApplicationNumber__c, SalesOrder__c,ApplicationDate__c, 
                                                        SPAApplicationNumber__c, SPAApplicationDate__c, HexaBPM__Contact__c, Unit__r.Name,
                                                        Unit__c, MortgageConfirmationDate__c,BuyerName__c,Unit__r.Project__r.City__c,Origin__c   
                                                        FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                
                SalesOrder__c salesOrder = SalesOrderService.queryAllFieldsWithExtraFields(new List<Id>{sRRecord.SalesOrder__c})[0];
                
                if(stp.HexaBPM__Summary__c == 'Charge Fees'){
                    List<ReceiptAcknowledgement__c> reciptList =[Select Id,Name From ReceiptAcknowledgement__c where ServiceRequest__c = :sRRecord.Id];
                    if(reciptList.isempty() && !sRRecord.ChargeWaivedOff__c){
                        result = 'Please select Charge Type & enter receipt';
                    }
                }
                if(stp.HexaBPM__Summary__c == 'Book Customer Appointment'){ 
                    if(sRRecord.AppointmentDate__c ==null){
                        result = 'Please book appointment';
                    }
                }
                
                System.debug('@@@stp.HexaBPM__Summary__c '+stp.HexaBPM__Summary__c );
                if(stp.HexaBPM__Summary__c == 'Verification of Seller Profile'){
                    List<HexaBPM__SR_Doc__c> sellerPassportCopyList =  [SELECT Id, Name ,HexaBPM__Status__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c =:sRRecord.Id AND Name ='Seller Passport Copy'];
                    if(!sellerPassportCopyList.isempty() && sellerPassportCopyList[0].HexaBPM__Status__c !='Uploaded' && sRRecord.Origin__c !='Customer Portal' && sRRecord.Origin__c !='Customer App'){
                         result = 'Please upload "Seller Passport Copy" to proceed.';
                    }
                    Boolean sellerKyc = UnitAvailabilityWebService.checkCustomerKYCStatus(sRRecord.HexaBPM__Customer__c); if(!sellerKyc){ result = 'Please complete Seller KYC';}
                }
                
                if(stp.HexaBPM__Summary__c == 'Verification of Buyer Profile'){   
                    List<HexaBPM__SR_Doc__c> buyerPassportCopyList =  [SELECT Id, Name ,HexaBPM__Status__c FROM HexaBPM__SR_Doc__c WHERE HexaBPM__Service_Request__c =:sRRecord.Id AND Name ='Buyer Passport Copy'];
                    if(!buyerPassportCopyList.isempty() && buyerPassportCopyList[0].HexaBPM__Status__c !='Uploaded' && sRRecord.Origin__c !='Customer Portal' && sRRecord.Origin__c !='Customer App'){
                         result = 'Please upload "Buyer Passport Copy" to proceed.';
                    }
                    Boolean buyerKyc = UnitAvailabilityWebService.checkCustomerKYCStatus(sRRecord.BuyerName__c); 
                    if(sRRecord.BuyerName__c == null){                      
                        result = 'Please enter buyer details';
                    }
                    else  if(!buyerKyc){result = 'Please complete Buyer KYC';}
                }
                if(stp.HexaBPM__Summary__c == 'Compliance Check for Buyers'){                    
                    if(sRRecord.Compliance_Status__c !='Cleared'){                      
                        result = 'Please update compliance status if verification is done';
                    }else{string documentStats =  CheckPOADocumentStatus(sRRecord.Id,'POA_Document');if(documentStats =='Uploaded'){
                           // ManualSrStepOpenFromApex('Property Transfer (Off Plan)',sRRecord.Id,'POA Verification');
                        }
                    }
                    
                }
                if(stp.HexaBPM__Summary__c == 'Finance Verification'){ 
                  List<ReceiptAllocation__c> admReceiptAllocationList =[Select id From ReceiptAllocation__c where SalesOrderOtherCharges__c In (Select id From SalesOrderOtherCharges__c where TypeOfCharge__c ='ADM Fee' and SalesOrder__c= :sRRecord.SalesOrder__c) and SalesOrder__c=:sRRecord.SalesOrder__c and ReceiptStatus__c  In ('Received','Cleared')];
                    if(admReceiptAllocationList.isEmpty() && sRRecord.Project_City__c == 'Abu Dhabi'){ result = 'Please update status of Receipt Acknowledgement for ADM FEE';
                    }
                }
                
                if(stp.HexaBPM__Summary__c == 'DD form by the buyer / PDCs / WT'){ 
                    Municipality_Fee_Details__mdt municipalityFee = SRUtility.fetchMunicipalityFee(salesOrder.Unit__r.Project__r.City__c);
                    System.debug('@@@municipalityFee'+municipalityFee);
                    if(municipalityFee <> null && municipalityFee.Municipality_Fee_perc__c <> null && municipalityFee.Municipality_Charge__c <> null){
                        System.debug('@@@InsidemunicipalityFee'+municipalityFee);
                        Decimal ADMAdminFeetoBeCharged = municipalityFee.Municipality_Charge__c;
                        Decimal totalCharges;
                        system.debug('totalcharges' + municipalityFee.Municipality_Charge__c.setScale(2) + (salesOrder.AmountPayable__c * (municipalityFee.Municipality_Fee_perc__c/100)).setScale(2));
                        if(!(sRRecord.ChargeType__c == 'Transfer Next of Kin (Death)' || sRRecord.ChargeType__c == 'Court Order'|| sRRecord.ChargeType__c == 'Transfer Next of Kin (Family)'))
                        {
                            totalCharges = municipalityFee.Municipality_Charge__c.setScale(2) + (salesOrder.AmountPayable__c * (municipalityFee.Municipality_Fee_perc__c/100)).setScale(2);
                            //Added by Kuhinoor....DD form by the buyer / PDCs / WT
                            String excludedCity = System.label.Excluded_OC_City;
                            Set<String> excludedCitySet = String.isNotBlank(excludedCity) ? new Set<String>( excludedCity.split(',')) : null; 
                            System.debug('@@@excludedCitySet'+excludedCitySet);
                            if(sRRecord != null && String.isNotBlank( sRRecord.Unit__r.Project__r.City__c) 
                               && !excludedCitySet.contains(sRRecord.Unit__r.Project__r.City__c)){
                                   SalesOrderOtherCharges__c newADMCharge = SRUtility.createSalesOrderOtherCharge(sRRecord, municipalityFee.MasterLabel, totalCharges);
                                   System.debug('@@@newADMCharge'+newADMCharge);
                               }
                        }
                    }
                }
                
                if(stp.HexaBPM__Summary__c == 'Post Sales Final Approval'){
                    
                    List<DirectDebitRequest__c> ddrList = [SELECT Id FROM DirectDebitRequest__c WHERE SalesOrder__c =: sRRecord.SalesOrder__c 
                                                           AND Account__c =: sRRecord.HexaBPM__Customer__c AND isActive__c = true AND 
                                                           (NOT Status__c IN ('Cancelled','Cancellation in progress','Cancellation Rejected','Rejected by Bank','Cancellation Sent to Bank')) LIMIT 1];
                    
                    if(!ddrList.isEmpty()){
                        update new DirectDebitRequest__c[]{new DirectDebitRequest__c(Id = ddrList[0].Id,Status__c = 'Cancellation in progress')};
                            }
                    List<HexaBPM__Step__c> pendingUpcomingInstallment = [SELECT Id, Name,HexaBPM__Summary__c,HexaBPM__Status__r.Name FROM HexaBPM__Step__c where HexaBPM__Status__r.Name = 'Pending' AND HexaBPM__Summary__c = 'Upcoming Installment Cleared' and HexaBPM__SR__c =: sRRecord.Id LIMIT 1];   
                    if(!pendingUpcomingInstallment.isEmpty()){
                        result = 'Please complete "Upcoming Installment Cleared" step to proceed further.';
                    }
                }    
                
                if(stp.HexaBPM__Summary__c == 'Prepare DD Cancellation and PDC documents'){   
                    boolean paymentMilestoneCheck = CheckPaymentMilestoneDays(sRRecord.SalesOrder__c,sRRecord.AppointmentDate__c);
                    if(paymentMilestoneCheck){
                        ManualSrStepOpenFromApex('Property Transfer (Off Plan)',sRRecord.Id,'Upcoming Installment Cleared');
                    }
                }
            }
            return result;
        }
        catch(exception ex){ return result;
                           }
    }
    
    public static string CheckPOADocumentStatus(Id srId,String documentName) {
        string docStatus; List<HexaBPM__SR_Doc__c> srDocList = [Select id,Name,HexaBPM__Status__c From HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c =:srId and DocumentMasterCode__c =:documentName limit 1];if(!srDocList.isempty()){ return srDocList[0].HexaBPM__Status__c;}else{return 'Document Not Found';
        }
        
    }
    
    public static boolean CheckPaymentMilestoneDays(string salesorderId,datetime appointmentDate) {
        Date appointmentDateOnly = appointmentDate.date();
        Date limitDate = appointmentDateOnly.addDays(45);
        List<InstallmentLines__c> listInstallmentLines = [Select id From InstallmentLines__c where 	SalesOrder__c =:salesorderId AND (StatusIndicator__c Like '%Partially%' OR StatusIndicator__c Like '%Not%') AND (InstallmentDate__c  >= :appointmentDateOnly AND InstallmentDate__c <= :limitDate) ];
        if(!listInstallmentLines.isempty())    {
            return true;
        }
        else{
            return false;
        }
    }
    
    public static void poaVerifiedStepStatusCheck(Set<Id> srId){
        HexaBPM__Service_Request__c srRec = [SELECT Id,SRType__c FROM HexaBPM__Service_Request__c WHERE Id IN: srId LIMIT 1];
        if(srRec.SRType__c == 'Property Transfer (Off Plan)'){
            Id pendingStatus = ServiceRequestTriggerHelper.getStepStatus().get(Constants.PENDING_STATUS)?.Id;
            Id rejectedStatus = ServiceRequestTriggerHelper.getStepStatus().get(Constants.STEP_REJECTED_STATUS)?.Id;
            Id approvedStatus = ServiceRequestTriggerHelper.getStepStatus().get(Constants.STATUS_APPROVED)?.Id;
            List<HexaBPM__Step__c> poaSteps = [SELECT Id, HexaBPM__Status__c,HexaBPM__SR__c FROM HexaBPM__Step__c WHERE HexaBPM__SR__c IN: srId AND HexaBPM__Summary__c = 'POA Verification'];
            if(poaSteps.isEmpty()){
                ManualSrStepOpenFromApex('Property Transfer (Off Plan)', String.valueOf(srRec.Id), 'POA Verification');
                return;
            }
            
            for(HexaBPM__Step__c step: poaSteps){
                if(step.HexaBPM__Status__c == pendingStatus || step.HexaBPM__Status__c == approvedStatus){return;
                }
            }ManualSrStepOpenFromApex('Property Transfer (Off Plan)', String.valueOf(srRec.Id), 'POA Verification');   
        }
    }
    
    public static void ManualSrStepOpenFromApex(string srTemplateName,string srId,string stepTemplateName){
        system.debug('--9--');
        List<HexaBPM__SR_Steps__c> tempStepCode = [select id,OwnerId,Name,HexaBPM__Sys_Custom_Conditions_Actions__c,HexaBPM__Estimated_Hours__c,HexaBPM__Step_No__c,HexaBPM__Step_Template__c,HexaBPM__Step_Template__r.Name
                                                   from HexaBPM__SR_Steps__c where HexaBPM__SR_Template__r.Name =:srTemplateName and HexaBPM__Step_Template__r.Name =:stepTemplateName limit 1];
        if(!tempStepCode.isempty()){
            system.debug('--10--');
            List<HexaBPM__Step__c> stepsToInsert = new  List<HexaBPM__Step__c>();
            Id pendingStatus = ServiceRequestTriggerHelper.getStepStatus().get(Constants.PENDING_STATUS)?.Id;
            HexaBPM__Step__c tempRec = new   HexaBPM__Step__c( ExecuteCustomCode__c =
                                                              tempStepCode[0].HexaBPM__Sys_Custom_Conditions_Actions__c,
                                                              HexaBPM__SR_Step__c = tempStepCode[0].Id,
                                                              OwnerId = tempStepCode[0].OwnerId,
                                                              HexaBPM__SR__c = srId,
                                                              HexaBPM__Start_Date__c = System.today(),
                                                              HexaBPM__Step_No__c = tempStepCode[0].HexaBPM__Step_No__c,
                                                              HexaBPM__Status__c = pendingStatus,
                                                              HexaBPM__Step_Template__c =  tempStepCode[0].HexaBPM__Step_Template__c,
                                                              HexaBPM__Summary__c =tempStepCode[0].HexaBPM__Step_Template__r.Name,
                                                              HexaBPM__Sys_Step_Loop_No__c = tempStepCode[0].HexaBPM__Step_No__c +'_1' );
            insert  tempRec;
        }
    }
}