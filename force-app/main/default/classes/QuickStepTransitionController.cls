/******************************************************************************************
*  Author         :   Durga Prasad
*  Company        :   PwC
*  Date           :   26-Nov-2019
*  Description    :   Apex Controller for Step Transition Window in Lightning
*  Version        :   1.0
Version History:
********************************************************************************************
********************************************************************************************/
public without sharing class QuickStepTransitionController{
    
    public HexaBPM__Step__c step{get;set;}
    public string SRID{get;set;}
    public string StepID{get;set;}
    public boolean hasAccess{get;set;}
    User objCurrentUser;
    public map<string,string> MapDelegatedUsers;
    public string userType{get;set;}
    public list<TransitionWrapper> lstTrnsWrap{get;set;}
    public Integer iListSize{get;set;}
    public map<id,HexaBPM__Step_Transition__c> mapStepTransition{get;set;}
    public list<String> openStepNameList;
    
    public QuickStepTransitionController(string recordId,string stepId){
        lstTrnsWrap = new list<TransitionWrapper>();
        
        openStepNameList = new list<String>();
        iListSize = 0;
        if(recordId!=null)
            SRID = recordId;
        step = new HexaBPM__Step__c();
        if(stepId!=null){
            StepID = stepId;
            for(HexaBPM__Step__c stp:[select Id,Name,Step_Template_Code__c, 
            HexaBPM__SR_Step__r.HexaBPM__Step_Type__c, HexaBPM__Summary__c,RecordTypeId,HexaBPM__Step_Status__c,
            RecordType.DeveloperName,OwnerId,Owner.Name,RecordType.Name,HexaBPM__Parent_Step__c,HexaBPM__SR__c,HexaBPM__SR__r.HexaBPM__SR_Template__c,HexaBPM__Status__c,
            HexaBPM__SR_Step__c,HexaBPM__SR_Step__r.HexaBPM__Step_Instructions__c,HexaBPM__Rejection_Reason__c,
            HexaBPM__Status__r.Name from HexaBPM__Step__c where Id=:StepID and HexaBPM__SR__c!=null and HexaBPM__SR__r.HexaBPM__SR_Template__c!=null and IsDeleted=false]){
                step = stp;
            }
        }
        hasAccess = false;
        objCurrentUser = new User();
        for(User curUser:[select Id,ContactId,ProfileId,Profile.UserLicenseId,Profile.UserLicense.Name,Profile.UserLicense.LicenseDefinitionKey,Profile.Name from User where Id=:userInfo.getUserId() and IsActive=true]){
            objCurrentUser = curUser;
            if(curUser.ContactId==null){
                userType = 'salesforce';
            }else{
                userType = 'Community';
            }
        }
    }
    /**
     * Method Name : Check_Permissions
     * Desription : Checks if the current user has access to make the required transition selection or not.
     **/
    public void Check_Permissions(){
        MapDelegatedUsers = new map<string,string>();
        MapDelegatedUsers = SetupObjectDataHelper.GetDelegatedUsers(objCurrentUser.Id);
        if(!system.test.isRunningTest() && (step.OwnerId==userinfo.getUserId() || (MapDelegatedUsers!=null && MapDelegatedUsers.get(step.OwnerId)!=null) || (objCurrentUser!=null && string.valueof(objCurrentUser.Profile.Name).indexof('System Administrator')>-1))){
            hasAccess = true;
        }else if(!system.test.isRunningTest() && userType!=null && userType=='Community'){
            hasAccess = true;
        }else{
            if(string.valueOf(step.OwnerId).substring(0,3)=='00G' || system.test.isRunningTest()){
                for(SetupObjectDataHelper.GroupDetails GD:SetupObjectDataHelper.getGroupData(step.OwnerId)){
                    if(GD.GroupOrUserId==userinfo.getUserId()){
                        hasAccess = true;
                        break;
                    }
                }
            }
        }
        Prepare_Transitions();
    }
    
    /**
     * Method Name : Prepare_Transitions
     * Description : Queries all transitions from the current step and sets the valid possible transitions and maps it to a map value
     **/
    public void Prepare_Transitions(){

        //CheckAllOpenSteps();
        
        set<id> setValidSteps = new set<id>();
        mapStepTransition = new map<id,HexaBPM__Step_Transition__c>();
        system.debug('Start Status===>'+step.HexaBPM__Status__r.Name);
        if(userType=='salesforce'){
            for(HexaBPM__Step_Transition__c trans:[select HexaBPM__From__c,HexaBPM__To__c,HexaBPM__Transition__c,
                                                    HexaBPM__Transition__r.HexaBPM__To__c,
                                                    HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Code__c,HexaBPM__SR_Step__c,
                                                    HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Reupload_Document__c,
                                                    HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Rejection__c,
                                                    HexaBPM__SR_Status_External__c,HexaBPM__SR_Status_External__r.HexaBPM__Type__c,
                                                    HexaBPM__SR_Status_Internal__c,HexaBPM__SR_Status_Internal__r.HexaBPM__Type__c 
                                                    from HexaBPM__Step_Transition__c where HexaBPM__Transition__c!=null 
                                                    and HexaBPM__From__c=:step.HexaBPM__Status__r.Name and HexaBPM__SR_Step__c=:step.HexaBPM__SR_Step__c 
                                                    and IsDeleted=false and HideManualTransition__c != true]){
                setValidSteps.add(trans.HexaBPM__Transition__r.HexaBPM__To__c);
                mapStepTransition.put(trans.HexaBPM__Transition__r.HexaBPM__To__c,trans);
            }
        }else{ 
            for(HexaBPM__Step_Transition__c trans:[select HexaBPM__From__c,HexaBPM__To__c,HexaBPM__Transition__c,HexaBPM__Transition__r.HexaBPM__To__c,HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Code__c,HexaBPM__SR_Step__c,HexaBPM__SR_Status_External__c,HexaBPM__SR_Status_External__r.HexaBPM__Type__c,HexaBPM__SR_Status_Internal__c,HexaBPM__SR_Status_Internal__r.HexaBPM__Type__c from HexaBPM__Step_Transition__c where HexaBPM__Transition__c!=null and HexaBPM__From__c=:step.HexaBPM__Status__r.Name and HexaBPM__SR_Step__c=:step.HexaBPM__SR_Step__c and HexaBPM__Display_on_Portal__c=true and IsDeleted=false]){
                setValidSteps.add(trans.HexaBPM__Transition__r.HexaBPM__To__c);
                mapStepTransition.put(trans.HexaBPM__Transition__r.HexaBPM__To__c,trans);
            }
        }
        if(setValidSteps!=null && setValidSteps.size()>0){
            TransitionWrapper objWrap;
            for(HexaBPM__Status__c objstat:[Select Id,Name,HexaBPM__Type__c,HexaBPM__Rejection__c,HexaBPM__SR_Closed_Status__c,HexaBPM__Code__c from HexaBPM__Status__c where ID IN:setValidSteps and IsDeleted=false]){
                objWrap = new TransitionWrapper();
                objWrap.objStatus = objstat;
                objWrap.objSRStepTrans = new HexaBPM__Step_Transition__c();
                if(mapStepTransition.get(objstat.id)!=null)
                    objWrap.objSRStepTrans = mapStepTransition.get(objstat.id);
                lstTrnsWrap.add(objWrap);
            }
            iListSize = lstTrnsWrap.size();
        }
        system.debug('mapStepTransition===>'+mapStepTransition);
    }

    /**
     * Method Name : CheckAllOpenSteps
     * Desciption  : Method to check if one step of each child step is already open (except Request for Screening), 
     *                then it will not be displayed on the step transition 
     **/
    /*
    public void CheckAllOpenSteps(){

        openStepNameList = new List<String>();

        Map<String,String> stepTemplateMap = new Map<String,String>{
            
            Constants.Str_TemplateCode_DraftRFILetter => 'Draft RFI Letter',
            Constants.Str_TemplateCode_ReviewRFILetter => 'Draft RFI Letter',
            Constants.Str_TemplateCode_UpdateRFIResponse => 'Draft RFI Letter',
            Constants.Str_TemplateCode_DraftAssessmentReport => 'Draft Assessment Report',
            Constants.Str_TemplateCode_ReviewAssessmentReport => 'Draft Assessment Report',
            Constants.Str_TemplateCode_DistributeAssessmentReport => 'Draft Assessment Report',
            Constants.Str_TemplateCode_ReviewCommentsACO => 'Request for Review (Internal)',
            Constants.Str_TemplateCode_AdditionalInformation => 'Request for Additional Information (External)'
            
        };

        List<HexaBPM__Step__c> existingStepList = [select id, Step_Template_Code__c, HexaBPM__SR__c, HexaBPM__Summary__c from HexaBPM__Step__c where 
            HexaBPM__SR__c =: step.HexaBPM__SR__c and HexaBPM__Status_Type__c != 'End' and Step_Template_Code__c in: stepTemplateMap.keySet() and Id !=: step.Id];
        
        for(HexaBPM__Step__c stepRecord : existingStepList){
            if(stepTemplateMap.containsKey(stepRecord.Step_Template_Code__c))
                openStepNameList.add(stepTemplateMap.get(stepRecord.Step_Template_Code__c));
        }
    }
    */
    
    /**
     * Method Name : SaveChanges
     * Desciption  : Method Invoked on click of the Proceed button. Passes the selected transition, rejected reason, step notes, SR id, Step object, map of possible step transitions and updates the step's status to the
     *               valid step value selected by the user
     **/
    @AuraEnabled
    public static LtngQuickStepTransitionWrapper SaveChanges(string selTransition, string RejReason, string StepNotes, string SRID, HexaBPM__Step__c step1, map<id, HexaBPM__Step_Transition__c> mapStepTransition, 
                    String authCaseOfficer, string newStepOwner, String contactPersonEmail, List<String> selectedFormValues ){
        pagereference pg;
        wrapperObj = new LtngQuickStepTransitionWrapper();
        wrapperObj.flsErrorMessage='Success';
        wrapperObj.flsErrorCheck = false;
        list<HexaBPM__Step__c> stepWrapper = new list<HexaBPM__Step__c>();
        integer flag=0;
        system.debug('selTransition===>'+selTransition);
        system.debug('selTransition Map===>'+mapStepTransition.get(selTransition));
        if(selTransition!=null && mapStepTransition.get(selTransition)!=null ){
            //REUPLOAD_DOCUMENT
            System.debug(mapStepTransition.get(selTransition).HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Code__c);
            if(mapStepTransition.get(selTransition).HexaBPM__Transition__r.HexaBPM__To__r.HexaBPM__Code__c=='REUPLOAD_DOCUMENT'){
                boolean hasReUploadDoc = false;
                for(HexaBPM__SR_Doc__c srdoc:[select Id from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c=:SRID and HexaBPM__Status__c='Re-upload' limit 1]){
                    hasReUploadDoc = true;
                }
                if(!hasReUploadDoc){
                    wrapperObj.flsErrorMessage = 'Atleast one document should be marked as re-upload';
                    wrapperObj.flsErrorCheck = true;
                    return wrapperObj;
                }
            }
            
            map<string,string> MapDocumentsTBU = new map<string,string>();
            if(step1.HexaBPM__SR_Step__c!=null){
                for(HexaBPM__SR_Doc__c doc:[Select Id,Name from HexaBPM__SR_Doc__c where HexaBPM__Service_Request__c=:step1.HexaBPM__SR__c and HexaBPM__SR_Template_Doc__r.HexaBPM__Validated_at__c=:step1.HexaBPM__SR_Step__c and HexaBPM__Status__c!='Uploaded' and HexaBPM__Doc_ID__c=null]){
                    string DocumentName = '';
                    if(MapDocumentsTBU.get(step1.Id)!=null)
                        DocumentName = MapDocumentsTBU.get(step1.Id);
                    if(DocumentName=='')
                        DocumentName = doc.Name;
                    else
                        DocumentName = DocumentName+','+doc.Name;
                    MapDocumentsTBU.put(step1.Id,DocumentName);
                }
            }
            system.debug('MapDocumentsTBU==>'+MapDocumentsTBU);
            //V1.4
            HexaBPM__Status__c objSelectedStatus;
            for(HexaBPM__Status__c stepstatus:[Select Id,HexaBPM__Type__c,HexaBPM__Rejection__c,HexaBPM__Reupload_Document__c from HexaBPM__Status__c where Id=:selTransition]){
                objSelectedStatus = stepstatus;
            }
            system.debug('objSelectedStatus==>'+objSelectedStatus);
            if(objSelectedStatus!=null && objSelectedStatus.HexaBPM__Type__c=='End' && objSelectedStatus.HexaBPM__Rejection__c==false  && objSelectedStatus.HexaBPM__Reupload_Document__c==false && MapDocumentsTBU.get(step1.Id)!=null){
                wrapperObj.flsErrorMessage = 'Please upload "'+MapDocumentsTBU.get(step1.Id)+'" to proceed.';
                wrapperObj.flsErrorCheck = true;
                return wrapperObj;
            }
                
            Savepoint Stat_svpoint = Database.setSavepoint();
            try{
                pg = new PageReference('/'+SRID);
                pg.setRedirect(true);
                
                boolean isRejected = false;
                HexaBPM__Service_Request__c objSR = [select id,TitleDeedRegistrationFee__c from HexaBPM__Service_Request__c where id =:SRID limit 1]; //new HexaBPM__Service_Request__c(Id=SRID);
                /*
                if(StepNotes!=null && StepNotes!='')
                    objSR.HexaBPM__Step_Notes__c = StepNotes;
                    */
                if(RejReason!=null && RejReason!=''){
                    //objSR.HexaBPM__Step_Notes__c = RejReason;
                    objSR.HexaBPM__Rejection_Reason__c = RejReason;
                }
                if(mapStepTransition.get(selTransition).HexaBPM__SR_Status_Internal__c!=null || mapStepTransition.get(selTransition).HexaBPM__SR_Status_External__c!=null){
                    if(mapStepTransition.get(selTransition).HexaBPM__SR_Status_Internal__c!=null){
                        objSR.HexaBPM__Internal_SR_Status__c = mapStepTransition.get(selTransition).HexaBPM__SR_Status_Internal__c;
                        if(mapStepTransition.get(selTransition).HexaBPM__SR_Status_Internal__r.HexaBPM__Type__c=='Rejected')
                            isRejected = true;
                    }
                    if(mapStepTransition.get(selTransition).HexaBPM__SR_Status_External__c!=null){
                        objSR.HexaBPM__External_SR_Status__c = mapStepTransition.get(selTransition).HexaBPM__SR_Status_External__c;
                        if(mapStepTransition.get(selTransition).HexaBPM__SR_Status_External__r.HexaBPM__Type__c=='Rejected')
                            isRejected = true;
                    }  
                }
                if(step1.Step_Template_Code__c == Constants.STEP_NAME_UPLOAD_TITLE_DEED){
                    objSR.TitleDeedRegistrationFee__c = objSR.TitleDeedRegistrationFee__c==null ? 0:null;
                }
                

                update objSR;


                //update the payment link email to send the payment order to the contact or person
                if(step1.Step_Template_Code__c == 'Send_Payment_Order'){

                    //V1.9
                    if(String.isBlank(contactPersonEmail)){
                        wrapperObj.flsErrorMessage = 'Please enter the email to send the payment link';
                        wrapperObj.flsErrorCheck = true;
                        return wrapperObj;
                    }else{
                        objSR.HexaBPM__Email__c = contactPersonEmail;
                        update objSR;
                    }
                } 
                
                HexaBPM__Step__c objStepToUpdate = new HexaBPM__Step__c(Id=step1.Id);
                

                objStepToUpdate.HexaBPM__Status__c = mapStepTransition.get(selTransition).HexaBPM__Transition__r.HexaBPM__To__c;
                objStepToUpdate.HexaBPM__Step_Notes__c = StepNotes;
                //objStepToUpdate.Internal_Comments__c = StepNotes;
                objStepToUpdate.HexaBPM__Rejection_Reason__c = RejReason;
                /*
                if( authCaseOfficer != null && String.isNotBlank( authCaseOfficer ) ){
                    objStepToUpdate.OwnerId = authCaseOfficer;
                }
                */
                objStepToUpdate.OwnerId = UserInfo.getUserId(); //Autoaccept the step on click of proceed button click
                stepWrapper.add(objStepToUpdate);
                System.debug('--objStepToUpdate--'+objStepToUpdate);
                               
                update stepWrapper;

                system.debug('updated');
                
            }catch(DMLException e){
                string DMLError = QueryUtilityClass.getMessageFromDMLException(e);
                selTransition = null;
               
                Integer occurence;
                if (DMLError.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                    occurence = DMLError.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 34;
                    DMLError = DMLError.mid(occurence, DMLError.length());
                    occurence = DMLError.lastIndexOf(':');
                    DMLError = DMLError.mid(0, occurence);
                }
                
                wrapperObj.debugger = DMLError;
                Database.rollback(Stat_svpoint);
                wrapperObj.flsErrorMessage = DMLError;
                wrapperObj.flsErrorCheck = true; 
            }
            catch(Exception e){
              
                string DMLError = e.getMessage()+'';
                System.debug('DMLError>>'+DMLError);
                if(DMLError==null){
                    DMLError = e.getMessage()+'';
                }
                selTransition = null;
                Database.rollback(Stat_svpoint);
                wrapperObj.flsErrorMessage = DMLError;
                wrapperObj.flsErrorCheck = true; 
            }
            
        }else{
            wrapperObj.flsErrorCheck = true;
            wrapperObj.flsErrorMessage='Please select a status to Proceed';
        }
        return wrapperObj;
    }
    
    @AuraEnabled
    public static boolean acceptAction(string stepId, boolean isStepOwnedByQueue){
        system.debug( 'isStepOwnedByQueue >>> '+isStepOwnedByQueue );
        try{
            if(isStepOwnedByQueue == true){
                system.debug( 'Insidre If ' );
                //Accept Action
                HexaBPM__Step__c step = new HexaBPM__Step__c(Id = stepId);
                step.OwnerId = Userinfo.getUserId();
                update step;
                isStepOwnedByQueue = false;
            }else{
                system.debug( 'Insidre else ' );
                //Release Action
                list<HexaBPM__Step__c> stepSelected = [SELECT Id, HexaBPM__SR_Step__r.OwnerId FROM HexaBPM__Step__c WHERE Id = :stepId];
                HexaBPM__Step__c step = new HexaBPM__Step__c(Id =stepId);
                if(stepSelected != null && stepSelected.size() > 0){
                    step.OwnerId = stepSelected[0].HexaBPM__SR_Step__r.OwnerId;
                    update step;
                }
                isStepOwnedByQueue = true;
            } 
        }catch(Exception ex){
        }
        return isStepOwnedByQueue;
    }
    @AuraEnabled    
    public static LtngQuickStepTransitionWrapper wrapperObj {get; set;}
   /**
     * Method Name : getLstTransWrapper
     * Description : Returns a Wrapper Class Object with the values to initialize the lightning component
     *               Also executes check permissions method and sets the hasAccess variable.
     **/
    @AuraEnabled
    public static LtngQuickStepTransitionWrapper getLstTransWrapper(string recordId,string stepId){
        
        QuickStepTransitionController newObj = new QuickStepTransitionController(recordId, stepId);
        
        newObj.Check_Permissions();
        system.debug(newObj);
        string ownerId;
        wrapperObj = new LtngQuickStepTransitionWrapper();
        wrapperObj.objFormSection = getFormFields(recordId,stepId);
        HexaBPM__Service_Request__c temp =[select Id, Name, HexaBPM__SR_template__c, InvoiceReversal__c, HexaBPM__SR_template__r.Name from HexaBPM__Service_Request__c where id=:newObj.SRID]; //SS_210623_ADDED_TO_SHOW_CUST_MESSAGE_ON_SCREEN
        wrapperObj.SRRequestType = temp.HexaBPM__SR_Template__r.Name;
        wrapperObj.SRNumber = temp.Name;
        wrapperObj.IsInvoiceReversal = temp.InvoiceReversal__c;//SS_210623_ADDED_TO_SHOW_CUST_MESSAGE_ON_SCREEN
        wrapperObj.ltngLstTrnsWrap = newObj.lstTrnsWrap;
        wrapperObj.hasAccess = newObj.hasAccess;
        wrapperObj.userType = newObj.userType;
        wrapperObj.listSize = newObj.iListSize;
        wrapperObj.step_ltng = newObj.step; 
        if(newObj.step != null && newObj.step.Owner != null){
            ownerId = newObj.step.Owner.Id;
            if(ownerId.subString(0,3) == '00G')
                wrapperObj.isStepOwnedByQueue = true;
        }
        wrapperObj.ltngMapStepTransition = newObj.mapStepTransition;
        wrapperObj.SRId = newObj.SRID;
        
       

        system.debug(wrapperObj);
        return wrapperObj;
    }
    /**
    * Method Name: Get the queue members in the group by Developer Name
    **/
    public static list<string> getQueueMembersByDeveloperName(list<string> queueNames){
        list<string> usrids = new list<string>();
        list<Group> grplist = [select Id, Name, Type from Group where Type = 'Queue' and DeveloperName in: queueNames];
        if(grplist <> null && !grplist.isEmpty()){
            set<string> grpnames = new set<string>();
            for(Group g: grplist){
                grpnames.add(g.Id);
            }
            list<GroupMember> gmlist = [select UserOrGroupId From GroupMember where groupId in:  grpnames];
            if(gmlist <> null && !gmlist.isEmpty()){
                for(GroupMember gm: gmlist){
                    usrids.add(gm.UserOrGroupId);
                }
            }
        }
        return usrids;
    }
    /**
    * Method Name: Get the queue members in the group
    **/
    public static list<string> getQueueMembers(list<string> queueNames){
        list<string> usrids = new list<string>();
        list<Group> grplist = [select Id, Name, Type from Group where Type = 'Queue' and Name in: queueNames];
        if(grplist <> null && !grplist.isEmpty()){
            set<string> grpnames = new set<string>();
            for(Group g: grplist){
                grpnames.add(g.Id);
            }
            list<GroupMember> gmlist = [select UserOrGroupId From GroupMember where groupId in:  grpnames];
            if(gmlist <> null && !gmlist.isEmpty()){
                for(GroupMember gm: gmlist){
                    usrids.add(gm.UserOrGroupId);
                }
            }
        }
        return usrids;
    }
    /**
     * Method Name : getFileExtension
     * Description : Method to fetch the file extension from fileName
     **/
    public static String getFileExtension(String filename) {
        String ext = '';
        if ( filename != null ) {
            List<String> splits = filename.split('\\.');
            ext = splits.get(splits.size()-1);
        }
        return ext.toLowerCase();
    }
    /**
     * Method Name : CancelAction
     * Description : Method invoked on click of the cancel button. Redirects the page back to the SR Detail page
     **/
    @AuraEnabled
    public static void CancelAction(string SRID){
        System.debug('CancelAction');
        Pagereference pg = new Pagereference('/'+SRID);
        system.debug(pg);
        pg.setRedirect(true);
        if(!system.test.isRunningTest())
            aura.redirect(pg);
    }
    /**
     * Method Name : ViewStep
     * Description : Method invoked on click of the View Step button. Redirects the page to the Step Detail page
     **/
    @AuraEnabled
    public static void ViewStep(string StepID){
        system.debug('ViewStep');
        Pagereference pg = new Pagereference('/'+StepID);
        system.debug(pg);
        pg.setRedirect(true);
        if(!system.test.isRunningTest())
            aura.redirect(pg);
    }

    /*********************************************************************************************************************
    * @Description        : Function to update the owner of the step                                                     *
    * @Author             : Rohit Sharma                                                                                 *
    * @Last Modified By   : Rohit Sharma                                                                                 *
    * @Last Modified On   : 11/05/2020                                                                                   *
    * @Params             : stepId, assignedTo                                                                           *  
    * @Return             : LtngQuickStepTransitionWrapper                                                               * 
    **********************************************************************************************************************/
    @AuraEnabled
    public static LtngQuickStepTransitionWrapper updateOwner( String stepId, String assignedTo, string comments ){
        try{
            
            wrapperObj = new LtngQuickStepTransitionWrapper();
            wrapperObj.flsErrorMessage='Success';
            wrapperObj.flsErrorCheck = false;

            HexaBPM__Step__c objStepToUpdate = new HexaBPM__Step__c( Id = stepId );
            if( assignedTo != null && String.isNotBlank( comments ) ){
                objStepToUpdate.OwnerId = assignedTo;
                if(String.isNotBlank( comments)){
                    objStepToUpdate.HexaBPM__Step_Notes__c = comments;
                }
                
            }
            
            update objStepToUpdate;
            return wrapperObj;
        }catch(DMLException e){
            string DMLError = e.getdmlMessage(0)+'';
            if(DMLError==null){
                DMLError = e.getMessage()+'';
            }
            wrapperObj.flsErrorMessage = DMLError;
            wrapperObj.flsErrorCheck = true; 
            
            return wrapperObj;
        }
    }

    /*********************************************************************************************************************
    * @Description        : Function to update the Auth Case Officer of the step                                         *
    * @Author             : Rohit Sharma                                                                                 *
    * @Last Modified By   : Rohit Sharma                                                                                 *
    * @Last Modified On   : 11/05/2020                                                                                   *
    * @Params             : stepId, authCaseOfficer                                                                      *  
    * @Return             : LtngQuickStepTransitionWrapper                                                               * 
    **********************************************************************************************************************/
    @AuraEnabled
    public static LtngQuickStepTransitionWrapper updateAuthCaseOfficer( String stepId, String authCaseOfficer ){
        try{
            wrapperObj = new LtngQuickStepTransitionWrapper();
            wrapperObj.flsErrorMessage='Success';
            wrapperObj.flsErrorCheck = false;


            HexaBPM__Step__c objStepToUpdate = new HexaBPM__Step__c( Id = stepId );
            update objStepToUpdate;
            return wrapperObj;
        }catch(DMLException e){
            string DMLError = e.getdmlMessage(0)+'';
            if(DMLError==null){
                DMLError = e.getMessage()+'';
            }
            wrapperObj.flsErrorMessage = DMLError;
            wrapperObj.flsErrorCheck = true; 
            return wrapperObj;
        }
    }
    
    /**
     * Method Name : getFormFields
     * Description : Returns a Wrapper list with the field details to be shown on transition popup
     **/
    public static LtngQuickStepTransitionWrapper.FormFieldSection getFormFields(string SRId,string stepId){
        LtngQuickStepTransitionWrapper.FormFieldSection objFormSection = new LtngQuickStepTransitionWrapper.FormFieldSection();
        list<LtngQuickStepTransitionWrapper.FormObjectsWrapper> lstObjects = new list<LtngQuickStepTransitionWrapper.FormObjectsWrapper>();
        
        string SRStepId;
        if(stepId!=null && stepId!=''){
            for(HexaBPM__Step__c stp:[Select Id,HexaBPM__SR_Step__c from HexaBPM__Step__c where Id=:stepId]){
                SRStepId = stp.HexaBPM__SR_Step__c;
            }
        }
        if(SRStepId!=null){
            
            string SRQuery = 'Select Id';
            string StepQuery = 'Select Id';
            boolean hasSRFields = true;
            boolean hasStepFields = true;
            
            HexaBPM__Step__c objStep = new HexaBPM__Step__c();
            HexaBPM__Service_Request__c objSR = new HexaBPM__Service_Request__c();
            if(hasSRFields){
                SRQuery = SRQuery+' from HexaBPM__Service_Request__c where Id=:SRId';
                objSR = database.query(SRQuery);
            }
            if(hasStepFields){
                StepQuery = StepQuery+' from HexaBPM__Step__c where Id=:stepId';
                objStep = database.query(StepQuery);
            }
               
            
            /*
            for(Transition_Form_Field__c fld:[Select Object_Name__c,Field_API_Name__c,Order__c,Read_only__c,Required__c,SR_Step__c from Transition_Form_Field__c where SR_Step__c=:SRStepId order by Order__c]){
                LtngQuickStepTransitionWrapper.FormFieldsWrapper objwrap = new LtngQuickStepTransitionWrapper.FormFieldsWrapper();
                objwrap.ObjectApi = fld.Object_Name__c;
                objwrap.FieldApi = fld.Field_API_Name__c;
                objwrap.FieldValue = null;
                objwrap.IsReadOnly = fld.Read_only__c;
                objwrap.IsRequired = fld.Required__c;
                lstFields.add(objwrap);
            }
            */
            objFormSection.SectionObjects = lstObjects;
        }
        return objFormSection;
    }

    @AuraEnabled
    public static RespondWrap saveDynamicForm(String requestWrapParam)  {
    
        //declaration of wrapper
        RequestWrap reqWrap = new RequestWrap();
        RespondWrap respWrap =  new RespondWrap();
        
        //deseriliaze.
        reqWrap = (RequestWrap) JSON.deserializeStrict(requestWrapParam, RequestWrap.class);
        
        try{
        
            
            list<sObject> sObjLstToUpsert = new list<sObject>();
            list<sObjMapClass> sObjListWrapper = new list<sObjMapClass>();

            for (map<string,string> sObjMap : reqWrap.sObjLst) {
                if(sObjMap.containsKey('id')){
                    Id ObjId = Id.valueof(sObjMap.get('id'));
                    sObjMapClass sObjMapClassObj = new sObjMapClass();
                    sObjMapClassObj.sObjName = ObjId.getSObjectType().getDescribe().getName();
                    sObjMapClassObj.sObjStructure = sObjMap;
                    sObjListWrapper.add(sObjMapClassObj);
                } 
            }

            respWrap.debugger = sObjListWrapper;

            for (sObjMapClass sObjMapClassObj : sObjListWrapper) {
                
                string sObjName = sObjMapClassObj.sObjName;
                sObject objrequest = Schema.getGlobalDescribe().get(sObjName).newSObject();
                SObjectType objType = ((SObject)(Type.forName('Schema.'+sObjName).newInstance())).getSObjectType();
                DescribeSObjectResult objDescb = ObjType.getDescribe();

                for (String fldApi : sObjMapClassObj.sObjStructure.keySet()) {
                    Schema.DisplayType fldType = objDescb.fields.getMap().get(fldApi).getDescribe().getType();
                    typeCastFlds(objrequest,fldType ,fldApi,sObjMapClassObj.sObjStructure.get(fldApi));
                }
                
                sObjLstToUpsert.add(objrequest);
            }

            for (sobject sObj : sObjLstToUpsert) {
                upsert sObj;
            }
         
        }catch(DMLException e) {
        
           string DMLError = e.getdmlMessage(0) + '';
           if(DMLError == null) {
             DMLError = e.getMessage() + '';
            }
           respWrap.errorMessage = DMLError;
        }
        

        return respWrap;
    }

    public static sObject typeCastFlds(sObject OBJSRTBU, Schema.DisplayType fldType,String fname,String fval) {
        
        switch on fldType {
            when BOOLEAN {
            OBJSRTBU.put(fname, Boolean.valueof(fval));
            }
            when DOUBLE {
            OBJSRTBU.put(fname, Double.valueof(fval));
            }
            when DATE {
            OBJSRTBU.put(fname, Date.valueof(fval));
            }
            when DATETIME {
            Datetime dt = Datetime.valueOf(fval.replace('T', ' ')).addHours(4);
            OBJSRTBU.put(fname, dt);
            }
            when CURRENCY {
            OBJSRTBU.put(fname, Double.valueof(fval));
            }
            when PERCENT {
            OBJSRTBU.put(fname, Double.valueof(fval));
            }
            when else {
            
            OBJSRTBU.put(fname, String.valueof(fval));
            }
        }

        return OBJSRTBU;
      }


        
    
    // ------------ Wrapper List ----------- //
        
    public class RequestWrap{
    
        //@AuraEnabled public map<string,object> sObjMap; 
       @AuraEnabled public list<map<string,string>> sObjLst; 
    }

    public class sObjMapClass{
    
        @AuraEnabled public string sObjName; 
       @AuraEnabled public map<string,string> sObjStructure = new map<string,string>(); 
    }
        
    public class RespondWrap{
    
        @AuraEnabled public object debugger;
        @AuraEnabled public object debugger2;
        @AuraEnabled public string userId;
        @AuraEnabled public string errorMessage;
    }
    
    @AuraEnabled
    public static Boolean externalCommentsProvided(Id stepId)  {
        Boolean commentsProvided=false;
        string RequestId;
        string CurrentStepTemplateCode;
        for(HexaBPM__Step__c CurStep:[Select Id, HexaBPM__SR__c,Step_Template_Code__c from HexaBPM__Step__c where Id=:stepId]){
            RequestId = CurStep.HexaBPM__SR__c;
            CurrentStepTemplateCode = CurStep.Step_Template_Code__c;
        }
        Map<String, String> mapOfExistingStepComments = new Map<String, String>();
        Map<String, String> mapOfStepCommentsByTemplateCode = new Map<String, String>();
        Set<Id> stepIds = new Set<Id>();
    
        if(mapOfStepCommentsByTemplateCode.get(CurrentStepTemplateCode)!=null){
            commentsProvided = True;            
        }
        return commentsProvided;   
       
    }
    
   
   
}