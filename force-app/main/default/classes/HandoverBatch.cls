/**********************************************************************************************************************
* Name               : HandoverBatch                                                        
* Description        : Class to perform handover action in batch
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/09/2022      Initial Draft       
******************************************************************************************************************/
global class HandoverBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{
    set<ID> srIds = new set<ID>();
    String action='';
    public HandoverBatch(set<ID> recordIds, String actionName){
        srIds=recordIds;
        action=actionName;
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query='select id,SalesOrder__c,HandoverDetail__c,SalesOrder__r.Account__r.PersonEmail,SalesOrder__r.Account__r.isPersonAccount,SalesOrder__r.Account__r.Email__c, SalesOrder__r.Contact__c, SalesOrder__r.Contact__r.Email,HandoverDetail__r.LastInstallment__c,HandoverDetail__r.DealType__c,IsRTOConverted__c,isPlot__c,Unit__r.Project__r.Name,HandoverDetail__r.HandoverPhasingLetterSent__c, HandoverDetail__r.CHOSent__c, HandoverDetail__r.RFOSent__c, HandoverDetail__r.HO_Snagging_Letter_Sent__c from HexaBPM__Service_Request__c where id in :srIds' ;
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<HexaBPM__Service_Request__c> scope){
        System.debug('####scope: '+scope);
        map<id,HexaBPM__Service_Request__c> srMap = new map<id,HexaBPM__Service_Request__c>(scope);
        set<ID> soToProcess = new set<ID>();
         set<ID> srToProcess = new set<ID>();
        for(HexaBPM__Service_Request__c tempRec : scope){
            soToProcess.add(tempRec.SalesOrder__c);
            srToProcess.add(tempRec.Id);
        }
        map<id,set<String>> soToJointOwnerMap =  DefaultAndTerminationUtility.getOwnerEmailList(soToProcess);
        
        
        //Send Email Notifications
        if(action == HandoverUtility.HANDOVERACTION_SEND_HC || action == HandoverUtility.HANDOVERACTION_SEND_HP  || action == HandoverUtility.HANDOVERACTION_SEND_HO || action == HandoverUtility.HANDOVERACTION_SEND_RFO || action == HandoverUtility.HANDOVERACTION_SEND_SNAG){
            //Generate Email Notification by setting HexaBPM__Generate_Document__c
            //Update steps as completed
            list<HandoverDetails__c> handoverDetailsToUpdate =new list<HandoverDetails__c> ();
            map<id,SalesOrder__C> soDetailsToUpdate =new map<id,SalesOrder__C>();
            string deliveryOptionName='';
            string documentType='';
            map<id,id> srToDesnagReportID = new map<id,id>();
            map<id,id> srToSnagReportID = new map<id,id>();

            if(action == HandoverUtility.HANDOVERACTION_SEND_HC){
                documentType= Constants.HO_HC_LETTER ;
            }else if(action == HandoverUtility.HANDOVERACTION_SEND_HP){
                documentType= Constants.HO_HP_LETTER;
                If(scope[0].HandoverDetail__r.HandoverPhasingLetterSent__c){
                    return;
                }
               
            }else if(action == HandoverUtility.HANDOVERACTION_SEND_HO){
                documentType=  !scope[0].isPlot__c && (scope[0].HandoverDetail__r.DealType__c == Constants.HANDOVER_RT 
                    || scope[0].HandoverDetail__r.DealType__c==Constants.HANDOVER_PROPERTYTRANSFER_DEAL_TYPE 
                    ||scope[0].HandoverDetail__r.DealType__c==Constants.HANDOVER_RTO_DEAL_TYPE
                    ||scope[0].HandoverDetail__r.DealType__c==Constants.HANDOVER_NEW_SALE) ?
                    Constants.HO_HO_LETTER : Constants.HO_HC_LETTER ;
                if(documentType==Constants.HO_HO_LETTER && scope[0].HandoverDetail__r.CHOSent__c){
                    return;
                }
            }else if(action == HandoverUtility.HANDOVERACTION_SEND_RFO){
                documentType= Constants.HO_RFO_LETTER ;
                if(scope[0].HandoverDetail__r.RFOSent__c){
                   // return;
                }
                srToDesnagReportID = HandoverUtility.getDesnagReportID(srIds);
            }else if(action == HandoverUtility.HANDOVERACTION_SEND_SNAG){
                documentType= Constants.HO_DOC_CUST_SNAG ;
                if(scope[0].HandoverDetail__r.HO_Snagging_Letter_Sent__c){
                    return;
                }
                srToSnagReportID = HandoverUtility.getSnagReportID(srIds);
                
            }

            deliveryOptionName= documentType+ ' Email';
            //Loop__DDP_Integration_Option__c deliveryOption =  [select id,Name,Loop__DDP__c,Loop__DDP__r.Name from Loop__DDP_Integration_Option__c where name = :deliveryOptionName limit 1];
            //get placeholders
            map<id,HexaBPM__SR_Doc__c> docMap = new map<id,HexaBPM__SR_Doc__c>([select id,HexaBPM__Service_Request__c, SendgridCommunication__c from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c in : srMap.keySet() and DocumentMasterCode__c = :documentType]);
            map<id,id> docToCDMap = new map<id,id>(); //(action == HandoverUtility.HANDOVERACTION_SEND_SNAG ? new map<id,id>(): HandoverUtility.generateSOA(docMap.keySet()));
            //Desnag report ID
           
            map<id,id> srToSAOReportID= HandoverUtility.getSOAReportID(srToProcess);
            for(ID docID :docMap.keySet() ){
                //docMap.get(docID).DocgenPackageId__c =  deliveryOption.Loop__DDP__c;
                //docMap.get(docID).DeliveryOptionId__c =  deliveryOption.Id;
              
              //  Id result=HandoverUtility.getERPSOAContentDocument(new List<Id>(srMap.keySet()));
                if(documentType==Constants.HO_HP_LETTER || 
                     (documentType==Constants.HO_HC_LETTER && scope[0].Unit__r.Project__r.Name == Label.Handover_SOA_Validity)){
                    docMap.get(docID).AttachmentID__c =srToSAOReportID.get(docMap.get(docID).HexaBPM__Service_Request__c);
                }else{
                   docMap.get(docID).AttachmentID__c = srToSnagReportID.containskey(docMap.get(docID).HexaBPM__Service_Request__c)  ? srToSnagReportID.get(docMap.get(docID).HexaBPM__Service_Request__c)  :null /*docToCDMap.get(docID)*/; 
                }
                docMap.get(docID).AttachmentID2__c = srToDesnagReportID.containskey(docMap.get(docID).HexaBPM__Service_Request__c) ? srToDesnagReportID.get(docMap.get(docID).HexaBPM__Service_Request__c) : null ;
                if(!docMap.get(docID).SendgridCommunication__c){
                    docMap.get(docID).HexaBPM__Generate_Document__c = true;
                }
               
                String emailId='';
                if(srMap.get(docMap.get(docID).HexaBPM__Service_Request__c).SalesOrder__r.Account__r.isPersonAccount) {
                    emailId=srMap.get(docMap.get(docID).HexaBPM__Service_Request__c).SalesOrder__r.Account__r.PersonEmail;
                }else if(!srMap.get(docMap.get(docID).HexaBPM__Service_Request__c).SalesOrder__r.Account__r.isPersonAccount &&
                          srMap.get(docMap.get(docID).HexaBPM__Service_Request__c).SalesOrder__r.Contact__c !=null)  {
                          
                              emailId= srMap.get(docMap.get(docID).HexaBPM__Service_Request__c).SalesOrder__r.Contact__r.Email;
                }else if(!srMap.get(docMap.get(docID).HexaBPM__Service_Request__c).SalesOrder__r.Account__r.isPersonAccount ){
                            emailId= srMap.get(docMap.get(docID).HexaBPM__Service_Request__c).SalesOrder__r.Account__r.Email__c;
                 }
                
                if(emailId!='' && soToJointOwnerMap.containsKey(srMap.get(docMap.get(docID).HexaBPM__Service_Request__c).SalesOrder__c)){
                    emailId=emailId+','+ string.join(new list<String>(soToJointOwnerMap.get(srMap.get(docMap.get(docID).HexaBPM__Service_Request__c).SalesOrder__c)),',');
                }
                
                docMap.get(docID).RecipientEmail__c = emailId;
                
                System.debug('***SendGridInfo***'+docMap.get(docID).SendgridCommunication__c+documentType+docMap.KeySet());
                
                if(docMap.get(docID).SendgridCommunication__c){
                    Map<String,String> docConfigMap=new  Map<String,String>();
                    docConfigMap.put(Constants.HO_HP_LETTER,'tpl_ho1_1');
                    docConfigMap.put(Constants.HO_HO_LETTER,'tpl_ho2');
                    docConfigMap.put( Constants.HO_RFO_LETTER,'tpl_ho2_3');
                    docConfigMap.put(Constants.HO_DOC_CUST_SNAG,'tpl_ho4');
                    
                    if(docConfigMap.get(documentType)!=null){
                         System.debug('***SendGridInfo 11111***'+docMap.get(docID).SendgridCommunication__c+docConfigMap.get(documentType)+docMap.KeySet());
                        if(!Test.isRunningTest()){
                            SendGridIntegrationController.sendHandoverPhasingLetter(new List<ID>(docMap.KeySet()), docConfigMap.get(documentType));
                        }
                        
                    }
                }
               //documentType 
                 
                
                /*
                docMap.get(docID).RecipientEmail__c = 
                    ( srMap.get(docMap.get(docID).HexaBPM__Service_Request__c).SalesOrder__r.Contact__c !=null?
                     srMap.get(docMap.get(docID).HexaBPM__Service_Request__c).SalesOrder__r.Contact__r.Email 
                     : srMap.get(docMap.get(docID).HexaBPM__Service_Request__c).SalesOrder__r.Account__r.PersonEmail) 
                     + (soToJointOwnerMap.containsKey(srMap.get(docMap.get(docID).HexaBPM__Service_Request__c).SalesOrder__c) ?  ','+ string.join(new list<String>(soToJointOwnerMap.get(srMap.get(docMap.get(docID).HexaBPM__Service_Request__c).SalesOrder__c)),',') : '' );
               */
            }
            if (!Test.isRunningTest()){
               update docMap.values(); 
            }
            
            //Close the step
            set<String> docTypeSet = new set<String>{documentType};
            if(action == HandoverUtility.HANDOVERACTION_SEND_HO){docTypeSet.add(Constants.HO_HO_LETTER); }
            if(documentType == Constants.HO_RFO_LETTER){ docTypeSet.add(Constants.HO_HO_LETTER); }
            
            list<HexaBPM__Step__c> stepsToClose = [select id,HexaBPM__SR__c from HexaBPM__Step__c where HexaBPM__SR__c in :srMap.Keyset() and Step_Template_Code__c in :docTypeSet and HexaBPM__Step_Status__c =:Constants.STEP_STATUS_PENDING];
            
            if(!stepsToClose.isEmpty()){
                HexaBPM__Status__c stepStatus= [select id,name from HexaBPM__Status__c where name = :Constants.STEP_STATUS_SENT limit 1];
                for(HexaBPM__Step__c tempRec : stepsToClose){
                    tempRec.HexaBPM__Status__c = stepStatus.Id;
                }
                update stepsToClose;
            }
            //Update date on HO
            for(HexaBPM__Service_Request__c tempSRRecord : srMap.values()){
                HandoverDetails__c hoRecord = new HandoverDetails__c(id =tempSRRecord.HandoverDetail__c );
                if(action == HandoverUtility.HANDOVERACTION_SEND_HC){
                    hoRecord.HandoverCompletionLetterSent__c=true;
                }else if(action == HandoverUtility.HANDOVERACTION_SEND_HP){
                    hoRecord.HandoverPhasingLetterSent__c=true;
                }else if(action == HandoverUtility.HANDOVERACTION_SEND_HO){
                    hoRecord.CHOSent__c=true;
                    if (scope[0].isPlot__c ||(scope[0].HandoverDetail__r.DealType__c != Constants.HANDOVER_RT 
                    || scope[0].HandoverDetail__r.DealType__c !=Constants.HANDOVER_PROPERTYTRANSFER_DEAL_TYPE 
                    ||scope[0].HandoverDetail__r.DealType__c !=Constants.HANDOVER_RTO_DEAL_TYPE
                    ||scope[0].HandoverDetail__r.DealType__c !=Constants.HANDOVER_NEW_SALE)){
                            hoRecord.HandoverCompletionLetterSent__c=true;
                    }
                }else if(action == HandoverUtility.HANDOVERACTION_SEND_RFO){
                    hoRecord.RFOSent__c=true;
                }else if(action == HandoverUtility.HANDOVERACTION_SEND_SNAG){
                    hoRecord.HO_Snagging_Letter_Sent__c=true;
                }
                
                handoverDetailsToUpdate.add(hoRecord);
            }
            if(!handoverDetailsToUpdate.isEmpty()){
                update handoverDetailsToUpdate;
            }
        }
    }
    global void finish(Database.BatchableContext bc){
       
    }    
}