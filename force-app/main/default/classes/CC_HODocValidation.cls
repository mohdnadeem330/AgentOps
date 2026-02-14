/**********************************************************************************************************************
* Name               : CC_HODocvalidation                                                
* Description        : This class is used by Handover Process to validate documents
* Usage              : Handover + Title Deed Process SR PRocess
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     29 Dec 2022      Initial Draft       
******************************************************************************************************************/
global without sharing class CC_HODocValidation implements HexaBPM.iCustomCodeExecutable {
    
    global string EvaluateCustomCode(HexaBPM__Service_Request__c SR, HexaBPM__Step__c stp){
        string result ='Success';
        try{

            if(stp == null || stp.HexaBPM__SR__c == null){
                result='CC_HODocValidation: Invalid SR or SR Step';
            }else{
                HexaBPM__Service_Request__c sRRecord = [SELECT Id, isPlot__c,isPHPPHandover__c, isRTOHandover__c,SRType__c, HexaBPM__Parent_SR__r.isPlot__c ,HexaBPM__Parent_SR__r.isRTOHandover__c, SalesOrder__c /*, isPHPP__c */,Unit__r.Project__r.Name  FROM HexaBPM__Service_Request__c WHERE id =: stp.HexaBPM__SR__c  limit 1];
                HexaBPM__Step__c stepRecord = [select id,HexaBPM__Step_Status__c,Step_Template_Code__c from HexaBPM__Step__c where id = :stp.Id limit 1];
                list<String> requiredDocs = new list<string>();
                string conditinVal='';
                if(stepRecord.Step_Template_Code__c == Constants.STEP_NAME_UTILITY_TRANSFER){
                    
                    StatementOfAccountModel statementOfAccount=StatementOfAccountController.getSalesOrderDetails(sRRecord.SalesOrder__c);                   
                    if(!sRRecord.isPHPPHandover__c && ( statementOfAccount.totalLPC >decimal.valueOf(Label.Ammount_Buffer) || statementOfAccount.totalInstallmentAmountDue>decimal.valueOf(Label.Ammount_Buffer) || statementOfAccount.totalAmountDue >decimal.valueOf(Label.Ammount_Buffer))){
                        return 'Please make sure all payments are cleared to proceed further';
                    }
                    if(sRRecord.SRType__c == 'Handover'){
                        if(sRRecord.isPlot__c){ requiredDocs.add('Service Charges Payment Proof');
                            conditinVal = 'For plots, ';
                        }else if(sRRecord.isRTOHandover__c){ requiredDocs.add('District Cooling Transfer');
                            conditinVal = 'For RTO, ';
                        }else if(sRRecord.isPHPPHandover__c){
                            requiredDocs.add('District Cooling Transfer');
                            requiredDocs.add('Service Charges Payment Proof');
                            conditinVal = 'For PHPP, ';
                        }else{
                            requiredDocs.add('ADDC Certificate');
                            if(!sRRecord.Unit__r.Project__r.Name.contains('Noya')){
                                 requiredDocs.add('District Cooling Transfer');
                            }
                            requiredDocs.add('Service Charges Payment Proof');
                            conditinVal = 'For Unit, ';
                        }
                    }else { if(sRRecord.HexaBPM__Parent_SR__r.isRTOHandover__c){ requiredDocs.add('ADDC Certificate'); conditinVal = 'For RTO converted unit, ';
                        }
                    }
                }else if(stepRecord.Step_Template_Code__c == 'Key Handover'){
                    if(sRRecord.SRType__c == 'Handover'){
                        if(sRRecord.isPlot__c){requiredDocs.add('Signed Plot Possession Certificate');
                            /*if(!sRRecord.isPHPPHandover__c){
                                //requiredDocs.add('Signed Handover NOC Letter');
                            }*/
                             requiredDocs.add('SignedDeclarationofAdherence');
                             conditinVal = 'For plots, ';
                            
                        }else if(sRRecord.isRTOHandover__c){ requiredDocs.add('Signed Key Acceptance Form'); conditinVal = 'For RTO, ';
                            
                        }else if(sRRecord.isPHPPHandover__c){requiredDocs.add('Signed Key Acceptance Form');
                            requiredDocs.add('Signed Declaration of Variance');
                            conditinVal = 'For PHPP, ';
                        }else{
                             if(!sRRecord.Unit__r.Project__r.Name.contains('Noya')){
                                requiredDocs.add('Signed Handover NOC Letter');
                                requiredDocs.add('Signed Key Acceptance Form');
                                requiredDocs.add('SignedDeclarationofAdherence');
                                requiredDocs.add('Signed Acknowledgement of Inspection');
                             }else {
                                 requiredDocs.add('Signed Unified Handover Documents');
                             }
                            conditinVal = 'For Unit, ';
                        }
                    }else {
                        if(sRRecord.HexaBPM__Parent_SR__r.isRTOHandover__c){ requiredDocs.add('Signed Handover NOC Letter');
                           conditinVal = 'For RTO converted unit, ';
                        }
                    }
                }
                list<HexaBPM__SR_Doc__c> srDocs = [select id, DocumentMasterCode__c,HexaBPM__Status__c from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c = :sRRecord.Id and DocumentMasterCode__c in :requiredDocs];
                
                list<String> pendingDocList = new list<String>();
                for( HexaBPM__SR_Doc__c tempDoc : srDocs){  if(tempDoc.HexaBPM__Status__c == 'Pending Upload') { pendingDocList.add(tempDoc.DocumentMasterCode__c); }
                }
                if(requiredDocs.size() != srDocs.size()){ return string.join(srDocs,',') + 'Missing reuired placeholders' + string.join(requiredDocs,',');
                }
                if(!pendingDocList.isEmpty()){ return conditinVal + 'please upload required '+  string.join(pendingDocList,',')+' document(s)';
                }
                
                
            } 
        } catch(Exception e){ result = e.getMessage()+ ' : ' + e.getLineNumber() +' :CC_HODocValidation';
        }
        return result;
    }
}