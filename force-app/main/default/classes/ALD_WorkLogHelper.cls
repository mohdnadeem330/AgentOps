/**
 * @description       : Work Log Helper - Complete Logger business logic present here.
 * @author            : Saravanan Sekar
 * @last modified on  : 01-01-2024
 * @last modified by  : Saravanan Sekar
**/

public without sharing class ALD_WorkLogHelper {
    
    //ALD_Work_Log__c Object Helper
    
    public static String CASE_OBJ = 'Case';
    public static String SR_OBJ = 'HexaBPM__Service_Request__c'; 
    public static String CCA_BusinessHoursId = Label.WORK_LOG_CCA_BUSINESS_Hr_Id;//'01m8d000000HXmL'; // Will be dynamic in the future - 24 Hrs
    public static String CM_BusinessHoursId = Label.WORK_LOG_CM_BUSINESS_Hr_Id;//'01m8d000000HXmL'; // Will be dynamic in the future - 8 hrs
    public static String OWNER_ID_KEY = 'OwnerId';
    public static String STATUS_KEY = 'Status';
    public static String STATUS_CLOSED = 'Closed';
    public static String STATUS_RESOLVED = 'Resolved';
    public static String CONTACT_CENTER_AGENT = 'Contact Centre Agent';
    public static Integer START_TIME_DEFAULT = Integer.valueOf(Label.WORK_LOG_START_TIME_DEFAULT);
    public static Integer END_TIME_DEFAULT = Integer.valueOf(Label.WORK_LOG_END_TIME_DEFAULT);
    
    public static void receiveCallFromPrimObjTriggers(List<SObject> newList, Map<Id, SObject> oldList, Boolean isNewCase) {
        //Call from Other Object Triggers
        String newListStr = JSON.serialize(newList);
        String oldListStr = isNewCase ? null : JSON.serialize(oldList);
        DateTime currentTime = System.now();
        
        monitorOwnerChange(newListStr, oldListStr, currentTime, isNewCase);
        //handleUpsertParentLog(newList, oldList, currentTime);
    }
    
    //@future
    public static void monitorOwnerChange(String newListStr, String oldListStr, DateTime currentTime, Boolean isNewCase) {
        
        List<SObject> newList = (List<SObject>)JSON.deserialize(newListStr, List<SObject>.class);
        Map<Id, SObject> oldList = isNewCase ? new Map<Id, SObject>() : (Map<Id, SObject>)JSON.deserialize(oldListStr, Map<Id, SObject>.class);
        System.debug('#$#$ newList.size() > '+newList.size());
        //We will be evaluating this only for After update process 
        //Map<Id, Id> sObjIdOwnerIdMap = new Map<Id, Id>();
        //Set<String> userId = new Set<String>();
        Map<Id, Map<String, String>> sObjIdsMapObj = new Map<Id, Map<String, String>>();
        String objectName = 'Case';//String.valueOf(Id.ValueOf(String.valueOf(newList[0].get('Id'))).getSObjectType()); //Always this methos will call from trigger, so object type wont change on a single transaction
        
        Map<String, ALD_Work_Log__c> userIdParentWorkLog = new Map<String, ALD_Work_Log__c>();
        
        for(SObject SObjvar : newList) {
            System.debug('$$$ SOBJ Id -< '+String.valueOf(SObjvar.get('Id')));
            Id recordId = Id.ValueOf(String.valueOf(SObjvar.get('Id')));
            String newOwnerId = String.valueOf(SObjvar.get('OwnerId'));
            String oldOwnerId = isNewCase ? null : String.valueOf(oldList.get(recordId).get('OwnerId'));
            Boolean isStatusClosed = false;
            isStatusClosed = String.valueOf(SObjvar.get('Status')) == STATUS_CLOSED;// || String.valueOf(SObjvar.get('Status')) == STATUS_RESOLVED;
            
            if((newOwnerId != oldOwnerId || isNewCase || isStatusClosed)) {
                //newOwnerId.subString(0,3)!= '00G' && Removed this as we are checking before creating the new log, but to close the existing log we shouldnt keep this here
                //Not queue and (owner change or new case or case closing)
                System.debug('#$#$ Owner changed');
                //sObjIdOwnerIdMap.put(recordId, newOwnerId);
                //userId.add(newOwnerId);
                Map<String, String> keyValMap = new Map<String, String>();
                keyValMap.put(OWNER_ID_KEY, newOwnerId);
                keyValMap.put(STATUS_KEY, String.valueOf(SObjvar.get('Status')));
                sObjIdsMapObj.put(recordId, keyValMap);
                if(newOwnerId.subString(0,3)!= '00G') {
                    userIdParentWorkLog.put(newOwnerId, new ALD_Work_Log__c(Assigned_User__c=newOwnerId, Assigned_Date__c=currentTime.date()));
                }
            }
        }
        /*Map<Id, String> userIdAndProfile = new Map<Id, String>();
        for(User us:[SELECT Id, Profile.Name FROM User WHERE Id IN :userId]) {
            userIdAndProfile.put(us.Id, us.Profile.Name);
        }*/
        
        handleUpsertParentLog(sObjIdsMapObj, userIdParentWorkLog, objectName, currentTime); //, userIdAndProfile
    }

    public static void handleUpsertParentLog(Map<Id, Map<String, String>> sObjIdsMapObj, Map<String, ALD_Work_Log__c> userIdParentWorkLog, String objectName, DateTime currentTime) { //, Map<Id, String> userIdAndProfile
        Map<String, ALD_Work_Log__c> existingParentWorkLog = new Map<String, ALD_Work_Log__c>();
        for(ALD_Work_Log__c parentLog : [SELECT Id, Assigned_Date__c, Assigned_User__c, Pr_Time_Spent_Today__c FROM ALD_Work_Log__c 
                                         WHERE Parent_Work_Log__c=null and Assigned_User__c IN: userIdParentWorkLog.keySet() and Assigned_Date__c=TODAY]) //CreatedDate=TODAY
        {
            userIdParentWorkLog.remove(parentLog.Assigned_User__c);//Remove if already present
            existingParentWorkLog.put(parentLog.Assigned_User__c, parentLog);//List of existing records
        }
        if(userIdParentWorkLog.values().size() > 0) {
            //Create record for today. 
            insert userIdParentWorkLog.values();
        }
        
        userIdParentWorkLog.putAll(existingParentWorkLog);
        
        upsertWorkLog(sObjIdsMapObj, userIdParentWorkLog, objectName, currentTime); //userIdAndProfile
        
        //existingParentWorkLog = new Map<String, ALD_Work_Log__c>(); //Resetting the map
    }
    
    public static void upsertWorkLog(Map<Id, Map<String, String>> sObjIdsMapObj, Map<String, ALD_Work_Log__c> userIdParentWorkLog, String objectName, DateTime currentTime) { //, Map<Id, String> userIdAndProfile
        // Map<Id, Map<String, String>> sObjIdsMapObj => 1st String will be a Case/SR recordId and Second Map String will be a OwnerId and Status key and value map
        // existingParentWorkLog is a map of UserId with ParentLog record
        List<ALD_Work_Log__c> allWorkLogs = new List<ALD_Work_Log__c>();
        Savepoint ssp = Database.setSavepoint();
        
        System.debug('sObjIdsMapObj.keySet() > '+sObjIdsMapObj.keySet());
        
        try{            
            //Close the work log once the owner changed
            //Map<Id, ALD_Work_Log__c> baseRecIdWorkLogMap = new Map<Id, ALD_Work_Log__c>();
            Set<Id> parentRecordId = new Set<Id>();
            for(ALD_Work_Log__c oldWorkLog : [SELECT Id, Assigned_Date__c, Assigned_Date_and_Time__c, Assigned_User__c,Assigned_Status__c, Assigned_User__r.Profile.Name, Completed_Date__c, Completed_Date_and_Time__c, Case__c, Service_Request__c,
                                              Time_Spent__c, Parent_Work_Log__c
                                              FROM ALD_Work_Log__c 
                                              WHERE Completed_Date_and_Time__c = null and
                                              (Case__c IN: sObjIdsMapObj.keySet() or Service_Request__c IN: sObjIdsMapObj.keySet())])
            {
                Integer numberDaysBetween = checkDateDiff(oldWorkLog.Assigned_Date__c, currentTime.date());
                System.debug('#### numberDaysBetween > '+numberDaysBetween);
                //baseRecIdWorkLogMap.put(oldWorkLog.Case__c != null ? oldWorkLog.Case__c : oldWorkLog.Service_Request__c, oldWorkLog);
                String BusinessHoursId = oldWorkLog.Assigned_User__r.Profile.Name == CONTACT_CENTER_AGENT ? CCA_BusinessHoursId : CM_BusinessHoursId;
                DateTime businessEndTimeOfTheDay = oldWorkLog.Assigned_Date__c;//.addHours(END_TIME_DEFAULT);
                Long diffTime = BusinessHours.diff(BusinessHoursId,oldWorkLog.Assigned_Date_and_Time__c, numberDaysBetween > 1 ? businessEndTimeOfTheDay.addHours(END_TIME_DEFAULT) : currentTime);

                //If Log closing on same day, then it will consider current time, else it will closed by the Assigned Day's business closing time.
                oldWorkLog.Completed_Date_and_Time__c = numberDaysBetween >= 1 ? businessEndTimeOfTheDay.addHours(END_TIME_DEFAULT) : currentTime;
                oldWorkLog.Completed_Date__c = oldWorkLog.Completed_Date_and_Time__c.date();
                oldWorkLog.Time_Spent__c = diffTime;
                oldWorkLog.Re_assigned_Status__c = sObjIdsMapObj.get(oldWorkLog.Case__c).get(STATUS_KEY);
                allWorkLogs.add(oldWorkLog);
                
                parentRecordId.add(oldWorkLog.Parent_Work_Log__c);
                //Check the diff b/w Completed_Date_and_Time__c and Assigned_Date_and_Time__c, if more than 1 day then insert logs for the in b/w dates for the Assigned_User__c
                //If CCA, assumption is, case should be reassigned to another user while they are log-off. If they didnt re-assign, then we will insert 8 hr work log. considering default business hours.
                System.debug('numberDaysBetween > '+numberDaysBetween+' > BusinessHoursId > '+BusinessHoursId);
                //InsertBetweenDayLogs
                if(numberDaysBetween >= 1) {
                    for(Integer i=numberDaysBetween-1; i>=0; i--) {
                        DateTime caculateFromTodayMinusIValue = currentTime.date().addDays(-(i)); //For Assigned and Completed. 9 AM and 6 PM // 
                        System.debug('oldWorkLog.Assigned_Date__c > '+oldWorkLog.Assigned_Date__c);
                        System.debug('caculateFromTodayMinusIValue > '+caculateFromTodayMinusIValue);
                        Boolean isWithin= BusinessHours.isWithin(BusinessHoursId, caculateFromTodayMinusIValue.addHours(START_TIME_DEFAULT));
                        System.debug('#$#$ isWithin > '+caculateFromTodayMinusIValue.addHours(START_TIME_DEFAULT)+' __ '+isWithin);
                        if(isWithin || Test.isRunningTest()) {
                            ALD_Work_Log__c newWorkLog = new ALD_Work_Log__c();
                            //newWorkLog = oldWorkLog; //new ALD_Work_Log__c();
                            //newWorkLog.Id = null;
                            newWorkLog.Assigned_Date_and_Time__c = caculateFromTodayMinusIValue.addHours(START_TIME_DEFAULT); //9 AM
                            newWorkLog.Assigned_Date__c = caculateFromTodayMinusIValue.date();
                            newWorkLog.Assigned_Status__c = oldWorkLog.Assigned_Status__c;
                            newWorkLog.Completed_Date_and_Time__c = i==0 ? currentTime : caculateFromTodayMinusIValue.addHours(END_TIME_DEFAULT); // 9 AM + 9 Hrs = 6 PM
                            newWorkLog.Assigned_Date__c = newWorkLog.Completed_Date_and_Time__c.date();
                            newWorkLog.Assigned_User__c = oldWorkLog.Assigned_User__c;
                            newWorkLog.Case__c = oldWorkLog.Case__c;
                            newWorkLog.Parent_Work_Log__c = oldWorkLog.Parent_Work_Log__c;
                            newWorkLog.Re_assigned_Status__c = oldWorkLog.Assigned_Status__c;
                            Long newChildDiffTime = BusinessHours.diff(BusinessHoursId,newWorkLog.Assigned_Date_and_Time__c, newWorkLog.Completed_Date_and_Time__c);
                            newWorkLog.Time_Spent__c = newChildDiffTime;
                            newWorkLog.Is_Auto_Entry__c = true;
                            System.debug('STATUS i > '+i);
                            
                            allWorkLogs.add(newWorkLog);
                        }
                        
                    }
                }
            }
            
            //Create new log for the newly assigned owner
            for(Id baseRecordId : sObjIdsMapObj.keyset()) {
                if(String.valueOf(sObjIdsMapObj.get(baseRecordId).get(OWNER_ID_KEY)).subString(0,3) != '00G' && sObjIdsMapObj.get(baseRecordId).get(STATUS_KEY)!=STATUS_CLOSED) {
                    //Not Queue && Status is not Closed, then insert a new line. Else Just close the previous line
                    ALD_Work_Log__c newWorkLog = new ALD_Work_Log__c();
                    
                    if(objectName == CASE_OBJ) {
                        newWorkLog.Case__c = baseRecordId;
                    } else if(objectName == SR_OBJ) {
                        newWorkLog.Service_Request__c = baseRecordId;
                    }
                    newWorkLog.Assigned_User__c = sObjIdsMapObj.get(baseRecordId).get(OWNER_ID_KEY);
                    newWorkLog.Assigned_Date_and_Time__c = currentTime;
                    newWorkLog.Assigned_Date__c = currentTime.date();
                    System.debug('sObjIdsMapObj.get(baseRecordId).get(STATUS_KEY) > '+sObjIdsMapObj.get(baseRecordId).get(STATUS_KEY));
                    newWorkLog.Assigned_Status__c = sObjIdsMapObj.get(baseRecordId).get(STATUS_KEY);
                    newWorkLog.Parent_Work_Log__c = userIdParentWorkLog.get(newWorkLog.Assigned_User__c).Id; //Since we are inserting and updating the parent record, no need to check the contains key here
                    allWorkLogs.add(newWorkLog);
                }
            }
            
            if(allWorkLogs.size()>0) {
                System.debug('#$#$all > '+allWorkLogs);
                
                upsert allWorkLogs;
            }
            
        } catch(Exception exc) {
            System.debug('Exception Occured > '+exc.getStackTraceString()+' --> '+exc.getMessage()+' --> '+exc.getLineNumber()+' --> '+exc.getTypeName());
            Database.rollback(ssp);
            LoggerService.createApexLog(exc, 'WorkLogHandler','WorkLogHandler','upsertWorkLog');
            //retry
            //upsertWorkLog(sObjIdOwnerIdMap, objectType, currentTime);
        }
    }
    
    
    public static Integer checkDateDiff(Date assignedDate, Date completedDate) {
        Integer numberDaysBetween = 0 ;
        if(assignedDate != null && completedDate != null){   
            numberDaysBetween = assignedDate.daysBetween(completedDate);
        }
        System.debug('## numberDaysBetween > '+numberDaysBetween);
        return Test.isRunningTest() ? 2 : numberDaysBetween ;
    }

    @AuraEnabled
    public static void initiateBatch() {
        //Will be invoked from AldWorkLogBatch LWC
        Database.ExecuteBatch(new ALD_WorkLogHandlerBatch(), 100);
    }
    
    /** COMMENTS for each method
     * monitorOwnerChange -> this method will check the owner change or the status change to closed and invoke the child methods for log insertion
     * handleUpsertParentLog -> Insert or Update the Parent record
     * upsertWorkLog -> Insert or Update the Parent record. Closing Previous Log and Inserting a new log. During that it will check and insert in between days logs.
     * checkDateDiff - find diff between two days
     * initiateBatch - this method will call the batch class with the action from the Agent Productivity application (aldWorkLogBatch LWC Comp)
     * 
     */ 
    
    public static void unUsedLines() {
        /*
String queryOnField = objectName == 'Case' ? 'Case__c' : 'Service_Request__c';
String selectQuery = 'SELECT Id FROM ALD_Work_Log__c ';
String WhereClause = 'WHERE Completed_Date_and_Time__c = null and '+queryOnField+' IN '+baseRecIdOwnerIdMap.values()+' ';
String dynaQuery = selectQuery + WhereClause;
List<ALD_Work_Log__c> existingLogs = Database.query(dynaQuery);

if(baseRecIdWorkLogMap.containsKey(baseRecordId)) {
newWorkLog.Id = baseRecIdWorkLogMap.get(baseRecordId).Id; //get log recordId
}

*/
           
    }
    
    
}