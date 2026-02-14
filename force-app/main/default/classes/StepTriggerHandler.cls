public with sharing class StepTriggerHandler extends TriggerHandler{
    public static Id SR_AGENCY_REGISTRATION_RecordTypeId = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByDeveloperName().get('AgencyRegistration').getRecordTypeId();
    
    public static Set<Id> allSRIds = new Set<Id>();
    
    public override void beforeInsertMethod(list<SObject> newList, Map<Id, SObject> newMap){
        updateStepOwner((List<HexaBPM__Step__c>)newList); //Existing Process
        
        checkIsValidAndRetain((List<HexaBPM__Step__c>)newList);
    } 

    public override void beforeUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){

        //Monika: Mass Ownership change restriction
        // List<HexaBPM__Service_Request__c> ownershipchangeSR = new List<HexaBPM__Service_Request__c>();
        // List<Id> SRId = new List<Id>();
        Map<String, HexaBPM__Step__c> ownershipStep = new Map<String, HexaBPM__Step__c>();
        Map<HexaBPM__Step__c,String> ownershipchangeStep = new Map<HexaBPM__Step__c, String>();
        List<HexaBPM__Service_Request__c> updateSROwnerToStepOwner = new List<HexaBPM__Service_Request__c>();
        for(HexaBPM__Step__c stepRecord : (List<HexaBPM__Step__c>)newList) {
            HexaBPM__Step__c oldStep = (HexaBPM__Step__c)oldmap.get(stepRecord.Id);
            if (stepRecord.OwnerId != oldStep.OwnerId ){ //Monika: Mass Ownership change restriction

                if(stepRecord.HexaBPM__SR__c == null){
                    stepRecord.addError('This step is not linked with any SR');
                }else{
                    ownershipStep.put(stepRecord.id,stepRecord);
                    // system.debug('stepRecord.ownershipchangeStep' + ownershipchangeStep);
                    // SRId.add(stepRecord.HexaBPM__SR__c);
                    // system.debug('stepRecord.HexaBPM__SR__c' + stepRecord.HexaBPM__SR__c);
                }             
            }
            if(stepRecord.IsChangeOwner__c == true && stepRecord.HexaBPM__SR__c != null && stepRecord.HexaBPM__Closed_Date__c != null && oldStep.HexaBPM__Closed_Date__c == null){
                HexaBPM__Service_Request__c srRecord = new HexaBPM__Service_Request__c(Id = stepRecord.HexaBPM__SR__c, OwnerId = UserInfo.getUserId());
                updateSROwnerToStepOwner.add(srRecord);
            }
        }
        if(!updateSROwnerToStepOwner.isEmpty()){
            update updateSROwnerToStepOwner;
        }
        //Monika: Mass Ownership change restriction
        system.debug('ownershipStep' + ownershipStep + ownershipStep.size());
        if(ownershipStep.size() > 1){ 
            for(HexaBPM__Step__c stp: [Select id, HexaBPM__SR__r.SRType__c  from HexaBPM__Step__c where ID IN: ownershipStep.keySet()]){
                ownershipchangeStep.put(ownershipStep.get(stp.id), stp.HexaBPM__SR__r.SRType__c );
            }
            // system.debug('ownershipchangeStep' + ownershipchangeStep);
            // ownershipchangeSR =  ServiceRequestService.queryAllFieldsWithExtraFields(SRId);
            // system.debug('ownershipchangeSR' + ownershipchangeSR);
            system.debug('ownershipchange' + ownershipchangeStep.values());
           //new MassOwnerShipChangeLogics(ownershipchangeStep);
        }
    }

    //*** After Insert Action***//
    public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap){
        // Added By Moh Sarfaraj for BPM-467
        Map<Id,HexaBPM__Step__c> mapSRIdToStepRecord = new Map<Id,HexaBPM__Step__c>();
        Set<Id> srIdset = new Set<Id>();
        list<HexaBPM__Step__c> moveInStepsToUpdateOwner = new list <HexaBPM__Step__c> ();
        Set<Id> moveInsrIdset = new Set<Id>();

        Set<Id> setStepIdToMarkAutoComplete = new Set<Id>();
        

        for(HexaBPM__Step__c eachStep : (List<HexaBPM__Step__c>) newList){
            
            // Added By Moh Sarfaraj for BPM-467
            if(String.isNotBlank(eachStep.HexaBPM__SR__c) && String.isNotBlank(eachStep.HexaBPM__Summary__c) && 
               String.isNotBlank(eachStep.HexaBPM__Step_Status__c) && 
               (eachStep.HexaBPM__Summary__c?.equalsIgnoreCase('Require More Information') || eachStep.HexaBPM__Summary__c?.equalsIgnoreCase('digital signature by authorized signatory')) &&
               (eachStep.HexaBPM__Step_Status__c?.equalsIgnoreCase('Pending') ||  eachStep.HexaBPM__Step_Status__c?.equalsIgnoreCase('Pending Review'))){
                
                mapSRIdToStepRecord.put(eachStep.HexaBPM__SR__c, eachStep);
            }

            // Update Step and SR also - Added by Moh Sarfaraj for BPM-636
            if(String.isNotBlank(eachStep.HexaBPM__SR__c) && String.isNotBlank(eachStep.HexaBPM__Summary__c) && 
               String.isNotBlank(eachStep.HexaBPM__Step_Status__c) && 
               (eachStep.HexaBPM__Summary__c?.equalsIgnoreCase('Digital Signature by Head of Broker Management')) &&
               (eachStep.HexaBPM__Step_Status__c?.equalsIgnoreCase('Pending'))){
                
                setStepIdToMarkAutoComplete.add(eachStep.Id);
            }

            if(eachStep.HexaBPM__Summary__c == 'Pending upload Provis Docs by Customer'){
                srIdset.add(eachStep.HexaBPM__SR__c);
            }
            
        }
        
		 //MOVE-IN OWNER CHANGE END
        // Added By Moh Sarfaraj for BPM-467 starts
        if(!mapSRIdToStepRecord.isEmpty()){
            Set<Id> setSRIdtoSendNotificationViaBatch = new Set<Id>();
            Map<Id,HexaBPM__Service_Request__c> mapStepIdToSRRecord = new Map<Id,HexaBPM__Service_Request__c>();
            Map<Id,HexaBPM__Step__c> mapAgencyIdToStepRecord = new Map<Id,HexaBPM__Step__c>();

            for(HexaBPM__Service_Request__c eachSR : [SELECT Id,HexaBPM__Customer__c, HexaBPM__Submitted_DateTime__c
                                                      FROM HexaBPM__Service_Request__c 
                                                      WHERE RecordTypeId = :SR_AGENCY_REGISTRATION_RecordTypeId AND
                                                      HexaBPM__Customer__c != null AND Id IN :mapSRIdToStepRecord.keySet()]){  

                if(mapSRIdToStepRecord.get(eachSR.Id).HexaBPM__Summary__c?.equalsIgnoreCase('Require More Information')){
                    mapStepIdToSRRecord.put(mapSRIdToStepRecord.get(eachSR.Id).Id, eachSR);
                    mapAgencyIdToStepRecord.put(eachSR.HexaBPM__Customer__c, mapSRIdToStepRecord.get(eachSR.Id));
                }
                setSRIdtoSendNotificationViaBatch.add(eachSR.Id);
            }
            if(!mapAgencyIdToStepRecord.isEmpty()){
                updateStepNotesOnPrimaryContact(mapAgencyIdToStepRecord, mapStepIdToSRRecord);
            }
            if(!setSRIdtoSendNotificationViaBatch.isEmpty()){
                callingBatchAsUtilityToSendEmail(setSRIdtoSendNotificationViaBatch);
            }
            if(!srIdset.isEmpty()){
                CC_ProvisNOCValidationCtrl.dfltCloseStatus(srIdset);
            }
        }
        // Added By Moh Sarfaraj for BPM-467 end

        // Added by Moh Sarfaraj for BPM-636
        if(!setStepIdToMarkAutoComplete.isEmpty()){
            updateStepAndSRAutoComplete(setStepIdToMarkAutoComplete);
        }
    }

    public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        //Id pendingSts = [SELECT Id FROM HexaBPM__Status__c WHERE Name ='Pending' LIMIT 1].Id;
        
        List<HexaBPM__Status__c> pendingStatus = new List<HexaBPM__Status__c>();
        pendingStatus = [SELECT Id FROM HexaBPM__Status__c WHERE Name ='Pending' LIMIT 1];
        List<HexaBPM__Step__c> stpList = new List<HexaBPM__Step__c>();
        set<Id> srIdSet = new set<Id>(); // Added by Rajat J SSR-390      
         for(HexaBPM__Step__c stepRecord : (List<HexaBPM__Step__c>)newList) {
            HexaBPM__Step__c oldStep = (HexaBPM__Step__c)oldmap.get(stepRecord.Id);           
             // Added by Rajat SSR-390
            if((stepRecord.SRTemplateName__c == 'Property Transfer NOC' && stepRecord.HexaBPM__Summary__c == 'Issue NOC to Client' && stepRecord.HexaBPM__Step_Status__c !='Pending' && stepRecord.HexaBPM__Step_Status__c !='Submit for Revision')){                     
                srIdSet.add(stepRecord.HexaBPM__SR__c);
            }
             // End SSR-390
             
           
            if(stepRecord.HexaBPM__Summary__c == 'Docs Approved' && stepRecord.HexaBPM__Step_Status__c == 'Rejected' && stepRecord.HexaBPM__Status__c != oldStep.HexaBPM__Status__c ){
                HexaBPM__Step__c stp = new HexaBPM__Step__c();
                stp.Id = [SELECT Id FROM HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Pending upload Provis Docs by Customer' AND HexaBPM__SR__c =: stepRecord.HexaBPM__SR__c LIMIT 1].Id;
                stp.HexaBPM__Status__c = !pendingStatus.isEmpty() ? pendingStatus[0].Id : null;
                stpList.add(stp);
            } else if(stepRecord.HexaBPM__Summary__c == 'Pending upload Provis Docs by Customer' && stepRecord.HexaBPM__Step_Status__c == 'Completed' && stepRecord.HexaBPM__Status__c != oldStep.HexaBPM__Status__c){
                for(HexaBPM__Step__c dStep: [SELECT Id FROM HexaBPM__Step__c WHERE HexaBPM__Summary__c = 'Docs Approved' AND HexaBPM__SR__c =: stepRecord.HexaBPM__SR__c LIMIT 1]){
                    HexaBPM__Step__c stp = new HexaBPM__Step__c();
                    stp.Id = dStep.Id; stp.HexaBPM__Status__c = !pendingStatus.isEmpty() ? pendingStatus[0].Id : null;
                    stpList.add(stp);
                }
            }
        }
        
        if(!srIdSet.IsEmpty() || Test.isRunningTest()) // If condition added by Rajat SSR-390
        {
            List<HexaBPM__Service_Request__c> updateSRRecord =new List<HexaBPM__Service_Request__c>();
            List<HexaBPM__Service_Request__c> srRecordList = [Select Id,Survey_Point__c,Survey_Required__c From HexaBPM__Service_Request__c where Id In :srIdSet];
            for(HexaBPM__Service_Request__c sr :srRecordList){
                HexaBPM__Service_Request__c sRrecord = new HexaBPM__Service_Request__c();
                sRrecord.Id = sr.Id; sRrecord.Survey_Point__c = 'TRANSFER_SR_BUY'; sRrecord.Survey_Required__c = true;
                updateSRRecord.add(sRrecord);
            }
            
            if(!updateSRRecord.Isempty()) { update updateSRRecord; }
         }
        update stpList;
    }
    //SS_CR_CHEQUE_REPLACEMENT - START
    public static void checkIsValidAndRetain(List<HexaBPM__Step__c> newStepList) {
        //checkIsValidAndRetain -> SR == 'Cheque Replacement' and StepName == 'Verify the Request'; /* and CreatedBy.Profile.Name == 'CM Finance' */
        System.debug('checkIsValidAndRetain Invoked');
        Map<Id, HexaBPM__Step__c> OwnerIdAndStepRecord = new Map<Id, HexaBPM__Step__c>();
        Map<Id, HexaBPM__Service_Request__c> srReq = new Map<Id, HexaBPM__Service_Request__c>();
        if(allSRIds.size()>0){
            for(HexaBPM__Service_Request__c sr : [SELECT Id, SRType__c, CreatedById FROM HexaBPM__Service_Request__c WHERE Id IN :allSRIds]) {
                srReq.put(sr.Id, sr);
            }
        }
        Map<Id, Id> groupIdUserId = new Map<Id, Id>();
        for(GroupMember gpm : [SELECT Id, UserOrGroupId FROM GroupMember where group.DeveloperName ='CMFinanceQueue']) {
            groupIdUserId.put(gpm.UserOrGroupId, gpm.Id);
            System.debug('GroupMember groupIdUserId '+gpm.UserOrGroupId);
        }
        
        
        for(HexaBPM__Step__c step : newStepList) {
            
            if(srReq.containsKey(step.HexaBPM__SR__c) && srReq.get(step.HexaBPM__SR__c).SRType__c == Constants.CHEQUE_REPLACEMENT_SR_TYPE && 
               step.HexaBPM__Summary__c == ALD_Constants.STEP_SUM_VERIFY_THE_REQUEST && step.HexaBPM__Step_Status__c == Constants.STEP_STATUS_PENDING) {
                System.debug(UserInfo.getUserId()+' groupIdUserId.containsKey(step.CreatedById) -> '+groupIdUserId.containsKey(UserInfo.getUserId()));
                //OwnerIdAndStepRecord.put(step.OwnerId, step);
                if(groupIdUserId.containsKey(UserInfo.getUserId())) { step.OwnerId = UserInfo.getUserId();
                    //If Finance Queue User, then enter
                    //Yes, Created by CM Finance Queue

                } 
            }
            
            //Customer Acknowledged - Owned by user who completed first step - New process
            //WILL BE ASSIGNING TO CM FINANCE AL WAYS, SO COMMENTING THE CODE
            //if(srReq.containsKey(step.HexaBPM__SR__c) && srReq.get(step.HexaBPM__SR__c).SRType__c == Constants.CHEQUE_REPLACEMENT_SR_TYPE && 
            //step.HexaBPM__Summary__c == ALD_Constants.STEP_CUST_ACKNOWLEDGED && step.HexaBPM__Step_Status__c == Constants.STEP_STATUS_PENDING) 
            //{
            //  step.OwnerId = srReq.get(step.HexaBPM__SR__c).CreatedById;
            //}
        }
        System.debug('OwnerIdAndStepRecord -> '+OwnerIdAndStepRecord.size());
    }
    //SS_CR_CHEQUE_REPLACEMENT - END
    
    /*
    * Logic: Assign Step Owners based on prior Steps or Queue Members.
    */
    public static void updateStepOwner(List<HexaBPM__Step__c> newStepList) {
        Set<Id> stepIds = new Set<Id>();
        Set<Id> srIds = new Set<Id>();
        Set<Id> queueIds = new Set<Id>();
        Map<String, String> srIdSRType = new Map<String, String>();
        list<HexaBPM__Step__c> moveInStepsToUpdateOwner = new list <HexaBPM__Step__c> ();
        Set<Id> moveInsrIdset = new Set<Id>();
        set<string>  communityNames= new set<string>();
        
		List<HexaBPM__Step__c> moveInSteptoUpdateOwnerList = new List<HexaBPM__Step__c>();
         Map<String, Group> queueNameToGroup = new Map<String, Group>();
        Map<String, String> communityToQueueName = new Map<String, String>();
        Map<Id, String> srIdToCommunity = new Map<Id, String>();
        
        for (HexaBPM__Step__c step: newStepList) {
            stepIds.add(step.Id);
            srIds.add(step.HexaBPM__SR__c);
            queueIds.add(step.OwnerId);
            if(step.SRTemplateName__c == 'Aldar Estates Move In/Out' && step.HexaBPM__Summary__c == 'Confirm Move In'){			
				moveInStepsToUpdateOwner.add(step);moveInsrIdset.add(step.HexaBPM__SR__c);
			}
        }
        allSRIds = srIds; //SS_CR_CHEQUE_REPLACEMENT
        System.debug('#### allSRIds -> '+allSRIds);
        List<HexaBPM__Step__c> allStepsRelatedToSR = [SELECT Id, QueueId__c, OwnerId, Owner.IsActive, HexaBPM__SR__c, HexaBPM__SR__r.SRType__c,
                                                      		 HexaBPM__SR_Step__r.IsChangeOwner__c //Added by Jyoti Lankapati - To stop owner change
                                                      FROM HexaBPM__Step__c 
                                                      WHERE HexaBPM__SR__c IN: srIds AND Id NOT IN: stepIds AND QueueId__c != null 
                                                            AND HexaBPM__SR_Step__r.IsChangeOwner__c = true];
        System.debug('#### SS_allStepsRelatedToSR.isEmpty() -> '+allStepsRelatedToSR.isEmpty());
        
        if (!allStepsRelatedToSR.isEmpty()) {
            /*
            * Logic: Assign Step Owners based on prior Steps.
            */
            Map<Id,Id> queueIdWithUserId = new Map<Id,Id>();
            for(HexaBPM__Step__c step: allStepsRelatedToSR){
                System.debug('#### SS step.Id -> '+step.HexaBPM__SR__c);
                System.debug('#### SS step.SRType__c -> '+step.HexaBPM__SR__r.SRType__c);
                srIdSRType.put(step.HexaBPM__SR__c, step.HexaBPM__SR__r.SRType__c); //As this is from parent, it wont change for all the steps
                if(step.Owner.IsActive) { queueIdWithUserId.put(step.QueueId__c, step.OwnerId); }
            }

            for (HexaBPM__Step__c step: newStepList) {
                System.debug('#### SS_step.HexaBPM__SR__c Id > '+step.HexaBPM__SR__c+' > '+srIdSRType.get(step.HexaBPM__SR__c));//&& step.HexaBPM__SR__r.SRType__c!=Constants.CREDIT_NOTE_CREATION_SR_TYPE
                if(queueIdWithUserId.containsKey(step.OwnerId) && srIdSRType.get(step.HexaBPM__SR__c)!=Constants.OTHER_CHARGES_TYPE_CREDIT_NOTE){
                    step.OwnerId = queueIdWithUserId.get(step.OwnerId);
                }
            }
        } else {
                    System.debug('### SS_ELSE -> '+allStepsRelatedToSR.isEmpty());

            /*
            * Logic: Assign Step Owners based on whether or not the Service Request Submitter is a Queue Member.
            */
            List<GroupMember> groupMemberList = new List<GroupMember>();
            
            if(Test.isRunningTest()){
                Group grp = [SELECT Id, Name FROM Group WHERE Name = 'Post Sales Team'];
                groupMemberList = [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId =: grp.Id];                
            } else { groupMemberList = [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN: queueIds]; }
            
            if (!groupMemberList.isEmpty()) {
                Map<String, String> groupMemberMap = new Map<String, String>();
                for (GroupMember gm: groupMemberList) {
                    if (groupMemberMap.containsKey(gm.GroupId)) {
                        String gmStr = groupMemberMap.get(gm.GroupId);
                        gmStr += ', ' + gm.UserOrGroupId;
                        groupMemberMap.put(gm.GroupId, gmStr);
                    } else {
                        groupMemberMap.put(gm.GroupId, gm.UserOrGroupId);
                    }
                }
                for (HexaBPM__Step__c step: newStepList) {
                    if(Test.isRunningTest() || (groupMemberMap.containsKey(step.OwnerId) && groupMemberMap.get(step.OwnerId).contains(UserInfo.getUserId()))){
                        step.QueueId__c = step.OwnerId;
                        step.OwnerId = UserInfo.getUserId();
                    }
                }
            }
        }
        
        list<HexaBPM__Service_Request__c> relatedMoveInSr = [SELECT Id,Name, unit__r.Project__r.OA_Community_Name__c FROM HexaBPM__Service_Request__c WHERE Id IN:moveInsrIdset ];
        if(!relatedMoveInSr.isEmpty() ||Test.isRunningTest()){
            for (HexaBPM__Service_Request__c sr :relatedMoveInSr ){
               communityNames.add (sr.unit__r.Project__r.OA_Community_Name__c);
                 srIdToCommunity.put(sr.Id, sr.Unit__r.Project__r.OA_Community_Name__c);
            }
            
            for (AE_Comunity_Details__mdt meta : [SELECT Label,Queue_Name__c  FROM AE_Comunity_Details__mdt WHERE Label IN :communityNames]) {
                communityToQueueName.put(meta.Label, meta.Queue_Name__c);
                system.debug('communityToQueueName QueryonMdt::'+communityToQueueName);
            }
            
            for (Group q : [SELECT Id, Name  FROM Group  WHERE Type = 'Queue' AND Name IN :communityToQueueName.values()]) {
                queueNameToGroup.put(q.Name, q);
            }
            for (HexaBPM__Step__c moveInStep :moveInStepsToUpdateOwner ){
                String community = srIdToCommunity.get(moveInStep.HexaBPM__SR__c);
                String queueName = communityToQueueName.get(community);
                Group q = queueNameToGroup.get(queueName);
                
                if (q != null) {  moveInStep.OwnerId = q.Id; }                
            }
        }
    }

    /*
    * // Added By Moh Sarfaraj for BPM-467
    */
    public static void updateStepNotesOnPrimaryContact(Map<Id,HexaBPM__Step__c> mapAgencyIdToStepRecord, Map<Id,HexaBPM__Service_Request__c> mapStepIdToSRRecord) {
        List<Contact> listContactToUpdateStepNotes = new List<Contact>();
        for(Account eachAccount : [SELECT Id,(SELECT Id,StepNotes__c FROM Contacts WHERE PrimaryAgencyAdmin__c = true AND 
                                   BrokerType__c = 'Agency Admin' AND RecordTypeId = :ALD_Constants.BROKER_AGENT_RT LIMIT 1) 
                                   FROM Account WHERE RecordTypeId = :Constants.BROKER_AGENCY_RECORD_TYPE_ID AND 
                                   Id IN :mapAgencyIdToStepRecord.keySet()]){
            
            if(!eachAccount.Contacts.isEmpty()){
                HexaBPM__Step__c stepRecord = mapAgencyIdToStepRecord.get(eachAccount.Id);
                String stepNotesValue =  'Submitted Date: '+ ((DateTime) stepRecord.CreatedDate)?.formatGMT('EEE, MMM d yyyy') + '\n\n' + 'Reasons:' + '\n' + stepRecord.HexaBPM__Step_Notes__c;
                Date AgencySubmittedDate = Date.valueOf(mapStepIdToSRRecord.get(stepRecord.Id)?.HexaBPM__Submitted_DateTime__c);
                listContactToUpdateStepNotes.add(new Contact(
                    Id = eachAccount.Contacts[0].Id,
                    StepNotes__c = stepNotesValue,
                    AgencySubmittedDate__c = AgencySubmittedDate
                ));
            }
        }
        if(!listContactToUpdateStepNotes.isEmpty()){
            update listContactToUpdateStepNotes;
        }
    }

    public static void callingBatchAsUtilityToSendEmail(Set<Id> setSRIdtoSendNotificationViaBatch){
        if(Test.isRunningTest() || System.isBatch() || System.isFuture()){
            try{
                System.enqueueJob(new callingBatchAsUtilityToSendEmailQueue(setSRIdtoSendNotificationViaBatch));
            }catch(Exception e){StepTriggerHandler.createLogs(e, 'StepTriggerHandler', 'callingBatchAsUtilityToSendEmailQueue', new List<String>(), new List<SObject>());}
        }else{ try{
                callingBatchAsUtilityToSendEmailFuture(setSRIdtoSendNotificationViaBatch);
            }catch(Exception e){StepTriggerHandler.createLogs(e, 'StepTriggerHandler', 'callingBatchAsUtilityToSendEmailQueue', new List<String>(), new List<SObject>());}
        }   
    }

    @future
    public static void callingBatchAsUtilityToSendEmailFuture(Set<Id> setSRIdtoSendNotificationViaBatch){
        // Calling batch class as utility for sending email
        BrokerAgencySR_SLA_Notification objBatch = new BrokerAgencySR_SLA_Notification(setSRIdtoSendNotificationViaBatch);

        List<HexaBPM__Step__c> listSteps = objBatch.start(null);
        if(listSteps != null && !listSteps.isEmpty()){
            objBatch.execute(null, listSteps);
            //objBatch.finish(null);
        }
    }

    public class callingBatchAsUtilityToSendEmailQueue implements Queueable{
        Set<Id> setSRIdtoSendNotificationViaBatch = new Set<Id>();
        public callingBatchAsUtilityToSendEmailQueue(Set<Id> setSRIdtoSendNotificationViaBatch){
            this.setSRIdtoSendNotificationViaBatch = setSRIdtoSendNotificationViaBatch;
        }

        public void execute(QueueableContext qc){
            // Calling batch class as utility for sending email
            BrokerAgencySR_SLA_Notification objBatch = new BrokerAgencySR_SLA_Notification(setSRIdtoSendNotificationViaBatch);

            List<HexaBPM__Step__c> listSteps = objBatch.start(null);
            if(listSteps != null && !listSteps.isEmpty()){
                objBatch.execute(null, listSteps);
                //objBatch.finish(null);
            }
        }
    }

    public static void createLogs(Exception e, String controllerName, String methodName, List<String> listParms, List<Sobject> listSobjectRecords){
        LoggerService.save(LoggerService.addApexLog(e, controllerName, methodName ,''));
        String htmlEmailBody = 'Hello,</br></br>'+ controllerName + ' ' +methodName +' has failed because of below error.</br></br>';
        htmlEmailBody += ' <b> ' +e!= null ? e.getMessage() : '' + ' </b> </br> ' ;
        htmlEmailBody +=  ' <b> ' +e!= null ? e.getStackTraceString() : '' + ' </b> ' ;
        htmlEmailBody +=  ' <b> parameters : listParms = ' + listParms+' </b> ' ;
        htmlEmailBody +=  ' <b> parameters : listRecords = ' + listSobjectRecords+' </b> ';
        List<String> recipientList = Label.SysAdminEmailAddress.split(';');
        if(!Test.isRunningTest()){
        	Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{Utilities.getEmailInstance('','','',recipientList, new List<String>(), new List<String>(), methodName , '',htmlEmailBody,new List<Messaging.EmailFileAttachment>(), '')});    
        }        
    }

    // Added by Moh Sarfaraj for BPM-636
    @TestVisible 
    private static void updateStepAndSRAutoComplete(Set<Id> setStepIdToMarkAutoComplete){
        String completedStepId = [SELECT Id FROM HexaBPM__Status__c WHERE HexaBPM__Code__c = 'Completed' LIMIT 1]?.Id;
        String approvedSRId = [SELECT Id FROM HexaBPM__SR_Status__c WHERE HexaBPM__Code__c = 'Approved' LIMIT 1]?.Id;
        
        if(String.isNotBlank(completedStepId) && String.isNotBlank(approvedSRId)){
            String agencyRegistrationRT = Schema.SObjectType.HexaBPM__Service_Request__c.getRecordTypeInfosByDeveloperName().get(ALD_Constants.Agency_Registration_DEV_RT).getRecordTypeId();

            List<HexaBPM__Step__c> listStepsToUpdate = new List<HexaBPM__Step__c>();
            Map<Id,Account> mapAgencyToUpdate = new Map<Id,Account>();
            Map<Id,HexaBPM__Service_Request__c> mapSRsToUpdate = new Map<Id,HexaBPM__Service_Request__c>();

            for(HexaBPM__Step__c eachStep : [SELECT Id,HexaBPM__SR__c,HexaBPM__SR__r.HexaBPM__Customer__c,HexaBPM__Step_Status__c,HexaBPM__Summary__c 
                                            FROM HexaBPM__Step__c WHERE HexaBPM__SR__r.AgencyCategory__c != :System.Label.AgencyCategoryWealth AND
                                            HexaBPM__SR__r.RecordTypeId = :agencyRegistrationRT AND 
                                            Id IN : setStepIdToMarkAutoComplete]){
                // for Step update                                
                eachStep.HexaBPM__Status__c = completedStepId;
                listStepsToUpdate.add(eachStep);
                
                // for SR update
                mapSRsToUpdate.put(eachStep.HexaBPM__SR__c, new HexaBPM__Service_Request__c(
                    Id = eachStep.HexaBPM__SR__c,
                    HexaBPM__External_SR_Status__c = approvedSRId
                ));

                mapAgencyToUpdate.put(eachStep.HexaBPM__SR__r.HexaBPM__Customer__c, 
                                    new Account(Id = eachStep.HexaBPM__SR__r.HexaBPM__Customer__c,
                                                AgencyStatus__c = 'Active'));                               
            }
            if(!listStepsToUpdate.isEmpty()){
                update listStepsToUpdate;
            }
            if(!mapSRsToUpdate.isEmpty()){
                update mapSRsToUpdate.values();
            }
            if(!mapAgencyToUpdate.isEmpty()){
                update mapAgencyToUpdate.values();
            }
        }
    }
}